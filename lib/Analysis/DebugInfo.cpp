//===- DebugInfo.cpp - Debug info analysis --------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "circt/Analysis/DebugInfo.h"
#include "circt/Dialect/Debug/DebugOps.h"
#include "circt/Dialect/HW/HWOps.h"
#include "mlir/IR/BuiltinOps.h"
#include "llvm/Support/Debug.h"

#define DEBUG_TYPE "di"

using namespace mlir;
using namespace circt;

namespace circt {
namespace detail {

/// Helper to populate a `DebugInfo` with nodes.
struct DebugInfoBuilder {
  DebugInfoBuilder(DebugInfo &di) : di(di) {}
  DebugInfo &di;

  void visitRoot(Operation *op);
  void visitModule(hw::HWModuleOp moduleOp, DIModule &module);

  DIModule *createModule() {
    return new (di.moduleAllocator.Allocate()) DIModule;
  }

  DIInstance *createInstance() {
    return new (di.instanceAllocator.Allocate()) DIInstance;
  }

  DIVariable *createVariable() {
    return new (di.variableAllocator.Allocate()) DIVariable;
  }

  DIModule &getOrCreateModule(StringAttr moduleName) {
    auto &slot = di.moduleNodes[moduleName];
    if (!slot) {
      slot = createModule();
      slot->name = moduleName;
    }
    return *slot;
  }
};

void DebugInfoBuilder::visitRoot(Operation *op) {
  op->walk<WalkOrder::PreOrder>([&](Operation *op) {
    if (auto moduleOp = dyn_cast<hw::HWModuleOp>(op)) {
      LLVM_DEBUG(llvm::dbgs()
                 << "Collect DI for module " << moduleOp.getNameAttr() << "\n");
      auto &module = getOrCreateModule(moduleOp.getNameAttr());
      module.op = op;

      // TODO: add source language type info to the module (similarly to
      // variables)

      visitModule(moduleOp, module); // Visit the module
      return WalkResult::skip();
    }

    if (auto moduleOp = dyn_cast<hw::HWModuleExternOp>(op)) {
      LLVM_DEBUG(llvm::dbgs() << "Collect DI for extern module "
                              << moduleOp.getNameAttr() << "\n");
      auto &module = getOrCreateModule(moduleOp.getNameAttr());
      module.op = op;
      module.isExtern = true;

      // Add variables for each of the ports.
      for (auto &port : moduleOp.getPortList()) {
        auto *var = createVariable();
        var->name = port.name;
        var->loc = port.loc;
        module.variables.push_back(var);
      }

      return WalkResult::skip();
    }

    return WalkResult::advance();
  });
}

void DebugInfoBuilder::visitModule(hw::HWModuleOp moduleOp, DIModule &module) {
  // Try to gather debug info from debug ops in the module. If we find any,
  // return. Otherwise collect ports, instances, and variables as a
  // fallback.

  // Check what kind of DI is present in the module. Also create additional
  // `DIModule` hierarchy levels for each explicit scope op in the module.
  SmallDenseMap<debug::ScopeOp, DIModule *> scopes;
  bool hasVariables = false;
  bool hasInstances = false;
  moduleOp.walk([&](Operation *op) {
    if (isa<debug::VariableOp>(op))
      hasVariables = true;
    if (auto scopeOp = dyn_cast<debug::ScopeOp>(op)) {
      auto *node = createModule();
      node->isInline = true;
      node->name = scopeOp.getModuleNameAttr();
      node->op = scopeOp;
      scopes.insert({scopeOp, node});
    }

    // Add the source language information to the module
    if (auto sourceLangType = dyn_cast<debug::ModuleInfoOp>(op)) {
      module.sourceLangType.typeName = sourceLangType.getTypeNameAttr();
      module.sourceLangType.params = sourceLangType.getParamsAttr();
    }

    // Add enum definitions to the module if any
    if (auto e = dyn_cast<debug::EnumDefOp>(op)) {
      SmallDenseMap<int64_t, StringAttr> enumMap;

      // Collect the enum map
      for (auto na : e.getVariantsMapAttr()) {
        auto key = na.getValue().cast<IntegerAttr>().getInt();
        auto value = na.getName().cast<StringAttr>();
        enumMap.insert({key, value});
      }
      module.enumDefinitions.insert({e.getId(), enumMap});
    }
  });

  // Helper function to resolve a `scope` operand on a variable to the
  // `DIModule` into which the variable should be collected. If the `scope` is
  // not set, or it isn't a valid `dbg.scope` op, returns the `module` argument
  // of this function.
  auto getScope = [&](Value scopeValue) -> DIModule & {
    if (scopeValue)
      if (auto scopeOp = scopeValue.getDefiningOp<debug::ScopeOp>())
        return *scopes.lookup(scopeOp);
    return module;
  };

  // If the module has no DI for variables, add variables for each of the ports
  // as a fallback.
  if (!hasVariables) {
    auto inputValues = moduleOp.getBody().getArguments();
    auto outputValues = moduleOp.getBodyBlock()->getTerminator()->getOperands();
    for (auto &port : moduleOp.getPortList()) {
      auto value = port.isOutput() ? outputValues[port.argNum]
                                   : inputValues[port.argNum];
      auto *var = createVariable();
      var->name = port.name;
      var->loc = port.loc;
      var->value = value;
      module.variables.push_back(var);
    }
  }

  // Fill in any missing DI as a fallback.
  moduleOp->walk([&](Operation *op) {
    if (auto varOp = dyn_cast<debug::VariableOp>(op)) {
      auto *var = createVariable();
      var->name = varOp.getNameAttr();
      var->loc = varOp.getLoc();
      var->value = varOp.getValue();

      // Attach to the variable the type information from the source language
      // type information.
      var->sourceLangType.typeName = varOp.getTypeNameAttr();
      var->sourceLangType.params = varOp.getParamsAttr();

      getScope(varOp.getScope()).variables.push_back(var);

      // Add enum definition to the variable if any
      if (auto e = varOp.getEnumDef())
        if (auto enumDef = e.getDefiningOp<debug::EnumDefOp>()) {
          var->enumDefRef = enumDef.getId();
        }
      return;
    }

    if (auto scopeOp = dyn_cast<debug::ScopeOp>(op)) {
      auto *instance = createInstance();
      instance->name = scopeOp.getInstanceNameAttr();
      instance->op = scopeOp;
      instance->module = scopes.lookup(scopeOp);
      getScope(scopeOp.getScope()).instances.push_back(instance);
    }

    // Fallback if the module has no DI for its instances.
    if (!hasInstances) {
      if (auto instOp = dyn_cast<hw::InstanceOp>(op)) {
        auto &childModule =
            getOrCreateModule(instOp.getModuleNameAttr().getAttr());
        auto *instance = createInstance();
        instance->name = instOp.getInstanceNameAttr();
        instance->op = instOp;
        instance->module = &childModule;
        module.instances.push_back(instance);

        // TODO: What do we do with the port assignments? These should be
        // tracked somewhere.
        return;
      }
    }

    // Fallback if the module has no DI for its variables.
    if (!hasVariables) {
      if (auto wireOp = dyn_cast<hw::WireOp>(op)) {
        auto *var = createVariable();
        var->name = wireOp.getNameAttr();
        var->loc = wireOp.getLoc();
        var->value = wireOp;
        module.variables.push_back(var);
        return;
      }
    }
  });
}

} // namespace detail
} // namespace circt

DebugInfo::DebugInfo(Operation *op) : operation(op) {
  detail::DebugInfoBuilder(*this).visitRoot(op);
}

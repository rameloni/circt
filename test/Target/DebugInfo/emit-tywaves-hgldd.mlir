// RUN: circt-translate --emit-tywaves-hgldd %s | FileCheck %s
// RUN: circt-translate %s --emit-split-tywaves-hgldd --hgldd-output-dir=%T --hgldd-source-prefix=my_source --hgldd-output-prefix=my_verilog

// RUN: cat %T/Foo.dd | FileCheck %s --check-prefix=CHECK-FOO
// RUN: cat %T/Bar.dd | FileCheck %s --check-prefix=CHECK-BAR

#loc1 = loc("InputFoo.scala":4:10)
#loc2 = loc("InputFoo.scala":5:11)
#loc3 = loc("InputFoo.scala":6:12)
#loc4 = loc("InputBar.scala":8:5)
#loc5 = loc("InputBar.scala":14:5)
#loc6 = loc("InputBar.scala":21:10)
#loc7 = loc("InputBar.scala":22:11)
#loc8 = loc("InputBar.scala":23:12)
#loc9 = loc("InputBar.scala":25:15)
#loc10 = loc("Foo.sv":42:10)
#loc11 = loc("Bar.sv":49:10)

// CHECK-FOO:      "file_info": [
// CHECK-FOO-NEXT:   "my_source{{/|\\\\}}InputFoo.scala"
// CHECK-FOO-NEXT:   "my_verilog{{/|\\\\}}Foo.sv"
// CHECK-FOO-NEXT:   "my_source{{/|\\\\}}InputBar.scala"
// CHECK-FOO-NEXT: ]
// CHECK-FOO-NEXT: "hdl_file_index": 2

// CHECK-FOO: "kind": "module"
// CHECK-FOO: "name": "Foo"

// CHECK-BAR:      "file_info": [
// CHECK-BAR-NEXT:   "my_source{{/|\\\\}}InputBar.scala"
// CHECK-BAR-NEXT:   "my_verilog{{/|\\\\}}Bar.sv"
// CHECK-BAR-NEXT: ]
// CHECK-BAR-NEXT: "hdl_file_index": 2

// CHECK-BAR: "kind": "module"
// CHECK-BAR: "name": "Bar"

// CHECK-LABEL: FILE "Foo.dd"
// CHECK: {
// CHECK-NEXT: "HGLDD"
// CHECK-NEXT:   "version": "1.0"
// CHECK-NEXT:   "file_info": [
// CHECK-NEXT:     "InputFoo.scala"
// CHECK-NEXT:     "Foo.sv"
// CHECK-NEXT:     "InputBar.scala"
// CHECK-NEXT:   ]
// CHECK-NEXT:   "hdl_file_index": 2
// CHECK-NEXT: }
// CHECK-NEXT: "scopes"
// CHECK-NEXT: {
// CHECK-NEXT:   "kind": "module"
// CHECK-NEXT:   "name": "Foo"
// CHECK-NEXT:   "verilog_name": "Foo"
// CHECK-NEXT:   "type_name": "na"
// CHECK-NEXT:   "hgl_loc"
// CHECK-NEXT:     "begin_column": 10
// CHECK-NEXT:     "begin_line": 4
// CHECK-NEXT:     "end_column": 10
// CHECK-NEXT:     "end_line": 4
// CHECK-NEXT:     "file": 1
// CHECK-NEXT:   }
// CHECK-NEXT:   "hdl_loc"
// CHECK-NEXT:     "begin_column": 10
// CHECK-NEXT:     "begin_line": 42
// CHECK-NEXT:     "end_column": 10
// CHECK-NEXT:     "end_line": 42
// CHECK-NEXT:     "file": 2
// CHECK-NEXT:   }
// CHECK-NEXT:   "child_variables"
// CHECK:          {"hw_type":"logic","name":"inA","real_type":{"ground":{"vcd_name":"a","width":[31,0]}},"type_name":"SInt<32>"}  
// CHECK:          {"hw_type":"logic","name":"outB","real_type":{"ground":{"vcd_name":"b","width":[31,0]}},"type_name":"SInt<32>"}
// CHECK:          {"hw_type":"logic","name":"var1"
// CHECK:             "params":[{"name":"n","type":"uint","value":"8"},{"name":"a","type":"myType"}]
// CHECK:             "real_type":{"ground":{"constant":"00101010","width":[7,0]}}
// CHECK:             "type_name":"UInt<8>"}    
// CHECK:        "child_scopes"
// CHECK-LABEL:    "name": "b0"
// CHECK:          "obj_name": "Bar"
// CHECK:          "module_name": "Bar"
// CHECK:          "hgl_loc"
// CHECK:            "file": 3
// CHECK-LABEL:    "name": "b1"
// CHECK:          "obj_name": "Bar"
// CHECK:          "module_name": "Bar"
// CHECK:          "hgl_loc"
// CHECK:            "file": 3
hw.module @Foo(in %a: i32 loc(#loc2), out b: i32 loc(#loc3)) {
  dbg.variable "inA", %a {typeName = "SInt<32>"}: i32 loc(#loc2)
  dbg.variable "outB", %b1.y {typeName = "SInt<32>"}: i32 loc(#loc3)
  %c42_i8 = hw.constant 42 : i8
  dbg.variable "var1", %c42_i8 {typeName = "UInt<8>", params = [{name="n",type="uint",value="8"}, {name="a", type="myType"}]}: i8 loc(#loc3)
  %b0.y = hw.instance "b0" @Bar(x: %a: i32) -> (y: i32) loc(#loc4)
  %b1.y = hw.instance "b1" @Bar(x: %b0.y: i32) -> (y: i32) loc(#loc5)
  hw.output %b1.y : i32 loc(#loc1)
} loc(fused[#loc1, "emitted"(#loc10)])

// CHECK-LABEL: FILE "Bar.dd"
// CHECK: "scopes"
// CHECK: "name": "Bar"
// CHECK:   "child_variables"
//            Handle missing typeName
// CHECK:     {"hw_type":"logic","name":"inX","real_type":{"ground":{"vcd_name":"x","width":[31,0]}}}    
// CHECK:     {"hw_type":"logic","name":"outY"
// CHECK:     {"hw_type":"logic","name":"varZ"
// CHECK:     {"hw_type":"logic","name":"add"    
hw.module private @Bar(in %x: i32 loc(#loc7), out y: i32 loc(#loc8)) {
  %0 = comb.mul %x, %x : i32 loc(#loc9)
  dbg.variable "inX", %x : i32 loc(#loc7)
  dbg.variable "outY", %0 : i32 loc(#loc8)
  dbg.variable "varZ", %0 : i32 loc(#loc9)
  %1 = comb.add %0, %x : i32 loc(#loc9)
  dbg.variable "add", %1 : i32 loc(#loc9)
  hw.output %0 : i32 loc(#loc6)
} loc(fused[#loc6, "emitted"(#loc11)])

// CHECK-LABEL: FILE "global.dd"
// CHECK:       "scopes"
// CHECK:         "kind": "module"
// CHECK:         "name": "Aggregates"
// CHECK:         "child_variables"
// CHECK:           "hw_type":"struct","name":"data","real_type":{"bundle":{"fields":
// CHECK:             "name":"a","real_type":{"ground":{"vcd_name":"data_a","width":[31,0]}},"type_name":"i32"}
// CHECK:             "name":"b","real_type":{"ground":{"vcd_name":"data_b","width":[41,0]}},"type_name":"i42"}
// CHECK:             "name":"c","real_type":{"vec":{"fields":
// CHECK:               "name":"data_c","real_type":{"ground":{"vcd_name":"data_c_0","width":[16,0]}},"type_name":"i17"}
// CHECK:               "name":"data_c","real_type":{"ground":{"vcd_name":"data_c_1","width":[16,0]}},"type_name":"i17"}
// CHECK:           "type_name":"i17[2]"}
// CHECK:          "type_name":"abc_struct"}

hw.module @Aggregates(in %data_a: i32, in %data_b: i42, in %data_c_0: i17, in %data_c_1: i17) {
  %0 = dbg.subfield "a", %data_a {typeName = "i32"}: i32
  %1 = dbg.subfield "b", %data_b {typeName = "i42"}: i42
  %2 = dbg.subfield "data_c", %data_c_0 {typeName = "i17"}: i17
  %3 = dbg.subfield "data_c", %data_c_1 {typeName = "i17"}: i17
  %4 = dbg.array [%2, %3] : !dbg.subfield
  %5 = dbg.subfield "c", %4 {typeName = "i17[2]"}: !dbg.array
  %6 = dbg.struct {"aa": %0, "bb": %1, "cc": %5} : !dbg.subfield, !dbg.subfield, !dbg.subfield
  dbg.variable "data", %6 {typeName = "abc_struct"}: !dbg.struct
}

// CHECK-LABEL: "verilog_name": "EmptyAggregates"
// CHECK:         "child_variables"
// CHECK-NEXT:      "hw_type":"array"
// CHECK:           "name":"x"
// CHECK:           "real_type"
// CHECK:               "vec":{"fields":[],"size":0}
// CHECK-NEXT:      "hw_type":"struct"
// CHECK:           "name":"y"
// CHECK:           "real_type"
// CHECK:               "bundle":{"fields":[],"vcd_name":"y"}
// CHECK-NEXT:      "hw_type":"struct",
// CHECK:           "name":"z"
// CHECK:           "real_type"
// CHECK:               "bundle":
// CHECK:               "fields"
// CHECK:                  "vec":
// CHECK:                    "fields":[],"size":0
// CHECK:                  "bundle"
// CHECK:                    "fields":[]
hw.module @EmptyAggregates() {
  %0 = dbg.array []
  %1 = dbg.struct {}
  %2 = dbg.struct {"a": %0, "b": %1} : !dbg.array, !dbg.struct
  dbg.variable "x", %0 : !dbg.array
  dbg.variable "y", %1 : !dbg.struct
  dbg.variable "z", %2 : !dbg.struct
}

// CHECK-LABEL: "verilog_name": "SingleElementAggregates"
// CHECK:       "child_variables"
// CHECK-NEXT:    "hw_type":"array"
// CHECK:         "name":"varFoo"
// CHECK:         "real_type":{"vec":{"fields":[{"vcd_name":"foo"}],"size":1}
// CHECK-NEXT:    "hw_type":"struct"
// CHECK:         "name":"varBar"
// CHECK:         "real_type":{"bundle":{"fields":[{"vcd_name":"bar"}],"vcd_name":"varBar"}
hw.module @SingleElementAggregates() {
  %foo = sv.wire : !hw.inout<i1>
  %bar = sv.wire : !hw.inout<i1>
  %0 = sv.read_inout %foo : !hw.inout<i1>
  %1 = sv.read_inout %bar : !hw.inout<i1>
  %2 = dbg.array [%0] : i1
  %3 = dbg.struct {"x": %1} : i1
  dbg.variable "varFoo", %2 : !dbg.array
  dbg.variable "varBar", %3 : !dbg.struct
}

// CHECK-LABEL: "verilog_name": "MultiDimensionalArrays"
// CHECK:         "child_variables"
// CHECK-NEXT:      "hw_type":"array"
// CHECK:           "name":"array"
// CHECK:           "real_type"
// CHECK:               "vec"
// CHECK:                 "fields"
// CHECK:                   [{"vec"
// CHECK:                     "fields":[{"vcd_name":"a"},{"vcd_name":"b"},{"vcd_name":"c"},{"vcd_name":"d"}]
// CHECK:                     "size":4}}]
// CHECK:                 "size":1

hw.module @MultiDimensionalArrays(in %a: i42, in %b: i42, in %c: i42, in %d: i42) {
  %0 = dbg.array [%a, %b, %c, %d] : i42
  %1 = dbg.array [%0] : !dbg.array
  dbg.variable "array", %1 : !dbg.array
}

// CHECK-LABEL: "verilog_name": "Expressions"
hw.module @Expressions(in %a: i1, in %b: i1) {
  // CHECK-LABEL: "name":"blockArg"
  // CHECK: "real_type":{"ground":{"vcd_name":"a","width":[0,0]}}
  dbg.variable "blockArg", %a : i1

  %0 = hw.wire %a {hw.verilogName = "explicitName"} : i1

  // CHECK-LABEL: "name":"constA"
  // CHECK: "real_type":{"ground":{"constant":"00000010100111001","width":[16,0]}}

  // CHECK-LABEL: "name":"constB"
  // CHECK: "real_type":{"ground":{"constant":"000000000000000000000000000010001100101001","width":[41,0]}}

  // CHECK-LABEL: "name":"constC"
  // CHECK: "real_type":{"ground":{"constant":"0000","width":[3,0]}}

  // CHECK-LABEL: "name":"constD"
  // CHECK: "real_type":{"ground":{"constant":"0","width":[0,0]}}

  %k0 = hw.constant 1337 : i17
  %k1 = hw.constant 9001 : i42
  %k2 = hw.constant 0 : i4
  %k3 = hw.constant 0 : i0
  dbg.variable "constA", %k0 : i17
  dbg.variable "constB", %k1 : i42
  dbg.variable "constC", %k2 : i4
  dbg.variable "constD", %k3 : i0

  // CHECK-LABEL: "name":"readWire"
  // CHECK: "real_type":{"ground":{"vcd_name":"svWire","width":[0,0]}}
  %svWire = sv.wire : !hw.inout<i1>
  %3 = sv.read_inout %svWire : !hw.inout<i1>
  dbg.variable "readWire", %3 : i1

  // CHECK-LABEL: "name":"readReg"
  // CHECK: "real_type":{"ground":{"vcd_name":"svReg","width":[0,0]}}
  %svReg = sv.reg : !hw.inout<i1>
  %4 = sv.read_inout %svReg : !hw.inout<i1>
  dbg.variable "readReg", %4 : i1

  // CHECK-LABEL: "name":"readLogic"
  // CHECK: "real_type":{"ground":{"vcd_name":"svLogic","width":[0,0]}}
  %svLogic = sv.logic : !hw.inout<i1>
  %5 = sv.read_inout %svLogic : !hw.inout<i1>
  dbg.variable "readLogic", %5 : i1

  // CHECK-LABEL: "name":"myWire"
  // CHECK: "real_type":{"ground":{"vcd_name":"hwWire","width":[0,0]}}
  %hwWire = hw.wire %a : i1
  dbg.variable "myWire", %hwWire : i1

  // CHECK-LABEL: "name":"unaryParity"
  // CHECK: "real_type":{"ground":{"opcode":"^","operands":[{"vcd_name":"a"}],"width":[0,0]}}
  %6 = comb.parity %a : i1
  dbg.variable "unaryParity", %6 : i1

  // CHECK-LABEL: "name":"binaryAdd"
  // CHECK: "real_type":{"ground":{"opcode":"+","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  %7 = comb.add %a, %b : i1
  dbg.variable "binaryAdd", %7 : i1

  // CHECK-LABEL: "name":"binarySub"
  // CHECK: "real_type":{"ground":{"opcode":"-","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  %8 = comb.sub %a, %b : i1
  dbg.variable "binarySub", %8 : i1

  // CHECK-LABEL: "name":"binaryMul"
  // CHECK: "real_type":{"ground":{"opcode":"*","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  %9 = comb.mul %a, %b : i1
  dbg.variable "binaryMul", %9 : i1

  // CHECK-LABEL: "name":"binaryDiv1"
  // CHECK: "real_type":{"ground":{"opcode":"/","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"binaryDiv2"
  // CHECK: "real_type":{"ground":{"opcode":"/","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  %10 = comb.divu %a, %b : i1
  %11 = comb.divs %a, %b : i1
  dbg.variable "binaryDiv1", %10 : i1
  dbg.variable "binaryDiv2", %11 : i1

  // CHECK-LABEL: "name":"binaryMod1"
  // CHECK: "real_type":{"ground":{"opcode":"%","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"binaryMod2"
  // CHECK: "real_type":{"ground":{"opcode":"%","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  %12 = comb.modu %a, %b : i1
  %13 = comb.mods %a, %b : i1
  dbg.variable "binaryMod1", %12 : i1
  dbg.variable "binaryMod2", %13 : i1

  // CHECK-LABEL: "name":"binaryShl"
  // CHECK: "real_type":{"ground":{"opcode":"<<","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"binaryShr1"
  // CHECK: "real_type":{"ground":{"opcode":">>","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"binaryShr2"
  // CHECK: "real_type":{"ground":{"opcode":">>>","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  %14 = comb.shl %a, %b : i1
  %15 = comb.shru %a, %b : i1
  %16 = comb.shrs %a, %b : i1
  dbg.variable "binaryShl", %14 : i1
  dbg.variable "binaryShr1", %15 : i1
  dbg.variable "binaryShr2", %16 : i1

 
  // CHECK-LABEL: "name":"cmpEq"
  // CHECK: "real_type":{"ground":{"opcode":"==","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpNe"
  // CHECK: "real_type":{"ground":{"opcode":"!=","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpCeq"
  // CHECK: "real_type":{"ground":{"opcode":"===","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpCne"
  // CHECK: "real_type":{"ground":{"opcode":"!==","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpWeq"
  // CHECK: "real_type":{"ground":{"opcode":"==?","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpWne"
  // CHECK: "real_type":{"ground":{"opcode":"!=?","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpUlt"
  // CHECK: "real_type":{"ground":{"opcode":"<","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpSlt"
  // CHECK: "real_type":{"ground":{"opcode":"<","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpUgt"
  // CHECK: "real_type":{"ground":{"opcode":">","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpSgt"
  // CHECK: "real_type":{"ground":{"opcode":">","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpUle"
  // CHECK: "real_type":{"ground":{"opcode":"<=","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpSle"
  // CHECK: "real_type":{"ground":{"opcode":"<=","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpUge"
  // CHECK: "real_type":{"ground":{"opcode":">=","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  // CHECK-LABEL: "name":"cmpSge"
  // CHECK: "real_type":{"ground":{"opcode":">=","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  %17 = comb.icmp eq %a, %b : i1
  %18 = comb.icmp ne %a, %b : i1
  %19 = comb.icmp ceq %a, %b : i1
  %20 = comb.icmp cne %a, %b : i1
  %21 = comb.icmp weq %a, %b : i1
  %22 = comb.icmp wne %a, %b : i1
  %23 = comb.icmp ult %a, %b : i1
  %24 = comb.icmp slt %a, %b : i1
  %25 = comb.icmp ugt %a, %b : i1
  %26 = comb.icmp sgt %a, %b : i1
  %27 = comb.icmp ule %a, %b : i1
  %28 = comb.icmp sle %a, %b : i1
  %29 = comb.icmp uge %a, %b : i1
  %30 = comb.icmp sge %a, %b : i1
  dbg.variable "cmpEq", %17 : i1
  dbg.variable "cmpNe", %18 : i1
  dbg.variable "cmpCeq", %19 : i1
  dbg.variable "cmpCne", %20 : i1
  dbg.variable "cmpWeq", %21 : i1
  dbg.variable "cmpWne", %22 : i1
  dbg.variable "cmpUlt", %23 : i1
  dbg.variable "cmpSlt", %24 : i1
  dbg.variable "cmpUgt", %25 : i1
  dbg.variable "cmpSgt", %26 : i1
  dbg.variable "cmpUle", %27 : i1
  dbg.variable "cmpSle", %28 : i1
  dbg.variable "cmpUge", %29 : i1
  dbg.variable "cmpSge", %30 : i1

  // CHECK-LABEL: "name":"opAnd"
  // CHECK: "real_type":{"ground":{"opcode":"&","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  %31 = comb.and %a, %b : i1
  dbg.variable "opAnd", %31 : i1

  // CHECK-LABEL: "name":"opOr"
  // CHECK: "real_type":{"ground":{"opcode":"|","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  %32 = comb.or %a, %b : i1
  dbg.variable "opOr", %32 : i1

  // CHECK-LABEL: "name":"opXor"
  // CHECK: "real_type":{"ground":{"opcode":"^","operands":[{"vcd_name":"a"},{"vcd_name":"b"}],"width":[0,0]}}
  %33 = comb.xor %a, %b : i1
  dbg.variable "opXor", %33 : i1

  // CHECK-LABEL: "name":"concat"
  // CHECK: "real_type":{"ground":{"opcode":"{}","operands":[{"vcd_name":"a"},{"vcd_name":"b"},{"vcd_name":"explicitName"}],"width":[2,0]}}
  %34 = comb.concat %a, %b, %0 : i1, i1, i1
  dbg.variable "concat", %34 : i3

  // CHECK-LABEL: "name":"replicate"
  // CHECK: "real_type":{"ground":{"opcode":"R{}","operands":[{"integer_num":3},{"vcd_name":"a"}],"width":[2,0]}}}
  %35 = comb.replicate %a : (i1) -> i3
  dbg.variable "replicate", %35 : i3

  // CHECK-LABEL: "name":"extract"
  // CHECK: "real_type":{"ground":{"opcode":"[]","operands":[{"vcd_name":"wideWire"},{"integer_num":19},{"integer_num":12}],"width":[7,0]}}}
  %wideWire = hw.wire %k1 : i42
  %36 = comb.extract %wideWire from 12 : (i42) -> i8
  dbg.variable "extract", %36 : i8

  // CHECK-LABEL: "name":"mux"
  // CHECK: "real_type":{"ground":{"opcode":"?:","operands":[{"vcd_name":"a"},{"vcd_name":"b"},{"vcd_name":"explicitName"}],"width":[0,0]}}
  %37 = comb.mux %a, %b, %0 : i1
  dbg.variable "mux", %37 : i1
}

// CHECK-LABEL: "verilog_name": "CustomSingleResult123"
// CHECK:       "isExtModule": 1
hw.module.extern @SingleResult(out outPort: i1) attributes {verilogName = "CustomSingleResult123"}

// CHECK-LABEL: "verilog_name": "LegalizedNames"
// CHECK:       "child_variables"
// CHECK:       "hw_type":"logic","name":"myWire"
// CHECK:       "real_type":{"ground":{"vcd_name":"wire_1","width":[0,0]}}
// CHECK:       "child_scopes"
// CHECK:         "name": "myInst"
// CHECK:         "hdl_obj_name": "reg_0"
// CHECK:         "obj_name": "Dummy"
// CHECK:         "module_name": "CustomDummy"
hw.module @LegalizedNames() {
  hw.instance "myInst" @Dummy() -> () {hw.verilogName = "reg_0"}
  %false = hw.constant false
  %myWire = hw.wire %false {hw.verilogName = "wire_1"} : i1
}
hw.module.extern @Dummy() attributes {verilogName = "CustomDummy"}

// CHECK-LABEL: "verilog_name": "InlineScopes"
// CHECK:       "child_variables"
// CHECK:       "hw_type":"logic","name":"x"
// CHECK:       "real_type":{"ground":{"vcd_name":"a","width":[41,0]}}
// CHECK:       "child_scopes"
// CHECK:         "name": "child"
// CHECK:         "child_variables"
// CHECK:           "hw_type":"logic","name":"y"
// CHECK:           "real_type":{"ground":{"vcd_name":"a","width":[41,0]}}
// CHECK:         "child_scopes"
// CHECK:           "name": "more"
// CHECK:           "child_variables"
// CHECK:             "hw_type":"logic","name":"z"
// CHECK:             "real_type":{"ground":{"vcd_name":"a","width":[41,0]}}
hw.module @InlineScopes(in %a: i42) {
  %1 = dbg.scope "child", "InlinedChild"
  %2 = dbg.scope "more", "InlinedMore" scope %1
  dbg.variable "x", %a : i42
  dbg.variable "y", %a scope %1 : i42
  dbg.variable "z", %a scope %2 : i42
}

// See https://github.com/llvm/circt/issues/6735
// CHECK-LABEL: "verilog_name": "Issue6735_Case1"
hw.module @Issue6735_Case1(out someOutput: i1) {
  // Don't use instance name as signal name directly.
  // CHECK: "hw_type":"logic","name":"varA"
  // CHECK-NOT: "vcd_name":"instA"
  // CHECK-NOT: "vcd_name":"instAVerilog"
  // CHECK: "vcd_name":"wireA"
  %0 = hw.instance "instA" @SingleResult() -> (outPort: i1) {hw.verilogName = "instAVerilog"}
  dbg.variable "varA", %0 : i1
  %wireA = hw.wire %0 : i1

  // Use SV declarations to refer to instance output.
  // CHECK: "hw_type":"logic","name":"varB"
  // CHECK-NOT: "vcd_name":"instB"
  // CHECK-NOT: "field":"outPort"
  // CHECK: "vcd_name":"wireB"
  %b = hw.instance "instB" @SingleResult() -> (outPort: i1)
  dbg.variable "varB", %b : i1
  %wireB = sv.wire : !hw.inout<i1>
  sv.assign %wireB, %b : i1
  // CHECK: "hw_type":"logic","name":"varC"
  // CHECK-NOT: "vcd_name":"instC"
  // CHECK-NOT: "field":"outPort"
  // CHECK: "vcd_name":"wireC"
  %c = hw.instance "instC" @SingleResult() -> (outPort: i1)
  dbg.variable "varC", %c : i1
  %wireC = sv.logic : !hw.inout<i1>
  sv.assign %wireC, %c : i1
  // CHECK: "hw_type":"logic","name":"varD"
  // CHECK-NOT: "vcd_name":"instD"
  // CHECK-NOT: "field":"outPort"
  // CHECK: "vcd_name":"wireD"
  %d = hw.instance "instD" @SingleResult() -> (outPort: i1)
  dbg.variable "varD", %d : i1
  %wireD = sv.logic : !hw.inout<i1>
  sv.assign %wireD, %d : i1

  // Use module's output port name to refer to instance output.
  // CHECK: "hw_type":"logic","name":"varZ"
  // CHECK-NOT: "vcd_name":"instZ"
  // CHECK-NOT: "field":"outPort"
  // CHECK: "vcd_name":"someOutput"
  %z = hw.instance "instZ" @SingleResult() -> (outPort: i1)
  dbg.variable "varZ", %z : i1
  hw.output %z : i1
}

// CHECK-LABEL: "verilog_name": "Issue6735_Case2"
hw.module @Issue6735_Case2(out x : i36, out y : i36 {hw.verilogName = "verilogY"}) {
  %a, %b = hw.instance "bar" @MultipleResults() -> (a: i36, b: i36)
  // CHECK: "hw_type":"logic","name":"portA"
  // CHECK-NOT: "field":"a"
  // CHECK-NOT: "var_ref":
  // CHECK-NOT: "vcd_name":"bar"
  // CHECK: "vcd_name":"x"
  dbg.variable "portA", %a : i36
  // CHECK: "hw_type":"logic","name":"portB"
  // CHECK-NOT: "field":"b"
  // CHECK-NOT: "var_ref":
  // CHECK-NOT: "vcd_name":"bar"
  // CHECK: "vcd_name":"verilogY"
  dbg.variable "portB", %b : i36
  hw.output %a, %b : i36, i36
}
hw.module.extern @MultipleResults(out a : i36, out b : i36)

// CHECK-LABEL: "verilog_name": "Issue6749"
hw.module @Issue6749(in %a: i42) {
  // Variables with empty names must have a non-empty name in the output.
  // CHECK-NOT: "name": ""
  dbg.variable "", %a : i42

  // Uniquify duplicate variable names.
  // CHECK: "hw_type":"logic","name":"myVar"
  // CHECK-NOT: "name":"myVar"
  // CHECK: "name":"myVar_0"
  dbg.variable "myVar", %a : i42
  dbg.variable "myVar", %a : i42

  // Uniquify Verilog keyword collisions.
  // CHECK-NOT: "hw_type":"logic","name":"signed"
  // CHECK: "hw_type":"logic","name":"signed_0"
  dbg.variable "signed", %a : i42

  // Scopes with empty names must have a non-empty name in the output.
  // CHECK: "child_scopes": [
  // CHECK-NOT: "name": ""
  %scope = dbg.scope "", "SomeScope"
}

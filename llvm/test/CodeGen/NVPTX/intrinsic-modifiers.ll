; RUN: opt -S -p verify < %s | FileCheck %s


; CHECK: @test_mods
define void @test_mods(float %f, half %h) {
  ; Parsing syntax with explicit mod args.
  ; CHECK:  call void @llvm.nvvm.float.op0.noftz.rup(float %f)
  call void @llvm.nvvm.float.op0(float %f, i1 0, i16 3)

  ; CHECK: call void @llvm.nvvm.float.op1.ftz.rup(float %f)
  ; 0x103 = 259 = .ftz.rup
  call void @llvm.nvvm.float.op1(i32 259, float %f)

  ; Parsing syntax with modifiers.
  ; CHECK: call void @llvm.nvvm.float.op0.noftz.rdn(float %f)
  call void @llvm.nvvm.float.op0.noftz.rdn(float %f)

  ; CHECK: call void @llvm.nvvm.float.op1.ftz.rtz(float %f)
  call void @llvm.nvvm.float.op1.ftz.rtz(float %f)

  ; overloaded with modifiers.
  ; CHECK: call void @llvm.nvvm.float.op2.ftz.rup.f32(float %f)
  ; CHECK: call void @llvm.nvvm.float.op2.ftz.rup.f16(half %h)
  call void @llvm.nvvm.float.op2(i32 259, float %f)
  call void @llvm.nvvm.float.op2(i32 259, half %h)

  ; overloaded no modifiers
  ; CHECK: call void @llvm.nvvm.float.op3.f32(float %f)
  ; CHECK: call void @llvm.nvvm.float.op3.f16(half %h)
  call void @llvm.nvvm.float.op3.f32(float %f)
  call void @llvm.nvvm.float.op3.f16(half %h)
  
  ret void
}


; declaration will spell out all arguments.
; These are non-overloaded intrinsics with modifiers.
declare void @llvm.nvvm.float.op0(float, i1, i16)
declare void @llvm.nvvm.float.op1(i32, float)

; Overloaded intrinsics with modifiers.
declare void @llvm.nvvm.float.op2.f32(i32, float)
declare void @llvm.nvvm.float.op2.f16(i32, half)

; Overloaded no modifiers
; declare void @llvm.nvvm.float.op3.f32(float)
declare void @llvm.nvvm.float.op3.f16(half)

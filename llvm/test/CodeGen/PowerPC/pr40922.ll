; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 2
; RUN: llc -verify-machineinstrs -mtriple=powerpc-unknown-linux-gnu < %s | FileCheck %s

; Test case adapted from PR40922.

@a.b = internal global i32 0, align 4

define i32 @a() {
; CHECK-LABEL: a:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    mflr 0
; CHECK-NEXT:    stwu 1, -32(1)
; CHECK-NEXT:    stw 0, 36(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 32
; CHECK-NEXT:    .cfi_offset lr, 4
; CHECK-NEXT:    .cfi_offset r29, -12
; CHECK-NEXT:    .cfi_offset r30, -8
; CHECK-NEXT:    stw 29, 20(1) # 4-byte Folded Spill
; CHECK-NEXT:    stw 30, 24(1) # 4-byte Folded Spill
; CHECK-NEXT:    bl d
; CHECK-NEXT:    lis 29, a.b@ha
; CHECK-NEXT:    lwz 4, a.b@l(29)
; CHECK-NEXT:    li 5, 0
; CHECK-NEXT:    mr 30, 3
; CHECK-NEXT:    addic 6, 4, 6
; CHECK-NEXT:    addze. 5, 5
; CHECK-NEXT:    rlwinm 5, 6, 0, 28, 26
; CHECK-NEXT:    cmplw 1, 5, 4
; CHECK-NEXT:    crnand 20, 4, 2
; CHECK-NEXT:    bc 12, 20, .LBB0_2
; CHECK-NEXT:  # %bb.1: # %if.then
; CHECK-NEXT:    bl e
; CHECK-NEXT:  .LBB0_2: # %if.end
; CHECK-NEXT:    stw 30, a.b@l(29)
; CHECK-NEXT:    lwz 30, 24(1) # 4-byte Folded Reload
; CHECK-NEXT:    lwz 29, 20(1) # 4-byte Folded Reload
; CHECK-NEXT:    lwz 0, 36(1)
; CHECK-NEXT:    addi 1, 1, 32
; CHECK-NEXT:    mtlr 0
; CHECK-NEXT:    blr
entry:
  %call = tail call i32 @d()
  %0 = load i32, ptr @a.b, align 4
  %conv = zext i32 %0 to i64
  %add = add nuw nsw i64 %conv, 6
  %and = and i64 %add, 8589934575
  %cmp = icmp ult i64 %and, %conv
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  %call3 = tail call i32 @e()
  br label %if.end

if.end:                                           ; preds = %if.then, %entry
  store i32 %call, ptr @a.b, align 4
  ret i32 undef
}

declare i32 @d(...)

declare i32 @e(...)

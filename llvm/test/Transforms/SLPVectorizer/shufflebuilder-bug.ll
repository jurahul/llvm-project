; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 2
; RUN: %if x86-registered-target %{ opt -S -p slp-vectorizer -mtriple=x86_64-- %s | FileCheck %s %}
; RUN: %if aarch64-registered-target %{ opt -S -p slp-vectorizer -mtriple=aarch64-unknown-linux-gnu %s | FileCheck %s %}

define void @foo(<4 x float> %vec, float %val, ptr %ptr) {
; CHECK-LABEL: define void @foo
; CHECK-SAME: (<4 x float> [[VEC:%.*]], float [[VAL:%.*]], ptr [[PTR:%.*]]) {
; CHECK-NEXT:    [[GEP0:%.*]] = getelementptr inbounds float, ptr [[PTR]], i64 0
; CHECK-NEXT:    [[TMP1:%.*]] = load <4 x float>, ptr [[GEP0]], align 8
; CHECK-NEXT:    [[TMP2:%.*]] = shufflevector <4 x float> [[VEC]], <4 x float> poison, <2 x i32> <i32 3, i32 poison>
; CHECK-NEXT:    [[TMP3:%.*]] = insertelement <2 x float> [[TMP2]], float [[VAL]], i32 1
; CHECK-NEXT:    [[TMP4:%.*]] = shufflevector <2 x float> [[TMP3]], <2 x float> poison, <4 x i32> <i32 0, i32 0, i32 1, i32 1>
; CHECK-NEXT:    [[TMP5:%.*]] = fadd <4 x float> [[TMP1]], [[TMP4]]
; CHECK-NEXT:    [[TMP6:%.*]] = fmul <4 x float> [[TMP5]], [[TMP4]]
; CHECK-NEXT:    store <4 x float> [[TMP6]], ptr [[GEP0]], align 4
; CHECK-NEXT:    ret void
;
  %vec_3 = extractelement <4 x float> %vec, i32 3

  %gep0 = getelementptr inbounds float, ptr %ptr, i64 0
  %gep1 = getelementptr inbounds float, ptr %ptr, i64 1
  %gep2 = getelementptr inbounds float, ptr %ptr, i64 2
  %gep3 = getelementptr inbounds float, ptr %ptr, i64 3

  %l0 = load float, ptr %gep0, align 8
  %l1 = load float, ptr %gep1, align 8
  %l2 = load float, ptr %gep2, align 8
  %l3 = load float, ptr %gep3, align 8

  %fadd0 = fadd float %l0, %vec_3
  %fadd1 = fadd float %l1, %vec_3
  %fadd2 = fadd float %l2, %val
  %fadd3 = fadd float %l3, %val

  %fmul0 = fmul float %fadd0, %vec_3
  %fmul1 = fmul float %fadd1, %vec_3
  %fmul2 = fmul float %fadd2, %val
  %fmul3 = fmul float %fadd3, %val

  store float %fmul0, ptr %gep0, align 4
  store float %fmul1, ptr %gep1, align 4
  store float %fmul2, ptr %gep2, align 4
  store float %fmul3, ptr %gep3, align 4
  ret void
}

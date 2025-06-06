; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -S -passes=sccp %s | FileCheck %s

declare void @use(i1)

define void @and_range_limit(i64 %a) {
; CHECK-LABEL: @and_range_limit(
; CHECK-NEXT:    [[R:%.*]] = and i64 [[A:%.*]], 255
; CHECK-NEXT:    [[C_0:%.*]] = icmp slt i64 [[R]], 15
; CHECK-NEXT:    call void @use(i1 [[C_0]])
; CHECK-NEXT:    call void @use(i1 true)
; CHECK-NEXT:    [[C_2:%.*]] = icmp eq i64 [[R]], 100
; CHECK-NEXT:    call void @use(i1 [[C_2]])
; CHECK-NEXT:    call void @use(i1 false)
; CHECK-NEXT:    [[C_4:%.*]] = icmp ne i64 [[R]], 100
; CHECK-NEXT:    call void @use(i1 [[C_4]])
; CHECK-NEXT:    call void @use(i1 true)
; CHECK-NEXT:    ret void
;
  %r = and i64 %a, 255
  %c.0 = icmp slt i64 %r, 15
  call void @use(i1 %c.0)
  %c.1 = icmp slt i64 %r, 256
  call void @use(i1 %c.1)
  %c.2 = icmp eq i64 %r, 100
  call void @use(i1 %c.2)
  %c.3 = icmp eq i64 %r, 300
  call void @use(i1 %c.3)
  %c.4 = icmp ne i64 %r, 100
  call void @use(i1 %c.4)
  %c.5 = icmp ne i64 %r, 300
  call void @use(i1 %c.5)
  ret void
}

; Below are test cases for PR44949.

; We can remove `%res = and i64 %p, 255`, because %r = 0 and we can eliminate
; %p as well.
define i64 @constant_and_undef(i1 %c1, i64 %a) {
; CHECK-LABEL: @constant_and_undef(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C1:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    br label [[BB3:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    br label [[BB3]]
; CHECK:       bb3:
; CHECK-NEXT:    ret i64 0
;
entry:
  br i1 %c1, label %bb1, label %bb2

bb1:
  br label %bb3

bb2:
  %r = and i64 %a, 0
  br label %bb3

bb3:
  %p = phi i64 [ undef, %bb1 ], [ %r, %bb2 ]
  %res = and i64 %p, 255
  ret i64 %res
}

; Check that we go to overdefined when merging a constant range with undef. We
; cannot remove '%res = and i64 %p, 255'.
define i64 @constant_range_and_undef(i1 %cond, i64 %a) {
; CHECK-LABEL: @constant_range_and_undef(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[COND:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    br label [[BB3:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    [[R:%.*]] = and i64 [[A:%.*]], 255
; CHECK-NEXT:    br label [[BB3]]
; CHECK:       bb3:
; CHECK-NEXT:    [[P:%.*]] = phi i64 [ undef, [[BB1]] ], [ [[R]], [[BB2]] ]
; CHECK-NEXT:    [[RES:%.*]] = and i64 [[P]], 255
; CHECK-NEXT:    ret i64 [[RES]]
;
entry:
  br i1 %cond, label %bb1, label %bb2

bb1:
  br label %bb3

bb2:
  %r = and i64 %a, 255
  br label %bb3

bb3:
  %p = phi i64 [ undef, %bb1 ], [ %r, %bb2 ]
  %res = and i64 %p, 255
  ret i64 %res
}

; Same as @constant_range_and_undef, with the undef coming from the other
; block.
define i64 @constant_range_and_undef_switched_incoming(i1 %cond, i64 %a) {
; CHECK-LABEL: @constant_range_and_undef_switched_incoming(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[COND:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    [[R:%.*]] = and i64 [[A:%.*]], 255
; CHECK-NEXT:    br label [[BB3:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    br label [[BB3]]
; CHECK:       bb3:
; CHECK-NEXT:    [[P:%.*]] = phi i64 [ [[R]], [[BB1]] ], [ undef, [[BB2]] ]
; CHECK-NEXT:    [[RES:%.*]] = and i64 [[P]], 255
; CHECK-NEXT:    ret i64 [[RES]]
;
entry:
  br i1 %cond, label %bb1, label %bb2

bb1:
  %r = and i64 %a, 255
  br label %bb3

bb2:
  br label %bb3

bb3:
  %p = phi i64 [ %r, %bb1 ], [ undef, %bb2 ]
  %res = and i64 %p, 255
  ret i64 %res
}

define i64 @constant_range_and_255_100(i1 %cond, i64 %a) {
; CHECK-LABEL: @constant_range_and_255_100(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[COND:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    [[R_1:%.*]] = and i64 [[A:%.*]], 100
; CHECK-NEXT:    br label [[BB3:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    [[R_2:%.*]] = and i64 [[A]], 255
; CHECK-NEXT:    br label [[BB3]]
; CHECK:       bb3:
; CHECK-NEXT:    [[P:%.*]] = phi i64 [ [[R_1]], [[BB1]] ], [ [[R_2]], [[BB2]] ]
; CHECK-NEXT:    call void @use(i1 true)
; CHECK-NEXT:    ret i64 [[P]]
;
entry:
  br i1 %cond, label %bb1, label %bb2

bb1:
  %r.1 = and i64 %a, 100
  br label %bb3

bb2:
  %r.2 = and i64 %a, 255
  br label %bb3

bb3:
  %p = phi i64 [ %r.1, %bb1 ], [ %r.2, %bb2 ]
  %p.and = and i64 %p, 255
  %c = icmp ult i64 %p.and, 256
  call void @use(i1 %c)
  ret i64 %p.and
}


define i64 @constant_range_and_undef2(i1 %c1, i1 %c2, i64 %a) {
; CHECK-LABEL: @constant_range_and_undef2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C1:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    [[V1:%.*]] = add i64 undef, undef
; CHECK-NEXT:    br label [[BB3:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    [[V2:%.*]] = and i64 [[A:%.*]], 255
; CHECK-NEXT:    br label [[BB3]]
; CHECK:       bb3:
; CHECK-NEXT:    [[P:%.*]] = phi i64 [ [[V1]], [[BB1]] ], [ [[V2]], [[BB2]] ]
; CHECK-NEXT:    br i1 [[C2:%.*]], label [[BB4:%.*]], label [[BB5:%.*]]
; CHECK:       bb4:
; CHECK-NEXT:    br label [[BB6:%.*]]
; CHECK:       bb5:
; CHECK-NEXT:    [[V3:%.*]] = and i64 [[A]], 255
; CHECK-NEXT:    br label [[BB6]]
; CHECK:       bb6:
; CHECK-NEXT:    [[P2:%.*]] = phi i64 [ [[P]], [[BB4]] ], [ [[V3]], [[BB5]] ]
; CHECK-NEXT:    [[RES:%.*]] = and i64 [[P2]], 255
; CHECK-NEXT:    ret i64 [[RES]]
;
entry:
  br i1 %c1, label %bb1, label %bb2

bb1:
  %v1 = add i64 undef, undef
  br label %bb3

bb2:
  %v2 = and i64 %a, 255
  br label %bb3

bb3:
  %p = phi i64 [ %v1, %bb1 ], [ %v2, %bb2 ]
  br i1 %c2, label %bb4, label %bb5

bb4:
  br label %bb6

bb5:
  %v3 = and i64 %a, 255
  br label %bb6

bb6:
  %p2 = phi i64 [ %p, %bb4 ], [ %v3, %bb5 ]
  %res = and i64 %p2, 255
  ret i64 %res
}

define i1 @constant_range_and_undef_3(i1 %cond, i64 %a) {
; CHECK-LABEL: @constant_range_and_undef_3(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[COND:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    br label [[BB3:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    [[R:%.*]] = and i64 [[A:%.*]], 255
; CHECK-NEXT:    br label [[BB3]]
; CHECK:       bb3:
; CHECK-NEXT:    [[P:%.*]] = phi i64 [ undef, [[BB1]] ], [ [[R]], [[BB2]] ]
; CHECK-NEXT:    ret i1 true
;
entry:
  br i1 %cond, label %bb1, label %bb2

bb1:
  br label %bb3

bb2:
  %r = and i64 %a, 255
  br label %bb3

bb3:
  %p = phi i64 [ undef, %bb1 ], [ %r, %bb2 ]
  %c = icmp ult i64 %p, 256
  ret i1 %c
}

define i1 @constant_range_and_undef_3_switched_incoming(i1 %cond, i64 %a) {
; CHECK-LABEL: @constant_range_and_undef_3_switched_incoming(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[COND:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    [[R:%.*]] = and i64 [[A:%.*]], 255
; CHECK-NEXT:    br label [[BB3:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    br label [[BB3]]
; CHECK:       bb3:
; CHECK-NEXT:    [[P:%.*]] = phi i64 [ [[R]], [[BB1]] ], [ undef, [[BB2]] ]
; CHECK-NEXT:    ret i1 true
;
entry:
  br i1 %cond, label %bb1, label %bb2

bb1:
  %r = and i64 %a, 255
  br label %bb3

bb2:
  br label %bb3

bb3:
  %p = phi i64 [ %r, %bb1 ], [ undef, %bb2 ]
  %c = icmp ult i64 %p, 256
  ret i1 %c
}

; Same as @constant_range_and_undef, but with 3 incoming
; values: undef, a constant and a constant range.
define i64 @constant_range_and_undef_3_incoming_v1(i1 %c1, i1 %c2, i64 %a) {
; CHECK-LABEL: @constant_range_and_undef_3_incoming_v1(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C1:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    [[R:%.*]] = and i64 [[A:%.*]], 255
; CHECK-NEXT:    br label [[BB4:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    br i1 [[C2:%.*]], label [[BB3:%.*]], label [[BB4]]
; CHECK:       bb3:
; CHECK-NEXT:    br label [[BB4]]
; CHECK:       bb4:
; CHECK-NEXT:    [[P:%.*]] = phi i64 [ [[R]], [[BB1]] ], [ 10, [[BB2]] ], [ undef, [[BB3]] ]
; CHECK-NEXT:    [[RES:%.*]] = and i64 [[P]], 255
; CHECK-NEXT:    ret i64 [[RES]]
;
entry:
  br i1 %c1, label %bb1, label %bb2

bb1:
  %r = and i64 %a, 255
  br label %bb4

bb2:
  br i1 %c2, label %bb3, label %bb4

bb3:
  br label %bb4

bb4:
  %p = phi i64 [ %r, %bb1 ], [ 10, %bb2], [ undef, %bb3 ]
  %res = and i64 %p, 255
  ret i64 %res
}

; Same as @constant_range_and_undef_3_incoming_v1, but with different order of
; incoming values.
define i64 @constant_range_and_undef_3_incoming_v2(i1 %c1, i1 %c2, i64 %a) {
; CHECK-LABEL: @constant_range_and_undef_3_incoming_v2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C1:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    br label [[BB4:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    br i1 [[C2:%.*]], label [[BB3:%.*]], label [[BB4]]
; CHECK:       bb3:
; CHECK-NEXT:    [[R:%.*]] = and i64 [[A:%.*]], 255
; CHECK-NEXT:    br label [[BB4]]
; CHECK:       bb4:
; CHECK-NEXT:    [[P:%.*]] = phi i64 [ undef, [[BB1]] ], [ 10, [[BB2]] ], [ [[R]], [[BB3]] ]
; CHECK-NEXT:    [[RES:%.*]] = and i64 [[P]], 255
; CHECK-NEXT:    ret i64 [[RES]]
;
entry:
  br i1 %c1, label %bb1, label %bb2

bb1:
  br label %bb4

bb2:
  br i1 %c2, label %bb3, label %bb4

bb3:
  %r = and i64 %a, 255
  br label %bb4

bb4:
  %p = phi i64 [ undef, %bb1 ], [ 10, %bb2], [ %r, %bb3 ]
  %res = and i64 %p, 255
  ret i64 %res
}

; Same as @constant_range_and_undef_3_incoming_v1, but with different order of
; incoming values.
define i64 @constant_range_and_undef_3_incoming_v3(i1 %c1, i1 %c2, i64 %a) {
; CHECK-LABEL: @constant_range_and_undef_3_incoming_v3(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C1:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    [[R:%.*]] = and i64 [[A:%.*]], 255
; CHECK-NEXT:    br label [[BB4:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    br i1 [[C2:%.*]], label [[BB3:%.*]], label [[BB4]]
; CHECK:       bb3:
; CHECK-NEXT:    br label [[BB4]]
; CHECK:       bb4:
; CHECK-NEXT:    [[P:%.*]] = phi i64 [ [[R]], [[BB1]] ], [ undef, [[BB2]] ], [ 10, [[BB3]] ]
; CHECK-NEXT:    [[RES:%.*]] = and i64 [[P]], 255
; CHECK-NEXT:    ret i64 [[RES]]
;
entry:
  br i1 %c1, label %bb1, label %bb2

bb1:
  %r = and i64 %a, 255
  br label %bb4

bb2:
  br i1 %c2, label %bb3, label %bb4

bb3:
  br label %bb4

bb4:
  %p = phi i64 [ %r, %bb1 ], [ undef, %bb2], [ 10, %bb3 ]
  %res = and i64 %p, 255
  ret i64 %res
}


define i64 @constant_range_and_phi_constant_undef(i1 %c1, i1 %c2, i64 %a) {
; CHECK-LABEL: @constant_range_and_phi_constant_undef(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C1:%.*]], label [[BB1:%.*]], label [[BB2:%.*]]
; CHECK:       bb1:
; CHECK-NEXT:    [[R:%.*]] = and i64 [[A:%.*]], 255
; CHECK-NEXT:    br label [[BB5:%.*]]
; CHECK:       bb2:
; CHECK-NEXT:    br i1 [[C2:%.*]], label [[BB3:%.*]], label [[BB4:%.*]]
; CHECK:       bb3:
; CHECK-NEXT:    br label [[BB4]]
; CHECK:       bb4:
; CHECK-NEXT:    br label [[BB5]]
; CHECK:       bb5:
; CHECK-NEXT:    [[P:%.*]] = phi i64 [ [[R]], [[BB1]] ], [ 10, [[BB4]] ]
; CHECK-NEXT:    [[RES:%.*]] = and i64 [[P]], 255
; CHECK-NEXT:    ret i64 [[RES]]
;
entry:
  br i1 %c1, label %bb1, label %bb2

bb1:
  %r = and i64 %a, 255
  br label %bb5

bb2:
  br i1 %c2, label %bb3, label %bb4

bb3:
  br label %bb4

bb4:
  %p.1 = phi i64 [ 10, %bb2 ], [ undef, %bb3]
  br label %bb5

bb5:
  %p = phi i64 [ %r, %bb1 ], [ %p.1, %bb4]
  %res = and i64 %p, 255
  ret i64 %res
}

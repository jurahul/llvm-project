// RUN: mlir-translate -mlir-to-llvmir -split-input-file %s | FileCheck %s

// CHECK-LABEL: define void @test_stand_alone_directives()
llvm.func @test_stand_alone_directives() {
  // CHECK: [[OMP_THREAD:%.*]] = call i32 @__kmpc_global_thread_num(ptr @{{[0-9]+}})
  // CHECK-NEXT:  call void @__kmpc_barrier(ptr @{{[0-9]+}}, i32 [[OMP_THREAD]])
  omp.barrier

  // CHECK: [[OMP_THREAD1:%.*]] = call i32 @__kmpc_global_thread_num(ptr @{{[0-9]+}})
  // CHECK-NEXT:  [[RET_VAL:%.*]] = call i32 @__kmpc_omp_taskwait(ptr @{{[0-9]+}}, i32 [[OMP_THREAD1]])
  omp.taskwait

  // CHECK: [[OMP_THREAD2:%.*]] = call i32 @__kmpc_global_thread_num(ptr @{{[0-9]+}})
  // CHECK-NEXT:  [[RET_VAL:%.*]] = call i32 @__kmpc_omp_taskyield(ptr @{{[0-9]+}}, i32 [[OMP_THREAD2]], i32 0)
  omp.taskyield

  // CHECK-NEXT:    ret void
  llvm.return
}

// CHECK-LABEL: define void @test_flush_construct(ptr %{{[0-9]+}})
llvm.func @test_flush_construct(%arg0: !llvm.ptr) {
  // CHECK: call void @__kmpc_flush(ptr @{{[0-9]+}}
  omp.flush

  // CHECK: call void @__kmpc_flush(ptr @{{[0-9]+}}
  omp.flush (%arg0 : !llvm.ptr)

  // CHECK: call void @__kmpc_flush(ptr @{{[0-9]+}}
  omp.flush (%arg0, %arg0 : !llvm.ptr, !llvm.ptr)

  %0 = llvm.mlir.constant(1 : i64) : i64
  //  CHECK: alloca {{.*}} align 4
  %1 = llvm.alloca %0 x i32 {in_type = i32, name = "a"} : (i64) -> !llvm.ptr
  // CHECK: call void @__kmpc_flush(ptr @{{[0-9]+}}
  omp.flush
  //  CHECK: load i32, ptr
  %2 = llvm.load %1 : !llvm.ptr -> i32

  // CHECK-NEXT:    ret void
  llvm.return
}

// CHECK-LABEL: define void @test_omp_parallel_1()
llvm.func @test_omp_parallel_1() -> () {
  // CHECK: call void{{.*}}@__kmpc_fork_call{{.*}}@[[OMP_OUTLINED_FN_1:.*]])
  omp.parallel {
    omp.barrier
    omp.terminator
  }

  llvm.return
}

// CHECK: define internal void @[[OMP_OUTLINED_FN_1]]
  // CHECK: call void @__kmpc_barrier

llvm.func @body(i64)

// CHECK-LABEL: define void @test_omp_parallel_2()
llvm.func @test_omp_parallel_2() -> () {
  // CHECK: call void{{.*}}@__kmpc_fork_call{{.*}}@[[OMP_OUTLINED_FN_2:.*]])
  omp.parallel {
    ^bb0:
      %0 = llvm.mlir.constant(1 : index) : i64
      %1 = llvm.mlir.constant(42 : index) : i64
      llvm.call @body(%0) : (i64) -> ()
      llvm.call @body(%1) : (i64) -> ()
      llvm.br ^bb1

    ^bb1:
      %2 = llvm.add %0, %1 : i64
      llvm.call @body(%2) : (i64) -> ()
      omp.terminator
  }
  llvm.return
}

// CHECK: define internal void @[[OMP_OUTLINED_FN_2]]
  // CHECK-LABEL: omp.par.region:
  // CHECK: br label %omp.par.region1
  // CHECK-LABEL: omp.par.region1:
  // CHECK: call void @body(i64 1)
  // CHECK: call void @body(i64 42)
  // CHECK: br label %omp.par.region2
  // CHECK-LABEL: omp.par.region2:
  // CHECK: call void @body(i64 43)
  // CHECK: br label %omp.par.pre_finalize

// CHECK: define void @test_omp_parallel_num_threads_1(i32 %[[NUM_THREADS_VAR_1:.*]])
llvm.func @test_omp_parallel_num_threads_1(%arg0: i32) -> () {
  // CHECK: %[[GTN_NUM_THREADS_VAR_1:.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GTN_SI_VAR_1:.*]])
  // CHECK: call void @__kmpc_push_num_threads(ptr @[[GTN_SI_VAR_1]], i32 %[[GTN_NUM_THREADS_VAR_1]], i32 %[[NUM_THREADS_VAR_1]])
  // CHECK: call void{{.*}}@__kmpc_fork_call{{.*}}@[[OMP_OUTLINED_FN_NUM_THREADS_1:.*]])
  omp.parallel num_threads(%arg0: i32) {
    omp.barrier
    omp.terminator
  }

  llvm.return
}

// CHECK: define internal void @[[OMP_OUTLINED_FN_NUM_THREADS_1]]
  // CHECK: call void @__kmpc_barrier

// CHECK: define void @test_omp_parallel_num_threads_2()
llvm.func @test_omp_parallel_num_threads_2() -> () {
  %0 = llvm.mlir.constant(4 : index) : i32
  // CHECK: %[[GTN_NUM_THREADS_VAR_2:.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GTN_SI_VAR_2:.*]])
  // CHECK: call void @__kmpc_push_num_threads(ptr @[[GTN_SI_VAR_2]], i32 %[[GTN_NUM_THREADS_VAR_2]], i32 4)
  // CHECK: call void{{.*}}@__kmpc_fork_call{{.*}}@[[OMP_OUTLINED_FN_NUM_THREADS_2:.*]])
  omp.parallel num_threads(%0: i32) {
    omp.barrier
    omp.terminator
  }

  llvm.return
}

// CHECK: define internal void @[[OMP_OUTLINED_FN_NUM_THREADS_2]]
  // CHECK: call void @__kmpc_barrier

// CHECK: define void @test_omp_parallel_num_threads_3()
llvm.func @test_omp_parallel_num_threads_3() -> () {
  %0 = llvm.mlir.constant(4 : index) : i32
  // CHECK: %[[GTN_NUM_THREADS_VAR_3_1:.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GTN_SI_VAR_3_1:.*]])
  // CHECK: call void @__kmpc_push_num_threads(ptr @[[GTN_SI_VAR_3_1]], i32 %[[GTN_NUM_THREADS_VAR_3_1]], i32 4)
  // CHECK: call void{{.*}}@__kmpc_fork_call{{.*}}@[[OMP_OUTLINED_FN_NUM_THREADS_3_1:.*]])
  omp.parallel num_threads(%0: i32) {
    omp.barrier
    omp.terminator
  }
  %1 = llvm.mlir.constant(8 : index) : i32
  // CHECK: %[[GTN_NUM_THREADS_VAR_3_2:.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GTN_SI_VAR_3_2:.*]])
  // CHECK: call void @__kmpc_push_num_threads(ptr @[[GTN_SI_VAR_3_2]], i32 %[[GTN_NUM_THREADS_VAR_3_2]], i32 8)
  // CHECK: call void{{.*}}@__kmpc_fork_call{{.*}}@[[OMP_OUTLINED_FN_NUM_THREADS_3_2:.*]])
  omp.parallel num_threads(%1: i32) {
    omp.barrier
    omp.terminator
  }

  llvm.return
}

// CHECK: define internal void @[[OMP_OUTLINED_FN_NUM_THREADS_3_2]]
  // CHECK: call void @__kmpc_barrier

// CHECK: define internal void @[[OMP_OUTLINED_FN_NUM_THREADS_3_1]]
  // CHECK: call void @__kmpc_barrier

// CHECK: define void @test_omp_parallel_if_1(i32 %[[IF_EXPR_1:.*]])
llvm.func @test_omp_parallel_if_1(%arg0: i32) -> () {

  %0 = llvm.mlir.constant(0 : index) : i32
  %1 = llvm.icmp "slt" %arg0, %0 : i32
// CHECK: %[[IF_COND_VAR_1:.*]] = icmp slt i32 %[[IF_EXPR_1]], 0


// CHECK: %[[GTN_IF_1:.*]] = call i32 @__kmpc_global_thread_num(ptr @[[SI_VAR_IF_1:.*]])
// CHECK: br label %[[OUTLINED_CALL_IF_BLOCK_1:.*]]
// CHECK: [[OUTLINED_CALL_IF_BLOCK_1]]:
// CHECK: %[[I32_IF_COND_VAR_1:.*]] = sext i1 %[[IF_COND_VAR_1]] to i32
// CHECK: call void @__kmpc_fork_call_if(ptr @[[SI_VAR_IF_1]], i32 0, ptr @[[OMP_OUTLINED_FN_IF_1:.*]], i32 %[[I32_IF_COND_VAR_1]], ptr null)
// CHECK: br label %[[OUTLINED_EXIT_IF_1:.*]]
  omp.parallel if(%1) {
    omp.barrier
    omp.terminator
  }

// CHECK: [[OUTLINED_EXIT_IF_1]]:
// CHECK: ret void
  llvm.return
}

// CHECK: define internal void @[[OMP_OUTLINED_FN_IF_1]]
  // CHECK: call void @__kmpc_barrier

// -----

// CHECK-LABEL: define void @test_omp_parallel_attrs()
llvm.func @test_omp_parallel_attrs() -> () attributes {
  target_cpu = "x86-64",
  target_features = #llvm.target_features<["+mmx", "+sse"]>
} {
  // CHECK: call void{{.*}}@__kmpc_fork_call{{.*}}@[[OMP_OUTLINED_FN:.*]])
  omp.parallel {
    omp.barrier
    omp.terminator
  }

  llvm.return
}

// CHECK: define {{.*}} @[[OMP_OUTLINED_FN]]{{.*}} #[[ATTRS:[0-9]+]]
// CHECK: attributes #[[ATTRS]] = {
// CHECK-SAME: "target-cpu"="x86-64"
// CHECK-SAME: "target-features"="+mmx,+sse"

// -----

// CHECK-LABEL: define void @test_omp_parallel_3()
llvm.func @test_omp_parallel_3() -> () {
  // CHECK: [[OMP_THREAD_3_1:%.*]] = call i32 @__kmpc_global_thread_num(ptr @{{[0-9]+}})
  // CHECK: call void @__kmpc_push_proc_bind(ptr @{{[0-9]+}}, i32 [[OMP_THREAD_3_1]], i32 2)
  // CHECK: call void{{.*}}@__kmpc_fork_call{{.*}}@[[OMP_OUTLINED_FN_3_1:.*]])
  omp.parallel proc_bind(master) {
    omp.barrier
    omp.terminator
  }
  // CHECK: [[OMP_THREAD_3_2:%.*]] = call i32 @__kmpc_global_thread_num(ptr @{{[0-9]+}})
  // CHECK: call void @__kmpc_push_proc_bind(ptr @{{[0-9]+}}, i32 [[OMP_THREAD_3_2]], i32 3)
  // CHECK: call void{{.*}}@__kmpc_fork_call{{.*}}@[[OMP_OUTLINED_FN_3_2:.*]])
  omp.parallel proc_bind(close) {
    omp.barrier
    omp.terminator
  }
  // CHECK: [[OMP_THREAD_3_3:%.*]] = call i32 @__kmpc_global_thread_num(ptr @{{[0-9]+}})
  // CHECK: call void @__kmpc_push_proc_bind(ptr @{{[0-9]+}}, i32 [[OMP_THREAD_3_3]], i32 4)
  // CHECK: call void{{.*}}@__kmpc_fork_call{{.*}}@[[OMP_OUTLINED_FN_3_3:.*]])
  omp.parallel proc_bind(spread) {
    omp.barrier
    omp.terminator
  }

  llvm.return
}

// CHECK: define internal void @[[OMP_OUTLINED_FN_3_3]]
// CHECK: define internal void @[[OMP_OUTLINED_FN_3_2]]
// CHECK: define internal void @[[OMP_OUTLINED_FN_3_1]]

// CHECK-LABEL: define void @test_omp_parallel_4()
llvm.func @test_omp_parallel_4() -> () {
// CHECK: call void {{.*}}@__kmpc_fork_call{{.*}} @[[OMP_OUTLINED_FN_4_1:.*]])
// CHECK: define internal void @[[OMP_OUTLINED_FN_4_1]]
// CHECK: call void @__kmpc_barrier
// CHECK: call void {{.*}}@__kmpc_fork_call{{.*}} @[[OMP_OUTLINED_FN_4_1_1:.*]])
// CHECK: call void @__kmpc_barrier
  omp.parallel {
    omp.barrier

// CHECK: define internal void @[[OMP_OUTLINED_FN_4_1_1]]
// CHECK: call void @__kmpc_barrier
    omp.parallel {
      omp.barrier
      omp.terminator
    }

    omp.barrier
    omp.terminator
  }
  llvm.return
}

llvm.func @test_omp_parallel_5() -> () {
// CHECK: call void {{.*}}@__kmpc_fork_call{{.*}} @[[OMP_OUTLINED_FN_5_1:.*]])
// CHECK: define internal void @[[OMP_OUTLINED_FN_5_1]]
// CHECK: call void @__kmpc_barrier
// CHECK: call void {{.*}}@__kmpc_fork_call{{.*}} @[[OMP_OUTLINED_FN_5_1_1:.*]])
// CHECK: call void @__kmpc_barrier
  omp.parallel {
    omp.barrier

// CHECK: define internal void @[[OMP_OUTLINED_FN_5_1_1]]
    omp.parallel {
// CHECK: call void {{.*}}@__kmpc_fork_call{{.*}} @[[OMP_OUTLINED_FN_5_1_1_1:.*]])
// CHECK: define internal void @[[OMP_OUTLINED_FN_5_1_1_1]]
// CHECK: call void @__kmpc_barrier
      omp.parallel {
        omp.barrier
        omp.terminator
      }
      omp.terminator
    }

    omp.barrier
    omp.terminator
  }
  llvm.return
}

// CHECK-LABEL: define void @test_omp_master()
llvm.func @test_omp_master() -> () {
// CHECK: call void {{.*}}@__kmpc_fork_call{{.*}} @{{.*}})
// CHECK: omp.par.region1:
  omp.parallel {
    omp.master {
// CHECK: [[OMP_THREAD_3_4:%.*]] = call i32 @__kmpc_global_thread_num(ptr @{{[0-9]+}})
// CHECK: {{[0-9]+}} = call i32 @__kmpc_master(ptr @{{[0-9]+}}, i32 [[OMP_THREAD_3_4]])
// CHECK: omp.master.region
// CHECK: call void @__kmpc_end_master(ptr @{{[0-9]+}}, i32 [[OMP_THREAD_3_4]])
// CHECK: br label %omp_region.end
      omp.terminator
    }
    omp.terminator
  }
  omp.parallel {
    omp.parallel {
      omp.master {
        omp.terminator
      }
      omp.terminator
    }
    omp.terminator
  }
  llvm.return
}

// -----

// CHECK-LABEL: define void @test_omp_masked({{.*}})
llvm.func @test_omp_masked(%arg0: i32)-> () {
// CHECK: call void {{.*}}@__kmpc_fork_call{{.*}} @{{.*}})
// CHECK: omp.par.region1:
  omp.parallel {
    omp.masked filter(%arg0: i32) {
// CHECK: [[OMP_THREAD_3_4:%.*]] = call i32 @__kmpc_global_thread_num(ptr @{{[0-9]+}})
// CHECK: {{[0-9]+}} = call i32 @__kmpc_masked(ptr @{{[0-9]+}}, i32 [[OMP_THREAD_3_4]], i32 %{{[0-9]+}})
// CHECK: omp.masked.region
// CHECK: call void @__kmpc_end_masked(ptr @{{[0-9]+}}, i32 [[OMP_THREAD_3_4]])
// CHECK: br label %omp_region.end
      omp.terminator
    }
    omp.terminator
  }
  llvm.return
}

// -----

// CHECK: %struct.ident_t = type
// CHECK: @[[$loc:.*]] = private unnamed_addr constant {{.*}} c";unknown;unknown;{{[0-9]+}};{{[0-9]+}};;\00"
// CHECK: @[[$loc_struct:.*]] = private unnamed_addr constant %struct.ident_t {{.*}} @[[$loc]] {{.*}}

// CHECK-LABEL: @wsloop_simple
llvm.func @wsloop_simple(%arg0: !llvm.ptr) {
  %0 = llvm.mlir.constant(42 : index) : i64
  %1 = llvm.mlir.constant(10 : index) : i64
  %2 = llvm.mlir.constant(1 : index) : i64
  omp.parallel {
    "omp.wsloop"() ({
      omp.loop_nest (%arg1) : i64 = (%1) to (%0) step (%2) {
        // The form of the emitted IR is controlled by OpenMPIRBuilder and
        // tested there. Just check that the right functions are called.
        // CHECK: call i32 @__kmpc_global_thread_num
        // CHECK: call void @__kmpc_for_static_init_{{.*}}(ptr @[[$loc_struct]],
        %3 = llvm.mlir.constant(2.000000e+00 : f32) : f32
        %4 = llvm.getelementptr %arg0[%arg1] : (!llvm.ptr, i64) -> !llvm.ptr, f32
        llvm.store %3, %4 : f32, !llvm.ptr
        omp.yield
      }
      // CHECK: call void @__kmpc_for_static_fini(ptr @[[$loc_struct]],
    }) : () -> ()
    omp.terminator
  }
  llvm.return
}

// -----

// CHECK-LABEL: @wsloop_inclusive_1
llvm.func @wsloop_inclusive_1(%arg0: !llvm.ptr) {
  %0 = llvm.mlir.constant(42 : index) : i64
  %1 = llvm.mlir.constant(10 : index) : i64
  %2 = llvm.mlir.constant(1 : index) : i64
  // CHECK: store i64 31, ptr %{{.*}}upperbound
  "omp.wsloop"() ({
    omp.loop_nest (%arg1) : i64 = (%1) to (%0) step (%2) {
      %3 = llvm.mlir.constant(2.000000e+00 : f32) : f32
      %4 = llvm.getelementptr %arg0[%arg1] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      llvm.store %3, %4 : f32, !llvm.ptr
      omp.yield
    }
  }) : () -> ()
  llvm.return
}

// -----

// CHECK-LABEL: @wsloop_inclusive_2
llvm.func @wsloop_inclusive_2(%arg0: !llvm.ptr) {
  %0 = llvm.mlir.constant(42 : index) : i64
  %1 = llvm.mlir.constant(10 : index) : i64
  %2 = llvm.mlir.constant(1 : index) : i64
  // CHECK: store i64 32, ptr %{{.*}}upperbound
  "omp.wsloop"() ({
    omp.loop_nest (%arg1) : i64 = (%1) to (%0) inclusive step (%2) {
      %3 = llvm.mlir.constant(2.000000e+00 : f32) : f32
      %4 = llvm.getelementptr %arg0[%arg1] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      llvm.store %3, %4 : f32, !llvm.ptr
      omp.yield
    }
  }) : () -> ()
  llvm.return
}

// -----

llvm.func @body(i32)

// CHECK-LABEL: @test_omp_wsloop_static_defchunk
llvm.func @test_omp_wsloop_static_defchunk(%lb : i32, %ub : i32, %step : i32) -> () {
  omp.wsloop schedule(static) {
    omp.loop_nest (%iv) : i32 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_for_static_init_4u(ptr @{{.*}}, i32 %{{.*}}, i32 34, ptr %{{.*}}, ptr %{{.*}}, ptr %{{.*}}, ptr %{{.*}}, i32 1, i32 0)
      // CHECK: call void @__kmpc_for_static_fini
      llvm.call @body(%iv) : (i32) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i32)

// CHECK-LABEL: @test_omp_wsloop_static_1
llvm.func @test_omp_wsloop_static_1(%lb : i32, %ub : i32, %step : i32) -> () {
  %static_chunk_size = llvm.mlir.constant(1 : i32) : i32
  omp.wsloop schedule(static = %static_chunk_size : i32) {
    omp.loop_nest (%iv) : i32 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_for_static_init_4u(ptr @{{.*}}, i32 %{{.*}}, i32 33, ptr %{{.*}}, ptr %{{.*}}, ptr %{{.*}}, ptr %{{.*}}, i32 1, i32 1)
      // CHECK: call void @__kmpc_for_static_fini
      llvm.call @body(%iv) : (i32) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i32)

// CHECK-LABEL: @test_omp_wsloop_static_2
llvm.func @test_omp_wsloop_static_2(%lb : i32, %ub : i32, %step : i32) -> () {
  %static_chunk_size = llvm.mlir.constant(2 : i32) : i32
  omp.wsloop schedule(static = %static_chunk_size : i32) {
    omp.loop_nest (%iv) : i32 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_for_static_init_4u(ptr @{{.*}}, i32 %{{.*}}, i32 33, ptr %{{.*}}, ptr %{{.*}}, ptr %{{.*}}, ptr %{{.*}}, i32 1, i32 2)
      // CHECK: call void @__kmpc_for_static_fini
      llvm.call @body(%iv) : (i32) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_dynamic(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(dynamic) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step)  {
      // CHECK: call void @__kmpc_dispatch_init_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_dynamic_chunk_const(%lb : i64, %ub : i64, %step : i64) -> () {
  %chunk_size_const = llvm.mlir.constant(2 : i16) : i16
  omp.wsloop schedule(dynamic = %chunk_size_const : i16) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step)  {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 1073741859, i64 {{.*}}, i64 %{{.*}}, i64 {{.*}}, i64 2)
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i32)

llvm.func @test_omp_wsloop_dynamic_chunk_var(%lb : i32, %ub : i32, %step : i32) -> () {
  %1 = llvm.mlir.constant(1 : i64) : i64
  %chunk_size_alloca = llvm.alloca %1 x i16 {bindc_name = "chunk_size", in_type = i16, uniq_name = "_QFsub1Echunk_size"} : (i64) -> !llvm.ptr
  %chunk_size_var = llvm.load %chunk_size_alloca : !llvm.ptr -> i16
  omp.wsloop schedule(dynamic = %chunk_size_var : i16) {
    omp.loop_nest (%iv) : i32 = (%lb) to (%ub) step (%step) {
      // CHECK: %[[CHUNK_SIZE:.*]] = sext i16 %{{.*}} to i32
      // CHECK: call void @__kmpc_dispatch_init_4u(ptr @{{.*}}, i32 %{{.*}}, i32 1073741859, i32 {{.*}}, i32 %{{.*}}, i32 {{.*}}, i32 %[[CHUNK_SIZE]])
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_4u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i32) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i32)

llvm.func @test_omp_wsloop_dynamic_chunk_var2(%lb : i32, %ub : i32, %step : i32) -> () {
  %1 = llvm.mlir.constant(1 : i64) : i64
  %chunk_size_alloca = llvm.alloca %1 x i64 {bindc_name = "chunk_size", in_type = i64, uniq_name = "_QFsub1Echunk_size"} : (i64) -> !llvm.ptr
  %chunk_size_var = llvm.load %chunk_size_alloca : !llvm.ptr -> i64
  omp.wsloop schedule(dynamic = %chunk_size_var : i64) {
    omp.loop_nest (%iv) : i32 = (%lb) to (%ub) step (%step) {
      // CHECK: %[[CHUNK_SIZE:.*]] = trunc i64 %{{.*}} to i32
      // CHECK: call void @__kmpc_dispatch_init_4u(ptr @{{.*}}, i32 %{{.*}}, i32 1073741859, i32 {{.*}}, i32 %{{.*}}, i32 {{.*}}, i32 %[[CHUNK_SIZE]])
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_4u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i32) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i32)

llvm.func @test_omp_wsloop_dynamic_chunk_var3(%lb : i32, %ub : i32, %step : i32, %chunk_size : i32) -> () {
  omp.wsloop schedule(dynamic = %chunk_size : i32) {
    omp.loop_nest (%iv) : i32 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_4u(ptr @{{.*}}, i32 %{{.*}}, i32 1073741859, i32 {{.*}}, i32 %{{.*}}, i32 {{.*}}, i32 %{{.*}})
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_4u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i32) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_auto(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(auto) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_runtime(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(runtime) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_guided(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(guided) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_dynamic_nonmonotonic(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(dynamic, nonmonotonic) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 1073741859
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_dynamic_monotonic(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(dynamic, monotonic) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 536870947
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_runtime_simd(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(runtime, simd) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 1073741871
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_guided_simd(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(guided, simd) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 1073741870
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

// CHECK-LABEL: @simd_simple
llvm.func @simd_simple(%lb : i64, %ub : i64, %step : i64, %arg0: !llvm.ptr) {
  "omp.simd" () ({
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      %3 = llvm.mlir.constant(2.000000e+00 : f32) : f32
      // The form of the emitted IR is controlled by OpenMPIRBuilder and
      // tested there. Just check that the right metadata is added.
      // CHECK: llvm.access.group
      %4 = llvm.getelementptr %arg0[%iv] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      llvm.store %3, %4 : f32, !llvm.ptr
      omp.yield
    }
  }) : () -> ()

  llvm.return
}
// CHECK: llvm.loop.parallel_accesses
// CHECK-NEXT: llvm.loop.vectorize.enable

// -----

// CHECK-LABEL: @simd_simple_multiple
llvm.func @simd_simple_multiple(%lb1 : i64, %ub1 : i64, %step1 : i64, %lb2 : i64, %ub2 : i64, %step2 : i64, %arg0: !llvm.ptr, %arg1: !llvm.ptr) {
  omp.simd {
    omp.loop_nest (%iv1, %iv2) : i64 = (%lb1, %lb2) to (%ub1, %ub2) inclusive step (%step1, %step2) {
      %3 = llvm.mlir.constant(2.000000e+00 : f32) : f32
      // The form of the emitted IR is controlled by OpenMPIRBuilder and
      // tested there. Just check that the right metadata is added and collapsed
      // loop bound is generated (Collapse clause is represented as a loop with
      // list of indices, bounds and steps where the size of the list is equal
      // to the collapse value.)
      // CHECK: icmp slt i64
      // CHECK-COUNT-3: select
      // CHECK: %[[TRIPCOUNT0:.*]] = select
      // CHECK: br label %[[PREHEADER:.*]]
      // CHECK: [[PREHEADER]]:
      // CHECK: icmp slt i64
      // CHECK-COUNT-3: select
      // CHECK: %[[TRIPCOUNT1:.*]] = select
      // CHECK: mul nuw i64 %[[TRIPCOUNT0]], %[[TRIPCOUNT1]]
      // CHECK: br label %[[COLLAPSED_PREHEADER:.*]]
      // CHECK: [[COLLAPSED_PREHEADER]]:
      // CHECK: br label %[[COLLAPSED_HEADER:.*]]
      // CHECK: llvm.access.group
      // CHECK-NEXT: llvm.access.group
      %4 = llvm.getelementptr %arg0[%iv1] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      %5 = llvm.getelementptr %arg1[%iv2] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      llvm.store %3, %4 : f32, !llvm.ptr
      llvm.store %3, %5 : f32, !llvm.ptr
      omp.yield
    }
  }
  llvm.return
}
// CHECK: llvm.loop.parallel_accesses
// CHECK-NEXT: llvm.loop.vectorize.enable

// -----

// CHECK-LABEL: @simd_simple_multiple_simdlen
llvm.func @simd_simple_multiple_simdlen(%lb1 : i64, %ub1 : i64, %step1 : i64, %lb2 : i64, %ub2 : i64, %step2 : i64, %arg0: !llvm.ptr, %arg1: !llvm.ptr) {
  omp.simd simdlen(2) {
    omp.loop_nest (%iv1, %iv2) : i64 = (%lb1, %lb2) to (%ub1, %ub2) step (%step1, %step2) {
      %3 = llvm.mlir.constant(2.000000e+00 : f32) : f32
      // The form of the emitted IR is controlled by OpenMPIRBuilder and
      // tested there. Just check that the right metadata is added.
      // CHECK: llvm.access.group
      // CHECK-NEXT: llvm.access.group
      %4 = llvm.getelementptr %arg0[%iv1] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      %5 = llvm.getelementptr %arg1[%iv2] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      llvm.store %3, %4 : f32, !llvm.ptr
      llvm.store %3, %5 : f32, !llvm.ptr
      omp.yield
    }
  }
  llvm.return
}
// CHECK: llvm.loop.parallel_accesses
// CHECK-NEXT: llvm.loop.vectorize.enable
// CHECK-NEXT: llvm.loop.vectorize.width{{.*}}i64 2

// -----

// CHECK-LABEL: @simd_simple_multiple_safelen
llvm.func @simd_simple_multiple_safelen(%lb1 : i64, %ub1 : i64, %step1 : i64, %lb2 : i64, %ub2 : i64, %step2 : i64, %arg0: !llvm.ptr, %arg1: !llvm.ptr) {
  omp.simd safelen(2) {
    omp.loop_nest (%iv1, %iv2) : i64 = (%lb1, %lb2) to (%ub1, %ub2) step (%step1, %step2) {
      %3 = llvm.mlir.constant(2.000000e+00 : f32) : f32
      %4 = llvm.getelementptr %arg0[%iv1] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      %5 = llvm.getelementptr %arg1[%iv2] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      llvm.store %3, %4 : f32, !llvm.ptr
      llvm.store %3, %5 : f32, !llvm.ptr
      omp.yield
    }
  }
  llvm.return
}
// CHECK: llvm.loop.vectorize.enable
// CHECK-NEXT: llvm.loop.vectorize.width{{.*}}i64 2

// -----

// CHECK-LABEL: @simd_simple_multiple_simdlen_safelen
llvm.func @simd_simple_multiple_simdlen_safelen(%lb1 : i64, %ub1 : i64, %step1 : i64, %lb2 : i64, %ub2 : i64, %step2 : i64, %arg0: !llvm.ptr, %arg1: !llvm.ptr) {
  omp.simd simdlen(1) safelen(2) {
    omp.loop_nest (%iv1, %iv2) : i64 = (%lb1, %lb2) to (%ub1, %ub2) step (%step1, %step2) {
      %3 = llvm.mlir.constant(2.000000e+00 : f32) : f32
      %4 = llvm.getelementptr %arg0[%iv1] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      %5 = llvm.getelementptr %arg1[%iv2] : (!llvm.ptr, i64) -> !llvm.ptr, f32
      llvm.store %3, %4 : f32, !llvm.ptr
      llvm.store %3, %5 : f32, !llvm.ptr
      omp.yield
    }
  }
  llvm.return
}
// CHECK: llvm.loop.vectorize.enable
// CHECK-NEXT: llvm.loop.vectorize.width{{.*}}i64 1

// -----

// CHECK-LABEL: @simd_if
llvm.func @simd_if(%arg0: !llvm.ptr {fir.bindc_name = "n"}, %arg1: !llvm.ptr {fir.bindc_name = "threshold"}) {
  %0 = llvm.mlir.constant(1 : i64) : i64
  %1 = llvm.alloca %0 x i32 {adapt.valuebyref, in_type = i32, operandSegmentSizes = array<i32: 0, 0>} : (i64) -> !llvm.ptr
  %2 = llvm.mlir.constant(1 : i64) : i64
  %3 = llvm.alloca %2 x i32 {bindc_name = "i", in_type = i32, operandSegmentSizes = array<i32: 0, 0>, uniq_name = "_QFtest_simdEi"} : (i64) -> !llvm.ptr
  %4 = llvm.mlir.constant(0 : i32) : i32
  %5 = llvm.load %arg0 : !llvm.ptr -> i32
  %6 = llvm.mlir.constant(1 : i32) : i32
  %7 = llvm.load %arg0 : !llvm.ptr -> i32
  %8 = llvm.load %arg1 : !llvm.ptr -> i32
  %9 = llvm.icmp "sge" %7, %8 : i32
  omp.simd if(%9) {
    omp.loop_nest (%arg2) : i32 = (%4) to (%5) inclusive step (%6) {
      // The form of the emitted IR is controlled by OpenMPIRBuilder and
      // tested there. Just check that the right metadata is added.
      // CHECK: llvm.access.group
      llvm.store %arg2, %1 : i32, !llvm.ptr
      omp.yield
    }
  }
  llvm.return
}
// Be sure that llvm.loop.vectorize.enable metadata appears twice
// CHECK: llvm.loop.parallel_accesses

// -----

// CHECK-LABEL: @simd_order
llvm.func @simd_order() {
  %0 = llvm.mlir.constant(10 : i64) : i64
  %1 = llvm.mlir.constant(1 : i64) : i64
  %2 = llvm.alloca %1 x i64 : (i64) -> !llvm.ptr
  omp.simd order(concurrent) safelen(2) {
    omp.loop_nest (%arg0) : i64 = (%1) to (%0) inclusive step (%1) {
      llvm.store %arg0, %2 : i64, !llvm.ptr
      omp.yield
    }
  }
  llvm.return
}
// If clause order(concurrent) is specified then the memory instructions
// are marked parallel even if 'safelen' is finite.
// CHECK: llvm.loop.parallel_accesses
// CHECK-NEXT: llvm.loop.vectorize.enable
// CHECK-NEXT: llvm.loop.vectorize.width{{.*}}i64 2
// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_ordered(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop ordered(0) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 66, i64 1, i64 %{{.*}}, i64 1, i64 1)
      // CHECK: call void @__kmpc_dispatch_fini_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_static_ordered(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(static) ordered(0) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 66, i64 1, i64 %{{.*}}, i64 1, i64 1)
      // CHECK: call void @__kmpc_dispatch_fini_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i32)

llvm.func @test_omp_wsloop_static_chunk_ordered(%lb : i32, %ub : i32, %step : i32) -> () {
  %static_chunk_size = llvm.mlir.constant(1 : i32) : i32
  omp.wsloop schedule(static = %static_chunk_size : i32) ordered(0) {
    omp.loop_nest (%iv) : i32 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_4u(ptr @{{.*}}, i32 %{{.*}}, i32 65, i32 1, i32 %{{.*}}, i32 1, i32 1)
      // CHECK: call void @__kmpc_dispatch_fini_4u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_4u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i32) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_dynamic_ordered(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(dynamic) ordered(0) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 67, i64 1, i64 %{{.*}}, i64 1, i64 1)
      // CHECK: call void @__kmpc_dispatch_fini_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_auto_ordered(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(auto) ordered(0) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 70, i64 1, i64 %{{.*}}, i64 1, i64 1)
      // CHECK: call void @__kmpc_dispatch_fini_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_runtime_ordered(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(runtime) ordered(0) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 69, i64 1, i64 %{{.*}}, i64 1, i64 1)
      // CHECK: call void @__kmpc_dispatch_fini_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_guided_ordered(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(guided) ordered(0) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 68, i64 1, i64 %{{.*}}, i64 1, i64 1)
      // CHECK: call void @__kmpc_dispatch_fini_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_dynamic_nonmonotonic_ordered(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(dynamic, nonmonotonic) ordered(0) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 1073741891, i64 1, i64 %{{.*}}, i64 1, i64 1)
      // CHECK: call void @__kmpc_dispatch_fini_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

llvm.func @body(i64)

llvm.func @test_omp_wsloop_dynamic_monotonic_ordered(%lb : i64, %ub : i64, %step : i64) -> () {
  omp.wsloop schedule(dynamic, monotonic) ordered(0) {
    omp.loop_nest (%iv) : i64 = (%lb) to (%ub) step (%step) {
      // CHECK: call void @__kmpc_dispatch_init_8u(ptr @{{.*}}, i32 %{{.*}}, i32 536870979, i64 1, i64 %{{.*}}, i64 1, i64 1)
      // CHECK: call void @__kmpc_dispatch_fini_8u
      // CHECK: %[[continue:.*]] = call i32 @__kmpc_dispatch_next_8u
      // CHECK: %[[cond:.*]] = icmp ne i32 %[[continue]], 0
      // CHECK: br i1 %[[cond]], label %omp_loop.header{{.*}}, label %omp_loop.exit{{.*}}
      llvm.call @body(%iv) : (i64) -> ()
      omp.yield
    }
  }
  llvm.return
}

// -----

omp.critical.declare @mutex_none hint(none) // 0
omp.critical.declare @mutex_uncontended hint(uncontended) // 1
omp.critical.declare @mutex_contended hint(contended) // 2
omp.critical.declare @mutex_nonspeculative hint(nonspeculative) // 4
omp.critical.declare @mutex_nonspeculative_uncontended hint(nonspeculative, uncontended) // 5
omp.critical.declare @mutex_nonspeculative_contended hint(nonspeculative, contended) // 6
omp.critical.declare @mutex_speculative hint(speculative) // 8
omp.critical.declare @mutex_speculative_uncontended hint(speculative, uncontended) // 9
omp.critical.declare @mutex_speculative_contended hint(speculative, contended) // 10

// CHECK-LABEL: @omp_critical
llvm.func @omp_critical(%x : !llvm.ptr, %xval : i32) -> () {
  // CHECK: call void @__kmpc_critical({{.*}}critical_user_.var{{.*}})
  // CHECK: br label %omp.critical.region
  // CHECK: omp.critical.region
  omp.critical {
  // CHECK: store
    llvm.store %xval, %x : i32, !llvm.ptr
    omp.terminator
  }
  // CHECK: call void @__kmpc_end_critical({{.*}}critical_user_.var{{.*}})

  // CHECK: call void @__kmpc_critical_with_hint({{.*}}critical_user_mutex_none.var{{.*}}, i32 0)
  // CHECK: br label %omp.critical.region
  // CHECK: omp.critical.region
  omp.critical(@mutex_none) {
  // CHECK: store
    llvm.store %xval, %x : i32, !llvm.ptr
    omp.terminator
  }
  // CHECK: call void @__kmpc_end_critical({{.*}}critical_user_mutex_none.var{{.*}})

  // CHECK: call void @__kmpc_critical_with_hint({{.*}}critical_user_mutex_uncontended.var{{.*}}, i32 1)
  // CHECK: br label %omp.critical.region
  // CHECK: omp.critical.region
  omp.critical(@mutex_uncontended) {
  // CHECK: store
    llvm.store %xval, %x : i32, !llvm.ptr
    omp.terminator
  }
  // CHECK: call void @__kmpc_end_critical({{.*}}critical_user_mutex_uncontended.var{{.*}})

  // CHECK: call void @__kmpc_critical_with_hint({{.*}}critical_user_mutex_contended.var{{.*}}, i32 2)
  // CHECK: br label %omp.critical.region
  // CHECK: omp.critical.region
  omp.critical(@mutex_contended) {
  // CHECK: store
    llvm.store %xval, %x : i32, !llvm.ptr
    omp.terminator
  }
  // CHECK: call void @__kmpc_end_critical({{.*}}critical_user_mutex_contended.var{{.*}})

  // CHECK: call void @__kmpc_critical_with_hint({{.*}}critical_user_mutex_nonspeculative.var{{.*}}, i32 4)
  // CHECK: br label %omp.critical.region
  // CHECK: omp.critical.region
  omp.critical(@mutex_nonspeculative) {
  // CHECK: store
    llvm.store %xval, %x : i32, !llvm.ptr
    omp.terminator
  }
  // CHECK: call void @__kmpc_end_critical({{.*}}critical_user_mutex_nonspeculative.var{{.*}})

  // CHECK: call void @__kmpc_critical_with_hint({{.*}}critical_user_mutex_nonspeculative_uncontended.var{{.*}}, i32 5)
  // CHECK: br label %omp.critical.region
  // CHECK: omp.critical.region
  omp.critical(@mutex_nonspeculative_uncontended) {
  // CHECK: store
    llvm.store %xval, %x : i32, !llvm.ptr
    omp.terminator
  }
  // CHECK: call void @__kmpc_end_critical({{.*}}critical_user_mutex_nonspeculative_uncontended.var{{.*}})

  // CHECK: call void @__kmpc_critical_with_hint({{.*}}critical_user_mutex_nonspeculative_contended.var{{.*}}, i32 6)
  // CHECK: br label %omp.critical.region
  // CHECK: omp.critical.region
  omp.critical(@mutex_nonspeculative_contended) {
  // CHECK: store
    llvm.store %xval, %x : i32, !llvm.ptr
    omp.terminator
  }
  // CHECK: call void @__kmpc_end_critical({{.*}}critical_user_mutex_nonspeculative_contended.var{{.*}})

  // CHECK: call void @__kmpc_critical_with_hint({{.*}}critical_user_mutex_speculative.var{{.*}}, i32 8)
  // CHECK: br label %omp.critical.region
  // CHECK: omp.critical.region
  omp.critical(@mutex_speculative) {
  // CHECK: store
    llvm.store %xval, %x : i32, !llvm.ptr
    omp.terminator
  }
  // CHECK: call void @__kmpc_end_critical({{.*}}critical_user_mutex_speculative.var{{.*}})

  // CHECK: call void @__kmpc_critical_with_hint({{.*}}critical_user_mutex_speculative_uncontended.var{{.*}}, i32 9)
  // CHECK: br label %omp.critical.region
  // CHECK: omp.critical.region
  omp.critical(@mutex_speculative_uncontended) {
  // CHECK: store
    llvm.store %xval, %x : i32, !llvm.ptr
    omp.terminator
  }
  // CHECK: call void @__kmpc_end_critical({{.*}}critical_user_mutex_speculative_uncontended.var{{.*}})

  // CHECK: call void @__kmpc_critical_with_hint({{.*}}critical_user_mutex_speculative_contended.var{{.*}}, i32 10)
  // CHECK: br label %omp.critical.region
  // CHECK: omp.critical.region
  omp.critical(@mutex_speculative_contended) {
  // CHECK: store
    llvm.store %xval, %x : i32, !llvm.ptr
    omp.terminator
  }
  // CHECK: call void @__kmpc_end_critical({{.*}}critical_user_mutex_speculative_contended.var{{.*}})
  llvm.return
}

// -----

// Check that the loop bounds are emitted in the correct location in case of
// collapse. This only checks the overall shape of the IR, detailed checking
// is done by the OpenMPIRBuilder.

// CHECK-LABEL: @collapse_wsloop
// CHECK: ptr noalias %[[TIDADDR:[0-9A-Za-z.]*]]
// CHECK: load i32, ptr %[[TIDADDR]]
// CHECK: store
// CHECK: load
// CHECK: %[[LB0:.*]] = load i32
// CHECK: %[[UB0:.*]] = load i32
// CHECK: %[[STEP0:.*]] = load i32
// CHECK: %[[LB1:.*]] = load i32
// CHECK: %[[UB1:.*]] = load i32
// CHECK: %[[STEP1:.*]] = load i32
// CHECK: %[[LB2:.*]] = load i32
// CHECK: %[[UB2:.*]] = load i32
// CHECK: %[[STEP2:.*]] = load i32
llvm.func @collapse_wsloop(
    %0: i32, %1: i32, %2: i32,
    %3: i32, %4: i32, %5: i32,
    %6: i32, %7: i32, %8: i32,
    %20: !llvm.ptr) {
  omp.parallel {
    // CHECK: icmp slt i32 %[[LB0]], 0
    // CHECK-COUNT-4: select
    // CHECK: %[[TRIPCOUNT0:.*]] = select
    // CHECK: br label %[[PREHEADER:.*]]
    //
    // CHECK: [[PREHEADER]]:
    // CHECK: icmp slt i32 %[[LB1]], 0
    // CHECK-COUNT-4: select
    // CHECK: %[[TRIPCOUNT1:.*]] = select
    // CHECK: icmp slt i32 %[[LB2]], 0
    // CHECK-COUNT-4: select
    // CHECK: %[[TRIPCOUNT2:.*]] = select
    // CHECK: %[[PROD:.*]] = mul nuw i32 %[[TRIPCOUNT0]], %[[TRIPCOUNT1]]
    // CHECK: %[[TOTAL:.*]] = mul nuw i32 %[[PROD]], %[[TRIPCOUNT2]]
    // CHECK: br label %[[COLLAPSED_PREHEADER:.*]]
    //
    // CHECK: [[COLLAPSED_PREHEADER]]:
    // CHECK: store i32 0, ptr
    // CHECK: %[[TOTAL_SUB_1:.*]] = sub i32 %[[TOTAL]], 1
    // CHECK: store i32 %[[TOTAL_SUB_1]], ptr
    // CHECK: call void @__kmpc_for_static_init_4u
    omp.wsloop {
      omp.loop_nest (%arg0, %arg1, %arg2) : i32 = (%0, %1, %2) to (%3, %4, %5) step (%6, %7, %8) {
        %31 = llvm.load %20 : !llvm.ptr -> i32
        %32 = llvm.add %31, %arg0 : i32
        %33 = llvm.add %32, %arg1 : i32
        %34 = llvm.add %33, %arg2 : i32
        llvm.store %34, %20 : i32, !llvm.ptr
        omp.yield
      }
    }
    omp.terminator
  }
  llvm.return
}

// -----

// Check that the loop bounds are emitted in the correct location in case of
// collapse for dynamic schedule. This only checks the overall shape of the IR,
// detailed checking is done by the OpenMPIRBuilder.

// CHECK-LABEL: @collapse_wsloop_dynamic
// CHECK: ptr noalias %[[TIDADDR:[0-9A-Za-z.]*]]
// CHECK: load i32, ptr %[[TIDADDR]]
// CHECK: store
// CHECK: load
// CHECK: %[[LB0:.*]] = load i32
// CHECK: %[[UB0:.*]] = load i32
// CHECK: %[[STEP0:.*]] = load i32
// CHECK: %[[LB1:.*]] = load i32
// CHECK: %[[UB1:.*]] = load i32
// CHECK: %[[STEP1:.*]] = load i32
// CHECK: %[[LB2:.*]] = load i32
// CHECK: %[[UB2:.*]] = load i32
// CHECK: %[[STEP2:.*]] = load i32

llvm.func @collapse_wsloop_dynamic(
    %0: i32, %1: i32, %2: i32,
    %3: i32, %4: i32, %5: i32,
    %6: i32, %7: i32, %8: i32,
    %20: !llvm.ptr) {
  omp.parallel {
    // CHECK: icmp slt i32 %[[LB0]], 0
    // CHECK-COUNT-4: select
    // CHECK: %[[TRIPCOUNT0:.*]] = select
    // CHECK: br label %[[PREHEADER:.*]]
    //
    // CHECK: [[PREHEADER]]:
    // CHECK: icmp slt i32 %[[LB1]], 0
    // CHECK-COUNT-4: select
    // CHECK: %[[TRIPCOUNT1:.*]] = select
    // CHECK: icmp slt i32 %[[LB2]], 0
    // CHECK-COUNT-4: select
    // CHECK: %[[TRIPCOUNT2:.*]] = select
    // CHECK: %[[PROD:.*]] = mul nuw i32 %[[TRIPCOUNT0]], %[[TRIPCOUNT1]]
    // CHECK: %[[TOTAL:.*]] = mul nuw i32 %[[PROD]], %[[TRIPCOUNT2]]
    // CHECK: br label %[[COLLAPSED_PREHEADER:.*]]
    //
    // CHECK: [[COLLAPSED_PREHEADER]]:
    // CHECK: store i32 1, ptr
    // CHECK: store i32 %[[TOTAL]], ptr
    // CHECK: call void @__kmpc_dispatch_init_4u
    omp.wsloop schedule(dynamic) {
      omp.loop_nest (%arg0, %arg1, %arg2) : i32 = (%0, %1, %2) to (%3, %4, %5) step (%6, %7, %8) {
        %31 = llvm.load %20 : !llvm.ptr -> i32
        %32 = llvm.add %31, %arg0 : i32
        %33 = llvm.add %32, %arg1 : i32
        %34 = llvm.add %33, %arg2 : i32
        llvm.store %34, %20 : i32, !llvm.ptr
        omp.yield
      }
    }
    omp.terminator
  }
  llvm.return
}

// -----

// CHECK-LABEL: @omp_ordered
llvm.func @omp_ordered(%arg0 : i32, %arg1 : i32, %arg2 : i32, %arg3 : i64,
    %arg4: i64, %arg5: i64, %arg6: i64) -> () {
  // CHECK: [[ADDR9:%.*]] = alloca [2 x i64], align 8
  // CHECK: [[ADDR7:%.*]] = alloca [2 x i64], align 8
  // CHECK: [[ADDR5:%.*]] = alloca [2 x i64], align 8
  // CHECK: [[ADDR3:%.*]] = alloca [1 x i64], align 8
  // CHECK: [[ADDR:%.*]] = alloca [1 x i64], align 8

  // CHECK: [[OMP_THREAD:%.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GLOB1:[0-9]+]])
  // CHECK-NEXT:  call void @__kmpc_ordered(ptr @[[GLOB1]], i32 [[OMP_THREAD]])
  omp.ordered.region {
    omp.terminator
  // CHECK: call void @__kmpc_end_ordered(ptr @[[GLOB1]], i32 [[OMP_THREAD]])
  }

  omp.wsloop ordered(0) {
    omp.loop_nest (%arg7) : i32 = (%arg0) to (%arg1) step (%arg2) {
      // CHECK:  call void @__kmpc_ordered(ptr @[[GLOB3:[0-9]+]], i32 [[OMP_THREAD2:%.*]])
      omp.ordered.region  {
        omp.terminator
      // CHECK: call void @__kmpc_end_ordered(ptr @[[GLOB3]], i32 [[OMP_THREAD2]])
      }
      omp.yield
    }
  }

  omp.wsloop ordered(1) {
    omp.loop_nest (%arg7) : i32 = (%arg0) to (%arg1) step (%arg2) {
      // CHECK: [[TMP:%.*]] = getelementptr inbounds [1 x i64], ptr [[ADDR]], i64 0, i64 0
      // CHECK: store i64 [[ARG0:%.*]], ptr [[TMP]], align 8
      // CHECK: [[TMP2:%.*]] = getelementptr inbounds [1 x i64], ptr [[ADDR]], i64 0, i64 0
      // CHECK: [[OMP_THREAD2:%.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GLOB3:[0-9]+]])
      // CHECK: call void @__kmpc_doacross_wait(ptr @[[GLOB3]], i32 [[OMP_THREAD2]], ptr [[TMP2]])
      omp.ordered depend_type(dependsink) depend_vec(%arg3 : i64) {doacross_num_loops = 1 : i64}

      // CHECK: [[TMP3:%.*]] = getelementptr inbounds [1 x i64], ptr [[ADDR3]], i64 0, i64 0
      // CHECK: store i64 [[ARG0]], ptr [[TMP3]], align 8
      // CHECK: [[TMP4:%.*]] = getelementptr inbounds [1 x i64], ptr [[ADDR3]], i64 0, i64 0
      // CHECK: [[OMP_THREAD4:%.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GLOB5:[0-9]+]])
      // CHECK: call void @__kmpc_doacross_post(ptr @[[GLOB5]], i32 [[OMP_THREAD4]], ptr [[TMP4]])
      omp.ordered depend_type(dependsource) depend_vec(%arg3 : i64) {doacross_num_loops = 1 : i64}

      omp.yield
    }
  }

  omp.wsloop ordered(2) {
    omp.loop_nest (%arg7) : i32 = (%arg0) to (%arg1) step (%arg2) {
      // CHECK: [[TMP5:%.*]] = getelementptr inbounds [2 x i64], ptr [[ADDR5]], i64 0, i64 0
      // CHECK: store i64 [[ARG0]], ptr [[TMP5]], align 8
      // CHECK: [[TMP6:%.*]] = getelementptr inbounds [2 x i64], ptr [[ADDR5]], i64 0, i64 1
      // CHECK: store i64 [[ARG1:%.*]], ptr [[TMP6]], align 8
      // CHECK: [[TMP7:%.*]] = getelementptr inbounds [2 x i64], ptr [[ADDR5]], i64 0, i64 0
      // CHECK: [[OMP_THREAD6:%.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GLOB7:[0-9]+]])
      // CHECK: call void @__kmpc_doacross_wait(ptr @[[GLOB7]], i32 [[OMP_THREAD6]], ptr [[TMP7]])
      // CHECK: [[TMP8:%.*]] = getelementptr inbounds [2 x i64], ptr [[ADDR7]], i64 0, i64 0
      // CHECK: store i64 [[ARG2:%.*]], ptr [[TMP8]], align 8
      // CHECK: [[TMP9:%.*]] = getelementptr inbounds [2 x i64], ptr [[ADDR7]], i64 0, i64 1
      // CHECK: store i64 [[ARG3:%.*]], ptr [[TMP9]], align 8
      // CHECK: [[TMP10:%.*]] = getelementptr inbounds [2 x i64], ptr [[ADDR7]], i64 0, i64 0
      // CHECK: [[OMP_THREAD8:%.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GLOB7]])
      // CHECK: call void @__kmpc_doacross_wait(ptr @[[GLOB7]], i32 [[OMP_THREAD8]], ptr [[TMP10]])
      omp.ordered depend_type(dependsink) depend_vec(%arg3, %arg4, %arg5, %arg6 : i64, i64, i64, i64) {doacross_num_loops = 2 : i64}

      // CHECK: [[TMP11:%.*]] = getelementptr inbounds [2 x i64], ptr [[ADDR9]], i64 0, i64 0
      // CHECK: store i64 [[ARG0]], ptr [[TMP11]], align 8
      // CHECK: [[TMP12:%.*]] = getelementptr inbounds [2 x i64], ptr [[ADDR9]], i64 0, i64 1
      // CHECK: store i64 [[ARG1]], ptr [[TMP12]], align 8
      // CHECK: [[TMP13:%.*]] = getelementptr inbounds [2 x i64], ptr [[ADDR9]], i64 0, i64 0
      // CHECK: [[OMP_THREAD10:%.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GLOB9:[0-9]+]])
      // CHECK: call void @__kmpc_doacross_post(ptr @[[GLOB9]], i32 [[OMP_THREAD10]], ptr [[TMP13]])
      omp.ordered depend_type(dependsource) depend_vec(%arg3, %arg4 : i64, i64) {doacross_num_loops = 2 : i64}

      omp.yield
    }
  }

  llvm.return
}

// -----

// CHECK-LABEL: @omp_atomic_read
// CHECK-SAME: (ptr %[[ARG0:.*]], ptr %[[ARG1:.*]])
llvm.func @omp_atomic_read(%arg0 : !llvm.ptr, %arg1 : !llvm.ptr) -> () {

  // CHECK: %[[X1:.*]] = load atomic i32, ptr %[[ARG0]] monotonic, align 4
  // CHECK: store i32 %[[X1]], ptr %[[ARG1]], align 4
  omp.atomic.read %arg1 = %arg0 : !llvm.ptr, !llvm.ptr, i32

  // CHECK: %[[X2:.*]] = load atomic i32, ptr %[[ARG0]] seq_cst, align 4
  // CHECK: call void @__kmpc_flush(ptr @{{.*}})
  // CHECK: store i32 %[[X2]], ptr %[[ARG1]], align 4
  omp.atomic.read %arg1 = %arg0 memory_order(seq_cst) : !llvm.ptr, !llvm.ptr, i32

  // CHECK: %[[X3:.*]] = load atomic i32, ptr %[[ARG0]] acquire, align 4
  // CHECK: call void @__kmpc_flush(ptr @{{.*}})
  // CHECK: store i32 %[[X3]], ptr %[[ARG1]], align 4
  omp.atomic.read %arg1 = %arg0 memory_order(acquire) : !llvm.ptr, !llvm.ptr, i32

  // CHECK: %[[X4:.*]] = load atomic i32, ptr %[[ARG0]] monotonic, align 4
  // CHECK: store i32 %[[X4]], ptr %[[ARG1]], align 4
  omp.atomic.read %arg1 = %arg0 memory_order(relaxed) : !llvm.ptr, !llvm.ptr, i32
  llvm.return
}

// -----

// CHECK-LABEL: @omp_atomic_read_implicit_cast
llvm.func @omp_atomic_read_implicit_cast () {
//CHECK: %[[ATOMIC_LOAD_TEMP:.*]] = alloca { float, float }, align 8
//CHECK: %[[Z:.*]] = alloca float, i64 1, align 4
//CHECK: %[[Y:.*]] = alloca double, i64 1, align 8
//CHECK: %[[X:.*]] = alloca [2 x { float, float }], i64 1, align 8
//CHECK: %[[W:.*]] = alloca i32, i64 1, align 4
//CHECK: %[[X_ELEMENT:.*]] = getelementptr { float, float }, ptr %3, i64 0
  %0 = llvm.mlir.constant(1 : i64) : i64
  %1 = llvm.alloca %0 x f32 {bindc_name = "z"} : (i64) -> !llvm.ptr
  %2 = llvm.mlir.constant(1 : i64) : i64
  %3 = llvm.alloca %2 x f64 {bindc_name = "y"} : (i64) -> !llvm.ptr
  %4 = llvm.mlir.constant(1 : i64) : i64
  %5 = llvm.alloca %4 x !llvm.array<2 x struct<(f32, f32)>> {bindc_name = "x"} : (i64) -> !llvm.ptr
  %6 = llvm.mlir.constant(1 : i64) : i64
  %7 = llvm.alloca %6 x i32 {bindc_name = "w"} : (i64) -> !llvm.ptr
  %8 = llvm.mlir.constant(1 : index) : i64
  %9 = llvm.mlir.constant(2 : index) : i64
  %10 = llvm.mlir.constant(1 : i64) : i64
  %11 = llvm.mlir.constant(0 : i64) : i64
  %12 = llvm.sub %8, %10 overflow<nsw> : i64
  %13 = llvm.mul %12, %10 overflow<nsw> : i64
  %14 = llvm.mul %13, %10 overflow<nsw> : i64
  %15 = llvm.add %14, %11 overflow<nsw> : i64
  %16 = llvm.mul %10, %9 overflow<nsw> : i64
  %17 = llvm.getelementptr %5[%15] : (!llvm.ptr, i64) -> !llvm.ptr, !llvm.struct<(f32, f32)>


//CHECK: call void @__atomic_load(i64 8, ptr %[[X_ELEMENT]], ptr %[[ATOMIC_LOAD_TEMP]], i32 0)
//CHECK: %[[LOAD:.*]] = load { float, float }, ptr %[[ATOMIC_LOAD_TEMP]], align 8
//CHECK: store { float, float } %[[LOAD]], ptr %[[Y]], align 4
  omp.atomic.read %3 = %17 : !llvm.ptr, !llvm.ptr, !llvm.struct<(f32, f32)>

//CHECK: %[[ATOMIC_LOAD_TEMP:.*]] = load atomic i32, ptr %[[Z]] monotonic, align 4
//CHECK: %[[CAST:.*]] = bitcast i32 %[[ATOMIC_LOAD_TEMP]] to float
//CHECK: store float %[[CAST]], ptr %[[Y]], align 4
  omp.atomic.read %3 = %1 : !llvm.ptr, !llvm.ptr, f32

//CHECK: %[[ATOMIC_LOAD_TEMP:.*]] = load atomic i32, ptr %[[W]] monotonic, align 4
//CHECK: store i32 %[[ATOMIC_LOAD_TEMP]], ptr %[[Y]], align 4
  omp.atomic.read %3 = %7 : !llvm.ptr, !llvm.ptr, i32

//CHECK: %[[ATOMIC_LOAD_TEMP:.*]] = load atomic i64, ptr %[[Y]] monotonic, align 4
//CHECK: %[[CAST:.*]] = bitcast i64 %[[ATOMIC_LOAD_TEMP]] to double
//CHECK: store double %[[CAST]], ptr %[[Z]], align 8
  omp.atomic.read %1 = %3 : !llvm.ptr, !llvm.ptr, f64

//CHECK: %[[ATOMIC_LOAD_TEMP:.*]] = load atomic i32, ptr %[[W]] monotonic, align 4
//CHECK: store i32 %[[ATOMIC_LOAD_TEMP]], ptr %[[Z]], align 4
  omp.atomic.read %1 = %7 : !llvm.ptr, !llvm.ptr, i32

//CHECK: %[[ATOMIC_LOAD_TEMP:.*]] = load atomic i64, ptr %[[Y]] monotonic, align 4
//CHECK: %[[CAST:.*]] = bitcast i64 %[[ATOMIC_LOAD_TEMP]] to double
//CHECK: store double %[[CAST]], ptr %[[W]], align 8
  omp.atomic.read %7 = %3 : !llvm.ptr, !llvm.ptr, f64

//CHECK: %[[ATOMIC_LOAD_TEMP:.*]] = load atomic i32, ptr %[[Z]] monotonic, align 4
//CHECK: %[[CAST:.*]] = bitcast i32 %[[ATOMIC_LOAD_TEMP]] to float
//CHECK: store float %[[CAST]], ptr %[[W]], align 4
  omp.atomic.read %7 = %1 : !llvm.ptr, !llvm.ptr, f32
  llvm.return
}

// -----

// CHECK-LABEL: @omp_atomic_write
// CHECK-SAME: (ptr %[[x:.*]], i32 %[[expr:.*]])
llvm.func @omp_atomic_write(%x: !llvm.ptr, %expr: i32) -> () {
  // CHECK: store atomic i32 %[[expr]], ptr %[[x]] monotonic, align 4
  omp.atomic.write %x = %expr : !llvm.ptr, i32
  // CHECK: store atomic i32 %[[expr]], ptr %[[x]] seq_cst, align 4
  // CHECK: call void @__kmpc_flush(ptr @{{.*}})
  omp.atomic.write %x = %expr memory_order(seq_cst) : !llvm.ptr, i32
  // CHECK: store atomic i32 %[[expr]], ptr %[[x]] release, align 4
  // CHECK: call void @__kmpc_flush(ptr @{{.*}})
  omp.atomic.write %x = %expr memory_order(release) : !llvm.ptr, i32
  // CHECK: store atomic i32 %[[expr]], ptr %[[x]] monotonic, align 4
  omp.atomic.write %x = %expr memory_order(relaxed) : !llvm.ptr, i32
  llvm.return
}

// -----

// Checking simple atomicrmw and cmpxchg based translation. This also checks for
// ambigous alloca insert point by putting llvm.mul as the first update operation.
// CHECK-LABEL: @omp_atomic_update
// CHECK-SAME: (ptr %[[x:.*]], i32 %[[expr:.*]], ptr %[[xbool:.*]], i1 %[[exprbool:.*]])
llvm.func @omp_atomic_update(%x:!llvm.ptr, %expr: i32, %xbool: !llvm.ptr, %exprbool: i1) {
  // CHECK: %[[t1:.*]] = mul i32 %[[x_old:.*]], %[[expr]]
  // CHECK: store i32 %[[t1]], ptr %[[x_new:.*]]
  // CHECK: %[[t2:.*]] = load i32, ptr %[[x_new]]
  // CHECK: cmpxchg ptr %[[x]], i32 %[[x_old]], i32 %[[t2]]
  omp.atomic.update %x : !llvm.ptr {
  ^bb0(%xval: i32):
    %newval = llvm.mul %xval, %expr : i32
    omp.yield(%newval : i32)
  }
  // CHECK: atomicrmw add ptr %[[x]], i32 %[[expr]] monotonic
  omp.atomic.update %x : !llvm.ptr {
  ^bb0(%xval: i32):
    %newval = llvm.add %xval, %expr : i32
    omp.yield(%newval : i32)
  }
  llvm.return
}

// -----

// CHECK-LABEL: @omp_atomic_write
llvm.func @omp_atomic_write() {
// CHECK: %[[ALLOCA0:.*]] = alloca { float, float }, align 8
// CHECK: %[[ALLOCA1:.*]] = alloca { float, float }, align 8
// CHECK: %[[X:.*]] = alloca float, i64 1, align 4
// CHECK: %[[R1:.*]] = alloca float, i64 1, align 4
// CHECK: %[[ALLOCA:.*]] = alloca { float, float }, i64 1, align 8
// CHECK: %[[LOAD:.*]] = load float, ptr %[[R1]], align 4
// CHECK: %[[IDX1:.*]] = insertvalue { float, float } undef, float %[[LOAD]], 0
// CHECK: %[[IDX2:.*]] = insertvalue { float, float } %[[IDX1]], float 0.000000e+00, 1
// CHECK: br label %entry

// CHECK: entry:
// CHECK: store { float, float } %[[IDX2]], ptr %[[ALLOCA1]], align 4
// CHECK: call void @__atomic_store(i64 8, ptr %[[ALLOCA]], ptr %[[ALLOCA1]], i32 0)
// CHECK: store { float, float } { float 1.000000e+00, float 1.000000e+00 }, ptr %[[ALLOCA0]], align 4
// CHECK: call void @__atomic_store(i64 8, ptr %[[ALLOCA]], ptr %[[ALLOCA0]], i32 0)

    %0 = llvm.mlir.constant(1 : i64) : i64
    %1 = llvm.alloca %0 x f32 {bindc_name = "x"} : (i64) -> !llvm.ptr
    %2 = llvm.mlir.constant(1 : i64) : i64
    %3 = llvm.alloca %2 x f32 {bindc_name = "r1"} : (i64) -> !llvm.ptr
    %4 = llvm.mlir.constant(1 : i64) : i64
    %5 = llvm.alloca %4 x !llvm.struct<(f32, f32)> {bindc_name = "c1"} : (i64) -> !llvm.ptr
    %6 = llvm.mlir.constant(1.000000e+00 : f32) : f32
    %7 = llvm.mlir.constant(0.000000e+00 : f32) : f32
    %8 = llvm.mlir.constant(1 : i64) : i64
    %9 = llvm.mlir.constant(1 : i64) : i64
    %10 = llvm.mlir.constant(1 : i64) : i64
    %11 = llvm.load %3 : !llvm.ptr -> f32
    %12 = llvm.mlir.undef : !llvm.struct<(f32, f32)>
    %13 = llvm.insertvalue %11, %12[0] : !llvm.struct<(f32, f32)>
    %14 = llvm.insertvalue %7, %13[1] : !llvm.struct<(f32, f32)>
    omp.atomic.write %5 = %14 : !llvm.ptr, !llvm.struct<(f32, f32)>
    %15 = llvm.mlir.undef : !llvm.struct<(f32, f32)>
    %16 = llvm.insertvalue %6, %15[0] : !llvm.struct<(f32, f32)>
    %17 = llvm.insertvalue %6, %16[1] : !llvm.struct<(f32, f32)>
    omp.atomic.write %5 = %17 : !llvm.ptr, !llvm.struct<(f32, f32)>
    llvm.return
}

// -----

//CHECK: %[[ATOMIC_TEMP_LOAD:.*]] = alloca { float, float }, align 8
//CHECK: %[[X_NEW_VAL:.*]] = alloca { float, float }, align 8
//CHECK: {{.*}} = alloca { float, float }, i64 1, align 8
//CHECK: %[[ORIG_VAL:.*]] = alloca { float, float }, i64 1, align 8

//CHECK: br label %entry

//CHECK: entry:
//CHECK: call void @__atomic_load(i64 8, ptr %[[ORIG_VAL]], ptr %[[ATOMIC_TEMP_LOAD]], i32 0)
//CHECK: %[[PHI_NODE_ENTRY_1:.*]] = load { float, float }, ptr %[[ATOMIC_TEMP_LOAD]], align 8
//CHECK: br label %.atomic.cont

//CHECK: .atomic.cont
//CHECK: %[[VAL_4:.*]] = phi { float, float } [ %[[PHI_NODE_ENTRY_1]], %entry ], [ %{{.*}}, %.atomic.cont ]
//CHECK: %[[VAL_5:.*]] = extractvalue { float, float } %[[VAL_4]], 0
//CHECK: %[[VAL_6:.*]] = extractvalue { float, float } %[[VAL_4]], 1
//CHECK: %[[VAL_7:.*]] = fadd contract float %[[VAL_5]], 1.000000e+00
//CHECK: %[[VAL_8:.*]] = fadd contract float %[[VAL_6]], 1.000000e+00
//CHECK: %[[VAL_9:.*]] = insertvalue { float, float } undef, float %[[VAL_7]], 0
//CHECK: %[[VAL_10:.*]] = insertvalue { float, float } %[[VAL_9]], float %[[VAL_8]], 1
//CHECK: store { float, float } %[[VAL_10]], ptr %[[X_NEW_VAL]], align 4
//CHECK: %[[VAL_11:.*]] = call i1 @__atomic_compare_exchange(i64 8, ptr %[[ORIG_VAL]], ptr %[[ATOMIC_TEMP_LOAD]], ptr %[[X_NEW_VAL]], i32 2, i32 2)
//CHECK: %[[VAL_12:.*]] = load { float, float }, ptr %[[ATOMIC_TEMP_LOAD]], align 4
//CHECK: br i1 %[[VAL_11]], label %.atomic.exit, label %.atomic.cont

llvm.func @_QPomp_atomic_update_complex() {
    %0 = llvm.mlir.constant(1 : i64) : i64
    %1 = llvm.alloca %0 x !llvm.struct<(f32, f32)> {bindc_name = "ib"} : (i64) -> !llvm.ptr
    %2 = llvm.mlir.constant(1 : i64) : i64
    %3 = llvm.alloca %2 x !llvm.struct<(f32, f32)> {bindc_name = "ia"} : (i64) -> !llvm.ptr
    %4 = llvm.mlir.constant(1.000000e+00 : f32) : f32
    %5 = llvm.mlir.undef : !llvm.struct<(f32, f32)>
    %6 = llvm.insertvalue %4, %5[0] : !llvm.struct<(f32, f32)>
    %7 = llvm.insertvalue %4, %6[1] : !llvm.struct<(f32, f32)>
    omp.atomic.update %3 : !llvm.ptr {
    ^bb0(%arg0: !llvm.struct<(f32, f32)>):
      %8 = llvm.extractvalue %arg0[0] : !llvm.struct<(f32, f32)>
      %9 = llvm.extractvalue %arg0[1] : !llvm.struct<(f32, f32)>
      %10 = llvm.extractvalue %7[0] : !llvm.struct<(f32, f32)>
      %11 = llvm.extractvalue %7[1] : !llvm.struct<(f32, f32)>
      %12 = llvm.fadd %8, %10  {fastmathFlags = #llvm.fastmath<contract>} : f32
      %13 = llvm.fadd %9, %11  {fastmathFlags = #llvm.fastmath<contract>} : f32
      %14 = llvm.mlir.undef : !llvm.struct<(f32, f32)>
      %15 = llvm.insertvalue %12, %14[0] : !llvm.struct<(f32, f32)>
      %16 = llvm.insertvalue %13, %15[1] : !llvm.struct<(f32, f32)>
      omp.yield(%16 : !llvm.struct<(f32, f32)>)
    }
   llvm.return
}

// -----

//CHECK: %[[ATOMIC_TEMP_LOAD:.*]] = alloca { float, float }, align 8
//CHECK: %[[X_NEW_VAL:.*]] = alloca { float, float }, align 8
//CHECK: %[[VAL_1:.*]] = alloca { float, float }, i64 1, align 8
//CHECK: %[[ORIG_VAL:.*]] = alloca { float, float }, i64 1, align 8
//CHECK: store { float, float } { float 2.000000e+00, float 2.000000e+00 }, ptr %[[ORIG_VAL]], align 4
//CHECK: br label %entry

//CHECK: entry:							; preds = %0
//CHECK: call void @__atomic_load(i64 8, ptr %[[ORIG_VAL]], ptr %[[ATOMIC_TEMP_LOAD]], i32 0)
//CHECK: %[[PHI_NODE_ENTRY_1:.*]] = load { float, float }, ptr %[[ATOMIC_TEMP_LOAD]], align 8
//CHECK: br label %.atomic.cont

//CHECK: .atomic.cont
//CHECK: %[[VAL_4:.*]] = phi { float, float } [ %[[PHI_NODE_ENTRY_1]], %entry ], [ %{{.*}}, %.atomic.cont ]
//CHECK: %[[VAL_5:.*]] = extractvalue { float, float } %[[VAL_4]], 0
//CHECK: %[[VAL_6:.*]] = extractvalue { float, float } %[[VAL_4]], 1
//CHECK: %[[VAL_7:.*]] = fadd contract float %[[VAL_5]], 1.000000e+00
//CHECK: %[[VAL_8:.*]] = fadd contract float %[[VAL_6]], 1.000000e+00
//CHECK: %[[VAL_9:.*]] = insertvalue { float, float } undef, float %[[VAL_7]], 0
//CHECK: %[[VAL_10:.*]] = insertvalue { float, float } %[[VAL_9]], float %[[VAL_8]], 1
//CHECK: store { float, float } %[[VAL_10]], ptr %[[X_NEW_VAL]], align 4 
//CHECK: %[[VAL_11:.*]] = call i1 @__atomic_compare_exchange(i64 8, ptr %[[ORIG_VAL]], ptr %[[ATOMIC_TEMP_LOAD]], ptr %[[X_NEW_VAL]], i32 2, i32 2)
//CHECK: %[[VAL_12:.*]] = load { float, float }, ptr %[[ATOMIC_TEMP_LOAD]], align 4
//CHECK: br i1 %[[VAL_11]], label %.atomic.exit, label %.atomic.cont
//CHECK: .atomic.exit
//CHECK: store { float, float } %[[VAL_10]], ptr %[[VAL_1]], align 4

llvm.func @_QPomp_atomic_capture_complex() {
    %0 = llvm.mlir.constant(1 : i64) : i64
    %1 = llvm.alloca %0 x !llvm.struct<(f32, f32)> {bindc_name = "ib"} : (i64) -> !llvm.ptr
    %2 = llvm.mlir.constant(1 : i64) : i64
    %3 = llvm.alloca %2 x !llvm.struct<(f32, f32)> {bindc_name = "ia"} : (i64) -> !llvm.ptr
    %4 = llvm.mlir.constant(1.000000e+00 : f32) : f32
    %5 = llvm.mlir.constant(2.000000e+00 : f32) : f32
    %6 = llvm.mlir.undef : !llvm.struct<(f32, f32)>
    %7 = llvm.insertvalue %5, %6[0] : !llvm.struct<(f32, f32)>
    %8 = llvm.insertvalue %5, %7[1] : !llvm.struct<(f32, f32)>
    llvm.store %8, %3 : !llvm.struct<(f32, f32)>, !llvm.ptr
    %9 = llvm.mlir.undef : !llvm.struct<(f32, f32)>
    %10 = llvm.insertvalue %4, %9[0] : !llvm.struct<(f32, f32)>
    %11 = llvm.insertvalue %4, %10[1] : !llvm.struct<(f32, f32)>
    omp.atomic.capture {
      omp.atomic.update %3 : !llvm.ptr {
      ^bb0(%arg0: !llvm.struct<(f32, f32)>):
        %12 = llvm.extractvalue %arg0[0] : !llvm.struct<(f32, f32)>
        %13 = llvm.extractvalue %arg0[1] : !llvm.struct<(f32, f32)>
        %14 = llvm.extractvalue %11[0] : !llvm.struct<(f32, f32)>
        %15 = llvm.extractvalue %11[1] : !llvm.struct<(f32, f32)>
        %16 = llvm.fadd %12, %14  {fastmathFlags = #llvm.fastmath<contract>} : f32
        %17 = llvm.fadd %13, %15  {fastmathFlags = #llvm.fastmath<contract>} : f32
        %18 = llvm.mlir.undef : !llvm.struct<(f32, f32)>
        %19 = llvm.insertvalue %16, %18[0] : !llvm.struct<(f32, f32)>
        %20 = llvm.insertvalue %17, %19[1] : !llvm.struct<(f32, f32)>
        omp.yield(%20 : !llvm.struct<(f32, f32)>)
      }
      omp.atomic.read %1 = %3 : !llvm.ptr, !llvm.ptr, !llvm.struct<(f32, f32)>
    }
    llvm.return
}

// -----

// CHECK-LABEL: define void @omp_atomic_read_complex() {
llvm.func @omp_atomic_read_complex(){

// CHECK: %[[ATOMIC_TEMP_LOAD:.*]] = alloca { float, float }, align 8
// CHECK: %[[a:.*]] = alloca { float, float }, i64 1, align 8
// CHECK: %[[b:.*]] = alloca { float, float }, i64 1, align 8
// CHECK: call void @__atomic_load(i64 8, ptr %[[b]], ptr %[[ATOMIC_TEMP_LOAD]], i32 0)
// CHECK: %[[LOADED_VAL:.*]] = load { float, float }, ptr %[[ATOMIC_TEMP_LOAD]], align 8
// CHECK: store { float, float } %[[LOADED_VAL]], ptr %[[a]], align 4
// CHECK: ret void
// CHECK: }

    %0 = llvm.mlir.constant(1 : i64) : i64
    %1 = llvm.alloca %0 x !llvm.struct<(f32, f32)> {bindc_name = "ib"} : (i64) -> !llvm.ptr
    %2 = llvm.mlir.constant(1 : i64) : i64
    %3 = llvm.alloca %2 x !llvm.struct<(f32, f32)> {bindc_name = "ia"} : (i64) -> !llvm.ptr
    omp.atomic.read %1 = %3 : !llvm.ptr, !llvm.ptr, !llvm.struct<(f32, f32)>
    llvm.return
}

// -----

// Checking an order-dependent operation when the order is `expr binop x`
// CHECK-LABEL: @omp_atomic_update_ordering
// CHECK-SAME: (ptr %[[x:.*]], i32 %[[expr:.*]])
llvm.func @omp_atomic_update_ordering(%x:!llvm.ptr, %expr: i32) {
  // CHECK: %[[t1:.*]] = shl i32 %[[expr]], %[[x_old:[^ ,]*]]
  // CHECK: store i32 %[[t1]], ptr %[[x_new:.*]]
  // CHECK: %[[t2:.*]] = load i32, ptr %[[x_new]]
  // CHECK: cmpxchg ptr %[[x]], i32 %[[x_old]], i32 %[[t2]]
  omp.atomic.update %x : !llvm.ptr {
  ^bb0(%xval: i32):
    %newval = llvm.shl %expr, %xval : i32
    omp.yield(%newval : i32)
  }
  llvm.return
}

// -----

// Checking an order-dependent operation when the order is `x binop expr`
// CHECK-LABEL: @omp_atomic_update_ordering
// CHECK-SAME: (ptr %[[x:.*]], i32 %[[expr:.*]])
llvm.func @omp_atomic_update_ordering(%x:!llvm.ptr, %expr: i32) {
  // CHECK: %[[t1:.*]] = shl i32 %[[x_old:.*]], %[[expr]]
  // CHECK: store i32 %[[t1]], ptr %[[x_new:.*]]
  // CHECK: %[[t2:.*]] = load i32, ptr %[[x_new]]
  // CHECK: cmpxchg ptr %[[x]], i32 %[[x_old]], i32 %[[t2]] monotonic
  omp.atomic.update %x : !llvm.ptr {
  ^bb0(%xval: i32):
    %newval = llvm.shl %xval, %expr : i32
    omp.yield(%newval : i32)
  }
  llvm.return
}

// -----

// Checking intrinsic translation.
// CHECK-LABEL: @omp_atomic_update_intrinsic
// CHECK-SAME: (ptr %[[x:.*]], i32 %[[expr:.*]])
llvm.func @omp_atomic_update_intrinsic(%x:!llvm.ptr, %expr: i32) {
  // CHECK: %[[t1:.*]] = call i32 @llvm.smax.i32(i32 %[[x_old:.*]], i32 %[[expr]])
  // CHECK: store i32 %[[t1]], ptr %[[x_new:.*]]
  // CHECK: %[[t2:.*]] = load i32, ptr %[[x_new]]
  // CHECK: cmpxchg ptr %[[x]], i32 %[[x_old]], i32 %[[t2]]
  omp.atomic.update %x : !llvm.ptr {
  ^bb0(%xval: i32):
    %newval = "llvm.intr.smax"(%xval, %expr) : (i32, i32) -> i32
    omp.yield(%newval : i32)
  }
  // CHECK: %[[t1:.*]] = call i32 @llvm.umax.i32(i32 %[[x_old:.*]], i32 %[[expr]])
  // CHECK: store i32 %[[t1]], ptr %[[x_new:.*]]
  // CHECK: %[[t2:.*]] = load i32, ptr %[[x_new]]
  // CHECK: cmpxchg ptr %[[x]], i32 %[[x_old]], i32 %[[t2]]
  omp.atomic.update %x : !llvm.ptr {
  ^bb0(%xval: i32):
    %newval = "llvm.intr.umax"(%xval, %expr) : (i32, i32) -> i32
    omp.yield(%newval : i32)
  }
  llvm.return
}

// -----

// CHECK-LABEL: @atomic_update_cmpxchg
// CHECK-SAME: (ptr %[[X:.*]], ptr %[[EXPR:.*]]) {
// CHECK:  %[[AT_LOAD_VAL:.*]] = load atomic i32, ptr %[[X]] monotonic, align 4
// CHECK:  %[[LOAD_VAL_PHI:.*]] = phi i32 [ %[[AT_LOAD_VAL]], %entry ], [ %[[LOAD_VAL:.*]], %.atomic.cont ]
// CHECK:  %[[VAL_SUCCESS:.*]] = cmpxchg ptr %[[X]], i32 %[[LOAD_VAL_PHI]], i32 %{{.*}} monotonic monotonic, align 4
// CHECK:  %[[LOAD_VAL]] = extractvalue { i32, i1 } %[[VAL_SUCCESS]], 0
// CHECK:  br i1 %{{.*}}, label %.atomic.exit, label %.atomic.cont

llvm.func @atomic_update_cmpxchg(%arg0: !llvm.ptr, %arg1: !llvm.ptr) {
  %0 = llvm.load %arg1 : !llvm.ptr -> f32
  omp.atomic.update %arg0 : !llvm.ptr {
  ^bb0(%arg2: i32):
    %1 = llvm.sitofp %arg2 : i32 to f32
    %2 = llvm.fadd %1, %0 : f32
    %3 = llvm.fptosi %2 : f32 to i32
    omp.yield(%3 : i32)
  }
  llvm.return
}

// -----

// CHECK-LABEL: @omp_atomic_capture_prefix_update
// CHECK-SAME: (ptr %[[x:.*]], ptr %[[v:.*]], i32 %[[expr:.*]], ptr %[[xf:.*]], ptr %[[vf:.*]], float %[[exprf:.*]])
llvm.func @omp_atomic_capture_prefix_update(
  %x: !llvm.ptr, %v: !llvm.ptr, %expr: i32,
  %xf: !llvm.ptr, %vf: !llvm.ptr, %exprf: f32) -> () {
  // CHECK: %[[res:.*]] = atomicrmw add ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK-NEXT: %[[newval:.*]] = add i32 %[[res]], %[[expr]]
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.add %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[res:.*]] = atomicrmw sub ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK-NEXT: %[[newval:.*]] = sub i32 %[[res]], %[[expr]]
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.sub %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[res:.*]] = atomicrmw and ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK-NEXT: %[[newval:.*]] = and i32 %[[res]], %[[expr]]
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.and %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[res:.*]] = atomicrmw or ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK-NEXT: %[[newval:.*]] = or i32 %[[res]], %[[expr]]
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.or %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[res:.*]] = atomicrmw xor ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK-NEXT: %[[newval:.*]] = xor i32 %[[res]], %[[expr]]
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.xor %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = mul i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.mul %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = sdiv i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.sdiv %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = udiv i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.udiv %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = shl i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.shl %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = lshr i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.lshr %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = ashr i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.ashr %xval, %expr : i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = call i32 @llvm.smax.i32(i32 %[[xval]], i32 %[[expr]])
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = "llvm.intr.smax"(%xval, %expr) : (i32, i32) -> i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = call i32 @llvm.smin.i32(i32 %[[xval]], i32 %[[expr]])
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = "llvm.intr.smin"(%xval, %expr) : (i32, i32) -> i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = call i32 @llvm.umax.i32(i32 %[[xval]], i32 %[[expr]])
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = "llvm.intr.umax"(%xval, %expr) : (i32, i32) -> i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = call i32 @llvm.umin.i32(i32 %[[xval]], i32 %[[expr]])
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[newval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = "llvm.intr.umin"(%xval, %expr) : (i32, i32) -> i32
      omp.yield(%newval : i32)
    }
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK: %[[newval:.*]] = fadd float %{{.*}}, %[[exprf]]
  // CHECK: store float %[[newval]], ptr %{{.*}}
  // CHECK: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK: %{{.*}} = cmpxchg ptr %[[xf]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store float %[[newval]], ptr %[[vf]]
  omp.atomic.capture {
    omp.atomic.update %xf : !llvm.ptr {
    ^bb0(%xval: f32):
      %newval = llvm.fadd %xval, %exprf : f32
      omp.yield(%newval : f32)
    }
    omp.atomic.read %vf = %xf : !llvm.ptr, !llvm.ptr, f32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK: %[[newval:.*]] = fsub float %{{.*}}, %[[exprf]]
  // CHECK: store float %[[newval]], ptr %{{.*}}
  // CHECK: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK: %{{.*}} = cmpxchg ptr %[[xf]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store float %[[newval]], ptr %[[vf]]
  omp.atomic.capture {
    omp.atomic.update %xf : !llvm.ptr {
    ^bb0(%xval: f32):
      %newval = llvm.fsub %xval, %exprf : f32
      omp.yield(%newval : f32)
    }
    omp.atomic.read %vf = %xf : !llvm.ptr, !llvm.ptr, f32
  }

  llvm.return
}

// -----

// CHECK-LABEL: @omp_atomic_capture_postfix_update
// CHECK-SAME: (ptr %[[x:.*]], ptr %[[v:.*]], i32 %[[expr:.*]], ptr %[[xf:.*]], ptr %[[vf:.*]], float %[[exprf:.*]])
llvm.func @omp_atomic_capture_postfix_update(
  %x: !llvm.ptr, %v: !llvm.ptr, %expr: i32,
  %xf: !llvm.ptr, %vf: !llvm.ptr, %exprf: f32) -> () {
  // CHECK: %[[res:.*]] = atomicrmw add ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK: store i32 %[[res]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.add %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[res:.*]] = atomicrmw sub ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK: store i32 %[[res]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.sub %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[res:.*]] = atomicrmw and ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK: store i32 %[[res]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.and %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[res:.*]] = atomicrmw or ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK: store i32 %[[res]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.or %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[res:.*]] = atomicrmw xor ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK: store i32 %[[res]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.xor %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = mul i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.mul %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = sdiv i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.sdiv %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = udiv i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.udiv %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = shl i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.shl %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = lshr i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.lshr %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = ashr i32 %[[xval]], %[[expr]]
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.ashr %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = call i32 @llvm.smax.i32(i32 %[[xval]], i32 %[[expr]])
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = "llvm.intr.smax"(%xval, %expr) : (i32, i32) -> i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = call i32 @llvm.smin.i32(i32 %[[xval]], i32 %[[expr]])
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = "llvm.intr.smin"(%xval, %expr) : (i32, i32) -> i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = call i32 @llvm.umax.i32(i32 %[[xval]], i32 %[[expr]])
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = "llvm.intr.umax"(%xval, %expr) : (i32, i32) -> i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK-NEXT: %[[newval:.*]] = call i32 @llvm.umin.i32(i32 %[[xval]], i32 %[[expr]])
  // CHECK-NEXT: store i32 %[[newval]], ptr %{{.*}}
  // CHECK-NEXT: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK-NEXT: %{{.*}} = cmpxchg ptr %[[x]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = "llvm.intr.umin"(%xval, %expr) : (i32, i32) -> i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK: %[[xvalf:.*]] = bitcast i32 %[[xval]] to float
  // CHECK: %[[newval:.*]] = fadd float %{{.*}}, %[[exprf]]
  // CHECK: store float %[[newval]], ptr %{{.*}}
  // CHECK: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK: %{{.*}} = cmpxchg ptr %[[xf]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store float %[[xvalf]], ptr %[[vf]]
  omp.atomic.capture {
    omp.atomic.read %vf = %xf : !llvm.ptr, !llvm.ptr, f32
    omp.atomic.update %xf : !llvm.ptr {
    ^bb0(%xval: f32):
      %newval = llvm.fadd %xval, %exprf : f32
      omp.yield(%newval : f32)
    }
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK: %[[xvalf:.*]] = bitcast i32 %[[xval]] to float
  // CHECK: %[[newval:.*]] = fsub float %{{.*}}, %[[exprf]]
  // CHECK: store float %[[newval]], ptr %{{.*}}
  // CHECK: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK: %{{.*}} = cmpxchg ptr %[[xf]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store float %[[xvalf]], ptr %[[vf]]
  omp.atomic.capture {
    omp.atomic.read %vf = %xf : !llvm.ptr, !llvm.ptr, f32
    omp.atomic.update %xf : !llvm.ptr {
    ^bb0(%xval: f32):
      %newval = llvm.fsub %xval, %exprf : f32
      omp.yield(%newval : f32)
    }
  }

  llvm.return
}

// -----
// CHECK-LABEL: @omp_atomic_capture_misc
// CHECK-SAME: (ptr %[[x:.*]], ptr %[[v:.*]], i32 %[[expr:.*]], ptr %[[xf:.*]], ptr %[[vf:.*]], float %[[exprf:.*]])
llvm.func @omp_atomic_capture_misc(
  %x: !llvm.ptr, %v: !llvm.ptr, %expr: i32,
  %xf: !llvm.ptr, %vf: !llvm.ptr, %exprf: f32) -> () {
  // CHECK: %[[xval:.*]] = atomicrmw xchg ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK: store i32 %[[xval]], ptr %[[v]]
  omp.atomic.capture{
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.write %x = %expr : !llvm.ptr, i32
  }

  // CHECK: %[[xval:.*]] = phi i32
  // CHECK: %[[xvalf:.*]] = bitcast i32 %[[xval]] to float
  // CHECK: store float %[[exprf]], ptr %{{.*}}
  // CHECK: %[[newval_:.*]] = load i32, ptr %{{.*}}
  // CHECK: %{{.*}} = cmpxchg ptr %[[xf]], i32 %[[xval]], i32 %[[newval_]] monotonic monotonic
  // CHECK: store float %[[xvalf]], ptr %[[vf]]
  omp.atomic.capture{
    omp.atomic.read %vf = %xf : !llvm.ptr, !llvm.ptr, f32
    omp.atomic.write %xf = %exprf : !llvm.ptr, f32
  }

  // CHECK: %[[res:.*]] = atomicrmw add ptr %[[x]], i32 %[[expr]] seq_cst
  // CHECK: store i32 %[[res]], ptr %[[v]]
  omp.atomic.capture memory_order(seq_cst) {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.add %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[res:.*]] = atomicrmw add ptr %[[x]], i32 %[[expr]] acquire
  // CHECK: store i32 %[[res]], ptr %[[v]]
  omp.atomic.capture memory_order(acquire) {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.add %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[res:.*]] = atomicrmw add ptr %[[x]], i32 %[[expr]] release
  // CHECK: store i32 %[[res]], ptr %[[v]]
  omp.atomic.capture memory_order(release) {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.add %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[res:.*]] = atomicrmw add ptr %[[x]], i32 %[[expr]] monotonic
  // CHECK: store i32 %[[res]], ptr %[[v]]
  omp.atomic.capture memory_order(relaxed) {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.add %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  // CHECK: %[[res:.*]] = atomicrmw add ptr %[[x]], i32 %[[expr]] acq_rel
  // CHECK: store i32 %[[res]], ptr %[[v]]
  omp.atomic.capture memory_order(acq_rel) {
    omp.atomic.read %v = %x : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %x : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.add %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }

  llvm.return
}

// -----

// CHECK-LABEL: @omp_sections_empty
llvm.func @omp_sections_empty() -> () {
  omp.sections {
    omp.terminator
  }
  // CHECK-NEXT: br label %entry
  // CHECK: entry:
  // CHECK-NEXT: ret void
  llvm.return
}

// -----

// Check IR generation for simple empty sections. This only checks the overall
// shape of the IR, detailed checking is done by the OpenMPIRBuilder.

// CHECK-LABEL: @omp_sections_trivial
llvm.func @omp_sections_trivial() -> () {
  // CHECK:   br label %[[ENTRY:[a-zA-Z_.]+]]

  // CHECK: [[ENTRY]]:
  // CHECK:   br label %[[PREHEADER:.*]]

  // CHECK: [[PREHEADER]]:
  // CHECK:   %{{.*}} = call i32 @__kmpc_global_thread_num({{.*}})
  // CHECK:   call void @__kmpc_for_static_init_4u({{.*}})
  // CHECK:   br label %[[HEADER:.*]]

  // CHECK: [[HEADER]]:
  // CHECK:   br label %[[COND:.*]]

  // CHECK: [[COND]]:
  // CHECK:   br i1 %{{.*}}, label %[[BODY:.*]], label %[[EXIT:.*]]
  // CHECK: [[BODY]]:
  // CHECK:   switch i32 %{{.*}}, label %[[INC:.*]] [
  // CHECK-NEXT:     i32 0, label %[[SECTION1:.*]]
  // CHECK-NEXT:     i32 1, label %[[SECTION2:.*]]
  // CHECK-NEXT: ]

  omp.sections {
    omp.section {
      // CHECK: [[SECTION1]]:
      // CHECK-NEXT: br label %[[SECTION1_REGION1:[^ ,]*]]
      // CHECK-EMPTY:
      // CHECK-NEXT: [[SECTION1_REGION1]]:
      // CHECK-NEXT: br label %[[SECTION1_REGION2:[^ ,]*]]
      // CHECK-EMPTY:
      // CHECK-NEXT: [[SECTION1_REGION2]]:
      // CHECK-NEXT: br label %[[INC]]
      omp.terminator
    }
    omp.section {
      // CHECK: [[SECTION2]]:
      // CHECK: br label %[[INC]]
      omp.terminator
    }
    omp.terminator
  }

  // CHECK: [[INC]]:
  // CHECK:   %{{.*}} = add {{.*}}, 1
  // CHECK:   br label %[[HEADER]]

  // CHECK: [[EXIT]]:
  // CHECK:   call void @__kmpc_for_static_fini({{.*}})
  // CHECK:   call void @__kmpc_barrier({{.*}})
  // CHECK:   br label %[[AFTER:.*]]

  // CHECK: [[AFTER]]:
  // CHECK:   ret void
  llvm.return
}

// -----

// CHECK: declare void @foo()
llvm.func @foo()

// CHECK: declare void @bar(i32)
llvm.func @bar(%arg0 : i32)

// CHECK-LABEL: @omp_sections
llvm.func @omp_sections(%arg0 : i32, %arg1 : i32, %arg2 : !llvm.ptr) -> () {

  // CHECK: switch i32 %{{.*}}, label %{{.*}} [
  // CHECK-NEXT:   i32 0, label %[[SECTION1:.*]]
  // CHECK-NEXT:   i32 1, label %[[SECTION2:.*]]
  // CHECK-NEXT:   i32 2, label %[[SECTION3:.*]]
  // CHECK-NEXT: ]
  omp.sections {
    omp.section {
      // CHECK: [[SECTION1]]:
      // CHECK:   br label %[[REGION1:[^ ,]*]]
      // CHECK: [[REGION1]]:
      // CHECK:   call void @foo()
      // CHECK:   br label %{{.*}}
      llvm.call @foo() : () -> ()
      omp.terminator
    }
    omp.section {
      // CHECK: [[SECTION2]]:
      // CHECK:   br label %[[REGION2:[^ ,]*]]
      // CHECK: [[REGION2]]:
      // CHECK:   call void @bar(i32 %{{.*}})
      // CHECK:   br label %{{.*}}
      llvm.call @bar(%arg0) : (i32) -> ()
      omp.terminator
    }
    omp.section {
      // CHECK: [[SECTION3]]:
      // CHECK:   br label %[[REGION3:[^ ,]*]]
      // CHECK: [[REGION3]]:
      // CHECK:   %11 = add i32 %{{.*}}, %{{.*}}
      %add = llvm.add %arg0, %arg1 : i32
      // CHECK:   store i32 %{{.*}}, ptr %{{.*}}, align 4
      // CHECK:   br label %{{.*}}
      llvm.store %add, %arg2 : i32, !llvm.ptr
      omp.terminator
    }
    omp.terminator
  }
  llvm.return
}

// -----

llvm.func @foo()

// CHECK-LABEL: @omp_sections_with_clauses
llvm.func @omp_sections_with_clauses() -> () {
  // CHECK-NOT: call void @__kmpc_barrier
  omp.sections nowait {
    omp.section {
      llvm.call @foo() : () -> ()
      omp.terminator
    }
    omp.section {
      llvm.call @foo() : () -> ()
      omp.terminator
    }
    omp.terminator
  }
  llvm.return
}

// -----

// Check that translation doesn't crash in presence of repeated successor
// blocks with different arguments within OpenMP operations: LLVM cannot
// represent this and a dummy block will be introduced for forwarding. The
// introduction mechanism itself is tested elsewhere.
// CHECK-LABEL: @repeated_successor
llvm.func @repeated_successor(%arg0: i64, %arg1: i64, %arg2: i64, %arg3: i1) {
  omp.wsloop {
    omp.loop_nest (%arg4) : i64 = (%arg0) to (%arg1) step (%arg2)  {
      llvm.cond_br %arg3, ^bb1(%arg0 : i64), ^bb1(%arg1 : i64)
    ^bb1(%0: i64):  // 2 preds: ^bb0, ^bb0
      omp.yield
    }
  }
  llvm.return
}

// -----

// CHECK-LABEL: @single
// CHECK-SAME: (i32 %[[x:.*]], i32 %[[y:.*]], ptr %[[zaddr:.*]])
llvm.func @single(%x: i32, %y: i32, %zaddr: !llvm.ptr) {
  // CHECK: %[[a:.*]] = sub i32 %[[x]], %[[y]]
  %a = llvm.sub %x, %y : i32
  // CHECK: store i32 %[[a]], ptr %[[zaddr]]
  llvm.store %a, %zaddr : i32, !llvm.ptr
  // CHECK: call i32 @__kmpc_single
  omp.single {
    // CHECK: %[[z:.*]] = add i32 %[[x]], %[[y]]
    %z = llvm.add %x, %y : i32
    // CHECK: store i32 %[[z]], ptr %[[zaddr]]
    llvm.store %z, %zaddr : i32, !llvm.ptr
    // CHECK: call void @__kmpc_end_single
    // CHECK: call void @__kmpc_barrier
    omp.terminator
  }
  // CHECK: %[[b:.*]] = mul i32 %[[x]], %[[y]]
  %b = llvm.mul %x, %y : i32
  // CHECK: store i32 %[[b]], ptr %[[zaddr]]
  llvm.store %b, %zaddr : i32, !llvm.ptr
  // CHECK: ret void
  llvm.return
}

// -----

// CHECK-LABEL: @single_nowait
// CHECK-SAME: (i32 %[[x:.*]], i32 %[[y:.*]], ptr %[[zaddr:.*]])
llvm.func @single_nowait(%x: i32, %y: i32, %zaddr: !llvm.ptr) {
  // CHECK: %[[a:.*]] = sub i32 %[[x]], %[[y]]
  %a = llvm.sub %x, %y : i32
  // CHECK: store i32 %[[a]], ptr %[[zaddr]]
  llvm.store %a, %zaddr : i32, !llvm.ptr
  // CHECK: call i32 @__kmpc_single
  omp.single nowait {
    // CHECK: %[[z:.*]] = add i32 %[[x]], %[[y]]
    %z = llvm.add %x, %y : i32
    // CHECK: store i32 %[[z]], ptr %[[zaddr]]
    llvm.store %z, %zaddr : i32, !llvm.ptr
    // CHECK: call void @__kmpc_end_single
    // CHECK-NOT: call void @__kmpc_barrier
    omp.terminator
  }
  // CHECK: %[[t:.*]] = mul i32 %[[x]], %[[y]]
  %t = llvm.mul %x, %y : i32
  // CHECK: store i32 %[[t]], ptr %[[zaddr]]
  llvm.store %t, %zaddr : i32, !llvm.ptr
  // CHECK: ret void
  llvm.return
}

// -----

llvm.func @copy_i32(!llvm.ptr, !llvm.ptr)
llvm.func @copy_f32(!llvm.ptr, !llvm.ptr)

// CHECK-LABEL: @single_copyprivate
// CHECK-SAME: (ptr %[[ip:.*]], ptr %[[fp:.*]])
llvm.func @single_copyprivate(%ip: !llvm.ptr, %fp: !llvm.ptr) {
  // CHECK: %[[didit_addr:.*]] = alloca i32
  // CHECK: store i32 0, ptr %[[didit_addr]]
  // CHECK: call i32 @__kmpc_single
  omp.single copyprivate(%ip -> @copy_i32 : !llvm.ptr, %fp -> @copy_f32 : !llvm.ptr) {
    // CHECK: %[[i:.*]] = load i32, ptr %[[ip]]
    %i = llvm.load %ip : !llvm.ptr -> i32
    // CHECK: %[[i2:.*]] = add i32 %[[i]], %[[i]]
    %i2 = llvm.add %i, %i : i32
    // CHECK: store i32 %[[i2]], ptr %[[ip]]
    llvm.store %i2, %ip : i32, !llvm.ptr
    // CHECK: %[[f:.*]] = load float, ptr %[[fp]]
    %f = llvm.load %fp : !llvm.ptr -> f32
    // CHECK: %[[f2:.*]] = fadd float %[[f]], %[[f]]
    %f2 = llvm.fadd %f, %f : f32
    // CHECK: store float %[[f2]], ptr %[[fp]]
    llvm.store %f2, %fp : f32, !llvm.ptr
    // CHECK: store i32 1, ptr %[[didit_addr]]
    // CHECK: call void @__kmpc_end_single
    // CHECK: %[[didit:.*]] = load i32, ptr %[[didit_addr]]
    // CHECK: call void @__kmpc_copyprivate({{.*}}, ptr %[[ip]], ptr @copy_i32, i32 %[[didit]])
    // CHECK: %[[didit2:.*]] = load i32, ptr %[[didit_addr]]
    // CHECK: call void @__kmpc_copyprivate({{.*}}, ptr %[[fp]], ptr @copy_f32, i32 %[[didit2]])
    // CHECK-NOT: call void @__kmpc_barrier
    omp.terminator
  }
  // CHECK: ret void
  llvm.return
}

// -----

// CHECK: @_QFsubEx = internal global i32 undef
// CHECK: @_QFsubEx.cache = common global ptr null

// CHECK-LABEL: @omp_threadprivate
llvm.func @omp_threadprivate() {
// CHECK:  [[THREAD:%.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GLOB:[0-9]+]])
// CHECK:  [[TMP1:%.*]] = call ptr @__kmpc_threadprivate_cached(ptr @[[GLOB]], i32 [[THREAD]], ptr @_QFsubEx, i64 4, ptr @_QFsubEx.cache)
// CHECK:  store i32 1, ptr [[TMP1]], align 4
// CHECK:  store i32 3, ptr [[TMP1]], align 4

// CHECK-LABEL: omp.par.region{{.*}}
// CHECK:  [[THREAD2:%.*]] = call i32 @__kmpc_global_thread_num(ptr @[[GLOB2:[0-9]+]])
// CHECK:  [[TMP3:%.*]] = call ptr @__kmpc_threadprivate_cached(ptr @[[GLOB2]], i32 [[THREAD2]], ptr @_QFsubEx, i64 4, ptr @_QFsubEx.cache)
// CHECK:  store i32 2, ptr [[TMP3]], align 4

  %0 = llvm.mlir.constant(1 : i32) : i32
  %1 = llvm.mlir.constant(2 : i32) : i32
  %2 = llvm.mlir.constant(3 : i32) : i32

  %3 = llvm.mlir.addressof @_QFsubEx : !llvm.ptr
  %4 = omp.threadprivate %3 : !llvm.ptr -> !llvm.ptr

  llvm.store %0, %4 : i32, !llvm.ptr

  omp.parallel  {
    %5 = omp.threadprivate %3 : !llvm.ptr -> !llvm.ptr
    llvm.store %1, %5 : i32, !llvm.ptr
    omp.terminator
  }

  llvm.store %2, %4 : i32, !llvm.ptr
  llvm.return
}

llvm.mlir.global internal @_QFsubEx() : i32

// -----

// CHECK-LABEL: define void @omp_task_detach
// CHECK-SAME: (ptr %[[event_handle:.*]])
llvm.func @omp_task_detach(%event_handle : !llvm.ptr){
   // CHECK: %[[omp_global_thread_num:.+]] = call i32 @__kmpc_global_thread_num({{.+}})
   // CHECK: %[[task_data:.+]] = call ptr @__kmpc_omp_task_alloc
   // CHECK: %[[return_val:.*]] = call ptr @__kmpc_task_allow_completion_event(ptr {{.*}}, i32 %[[omp_global_thread_num]], ptr %[[task_data]])
   // CHECK: %[[conv:.*]] = ptrtoint ptr %[[return_val]] to i64
   // CHECK: store i64 %[[conv]], ptr %[[event_handle]], align 4
   // CHECK: call i32 @__kmpc_omp_task(ptr @{{.+}}, i32 %[[omp_global_thread_num]], ptr %[[task_data]])
   omp.task detach(%event_handle : !llvm.ptr){
     omp.terminator
   }
   llvm.return
}

// -----

// CHECK-LABEL: define void @omp_task
// CHECK-SAME: (i32 %[[x:.+]], i32 %[[y:.+]], ptr %[[zaddr:.+]])
llvm.func @omp_task(%x: i32, %y: i32, %zaddr: !llvm.ptr) {
  // CHECK: %[[omp_global_thread_num:.+]] = call i32 @__kmpc_global_thread_num({{.+}})
  // CHECK: %[[task_data:.+]] = call ptr @__kmpc_omp_task_alloc
  // CHECK-SAME: (ptr @{{.+}}, i32 %[[omp_global_thread_num]], i32 1, i64 40,
  // CHECK-SAME:  i64 0, ptr @[[outlined_fn:.+]])
  // CHECK: call i32 @__kmpc_omp_task(ptr @{{.+}}, i32 %[[omp_global_thread_num]], ptr %[[task_data]])
  omp.task {
    %n = llvm.mlir.constant(1 : i64) : i64
    %valaddr = llvm.alloca %n x i32 : (i64) -> !llvm.ptr
    %val = llvm.load %valaddr : !llvm.ptr -> i32
    %double = llvm.add %val, %val : i32
    llvm.store %double, %valaddr : i32, !llvm.ptr
    omp.terminator
  }
  llvm.return
}

// CHECK: define internal void @[[outlined_fn]](i32 %[[global_tid:[^ ,]+]])
// CHECK: task.alloca{{.*}}:
// CHECK:   br label %[[task_body:[^, ]+]]
// CHECK: [[task_body]]:
// CHECK:   br label %[[task_region:[^, ]+]]
// CHECK: [[task_region]]:
// CHECK:   %[[alloca:.+]] = alloca i32, i64 1
// CHECK:   %[[val:.+]] = load i32, ptr %[[alloca]]
// CHECK:   %[[newval:.+]] = add i32 %[[val]], %[[val]]
// CHECK:   store i32 %[[newval]], ptr %{{[^, ]+}}
// CHECK:   br label %[[exit_stub:[^, ]+]]
// CHECK: [[exit_stub]]:
// CHECK:   ret void

// -----

// CHECK-LABEL: define void @omp_task_attrs()
llvm.func @omp_task_attrs() -> () attributes {
  target_cpu = "x86-64",
  target_features = #llvm.target_features<["+mmx", "+sse"]>
} {
  // CHECK: %[[task_data:.*]] = call {{.*}}@__kmpc_omp_task_alloc{{.*}}@[[outlined_fn:.*]])
  // CHECK: call {{.*}}@__kmpc_omp_task(
  // CHECK-SAME: ptr %[[task_data]]
  omp.task {
    omp.terminator
  }

  llvm.return
}

// CHECK: define {{.*}} @[[outlined_fn]]{{.*}} #[[attrs:[0-9]+]]
// CHECK: attributes #[[attrs]] = {
// CHECK-SAME: "target-cpu"="x86-64"
// CHECK-SAME: "target-features"="+mmx,+sse"

// -----

// CHECK-LABEL: define void @omp_task_with_deps
// CHECK-SAME: (ptr %[[zaddr:.+]])
// CHECK:  %[[dep_arr_addr:.+]] = alloca [1 x %struct.kmp_dep_info], align 8
// CHECK:  %[[DEP_ARR_ADDR1:.+]] = alloca [1 x %struct.kmp_dep_info], align 8
// CHECK:  %[[DEP_ARR_ADDR2:.+]] = alloca [1 x %struct.kmp_dep_info], align 8
// CHECK:  %[[DEP_ARR_ADDR3:.+]] = alloca [1 x %struct.kmp_dep_info], align 8
// CHECK:  %[[DEP_ARR_ADDR4:.+]] = alloca [1 x %struct.kmp_dep_info], align 8

// CHECK: %[[omp_global_thread_num:.+]] = call i32 @__kmpc_global_thread_num({{.+}})
// CHECK: %[[task_data:.+]] = call ptr @__kmpc_omp_task_alloc
// CHECK-SAME: (ptr @{{.+}}, i32 %[[omp_global_thread_num]], i32 1, i64 40,
// CHECK-SAME:  i64 0, ptr @[[outlined_fn:.+]])

// CHECK:  %[[dep_arr_addr_0:.+]] = getelementptr inbounds [1 x %struct.kmp_dep_info], ptr %[[dep_arr_addr]], i64 0, i64 0
// CHECK:  %[[dep_arr_addr_0_val:.+]] = getelementptr inbounds nuw %struct.kmp_dep_info, ptr %[[dep_arr_addr_0]], i32 0, i32 0
// CHECK:  %[[dep_arr_addr_0_val_int:.+]] = ptrtoint ptr %0 to i64
// CHECK:  store i64 %[[dep_arr_addr_0_val_int]], ptr %[[dep_arr_addr_0_val]], align 4
// CHECK:  %[[dep_arr_addr_0_size:.+]] = getelementptr inbounds nuw %struct.kmp_dep_info, ptr %[[dep_arr_addr_0]], i32 0, i32 1
// CHECK:  store i64 8, ptr %[[dep_arr_addr_0_size]], align 4
// CHECK:  %[[dep_arr_addr_0_kind:.+]] = getelementptr inbounds nuw %struct.kmp_dep_info, ptr %[[dep_arr_addr_0]], i32 0, i32 2
// CHECK: store i8 1, ptr %[[dep_arr_addr_0_kind]], align 1

// CHECK: call i32 @__kmpc_omp_task_with_deps(ptr @{{.+}}, i32 %[[omp_global_thread_num]], ptr %[[task_data]], {{.*}})
// -----
// dependence_type: Out
// CHECK:  %[[DEP_ARR_ADDR_1:.+]] = getelementptr inbounds [1 x %struct.kmp_dep_info], ptr %[[DEP_ARR_ADDR1]], i64 0, i64 0
//         [...]
// CHECK:  %[[DEP_TYPE_1:.+]] = getelementptr inbounds nuw %struct.kmp_dep_info, ptr %[[DEP_ARR_ADDR_1]], i32 0, i32 2
// CHECK:  store i8 3, ptr %[[DEP_TYPE_1]], align 1
// -----
// dependence_type: Inout
// CHECK:  %[[DEP_ARR_ADDR_2:.+]] = getelementptr inbounds [1 x %struct.kmp_dep_info], ptr %[[DEP_ARR_ADDR2]], i64 0, i64 0
//         [...]
// CHECK:  %[[DEP_TYPE_2:.+]] = getelementptr inbounds nuw %struct.kmp_dep_info, ptr %[[DEP_ARR_ADDR_2]], i32 0, i32 2
// CHECK:  store i8 3, ptr %[[DEP_TYPE_2]], align 1
// -----
// dependence_type: Mutexinoutset
// CHECK:  %[[DEP_ARR_ADDR_3:.+]] = getelementptr inbounds [1 x %struct.kmp_dep_info], ptr %[[DEP_ARR_ADDR3]], i64 0, i64 0
//         [...]
// CHECK:  %[[DEP_TYPE_3:.+]] = getelementptr inbounds nuw %struct.kmp_dep_info, ptr %[[DEP_ARR_ADDR_3]], i32 0, i32 2
// CHECK:  store i8 4, ptr %[[DEP_TYPE_3]], align 1
// -----
// dependence_type: Inoutset
// CHECK:  %[[DEP_ARR_ADDR_4:.+]] = getelementptr inbounds [1 x %struct.kmp_dep_info], ptr %[[DEP_ARR_ADDR4]], i64 0, i64 0
//         [...]
// CHECK:  %[[DEP_TYPE_4:.+]] = getelementptr inbounds nuw %struct.kmp_dep_info, ptr %[[DEP_ARR_ADDR_4]], i32 0, i32 2
// CHECK:  store i8 8, ptr %[[DEP_TYPE_4]], align 1
llvm.func @omp_task_with_deps(%zaddr: !llvm.ptr) {
  omp.task depend(taskdependin -> %zaddr : !llvm.ptr) {
    %n = llvm.mlir.constant(1 : i64) : i64
    %valaddr = llvm.alloca %n x i32 : (i64) -> !llvm.ptr
    %val = llvm.load %valaddr : !llvm.ptr -> i32
    %double = llvm.add %val, %val : i32
    llvm.store %double, %valaddr : i32, !llvm.ptr
    omp.terminator
  }
  omp.task depend(taskdependout -> %zaddr : !llvm.ptr) {
    omp.terminator
  }
  omp.task depend(taskdependinout -> %zaddr : !llvm.ptr) {
    omp.terminator
  }
  omp.task depend(taskdependmutexinoutset -> %zaddr : !llvm.ptr) {
    omp.terminator
  }
  omp.task depend(taskdependinoutset -> %zaddr : !llvm.ptr) {
    omp.terminator
  }
  llvm.return
}

// CHECK: define internal void @[[outlined_fn]](i32 %[[global_tid:[^ ,]+]])
// CHECK: task.alloca{{.*}}:
// CHECK:   br label %[[task_body:[^, ]+]]
// CHECK: [[task_body]]:
// CHECK:   br label %[[task_region:[^, ]+]]
// CHECK: [[task_region]]:
// CHECK:   %[[alloca:.+]] = alloca i32, i64 1
// CHECK:   %[[val:.+]] = load i32, ptr %[[alloca]]
// CHECK:   %[[newval:.+]] = add i32 %[[val]], %[[val]]
// CHECK:   store i32 %[[newval]], ptr %{{[^, ]+}}
// CHECK:   br label %[[exit_stub:[^, ]+]]
// CHECK: [[exit_stub]]:
// CHECK:   ret void

// -----

// CHECK-LABEL: define void @omp_task
// CHECK-SAME: (i32 %[[x:.+]], i32 %[[y:.+]], ptr %[[zaddr:.+]])
module attributes {llvm.target_triple = "x86_64-unknown-linux-gnu"} {
  llvm.func @omp_task(%x: i32, %y: i32, %zaddr: !llvm.ptr) {
    // CHECK: %[[diff:.+]] = sub i32 %[[x]], %[[y]]
    %diff = llvm.sub %x, %y : i32
    // CHECK: store i32 %[[diff]], ptr %2
    llvm.store %diff, %zaddr : i32, !llvm.ptr
    // CHECK: %[[omp_global_thread_num:.+]] = call i32 @__kmpc_global_thread_num({{.+}})
    // CHECK: %[[task_data:.+]] = call ptr @__kmpc_omp_task_alloc
    // CHECK-SAME: (ptr @{{.+}}, i32 %[[omp_global_thread_num]], i32 1, i64 40, i64 16,
    // CHECK-SAME: ptr @[[outlined_fn:.+]])
    // CHECK: %[[shareds:.+]] = load ptr, ptr %[[task_data]]
    // CHECK: call void @llvm.memcpy.p0.p0.i64(ptr {{.+}} %[[shareds]], ptr {{.+}}, i64 16, i1 false)
    // CHECK: call i32 @__kmpc_omp_task(ptr @{{.+}}, i32 %[[omp_global_thread_num]], ptr %[[task_data]])
    omp.task {
      %z = llvm.add %x, %y : i32
      llvm.store %z, %zaddr : i32, !llvm.ptr
      omp.terminator
    }
    // CHECK: %[[prod:.+]] = mul i32 %[[x]], %[[y]]
    %b = llvm.mul %x, %y : i32
    // CHECK: store i32 %[[prod]], ptr %[[zaddr]]
    llvm.store %b, %zaddr : i32, !llvm.ptr
    llvm.return
  }
}

// CHECK: define internal void @[[outlined_fn]](i32 %[[global_tid:[^ ,]+]], ptr %[[task_data:.+]])
// CHECK: task.alloca{{.*}}:
// CHECK:   %[[shareds:.+]] = load ptr, ptr %[[task_data]]
// CHECK:   br label %[[task_body:[^, ]+]]
// CHECK: [[task_body]]:
// CHECK:   br label %[[task_region:[^, ]+]]
// CHECK: [[task_region]]:
// CHECK:   %[[sum:.+]] = add i32 %{{.+}}, %{{.+}}
// CHECK:   store i32 %[[sum]], ptr %{{.+}}
// CHECK:   br label %[[exit_stub:[^, ]+]]
// CHECK: [[exit_stub]]:
// CHECK:   ret void

// -----

llvm.func @par_task_(%arg0: !llvm.ptr {fir.bindc_name = "a"}) {
  %0 = llvm.mlir.constant(1 : i32) : i32
  omp.task   {
    omp.parallel   {
      llvm.store %0, %arg0 : i32, !llvm.ptr
      omp.terminator
    }
    omp.terminator
  }
  llvm.return
}

// CHECK-LABEL: @par_task_
// CHECK: %[[ARG_ALLOC:.*]] = alloca { ptr }, align 8
// CHECK: %[[TASK_ALLOC:.*]] = call ptr @__kmpc_omp_task_alloc({{.*}}ptr @[[task_outlined_fn:.+]])
// CHECK: call i32 @__kmpc_omp_task({{.*}}, ptr %[[TASK_ALLOC]])
// CHECK: define internal void @[[task_outlined_fn]](i32 %[[GLOBAL_TID_VAL:.*]], ptr %[[STRUCT_ARG:.*]])
// CHECK: %[[LOADED_STRUCT_PTR:.*]] = load ptr, ptr %[[STRUCT_ARG]], align 8
// CHECK: %[[GEP_STRUCTARG:.*]] = getelementptr { ptr }, ptr %[[LOADED_STRUCT_PTR]], i32 0, i32 0
// CHECK: %[[LOADGEP_STRUCTARG:.*]] = load ptr, ptr %[[GEP_STRUCTARG]], align 8
// CHEKC: %[[NEW_STRUCTARG:.*]] = alloca { ptr }, align 8
// CHECK: call void ({{.*}}) @__kmpc_fork_call({{.*}}, ptr @[[parallel_outlined_fn:.+]],
// CHECK: define internal void @[[parallel_outlined_fn]]
// -----

llvm.func @foo(!llvm.ptr) -> ()
llvm.func @destroy(!llvm.ptr) -> ()

omp.private {type = firstprivate} @privatizer : i32 copy {
^bb0(%arg0: !llvm.ptr, %arg1: !llvm.ptr):
  %0 = llvm.load %arg0 : !llvm.ptr -> i32
  llvm.store %0, %arg1 : i32, !llvm.ptr
  omp.yield(%arg1 : !llvm.ptr)
} dealloc {
^bb0(%arg0 : !llvm.ptr):
  llvm.call @destroy(%arg0) : (!llvm.ptr) -> ()
  omp.yield
}

llvm.func @task(%arg0 : !llvm.ptr) {
  omp.task private(@privatizer %arg0 -> %arg1 : !llvm.ptr) {
    llvm.call @foo(%arg1) : (!llvm.ptr) -> ()
    omp.terminator
  }
  llvm.return
}
// CHECK-LABEL: @task
// CHECK-SAME:      (ptr %[[ARG:.*]])
// CHECK:         %[[STRUCT_ARG:.*]] = alloca { ptr }, align 8
//                ...
// CHECK:         br label %omp.private.init
// CHECK:       omp.private.init:
// CHECK:         %[[TASK_STRUCT:.*]] = tail call ptr @malloc(i64 ptrtoint (ptr getelementptr ({ i32 }, ptr null, i32 1) to i64))
// CHECK:         %[[GEP:.*]] = getelementptr { i32 }, ptr %[[TASK_STRUCT:.*]], i32 0, i32 0
// CHECK:         br label %omp.private.copy1
// CHECK:       omp.private.copy1:
// CHECK:         %[[LOADED:.*]] = load i32, ptr %[[ARG]], align 4
// CHECK:         store i32 %[[LOADED]], ptr %[[GEP]], align 4
//                ...
// CHECK:         br label %omp.task.start
// CHECK:       omp.task.start:
// CHECK:         br label %[[CODEREPL:.*]]
// CHECK:       [[CODEREPL]]:

// CHECK-LABEL: @task..omp_par
// CHECK:      task.alloca:
// CHECK:         %[[VAL_12:.*]] = load ptr, ptr %[[STRUCT_ARG:.*]], align 8
// CHECK:         %[[VAL_13:.*]] = getelementptr { ptr }, ptr %[[VAL_12]], i32 0, i32 0
// CHECK:         %[[VAL_14:.*]] = load ptr, ptr %[[VAL_13]], align 8
// CHECK:         br label %task.body
// CHECK:       task.body:                                        ; preds = %task.alloca
// CHECK:         %[[VAL_15:.*]] = getelementptr { i32 }, ptr %[[VAL_14]], i32 0, i32 0
// CHECK:         br label %omp.task.region
// CHECK:       omp.task.region:                                  ; preds = %task.body
// CHECK:         call void @foo(ptr %[[VAL_15]])
// CHECK:         br label %omp.region.cont
// CHECK:       omp.region.cont:                                  ; preds = %omp.task.region
// CHECK:         call void @destroy(ptr %[[VAL_15]])
// CHECK:         br label %task.exit.exitStub
// CHECK:       task.exit.exitStub:                               ; preds = %omp.region.cont
// CHECK:         ret void
// -----

llvm.func @foo() -> ()

llvm.func @omp_taskgroup(%x: i32, %y: i32, %zaddr: !llvm.ptr) {
  omp.taskgroup {
    llvm.call @foo() : () -> ()
    omp.terminator
  }
  llvm.return
}

// CHECK-LABEL: define void @omp_taskgroup(
// CHECK-SAME:                             i32 %[[x:.+]], i32 %[[y:.+]], ptr %[[zaddr:.+]])
// CHECK:         br label %[[entry:[^,]+]]
// CHECK:       [[entry]]:
// CHECK:         %[[omp_global_thread_num:.+]] = call i32 @__kmpc_global_thread_num(ptr @{{.+}})
// CHECK:         call void @__kmpc_taskgroup(ptr @{{.+}}, i32 %[[omp_global_thread_num]])
// CHECK:         br label %[[omp_taskgroup_region:[^,]+]]
// CHECK:       [[omp_taskgroup_region]]:
// CHECK:         call void @foo()
// CHECK:         br label %[[omp_region_cont:[^,]+]]
// CHECK:       [[omp_region_cont]]:
// CHECK:         br label %[[taskgroup_exit:[^,]+]]
// CHECK:       [[taskgroup_exit]]:
// CHECK:         call void @__kmpc_end_taskgroup(ptr @{{.+}}, i32 %[[omp_global_thread_num]])
// CHECK:         ret void

// -----

llvm.func @foo() -> ()
llvm.func @bar(i32, i32, !llvm.ptr) -> ()

llvm.func @omp_taskgroup_task(%x: i32, %y: i32, %zaddr: !llvm.ptr) {
  omp.taskgroup {
    %c1 = llvm.mlir.constant(1) : i32
    %ptr1 = llvm.alloca %c1 x i8 : (i32) -> !llvm.ptr
    omp.task {
      llvm.call @foo() : () -> ()
      omp.terminator
    }
    omp.task {
      llvm.call @bar(%x, %y, %zaddr) : (i32, i32, !llvm.ptr) -> ()
      omp.terminator
    }
    llvm.br ^bb1
  ^bb1:
    llvm.call @foo() : () -> ()
    omp.terminator
  }
  llvm.return
}

// CHECK-LABEL: define void @omp_taskgroup_task(
// CHECK-SAME:                                  i32 %[[x:.+]], i32 %[[y:.+]], ptr %[[zaddr:.+]])
// CHECK:         %[[structArg:.+]] = alloca { i32, i32, ptr }, align 8
// CHECK:         br label %[[entry:[^,]+]]
// CHECK:       [[entry]]:                                            ; preds = %3
// CHECK:         %[[omp_global_thread_num:.+]] = call i32 @__kmpc_global_thread_num(ptr @{{.+}})
// CHECK:         call void @__kmpc_taskgroup(ptr @{{.+}}, i32 %[[omp_global_thread_num]])
// CHECK:         br label %[[omp_taskgroup_region:[^,]+]]
// CHECK:       [[omp_taskgroup_region1:.+]]:
// CHECK:         call void @foo()
// CHECK:         br label %[[omp_region_cont:[^,]+]]
// CHECK:       [[omp_taskgroup_region]]:
// CHECK:         %{{.+}} = alloca i8, align 1
// CHECK:         br label %[[omp_private_init:[^,]+]]
// CHECK:       [[omp_private_init]]:
// CHECK:         br label %[[omp_private_copy:[^,]+]]
// CHECK:       [[omp_private_copy]]:
// CHECK:         br label %[[omp_task_start:[^,]+]]

// CHECK:       [[omp_region_cont:[^,]+]]:
// CHECK:         br label %[[taskgroup_exit:[^,]+]]
// CHECK:       [[taskgroup_exit]]:
// CHECK:         call void @__kmpc_end_taskgroup(ptr @{{.+}}, i32 %[[omp_global_thread_num]])
// CHECK:         ret void

// CHECK:       [[omp_task_start]]:
// CHECK:         br label %[[codeRepl:[^,]+]]
// CHECK:       [[codeRepl]]:
// CHECK:         %[[omp_global_thread_num_t1:.+]] = call i32 @__kmpc_global_thread_num(ptr @{{.+}})
// CHECK:         %[[t1_alloc:.+]] = call ptr @__kmpc_omp_task_alloc(ptr @{{.+}}, i32 %[[omp_global_thread_num_t1]], i32 1, i64 40, i64 0, ptr @[[outlined_task_fn:.+]])
// CHECK:         %{{.+}} = call i32 @__kmpc_omp_task(ptr @{{.+}}, i32 %[[omp_global_thread_num_t1]], ptr %[[t1_alloc]])
// CHECK:         br label %[[task_exit:[^,]+]]
// CHECK:       [[task_exit]]:
// CHECK:         br label %[[codeRepl9:[^,]+]]
// CHECK:       [[codeRepl9]]:
// CHECK:         %[[gep1:.+]] = getelementptr { i32, i32, ptr }, ptr %[[structArg]], i32 0, i32 0
// CHECK:         store i32 %[[x]], ptr %[[gep1]], align 4
// CHECK:         %[[gep2:.+]] = getelementptr { i32, i32, ptr }, ptr %[[structArg]], i32 0, i32 1
// CHECK:         store i32 %[[y]], ptr %[[gep2]], align 4
// CHECK:         %[[gep3:.+]] = getelementptr { i32, i32, ptr }, ptr %[[structArg]], i32 0, i32 2
// CHECK:         store ptr %[[zaddr]], ptr %[[gep3]], align 8
// CHECK:         %[[omp_global_thread_num_t2:.+]] = call i32 @__kmpc_global_thread_num(ptr @{{.+}})
// CHECK:         %[[t2_alloc:.+]] = call ptr @__kmpc_omp_task_alloc(ptr @{{.+}}, i32 %[[omp_global_thread_num_t2]], i32 1, i64 40, i64 16, ptr @[[outlined_task_fn:.+]])
// CHECK:         %[[shareds:.+]] = load ptr, ptr %[[t2_alloc]]
// CHECK:         call void @llvm.memcpy.p0.p0.i64(ptr align 1 %[[shareds]], ptr align 1 %[[structArg]], i64 16, i1 false)
// CHECK:         %{{.+}} = call i32 @__kmpc_omp_task(ptr @{{.+}}, i32 %[[omp_global_thread_num_t2]], ptr %[[t2_alloc]])
// CHECK:         br label %[[task_exit3:[^,]+]]
// CHECK:       [[task_exit3]]:
// CHECK:         br label %[[omp_taskgroup_region1]]
// CHECK:       }

// -----

llvm.func @test_01() attributes {sym_visibility = "private"}
llvm.func @test_02() attributes {sym_visibility = "private"}
// CHECK-LABEL: define void @_QPomp_task_priority() {
llvm.func @_QPomp_task_priority() {
  %0 = llvm.mlir.constant(1 : i64) : i64
  %1 = llvm.alloca %0 x i32 {bindc_name = "x"} : (i64) -> !llvm.ptr
  %2 = llvm.mlir.constant(4 : i32) : i32
  %3 = llvm.mlir.constant(true) : i1
  %4 = llvm.load %1 : !llvm.ptr -> i32
// CHECK:   %[[GID_01:.*]] = call i32 @__kmpc_global_thread_num(ptr {{.*}})
// CHECK:   %[[I_01:.*]] = call ptr @__kmpc_omp_task_alloc(ptr {{.*}}, i32 %[[GID_01]], i32 33, i64 40, i64 0, ptr @{{.*}})
// CHECK:   %[[I_02:.*]] = getelementptr inbounds { ptr }, ptr %[[I_01]], i32 0, i32 0
// CHECK:   %[[I_03:.*]] = getelementptr inbounds { ptr, ptr, i32, ptr, ptr }, ptr %[[I_02]], i32 0, i32 4
// CHECK:   %[[I_04:.*]] = getelementptr inbounds { ptr, ptr }, ptr %[[I_03]], i32 0, i32 0
// CHECK:   store i32 {{.*}}, ptr %[[I_04]], align 4
// CHECK:   %{{.*}} = call i32 @__kmpc_omp_task(ptr {{.*}}, i32 %[[GID_01]], ptr %[[I_01]])
  omp.task priority(%4 : i32) {
    llvm.call @test_01() : () -> ()
    omp.terminator
  }
// CHECK:   %[[GID_02:.*]] = call i32 @__kmpc_global_thread_num(ptr {{.*}})
// CHECK:   %[[I_05:.*]] = call ptr @__kmpc_omp_task_alloc(ptr {{.*}}, i32 %[[GID_02]], i32 35, i64 40, i64 0, ptr @{{.*}})
// CHECK:   %[[I_06:.*]] = getelementptr inbounds { ptr }, ptr %[[I_05]], i32 0, i32 0
// CHECK:   %[[I_07:.*]] = getelementptr inbounds { ptr, ptr, i32, ptr, ptr }, ptr %[[I_06]], i32 0, i32 4
// CHECK:   %[[I_08:.*]] = getelementptr inbounds { ptr, ptr }, ptr %[[I_07]], i32 0, i32 0
// CHECK:   store i32 4, ptr %[[I_08]], align 4
// CHECK:   %{{.*}} = call i32 @__kmpc_omp_task(ptr {{.*}}, i32 %[[GID_02]], ptr %[[I_05]])
  omp.task final(%3) priority(%2 : i32) {
    llvm.call @test_02() : () -> ()
    omp.terminator
  }
  llvm.return
// CHECK:   ret void
// CHECK: }
}

// -----

// CHECK-LABEL: @omp_opaque_pointers
// CHECK-SAME: (ptr %[[ARG0:.*]], ptr %[[ARG1:.*]], i32 %[[EXPR:.*]])
llvm.func @omp_opaque_pointers(%arg0 : !llvm.ptr, %arg1: !llvm.ptr, %expr: i32) -> () {
  // CHECK: %[[X1:.*]] = load atomic i32, ptr %[[ARG0]] monotonic, align 4
  // CHECK: store i32 %[[X1]], ptr %[[ARG1]], align 4
  omp.atomic.read %arg1 = %arg0 : !llvm.ptr, !llvm.ptr, i32

  // CHECK: %[[RES:.*]] = atomicrmw add ptr %[[ARG1]], i32 %[[EXPR]] acq_rel
  // CHECK: store i32 %[[RES]], ptr %[[ARG0]]
  omp.atomic.capture memory_order(acq_rel) {
    omp.atomic.read %arg0 = %arg1 : !llvm.ptr, !llvm.ptr, i32
    omp.atomic.update %arg1 : !llvm.ptr {
    ^bb0(%xval: i32):
      %newval = llvm.add %xval, %expr : i32
      omp.yield(%newval : i32)
    }
  }
  llvm.return
}

// -----

// CHECK: @__omp_rtl_debug_kind = weak_odr hidden constant i32 1
// CHECK: @__omp_rtl_assume_teams_oversubscription = weak_odr hidden constant i32 1
// CHECK: @__omp_rtl_assume_threads_oversubscription = weak_odr hidden constant i32 1
// CHECK: @__omp_rtl_assume_no_thread_state = weak_odr hidden constant i32 1
// CHECK: @__omp_rtl_assume_no_nested_parallelism = weak_odr hidden constant i32 1
module attributes {omp.flags = #omp.flags<debug_kind = 1, assume_teams_oversubscription = true, 
                                          assume_threads_oversubscription = true, assume_no_thread_state = true, 
                                          assume_no_nested_parallelism = true>} {}
// -----

// CHECK: @__omp_rtl_debug_kind = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_teams_oversubscription = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_threads_oversubscription = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_no_thread_state = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_no_nested_parallelism = weak_odr hidden constant i32 0
// CHECK: [[META0:![0-9]+]] = !{i32 7, !"openmp-device", i32 50}
module attributes {omp.flags = #omp.flags<>} {}

// -----

// CHECK: @__omp_rtl_debug_kind = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_teams_oversubscription = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_threads_oversubscription = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_no_thread_state = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_no_nested_parallelism = weak_odr hidden constant i32 0
// CHECK: [[META0:![0-9]+]] = !{i32 7, !"openmp-device", i32 51}
module attributes {omp.flags = #omp.flags<openmp_device_version = 51>} {}

// -----

// CHECK: @__omp_rtl_debug_kind = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_teams_oversubscription = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_threads_oversubscription = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_no_thread_state = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_no_nested_parallelism = weak_odr hidden constant i32 0
// CHECK: [[META0:![0-9]+]] = !{i32 7, !"openmp-device", i32 50}
// CHECK: [[META0:![0-9]+]] = !{i32 7, !"openmp", i32 50}
module attributes {omp.version = #omp.version<version = 50>, omp.flags = #omp.flags<>} {}

// -----

// CHECK: [[META0:![0-9]+]] = !{i32 7, !"openmp", i32 51}
// CHECK-NOT: [[META0:![0-9]+]] = !{i32 7, !"openmp-device", i32 50}
module attributes {omp.version = #omp.version<version = 51>} {}

// -----
// CHECK: @__omp_rtl_debug_kind = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_teams_oversubscription = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_threads_oversubscription = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_no_thread_state = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_no_nested_parallelism = weak_odr hidden constant i32 0
module attributes {omp.flags = #omp.flags<debug_kind = 0, assume_teams_oversubscription = false, 
                                          assume_threads_oversubscription = false, assume_no_thread_state = false, 
                                          assume_no_nested_parallelism = false>} {}

// -----

// CHECK: @__omp_rtl_debug_kind = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_teams_oversubscription = weak_odr hidden constant i32 1
// CHECK: @__omp_rtl_assume_threads_oversubscription = weak_odr hidden constant i32 0
// CHECK: @__omp_rtl_assume_no_thread_state = weak_odr hidden constant i32 1
// CHECK: @__omp_rtl_assume_no_nested_parallelism = weak_odr hidden constant i32 0
module attributes {omp.flags = #omp.flags<assume_teams_oversubscription = true, assume_no_thread_state = true>} {}

// -----

// CHECK-NOT: @__omp_rtl_debug_kind = weak_odr hidden constant i32 0
// CHECK-NOT: @__omp_rtl_assume_teams_oversubscription = weak_odr hidden constant i32 1
// CHECK-NOT: @__omp_rtl_assume_threads_oversubscription = weak_odr hidden constant i32 0
// CHECK-NOT: @__omp_rtl_assume_no_thread_state = weak_odr hidden constant i32 1
// CHECK-NOT: @__omp_rtl_assume_no_nested_parallelism = weak_odr hidden constant i32 0
module attributes {omp.flags = #omp.flags<assume_teams_oversubscription = true, assume_no_thread_state = true,
                                          no_gpu_lib=true>} {}

// -----

module attributes {omp.is_target_device = false} {
  // CHECK: define void @filter_nohost
  llvm.func @filter_nohost() -> ()
      attributes {
        omp.declare_target =
          #omp.declaretarget<device_type = (nohost), capture_clause = (to)>
      } {
    llvm.return
  }

  // CHECK: define void @filter_host
  llvm.func @filter_host() -> ()
      attributes {
        omp.declare_target =
          #omp.declaretarget<device_type = (host), capture_clause = (to)>
      } {
    llvm.return
  }
}

// -----

module attributes {omp.is_target_device = false} {
  // CHECK: define void @filter_nohost
  llvm.func @filter_nohost() -> ()
      attributes {
        omp.declare_target =
          #omp.declaretarget<device_type = (nohost), capture_clause = (enter)>
      } {
    llvm.return
  }

  // CHECK: define void @filter_host
  llvm.func @filter_host() -> ()
      attributes {
        omp.declare_target =
          #omp.declaretarget<device_type = (host), capture_clause = (enter)>
      } {
    llvm.return
  }
}

// -----

module attributes {omp.is_target_device = true} {
  // CHECK: define void @filter_nohost
  llvm.func @filter_nohost() -> ()
      attributes {
        omp.declare_target =
          #omp.declaretarget<device_type = (nohost), capture_clause = (to)>
      } {
    llvm.return
  }

  // CHECK-NOT: define void @filter_host
  llvm.func @filter_host() -> ()
      attributes {
        omp.declare_target =
          #omp.declaretarget<device_type = (host), capture_clause = (to)>
      } {
    llvm.return
  }
}

// -----

module attributes {omp.is_target_device = true} {
  // CHECK: define void @filter_nohost
  llvm.func @filter_nohost() -> ()
      attributes {
        omp.declare_target =
          #omp.declaretarget<device_type = (nohost), capture_clause = (enter)>
      } {
    llvm.return
  }

  // CHECK-NOT: define void @filter_host
  llvm.func @filter_host() -> ()
      attributes {
        omp.declare_target =
          #omp.declaretarget<device_type = (host), capture_clause = (enter)>
      } {
    llvm.return
  }
}

// -----

llvm.func @omp_task_untied() {
  // The third argument is 0: which signifies the untied task
  // CHECK: {{.*}} = call ptr @__kmpc_omp_task_alloc(ptr @1, i32 %{{.*}}, i32 0,
  // CHECK-SAME:     i64 40, i64 0, ptr @{{.*}})
  omp.task untied {
        omp.terminator
  }
  llvm.return
}

// -----

// Third argument is 5: essentially (4 || 1)
// signifying this task is TIED and MERGEABLE

// CHECK: {{.*}} = call ptr @__kmpc_omp_task_alloc(ptr @1, i32 %omp_global_thread_num, i32 5, i64 40, i64 0, ptr @omp_task_mergeable..omp_par)
llvm.func @omp_task_mergeable() {
  omp.task mergeable {
    omp.terminator
  }
  llvm.return
}

// -----

llvm.func external @foo_before() -> ()
llvm.func external @foo() -> ()
llvm.func external @foo_after() -> ()

llvm.func @omp_task_final(%boolexpr: i1) {
  llvm.call @foo_before() : () -> ()
  omp.task final(%boolexpr) {
    llvm.call @foo() : () -> ()
    omp.terminator
  }
  llvm.call @foo_after() : () -> ()
  llvm.return
}

// CHECK-LABEL: define void @omp_task_final(
// CHECK-SAME:    i1 %[[boolexpr:.+]]) {
// CHECK:         call void @foo_before()
// CHECK:         br label %[[entry:[^,]+]]
// CHECK:       [[entry]]:
// CHECK:         br label %[[codeRepl:[^,]+]]
// CHECK:       [[codeRepl]]:                                         ; preds = %entry
// CHECK:         %[[omp_global_thread_num:.+]] = call i32 @__kmpc_global_thread_num(ptr @{{.+}})
// CHECK:         %[[final_flag:.+]] = select i1 %[[boolexpr]], i32 2, i32 0
// CHECK:         %[[task_flags:.+]] = or i32 %[[final_flag]], 1
// CHECK:         %[[task_data:.+]] = call ptr @__kmpc_omp_task_alloc(ptr @{{.+}}, i32 %[[omp_global_thread_num]], i32 %[[task_flags]], i64 40, i64 0, ptr @[[task_outlined_fn:.+]])
// CHECK:         %{{.+}} = call i32 @__kmpc_omp_task(ptr @{{.+}}, i32 %[[omp_global_thread_num]], ptr %[[task_data]])
// CHECK:         br label %[[task_exit:[^,]+]]
// CHECK:       [[task_exit]]:
// CHECK:         call void @foo_after()
// CHECK:         ret void

// -----

llvm.func external @foo_before() -> ()
llvm.func external @foo() -> ()
llvm.func external @foo_after() -> ()

llvm.func @omp_task_if(%boolexpr: i1) {
  llvm.call @foo_before() : () -> ()
  omp.task if(%boolexpr) {
    llvm.call @foo() : () -> ()
    omp.terminator
  }
  llvm.call @foo_after() : () -> ()
  llvm.return
}

// CHECK-LABEL: define void @omp_task_if(
// CHECK-SAME:    i1 %[[boolexpr:.+]]) {
// CHECK:         call void @foo_before()
// CHECK:         br label %[[entry:[^,]+]]
// CHECK:       [[entry]]:
// CHECK:         br label %[[codeRepl:[^,]+]]
// CHECK:       [[codeRepl]]:
// CHECK:         %[[omp_global_thread_num:.+]] = call i32 @__kmpc_global_thread_num(ptr @{{.+}})
// CHECK:         %[[task_data:.+]] = call ptr @__kmpc_omp_task_alloc(ptr @{{.+}}, i32 %[[omp_global_thread_num]], i32 1, i64 40, i64 0, ptr @[[task_outlined_fn:.+]])
// CHECK:         br i1 %[[boolexpr]], label %[[true_label:[^,]+]], label %[[false_label:[^,]+]]
// CHECK:       [[true_label]]:
// CHECK:         %{{.+}} = call i32 @__kmpc_omp_task(ptr @{{.+}}, i32 %[[omp_global_thread_num]], ptr %[[task_data]])
// CHECK:         br label %[[if_else_exit:[^,]+]]
// CHECK:       [[false_label:[^,]+]]:                                                ; preds = %codeRepl
// CHECK:         call void @__kmpc_omp_task_begin_if0(ptr @{{.+}}, i32 %[[omp_global_thread_num]], ptr %[[task_data]])
// CHECK:         call void @[[task_outlined_fn]](i32 %[[omp_global_thread_num]])
// CHECK:         call void @__kmpc_omp_task_complete_if0(ptr @{{.+}}, i32 %[[omp_global_thread_num]], ptr %[[task_data]])
// CHECK:         br label %[[if_else_exit]]
// CHECK:       [[if_else_exit]]:
// CHECK:         br label %[[task_exit:[^,]+]]
// CHECK:       [[task_exit]]:
// CHECK:         call void @foo_after()
// CHECK:         ret void

// -----

module attributes {omp.requires = #omp<clause_requires reverse_offload|unified_shared_memory>} {}

// -----

llvm.func @distribute() {
  %0 = llvm.mlir.constant(42 : index) : i64
  %1 = llvm.mlir.constant(10 : index) : i64
  %2 = llvm.mlir.constant(1 : index) : i64
  omp.distribute {
    omp.loop_nest (%arg1) : i64 = (%1) to (%0) step (%2) {
      omp.yield
    }
  }
  llvm.return
}

// CHECK-LABEL: define void @distribute
// CHECK:         call void @[[OUTLINED:.*]]({{.*}})
// CHECK-NEXT:    br label %[[EXIT:.*]]
// CHECK:       [[EXIT]]:
// CHECK:         ret void

// CHECK:       define internal void @[[OUTLINED]]({{.*}})
// CHECK:         %[[LASTITER:.*]] = alloca i32
// CHECK:         %[[LB:.*]] = alloca i64
// CHECK:         %[[UB:.*]] = alloca i64
// CHECK:         %[[STRIDE:.*]] = alloca i64
// CHECK:         br label %[[BODY:.*]]
// CHECK:       [[BODY]]:
// CHECK-NEXT:    br label %[[REGION:.*]]
// CHECK:       [[REGION]]:
// CHECK-NEXT:    br label %[[PREHEADER:.*]]
// CHECK:       [[PREHEADER]]:
// CHECK:         store i64 0, ptr %[[LB]]
// CHECK:         store i64 31, ptr %[[UB]]
// CHECK:         store i64 1, ptr %[[STRIDE]]
// CHECK:         %[[TID:.*]] = call i32 @__kmpc_global_thread_num({{.*}})
// CHECK:         call void @__kmpc_for_static_init_{{.*}}(ptr @{{.*}}, i32 %[[TID]], i32 92, ptr %[[LASTITER]], ptr %[[LB]], ptr %[[UB]], ptr %[[STRIDE]], i64 1, i64 0)

// -----

llvm.func @distribute_wsloop(%lb : i32, %ub : i32, %step : i32) {
  omp.parallel {
    omp.distribute {
      omp.wsloop {
        omp.loop_nest (%iv) : i32 = (%lb) to (%ub) step (%step) {
          omp.yield
        }
      } {omp.composite}
    } {omp.composite}
    omp.terminator
  } {omp.composite}
  llvm.return
}

// CHECK-LABEL: define void @distribute_wsloop
// CHECK:         call void{{.*}}@__kmpc_fork_call({{.*}}, ptr @[[OUTLINED_PARALLEL:.*]],

// CHECK:       define internal void @[[OUTLINED_PARALLEL]]
// CHECK:         call void @[[OUTLINED_DISTRIBUTE:.*]]({{.*}})

// CHECK:       define internal void @[[OUTLINED_DISTRIBUTE]]
// CHECK:         %[[LASTITER:.*]] = alloca i32
// CHECK:         %[[LB:.*]] = alloca i32
// CHECK:         %[[UB:.*]] = alloca i32
// CHECK:         %[[STRIDE:.*]] = alloca i32
// CHECK:         br label %[[AFTER_ALLOCA:.*]]

// CHECK:       [[AFTER_ALLOCA]]:
// CHECK:         br label %[[DISTRIBUTE_BODY:.*]]

// CHECK:       [[DISTRIBUTE_BODY]]:
// CHECK-NEXT:    br label %[[DISTRIBUTE_REGION:.*]]

// CHECK:       [[DISTRIBUTE_REGION]]:
// CHECK-NEXT:    br label %[[WSLOOP_REGION:.*]]

// CHECK:       [[WSLOOP_REGION]]:
// CHECK:         %omp_loop.tripcount = select {{.*}}
// CHECK-NEXT:    br label %[[PREHEADER:.*]]

// CHECK:       [[PREHEADER]]:
// CHECK:         store i32 0, ptr %[[LB]]
// CHECK:         %[[TRIPCOUNT:.*]] = sub i32 %omp_loop.tripcount, 1
// CHECK:         store i32 %[[TRIPCOUNT]], ptr %[[UB]]
// CHECK:         store i32 1, ptr %[[STRIDE]]
// CHECK:         %[[TID:.*]] = call i32 @__kmpc_global_thread_num({{.*}})
// CHECK:         %[[DIST_UB:.*]] = alloca i32
// CHECK:         call void @__kmpc_dist_for_static_init_{{.*}}(ptr @{{.*}}, i32 %[[TID]], i32 34, ptr %[[LASTITER]], ptr %[[LB]], ptr %[[UB]], ptr %[[DIST_UB]], ptr %[[STRIDE]], i32 1, i32 0)

// -----

omp.private {type = private} @_QFEx_private_i32 : i32
llvm.func @nested_task_with_deps() {
  %0 = llvm.mlir.constant(1 : i64) : i64
  %1 = llvm.alloca %0 x i32 {bindc_name = "x"} : (i64) -> !llvm.ptr
  %2 = llvm.mlir.constant(1 : i64) : i64
  omp.parallel private(@_QFEx_private_i32 %1 -> %arg0 : !llvm.ptr) {
    omp.task depend(taskdependout -> %arg0 : !llvm.ptr) {
      omp.terminator
    }
    omp.terminator
  }
  llvm.return
}

// CHECK-LABEL: define void @nested_task_with_deps() {
// CHECK:         %[[PAR_FORK_ARG:.*]] = alloca { ptr }, align 8
// CHECK:         %[[DEP_ARR:.*]] = alloca [1 x %struct.kmp_dep_info], align 8

// CHECK:       omp_parallel:
// CHECK-NEXT:    %[[DEP_ARR_GEP:.*]] = getelementptr { ptr }, ptr %[[PAR_FORK_ARG]], i32 0, i32 0
// CHECK-NEXT:    store ptr %[[DEP_ARR]], ptr %[[DEP_ARR_GEP]], align 8
// CHECK-NEXT:    call void {{.*}} @__kmpc_fork_call(ptr @{{.*}}, i32 1, ptr @[[PAR_OUTLINED:.*]], ptr %[[PAR_FORK_ARG]])
// CHECK-NEXT:    br label %[[PAR_EXIT:.*]]

// CHECK:       [[PAR_EXIT]]:
// CHECK-NEXT:    ret void
// CHECK:       }

// CHECK:       define internal void @[[PAR_OUTLINED]]{{.*}} {
// CHECK:       omp.par.entry:
// CHECK:         %[[DEP_ARR_GEP_2:.*]] = getelementptr { ptr }, ptr %{{.*}}, i32 0, i32 0
// CHECK:         %[[DEP_ARR_2:.*]] = load ptr, ptr %[[DEP_ARR_GEP_2]], align 8
// CHECK:         %[[PRIV_ALLOC:omp.private.alloc]] = alloca i32, align 4

// CHECK:         %[[TASK:.*]] = call ptr @__kmpc_omp_task_alloc
// CHECK:         %[[DEP_STRUCT_GEP:.*]] = getelementptr inbounds [1 x %struct.kmp_dep_info], ptr %[[DEP_ARR_2]], i64 0, i64 0
// CHECK:         %[[DEP_GEP:.*]] = getelementptr inbounds nuw %struct.kmp_dep_info, ptr %[[DEP_STRUCT_GEP]], i32 0, i32 0
// CHECK:         %[[PRIV_ALLOC_TO_INT:.*]] = ptrtoint ptr %[[PRIV_ALLOC]] to i64
// CHECK:         store i64 %[[PRIV_ALLOC_TO_INT]], ptr %[[DEP_GEP]], align 4
// CHECK:         call i32 @__kmpc_omp_task_with_deps(ptr @{{.*}}, i32 %{{.*}}, ptr %{{.*}}, i32 1, ptr %[[DEP_ARR_2]], i32 0, ptr null)

// CHECK:         ret void
// CHECK:       }

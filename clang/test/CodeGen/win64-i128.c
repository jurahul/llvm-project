// RUN: %clang_cc1 -triple x86_64-windows-gnu -emit-llvm -o - %s \
// RUN:    | FileCheck %s --check-prefix=GNU64
// RUN: %clang_cc1 -triple x86_64-windows-msvc -emit-llvm -o - %s \
// RUN:    | FileCheck %s --check-prefix=MSC64

typedef int int128_t __attribute__((mode(TI)));

int128_t foo(void) { return 0; }

// GNU64: define dso_local <2 x i64> @foo()
// MSC64: define dso_local <2 x i64> @foo()

int128_t bar(int128_t a, int128_t b) { return a * b; }

// GNU64: define dso_local <2 x i64> @bar(ptr dead_on_return noundef %0, ptr dead_on_return noundef %1)
// MSC64: define dso_local <2 x i64> @bar(ptr dead_on_return noundef %0, ptr dead_on_return noundef %1)

void vararg(int a, ...) {
  // GNU64-LABEL: define{{.*}} void @vararg
  // MSC64-LABEL: define{{.*}} void @vararg
  __builtin_va_list ap;
  __builtin_va_start(ap, a);
  int128_t i = __builtin_va_arg(ap, int128_t);
  // GNU64: load ptr, ptr
  // GNU64: load i128, ptr
  // MSC64: load ptr, ptr
  // MSC64: load i128, ptr
  __builtin_va_end(ap);
}

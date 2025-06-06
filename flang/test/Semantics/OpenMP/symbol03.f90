! RUN: %python %S/../test_symbols.py %s %flang_fc1 -fopenmp

! 1.4.1 Structure of the OpenMP Memory Model
! In the inner OpenMP region, SHARED `a` refers to the `a` in the outer OpenMP
! region; PRIVATE `b` refers to the new `b` in the same OpenMP region

  !DEF: /MainProgram1/b (Implicit) ObjectEntity REAL(4)
  b = 2
  !$omp parallel  private(a) shared(b)
  !DEF: /MainProgram1/OtherConstruct1/a (OmpPrivate, OmpExplicit) HostAssoc REAL(4)
  a = 3.
  !DEF: /MainProgram1/OtherConstruct1/b (OmpShared, OmpExplicit) HostAssoc REAL(4)
  b = 4
  !$omp parallel  private(b) shared(a)
  !DEF: /MainProgram1/OtherConstruct1/OtherConstruct1/a (OmpShared, OmpExplicit) HostAssoc REAL(4)
  a = 5.
  !DEF: /MainProgram1/OtherConstruct1/OtherConstruct1/b (OmpPrivate, OmpExplicit) HostAssoc REAL(4)
  b = 6
  !$omp end parallel
  !$omp end parallel
  !DEF: /MainProgram1/a (Implicit) ObjectEntity REAL(4)
  !REF: /MainProgram1/b
  print *, a, b
end program

MODULE evaluator_blocks

  USE custom_parser
  USE stack

  IMPLICIT NONE

  ! Subroutine behaviour modifier
  INTEGER, PARAMETER :: c_eval_all = 0
  INTEGER, PARAMETER :: c_eval_no_time = 1
  INTEGER, PARAMETER :: c_eval_no_x = 2
  INTEGER, PARAMETER :: c_eval_no_y = 4
  INTEGER, PARAMETER :: c_eval_no_z = 8
  INTEGER, PARAMETER :: c_eval_no_space = &
      c_eval_no_x + c_eval_no_y + c_eval_no_z
  INTEGER, PARAMETER :: c_eval_none = c_eval_no_time + c_eval_no_space

CONTAINS

  SUBROUTINE do_species(opcode, err)

    INTEGER, INTENT(IN) :: opcode
    INTEGER, INTENT(INOUT) :: err

    err = c_err_none
    CALL push_on_eval(REAL(opcode, num))

  END SUBROUTINE do_species



  SUBROUTINE do_operator(opcode, err)

    INTEGER, INTENT(IN) :: opcode
    INTEGER, INTENT(INOUT) :: err
    REAL(num), DIMENSION(2) :: values
    REAL(num) :: val
    LOGICAL :: comp

    err = c_err_none

    IF (opcode .EQ. c_opcode_plus) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1)+values(2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_minus) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1)-values(2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_unary_plus) THEN
      CALL get_values(1, values)
      CALL push_on_eval(values(1))
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_unary_minus) THEN
      CALL get_values(1, values)
      CALL push_on_eval(-values(1))
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_times) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1)*values(2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_divide) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1)/values(2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_power) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1)**values(2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_expo) THEN
      CALL get_values(2, values)
      CALL push_on_eval(values(1) * 10.0_num ** values(2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_lt) THEN
      CALL get_values(2, values)
      comp = values(1) .LT. values(2)
      val = 0.0_num
      IF (comp) val = 1.0_num
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_gt) THEN
      CALL get_values(2, values)
      comp = values(1) .GT. values(2)
      val = 0.0_num
      IF (comp) val = 1.0_num
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_eq) THEN
      CALL get_values(2, values)
      comp = (ABS(values(1) - values(2)) .LE. c_tiny)
      val = 0.0_num
      IF (comp) val = 1.0_num
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_or) THEN
      CALL get_values(2, values)
      comp = (FLOOR(values(1)) .NE. 0 .OR. FLOOR(values(2)) .NE. 0)
      val = 0.0_num
      IF (comp)val = 1.0_num
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode .EQ. c_opcode_and) THEN
      CALL get_values(2, values)
      comp = (FLOOR(values(1)) .NE. 0 .AND. FLOOR(values(2)) .NE. 0)
      val = 0.0_num
      IF (comp)val = 1.0_num
      CALL push_on_eval(val)
      RETURN
    ENDIF

    err = c_err_unknown_element

  END SUBROUTINE do_operator



  SUBROUTINE do_constant(opcode, modify, ix, err)

    INTEGER, INTENT(IN) :: opcode, modify, ix
    INTEGER, INTENT(INOUT) :: err
    REAL(num) :: val

    err = c_err_none

    IF (IAND(modify, c_eval_no_time) .NE. 0) THEN
      IF (opcode .EQ. c_const_time &
          .OR. opcode .GE. c_const_custom_lowbound) THEN
        err = -c_eval_no_time
        RETURN
      ENDIF
    ENDIF

    IF (IAND(modify, c_eval_no_x) .NE. 0) THEN
      IF (opcode .EQ. c_const_x &
          .OR. opcode .EQ. c_const_ix &
          .OR. opcode .EQ. c_const_r_xy &
          .OR. opcode .EQ. c_const_r_xz &
          .OR. opcode .GE. c_const_custom_lowbound) THEN
        err = -c_eval_no_x
        RETURN
      ENDIF
    ENDIF

    IF (opcode .EQ. c_const_time) THEN
      CALL push_on_eval(time)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_x) THEN
      CALL push_on_eval(x(ix))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_ix) THEN
      CALL push_on_eval(REAL(ix, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_y) THEN
      CALL push_on_eval(0.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_iy) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_z) THEN
      CALL push_on_eval(0.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_iz) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_r_xy) THEN
      CALL push_on_eval(ABS(x(ix)**2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_r_xz) THEN
      CALL push_on_eval(ABS(x(ix)**2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_r_yz) THEN
      CALL push_on_eval(0.0_num)
      RETURN
    ENDIF

    IF (opcode .GE. c_const_custom_lowbound) THEN
      ! Check for custom constants
      val = custom_constant(opcode, ix, err)
      IF (IAND(err, c_err_unknown_element) .EQ. 0) CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_pi) THEN
      CALL push_on_eval(pi)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_kb) THEN
      CALL push_on_eval(kb)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_qe) THEN
      CALL push_on_eval(q0)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_c) THEN
      CALL push_on_eval(c)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_me) THEN
      CALL push_on_eval(m0)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_eps0) THEN
      CALL push_on_eval(epsilon0)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_mu0) THEN
      CALL push_on_eval(mu0)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_ev) THEN
      CALL push_on_eval(ev)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_kev) THEN
      CALL push_on_eval(ev*1000.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_mev) THEN
      CALL push_on_eval(ev*1.0e6_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_milli) THEN
      CALL push_on_eval(1.0e-3_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_micro) THEN
      CALL push_on_eval(1.0e-6_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_nano) THEN
      CALL push_on_eval(1.0e-9_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_pico) THEN
      CALL push_on_eval(1.0e-12_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_femto) THEN
      CALL push_on_eval(1.0e-15_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_atto) THEN
      CALL push_on_eval(1.0e-18_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_io_never) THEN
      CALL push_on_eval(REAL(c_io_never, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_io_always) THEN
      CALL push_on_eval(REAL(c_io_always, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_io_full) THEN
      CALL push_on_eval(REAL(c_io_full, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_io_restartable) THEN
      CALL push_on_eval(REAL(c_io_restartable, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_io_species) THEN
      CALL push_on_eval(REAL(c_io_species, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_io_no_sum) THEN
      CALL push_on_eval(REAL(c_io_no_sum, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_io_average) THEN
      CALL push_on_eval(REAL(c_io_averaged, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_io_snapshot) THEN
      CALL push_on_eval(REAL(c_io_snapshot, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_io_dump_single) THEN
      CALL push_on_eval(REAL(c_io_dump_single, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_io_average_single) THEN
      CALL push_on_eval(REAL(c_io_averaged+c_io_average_single, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dir_x) THEN
      CALL push_on_eval(REAL(c_dir_x, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dir_y) THEN
      CALL push_on_eval(REAL(c_dir_y, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dir_px) THEN
      CALL push_on_eval(REAL(c_dir_px, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dir_py) THEN
      CALL push_on_eval(REAL(c_dir_py, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dir_pz) THEN
      CALL push_on_eval(REAL(c_dir_pz, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dir_en) THEN
      CALL push_on_eval(REAL(c_dir_en, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dir_gamma_m1) THEN
      CALL push_on_eval(REAL(c_dir_gamma_m1,num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dir_xy_angle) THEN
      CALL push_on_eval(REAL(c_dir_xy_angle,num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dir_yz_angle) THEN
      CALL push_on_eval(REAL(c_dir_yz_angle,num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dir_zx_angle) THEN
      CALL push_on_eval(REAL(c_dir_zx_angle,num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_nsteps) THEN
      CALL push_on_eval(REAL(nsteps, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_t_end) THEN
      CALL push_on_eval(t_end)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_lx) THEN
      CALL push_on_eval(length_x)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dx) THEN
      CALL push_on_eval(dx)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_x_min) THEN
      CALL push_on_eval(x_min)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_x_max) THEN
      CALL push_on_eval(x_max)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_nx) THEN
      CALL push_on_eval(REAL(nx_global, num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_nprocx) THEN
      CALL push_on_eval(REAL(nprocx, num))
      RETURN
    ENDIF

    ! Ignorable directions

    IF (opcode .EQ. c_const_ly) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dy) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_y_min) THEN
      CALL push_on_eval(-0.5_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_y_max) THEN
      CALL push_on_eval(0.5_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_ny) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_nprocy) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_lz) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_dz) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_z_min) THEN
      CALL push_on_eval(-0.5_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_z_max) THEN
      CALL push_on_eval(0.5_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_nz) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    IF (opcode .EQ. c_const_nprocz) THEN
      CALL push_on_eval(1.0_num)
      RETURN
    ENDIF

    err = c_err_unknown_element

  END SUBROUTINE do_constant



  SUBROUTINE do_functions(opcode, modify, ix, err)

    INTEGER, INTENT(IN) :: opcode, modify, ix
    INTEGER, INTENT(INOUT) :: err
    REAL(num), DIMENSION(4) :: values
    REAL(num) :: val
    INTEGER :: count, ipoint, n
    LOGICAL :: done
    REAL(num), DIMENSION(:), ALLOCATABLE :: var_length_values
    REAL(num) :: point, t0

    err = c_err_none

    IF (IAND(modify, c_eval_no_space) .NE. 0) THEN
      IF (opcode .EQ. c_func_rho &
          .OR. opcode .EQ. c_func_tempx &
          .OR. opcode .EQ. c_func_tempy &
          .OR. opcode .EQ. c_func_tempz &
          .OR. opcode .EQ. c_func_tempx_ev &
          .OR. opcode .EQ. c_func_tempy_ev &
          .OR. opcode .EQ. c_func_tempz_ev &
          .OR. opcode .GE. c_func_custom_lowbound) THEN
        err = -c_eval_no_space
        RETURN
      ENDIF
    ENDIF

    IF (opcode .EQ. c_func_rho) THEN
      CALL get_values(1, values)
      CALL push_on_eval(initial_conditions(NINT(values(1)))%density(ix))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_tempx) THEN
      CALL get_values(1, values)
      CALL push_on_eval(initial_conditions(NINT(values(1)))%temp(ix, 1))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_tempy) THEN
      CALL get_values(1, values)
      CALL push_on_eval(initial_conditions(NINT(values(1)))%temp(ix, 2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_tempz) THEN
      CALL get_values(1, values)
      CALL push_on_eval(initial_conditions(NINT(values(1)))%temp(ix, 3))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_tempx_ev) THEN
      CALL get_values(1, values)
      CALL push_on_eval(kb / ev &
          * initial_conditions(NINT(values(1)))%temp(ix, 1))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_tempy_ev) THEN
      CALL get_values(1, values)
      CALL push_on_eval(kb / ev &
          * initial_conditions(NINT(values(1)))%temp(ix, 2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_tempz_ev) THEN
      CALL get_values(1, values)
      CALL push_on_eval(kb / ev &
          * initial_conditions(NINT(values(1)))%temp(ix, 3))
      RETURN
    ENDIF

    IF (opcode .GE. c_func_custom_lowbound) THEN
      ! Check for custom functions
      val = custom_function(opcode, ix, err)
      IF (IAND(err, c_err_unknown_element) .EQ. 0) CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_floor) THEN
      CALL get_values(1, values)
      CALL push_on_eval(REAL(FLOOR(values(1)),num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_ceil) THEN
      CALL get_values(1, values)
      CALL push_on_eval(REAL(CEILING(values(1)),num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_nint) THEN
      CALL get_values(1, values)
      CALL push_on_eval(REAL(NINT(values(1)),num))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_sqrt) THEN
      CALL get_values(1, values)
      CALL push_on_eval(SQRT(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_sine) THEN
      CALL get_values(1, values)
      CALL push_on_eval(SIN(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_cosine) THEN
      CALL get_values(1, values)
      CALL push_on_eval(COS(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_tan) THEN
      CALL get_values(1, values)
      CALL push_on_eval(TAN(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_exp) THEN
      CALL get_values(1, values)
      CALL push_on_eval(EXP(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_arcsine) THEN
      CALL get_values(1, values)
      CALL push_on_eval(ASIN(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_arccosine) THEN
      CALL get_values(1, values)
      CALL push_on_eval(ACOS(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_arctan) THEN
      CALL get_values(1, values)
      CALL push_on_eval(ATAN(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_neg) THEN
      CALL get_values(1, values)
      CALL push_on_eval(-(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_if) THEN
      CALL get_values(3, values)
      IF (FLOOR(values(1)) .NE. 0) THEN
        val = values(2)
      ELSE
        val = values(3)
      ENDIF
      CALL push_on_eval(val)
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_interpolate) THEN
      CALL get_values(1, values)
      count = NINT(values(1))
      ALLOCATE(var_length_values(0:count*2))
      CALL get_values(count*2+1, var_length_values)
      ! This could be replaced by a bisection algorithm, change at some point
      ! For now, not too bad for small count

      ! var_length_values(0) = position in domain
      done = .FALSE.
      point = var_length_values(0)

      DO ipoint = 1, count-1
        IF (point .GE. var_length_values(ipoint*2-1) &
            .AND. point .LE. var_length_values(ipoint*2+1)) THEN
          val = (point-var_length_values(ipoint*2-1)) &
              / (var_length_values(ipoint*2+1)-var_length_values(ipoint*2-1)) &
              * (var_length_values(ipoint*2+2) - var_length_values(ipoint*2)) &
              + var_length_values(ipoint*2)
          done = .TRUE.
          CALL push_on_eval(val)
          EXIT
        ENDIF
      ENDDO
      DEALLOCATE(var_length_values)
      IF (.NOT. done) err = c_err_bad_value
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_tanh) THEN
      CALL get_values(1, values)
      CALL push_on_eval(TANH(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_sinh) THEN
      CALL get_values(1, values)
      CALL push_on_eval(SINH(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_cosh) THEN
      CALL get_values(1, values)
      CALL push_on_eval(COSH(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_ex) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(ex(NINT(values(1))))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_ey) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(ey(NINT(values(1))))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_ez) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(ez(NINT(values(1))))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_bx) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(bx(NINT(values(1))))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_by) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(by(NINT(values(1))))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_bz) THEN
      CALL get_values(c_ndims, values)
      CALL push_on_eval(bz(NINT(values(1))))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_gauss) THEN
      CALL get_values(3, values)
      CALL push_on_eval(EXP(-((values(1)-values(2))/values(3))**2))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_semigauss) THEN
      CALL get_values(4, values)
      ! values are : time, maximum amplitude, amplitude at t = 0,
      ! characteristic time width
      t0 = values(4) * SQRT(-LOG(values(3)/values(2)))
      IF (values(1) .LE. t0) THEN
        CALL push_on_eval(values(2) * EXP(-((values(1)-t0)/values(4))**2))
      ELSE
        CALL push_on_eval(values(2))
      ENDIF
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_supergauss) THEN
      CALL get_values(4, values)
      n = INT(values(4))
      CALL push_on_eval(EXP(-ABS(((values(1)-values(2))/values(3)))**n))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_crit) THEN
      CALL get_values(1, values)
      CALL push_on_eval(values(1)**2 * m0 * epsilon0 / q0**2)
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_abs) THEN
      CALL get_values(1, values)
      CALL push_on_eval(ABS(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_loge) THEN
      CALL get_values(1, values)
      CALL push_on_eval(LOG(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_log10) THEN
      CALL get_values(1, values)
      CALL push_on_eval(LOG10(values(1)))
      RETURN
    ENDIF

    IF (opcode .EQ. c_func_log_base) THEN
      CALL get_values(2, values)
      CALL push_on_eval(LOG(values(1))/LOG(values(2)))
      RETURN
    ENDIF

    err = c_err_unknown_element

  END SUBROUTINE do_functions

END MODULE evaluator_blocks

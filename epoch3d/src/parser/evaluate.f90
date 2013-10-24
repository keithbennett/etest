MODULE evaluator

  USE evaluator_blocks

  IMPLICIT NONE

CONTAINS

  SUBROUTINE basic_evaluate(input_stack, ix, iy, iz, err)

    TYPE(primitive_stack), INTENT(IN) :: input_stack
    INTEGER, INTENT(IN) :: ix, iy, iz
    INTEGER, INTENT(INOUT) :: err
    INTEGER :: i, ierr
    TYPE(stack_element) :: block

    eval_stack%stack_point = 0

    DO i = 1, input_stack%stack_point
      block = input_stack%entries(i)
      IF (block%ptype .EQ. c_pt_variable) THEN
        CALL push_on_eval(block%numerical_data)
      ELSE IF (block%ptype .EQ. c_pt_species) THEN
        CALL do_species(block%value, err)
      ELSE IF (block%ptype .EQ. c_pt_operator) THEN
        CALL do_operator(block%value, err)
      ELSE IF (block%ptype .EQ. c_pt_constant &
          .OR. block%ptype .EQ. c_pt_default_constant) THEN
        CALL do_constant(block%value, c_eval_all, ix, iy, iz, err)
      ELSE IF (block%ptype .EQ. c_pt_function) THEN
        CALL do_functions(block%value, c_eval_all, ix, iy, iz, err)
      ENDIF

      IF (err .NE. c_err_none) THEN
        PRINT *, 'BAD block', err, block%ptype, i, block%value
        CALL MPI_ABORT(MPI_COMM_WORLD, errcode, ierr)
        STOP
      ENDIF
    ENDDO

  END SUBROUTINE basic_evaluate



  SUBROUTINE evaluate_at_point_to_array(input_stack, ix, iy, iz, n_elements, &
      array, err)

    TYPE(primitive_stack), INTENT(IN) :: input_stack
    INTEGER, INTENT(IN) :: ix, iy, iz
    INTEGER, INTENT(IN) :: n_elements
    REAL(num), DIMENSION(:), INTENT(INOUT) :: array
    INTEGER, INTENT(INOUT) :: err
    INTEGER :: i

    CALL basic_evaluate(input_stack, ix, iy, iz, err)

    IF (eval_stack%stack_point .NE. n_elements) err = IOR(err, c_err_bad_value)

    ! Pop off the final answers
    DO i = MIN(eval_stack%stack_point,n_elements),1,-1
      array(i) = pop_off_eval()
    ENDDO

  END SUBROUTINE evaluate_at_point_to_array



  SUBROUTINE evaluate_and_return_all(input_stack, ix, iy, iz, n_elements, &
      array, err)

    TYPE(primitive_stack), INTENT(IN) :: input_stack
    INTEGER, INTENT(IN) :: ix, iy, iz
    INTEGER, INTENT(OUT) :: n_elements
    REAL(num), DIMENSION(:), POINTER :: array
    INTEGER, INTENT(INOUT) :: err
    INTEGER :: i

    IF (ASSOCIATED(array)) DEALLOCATE(array)

    CALL basic_evaluate(input_stack, ix, iy, iz, err)

    n_elements = eval_stack%stack_point
    ALLOCATE(array(1:n_elements))

    ! Pop off the final answers
    DO i = n_elements,1,-1
      array(i) = pop_off_eval()
    ENDDO

  END SUBROUTINE evaluate_and_return_all



  SUBROUTINE evaluate_as_list(input_stack, array, n_elements, err)

    TYPE(primitive_stack), INTENT(IN) :: input_stack
    INTEGER, DIMENSION(:), INTENT(OUT) :: array
    INTEGER, INTENT(OUT) :: n_elements
    INTEGER, INTENT(INOUT) :: err
    INTEGER :: i, ierr
    TYPE(stack_element) :: block

    array(1) = 0
    n_elements = 1

    DO i = 1, input_stack%stack_point
      block = input_stack%entries(i)

      IF (block%ptype .EQ. c_pt_subset) THEN
        n_elements = n_elements + 1
        array(n_elements) = block%value
      ELSE IF (block%ptype .EQ. c_pt_constant &
          .OR. block%ptype .EQ. c_pt_default_constant) THEN
        CALL do_constant(block%value, c_eval_all, 1, 1, 1, err)
        array(1) = array(1) + INT(pop_off_eval())
      ELSE IF (block%ptype .NE. c_pt_operator) THEN
        err = c_err_bad_value
      ENDIF

      IF (err .NE. c_err_none) THEN
        PRINT *, 'BAD block', err, block%ptype, i, block%value
        CALL MPI_ABORT(MPI_COMM_WORLD, errcode, ierr)
        STOP
      ENDIF
    ENDDO

  END SUBROUTINE evaluate_as_list



  FUNCTION evaluate_at_point(input_stack, ix, iy, iz, err)

    TYPE(primitive_stack), INTENT(IN) :: input_stack
    INTEGER, INTENT(IN) :: ix, iy, iz
    INTEGER, INTENT(INOUT) :: err
    REAL(num), DIMENSION(1) :: array
    REAL(num) :: evaluate_at_point

    CALL evaluate_at_point_to_array(input_stack, ix, iy, iz, 1, array, err)
    evaluate_at_point = array(1)

  END FUNCTION evaluate_at_point



  FUNCTION evaluate(input_stack, err)

    TYPE(primitive_stack), INTENT(IN) :: input_stack
    INTEGER, INTENT(INOUT) :: err
    REAL(num) :: evaluate

    evaluate = evaluate_at_point(input_stack, 0, 0, 0, err)

  END FUNCTION evaluate

END MODULE evaluator

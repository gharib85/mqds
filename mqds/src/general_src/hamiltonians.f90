!> This module contains the necessary subroutines
!! and functions to deal with Hamiltonians in the diabatic basis
!! and will be extended in a future version to deal with adiabatic
!! basis
MODULE hamiltonians
  USE kinds
  IMPLICIT NONE
  REAL(dp), ALLOCATABLE :: hel(:,:)
  
CONTAINS
  
  !> Allocates the electronic (system) Hamiltonian to
  !! be a matrix of size nstate X nstate
  SUBROUTINE initialize_hel
    USE input_output
    IMPLICIT NONE
    
    ALLOCATE( hel(nstate,nstate) )
    
  END SUBROUTINE initialize_hel
  
  !> Reads the input electronic (or system) Hamiltonian
  !! from a file called "hel.in"
  SUBROUTINE read_hel
    USE input_output
    IMPLICIT NONE
    INTEGER :: i,j
    
    OPEN(UNIT=10, FILE=INPHEL)
    DO i=1,nstate
       READ(10,*) ( hel(j,i), j=1, nstate)
    END DO
    CLOSE(10)
    
  END SUBROUTINE read_hel
  
  !> Deallocates the electronic (system) Hamiltonian
  SUBROUTINE finalize_hel
    USE input_output
    IMPLICIT NONE
    
    DEALLOCATE( hel )
    
  END SUBROUTINE finalize_hel

  !> Takes the bath position and uses electronic hamiltonian to calculate hel + V(x_bath)
  !! including the harmonic potential energy of the bath.
  FUNCTION diabatic_bilinear_coupling_hamiltonian(x_b,coupling_matrix) RESULT(res)
    USE kinds
    USE input_output
    USE harmonic_bath
    IMPLICIT NONE
    INTEGER :: i,j
    REAL(dp), INTENT(in) :: x_b(:)
    REAL(dp), INTENT(in) :: coupling_matrix(:,:)
    REAL(dp) :: res(nstate, nstate)

    res = hel
    DO i=1, nstate
       DO j=1, nbath*nosc
          res(i, i) = res(i, i) + coupling_matrix(j,i) * x_b(j) !+ 0.5_dp * omega(j)**2 * x_b(j)**2
       END DO
    END DO
    
  END FUNCTION diabatic_bilinear_coupling_hamiltonian


END MODULE hamiltonians

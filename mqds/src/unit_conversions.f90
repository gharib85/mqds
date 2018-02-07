!  
! This module contains a function to perform unit conversions
!
MODULE unit_conversions
  IMPLICIT NONE
  PRIVATE
  PUBLIC convert

CONTAINS
  
  FUNCTION convert(a,b) RESULT(res)
    ! Function that converts units from "a" to "b"
    USE parameters
    USE input_output
    IMPLICIT NONE
    CHARACTER(len=*), INTENT(in) :: a,b
    REAL(dp) :: res
    
    ! Femtoseconds converted to atomic units of time
    IF ( a .EQ. 'fs' .AND. b .EQ. 'au_time' ) THEN
       res = fs2s * s2autime
    ELSE IF ( a .EQ. 'au_time' .AND. b .EQ. 'fs' ) THEN
       res = 1.0_dp / ( fs2s * s2autime )

    ! Kelvin converted to atomic units of energy
    ELSE IF ( a .EQ. 'kelvin' .AND. b .EQ. 'au_energy' ) THEN
       res = kb * joules2au
    ELSE IF ( a .EQ. 'au_energy' .AND. b .EQ. 'kelvin' ) THEN
       res = 1.0_dp / ( kb * joules2au )

    ! Wavenumbers converted to atomic units of angular frequency
    ELSE IF ( a .EQ. 'wvnbr' .AND. b .EQ. 'au_ang_freq' ) THEN
       res = wvnbr2Hz/s2autime*2.0_dp*pi
    ELSE IF ( a .EQ. 'au_ang_freq' .AND. b .EQ. 'wvnbr' ) THEN
       res = 1.0_dp/(wvnbr2Hz/s2autime*2.0_dp*pi)

    ! Wavenumbers converted to atomic units of energy
    ELSE IF ( a .EQ. 'wvnbr' .AND. b .EQ. 'au_energy' ) THEN
       res = wvnbr2joules*joules2au
    ELSE IF ( a .EQ. 'au_energy' .AND. b .EQ. 'wvnbr' ) THEN
       res = 1.0_dp/(wvnbr2joules*joules2au)
    
    ELSE
       OPEN(UNIT=10, FILE=ERRORLOG)
       WRITE(10,*) 'Undefined unit conversion attempted, see file unit_conversions.f90'
       CLOSE(10)
    END IF

  END FUNCTION convert
  
END MODULE unit_conversions

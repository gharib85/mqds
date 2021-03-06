!> This subroutine calculates the reduced density matrix
!! using PLDM with a harmonic bath model in the diabatic basis
!! with bilinear coupling.
SUBROUTINE calculate_pldm_redmat_maphop
  USE kinds
  USE unit_conversions
  USE hamiltonians
  USE mapping_variables
  USE harmonic_bath
  USE input_output
  IMPLICIT NONE
  INTEGER :: i, j, k
  INTEGER :: istep, itraj, itime, islice
  REAL(dp) :: beta
  REAL(dp) :: ham( nstate, nstate )
  REAL(dp) :: bath_force( nosc * nbath )
  REAL(dp) :: dt_bath, dt_map, printstep
  REAL(dp) :: x_bath_save( nosc * nbath, ntraj )
  REAL(dp) :: p_bath_save( nosc * nbath, ntraj )
  REAL(dp) :: bath_force_save( nosc * nbath, ntraj )
  COMPLEX(dp) :: redmat( nstate, nstate, 0 : nbstep / dump )
  COMPLEX(dp) :: redmat_save( nstate, nstate )
  ham = 0.0_dp ; bath_force = 0.0_dp ; dt_bath = 0.0_dp ; dt_map = 0.0_dp
  redmat = ( 0.0_dp , 0.0_dp ) ; beta = 0.0_dp ; x_bath_save = 0.0_dp
  p_bath_save = 0.0_dp

  print*, 'got into the maphop routine'
  ! Calculate Beta for thermal sampling
  beta = 1.0_dp / ( temperature * convert('kelvin','au_energy') )

  ! Setup the necessary timings
  printstep = runtime * REAL( dump ) / REAL( nbstep )
  runtime = runtime * convert('fs','au_time')  
  dt_bath = runtime / REAL(nbstep)
  dt_map = dt_bath / REAL(nlit)

  ! Read the input electonic Hamiltonian
  CALL read_hel
  hel = hel * convert('wvnbr','au_energy')

  DO islice = 1, nslice
      DO itraj=1, ntraj

          itime = (islice - 1) * ( nbstep / nslice ) / dump
          ! Two different initializations, if on second slice initialize
          ! from old bath values, resample mapping and make new initial produce
          IF ( islice == 1 ) THEN
              ! Sample the initial conditions for system mapping and bath DOFs
              CALL sample_thermal_wigner(x_bath, p_bath, beta)
              CALL sample_pldm_map(x_map, p_map, xt_map, pt_map)
              ! Calculate the t=0 redmat
              redmat(:, :, itime) = redmat(:, :, itime) + pldm_redmat(x_map, p_map, xt_map, pt_map)
              ! Find the initial bath force
              bath_force = bilinear_harmonic_force_pldm(x_bath, x_map, p_map, xt_map, pt_map)
              !print*, x_bath(1), x_bath(2)
          ELSE
              CALL pldm_map_hop( redmat_save, x_map, p_map, xt_map, pt_map )
              x_bath( : ) = x_bath_save( :, itraj )
              p_bath( : ) = p_bath_save( :, itraj )
              !bath_force( : ) = bath_force_save( :, itraj )
              bath_force = bilinear_harmonic_force_pldm( x_bath, x_map, p_map, xt_map, pt_map )
              !redmat(:, :, itime) = redmat(:, :, itime) + pldm_redmat(x_map, p_map, xt_map, pt_map)
          END IF


          DO istep = 1, nbstep / nslice

              ! First half of the verlet
              x_bath = x_bath + p_bath * dt_bath + bath_force * 0.5_dp * dt_bath ** 2
              p_bath = p_bath + bath_force * 0.5_dp * dt_bath

              ! Update the full hamiltonian
              ham = diabatic_bilinear_coupling_hamiltonian(x_bath, c)

              ! Propagate the mapping variables
              CALL verlet_mapping_variables(x_map, p_map, ham, dt_map)
              CALL verlet_mapping_variables(xt_map, pt_map, ham, dt_map)

              ! If the step is divisible by dump, compute the redmat
              IF ( MOD( istep, dump) == 0 ) THEN
                  itime = itime + 1
                  redmat(:, :, itime) = redmat(:, :, itime) + pldm_redmat(x_map, p_map, xt_map, pt_map)
              END IF

              ! Update the force and finish the verlet
              bath_force = bilinear_harmonic_force_pldm(x_bath, x_map, p_map, xt_map, pt_map)
              p_bath = p_bath + bath_force * 0.5_dp * dt_bath

          END DO


          x_bath_save( :, itraj ) = x_bath( : )
          p_bath_save( :, itraj ) = p_bath( : )
          bath_force_save( :, itraj ) = bath_force( : )
      END DO
      redmat( :, :, (islice - 1) * nbstep / nslice + 1 : islice * nbstep / nslice ) =  &
              redmat( :, :, (islice - 1) * nbstep / nslice + 1 : islice * nbstep / nslice ) / REAL( ntraj )
      redmat_save( :, : ) = redmat( :, :, itime )
  END DO


  redmat( :, :, 0 ) = redmat( :, :, 0 ) / REAL( ntraj )
  CALL write_redmat(method, redmat, printstep)


END SUBROUTINE calculate_pldm_redmat_maphop

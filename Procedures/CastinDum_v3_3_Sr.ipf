#pragma rtGlobals=1		// Use modern global access method.

//! @file
//! @brief Compute the 3 Castin-Dum scaling parameters for a freely expanding BEC.
//! @details They are computed using Igor's built in ODE solver.
//! 
//! See http://link.aps.org/doi/10.1103/PhysRevLett.77.5315 for reference.

// *************** CastinDum ***************************************************************
//!
//! @brief Generates a wave containing the Castin-Dum scaling parameters
//! @details Uses Igor's built-in ODE solver to compute.
//!
//! See "Bose-Einstein Condensates in Time Dependent Traps" Castin &Dum.
//! PRL 77, 5315. 1996.
//!
//! @note This should be considered to be the only user accessible function in the procedure.
//! @public
//!
//! @param[in]  t      expansion time over which to generate the parameters
//! @param[in]  omega  angular trap frequencies in (x, y, z) order
//! @param[out] lambda destination wave for scaling parameters in (x, y, z) order
//! @sa http://link.aps.org/doi/10.1103/PhysRevLett.77.5315
function CastinDum(t, omega,lambda)
	// t			Expansion time
	// omega 	Wave of trap angular frequencies in order x,y,z
	// lambda	results of computation
	variable t
	wave omega
	wave lambda
		
	// The number of points for the integration
	variable points = 100;
	
	Make/D/O/N=(points,6) CastinDumWave_Temp
	wave CastinDumWave =  CastinDumWave_Temp
	
	SetScale/P x 0, t / (Points-1), CastinDumWave		// calculate factors with a time step of t / (Points-1)
	//SetDimLabel 1,0,l1,CastinDumWave					// set dimension labels to substance names
	//SetDimLabel 1,1,dl1,CastinDumWave				// this can be done in a table if you make
	//SetDimLabel 1,2,l2,CastinDumWave					// the table using edit ChemKin.ld
	//SetDimLabel 1,3,dl2,CastinDumWave
	//SetDimLabel 1,4,l3,CastinDumWave
	//SetDimLabel 1,5,dl3,CastinDumWave
	
	// initial conditions
	CastinDumWave[0][0] = 1
	CastinDumWave[0][1] = 0	
	CastinDumWave[0][2] = 1						// note indexing using dimension labels
	CastinDumWave[0][3] = 0
	CastinDumWave[0][4] = 1
	CastinDumWave[0][5] = 0

	IntegrateODE/Q/M=1 CastinDumDerivitive, omega, CastinDumWave

	Lambda[0] = CastinDumWave[Points-1][0];
	Lambda[1] = CastinDumWave[Points-1][2];
	Lambda[2] = CastinDumWave[Points-1][4];
	
	killwaves CastinDumWave
end

// ***************  CastinDumDerivitive ***************************************************************
//!
//! @brief Computes the derivatives for the Castin-Dum scale parameters for Igor's ODE solver
//! @details Because Igor's solver uses only first-order equations, we manually transformed
//! the second-order set into twice as many first-order equations.  As a result, the \p yw bits
//! correspond:
//!  + yw[0] = lambda_x
//!  + yw[1] = d lambda_x/dt
//!  + yw[2] = lambda_y
//!  + \e etc.
//!
//! @note This should only be called by ::CastinDum
//! @private
//!
//! @param[in]  pw   The trap frequencies in (x, y, z) order.
//! @param[in]  tt   The time at which to generate the scale parameters
//! @param[in]  yw   The current scaling functions and their derivatives
//! @param[out] dydt The current derivatives of the \p yw values for computing the next step
Function CastinDumDerivitive(pw, tt, yw, dydt)
	Wave pw	// pw[0] = w1, pw[1] = w2, pw[2] = w3
	Variable tt	// time value at which to calculate derivatives
	Wave yw	// yw[0]-yw[3] containing the 3 scaling functions and their derivatives
	Wave dydt	// wave to receive dlambda/dt (output)
	dydt[0] = yw[1];
	dydt[1] = pw[0]^2 / (yw[0]^2 * yw[2] * yw[4]) ;
	dydt[2] = yw[3];
	dydt[3] = pw[1]^2 / (yw[0] * yw[2]^2 * yw[4]) ;
	dydt[4] = yw[5];
	dydt[5] = pw[2]^2 / (yw[0] * yw[2] * yw[4]^2) ;
End

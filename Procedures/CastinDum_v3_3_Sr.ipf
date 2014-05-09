#pragma rtGlobals=1		// Use modern global access method.


// The functions in this file compute the 3 Castin-Dum scaling paramaters
// for a freely expanding BEC.
//
// They are computed using Igor's built in ODE solver

// ***************  CastinDum ***************************************************************
// This should be considered to be the only user accessable function in the procedure.  When called it will
// return a wave containing the Castin Dum scaling paramaters.

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
//
// This function computes the derivities for the Castin Dum
// Scaling paramaters, from which Igor can numerical integrate
// for the case of interest.
//
// Because Igor requires only 1st order equations, there
// are twice as many paramters as you might expect here:
// y[0] = lambad0
// y[1] = d lambda0 / dt
// and etc.

Function CastinDumDerivitive(pw, tt, yw, dydt)
	Wave pw	// pw[0] = w1, pw[1] = w2, pw[2] = w3
	Variable tt	// time value at which to calculate derivatives
	Wave yw	// yw[0]-yw[3] containing the 3 scaling functions and their derivitives
	Wave dydt	// wave to receive dlambda/dt (output)
	dydt[0] = yw[1];
	dydt[1] = pw[0]^2 / (yw[0]^2 * yw[2] * yw[4]) ;
	dydt[2] = yw[3];
	dydt[3] = pw[1]^2 / (yw[0] * yw[2]^2 * yw[4]) ;
	dydt[4] = yw[5];
	dydt[5] = pw[2]^2 / (yw[0] * yw[2] * yw[4]^2) ;
End

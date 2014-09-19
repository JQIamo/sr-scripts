#pragma rtGlobals=1		// Use modern global access method.



//Make3BodyWaves creates two waves for extracting 3 body decay constants.

//The first wave is y3body = Ln(N/N0)+t/tau.

//The second wave is x3body = const*Integrate[rhopeak(t')^2,{t',0,t}]

//mode = 0 for thermal gas, mode = 1 for BEC

Function Make3BodyWaves(numWave,numSD,rhoWave,rhoSD,tWave,gam1,gam1SD,mode)

	

	Wave numWave, numSD, rhoWave, rhoSD, tWave

	Variable gam1,gam1SD,mode

	

	//mask the data

	Duplicate/FREE/D numWave, numTemp;

	Duplicate/FREE/D numSD, numSDTemp;

	Duplicate/FREE/D rhoWave, rhoTemp;

	Duplicate/FREE/D rhoSD, rhoSDTemp;

	Duplicate/FREE/D tWave, tTemp;

	

	//make destination waves

	Make/O/D/N=(numpnts(tTemp)) y3Body, y3Body_SD, x3Body, x3Body_SD;

	

	//Monte Carlo to estimate integral errors

	Variable iterations = 100;

	Make/FREE/D/N=(iterations,numpnts(tTemp)) MCtemp;

	Duplicate/FREE/D rhoSDTemp, MCpath;

	Variable i;

	//Do the Monte Carlo

	For(i=0;i<iterations;i+=1)

		//Generate fake data assuming gaussian distribution

		MCpath = rhoTemp[p]+gnoise(rhoSDTemp[p],2);

		MCpath = MCpath^2;

		//Integrate fake data

		Integrate/METH=1 MCpath /X=tTemp /D=integTemp;

		if(mode==0)

			MCtemp[i][0,numpnts(tTemp)-1] = 3^(-3/2)*integTemp[q];//Thermal gas

		else

			MCtemp[i][0,numpnts(tTemp)-1] = (8/21)*integTemp[q];//BEC

		endif

	endFor

	//Extract Uncertainties

	Make/FREE/D/N=(iterations) MCpathSD;

	For(i=0;i<numpnts(tTemp);i+=1)

		MCpathSD=MCtemp[p][i];

		WaveStats/Q/Z/M=2 MCpathSD;

		x3Body_SD[i] = V_sdev;

	endFor

	

	rhoTemp = rhoTemp^2;

	Integrate/METH=1 rhoTemp /X=tTemp /D=integTemp;

	if(mode==0)

		x3Body = 3^(-3/2)*integTemp;//Thermal gas

	else

		x3Body = (8/21)*integTemp;//BEC

	endif

	

	y3Body = ln(numTemp[p]/numTemp[0])+(tTemp[p]-tTemp[0])*gam1;

	y3Body_SD = sqrt((numSDTemp[p]/numTemp[p])^2+(gam1SD*(tTemp[p]-tTemp[0]))^2);

	KillWaves integTemp;



	//K0=0;

	//CurveFit/ODR=2/H="10"/NTHR=0/TBOX=768 line  y3Body[pcsr(A),pcsr(B)] /X=x3Body /W=y3Body_SD /I=1 /D /F={0.683000, 4} /XW=x3Body_SD;

End



Function NBodyDecay(w, t) : FitFunc

	Wave w

	Variable t

	

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will

	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.

	//CurveFitDialog/ Equation:

	//CurveFitDialog/ f(t) = w[0]*exp(-w[1]*t-w[2]*t)

	//CurveFitDialog/ End of Equation

	//CurveFitDialog/ Independent Variables 1

	//CurveFitDialog/ t

	//CurveFitDialog/ Coefficients 3

	//CurveFitDialog/ w[0] = N0

	//CurveFitDialog/ w[1] = gam1

	//CurveFitDialog/ w[2] = gam3



	return w[0]*exp(-w[1]*t-w[2]*t)

End



Function ExactBodyDecay(w, t) : FitFunc

	Wave w

	Variable t

	

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will

	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.

	//CurveFitDialog/ Equation:

	//CurveFitDialog/ f(t) = w[0]*Sqrt(w[1]/(exp(2*w[1]*t)*w[1]-w[2]*w[0]^2+exp(2*w[1]*t)*w[2]*w[0]^2))

	//CurveFitDialog/ End of Equation

	//CurveFitDialog/ Independent Variables 1

	//CurveFitDialog/ t

	//CurveFitDialog/ Coefficients 4

	//CurveFitDialog/ w[0] = N0

	//CurveFitDialog/ w[1] = gam1

	//CurveFitDialog/ w[2] = gam3

	//CurveFitDialog/ w[3] = t0



	return w[0]*Sqrt(w[1]/(exp(2*w[1]*(t-w[3]))*w[1]-w[2]*w[0]^2+exp(2*w[1]*(t-w[3]))*w[2]*w[0]^2))

End



//MakeLattice3BodyWaves creates two waves for extracting 3 body decay constants from a gas trapped in a 2D Lattice.

//The first wave is y3body = Ln(N/N0)+t/tau.
//The second wave is x3body = const*Integrate[rhopeak(t')^2,{t',0,t}]

//MUST SET DATAFOLDER TO BE THE PROJECT FOLDER FOR THE DATA SERIES!

Function MakeLattice3BodyWaves(numWave,numSD,T_Wave,T_SD,timeWave,gam1,gam1SD)

	
	//numWave = wave of average atom numbers
	//numSD = wave of standard deviations of atom number
	//T_wave = wave of average temperatures
	//T_SD = wave of standard deviations of temperature
	//timeWave = wave of lattice hold times
	Wave numWave, numSD, T_Wave, T_SD, timeWave

	//gam1 = Measured 1 body decay rate
	//gam1SD = standard deviation in fit of 1 body decay rate
	Variable gam1,gam1SD

	//Assume that the current datafolder is the project folder
	//and get the trap frequencies
	NVAR omgX = :Experimental_Info:omgX;
	NVAR omgY = :Experimental_Info:omgY;
	NVAR omgZ = :Experimental_Info:omgZ;
	NVAR omgXLat = :Experimental_Info:omgXLat;
	NVAR omgYLat = :Experimental_Info:omgYLat;
	NVAR omgZLat = :Experimental_Info:omgZLat;
	NVAR mass = :Experimental_Info:mass;

	//mask the data

	Duplicate/FREE/D numWave, numTemp;

	Duplicate/FREE/D numSD, numSDTemp;

	Duplicate/FREE/D T_Wave, T_Temp;

	Duplicate/FREE/D T_SD, T_SDTemp;

	Duplicate/FREE/D timeWave, timeTemp;

	

	//make destination waves

	Make/O/D/N=(numpnts(timeTemp)) y3Body, y3Body_SD, x3Body, x3Body_SD;

	//Make waves to store the reference volumes
	//RefVolTrap will store the reference volume for the harmonic confinement
	//RefVolSite will store the reference volume for an individual lattice site
	//N_sites is the number of sites with atoms
	Make/O/D/FREE/N=(numpnts(timeTemp)) RefVolTrap,RefVolSite,RefVolTrap_SD,RefVolSite_SD, N_sites,N_sites_SD;
	
	//First compute the reference volume for the harmonic trap
	RefVolTrap = (2*pi*kB*T_temp[p]*(1e-9)/mass)^(3/2)/(omgX*omgY*omgZ);
	RefVolTrap_SD = 3/2*T_SDTemp[p]*(1e-9)*(2*pi*kB*T_temp[p]*(1e-9)/mass)^(1/2)/(omgX*omgY*omgZ);
	//compute the reference volume for the lattice sites
	RefVolSite = (2*pi*kB*T_temp[p]*(1e-9)/mass)^(3/2)/(omgXLat*omgY*omgZLat);
	RefVolSite_SD = 3/2*T_SDTemp[p]*(1e-9)*(2*pi*kB*T_temp[p]*(1e-9)/mass)^(1/2)/(omgXLat*omgY*omgZLat);
	//Number of lattice sites per unit area:
	Variable site_density = 1/(.532e-6)^2;
	
	//get approximate number of loaded sites at each step
	N_sites = floor(site_density*(2*pi*kB*T_temp[p]*(1e-9)/(mass*omgX*omgZ)));
	N_sites_SD = site_density*(2*pi*kB*T_SDtemp[p]*(1e-9)/(mass*omgX*omgZ));

	//Monte Carlo to estimate integral errors
	//Set iterations to match number of points used to compute
	//number and temperature averages

	Variable iterations = 10;

	Make/FREE/D/N=(iterations,numpnts(timeTemp)) MCtemp;

	Duplicate/FREE/D T_SDTemp, MCpath;

	Variable i;

	//Do the Monte Carlo

	For(i=0;i<iterations;i+=1)

		//Generate fake data assuming gaussian distribution

		MCpath = T_Temp[p]+gnoise(T_SDTemp[p],2);

		MCpath = MCpath^2;

		//Integrate fake data

		Integrate/METH=1 MCpath /X=tTemp /D=integTemp;

		if(1)

			MCtemp[i][0,numpnts(tTemp)-1] = 3^(-3/2)*integTemp[q];//Thermal gas

		else

			MCtemp[i][0,numpnts(tTemp)-1] = (8/21)*integTemp[q];//BEC

		endif

	endFor

	//Extract Uncertainties

	Make/FREE/D/N=(iterations) MCpathSD;

	For(i=0;i<numpnts(tTemp);i+=1)

		MCpathSD=MCtemp[p][i];

		WaveStats/Q/Z/M=2 MCpathSD;

		x3Body_SD[i] = V_sdev;

	endFor

	

	//rhoTemp = rhoTemp^2;

	Integrate/METH=1 rhoTemp /X=tTemp /D=integTemp;

	if(1)

		x3Body = 3^(-3/2)*integTemp;//Thermal gas

	else

		x3Body = (8/21)*integTemp;//BEC

	endif

	

	y3Body = ln(numTemp[p]/numTemp[0])+(timeTemp[p]-timeTemp[0])*gam1;

	y3Body_SD = sqrt((numSDTemp[p]/numTemp[p])^2+(gam1SD*(timeTemp[p]-timeTemp[0]))^2);

	KillWaves integTemp;



	//K0=0;

	//CurveFit/ODR=2/H="10"/NTHR=0/TBOX=768 line  y3Body[pcsr(A),pcsr(B)] /X=x3Body /W=y3Body_SD /I=1 /D /F={0.683000, 4} /XW=x3Body_SD;

End
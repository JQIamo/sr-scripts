#pragma rtGlobals=1		// Use modern global access method.

//! @file
//! @brief Does 3-Body calculations for Sr's stuffs.


//!
//! @brief creates two waves for extracting 3 body decay constants.
//! @details The first wave is y3body = Ln(N/N0)+t/tau.
//! @details The second wave is x3body = const*Integrate[rhopeak(t')^2,{t',0,t}]
//! @warning MUST SET DATAFOLDER TO BE THE PROJECT FOLDER FOR THE DATA SERIES!
//!
//! @param[in] numWave  wave of average atom numbers
//! @param[in] numSD    wave of standard deviations of atom number
//! @param[in] rhoWave  wave of average ??
//! @param[in] rhoSD    wave of standard deviations of ??
//! @param[in] tWave    ??
//! @param[in] gam1     Measured 1 body decay rate
//! @param[in] gam1SD   standard deviation in fit of 1 body decay rate
//! @param[in] mode     \b 0 for thermal gas, \b 1 for BEC
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


//!
//! @brief Fit function N0*exp(-gam1*t-gam2*t)
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


//!
//! @brief Fit function n0*Sqrt(K1/(exp(2*K1*(t-t0))*K1-K3*n0^2+exp(2*K1*(t-t0))*K3*n0^2))
//! @details n0 = density, t0 = time coord of first point in fit
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

	//CurveFitDialog/ w[0] = n0

	//CurveFitDialog/ w[1] = K1

	//CurveFitDialog/ w[2] = K3

	//CurveFitDialog/ w[3] = t0



	return w[0]*Sqrt(w[1]/(exp(2*w[1]*(t-w[3]))*w[1]-w[2]*w[0]^2+exp(2*w[1]*(t-w[3]))*w[2]*w[0]^2))

End



//!
//! @brief creates two waves for extracting 3 body decay constants from a gas trapped in a 2D Lattice.
//! @details It will also work with a 1D or 3D Lattice provided that there is external harmonic confinement along each lattice direction
//! For a vertical lattice with no harmonic confinement, use ::MakeVLattice3BodyWaves instead.
//! @details The first wave is y3body = Ln(N/N0)+t/tau.
//! @details The second wave is x3body = const*Integrate[rhopeak(t')^2,{t',0,t}]
//! @warning MUST SET DATAFOLDER TO BE THE PROJECT FOLDER FOR THE DATA SERIES!
//!
//! @param[in] numWave  wave of average atom numbers
//! @param[in] numSD    wave of standard deviations of atom number
//! @param[in] T_Wave   wave of axial temperatures
//! @param[in] T_SD     wave of standard deviations of temperature
//! @param[in] timeWave wave of lattice hold times
//! @param[in] gam1     Measured 1 body decay rate
//! @param[in] gam1SD   standard deviation in fit of 1 body decay rate
//! @param[in] mode     \b 0 for thermal gas, \b 1 for BEC
Function Make2DLattice3BodyWaves(numWave,numSD,T_Wave,T_SD,timeWave,gam1,gam1SD,mode)

	
	//numWave = wave of average atom numbers
	//numSD = wave of standard deviations of atom number
	//T_wave = wave of average temperatures
	//T_SD = wave of standard deviations of temperature
	//timeWave = wave of lattice hold times
	Wave numWave, numSD, T_Wave, T_SD, timeWave

	//gam1 = Measured 1 body decay rate
	//gam1SD = standard deviation in fit of 1 body decay rate
	Variable gam1,gam1SD,mode

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
	Make/O/D/N=(numpnts(timeTemp)) x3BodyExt, x3BodyExt_SD;
	Make/O/D/N=(numpnts(timeTemp)) rho3Body, rho3Body_SD;
	Make/O/D/N=(numpnts(timeTemp)) rho3BodyExt, rho3BodyExt_SD;

	//Make waves to store the reference volumes
	//RefVolTrap will store the reference volume for the harmonic confinement
	//RefVolSite will store the reference volume for an individual lattice site
	//N_sites is the number of sites with atoms
	Make/O/D/FREE/N=(numpnts(timeTemp)) RefVolSite,RefVolSite_SD, N_sites,N_sites_SD;
	
	//compute the reference volume for the lattice sites
	RefVolSite = (2*pi*kB*T_temp[p]*(1e-9)/mass)^(3/2)/(omgXLat*omgY*omgZ);
	RefVolSite_SD = 3/2*T_SDTemp[p]*(1e-9)*(2*pi*kB*T_temp[p]*(1e-9)/mass)^(1/2)/(omgXLat*omgY*omgZ);
	//Number of lattice sites per unit length for 1064 nm lattice beams:
	Variable site_density = 1/(.532e-6);
	
	//get approximate number of loaded sites at each step
	N_sites = site_density*sqrt(pi)*400*1e-6;//sqrt(2*pi*kB*T_temp[p]*(1e-9)/mass)/omgX;
	N_sites_SD = site_density*sqrt(pi)*25*1e-6;//sqrt(2*pi*kB*T_SDtemp[p]*(1e-9)/mass)/omgX;
	
	//make a wave to hold computed density
	Make/O/D/FREE/N=(numpnts(timeTemp)) rhoTemp,rhoTemp_SD,rhoTempExt,rhoTempExt_SD;
	
	//approximate the density, in atoms/(m^3):
	rhoTemp = numTemp[p]/(RefVolSite[p]*N_sites[p]);
	rhoTemp_SD = Sqrt((numSDTemp[p]/(RefVolSite[p]*N_sites[p]))^2+(RefVolSite_SD[p]*numTemp[p]/((RefVolSite[p]^2)*N_sites[p]))^2+(N_sites_SD[p]*numTemp[p]/(RefVolSite[p]*N_sites[p]^2))^2);
	rho3Body = rhoTemp*10^(-6);
	rho3Body_SD = rhoTemp_SD*10^(-6);
	//numeric integration for exact density, in atoms/(um^3)
	rhoTempExt = numTemp[p]/getEffVol(T_temp[p]);
	rhoTempExt_SD = 0;     //need to think about how to get standard error for numeric integral
	rho3BodyExt = rhoTempExt*10^(12);
	rho3BodyExt_SD = rhoTempExt_SD*10^(12);

	//Monte Carlo to estimate integral errors
	//Set iterations to match number of points used to compute
	//number and temperature averages

	Variable iterations = 10;

	Make/O/FREE/D/N=(iterations,numpnts(timeTemp)) MCtemp;

	Duplicate/FREE/O/D rhoTemp_SD, MCpath;

	Variable i;

	//Do the Monte Carlo

	For(i=0;i<iterations;i+=1)

		//Generate fake data assuming gaussian distribution
		MCpath = rhoTemp[p]+gnoise(rhoTemp_SD[p],2);

		MCpath = MCpath^2;

		//Integrate fake data

		Integrate/METH=1 MCpath /X=timeTemp /D=integTemp;
		
		if(mode==0)

			MCtemp[i][0,numpnts(timeTemp)-1] = 3^(-2)*integTemp[q]*10^(-12);//Thermal gas
			print i

		else

			MCtemp[i][0,numpnts(timeTemp)-1] = (8/21)*(1/2)*integTemp[q]*10^(-12);//BEC

		endif

	endFor

	//Extract Uncertainties

	Make/FREE/D/N=(iterations) MCpathSD;

	For(i=0;i<numpnts(timeTemp);i+=1)

		MCpathSD=MCtemp[p][i];

		WaveStats/Q/Z/M=2 MCpathSD;

		x3Body_SD[i] = V_sdev;

	endFor

	

	rhoTemp = rhoTemp^2;
	rhoTempExt = rhoTempExt^2;
	rhoTempExt = rhoTempExt[p]*getEffVol(T_temp[p]/3)/getEffVol(T_temp[p]);

	Integrate/METH=1 rhoTemp /X=timeTemp /D=integTemp;

	if(mode==0)

		x3Body = 3^(-2)*integTemp*10^(-12);//Thermal gas

	else

		x3Body = (8/21)*(1/2)*integTemp*10^(-12);//BEC

	endif
	
	Integrate/METH=1 rhoTempExt /X=timeTemp /D=integTemp;

	if(mode==0)

		x3BodyExt = integTemp*10^(24);//Thermal gas

	else

		//note that the getEffVol is for a thermal gas only
		//so this is not the correct x3Body
		x3BodyExt = integTemp*10^(24);//BEC

	endif

	

	y3Body = ln(numTemp[p]/numTemp[0])+(timeTemp[p]-timeTemp[0])*gam1;

	y3Body_SD = sqrt((numSDTemp[p]/numTemp[p])^2+(gam1SD*(timeTemp[p]-timeTemp[0]))^2);

	KillWaves integTemp;



	//K0=0;

	//CurveFit/ODR=2/H="10"/NTHR=0/TBOX=768 line  y3Body[pcsr(A),pcsr(B)] /X=x3Body /W=y3Body_SD /I=1 /D /F={0.683000, 4} /XW=x3Body_SD;

End

//!
//! @brief creates two waves for extracting 3 body decay constants from a gas trapped in a vertical lattice
//! which does not have external harmonic confinement along the lattice direction
//! @details It will also work with a 1D or 3D Lattice provided that there is external harmonic confinement along each lattice direction
//! For a vertical lattice with no harmonic confinement, use ::MakeVLattice3BodyWaves instead.
//! @details The first wave is y3body = Ln(N/N0)+t/tau.
//! @details The second wave is x3body = const*Integrate[rhopeak(t')^2,{t',0,t}]
//! @warning MUST SET DATAFOLDER TO BE THE PROJECT FOLDER FOR THE DATA SERIES!
//!
//! @param[in] numWave     wave of average atom numbers
//! @param[in] numSD       wave of standard deviations of atom number
//! @param[in] T_Wave      wave of axial temperatures
//! @param[in] T_SD        wave of standard deviations of temperature
//! @param[in] timeWave    wave of lattice hold times
//! @param[in] gam1        Measured 1 body decay rate
//! @param[in] gam1SD      standard deviation in fit of 1 body decay rate
//! @param[in] z_1e_t0     is the in-situ 1/e size of the cloud along the lattice direction
//! @param[in] z_1e_t0_SD  is standard deviation of the in-situ 1/e size
//! @param[in] mode        \b 0 for thermal gas, \b 1 for BEC
Function MakeVLattice3BodyWaves(numWave,numSD,T_Wave,T_SD,timeWave,gam1,gam1SD,z_1e_t0,z_1e_t0_SD,mode)

	
	//numWave = wave of average atom numbers
	//numSD = wave of standard deviations of atom number
	//T_wave = wave of average temperatures
	//T_SD = wave of standard deviations of temperature
	//timeWave = wave of lattice hold times
	Wave numWave, numSD, T_Wave, T_SD, timeWave

	//gam1 = Measured 1 body decay rate
	//gam1SD = standard deviation in fit of 1 body decay rate
	//z_1e_t0 is the in-situ 1/e size of the cloud along the lattice direction
	//z_1e_t0_SD is standard deviation of the in-situ 1/e size
	Variable gam1,gam1SD,mode
	Variable z_1e_t0,z_1e_t0_SD

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

	//T_Temp = 1900;

	//make destination waves

	Make/O/D/N=(numpnts(timeTemp)) y3Body, y3Body_SD, x3Body, x3Body_SD;
	//Make/O/D/N=(numpnts(timeTemp)) x3BodyExt, x3BodyExt_SD;
	Make/O/D/N=(numpnts(timeTemp)) rho3Body, rho3Body_SD;

	//Make waves to store the reference volumes
	//RefVolTrap will store the reference volume for the harmonic confinement
	//RefVolSite will store the reference volume for an individual lattice site
	//N_sites is the number of sites with atoms
	Make/O/D/FREE/N=(numpnts(timeTemp)) RefVolSite,RefVolSite_SD, N_sites,N_sites_SD;
	
	//compute the reference volume for the lattice sites
	RefVolSite = (2*pi*kB*T_temp[p]*(1e-9)/mass)^(3/2)/(omgX*omgY*omgZLat);
	RefVolSite_SD = 3/2*T_SDTemp[p]*(1e-9)*(2*pi*kB*T_temp[p]*(1e-9)/mass)^(1/2)/(omgX*omgY*omgZLat);
	//Number of lattice sites per unit length for 1064 nm lattice beams:
	Variable site_density = 1/(.532e-6);
	
	//get approximate number of loaded sites at each step
	N_sites = site_density*sqrt(pi)*z_1e_t0*1e-6;
	N_sites_SD = site_density*sqrt(pi)*z_1e_t0_SD*1e-6;
	
	//make a wave to hold computed density
	Make/O/D/FREE/N=(numpnts(timeTemp)) rhoTemp,rhoTemp_SD,rhoTempExt,rhoTempExt_SD;
	
	//approximate the density, in atoms/(m^3):
	rhoTemp = numTemp[p]/(RefVolSite[p]*N_sites[p]);
	rho3Body = rhoTemp*10^(-6);
	rhoTemp_SD = Sqrt((numSDTemp[p]/(RefVolSite[p]*N_sites[p]))^2+(RefVolSite_SD[p]*numTemp[p]/((RefVolSite[p]^2)*N_sites[p]))^2+(N_sites_SD[p]*numTemp[p]/(RefVolSite[p]*N_sites[p]^2))^2);
	rho3Body_SD = rhoTemp_SD*10^(-6);
	//numeric integration for exact density, in atoms/(um^3)
	//rhoTempExt = numTemp[p]/getEffVol(T_temp[p]);
	//rhoTempExt_SD = 0;     //need to think about how to get standard error for numeric integral

	//Monte Carlo to estimate integral errors
	//Set iterations to match number of points used to compute
	//number and temperature averages

	Variable iterations = 10;

	Make/FREE/D/N=(iterations,numpnts(timeTemp)) MCtemp;

	Duplicate/FREE/D rhoTemp_SD, MCpath;

	Variable i;

	//Do the Monte Carlo

	For(i=0;i<iterations;i+=1)

		//Generate fake data assuming gaussian distribution

		MCpath = rhoTemp[p]+gnoise(rhoTemp_SD[p],2);

		MCpath = MCpath^2;

		//Integrate fake data

		Integrate/METH=1 MCpath /X=timeTemp /D=integTemp;

		if(mode==0)

			MCtemp[i][0,numpnts(timeTemp)-1] = 3^(-2)*integTemp[q]*10^(-12);//Thermal gas

		else

			MCtemp[i][0,numpnts(timeTemp)-1] = (8/21)*(1/2)*integTemp[q]*10^(-12);//BEC

		endif

	endFor

	//Extract Uncertainties

	Make/FREE/D/N=(iterations) MCpathSD;

	For(i=0;i<numpnts(timeTemp);i+=1)

		MCpathSD=MCtemp[p][i];

		WaveStats/Q/Z/M=2 MCpathSD;

		x3Body_SD[i] = V_sdev;

	endFor

	

	rhoTemp = rhoTemp^2;
	//rhoTempExt = rhoTempExt^2;
	//rhoTempExt = rhoTempExt[p]*getEffVol(T_temp[p]/3)/getEffVol(T_temp[p]);

	Integrate/METH=1 rhoTemp /X=timeTemp /D=integTemp;

	if(mode==0)

		x3Body = 3^(-2)*integTemp*10^(-12);//Thermal gas

	else

		x3Body = (8/21)*(1/2)*integTemp*10^(-12);//BEC

	endif
	
	//Integrate/METH=1 rhoTempExt /X=tTemp /D=integTemp;

	//if(mode==0)

		//x3BodyExt = integTemp*10^(24);//Thermal gas

	//else

		//note that the getEffVol is for a thermal gas only
		//so this is not the correct x3Body
		//x3BodyExt = integTemp*10^(24);//BEC

	//endif

	

	y3Body = ln(numTemp[p]/numTemp[0])+(timeTemp[p]-timeTemp[0])*gam1;

	y3Body_SD = sqrt((numSDTemp[p]/numTemp[p])^2+(gam1SD*(timeTemp[p]-timeTemp[0]))^2);

	KillWaves integTemp;



	//K0=0;

	//CurveFit/ODR=2/H="10"/NTHR=0/TBOX=768 line  y3Body[pcsr(A),pcsr(B)] /X=x3Body /W=y3Body_SD /I=1 /D /F={0.683000, 4} /XW=x3Body_SD;

End

//!
//! @brief creates a wave for extracting 3 body decay constants from a gas trapped in a 2D Lattice.
//! @details
//! The first wave is y3body = Ln(N/N0)+t/tau.
//! The second wave is x3body = const*Integrate[rhopeak(t')^2,{t',0,t}]
//! @warning MUST SET DATAFOLDER TO BE THE PROJECT FOLDER FOR THE DATA SERIES!
//!
//! @param[in] numWave  wave of average atom numbers
//! @param[in] Tx_Wave  wave of axial temperatures
//! @param[in] Tz_Wave  wave of vertical temperatures
//! @param[in] timeWave wave of lattice hold times
//! @param[in] xw_t0    Measured ??In-situ size??
//! @param[in] xw_t0_SD standard deviation in fit of ??In-situ size??
//! @param[in] mode     \b 0 for thermal gas, \b 1 for BEC
Function Make2DLatticeDensityWave(numWave,Tx_Wave,Tz_Wave,timeWave,xw_t0,xw_t0_SD,mode)

	
	//numWave = wave of average atom numbers
	//Tx_wave = wave of axial temperatures
	//Tz_wave = wave of vertical temperatures
	//timeWave = wave of lattice hold times
	Wave numWave, Tx_Wave, Tz_Wave, timeWave

	//gam1 = Measured 1 body decay rate
	//gam1SD = standard deviation in fit of 1 body decay rate
	Variable xw_t0,xw_t0_SD,mode

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
	Duplicate/FREE/D Tx_Wave, Tx_Temp;
	Duplicate/FREE/D Tz_Wave, Tz_Temp;
	Duplicate/FREE/D timeWave, timeTemp;

	//make destination waves

	//Make/O/D/N=(numpnts(timeTemp)) rho3Body, rho3Body_SD;
	Make/O/D/N=(numpnts(timeTemp)) rho3BodyExt
	
	//make a wave to hold computed density
	Make/O/D/FREE/N=(numpnts(timeTemp)) rhoTempExt;
	
	//numeric integration for exact density, in atoms/(um^3)
	rhoTempExt = numTemp[p]/getEffVol_insitu(Tx_temp[p]-1000,Tz_Temp[p],xw_t0);
	//rhoTempExt_SD = 0;     //need to think about how to get standard error for numeric integral
	rho3BodyExt = rhoTempExt*10^(12);     //convert to atoms/(cm^3)
	//rho3BodyExt_SD = rhoTempExt_SD*10^(12);

End

//!
//! @brief This function numerically integrates a 2D lattice potential to find the reference volume for our Sr88 3Body measurements
//! @param[in] T temperature in nK
Function getEffVol(T)
	
	//T is temperature in nK
	Variable T
	
	//define and get globals to do the integration
	NVAR freqX = :Experimental_Info:freqX;
	NVAR freqY = :Experimental_Info:freqY;
	NVAR freqZ = :Experimental_Info:freqZ;
	NVAR freqXLat = :Experimental_Info:freqXLat;
	NVAR freqYLat = :Experimental_Info:freqYLat;
	NVAR freqZLat = :Experimental_Info:freqZLat;
	NVAR mass = :Experimental_Info:mass;
	NVAR k = :Experimental_Info:k;
	
	//this is dangerous because it could overwrite another global
	Variable/G tEffVol_temp = T*(1e-9);
	
	//set limits of integration, we could do this based on T
	//but this works for now
	Variable intLim = 2000;     //distance in microns
	//decrease intLim for small temperature
	if(T<=200)
		intLim = 250;
	endif
	
	//romberg integration since trapezoidal seems to fail for low temperatures
	//gaussian quadrature gives similar results but takes much longer.
	Variable resultX = integrate1D(xFunc,0,intLim,1,-1)
	Variable resultY = integrate1D(yFunc,0,intLim,1,-1)
	Variable resultZ = integrate1D(zFunc,0,intLim,1,-1)

	KillVariables tEffVol_temp;

	//print/D resultX*resultY*resultZ
	return 8*resultX*resultY*resultZ
End
	
//!
//! @brief These are helper functions for the getEffVol function
Function xFunc(x)
	Variable x
	
	NVAR freqX = :Experimental_Info:freqX;
	NVAR freqXLat = :Experimental_Info:freqXLat;
	NVAR mass = :Experimental_Info:mass;
	NVAR k = :Experimental_Info:k;
	NVAR T = tEffVol_temp;
	
	//set units to microns
	return exp(-4*pi^2*mass*((freqXLat/(k*(1e-6)))^2*cos(k*x*(1e-6))^2+freqX^2*x^2)/(2*kB*T*(1e12)));
End

//!
//! @brief These are helper functions for the getEffVol function
Function yFunc(y)
	Variable y
	
	NVAR freqY = :Experimental_Info:freqY;
	NVAR freqYLat = :Experimental_Info:freqYLat;
	NVAR mass = :Experimental_Info:mass;
	NVAR k = :Experimental_Info:k;
	NVAR T = tEffVol_temp;
	
	//set units to microns
	return exp(-4*pi^2*mass*((freqYLat/(k*(1e-6)))^2*cos(k*y*(1e-6))^2+freqY^2*y^2)/(2*kB*T*(1e12)));
End

//!
//! @brief These are helper functions for the getEffVol function
Function zFunc(z)
	Variable z
	
	NVAR freqZ = :Experimental_Info:freqZ;
	NVAR freqZLat = :Experimental_Info:freqZLat;
	NVAR mass = :Experimental_Info:mass;
	NVAR k = :Experimental_Info:k;
	NVAR T = tEffVol_temp;
	
	//set units to microns
	return exp(-4*pi^2*mass*((freqZLat/(k*(1e-6)))^2*cos(k*z*(1e-6))^2+freqZ^2*z^2)/(2*kB*T*(1e12)));
End

//!
//! @brief This function numerically integrates a 2D lattice potential to find the reference volume for our Sr88 3Body measurements
Function getEffVol_insitu(Tx,Tz,xw_0)
	
	//Tx,Tz are temperature in nK
	Variable Tx,Tz
	//Measured in-situ axial size in microns
	Variable xw_0
	
	//define and get globals to do the integration
	NVAR freqX = :Experimental_Info:freqX;
	NVAR freqY = :Experimental_Info:freqY;
	NVAR freqZ = :Experimental_Info:freqZ;
	NVAR freqXLat = :Experimental_Info:freqXLat;
	NVAR freqYLat = :Experimental_Info:freqYLat;
	NVAR freqZLat = :Experimental_Info:freqZLat;
	NVAR mass = :Experimental_Info:mass;
	NVAR k = :Experimental_Info:k;
	
	//this is dangerous because it could overwrite another global
	Variable/G tEffVol_temp = Tx*(1e-9);
	Variable/G xwEffVol_temp = xw_0;
	
	//set limits of integration, we could do this based on T
	//but this works for now
	Variable intLim = 2000;     //distance in microns
	//decrease intLim for small temperature
	if(T<=200)
		intLim = 250;
	endif
	
	if(intLim<=(2*xw_0))
		intLim+=(2*xw_0);
	endif
	
	//romberg integration since trapezoidal seems to fail for low temperatures
	//gaussian quadrature gives similar results but takes much longer.
	Variable resultX = integrate1D(xFunc_insitu,0,intLim,1,-1)
	tEffVol_temp = 2700*(1e-9);
	Variable resultY = integrate1D(yFunc,0,intLim,1,-1)
	tEffVol_temp = Tz*(1e-9);
	Variable resultZ = integrate1D(zFunc,0,intLim,1,-1)

	KillVariables tEffVol_temp, xwEffVol_temp ;

	//print/D resultX*resultY*resultZ
	return 8*resultX*resultY*resultZ
End

//!
//! @brief These are helper functions for the getEffVol_insitu function
Function xFunc_insitu(x)
	Variable x
	
	NVAR freqX = :Experimental_Info:freqX;
	NVAR freqXLat = :Experimental_Info:freqXLat;
	NVAR mass = :Experimental_Info:mass;
	NVAR k = :Experimental_Info:k;
	NVAR T = tEffVol_temp;
	NVAR xw_0 = xwEffVol_temp;
	
	//set units to microns
	return exp(-4*pi^2*mass*((freqXLat/(k*(1e-6)))^2*cos(k*x*(1e-6))^2)/(2*kB*T*(1e12))-x^2/(xw_0^2));
End

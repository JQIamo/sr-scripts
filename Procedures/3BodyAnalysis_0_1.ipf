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


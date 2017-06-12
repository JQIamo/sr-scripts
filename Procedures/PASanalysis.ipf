#pragma rtGlobals=1		// Use modern global access method.

function setupPASanalysis()
	//make directory to hold analysis results
	NewDataFolder /O root:PAS
	SetDataFolder root:PAS
	KillWaves /A/Z ; KillVariables /A/Z ; KillStrings /A/Z
	
	
	//build list of data series
	String /G dataSeriesList = "";
	
	//*******Put in names of data series that contain the data we want to analyze
	dataSeriesList = AddListItem("root:PAS_23MHz_10uW",dataSeriesList,";")
	dataSeriesList = AddListItem("root:PAS_23MHz_20uW",dataSeriesList,";",999)
	dataSeriesList = AddListItem("root:PAS_23MHz_40uW",dataSeriesList,";",999)
	dataSeriesList = AddListItem("root:PAS_23MHz_60uW",dataSeriesList,";",999)
	dataSeriesList = AddListItem("root:PAS_23MHz_80uW",dataSeriesList,";",999)
	
	Variable numDataSeries = ItemsInList(dataSeriesList)
	
	//*******Insert measured optical powers for each data series, following the order above
	Make /O measuredPow = {9.4,21,41,60,79} //units are uW
	
	//*******Insert the amount of time the PAS laser was applied for each data series, following the order above
	Make /O pasT = {100,100,25,15,12} //units are ms
	
	//*******Insert the correction needed to detuning to account for how far the PAS laser drifted from resonance for each data series, following the order above
	Make /O detuningCorrection = {0,0,0,0,0} //detuning correction in kHz
	
	//check that we got the right number of entries in each wave
	if ((numpnts(measuredPow) != numDataSeries) || (numpnts(pasT) != numDataSeries) || (numpnts(detuningCorrection) != numDataSeries))
		print("The number of data series doesn't match the number of entries in initialization waves")
		return -1;
	endif
	
	
	//Make waves that hold parameters that may be different for each data series
	Make /O/N=(numDataSeries) omgZ
	Make /O/N=(numDataSeries) omgX
	Make /O/N=(numDataSeries) omgY
	Make /O/N=(numDataSeries) actIntensity
	Make /O/N=(numDataSeries) deltaIntensity 
	Make /O/N=(numDataSeries) lopt
	Make /O/N=(numDataSeries) eta
	Make /O/N=(numDataSeries) deltaEta
	Make /O/N=(numDataSeries) deltaLopt

	
	//Make variables for common parameters
	Variable /G mass = 84 * 1.67377e-27; //kg
	Variable /G gammaMol = 2*pi*2*7.44e3; //2*pi*Hz (uncertainty?) (??????????? factor of 2Pi ??????????)
	Variable /G a_scatt = 123 * 5.29177e-11; //m (uncertainty?)
	Variable /G beamWaist = 0.135 //cm
	Variable /G fractionTransmitted = 0.875 // (uncertainty?)
	
	//loop over data series to populate certain data
	variable i;
	String path = ""
	for(i=0;i<numDataSeries; i +=1)	
		path = StringFromList(i,dataSeriesList);
		
		//grab vertical trap frequency
		NVAR omg = $(path + ":Experimental_Info:omgZ")
		omgZ[i] = omg
		
		//grab the x trap frequency
		NVAR omg = $(path + ":Experimental_Info:omgX")
		omgX[i] = omg
		
		//grab the y trap frequency
		NVAR omg = $(path + ":Experimental_Info:omgY")
		omgY[i] = omg	
	endfor												
	
	//calculate actual intensity:
	actIntensity = 2*fractionTransmitted*measuredPow/ (pi*beamWaist^2) //units uW/cm^2
	
	//calculate uncertainty in the intensity:
	//assumptions: uncertainty in intensity measurement: 3% (per Thorlabs spec)
	//uncertainty in fraction transmitted: 4% (estimate, there is about an 8% difference in loss before and after the chamber, so I split the difference)
	//uncertainty in beam waist: 4% this dominates at larger intensities
	deltaIntensity = (2/pi)*sqrt( (fractionTransmitted*0.03*measuredPow/beamWaist)^2 + (measuredPow*.04/beamWaist)^2 + (2*measuredPow*fractionTransmitted/beamWaist^3)^2*(0.04*beamWaist)^2 )
	
	//to do:
	//calc omega_bar
	//add detuning correction
	
	//Group each data series by SSDetuning and average absnum, numBEC, numTF
	
	//make fit function
	
	//fit each data serie
	
	//extract lopt, eta
	
	//more complicated:
	
	//calculate thermal fraction?
	//make fit function that includes one body loss
	//calculate error bars
	
end

function avgPASdata()
	Variable plot
	
	SetDataFolder root:PAS
		
	SVAR dataSeriesList = dataSeriesList;
	Variable numDataSeries = ItemsInList(dataSeriesList)
	
	Variable i;
	String path;
	for (i=0 ; i<numDataSeries; i+=1)
		path = StringFromList(i,dataSeriesList) + ":IndexedWaves:";
		
		//absnum:
		DataSorter($(path + "absnum"),$(path + "SSDetuning"),"absnum_" + num2str(i),"detuning_" + num2str(i)); //other option: put the the waves in different folders
		//numBEC:
		DataSorter($(path + "num_BEC"),$(path + "SSDetuning"),"num_BEC_" + num2str(i),"detuning_" + num2str(i)); 
		//numTF:
		DataSorter($(path + "num_TF"),$(path + "SSDetuning"),"num_TF_" + num2str(i),"detuning_" + num2str(i)); 
		//other variables?? TF radii - will need if we take stimulated broadening into account
			
	endfor

end

function fitPASLorenztian()
	SetDataFolder root:PAS
	
	SVAR dataSeriesList = dataSeriesList;
	Variable numDataSeries = ItemsInList(dataSeriesList)
	
	Variable i;
	//Make /O/N=4 fitCoef
	
	for (i=0 ; i<numDataSeries; i+=1)
		Wave numWv = $("absnum_" + num2str(i) + "_Avg");
		Wave detWv = $("detuning_" + num2str(i) + "_Vals");
		Wave StdDevWv = $("absnum_" + num2str(i) + "_SD");
		CurveFit/NTHR=0/N=1/Q=1 lor numWv /X=detWv /D /I=1/W=StdDevWv
		
		//Extract values
		//Wave W_coef = :W_coef
		// W_coef[2] //center
		//2*sqrt(W_coef[3]) //FWHM 

			
	endfor
end

function PASdataPlot(dataToPlot,index)
	String dataToPlot; //right now options are absnum, num_BEC, num_TF
	Variable index;	//index of data series to plot, maybe add error checking

	//String yWv = dataToPlot + "_" + num2str(index) +"_Avg"
	Wave waveToPlot = $(dataToPlot + "_" + num2str(index) +"_Avg")
	Wave detWave = $("detuning_" + num2str(index) + "_Vals")
	Wave stdDevWave = $(dataToPlot + "_" + num2str(index) + "_SD");
	
	Display waveToPlot vs detWave
	ModifyGraph mode=3,marker=19
	ErrorBars $(dataToPlot + "_" + num2str(index) +"_Avg"), Y wave=(stdDevWave,stdDevWave)

end

function fitPASLoss(dataToFit,index)
	String dataToFit  //right now options are absnum, num_BEC, num_TF
	Variable index //index of data series to fit
	SetDataFolder root:PAS
	
	Wave numWv = $(dataToFit + "_" + num2str(index) + "_Avg")
	Wave detWv = $("detuning_" + num2str(index) + "_Vals")
	Wave StdDevWv = $(dataToFit + "_" + num2str(index) + "_SD");
	
	//Make wave to hold fit coefficients:
	Make /O/N=(4) fit_coef;
	
	//Fit lorenztian to get guesses
	CurveFit/NTHR=0/N=1/Q=1 lor kwCWave=fit_coef numWv /X=detWv /D /I=1/W=StdDevWv
	
	//manipulate fit_coef to be the appropriate guesses for the becPASloss function:
	Redimension/N=5 fit_coef
	fit_coef[1] = sqrt(-fit_coef[1]);
	fit_coef[2] = fit_coef[2]/(2*pi);
	fit_coef[3] = 2*sqrt(fit_coef[3])*2*pi
	fit_coef[4] = 0; //hold to zero if we can ignore loss from atomic resonance
	
	//populate coefficient wave
	//w[0] = N0 1.8e5 -> close to y0 from Lor
	//w[1] = B 4.6e7 -> close to sqrt(A) from Lor
	//w[2] = x0 //23.033e6 -> close to x0 from Lor
	//w[3] = gamma 20e3 -> close to 2*sqrt(B) from Lor
	//w[4] = C //hold to 0
	
	FuncFit/NTHR=0/N=1/Q=1/H="00001" becPASloss fit_coef numWv /X=detWv /W=StdDevWv /I=1 /D
	
	//uncertainties are stored in W_sigma
	
	//extract physical values:
	NVAR gammaMol = :gammaMol
	
	Variable eta = fit_coef[3]/gammaMol;
	print eta
	
	NVAR mass = :mass;
	Wave pasT = :pasT
	Wave omgZ = :omgZ
	Wave omgX = :omgX
	Wave omgY = :omgY
	NVAR a_scatt = :a_scatt;
	
	Variable omegaBar = (omgZ[index]*omgX[index]*omgY[index])^(1/3);
	Variable time_pas = pasT[index]*1e-3 //convert ms to s
	Variable mu = mass/2; //reduced mass
	Variable C2 = (15^(2/5) / (14*pi) ) * (mass*omegaBar/(hbar*sqrt(a_scatt)))^(6/5);	
	
	Variable lopt = fit_coef[1]*(5/2)*mu/ (time_pas*fit_coef[0]^(2/5)*C2*2*pi*hbar*eta*gammaMol^2)
	
	lopt = lopt/5.29177e-11 ; //give optical length in units of bohr radius
		
	//populate results in waves:
	Wave loptWv = :lopt
	loptWv[index] = lopt;
	Wave etaWv = :eta;
	etaWv[index] = eta;
	
	
end

function becPASloss(w,x) : FitFunc
	Wave w;
	Variable x
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = N0*(1 + B/((x-x0)^2 + gamma^2/4)) + C)^(-5/2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 5
	//CurveFitDialog/ w[0] = N0
	//CurveFitDialog/ w[1] = B
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = gamma
	//CurveFitDialog/ w[4] = C
	x=2*Pi*x;
	w[2] = 2*Pi*w[2]//these lines break the function, I have no idea why
	
	return w[0]*(1 + w[1]/( (x-w[2])^2 + (1/4)*w[3]^2 ) + w[4])^(-5/2)

end

function analyzePAS()
	SetDataFolder root:PAS
	
	//choose one:
	//String num = "absnum"
	//String num = "num_BEC"
	String num = "num_TF"
	
	SVAR dataSeriesList = dataSeriesList;
	Variable numDataSeries = ItemsInList(dataSeriesList)
	
	Variable i;
	//Make /O/N=4 fitCoef
	
	for (i=0 ; i<numDataSeries; i+=1)
		
		//PASdataPlot(num,i);
		fitPASloss(num,i)
			
	endfor
	
	
end
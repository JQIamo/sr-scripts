#pragma rtGlobals=1		// Use modern global access method.

function setupPASanalysis()
	//make directory to hold analysis results
	NewDataFolder /O root:PAS
	SetDataFolder root:PAS
	KillWaves /A/Z ; KillVariables /A/Z ; KillStrings /A/Z
	
	Variable dataset = 3
	// 1: 23 MHz data, regular trap, from 6/1 and 6/5
	// 2: 228 MHz data, regular trap, taken 6/6 and 6/7
	// 3: 23 MHz data, dithered trap, taken 6/14 and 6/15
	
	//build list of data series
	String /G dataSeriesList = "";
	Variable numDataSeries
	
	switch(dataset)
		case 3:
			//Settings for 23 MHz data, dithered trap taken 6/14 and 6/15 2017	
			//*******Put in names of data series that contain the data we want to analyze
			dataSeriesList = AddListItem("root:PAS_23MHz_10uW",dataSeriesList,";")
			dataSeriesList = AddListItem("root:PAS_23MHz_20uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_23MHz_30uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_23MHz_40uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_23MHz_50uW",dataSeriesList,";",999)
			
			numDataSeries = ItemsInList(dataSeriesList)
			
			//*******Insert measured optical powers for each data series, following the order above
			Make /O measuredPow = {11.1,19.9,30.4,40,50.6} //units are uW
			
			//*******Insert the amount of time the PAS laser was applied for each data series, following the order above
			Make /O pasT = {75,50,35,25,20} //units are ms
			Variable /G fracPasT = 2/5; //(fraction of total hold time that the PAS laser was on (1 for regular trap, 2/5 for dithered trap)
			Make /O trapLifetime = {6.3,6.4,6.4,6.4,6.4} //units are s, measured one body trap lifetime
			//Future: Make /O deltaTrapLifetime = {0.8,0.3,0.3,0.3,0.3} //units are in s, std dev of fitted lifetime
			
			//*******Insert the correction needed to detuning to account for how far the PAS laser drifted from resonance for each data series, following the order above
			Make /O detuningCorrection = {-3.1,3.75,6.25,22.5,30.05} //detuning correction in kHz
			break;
		case 2:
			//Settings for 228 MHz data taken 6/6 and 6/7 2017
			//*******Put in names of data series that contain the data we want to analyze
			dataSeriesList = AddListItem("root:PAS_228MHz_10uW",dataSeriesList,";")
			dataSeriesList = AddListItem("root:PAS_228MHz_100uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_228MHz_200uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_228MHz_600uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_228MHz_1000uW",dataSeriesList,";",999)
			
			numDataSeries = ItemsInList(dataSeriesList)
			
			//*******Insert measured optical powers for each data series, following the order above
			Make /O measuredPow = {11.65,100.1,199,593,993} //units are uW
			
			//*******Insert the amount of time the PAS laser was applied for each data series, following the order above
			Make /O pasT = {200,15,10,4,4} //units are ms
			Variable /G fracPasT = 1; //(raction of total hold time that the PAS laser was on (1 for regular trap, 2/5 for dithered trap)
			Make /O trapLifetime = {20,20,20,20,20} //units are s, measured one body trap lifetime, placeholder
			
			//*******Insert the correction needed to detuning to account for how far the PAS laser drifted from resonance for each data series, following the order above
			Make /O detuningCorrection = {23.2,12,18.75,14.9,3.7} //detuning correction in kHz
			break;
		case 1:
			//Settings for 23 MHz data taken 6/1 and 6/5 2017	
			//*******Put in names of data series that contain the data we want to analyze
			dataSeriesList = AddListItem("root:PAS_23MHz_10uW",dataSeriesList,";")
			dataSeriesList = AddListItem("root:PAS_23MHz_20uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_23MHz_40uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_23MHz_60uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_23MHz_80uW",dataSeriesList,";",999)
			
			numDataSeries = ItemsInList(dataSeriesList)
			
			//*******Insert measured optical powers for each data series, following the order above
			Make /O measuredPow = {9.4,21,41,60,79} //units are uW
			
			//*******Insert the amount of time the PAS laser was applied for each data series, following the order above
			Make /O pasT = {100,100,25,15,12} //units are ms
			Variable /G fracPasT = 1; //(fraction of total hold time that the PAS laser was on (1 for regular trap, 2/5 for dithered trap)
			Make /O trapLifetime = {20,20,20,20,20} //units are s, measured one body trap lifetime, placeholder
			
			//*******Insert the correction needed to detuning to account for how far the PAS laser drifted from resonance for each data series, following the order above
			Make /O detuningCorrection = {0,0,0,0,0} //detuning correction in kHz
			break;
		default:
			print "Error: data series details not entered"
			break;
		endswitch
	
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
	Make /O/N=(numDataSeries) fitted_center
	Make /O/N=(numDataSeries) corrected_center
	Make /O/N=(numDataSeries) deltaCenter

	
	//Make variables for common parameters
	Variable /G mass = 84 * 1.67377e-27; //kg
	Variable /G gammaMol = 2*7.44e3; //Hz Note: I have divided out the factor of 2 Pi because the fit function expects delta/2Pi as the dependent variable, same result if we add factor of 2Pi here and fit vs scaled detunings
	Variable /G deltaGammaMol = 2*35 //Hz same issue of 2 Pi as above, find a reference for this!
	Variable /G a_scatt = 123 * 5.29177e-11; //m (uncertainty?)
	Variable /G delta_a_scatt = 0 * 5.29177e-11; //m //Look this up!
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
		//add detuning correction
		
	
	//calculate thermal fraction?
	//make fit function that includes one body loss
	//calculate error bars
	
	avgPASdata()
end

function avgPASdata()
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
		
		Duplicate /O $("detuning_" + num2str(i) + "_Vals") $("detuning_" + num2str(i) + "_Scaled")
		Wave detScaledWv = $("detuning_" + num2str(i) + "_Scaled")
		detScaledWv = 2*pi*detScaledWv;
			
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
	//Wave detWave = $("detuning_" + num2str(index) + "_Scaled")
	Wave stdDevWave = $(dataToPlot + "_" + num2str(index) + "_SD");
	
	Display waveToPlot vs detWave
	ModifyGraph mode=3,marker=19
	Label left "Atom Number"
	Label bottom "Detuning (Hz)"
	ErrorBars $(dataToPlot + "_" + num2str(index) +"_Avg"), Y wave=(stdDevWave,stdDevWave)
	

end

function fitPASLoss(dataToFit,index,oneBody)
	String dataToFit  //right now options are absnum, num_BEC, num_TF
	Variable index //index of data series to fit
	Variable oneBody //flag to indicate which fitting method to use: 1=include one body loss, 0=don't include one body loss
	SetDataFolder root:PAS
	
	Wave numWv = $(dataToFit + "_" + num2str(index) + "_Avg")
	Wave detWv = $("detuning_" + num2str(index) + "_Vals")
	//Wave detWv = $("detuning_" + num2str(index) + "_Scaled")
	Wave StdDevWv = $(dataToFit + "_" + num2str(index) + "_SD");
	
	//Make wave to hold fit coefficients:
	Make /O/N=(4) fit_coef;
	
	//Fit lorenztian to get guesses
	CurveFit/NTHR=0/N=1/Q=1 lor kwCWave=fit_coef numWv /X=detWv /D /I=1/W=StdDevWv
	
	//Make constraint wave to force gamma to be positive **commong
	Make/O/T/N=1 T_Constraints
	T_Constraints[0] = {"K3 > 0"}
	
	if (oneBody==1)
	
		Wave trapLifetime = :trapLifetime
		Wave pasT = :pasT
		NVAR pasOnFrac = :fracPasT
		//manipulate fit_coef to be the appropriate guesses for the becPASloss function:
		Redimension/N=8 fit_coef
		fit_coef[1] = sqrt(-fit_coef[1]); //?
		fit_coef[3] = 2*sqrt(fit_coef[3])
		fit_coef[4] = 0; //hold to zero if we can ignore loss from atomic resonance
		fit_coef[5] = trapLifetime[index] //hold tau to the measured onebody trap lifetime
		fit_coef[6] = pasT[index]/(1000*pasOnFrac) // total hold time, divide by 1000 to convert ms to s
		fit_coef[7] = pasOnFrac //fraction of total hold that the PAS laser is on
		
		//Do the fit
		FuncFit/NTHR=0/N=1/Q=1/H="00001111" becPASlossOneBodyFitFunc fit_coef numWv /X=detWv /W=StdDevWv /I=1 /D /C=T_Constraints 
	else
		//manipulate fit_coef to be the appropriate guesses for the becPASloss function:
		Redimension/N=5 fit_coef
		fit_coef[1] = sqrt(-fit_coef[1]);
		//fit_coef[1] = -fit_coef[1]*1e-5;
		//fit_coef[2] = fit_coef[2]/(2*pi);
		fit_coef[3] = 2*sqrt(fit_coef[3])
		fit_coef[4] = 0; //hold to zero if we can ignore loss from atomic resonance
		
		//Do the fit
		FuncFit/NTHR=0/N=1/Q=1/H="00001" becPASloss fit_coef numWv /X=detWv /W=StdDevWv /I=1 /D /C=T_Constraints 
	endif

	
	
	//uncertainties are stored in W_sigma
	Wave W_sigma = :W_sigma;
	Variable delta_fitted_Gamma = W_sigma[3];
	Variable delta_center = W_sigma[2];
	Variable delta_B = W_sigma[1];
	
	//extract physical values:
	NVAR gammaMol = :gammaMol
	NVAR deltaGammaMol = :deltaGammaMol
	Variable eta = fit_coef[3]/gammaMol;
	Variable delta_eta = sqrt((delta_fitted_Gamma/gammaMol)^2 + (fit_coef[3]*deltaGammaMol/GammaMol^2)^2);
	
	NVAR mass = :mass;
	Wave pasT = :pasT
	Wave omgZ = :omgZ
	Wave omgX = :omgX
	Wave omgY = :omgY
	NVAR a_scatt = :a_scatt;
	
	Variable omegaBar = (omgZ[index]*omgX[index]*omgY[index])^(1/3);
	Variable time_pas = pasT[index]*1e-3 //convert ms to s
	Variable mu = mass/2; //reduced mass
	Variable a0 = 5.29177e-11; //bohr radius, m
	Variable C2 = (15^(2/5) / (14*pi) ) * (mass*omegaBar/(hbar*sqrt(a_scatt)))^(6/5);	
	Variable lopt
	
	if (oneBody==1)
		lopt = mu*fit_coef[1]/(2*pi*hbar*eta*gammaMol^2*C2);
	else
		lopt = fit_coef[1]*(5/2)*mu/ (time_pas*fit_coef[0]^(2/5)*C2*2*pi*hbar*eta*gammaMol^2)	;
	endif
		
	lopt = lopt/a0 ; //give optical length in units of bohr radius
	
	//Calculate uncertainty in lopt - this is going to be messy!
	//First calculate uncertainty in omegaBar, assume 10 Hz (10% in z) and 2.5 Hz (5%) in x, y, this is probably too big?
	Variable deltaFx = 2.5;
	Variable deltaFy = deltaFx;	
	Variable deltaFz = 10;
	Variable deltaOmegaBar = (1/3)*sqrt( (omgX[index]*omgY[index]/omgZ[index]^2)^(2/3)*deltaFz + (omgZ[index]*omgY[index]/omgX[index]^2)^(2/3)*deltaFx + (omgX[index]*omgZ[index]/omgY[index]^2)^(2/3)*deltaFy)
	
	//Now calculate deltaC2:
	NVAR delta_a_scatt = :delta_a_scatt
	Variable deltaC2 = (15^(2/5) / (14*pi) ) * (3/5) *(mass/hbar)^(6/5) * sqrt( (2/(a_scatt^(3/5)*omegaBar^(1/5)))^2*deltaOmegaBar^2 + (omegaBar^(6/5)/a_scatt^(8/5))^2*delta_a_scatt)
	
	//Finally, calculate deltaLopt
	Variable deltaBterm 
	Variable deltaN0term 
	Variable deltaC2term 
	Variable deltaEtaterm 
	Variable deltaGammaMolterm
	Variable deltaLopt
	
	if (oneBody==1)
		deltaBterm = (W_sigma[1]/(eta*gammaMol^2*C2))^2;
		deltaC2term = (fit_coef[1]*deltaC2/(eta*gammaMol^2*C2^2))^2;
		deltaEtaterm = (fit_coef[1]*delta_Eta/(eta^2*gammaMol^2*C2))^2;
		deltaGammaMolterm = (2*fit_coef[1]*deltaGammaMol^2/(eta*gammaMol^3*C2))^2;
		deltaLopt = (mu / (2*pi*hbar))*sqrt(deltaBterm + deltaC2term + deltaEtaterm + deltaGammaMolterm);
	else
		deltaBterm = (fit_coef[0]^(2/5)*C2*eta*gammaMol^2)^(-2)*W_sigma[1]^2;
		deltaN0term = ((2/5)*fit_coef[1]/(C2*eta*gammaMol^2*fit_coef[0]^(7/5)))^2 * W_sigma[0]^2;
		deltaC2term = (fit_coef[1]/(fit_coef[0]^(2/5)*eta*gammaMol^2*C2^2))^2*deltaC2^2;
		deltaEtaterm = (fit_coef[1]/(fit_coef[0]^(2/5)*C2*gammaMol^2*eta^2))^2*delta_Eta^2;
		deltaGammaMolterm = (2*fit_coef[1]/(fit_coef[0]^(2/5)*C2*eta*gammaMol^3))^2*deltaGammaMol^2;
		deltaLopt = ((5/2)*mu / (time_pas*2*pi*hbar)) * sqrt( deltaBterm + deltaN0term + deltaC2term + deltaEtaterm + deltaGammaMolterm )
	endif
			
	//print deltaBterm
	//print deltaN0term
	//print deltaC2term
	//print deltaEtaterm
	//print deltaGammaMolterm
	
	
	//print deltaLopt
	deltaLopt = deltaLopt/a0 ; //in units of bohr radius
	
		
	//populate results in waves:
	Wave loptWv = :lopt
	loptWv[index] = lopt;
	Wave etaWv = :eta;
	etaWv[index] = eta;
	Wave deltaEtaWv = :deltaEta
	deltaEtaWv[index] = delta_eta
	Wave deltaLoptWv = :deltaLopt
	deltaLoptWv[index] = deltaLopt
	
	
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
	//x=2*Pi*x;
	//w[2] = 2*Pi*w[2]//these lines break the function, I have no idea why
	
	return w[0]*(1 + w[1]/( (x-w[2])^2 + (1/4)*w[3]^2 ) + w[4])^(-5/2)

end

function analyzePAS(plot,oneBody)
	Variable plot; //flag to indicate if we should generate new plots (1=plot, 0 = don't plot)
	Variable oneBody; //flag to indicate whether to include one body loss: 1=include one body, 0 = ignore one body
	SetDataFolder root:PAS
	
	//choose one:
	String num = "absnum"
	//String num = "num_BEC"
	//String num = "num_TF"
	
	SVAR dataSeriesList = dataSeriesList;
	Variable numDataSeries = ItemsInList(dataSeriesList)
	
	Variable i;
	//Make /O/N=4 fitCoef
	
	for (i=0 ; i<numDataSeries; i+=1)
		
		if (plot==1)
			PASdataPlot(num,i);
		endif
		fitPASloss(num,i,oneBody)
			
	endfor
	
	if (plot==1)
		//plot optical lengths:
		Display lopt vs actIntensity
		ModifyGraph mode=3,marker=19
		ErrorBars lopt XY,wave=(deltaIntensity,deltaIntensity),wave=(deltaLopt,deltaLopt)
		Label left "l\\Bopt\\M/a\\B0"
		Label bottom "Intensity (uW/cm\\S2\\M)"
		
	endif
	
	//Extract lopt/I, or the slope of the above plot
	Make /O/N=(2) lopt_fit_coef
	K0=0;
	CurveFit/NTHR=0/N=1/Q=1/H="10" line kwCWave=lopt_fit_coef lopt /X=actIntensity /D // /I=1/W=StdDevWv
	Variable slope = K1*1e6; //units: (lopt/a0) / (W/cm^2)
	Wave W_sigma = :W_sigma
	Variable slope_sigma = W_sigma[1]*1e6;//units: (lopt/a0) / (W/cm^2)
	string result = "lopt/a0 = " + num2str(slope) + " ± " + num2str(slope_sigma) + "(W/cm^2)^-1"
	
	if (plot ==1)
		TextBox/C/N=text0/A=MC result
		TextBox/C/N=text0/A=LC/X=36.56/Y=31.88
		
		//Display eta:
		Display eta vs actIntensity
		ModifyGraph mode=3,marker=19
		ErrorBars eta XY,wave=(deltaIntensity,deltaIntensity),wave=(deltaEta,deltaEta)
		Label left "eta"
		Label bottom "Intensity (uW/cm\\S2\\M)"
	else
		print result
	endif
	
end

function plotNums()
	
	SetDataFolder root:PAS
	
	SVAR dataSeriesList = dataSeriesList;
	Variable numDataSeries = ItemsInList(dataSeriesList)
	
	
	Variable i;
	for (i=0 ; i<numDataSeries; i+=1)
	
		Wave absnum = $("absnum_" + num2str(i) +"_Avg")
		Wave absnum_SD = $("absnum_" + num2str(i) +"_SD")
		Wave num_BEC = $("num_BEC_" +num2str(i) + "_Avg")
		Wave num_BEC_SD = $("num_BEC_" +num2str(i) + "_SD")
		Wave num_TF= $("num_TF_" + num2str(i) +"_Avg")
		Wave num_TF_SD = $("absnum_" + num2str(i) +"_SD")
		Wave detWv = $("detuning_" + num2str(i) + "_Vals")
	
		//Make plot of absnum, num_BEC, and num_TF on same graph for each data series
		Display absnum, num_BEC, num_TF vs detWv; 
		ModifyGraph mode=3,marker( $("absnum_" + num2str(i) +"_Avg"))=19,marker($("num_BEC_" +num2str(i) + "_Avg"))=16; 
		ModifyGraph rgb($("num_BEC_" +num2str(i) + "_Avg"))=(0,12800,52224),marker($("num_TF_" + num2str(i) +"_Avg"))=17;
		ModifyGraph rgb($("num_TF_" + num2str(i) +"_Avg"))=(0,26112,13056)
		
		ErrorBars $("absnum_" + num2str(i) +"_Avg") Y,wave=($("absnum_" + num2str(i) +"_SD"),$("absnum_" + num2str(i) +"_SD"));
		ErrorBars $("num_BEC_" +num2str(i) + "_Avg") Y,wave=($("num_BEC_" +num2str(i) + "_SD"),$("num_BEC_" +num2str(i) + "_SD"));
		ErrorBars $("num_TF_" + num2str(i) +"_Avg") Y,wave=($("num_TF_" + num2str(i) +"_SD"),$("num_TF_" + num2str(i) +"_SD"));
		
		Wave measuredPow = :measuredPow
		String powerLabel = "power = " + num2str(measuredPow[i]) + " uW"
		TextBox/C/N=text0/A=MC powerLabel
		TextBox/C/N=text0/A=LC/X=36.56/Y=31.88
		
		Label left "Atom Number"
		Label bottom "Detuning (Hz)"
			
		//Calculate thermal fraction (assumed to be (absnum-num_BEC)/absnum
		duplicate absnum $("thermal_frac_" + num2str(i))
		Wave thermal_frac = $("thermal_frac_" + num2str(i));
		thermal_frac = (absnum-num_BEC)/absnum
						
	endfor
	
	//plot thermal fractions on same plot:
	
	Display thermal_frac_0 vs detuning_0_Vals;
	
	for (i=1 ; i<numDataSeries; i+=1)
		AppendToGraph $("thermal_frac_" + num2str(i)) vs $("detuning_" + num2str(I) + "_Vals")
	endfor	
	Legend/C/N=text0/A=LC
	Label left "Thermal Fraction"
	Label bottom "Detuning (Hz)"

end

function checkForOutliers()
	SetDataFolder root:PAS
		
	SVAR dataSeriesList = dataSeriesList;
	Variable numDataSeries = ItemsInList(dataSeriesList)
	
	Variable i;
	String path;
	for (i=0 ; i<numDataSeries; i+=1)
		path = StringFromList(i,dataSeriesList) + ":IndexedWaves:";
		
		Wave absnum = $(path + "absnum")
		Wave num_BEC = $(path + "num_BEC")
		Wave num_TF= $(path + "num_TF")
		Wave detWv = $(path + "SSDetuning")
		
		//Make plot of absnum, num_BEC, and num_TF on same graph for each data series
		Display absnum, num_BEC, num_TF vs detWv; 
		ModifyGraph mode=3,marker($("absnum"))=19,marker($("num_BEC"))=16; 
		ModifyGraph rgb($("num_BEC"))=(0,12800,52224),marker( $("num_TF"))=17;
		ModifyGraph rgb( $("num_TF"))=(0,26112,13056)
		
		Label left "Atom Number"
		Label bottom "Detuning (Hz)"
		//Legend/C/N=text0/A=LC
		//Legend/C/N=text0/A=LC/X=36.56/Y=31.88
		
		String dataSeriesLabel = StringFromList(i,dataSeriesList)
		TextBox/C/N=text0/A=MC dataSeriesLabel
		TextBox/C/N=text0/A=LC/X=36.56/Y=31.88
					
	endfor
	
end

Function PASlossOneBodyDiffEq(pw,tt,Nw,dNdt)
	//This function defines the differential equation that governs atom number loss in the presence of two-body and one body loss
	//dN/dt = -k*N^(7/5)*pasOnFrac -N/tau
	
	Wave pw //parameter wave (input) pw[0] = k, pw[1] = tau, pw[2] = pasOnFrac
	Variable tt //time
	wave Nw //number wave Nw[0] is N(t)
	wave dNdt //derivative wave dNdt[0] = dN/dT
	
//	Variable t_us = tt*1e6;
//	Variable pasDitherDutyTime = 250;
//	Variable pasDitherDelay = 50;
//	Variable pasOn;
	
	//This is the "right" way to account for dither, but from my tests you get the same results by scaling the PAS term by the ratio of time it's on
//	If (mod(t_us,2*pasDitherDutyTime) > (pasDitherDutyTime+pasDitherDelay))
//		pasOn=1;
//	else 
//		pasOn=0;
//	endif
//	
//	dNdt = -pw[0]*Nw[0]^(7/5)*pasOn - Nw[0]/pw[1];
	dNdt = -pw[0]*Nw[0]^(7/5)*pw[2] - Nw[0]/pw[1]; //factor of 2/5 accounts for the fact that the PAS laser is on for 200 out of every 500 us of hold time
	
	return 0
end

Function PASlossOneBody(k,tau,N0,t,pasOnFrac)
	Variable k //loss parameter
	Variable tau //one body loss rate (sec)
	Variable N0 //Initial atom number
	Variable t //time to evaluate
	Variable pasOnFrac //Fraction of total hold time that the photoassociation laser is on for
	//Variable npts //number of points to integrate
	
	Make /D/O/Free parWave = {k,tau,pasOnFrac} //parameter wave to pass to diff equation
	Make /D/O/N=(2) NN //for now only evaluate two points (initial and final), if we add dithering function, use enough points to get a step size of 1ms or smaller
	SetScale /I x 0,t,NN; 
	
	NN[0] = N0 //Set initial condition
	IntegrateODE PASlossOneBodyDiffEq, parWave, NN
	
	//Display NN
	//print NN[numpnts(NN)-1]
	return NN[numpnts(NN)-1]
		
End

function becPASlossOneBodyFitFunc(w,x) : FitFunc
	Wave w;
	Variable x
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = solution to N'(t) = -k*N^(7/5)*pasOnFrac - N/tau, where k = Beta/( (x-x0)^2 +gamma^2/4)) + C
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 8
	//CurveFitDialog/ w[0] = N0
	//CurveFitDialog/ w[1] = Beta
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = gamma
	//CurveFitDialog/ w[4] = C (extra loss due to scattering from atomic transition)
	//CurveFitDialog/ w[5] = tau (one body lifetime)
	//CurveFitDialog/ w[6] = t (total hold time)
	//CurveFitDialog/ w[7] = pasOnFrac (fraction of time the photassociation laser is on)
	
	//x=2*Pi*x;
	//w[2] = 2*Pi*w[2]//these lines break the function, I have no idea why
	return PASlossOneBody(w[1]/( (x-w[2])^2 + (1/4)*w[3]^2 )+w[4],w[5],w[0],w[6],w[7])
	
	//return w[0]*(1 + w[1]/( (x-w[2])^2 + (1/4)*w[3]^2 ) + w[4])^(-5/2)

end
	
function testRotation()
	variable shotNum;
	variable ii
	
	Wave optdepth = :optdepth
	Wave rotationAngle = :rotationAngle
	ii = numpnts(rotationAngle)
	for (shotNum = 1511; shotNum < 1609; shotNum +=1)
		redimension /N=(numpnts(rotationAngle)+1) rotationAngle
		BatchRun(-1,shotNum,0,"")
		rotationAngle[ii] = GaussRotate2DFit(optdepth)
		ii += 1; 
	endfor
end
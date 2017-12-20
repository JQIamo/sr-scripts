#pragma rtGlobals=1		// Use modern global access method.

function setupPASanalysis()
	//make directory to hold analysis results
	NewDataFolder /O root:PAS
	SetDataFolder root:PAS
	KillWaves /A/Z ; KillVariables /A/Z ; KillStrings /A/Z
	
	Variable dataset = 7;
	// 1: 23 MHz data, regular trap, from 6/1 and 6/5
	// 2: 228 MHz data, regular trap, taken 6/6 and 6/7
	// 3: 23 MHz data, dithered trap, taken 6/14 and 6/15, and 7/7/17
	// 4: 228 MHz data, dithered trap, taken 6/15, 6/16, 6/19, and 6/20
	// 5: 1143 MHz data, regular trap, taken 6/8
	// 6: 1143 MHz data, dithered trap, taken 6/27/17 (and morning of 6/28), and 7/7/17
	// 7: 3693 MHz data, dithered trap, taken 7/12/17
	
	//build list of data series
	String /G dataSeriesList = "";
	Variable numDataSeries
	
	switch(dataset)
		case 7:
			//Settings for 3963 MHz data taken 7/12 2017
			//*******Put in names of data series that contain the data we want to analyze
			dataSeriesList = AddListItem("root:PAS_3693MHz_1200uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_3693MHz_2400uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_3693MHz_3500uW",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_3693MHz_4600uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_3693MHz_4600uWb",dataSeriesList,";",999) //same as above data set without last scan
			dataSeriesList = AddListItem("root:PAS_3693MHz_5600uW",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_3693MHz_5300uW_0mG",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_3693MHz_5300uW_0mGb",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_3693MHz_5300uW_200mG",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_3693MHz_5300uW_200mGb",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_3693MHz_1100uW_0mG",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_3693MHz_1100uW_0mGb",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_3693MHz_1100uW_200mG",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_3693MHz_1100uW_200mGb",dataSeriesList,";",999)
			
			
			numDataSeries = ItemsInList(dataSeriesList)
			
			//*******Insert measured optical powers for each data series, following the order above
			//Make /O measuredPow = {1210,2355,3520,4560,5600,5300,5300,5300,5300,1112,1112,1112,1112} //units are uW
			Make /O measuredPow = {1210,2355,3520,4560,5600} //units are uW
			
			//*******Insert the amount of time the PAS laser was applied for each data series, following the order above
			//Make /O pasT = {150,100,100,50,40,40,40,40,40,150,150,150,150} //units are ms
			Make /O pasT = {150,100,100,50,40} //units are ms
			Variable /G fracPasT = 2/5; //(raction of total hold time that the PAS laser was on (1 for regular trap, 2/5 for dithered trap)
			Make /O trapLifetime = {9.4,9.4,9.4,9.4,9.4} //units are s, measured one body trap lifetime, placeholder
			
			//*******Insert the correction needed to detuning to account for how far the PAS laser drifted from resonance for each data series, following the order above
			Make /O detuningCorrection = {0.9,-26.2,-4.25,19.8,-2.2} //detuning correction in kHz
			break;
		case 6:
			//Settings for 1143 MHz data taken 6/27 and 6/28 2017
			//*******Put in names of data series that contain the data we want to analyze
			//dataSeriesList = AddListItem("root:PAS_1143MHzDither_1000uWa",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_1143MHzDither_1000uWb",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_1143MHzDither_2000uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_1143MHzDither_3000uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_1143MHzDither_4000uWa",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_1143MHzDither_4000uWb",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_1143MHzDither_5000uW",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_1143MHzDither_5000uWb",dataSeriesList,";",999)
			
			numDataSeries = ItemsInList(dataSeriesList)
			
			//*******Insert measured optical powers for each data series, following the order above
			//Make /O measuredPow = {1040,1030,2090,3060,3980,3980,4940,5030} //units are uW
			Make /O measuredPow = {1030,2090,3060,3980,4940} //units are uW
			
			//*******Insert the amount of time the PAS laser was applied for each data series, following the order above
			//Make /O pasT = {400,400,200,150,100,100,100,100} //units are ms
			Make /O pasT = {400,200,150,100,100} //units are ms
			Variable /G fracPasT = 2/5; //(raction of total hold time that the PAS laser was on (1 for regular trap, 2/5 for dithered trap)
			//Make /O trapLifetime = {2.6,2.6,2.6,2.6,2.6,2.6,2.6,2.6} //units are s, measured one body trap lifetime, placeholder
			Make /O trapLifetime = {2.6,2.6,2.6,2.6,2.6} //units are s, measured one body trap lifetime, placeholder
			
			//*******Insert the correction needed to detuning to account for how far the PAS laser drifted from resonance for each data series, following the order above
			//Make /O detuningCorrection = {-11.05,-10.9,-16.15,-20.1,-16.55,-16.55,-9.6,-20.95} //detuning correction in kHz
			Make /O detuningCorrection = {-10.9,-16.15,-20.1,-16.55,-9.6} //detuning correction in kHz
			
			break;
		case 5:
			//Settings for 1143 MHz data taken 6/8 2017
			//*******Put in names of data series that contain the data we want to analyze
			dataSeriesList = AddListItem("root:PAS_1143MHz_1000uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_1143MHz_2000uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_1143MHz_3000uW",dataSeriesList,";",999)
			
			numDataSeries = ItemsInList(dataSeriesList)
			
			//*******Insert measured optical powers for each data series, following the order above
			Make /O measuredPow = {1000,1990,3000} //units are uW
			
			//*******Insert the amount of time the PAS laser was applied for each data series, following the order above
			Make /O pasT = {350,200,125} //units are ms
			Variable /G fracPasT = 1; //(raction of total hold time that the PAS laser was on (1 for regular trap, 2/5 for dithered trap)
			Make /O trapLifetime = {20,20,20,20,20} //units are s, measured one body trap lifetime, placeholder
			
			//*******Insert the correction needed to detuning to account for how far the PAS laser drifted from resonance for each data series, following the order above
			Make /O detuningCorrection = {-6,-9.2,-10.2} //detuning correction in kHz
			break;
		case 4:
			//Settings for 228 MHz data, dithered trap taken 6/15, 6/16, 6/19, and 6/20 2017	
			//*******Put in names of data series that contain the data we want to analyze
			dataSeriesList = AddListItem("root:PAS_228MHz_10uW",dataSeriesList,";")
			dataSeriesList = AddListItem("root:PAS_228MHz_50uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_228MHz_100uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_228MHz_150uW",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_228MHz_150uWb",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_228MHz_150uWc",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_228MHz_200uW",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_228MHz_250uW",dataSeriesList,";",999)
			
			numDataSeries = ItemsInList(dataSeriesList)
			
			//*******Insert measured optical powers for each data series, following the order above
			//Make /O measuredPow = {10,49.7,101,152,152,152,195,255} //units are uW
			Make /O measuredPow = {10,49.7,101,152,195} //units are uW
			
			//*******Insert the amount of time the PAS laser was applied for each data series, following the order above
			//Make /O pasT = {250,40,20,13,13,13,10,13} //units are ms
			Make /O pasT = {250,40,20,13,10} //units are ms
			Variable /G fracPasT = 2/5; //(fraction of total hold time that the PAS laser was on (1 for regular trap, 2/5 for dithered trap)
			//Make /O trapLifetime = {6.4,2.2,2.2,2.2,2.2,2.2,2.2,4} //units are s, measured one body trap lifetime
			Make /O trapLifetime = {6.4,2.2,2.2,2.2,2.2} //units are s, measured one body trap lifetime
			//Future: Make /O deltaTrapLifetime = {0.8,0.3,0.3,0.3,0.3} //units are in s, std dev of fitted lifetime
			
			//*******Insert the correction needed to detuning to account for how far the PAS laser drifted from resonance for each data series, following the order above
			//Make /O detuningCorrection = {35.05,-6.9,2.75,10,10,9.85,-0.75,3.5} //detuning correction in kHz
			Make /O detuningCorrection = {35.05,-6.9,2.75,10,-0.75} //detuning correction in kHz
			break;
		case 3:
			//Settings for 23 MHz data, dithered trap taken 6/14 and 6/15 2017	
			//*******Put in names of data series that contain the data we want to analyze
			dataSeriesList = AddListItem("root:PAS_23MHz_10uW",dataSeriesList,";")
			dataSeriesList = AddListItem("root:PAS_23MHz_20uW",dataSeriesList,";",999)
			//dataSeriesList = AddListItem("root:PAS_23MHz_30uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_23MHz_30uWb",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_23MHz_40uW",dataSeriesList,";",999)
			dataSeriesList = AddListItem("root:PAS_23MHz_50uW",dataSeriesList,";",999)
			
			numDataSeries = ItemsInList(dataSeriesList)
			
			//*******Insert measured optical powers for each data series, following the order above
			//Make /O measuredPow = {11.1,19.9,30.4,30,40,50.6} //units are uW
			Make /O measuredPow = {11.1,19.9,30,40,50.6} //units are uW
			
			//*******Insert the amount of time the PAS laser was applied for each data series, following the order above
			//Make /O pasT = {75,50,35,40,25,20} //units are ms
			Make /O pasT = {75,50,40,25,20} //units are ms
			Variable /G fracPasT = 2/5; //(fraction of total hold time that the PAS laser was on (1 for regular trap, 2/5 for dithered trap)
			//Make /O trapLifetime = {6.3,6.4,6.4,6.4,6.4,6.4} //units are s, measured one body trap lifetime
			Make /O trapLifetime = {6.3,6.4,6.4,6.4,6.4} //units are s, measured one body trap lifetime
			//Future: Make /O deltaTrapLifetime = {0.8,0.3,0.3,0.3,0.3} //units are in s, std dev of fitted lifetime
			
			//*******Insert the correction needed to detuning to account for how far the PAS laser drifted from resonance for each data series, following the order above
			//Make /O detuningCorrection = {-3.1,3.75,6.25,12.5,22.5,30.05} //detuning correction in kHz
			Make /O detuningCorrection = {-3.1,3.75,12.5,22.5,30.05} //detuning correction in kHz
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
	Variable /G a_scatt = 122.762 * 5.29177e-11; //m  (from Stein, Knockel, Tiemann, 2010)
	Variable /G delta_a_scatt = 0.092* 5.29177e-11; //m (from Stein, Knockel, Tiemann, 2010)
	//Variable /G beamWaist = 0.135 //cm
	Variable /G beamWaist = 0.16287 //cm
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
	actIntensity = 2*fractionTransmitted*measuredPow/ (pi*beamWaist^2) //units µW/cm^2
	
	//calculate uncertainty in the intensity:
	//assumptions: uncertainty in intensity measurement: 3% (per Thorlabs spec)
	//uncertainty in fraction transmitted: 4% (estimate, there is about an 8% difference in loss before and after the chamber, so I split the difference)
	//uncertainty in beam waist: 5%, this dominates at larger intensities
	deltaIntensity = (2/pi)*sqrt( (fractionTransmitted*0.03*measuredPow/beamWaist)^2 + (fractionTransmitted*measuredPow*.04/beamWaist)^2 + (2*measuredPow*fractionTransmitted/beamWaist^3)^2*(0.05*beamWaist)^2 )
	
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
	Wave StdErrWv = $(dataToFit + "_" + num2str(index) + "_SEM");
	
	//Make wave to hold fit coefficients:
	Make /O/N=(4) fit_coef;
	
	//Fit lorenztian to get guesses
	CurveFit/NTHR=0/N=1/Q=1 lor kwCWave=fit_coef numWv /X=detWv /D /I=1/W=StdErrWv //sometime getting rid of weighting gives better guesses for some data sets
	
	//Extract fitted center
	Wave W_sigma = :W_sigma;
	Wave detuningCorrection = :detuningCorrection
	Wave fitted_center = :fitted_center
	Wave corrected_center = :corrected_center
	Wave deltaCenter = :deltaCenter
	
	fitted_center[index] = fit_coef[2]
	corrected_center[index] = fit_coef[2] + detuningCorrection[index]*1e3 //correct the center position, (convert the correction from kHz to Hz)
	deltaCenter[index] = W_sigma[2]
	
	//Make constraint wave to force gamma to be positive
	Make/O/T/N=1 T_Constraints
	T_Constraints[0] = {"K3 > 0"}
	
	if (oneBody==1)
	
		Wave trapLifetime = :trapLifetime
		Wave pasT = :pasT
		NVAR pasOnFrac = :fracPasT
		//manipulate fit_coef to be the appropriate guesses for the becPASloss function:
		Redimension/N=8 fit_coef
		fit_coef[1] = 1*sqrt(-fit_coef[1]); //multiplying by 10 gives better results for 228MHz, dithered data, multiplying by 1 gives better guesses for 1143 dithered data
		fit_coef[3] = 2*sqrt(fit_coef[3])
		fit_coef[4] = 0; //hold to zero if we can ignore loss from atomic resonance
		fit_coef[5] = trapLifetime[index] //hold tau to the measured onebody trap lifetime
		fit_coef[6] = pasT[index]/(1000*pasOnFrac) // total hold time, divide by 1000 to convert ms to s
		fit_coef[7] = pasOnFrac //fraction of total hold that the PAS laser is on
		//Do the fit
		FuncFit/NTHR=0/N=1/Q=1/H="00101111" becPASlossOneBodyFitFunc fit_coef numWv /X=detWv /I=1 /D /C=T_Constraints /W=StdDevWv //W=StdErrWv //acording the the igor manual, std error is the appropriate weighting, gives smaller error bars 
	else
		//manipulate fit_coef to be the appropriate guesses for the becPASloss function:
		Redimension/N=5 fit_coef
		fit_coef[1] = 11*sqrt(-fit_coef[1]); //multiplying by 10 gives better results for 228MHz, dithered data
		//fit_coef[1] = -fit_coef[1]*1e-5;
		//fit_coef[2] = fit_coef[2]/(2*pi);
		fit_coef[3] = 1.4*sqrt(fit_coef[3])
		fit_coef[4] = 0; //hold to zero if we can ignore loss from atomic resonance
		
		//CurveFitDialog/ w[0] = N0
		//CurveFitDialog/ w[1] = B
		//CurveFitDialog/ w[2] = x0
		//CurveFitDialog/ w[3] = gamma
		//CurveFitDialog/ w[4] = C
		
		//Do the fit
		//Variable/G V_FitTol=0.00001
		FuncFit/NTHR=0/N=1/Q=1/H="00101"/M=2 becPASloss fit_coef numWv /X=detWv  /D /C=T_Constraints /I=1 /W=StdDevWv //W=StdErrWv  //acording the the igor manual, std error is the appropriate weighting, gives smaller error bars 
		print fit_coef
	endif

	
	
	//uncertainties are stored in W_sigma
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
	Variable deltaFx  = 0.025*OmgX[index];
	Variable deltaFy 	= 0.025*OmgY[index];
	Variable deltaFz = 0.1*OmgZ[index];
	//Variable deltaOmegaBar = (1/3)*sqrt( (omgX[index]*omgY[index]/omgZ[index]^2)^(2/3)*deltaFz^2 + (omgZ[index]*omgY[index]/omgX[index]^2)^(2/3)*deltaFx^2 + (omgX[index]*omgZ[index]/omgY[index]^2)^(2/3)*deltaFy^2)
	Variable deltaOmegaBar = (1/3)*omegaBar*sqrt( (deltaFz/omgZ[index])^2 + (deltaFx/omgX[index])^2  +(deltaFy/omgY[index])^2)

	
	//Now calculate deltaC2:
	NVAR delta_a_scatt = :delta_a_scatt
	Variable deltaC2 = (15^(2/5) / (14*pi) ) * (3/5) *(mass/hbar)^(6/5) * sqrt( (2*omegaBar^(1/5)/(a_scatt^(3/5)))^2*deltaOmegaBar^2 + (omegaBar^(6/5)/a_scatt^(8/5))^2*delta_a_scatt^2)
	
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
		deltaGammaMolterm = (2*fit_coef[1]*deltaGammaMol/(eta*gammaMol^3*C2))^2;
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
		Label bottom "Intensity (µW/cm\\S2\\M)"
		SetAxis left 0,*;
		SetAxis bottom 0,*
	endif
	
	//Extract lopt/I, or the slope of the above plot
	Make /O/N=(2) lopt_fit_coef
	K0=0;
	//CurveFit/NTHR=0/N=1/Q=1/H="10" line kwCWave=lopt_fit_coef lopt /X=actIntensity /D // /I=1/W=StdDevWv
	CurveFit/NTHR=0/Q=1/H="10"/ODR=2 line kwCWave=lopt_fit_coef lopt /X=actIntensity /D /I=1 /W=deltaLopt /XW=deltaIntensity
	Variable slope = K1*1e6; //units: (lopt/a0) / (W/cm^2)
	Wave W_sigma = :W_sigma
	Variable slope_sigma = W_sigma[1]*1e6;//units: (lopt/a0) / (W/cm^2)
	string result = "lopt/a0 = " + num2str(slope) + " ± " + num2str(slope_sigma) + "(W/cm^2)^-1"
	
	if (plot ==1)
		//Display lopt textbox on the lopt plot
		TextBox/C/N=text0/A=MC result
		TextBox/C/N=text0/A=LC/X=36.56/Y=31.88
		
		//Display eta:
		Display eta vs actIntensity
		ModifyGraph mode=3,marker=19
		ErrorBars eta XY,wave=(deltaIntensity,deltaIntensity),wave=(deltaEta,deltaEta)
		Label left "eta"
		Label bottom "Intensity (µW/cm\\S2\\M)"
		SetAxis left 1.0,*;
		SetAxis bottom 0,*

	endif
	
	//Extract the average eta value:
	Make /O/N=2 eta_fit_coef
	K1=0;
	CurveFit/NTHR=0/N=1/Q=1/H="01" line kwCWave=eta_fit_coef eta /X=actIntensity /D /I=1 /W=deltaEta
	Variable etaAvg = K0;
	Variable etaAvgDelta = W_sigma[0]
	string result2 = "Average eta = " + num2str(etaAvg) + " ± " + num2str(etaAvgDelta)
	
	if (plot ==1)
		//Display eta result textbox on the eta plot
		TextBox/C/N=text0/A=MC result2
		TextBox/C/N=text0/A=LC/X=36.56/Y=31.88
		ModifyGraph lstyle(fit_eta)=7
	endif
	

	
	//Plot the center frequency
	If (plot ==1)
		Display corrected_center vs actIntensity
		ModifyGraph mode=3
		ModifyGraph marker=19;
		ErrorBars corrected_center Y,wave=(deltaCenter,deltaCenter)
		Label left "Center Frequency (Hz)"
		Label bottom "Intensity (µW/cm\\S2\\M)"
	endif
	
	//Extract the average center frequency:
	Make /O/N=2 center_fit_coef
	K1=0;
	CurveFit/NTHR=0/N=1/Q=1/H="01" line kwCWave=center_fit_coef corrected_center /X=actIntensity /D /I=1 /W=deltaCenter
	Variable centerAvg = K0;
	Variable centerAvgDelta = W_sigma[0]
	string centerFormatted
	string centerDeltaFormatted
	sprintf centerFormatted "%.6W1PHz" centerAvg;
	sprintf centerDeltaFormatted "%.0W1PHz" centerAvgDelta;
	string result3 = "Resonance center = " + centerFormatted + " ± " + centerDeltaFormatted
	//string result3 = "Average Detuning = " + num2str(centerAvg) + " ± " + num2str(centerAvgDelta)
	
	if (plot == 1)	
		//Display the result textbox on the detuning center plot
		TextBox/C/N=text0/A=MC result3
		TextBox/C/N=text0/A=LC/X=36.56/Y=31.88
		ModifyGraph lstyle(fit_corrected_center)=7
	else
		print result
		print result2
		print result3
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
		String powerLabel = "power = " + num2str(measuredPow[i]) + " µW"
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

function plotClearShotCounts()
	
	SetDataFolder root:PAS
	
	SVAR dataSeriesList = dataSeriesList;
	Variable numDataSeries = ItemsInList(dataSeriesList)
	
	Variable i;
	String path;
	for (i=0 ; i<numDataSeries; i+=1)
		path = StringFromList(i,dataSeriesList) + ":IndexedWaves:";
		
		Wave absnum = $(path + "absnum")
		Wave ClearMax = $(path + "ClearMax")
		
		//Make plot of absnum, num_BEC, and num_TF on same graph for each data series
		Display absnum; 
		AppendToGraph/R ClearMax
		ModifyGraph rgb(ClearMax)=(0,0,65280)
		
		Label left "Atom Number"
		Label right "Clear Shot Max Counts"
		Label bottom "ShotNumber"
		
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

function exportPASData(FolderName)
	String FolderName// "This name should be formatted like PAS_XXXMHz" where XXX=23, 228, 1132, or 3693
	
	SetDataFolder root:PAS
	SaveData /D=1/O /T=$FolderName ":IgorPASdata"
end

function importPASData()
	String FolderName// "This name should be formatted like PAS_XXXMHz" where XXX=23, 228, 1132, or 3693
	
	
	//LoadData /D ":IgorPASdata"
	
	//NewPath 
	//String path = "Englebert_3_7_Sr_PAS_23MHz.pxp"
	LoadData /O=1 /S="PAS" /T=PAS_23MHz ":" //This works, but requires the user to manually find the file
		
end

function plotLoptCombined()
	
	String Axes;
	
	//Make 23 MHz lopt plot
	Display root:PAS_23MHz:lopt vs root:PAS_23MHz:actIntensity
	ModifyGraph mode=3,marker=19
	ErrorBars lopt XY,wave=(root:PAS_23MHz:deltaIntensity,root:PAS_23MHz:deltaIntensity),wave=(root:PAS_23MHz:deltaLopt,root:PAS_23MHz:deltaLopt)
	Label left "l\\Bopt\\M/a\\B0"
	Label bottom "Intensity (µW/cm\\S2\\M)"
	SetAxis left 0,*;
	SetAxis bottom 0,*
	
	//Add fit line (calculated in other notebook)
	AppendToGraph :PAS_23MHz:fit_lopt
	//Add line
	//Make /O/N=(2) lopt23_fit_coef
	//K0=0;
	//CurveFit/NTHR=0/Q=1/H="10"/ODR=2 line kwCWave=lopt23_fit_coef root:PAS_23MHz:lopt /X=root:PAS_23MHz:actIntensity /D /I=1 /W=root:PAS_23MHz:deltaLopt /XW=root:PAS_23MHz:deltaIntensity
	formatPASgraph()
	
	//Make 228 MHz lopt plot
	Display root:PAS_228MHz:lopt vs root:PAS_228MHz:actIntensity
	ModifyGraph mode=3,marker=19
	ErrorBars lopt XY,wave=(root:PAS_228MHz:deltaIntensity,root:PAS_228MHz:deltaIntensity),wave=(root:PAS_228MHz:deltaLopt,root:PAS_228MHz:deltaLopt)
	Label left "l\\Bopt\\M/a\\B0"
	Label bottom "Intensity (µW/cm\\S2\\M)"
	SetAxis left 0,*;
	SetAxis bottom 0,*
	//Add line
	AppendToGraph :PAS_228MHz:fit_lopt
	ModifyGraph rgb=(0,0,65280),marker(lopt)=16
	formatPASgraph()
	
	//Make 1143 MHz lopt plot
	Display root:PAS_1143MHz:lopt vs root:PAS_1143MHz:actIntensity
	ModifyGraph mode=3,marker=19
	ErrorBars lopt XY,wave=(root:PAS_1143MHz:deltaIntensity,root:PAS_1143MHz:deltaIntensity),wave=(root:PAS_1143MHz:deltaLopt,root:PAS_1143MHz:deltaLopt)
	Label left "l\\Bopt\\M/a\\B0"
	Label bottom "Intensity (µW/cm\\S2\\M)"
	SetAxis left 0,*;
	SetAxis bottom 0,*
	//Add line
	AppendToGraph :PAS_1143MHz:fit_lopt
	ModifyGraph rgb=(0,26112,0),marker(lopt)=17
	formatPASgraph()
	
	//Make 3693 MHz lopt plot
	Display root:PAS_3693MHz:lopt vs root:PAS_3693MHz:actIntensity
	ModifyGraph mode=3,marker=19
	ErrorBars lopt XY,wave=(root:PAS_3693MHz:deltaIntensity,root:PAS_3693MHz:deltaIntensity),wave=(root:PAS_3693MHz:deltaLopt,root:PAS_3693MHz:deltaLopt)
	Label left "l\\Bopt\\M/a\\B0"
	Label bottom "Intensity (µW/cm\\S2\\M)"
	SetAxis left 0,*;
	SetAxis bottom 0,*
	//Add line
	AppendToGraph :PAS_3693MHz:fit_lopt
	ModifyGraph rgb=(52224,34816,0),marker(lopt)=19
	formatPASgraph()
	
	//Make 1143, 3693 combined lopt plot
	Display root:PAS_1143MHz:lopt vs root:PAS_1143MHz:actIntensity
	ModifyGraph mode=3,marker=19
	ErrorBars lopt XY,wave=(root:PAS_1143MHz:deltaIntensity,root:PAS_1143MHz:deltaIntensity),wave=(root:PAS_1143MHz:deltaLopt,root:PAS_1143MHz:deltaLopt)
	Label left "l\\Bopt\\M/a\\B0"
	Label bottom "Intensity (µW/cm\\S2\\M)"
	SetAxis left 0,*;
	SetAxis bottom 0,*
	//Add line
	AppendToGraph :PAS_1143MHz:fit_lopt
	ModifyGraph rgb=(0,26112,0),marker(lopt)=17
	//Add 3693 data
	AppendToGraph :PAS_3693MHz:lopt vs :PAS_3693MHz:actIntensity
	ErrorBars lopt#1 XY,wave=(root:PAS_3693MHz:deltaIntensity,root:PAS_3693MHz:deltaIntensity),wave=(root:PAS_3693MHz:deltaLopt,root:PAS_3693MHz:deltaLopt)
	AppendToGraph :PAS_3693MHz:fit_lopt
	ModifyGraph mode(lopt#1)=3,marker(lopt#1)=19,rgb(lopt#1)=(52224,34816,0)
	ModifyGraph rgb(fit_lopt#1)=(52224,34816,0)
	formatPASgraph()
	
end

function formatPASgraph()
	
	String Axes;
	
	ModifyGraph tick=2, standoff=1, btLen=3, stLen=2 //change to standoff=0 to remove standoff
	// Only mirror if no opposite axes
	Axes = AxisList("");
	if (stringmatch(Axes, "!*right*" ))
		ModifyGraph mirror(left)=1		
	Endif
	if (stringmatch(Axes, "!*left*" ))
		ModifyGraph mirror(right)=1		
	Endif
	if (stringmatch(Axes, "!*top*" ))
		ModifyGraph mirror(bottom)=1		
	Endif
	if (stringmatch(Axes, "!*bottom*" ))
		ModifyGraph mirror(top)=1		
	Endif
	
	•ModifyGraph width=0,height={Aspect,1}
	//ModifyGraph width=250
	//ModifyGraph height=250
	// Line Thickness Stuff
		ModifyGraph lsize=0.5
		ModifyGraph zeroThick=0.5
		ModifyGraph axThick=0.5
		ModifyGraph btThick=0.5
		ModifyGraph ftThick=0.5
		ModifyGraph stThick=0.5
		ModifyGraph ttThick=0.5
		
		//font size
		ModifyGraph fSize(left)=22, fSize(bottom)=22
end

function generateplots()
	
	String folderList = "root:PAS_23MHz;root:PAS_228MHz;root:PAS_1143MHz;root:PAS_3693MHz"
	NewPath /O FigureFolder "C:Users:breschovsky:Documents:GitHub:Papers:SrDepumpPaper:84 PAS Files:84PAS-Figures:"
	
	//options:
	Variable plotLoptInd = 1
	Variable plotLoptComb = 1
	Variable plotEtaInd = 1
	Variable plotEtaComb = 1
	
	Variable savePlot = 1;

	Variable numFolders = ItemsInList(folderList);
	Variable i;
	String path;
	String plotName;
	String AxesLabelSize = "\Z28"
	String legendTextSize = "\Z24";

	for(i=0;i<numFolders; i +=1)	
		path = StringFromList(i,folderList);
		cd path;
		Wave actIntensity = :actIntensity
		Wave deltaIntensity = :deltaIntensity
		Wave fit_lopt = :fit_lopt
		Wave fit_eta = :fit_eta
		
		//Add new waves to scale the intensity from uW to mW
		Make /O /N=(numpnts(lopt)) actIntensity_mW = actIntensity/1000;
		Make /O /N=(numpnts(lopt)) deltaIntensity_mW = deltaIntensity/1000;
		Make /O /N=(numpnts(fit_lopt)) fit_lopt_mW = fit_lopt;
		Make /O /N=(numpnts(fit_eta)) fit_eta_mW = fit_eta;
		SetScale /P x, DimOffset(fit_lopt,0)/1000, DimDelta(fit_lopt,0)/1000, fit_lopt_mW
		SetScale /P x, DimOffset(fit_eta,0)/1000, DimDelta(fit_eta,0)/1000, fit_eta_mW
		
		if (plotLoptInd == 1)
			//Generate individual lopt plots
			plotName = "lopt_" + num2str(i)
			Display /N=$plotName lopt vs actIntensity_mW
			ModifyGraph mode=3,marker=19
			ErrorBars lopt XY,wave=(deltaIntensity_mW,deltaIntensity_mW),wave=(deltaLopt,deltaLopt)
			Label left AxesLabelSize + "\F'Times New Roman'l\\Bopt\\M/\f02a\f00\\B0"
			Label bottom AxesLabelSize + "\f02\F'Times New Roman'I \f00(mW/cm\\S2\\M)" 
			
			SetAxis left 0,*;
			SetAxis bottom 0,*
		
			//Add fit line (calculated in other igor experiment)
			AppendToGraph fit_lopt_mW
			
			//Change color and marker
			if (i == 1)
				//228 MHz
				ModifyGraph rgb=(0,0,65280),marker(lopt)=16
				Legend /C/N=text0/J/M/A=LT legendTextSize + "\\s(lopt)0\Bu\M\S\Z16+\M" + legendTextSize +"\F'symbol' n = -3"

			elseif (i==2)
				//1143 MHz
				ModifyGraph rgb=(0,26112,0),marker(lopt)=17
				Legend /C/N=text0/J/M/A=LT legendTextSize + "\\s(lopt)0\Bu\M\S\Z16+\M" + legendTextSize +"\F'symbol' n = -4"
			elseif (i==3)
				//3693 MHz
				ModifyGraph rgb=(52224,34816,0),marker(lopt)=18
				Legend /C/N=text0/J/M/A=LT legendTextSize + "\\s(lopt)0\Bu\M\S\Z16+\M" + legendTextSize +"\F'symbol' n = -5"
			else //i==0, 23 MHz
				Legend /C/N=text0/J/M/A=LT legendTextSize + "\\s(lopt)0\Bu\M\S\Z16+\M" + legendTextSize +"\F'symbol' n = -2"
			endif
			
			formatPASgraph()
			
			if (savePlot==1)
				SavePICT/EF=1/E=-8 /O/WIN=$plotName /P=FigureFolder
			endif
		endif
		
		//Generate combined plots for 1143 and 3693 MHz;
		
		if (plotLoptComb == 1)
			if (i==2)
				plotName = "lopt_2_3" 
				Display /N=$plotName lopt vs actIntensity_mW
				ModifyGraph mode=3,marker=19
				ErrorBars lopt XY,wave=(deltaIntensity_mW,deltaIntensity_mW),wave=(deltaLopt,deltaLopt)
				Label left AxesLabelSize + "\F'Times New Roman'l\\Bopt\\M/\f02a\f00\\B0"
				Label bottom AxesLabelSize + "\f02\F'Times New Roman'I \f00(mW/cm\\S2\\M)" 
				SetAxis left 0,*;
				SetAxis bottom 0,*
		
				//Add fit line (calculated in other igor experiment)
				AppendToGraph fit_lopt_mW
				ModifyGraph rgb=(0,26112,0),marker(lopt)=17
			elseif (i==3)
				plotName = "lopt_2_3"
				DoWindow /F $plotName
				AppendToGraph lopt vs actIntensity_mW
				AppendToGraph fit_lopt_mW
				ErrorBars lopt#1 XY,wave=(deltaIntensity_mW,deltaIntensity_mW),wave=(deltaLopt,deltaLopt)
				ModifyGraph mode(lopt#1)=3,marker(lopt#1)=18,rgb(lopt#1)=(52224,34816,0)
				ModifyGraph rgb(fit_lopt_mW#1)=(52224,34816,0)
				formatPASgraph()
				
				//Add Legend
				
				Legend /C/N=text0/J/M/A=LT/X=0.0/Y=5.0 legendTextSize + "\\s(lopt)0\Bu\M\S\Z16+\M" + legendTextSize +"\F'symbol' n = -4 \F'Arial' \r\\s(lopt#1)0\Bu\M\S\Z16+\M" + legendTextSize + "\F'symbol' n = -5 \F'Arial'"
				
				if (savePlot==1)
					SavePICT/EF=1/E=-8/O/WIN=$plotName /P=FigureFolder
				endif
			endif
		endif
		
		if (plotEtaComb == 1)
			if (i==2)
				plotName = "eta_2_3"
				Display /N =$plotName eta vs actIntensity_mW
				ModifyGraph mode=3,marker=19
				ErrorBars eta XY,wave=(deltaIntensity_mW,deltaIntensity_mW),wave=(deltaEta,deltaEta)
				Label left AxesLabelSize + "\f02\[0\F'Symbol'h\]0"
				Label bottom AxesLabelSize + "\f02\F'Times New Roman'I \f00(mW/cm\\S2\\M)" 
				
				SetAxis left 1.0,*;
				SetAxis bottom 0,*
		
				//Add fit line (calculated in other igor experiment)
				AppendToGraph fit_eta_mW
				ModifyGraph lstyle(fit_eta_mW)=7
				ModifyGraph rgb=(0,26112,0),marker(eta)=17
			elseif (i==3)
				plotName = "eta_2_3"
				DoWindow /F $plotName
				AppendToGraph eta vs actIntensity_mW
				AppendToGraph fit_eta_mW
				ErrorBars eta#1 XY,wave=(deltaIntensity_mW,deltaIntensity_mW),wave=(deltaEta,deltaEta)
				ModifyGraph mode(eta#1)=3,marker(eta#1)=18,rgb(eta#1)=(52224,34816,0)
				ModifyGraph rgb(fit_eta_mW#1)=(52224,34816,0)
				ModifyGraph lstyle(fit_eta_mW#1)=7
				formatPASgraph()
				if (savePlot==1)
					SavePICT/EF=1/E=-8 /O/WIN=$plotName /P=FigureFolder
				endif
			endif
		endif
		
		//Generate individual eta plots
		if (plotEtaInd == 1)
			plotName = "eta_" + num2str(i)
			Display /N=$plotName eta vs actIntensity_mW
			ModifyGraph mode=3,marker=19
			ErrorBars eta XY,wave=(deltaIntensity_mW,deltaIntensity_mW),wave=(deltaEta,deltaEta)
			Label left AxesLabelSize + "\f02\[0\F'Symbol'h\]0"
			Label bottom AxesLabelSize + "\f02\F'Times New Roman'I \f00(mW/cm\\S2\\M)" 
			SetAxis left 1.0,*;
			SetAxis bottom 0,*
			//Add fit line (calculated in other igor experiment)
			AppendToGraph fit_eta_mW
			ModifyGraph lstyle(fit_eta_mW)=7
			
			//Change color and marker
			if (i == 1)
				//228 MHz
				ModifyGraph rgb=(0,0,65280),marker(eta)=16
			elseif (i==2)
				//1143 MHz
				ModifyGraph rgb=(0,26112,0),marker(eta)=17
			elseif (i==3)
				//3693 MHz
				ModifyGraph rgb=(52224,34816,0),marker(eta)=18
			endif
			
			formatPASgraph()
			if (savePlot==1)
				SavePICT/EF=1/E=-8 /O/WIN=$plotName /P=FigureFolder
			endif
		endif
		
		
	endfor
	cd root:
end

function combineCenterScans()

	//make directory to hold analysis results
	NewDataFolder /O root:PAS_combinedCenters
	SetDataFolder root:PAS_combinedCenters
	KillWaves /A/Z ; KillVariables /A/Z ; KillStrings /A/Z
	
	String /G dataSeriesList = "";
	Variable numDataSeries
	
	Variable isotope = 86;
	
	if (isotope == 84)
		//*******Put in names of data series that contain the data we want to analyze and plot
		dataSeriesList = AddListItem("root:center0",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center350",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center23",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center152",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center228",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center1143",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center2047",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center3693",dataSeriesList,";",999)
	elseif(isotope == 86)
		dataSeriesList = AddListItem("root:center0",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center1",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center44",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center349",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center1003",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center1528",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center4467",dataSeriesList,";",999)
		dataSeriesList = AddListItem("root:center4624",dataSeriesList,";",999)
	endif
	
	numDataSeries = ItemsInList(dataSeriesList)
	
	//loop over data series to populate certain data
	variable i;
	String path = ""
	variable maxAtomNum;
	for(i=0;i<numDataSeries; i +=1)	
		
		if (isotope==84)
			path = StringFromList(i,dataSeriesList) + ":IndexedWaves";
		elseif (isotope ==86)
			path = StringFromList(i,dataSeriesList)
		endif
		
		//Duplicate absnum
		Duplicate /O $(path + ":absnum") $("absnum_" + num2str(i) )
		
		//Duplicate SSDetuning
		Duplicate /O $(path + ":SSDetuning") $("detuning_" + num2str(i) )
		
		//Manipulate data
		Duplicate $("absnum_" + num2str(i) ) $("absnum_normalized_" + num2str(i) )
		Wave absNorm = $(":absnum_normalized_" + num2str(i) )
		
		Wave det = $("detuning_" + num2str(i) )
		
		det = det/1e6 //convert detuning from Hz to MHz;
		if (i < 5)
			det = - det //For resonances less than ~1 GHz, multiply by -1 so that all detunings are negative
		endif
		
		//Fit to lorenztian to get atom number level to normalize to
		//Make wave to hold fit coefficients:
		Make /O/N=(4) fit_coef;
		CurveFit/NTHR=0/N=1/Q=1 lor kwCWave=fit_coef absNorm /X=det //D 
				//CurveFit lor absNorm /X=det
		maxAtomNum = fit_coef[0];
		absNorm = absNorm / maxAtomNum
		//absNorm = absNorm / WaveMax(absNorm) ; //Normalize atom number
		
	endfor
	
	//plot all scans on the same axes
	Display
	for(i=0;i<numDataSeries; i +=1)
		Wave absNorm = $(":absnum_normalized_" + num2str(i) )
		Wave det = $("detuning_" + num2str(i) )
		AppendToGraph absNorm vs det
		//ModifyGraph mode(absNorm)=3,marker(absNorm)=8
	endfor
		
end


function fitThermalK2(w,x) : FitFunc
	Wave w;
	Variable x
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = N0*(1 + B/((x-x0)^2 + gamma^2/4)) + C)^(-5/2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = lopt
	//CurveFitDialog/ w[1] = eta
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = temp (temperature, nK)
	
	//x=2*Pi*x;
	//w[2] = 2*Pi*w[2]//these lines break the function, I have no idea why
	
	//calcThermalK2(temp (nK), f (Hz), f0 (Hz),lopt (a0), eta (>=1))
	
	return calcThermalK2(w[3],x,w[2],w[0],w[1]) 

end

function calcThermalK2(temp, f, f0,lopt, eta)
	
	Variable temp //temp, nK
	Variable f //Detuning, Hz (this should be negative for red detuned)
	Variable f0 //binding energy of photassociation resonance, Hz
	Variable lopt //optical length (a0)
	Variable eta //(broadening factor)
	
	//constants needed: kB, hbar, h, m
	Variable h = hbar*2*pi
	Variable m = 86*1.660539040e-27;
	Variable mu = m/2;
	
	Variable lambda=689e-9;
	Variable k = 2*pi/lambda;
	Variable Erec = ((h/lambda)^2/(4*m))/h;
	
	lopt = lopt*5.29177e-11 //convert from bohr radii to m
	
	Variable Qt = (2*pi*kB*temp*1e-9*mu/(h^2))^(3/2);
	
	Variable delMol = 2*pi*15000; //molecular natural linewidth
	Variable/G globalDelT = kB*temp*1e-9/h; //thermal width
	Variable/G globalF = f; //detuning
	Variable/G globalF0 = f0 //center
	Variable/G globalErec = Erec //recoil energy shift (Hz)
	Variable/G globalDelD = sqrt(kB*temp*1e-9/m)/lambda //doppler width
	Variable/G globalEta = eta;
	Variable/G globalNumerator = eta*delMol*2*sqrt(2*mu*globalDelT*h)*delMol*lopt/(hbar*4*pi^2); //numerator of L function, without the x dependence
	
	Variable/G globalY
	return (kB*temp*1e-9)*integrate1D(lineshapeIntegrate2,-10,10)/(h*Qt)
end

function lineshapeIntegrand(inX)
	Variable inX
	
	NVAR globalY=globalY
	NVAR globalNumerator = globalNumerator
	NVAR globalF = globalF
	NVAR globalDelD = globalDelD
	NVAR globalDelT = globalDelT
	NVAR globalF0 = globalF0
	NVAR globalErec = globalErec
	NVAR globalEta = globalEta
	Variable delMol = 2*pi*15000; //molecular natural linewidth
	
	return exp(-globalY^2)*inX*exp(-inX^2)*globalNumerator*inX / ( (globalF + globalY*globalDelD + inX^2*globalDelT - globalF0 - globalErec)^2 + (globalEta*delMol)^2/(4*pi)^2 );
	
end	

function lineshapeIntegrate2(inY)
	Variable inY
	
	NVAR globalY=globalY
	globalY = inY
	
	return integrate1D(lineshapeIntegrand,0,10)
end

function testThermalLinshapes()

	Make/O /n=200 detuning
	duplicate/O detuning K2wave
	Variable detStart = 999.9e6
	Variable deltaDet = 1e3
	Variable lopt = 6;
	Variable eta = 1.5
	
	variable temp =160;
	
	Variable i=0;
	for (i=0; i<200; i+=1)
		detuning[i] = detStart + i*deltaDet
		K2wave[i] = calcThermalK2(temp,detuning[i],1e9,lopt ,eta)
	endfor
	display k2wave vs detuning
end	


function thermalPASloss(w,x) : FitFunc
	Wave w;
	Variable x
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = N0*(1 + B/((x-x0)^2 + gamma^2/4)) + C)^(-5/2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = N0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = lopt
	//CurveFitDialog/ w[4] = eta
	//CurveFitDialog/ w[5] = t
	//CurveFitDialog/ w[6] = temp (temperature, nK)
	
	//x=2*Pi*x;
	//w[2] = 2*Pi*w[2]//these lines break the function, I have no idea why
	
	//calcThermalK2(temp (nK), f (Hz), f0 (Hz),lopt (a0), eta (>=1))
	
	return w[0]*(1 + w[1]*w[0]*w[5]*calcThermalK2(w[6],x,w[2],w[3],w[4]) )

end

function analyzeThermalPAS()
	//Wave detWave, absnumWave, tempWave
	//working directory must be the indexed waves folder of the data series
	
	//make plots if desired
	Variable plot = 1
	if (plot == 1)
		Display absnum vs SSDetuning
		ModifyGraph mode=3,marker=19
		//Display ClearMax
		Display tempV vs SSDetuning
		ModifyGraph mode=3,marker=19
	endif
	
	//declare local wave references
	Wave detWave = :SSDetuning	
	Wave absnumWave = :absnum
	Wave tempWave = :tempV
		
	//Find average temperature	
	Wavestats /Q tempWave
	Variable tempAvg = V_avg;
	Variable deltaTemp = V_sdev;
	
	//apply correction to temperature to account for the slight overestimate of the single shot temperatures:
	tempAvg = 0.975*tempAvg;
	print "temp: " + num2str(tempAvg)
	
	//declare some constants
	Variable omegaBar = 2*pi*(213*21.5*3.5)^(1/3);
	Variable mass = 86*1.66e-27;
	Wave PATwv = :PAT
	variable PAT = PATwv[0];
	
	print "PAT: " + num2str(PAT)
	
	//In order for the correction to be in the correct direction, the SSDetuning values must be negative
	if (detWave[0] > 0)
		Duplicate /O detWave SSDetNeg
		SSDetNeg = -detWave
		Wave detWave = :SSDetNeg
	endif
	
	//fit the data to a lorentzian to get guesses for several parameters
	Make /O/N=4 lorFitCoef
	CurveFit/NTHR=0/N/Q lor kwCWave=lorFitCoef absnumWave /X=detWave /D 
	
	Variable N0 = lorFitCoef[0]
	Variable f0 = lorFitCoef[2]
	
	Duplicate /O absnumWave kWave
	
	//Calculate PAS loss rate for the data:
	kWave = (4/PAT)*(1/absnumWave - 1/N0)*(pi*kB*tempAvg*1e-9/(mass*omegaBar^2))^(3/2)
	
	Duplicate /O detWave SSDetuningShifted
	SSDetuningShifted = SSDetuningShifted - f0;
	
	if (plot == 1)
		Display kWave vs SSDetuningShifted
		ModifyGraph mode=3,marker=19
	endif
		
	Make /D/O/N=4 fit_K2_coef = {10,1.2,4000,tempAvg}
	Make/O/T/N=2 T_Constraints
	T_Constraints = {"K0>0","K1 > 1"}
	FuncFit/H="0001"/NTHR=0 fitThermalK2 fit_K2_coef kWave /X=SSDetuningShifted /D //C=T_Constraints 
	
	Wave W_sigma = :W_sigma
	print /d (fit_k2_coef[2] + f0)/1e6
	print W_sigma[2]

end

function formatCombinedGraph86()
	
	String plotName = "combinedDetunings"
	
	Display/R=R0/B=B0 absnum_normalized_0 vs detuning_0
	AppendToGraph/R=R1/B=B1 absnum_normalized_1 vs detuning_1
	AppendToGraph/R=R44/B=B44 absnum_normalized_2 vs detuning_2
	AppendToGraph/R=R349/B=B349 absnum_normalized_3 vs detuning_3
	AppendToGraph/R=R1003/B=B1003 absnum_normalized_4 vs detuning_4
	AppendToGraph/R=R1528/B=B1528 absnum_normalized_5 vs detuning_5
	AppendToGraph/R=R4467/B=B4467 absnum_normalized_6 vs detuning_6
	AppendToGraph/R=R4624/B=B4624 absnum_normalized_7 vs detuning_7
	
	DoWindow /C $plotName
	
	Variable gap = 2/100 // gap between breaks, %
	
	//B0 0.1 - -0.1, 				16.3%
	//B1 1.548-1.698, 			12.3%
	//B44 44.171-44.321			12.3%
	//B349 349.657-348.807 		12.3%
	//B1003 1003.37-1003.51		11.5%
	//B1528 1527.71-1527.57		11.5%
	//B4467 4466.5-4466.65		12.3%
	//B4624	4624.23-4624.09		11.5%
	Variable total = 1-7*gap; //percent of graph available for data after taking out the gaps
	Variable width16 = .163*total;
	Variable width12 = 0.123*total;
	Variable width11 = .115*total;
	
	Variable i=0;
	String wvName = "absnum_normalized_"
	String tempWvName;
	String bottomLabel;
	String rightLabel;
	String leftLabel
	for (i=0; i<8; i+=1)
		tempWvName = wvName + num2str(i);
		ModifyGraph mode($(tempWvName))=3,marker($(tempWvName))=8 //modify marker type
		
		//Wave absNorm = $(":absnum_normalized_" + num2str(i) )
		//Wave det = $("detuning_" + num2str(i) )
		//CurveFit /N/Q lor absNorm /X=det /D
		
		Wave fitWave = $(":fit_absnum_normalized_" + num2str(i) )		
		
		if (i == 0)
			bottomLabel = "B0"
			rightLabel = "R0"
			leftLabel = "L0"
		elseif (i == 1)
			bottomLabel = "B1"
			rightLabel = "R1"
			leftLabel = "L1"
		elseif (i == 2)
			bottomLabel = "B44"
			rightLabel = "R44"
			leftLabel = "L44"
		elseif (i == 3)
			bottomLabel = "B349"
			rightLabel = "R349"
			leftLabel = "L349"
		elseif (i == 4)
			bottomLabel = "B1003"
			rightLabel = "R1003"
			leftLabel = "L1003"
		elseif (i == 5)
			bottomLabel = "B1528"
			rightLabel = "R1528"
			leftLabel = "L1528"
		elseif (i == 6)
			bottomLabel = "B4467"
			rightLabel = "R4467"
			leftLabel = "L4467"
		elseif (i == 7)
			bottomLabel = "B4624"
			rightLabel = "R4624"
			leftLabel = "L4624"
		endif

		AppendToGraph /B=$(bottomLabel) /L=$(leftLabel) fitWave		//add fit wave
				
		ModifyGraph mirror($(bottomLabel))=1		//mirror bottom axes
		SetAxis $(rightLabel) 0,1.2					//set vertical axes limits
		SetAxis $(leftLabel) 0, 1.2
		ModifyGraph freePos($(bottomLabel))={0,$(rightLabel)}  //set bottom axes position
		ModifyGraph noLabel($(rightLabel))=2         //no number labels on vertical axes
		ModifyGraph noLabel($(leftLabel))=2
	endfor
	
	Variable borderR = 1;
	Variable borderL = borderR-width16;
	ModifyGraph axisEnab(B0)={borderL,borderR}
	ModifyGraph freePos(R0)={0,kwFraction}
	ModifyGraph freePos(L0)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = borderR - width12;	
	ModifyGraph axisEnab(B1)={borderL,borderR}
	ModifyGraph freePos(R1)={1-borderR,kwFraction}
	ModifyGraph freePos(L1)={borderL,kwFraction}
	
	borderR = borderL - gap
	borderL = borderR - width12;	
	ModifyGraph axisEnab(B44)={borderL,borderR}
	ModifyGraph freePos(R44)={1-borderR,kwFraction}
	ModifyGraph freePos(L44)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = borderR - width12;	
	ModifyGraph axisEnab(B349)={borderL,borderR}
	ModifyGraph freePos(R349)={1-borderR,kwFraction}
	ModifyGraph freePos(L349)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = borderR - width11;	
	ModifyGraph axisEnab(B1003)={borderL,borderR}
	ModifyGraph freePos(R1003)={1-borderR,kwFraction}
	ModifyGraph freePos(L1003)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = borderR - width11;	
	ModifyGraph axisEnab(B1528)={borderL,borderR}
	ModifyGraph freePos(R1528)={1-borderR,kwFraction}
	ModifyGraph freePos(L1528)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = borderR - width12;	
	ModifyGraph axisEnab(B4467)={borderL,borderR}
	ModifyGraph freePos(R4467)={1-borderR,kwFraction}
	ModifyGraph freePos(L4467)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = max(borderR - width11,0);	
	ModifyGraph axisEnab(B4624)={borderL,borderR}
	ModifyGraph freePos(R4624)={1-borderR,kwFraction}
	ModifyGraph freePos(L4624)={borderL,kwFraction}
	
	//SetAxis left 0,1.2
	ModifyGraph tick=2, standoff=1, btLen=3, stLen=2 //change to standoff=0 to remove standoff

	//Change the number of ticks so the bottom axis is readable
	ModifyGraph nticks(B1)=2;
	ModifyGraph nticks(B44)=2;
	ModifyGraph nticks(B349)=2,nticks(B1003)=1,nticks(B1528)=1,nticks(B4467)=1;
	ModifyGraph nticks(B4624)=1;
	
	//labels
	Label B349 "Detuning (MHz)"
	Label L4624 "Normalized Atom Number"
	
	//Set size of graph
	ModifyGraph width=500,height=100
	
	//Fix the labels around zero
	ModifyGraph ZisZ(B0)=1,lowTrip(B0)=0.01
	
	//Add labels to leftmost vertical axis
	ModifyGraph noLabel(L4624)=0,lblPos(L4624)=30
	
	//Position bottom label
	ModifyGraph lblPos(B349)=30
	
	//Get rid of offset on the right of plot
	ModifyGraph axOffset(R0)=-5
	
	//SavePICT/EF=2/E=-8 /O/WIN=$plotName /P=FigureFolder
end

function formatCombinedGraph84()

	cd root:PAS_combinedCenters

	String plotName = "combinedDetunings84"
	
	Display/R=R0/B=B0 absnum_normalized_0 vs detuning_0
	AppendToGraph/R=R1/B=B1 absnum_normalized_1 vs detuning_1
	AppendToGraph/R=R2/B=B2 absnum_normalized_2 vs detuning_2
	AppendToGraph/R=R3/B=B3 absnum_normalized_3 vs detuning_3
	AppendToGraph/R=R4/B=B4 absnum_normalized_4 vs detuning_4
	AppendToGraph/R=R5/B=B5 absnum_normalized_5 vs detuning_5
	AppendToGraph/R=R6/B=B6 absnum_normalized_6 vs detuning_6
	AppendToGraph/R=R7/B=B7 absnum_normalized_7 vs detuning_7
	
	DoWindow /C $plotName
	
	Variable gap = 2/100 // gap between breaks, %
	
	//B0 0.1 - -0.1, 				16.1%
	//B1 .25 - 0.45, 				16.1%
	//B2 27.99 - 23.11			9.7%
	//B3 152.08 - 152.28 			16.1%
	//B4 228.33 - 228.47			11.3%
	//B5 1143.09 - 1143.21		9.7%
	//B6 2046.64 - 2046.76		9.7%
	//B7	3692.57 - 3692.71		11.3%
	Variable total = 1-7*gap; //percent of graph available for data after taking out the gaps
	Variable width16 = .161*total;
	Variable width9 = 0.097*total;
	Variable width11 = .113*total;
	
	Variable i=0;
	String wvName = "absnum_normalized_"
	String tempWvName;
	String bottomLabel;
	String rightLabel;
	String leftLabel
	for (i=0; i<8; i+=1)
		tempWvName = wvName + num2str(i);
		ModifyGraph mode($(tempWvName))=3,marker($(tempWvName))=8 //modify marker type
		
		//Wave absNorm = $(":absnum_normalized_" + num2str(i) )
		//Wave det = $("detuning_" + num2str(i) )
		//CurveFit /N/Q lor absNorm /X=det /D
		
		Wave fitWave = $(":fit_absnum_normalized_" + num2str(i) )		
		
		bottomLabel = "B" + num2str(i)
		rightLabel = "R" + num2str(i)
		leftLabel = "L" + num2str(i)

		AppendToGraph /B=$(bottomLabel) /L=$(leftLabel) fitWave		//add fit wave
				
		ModifyGraph mirror($(bottomLabel))=1		//mirror bottom axes
		SetAxis $(rightLabel) 0,1.2					//set vertical axes limits
		SetAxis $(leftLabel) 0, 1.2
		ModifyGraph freePos($(bottomLabel))={0,$(rightLabel)}  //set bottom axes position
		ModifyGraph noLabel($(rightLabel))=2         //no number labels on vertical axes
		ModifyGraph noLabel($(leftLabel))=2
	endfor
	
	Variable borderR = 1;
	Variable borderL = borderR-width16;
	ModifyGraph axisEnab(B0)={borderL,borderR}
	ModifyGraph freePos(R0)={0,kwFraction}
	ModifyGraph freePos(L0)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = borderR - width16;	
	ModifyGraph axisEnab(B1)={borderL,borderR}
	ModifyGraph freePos(R1)={1-borderR,kwFraction}
	ModifyGraph freePos(L1)={borderL,kwFraction}
	
	borderR = borderL - gap
	borderL = borderR - width9;	
	ModifyGraph axisEnab(B2)={borderL,borderR}
	ModifyGraph freePos(R2)={1-borderR,kwFraction}
	ModifyGraph freePos(L2)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = borderR - width16;	
	ModifyGraph axisEnab(B3)={borderL,borderR}
	ModifyGraph freePos(R3)={1-borderR,kwFraction}
	ModifyGraph freePos(L3)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = borderR - width11;	
	ModifyGraph axisEnab(B4)={borderL,borderR}
	ModifyGraph freePos(R4)={1-borderR,kwFraction}
	ModifyGraph freePos(L4)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = borderR - width9;	
	ModifyGraph axisEnab(B5)={borderL,borderR}
	ModifyGraph freePos(R5)={1-borderR,kwFraction}
	ModifyGraph freePos(L5)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = borderR - width9;	
	ModifyGraph axisEnab(B6)={borderL,borderR}
	ModifyGraph freePos(R6)={1-borderR,kwFraction}
	ModifyGraph freePos(L6)={borderL,kwFraction}

	borderR = borderL - gap
	borderL = max(borderR - width11,0);	
	ModifyGraph axisEnab(B7)={borderL,borderR}
	ModifyGraph freePos(R7)={1-borderR,kwFraction}
	ModifyGraph freePos(L7)={borderL,kwFraction}
	
	//SetAxis left 0,1.2
	ModifyGraph tick=2, standoff=1, btLen=3, stLen=2 //change to standoff=0 to remove standoff
	
	//Change the number of ticks so the bottom axis is readable
	ModifyGraph nticks(B2)=1,nticks(B3)=2,nticks(B4)=1,nticks(B5)=1,nticks(B6)=1,nticks(B7)=1
		
	//labels
	Label B3 "Detuning (MHz)"
	Label L7 "Normalized Atom Number"
	
	//Set size of graph
	ModifyGraph width=500,height=100
	
	//Fix the labels around zero
	ModifyGraph ZisZ(B0)=1,lowTrip(B0)=0.01
	
	//Add labels to leftmost vertical axis
	ModifyGraph noLabel(L7)=0,lblPos(L7)=30
	
	//Position bottom label
	ModifyGraph lblPos(B3)=30
	
	//Get rid of offset on the right of plot
	ModifyGraph axOffset(R0)=-5
	
	//SavePICT/EF=2/E=-8 /O/WIN=$plotName /P=FigureFolder
end
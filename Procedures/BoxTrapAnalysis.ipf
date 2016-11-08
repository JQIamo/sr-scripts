#pragma rtGlobals=1		// Use modern global access method.

function boxTOFimportImages(startNum,endNum,skipList,startAlpha,endAlpha)
 	Variable startNum, endNum, startAlpha, endAlpha
 	string skipList


	NVAR PolyLogOrd = :PolyLogOrderVar
	variable ii, jj
	
	for (jj = startNum ; jj <= endNum; jj+=1) //loop over image numbers
		if(WhichListItem(num2str(jj),skipList,";",0,1)==-1) //only load images not in skipList
			PolyLogOrd=startAlpha;
			BatchRun(-1,jj,0,"") //load the current image
			for (ii = startAlpha+0.1 ; ii < endAlpha+0.1 ; ii += 0.1) //Loop over polylog orders
				PolyLogOrd = ii;
				refit("");
			endfor
		endif
	endfor
				

End

function sliceByPolyLogOrder()
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	
	
	//Sort Indexed Waves
	Sort_IndexedWaves(ProjectFolder,"polyLogOrder;boxOn;temp",3)
	
	//Make a new data folder to store the waves created below
	NewDataFolder /O $(ProjectFolder + ":polyLogBoxTrapAnalysis")
		
	//Make wave to hold the polylog orders that were fitted:
	Duplicate /O $(ProjectFolder + ":IndexedWaves:polyLogOrder") $(ProjectFolder + ":polyLogBoxTrapAnalysis:polyLogOrder")
	Wave polyLogOrder= $(ProjectFolder + ":polyLogBoxTrapAnalysis:polyLogOrder")
	
	//Make wave to hold the number of images that were fitted for each polylog order:
	Make /O 	/N=1 $(ProjectFolder + ":polyLogBoxTrapAnalysis:numImages")
	Wave numImages = $(ProjectFolder + ":polyLogBoxTrapAnalysis:numImages")
	
	//Delete duplicates and save the number of images at each order
	Variable ii=1, count=1, jj=0
	do
		if (polyLogOrder[ii] == polyLogOrder[ii-1])
			DeletePoints ii, 1, polyLogOrder //if this point is the same as previous, delete it
			count +=1; //increment counter
		else
			ii+=1
			numImages[jj] = count;
			count = 1 //reset counter
			jj+=1
			Redimension /N=(numpnts(numImages)+1) numImages
		endif
	while (ii<numpnts(polyLogOrder))			
	numImages[jj] = count; //handle the last point
	
	Variable numOrders = numpnts(polyLogOrder)
	
	//Make wave to hold string representations of the polylog orders:
	//Make/T/O /N=(numOrders) $(ProjectFolder + ":polyLogBoxTrapAnalysis:polyLogOrderStr")  = ReplaceString(".",num2str(polyLogOrder),"_");
	//Wave polyLogOrderStr = $(ProjectFolder + ":polyLogBoxTrapAnalysis:polyLogOrderStr")
	
	String tempStr = ""
	Variable startNum = 0;
	Variable endNum = 0;
	
	String savedDataFolder = GetDataFolder(1);
	//String indWvsDF = ProjectFolder + ":IndexedWaves"
	SetDataFolder $(ProjectFolder + ":IndexedWaves")
	String indWavesList = WaveList("*",";","")
	String currIndWave;
	Variable indWavesNum = ItemsInList(indWavesList);
	
	for (ii = 0 ; ii <numOrders ; ii+=1) //loop through poly log orders
		tempStr = ReplaceString(".",num2str(polyLogOrder[ii]),"_");
		tempStr = ProjectFolder + ":polyLogBoxTrapAnalysis:PL_" + tempStr 
		NewDataFolder /O $tempStr //make new data folder
		
		NewDataFolder /O $(tempStr + ":BoxOff")
		NewDataFolder /O $(tempStr + ":BoxOn")
		
		for (jj = 0; jj <indWavesNum; jj +=1) //loop through each indexed wave
			currIndWave = StringFromList(jj,indWavesList);
			
			//Check if there are boxOff shots:
			FindValue /V=0 /T=0.1 /S=(startNum) $(ProjectFolder + ":IndexedWaves:boxOn")
			If (V_Value == startNum)
				//yes there are boxOff shots
				FindValue /V=1 /T=0.1 /S=(startNum) $(ProjectFolder + ":IndexedWaves:boxOn") //find start of boxOn images
				endNum= min(V_Value-1,startNum + numImages[ii] - 1);
				
				//Copy boxOff data:
				Duplicate /O/R=(startNum,endNum) $(ProjectFolder + ":IndexedWaves:" + currIndWave) $(tempStr + ":BoxOff:" + currIndWave)
			endif
			
			//check if there are boxOn shots:
			FindValue /V=1 /T=0.1 /S=(startNum) $(ProjectFolder + ":IndexedWaves:boxOn")
			if (V_Value >= startNum && V_Value <= (startNum + numImages[ii] -1))
				//yes there are boxOn shots
				//Copy boxOff data:
				Duplicate /O/R=(V_Value,startNum + numImages[ii] - 1) $(ProjectFolder + ":IndexedWaves:" + currIndWave) $(tempStr + ":BoxOn:" + currIndWave)
			endif				
			
			//Duplicate /O/R=(startNum,startNum+numImages[ii]-1) $(ProjectFolder + ":IndexedWaves:" + currIndWave) $(tempStr + ":" + currIndWave)
		endfor
		startNum += numImages[ii]		
	endfor
	
	
	SetDataFolder savedDataFolder

	
	//Make numOrders folders named 1_0, 1_1, etc
	
	//Copy relavant points from each(?) indexed wave to the appropriate folder
	//wavelist to get indexed waves
	//stringfromlist to get items out of list
	//ItemsInList to get number of items in list
	
	//graph things
	
	


End

function testCatch()

	Variable jj = 341
	Variable V_FitError = 0
	try
		BatchRun(-1,jj,0,"") ;// AbortonRTE
	catch
		print("got here")
	endtry
	print V_FitError
end

function calcThetaAlpha()
	//make sure current data folder is pointing to the data series you want to modify
	
	//String currentDir = GetDataFolder(1)
	//SetDataFolder $(currentDir + ":IndexedWaves")
	
	Wave polyLogOrder = :IndexedWaves:polyLogOrder
	Wave temp = :IndexedWaves:temp
	Wave z_fermi =  :IndexedWaves:z_fermi
	Wave amplitude =  :IndexedWaves:amplitude
	Wave xwidth =  :IndexedWaves:xwidth
	Wave ywidth =  :IndexedWaves:ywidth
	Wave tempV =  :IndexedWaves:tempV
	Wave tempH =  :IndexedWaves:tempH
	
	//Check if alpha and theta_alpha indexed waves have been created yet:
	if (WaveExists(:IndexedWaves:alpha)==0)
		New_IndexedWave("alpha",":alpha")
		//Redimension /N=(numpnts( :IndexedWaves:FileNames))  :IndexedWaves:alpha
		Make /O/N=(numpnts( :IndexedWaves:FileNames))  :IndexedWaves:alpha
		Wave alpha =  :IndexedWaves:alpha
		alpha = polyLogOrder + 1
		
		New_IndexedWave("theta_alpha",":theta_alpha")
		//Redimension  /N=(numpnts( :IndexedWaves:FileNames)) :IndexedWaves:theta_alpha
		Make /O/N=(numpnts( :IndexedWaves:FileNames))  :IndexedWaves:theta_alpha
		Wave theta_alpha = :IndexedWaves:theta_alpha
	else
		Wave alpha =  :IndexedWaves:alpha
		Wave theta_alpha = :IndexedWaves:theta_alpha
	endif
	
	//theta_alpha =  (temp*1e-9)*(2*NumPolyLog(alpha-1,-z_fermi) / (-amplitude*xwidth*ywidth*1e-12) )^(1/alpha)
	theta_alpha =  (temp)*(2*NumPolyLog(alpha-1,-z_fermi) / (-amplitude*xwidth*ywidth) )^(1/alpha)
	
end

function getSlopes(maxTemp,makePlots)
	
	Variable maxTemp, makePlots
	
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	Wave polyLogOrder = $(ProjectFolder + ":polyLogBoxTrapAnalysis:polyLogOrder")
	
	
	String savedDataFolder = GetDataFolder(1);
	SetDataFolder $(ProjectFolder + ":polyLogBoxTrapAnalysis")
	Variable numOrders = numpnts(polyLogOrder)
	
	//Make waves to hold fit parameters
	Duplicate /O polyLogOrder $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_slope_boxOn")
	Duplicate /O polyLogOrder $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_offset_boxOn")
	Duplicate /O polyLogOrder $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_chisq_boxOn")
	Duplicate /O polyLogOrder $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_stdev_boxOn")
	Wave fitted_slope_boxOn = $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_slope_boxOn")
	Wave fitted_offset_boxOn = $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_offset_boxOn")
	Wave fitted_chisq_boxOn = $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_chisq_boxOn")
	Wave fitted_stdev_boxOn = $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_stdev_boxOn")
	
	Duplicate /O polyLogOrder $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_slope_boxOff")
	Duplicate /O polyLogOrder $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_offset_boxOff")
	Duplicate /O polyLogOrder $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_chisq_boxOff")
	Duplicate /O polyLogOrder $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_stdev_boxOff")
	Wave fitted_slope_boxOff = $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_slope_boxOff")
	Wave fitted_offset_boxOff = $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_offset_boxOff")
	Wave fitted_chisq_boxOff = $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_chisq_boxOff")
	Wave fitted_stdev_boxOff = $(ProjectFolder + ":polyLogBoxTrapAnalysis:fitted_stdev_boxOff")
	
	Variable ii, index
	String tempStr
	Make /O/N=2 fitCoef
	for (ii = 0 ; ii <numOrders ; ii+=1) //loop through poly log orders
		tempStr = ReplaceString(".",num2str(polyLogOrder[ii]),"_");
		tempStr = ProjectFolder + ":polyLogBoxTrapAnalysis:PL_" + tempStr 
		
		Wave tempWave = $(tempStr + ":BoxOn:temp")
		//print tempWave
		//Find the index corresponding to maxTemp for box on
		FindLevel /Q/P tempWave maxTemp
		if (V_flag == 0)
			index = min( round(V_LevelX), numpnts(tempWave)-1 ) //level was found
		else
			index = numpnts(tempWave)-1 
		endif

		//Fit the box on data, save parameters:
		CurveFit /N/Q /NTHR=0 line kwCWave=fitCoef $(tempStr + ":BoxOn:theta_alpha")[0,index] /X=tempWave
		wave W_sigma = :W_sigma;
		fitted_offset_boxOn[ii] = fitCoef[0]
		fitted_slope_boxOn[ii] = fitCoef[1]
		fitted_chisq_boxOn[ii] = V_chisq
		fitted_stdev_boxOn[ii] = W_sigma[1]
		
		
		//Find the index corresponding to maxTemp for box off
		Wave tempWave = $(tempStr + ":BoxOff:temp")
		FindLevel /Q/P tempWave maxTemp
		if (V_flag == 0)
			index = min( round(V_LevelX), numpnts(tempWave)-1 ) //level was found
		else
			index = numpnts(tempWave)-1 
		endif
		
		//Fit the box off data, save parameters:
		CurveFit /N/Q /NTHR=0 line kwCWave=fitCoef $(tempStr + ":BoxOff:theta_alpha")[0,index] /X=tempWave
		fitted_offset_boxOff[ii] = fitCoef[0]
		fitted_slope_boxOff[ii] = fitCoef[1]
		fitted_chisq_boxOff[ii] = V_chisq
		fitted_stdev_boxOff[ii] = W_sigma[1]

	endfor
	
	if (makePlots == 1)
	
		Display fitted_slope_boxOn vs polyLogOrder
		AppendToGraph fitted_slope_boxOff vs polyLogOrder
		ModifyGraph mode=3,marker(fitted_slope_boxOn)=19 //red circles
		ModifyGraph mode(fitted_slope_boxOff)=3,marker(fitted_slope_boxOff)=16, rgb(fitted_slope_boxOff)=(0,0,65280) //blue squares
		Legend/C/N=text0/A=MC //add legend
		Label left "slope";
		Label bottom "PolyLog Order"
		ModifyGraph zero(left)=2 //add horizontal line at zero slope
	
		Display fitted_chisq_boxOn, fitted_chisq_boxOff vs polyLogOrder
		ModifyGraph mode=3,marker(fitted_chisq_boxOn)=19 //red circles
		ModifyGraph mode(fitted_chisq_boxOff)=3,marker(fitted_chisq_boxOff)=16, rgb(fitted_chisq_boxOff)=(0,0,65280) //blue squares
		Legend/C/N=text0/A=MC //add legend
		Label left "Chi Squared";
		Label bottom "PolyLog Order"
	
		Display fitted_stdev_boxOn, fitted_stdev_boxOff vs polyLogOrder
		ModifyGraph mode=3,marker(fitted_stdev_boxOn)=19 //red circles
		ModifyGraph mode(fitted_stdev_boxOff)=3,marker(fitted_stdev_boxOff)=16, rgb(fitted_stdev_boxOff)=(0,0,65280) //blue squares
		Legend/C/N=text0/A=MC //add legend
		Label left "Std Dev in Slope";
		Label bottom "PolyLog Order"
	
	endif
	
	
	Killwaves fitCoef
	SetDataFolder savedDataFolder
end

function extract1Dslices(startNum,endNum,skipList)
 	Variable startNum, endNum
 	string skipList
 	
 	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
 	String SubDirectory;
 	String tempStr
	
	NewDataFolder /O $(ProjectFolder + ":TOF") //make new data folder
	NVAR TOF =  $(ProjectFolder + ":TOF")

	variable jj
	
	for (jj = startNum ; jj <= endNum; jj+=1) //loop over image numbers
		if(WhichListItem(num2str(jj),skipList,";",0,1)==-1) //only load images not in skipList
			BatchRun(-1,jj,0,"") //load the current image
			
		//	SubDirectory = num2str(TOF*1000)
		//	SubDirectory = ReplaceString(".",SubDirectory,"_")
		//	SubDirectory = ProjectFolder + ":TOF:" + Subdirectory 
		//if (DataFolderExists(SubDirectory) != 1) //if subfolder doesn't exist
		//	NewDataFolder /O SubDirectory
		//endif
			tempStr = ReplaceString(".", num2str(TOF*1000), "_")
			if (WaveExists( $(ProjectFolder + ":TOF:xsec_col_sum_" + tempStr)) !=1)
				//Duplicate xsec_col xsec_col_ + tempStr  //but the right number of points
				//Duplicate xsec_xol xsec_col_sum + tempStr //but the right number of points
				
				//Add entry to
			endif
			
			
			
		endif
	endfor
	
end

function testing()
	Variable centerY = 170.25
	Duplicate /R=(centerY-150,centerY+150) root:Sr_PIXIS_Seq:Fit_Info:xsec_col root:copied2_xsec_col
	
end

function createChiSqWave()
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	New_IndexedWave("fit_chi_sq","chisqVar");
	Wave G3d_confidenceHistory = $(ProjectFolder + ":IndexedWaves:FitWaves:G3d_confidenceHistory")
	Wave fit_chi_sq = $(ProjectFolder + ":IndexedWaves:fit_chi_sq")
	Duplicate /O/R=[][8,8]  G3d_confidenceHistory fit_chi_sq
end

function importImagesISatTest(startNum,endNum,skipList,startAlpha,endAlpha,deltaAlpha)
 	Variable startNum, endNum, startAlpha, endAlpha, deltaAlpha
 	string skipList

	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;

	New_IndexedWave("alphaIsat",":alphaIsat")
	NVAR alpha = :alphaIsat
	variable ii, jj
	
	//Make a new data folder to store the waves created below
	String ISatCalFolder = ProjectFolder + ":ISatCalibration"
	NewDataFolder /O $ISatCalFolder
	
	//Make a wave to hold the alpha values:
	Variable numAlphaVals = round((endAlpha-startAlpha)/deltaAlpha)+1
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":alphaIsat")
	Wave alphaIsatCal =  $(ISatCalFolder + ":alphaIsat")
	
	Variable alphaCount = 0;
	
	Variable numImages = endNum - startNum + 1 - ItemsInList(skipList);
	
	for (ii = startAlpha ; ii < endAlpha+deltaAlpha; ii += deltaAlpha) //loop over alpha values
		alpha = ii
		alphaIsatCal[alphaCount] = ii //save this alpha value
		
		for (jj = startNum ; jj <= endNum; jj+=1) //loop over image numbers
			if(WhichListItem(num2str(jj),skipList,";",0,1)==-1) //only load images not in skipList
				BatchRun(-1,jj,0,"") //load current image
			endif
		endfor
		
		alphaCount +=1
		
	endfor
		
	//Make a wave to hold the std deviation of the atom number
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":absnumStdDev")
	Wave absnumStdDev = $(ISatCalFolder + ":absnumStdDev")
	
	//Make a wave to hold the std deviation of the peak OD
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":amplitudeStdDev")
	Wave amplitudeStdDev = $(ISatCalFolder + ":amplitudeStdDev")
	

	
//	Variable imgIndex = 0
//	alphaCount = 0
//	for (ii = startAlpha ; ii < endAlpha+deltaAlpha; ii += deltaAlpha) //loop over alpha values
//		WaveStats /Q/R=(imgIndex,imgIndex+numImages-1) $(ProjectFolder + ":IndexedWaves:absnum")
//		absnumStdDev[alphaCount] = V_sdev
//		WaveStats /Q/R=(imgIndex,imgIndex + numImages - 1) $(ProjectFolder + ":IndexedWaves:amplitude")
//		amplitudeStdDev[alphaCount] = V_sdev
//		alphaCount += 1
//		imgIndex += numImages -1
//	endfor
//	
//	Display :ISatCalibration:absnumStdDev vs :ISatCalibration:alphaIsat
//	CurveFit/NTHR=0/TBOX=768 gauss  :ISatCalibration:absnumStdDev /X=:ISatCalibration:alphaIsat /D 			
End

Function analyzeIsatCal(numImages,startAlpha,endAlpha,deltaAlpha, plot)
	Variable numImages, startAlpha, endAlpha, deltaAlpha, plot
	
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	
	Variable numAlphaVals = round((endAlpha-startAlpha)/deltaAlpha)+1

	//Make a new data folder to store the waves created below
	String ISatCalFolder = ProjectFolder + ":ISatCalibration"
	NewDataFolder /O $ISatCalFolder
	
	//Make a wave to hold the std deviation of the atom number
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":absnumStdDev")
	Wave absnumStdDev = $(ISatCalFolder + ":absnumStdDev")
	
	//Make a wave to hold the mean of the atom number
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":absnumMean")
	Wave absnumMean = $(ISatCalFolder + ":absnumMean")
	
	//Make a wave to hold the std deviation of the peak OD
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":amplitudeStdDev")
	Wave amplitudeStdDev = $(ISatCalFolder + ":amplitudeStdDev")
	
	//Make a wave to hold the mean of the peak OD
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":amplitudeMean")
	Wave amplitudeMean = $(ISatCalFolder + ":amplitudeMean")
	
	//Make a wave to hold the probe powers
	Duplicate /O /R=(0,numImages-1) $(ProjectFolder + ":IndexedWaves:ProbePow") $(ISatCalFolder + ":ProbePow")
	Wave probePow =  $(ISatCalFolder + ":ProbePow")
	
	//Make waves to hold fit parameters
	Make /O/N=(numAlphaVals) $(ISatCalFolder + ":absnum_slope")
	Wave absnum_slope = $(ISatCalFolder + ":absnum_slope")
	Make /O/N=(numAlphaVals) $(ISatCalFolder + ":amplitude_slope")
	Wave amplitude_slope = $(ISatCalFolder + ":amplitude_slope")

	Variable imgIndex = 0
	Variable alphaCount = 0
	Variable ii
	String tempStr
	Make /O/N=2 fitCoef
	for (ii = startAlpha ; ii < endAlpha+deltaAlpha; ii += deltaAlpha) //loop over alpha values
		WaveStats /Q/R=(imgIndex,imgIndex+numImages-1) $(ProjectFolder + ":IndexedWaves:absnum")
		absnumStdDev[alphaCount] = V_sdev
		absnumMean[alphaCount] = V_avg
		WaveStats /Q/R=(imgIndex,imgIndex + numImages - 1) $(ProjectFolder + ":IndexedWaves:amplitude")
		amplitudeStdDev[alphaCount] = V_sdev
		amplitudeMean[alphaCount] = V_avg
		
		//Make wave for the absnum and amplitudes at various alpha values
		tempStr = ReplaceString(".",num2str(ii),"_");
		Duplicate /O /R=(imgIndex,imgIndex+numImages-1) $(ProjectFolder + ":IndexedWaves:absnum") $(ISatCalFolder + ":absnum_" + tempStr) 
		Duplicate /O /R=(imgIndex,imgIndex+numImages-1) $(ProjectFolder + ":IndexedWaves:amplitude") $(ISatCalFolder + ":amplitude_" + tempStr) 
		Wave temp_absnum = $(ISatCalFolder + ":absnum_" + tempStr)
		Wave temp_amplitude = $(ISatCalFolder + ":amplitude_" + tempStr)
		print imgIndex
		print imgIndex + numImages - 1
		//Generate slopes of absnum and amplitude as a function of ProbePow:
		CurveFit /N/Q /NTHR=0 line kwCWave=fitCoef temp_absnum /X=probePow
		//wave W_sigma = :W_sigma;
		absnum_slope[alphaCount] = fitCoef[1]
		
		CurveFit /N/Q /NTHR=0 line kwCWave=fitCoef temp_amplitude /X=probePow
		//wave W_sigma = :W_sigma;
		amplitude_slope[alphaCount] = fitCoef[1]
	
		alphaCount += 1
		imgIndex += numImages 
	endfor
	
	if (plot == 1)
		Display absnumStdDev vs :ISatCalibration:alphaIsat
		AppendToGraph/R absnum_slope vs :ISatCalibration:alphaIsat
		ModifyGraph mode(absnumStdDev)=3
		ModifyGraph mode(absnum_slope)=3,marker(absnum_slope)=8;
		ModifyGraph useMrkStrokeRGB(absnum_slope)=1;
		ModifyGraph mrkStrokeRGB(absnum_slope)=(0,0,52224)
		ModifyGraph zero(right)=1
		Label left "Atom Number Std Dev"
		Label bottom "Alpha"
		Label right "Atom Number Slope"
		CurveFit/NTHR=0/TBOX=768 gauss  absnumStdDev /X=:ISatCalibration:alphaIsat /D 	
		
		Display amplitudeStdDev vs :ISatCalibration:alphaIsat
		AppendToGraph/R amplitude_slope vs :ISatCalibration:alphaIsat
		ModifyGraph mode(amplitudeStdDev)=3
		ModifyGraph mode(amplitude_slope)=3,marker(amplitude_slope)=8;
		ModifyGraph useMrkStrokeRGB(amplitude_slope)=1;
		ModifyGraph mrkStrokeRGB(amplitude_slope)=(0,0,52224)
		ModifyGraph zero(right)=1
		Label left "Peak OD Std Dev"
		Label bottom "Alpha"
		Label right "Peak OD Slope"
		CurveFit/NTHR=0/TBOX=768 gauss  amplitudeStdDev /X=:ISatCalibration:alphaIsat /D 
	endif
	
end
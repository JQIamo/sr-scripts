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
		
		//Check if there are boxOff shots:
		FindValue /V=0 /T=0.1 /S=(startNum) $(ProjectFolder + ":IndexedWaves:boxOn")
		If (V_Value == startNum)
			//yes there are boxOff shots
			NewDataFolder /O $(tempStr + ":BoxOff")
			FindValue /V=1 /T=0.1 /S=(startNum) $(ProjectFolder + ":IndexedWaves:boxOn") //find start of boxOn images
			
			if (V_Value == -1)
				//there are no boxOn images
				endNum = startNum +numImages[ii] -1;
			else
				endNum= min(V_Value-1,startNum + numImages[ii] - 1);
			endif
			
			//Copy boxOff data:
			for (jj = 0; jj <indWavesNum; jj +=1) //loop through each indexed wave
				currIndWave = StringFromList(jj,indWavesList);
				Duplicate /O/R=(startNum,endNum) $(ProjectFolder + ":IndexedWaves:" + currIndWave) $(tempStr + ":BoxOff:" + currIndWave)
			endfor
		endif
			
		//check if there are boxOn shots:
		FindValue /V=1 /T=0.1 /S=(startNum) $(ProjectFolder + ":IndexedWaves:boxOn")
		if (V_Value >= startNum && V_Value <= (startNum + numImages[ii] -1))
			//yes there are boxOn shots
			NewDataFolder /O $(tempStr + ":BoxOn")
			//Copy boxOff data:
			for (jj = 0; jj <indWavesNum; jj +=1) //loop through each indexed wave
				currIndWave = StringFromList(jj,indWavesList);
				Duplicate /O/R=(V_Value,startNum + numImages[ii] - 1) $(ProjectFolder + ":IndexedWaves:" + currIndWave) $(tempStr + ":BoxOn:" + currIndWave)
			endfor
		endif				
		
		//Duplicate /O/R=(startNum,startNum+numImages[ii]-1) $(ProjectFolder + ":IndexedWaves:" + currIndWave) $(tempStr + ":" + currIndWave)
		
		startNum += numImages[ii]		
	endfor
	
	SetDataFolder savedDataFolder
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
	
	Variable sigma
	sigma=3*lambda^2/(2*pi) ;
	//theta_alpha =  (temp*1e-9)*(2*NumPolyLog(alpha-1,-z_fermi) / (-amplitude*xwidth*ywidth*1e-12) )^(1/alpha)
	theta_alpha =  (temp)*(2*sigma*NumPolyLog(alpha-1,-z_fermi) / (-amplitude*xwidth*ywidth) )^(1/alpha)
	
	
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
		
		if (DataFolderExists(tempStr + ":BoxOn"))
			
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
		endif
		
		if (DataFolderExists(tempStr + ":BoxOff"))
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
			//fitted_stdev_boxOff[ii] = W_sigma[1]
		endif

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
	
	Variable sliceWidth = 100;
	
	NewDataFolder /O $(ProjectFolder + ":TOF") //make new data folder
	NVAR TOF =  $(ProjectFolder + ":TOF")
	
	Make /N=0/O $(ProjectFolder + ":TOF:times") //make wave to store various times of flight
	Make /N=0/O $(ProjectFolder + ":TOF:numImages") //make wave to store number of images at each TOF
	Wave times = $(ProjectFolder + ":TOF:times")
	Wave numImages = $(ProjectFolder + ":TOF:numImages")
	
	
	variable jj
	variable index
	
	for (jj = startNum ; jj <= endNum; jj+=1) //loop over image numbers
		if(WhichListItem(num2str(jj),skipList,";",0,1)==-1) //only load images not in skipList
			BatchRun(-1,jj,0,"") //load the current image
			
			SubDirectory = num2str(TOF*1000)
			SubDirectory = ReplaceString(".",SubDirectory,"_")
			SubDirectory = ProjectFolder + ":TOF:" + "TOF_" + Subdirectory 
		if (DataFolderExists(SubDirectory) != 1) //if subfolder doesn't exist
			NewDataFolder /O $SubDirectory
		endif
		
		FindValue /T=0.01 /V=(TOF*1000) times //find the TOF value in the times wave
		
		if (V_value == -1) //check if the TOF value was found
			//if not, add it and add entry to the numImages wave
			index = numpnts(times);
			Redimension /N=(numpnts(times)+1) times
			times[index] = TOF*1000
			
			Redimension /N=(numpnts(numImages)+1) numImages
			numImages[index] = 1
		else
			index = V_value
			numImages[index] += 1
		endif
		
		//NVAR centerY = $(ProjectFolder + ":yposition") //for PIXIS
		NVAR centerY = $(ProjectFolder + ":xposition")
		//Wave xsec_col = $(ProjectFolder + ":Fit_Info:xsec_col") //for PIXIS
		Wave xsec_col = $(ProjectFolder + ":Fit_Info:xsec_row") //for H Imaging
		
		
		Duplicate /O/R=(centerY-sliceWidth,centerY+sliceWidth) xsec_col $(SubDirectory + ":xsec_col_copy"+ num2str(numImages[index]))
		
//			tempStr = ReplaceString(".", num2str(TOF*1000), "_")
//			if (WaveExists( $(ProjectFolder + ":TOF:xsec_col_sum_" + tempStr)) !=1)
//				//Duplicate xsec_col xsec_col_ + tempStr  //but the right number of points
//				//Duplicate xsec_xol xsec_col_sum + tempStr //but the right number of points
//				
//				//Add entry to
//			endif
			
			
			
		endif
	endfor
	
	variable t, ii;
	for (jj = 0; jj < numpnts(times) ; jj +=1) //loop through subdirectories
		t = times[jj]
		SubDirectory = ProjectFolder + ":TOF:" + "TOF_" +  ReplaceString(".",num2str(t),"_")
		
		Duplicate /O $(SubDirectory + ":xsec_col_copy1") $(SubDirectory + ":xsec_col_avg")
		Wave xsec_col_avg = $(SubDirectory + ":xsec_col_avg")
		xsec_col_avg = 0
		for (ii = 1; ii < numImages[jj]+1 ; ii += 1)
			Wave tempWv = $(SubDirectory + ":xsec_col_copy" + num2str(ii)) 
			xsec_col_avg += tempWv
		endfor
		xsec_col_avg = xsec_col_avg/numImages[jj]
		Duplicate /O xsec_col_avg $(ProjectFolder + ":TOF:xsec_col_avg_" + ReplaceString(".",num2str(t),"_"))
		SetScale /I x,  -sliceWidth, sliceWidth, $(ProjectFolder + ":TOF:xsec_col_avg_" + ReplaceString(".",num2str(t),"_"))
	endfor
end

function testing()
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	
	Variable t, jj;
	Wave times = $(ProjectFolder + ":TOF:times")
	String SubDirectory;
	
	for (jj = 0; jj < numpnts(times) ; jj +=1) //loop through subdirectories
		t = times[jj]
		SubDirectory = ProjectFolder + ":TOF:" + "TOF_" +  ReplaceString(".",num2str(t),"_")
		Duplicate /O $(SubDirectory + ":xsec_col_avg") $(ProjectFolder + ":TOF:xsec_col_avg_" + ReplaceString(".",num2str(t),"_"))
		SetScale /I x,  -150, 150, $(ProjectFolder + ":TOF:xsec_col_avg_" + ReplaceString(".",num2str(t),"_"))
	endfor
	
end

Function MakeTOFMovie()
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	Wave times = $(ProjectFolder + ":TOF:boxOn:times")
	String SubDirectory, timeLabel;
	Variable t, jj, m;
	
	Variable normalize = 1;
	
	Make /O movieWave
	
	Display /N=MovieGraph movieWave
	Label /W=MovieGraph left "Optical Depth"
	Label /W=MovieGraph bottom "Distance (um)"
	SetAxis left 0,1.1
	
	String movieName = "BEC_box_expansion.avi"
	NewMovie /F=1/L/O as movieName
	
//	WaveStats /Q times
//	for (jj = V_min; jj <= V_max; jj += (V_max-V_min)/(V_npnts-1))
//		Duplicate /O $(ProjectFolder + ":TOF:xsec_col_avg_" + ReplaceString(".",num2str(jj),"_")) movieWave
//		DoUpdate
//		AddMovieFrame
//	endfor
	
	Duplicate /O/Free times sortedTimes;
	Sort sortedTimes, sortedTimes
	
	for (jj = 0; jj < numpnts(sortedTimes); jj +=1)
		t = sortedTimes[jj]
		Duplicate /O $(ProjectFolder + ":TOF:boxOn:xsec_row_avg_" + ReplaceString(".",num2str(t),"_")) movieWave
		if (normalize == 1)
			m = wavemax(movieWave)
			movieWave/= m
		endif
		timeLabel = "t = " + num2str(t) + " ms"
		TextBox/C/N=text0_1/A=MC/X=33.18/Y=27.96 timeLabel
		DoUpdate
		AddMovieFrame
	endfor

	
	CloseMovie
	Killwindow MovieGraph
	Killwaves movieWave
	
end

function extract1DslicesV2(startNum,endNum,skipList)
 	Variable startNum, endNum
 	string skipList
 	
 	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
 	String SubDirectory;
 	String tempStr
	
	Variable sliceWidth = 100;
	
	NewDataFolder /O $(ProjectFolder + ":TOF") //make new data folder
	NVAR TOF =  $(ProjectFolder + ":TOF")
	NVAR boxOn = $(ProjectFolder + ":boxOn")
	SVAR ImageDirection = $(ProjectFolder + ":Experimental_Info:ImageDirection")
	
	if (stringmatch(ImageDirection,"XY"))
		NVAR centerX = $(ProjectFolder + ":xposition") //for PIXIS
		NVAR centerY = $(ProjectFolder + ":yposition") //for PIXIS
	elseif (stringmatch(ImageDirection,"XZ"))
		NVAR centerX = $(ProjectFolder + ":xposition") //for Flea
		NVAR centerY = $(ProjectFolder + ":zposition") //for Flea
	endif
		
	Wave xsec_col = $(ProjectFolder + ":Fit_Info:xsec_col") 
	Wave xsec_row = $(ProjectFolder + ":Fit_Info:xsec_row") 
	
	//Make subfolders
	NewDataFolder /O /O $(ProjectFolder + ":TOF:boxOn")
	NewDataFolder /O /O $(ProjectFolder + ":TOF:boxOff")
	
	//Make waves to store the various times and number of images at each TOF:
	Make /N=0/O $(ProjectFolder + ":TOF:boxOn:times") //make wave to store various times of flight
	Make /N=0/O $(ProjectFolder + ":TOF:boxOn:numImages") //make wave to store number of images at each TOF
	Make /N=0/O $(ProjectFolder + ":TOF:boxOff:times") //make wave to store various times of flight
	Make /N=0/O $(ProjectFolder + ":TOF:boxOff:numImages") //make wave to store number of images at each TOF
	
	Wave times = $(ProjectFolder + ":TOF:boxOn:times")
	Wave numImages = $(ProjectFolder + ":TOF:boxOn:numImages")
	
	
	variable jj
	variable index
	
	for (jj = startNum ; jj <= endNum; jj+=1) //loop over image numbers
		if(WhichListItem(num2str(jj),skipList,";",0,1)==-1) //only load images not in skipList
			BatchRun(-1,jj,0,"") //load the current image
			
			if (boxOn == 1)
				SubDirectory = ProjectFolder + ":TOF:boxOn"
				Wave times = $(ProjectFolder + ":TOF:boxOn:times")
				Wave numImages = $(ProjectFolder + ":TOF:boxOn:numImages")
			else
				SubDirectory = ProjectFolder + ":TOF:boxOff"
				Wave times = $(ProjectFolder + ":TOF:boxOff:times")
				Wave numImages = $(ProjectFolder + ":TOF:boxOff:numImages")
			endif
			
			SubDirectory = SubDirectory + ":TOF_" + ReplaceString(".",num2str(TOF*1000),"_")
			
			//SubDirectory = num2str(TOF*1000)
			//SubDirectory = ReplaceString(".",SubDirectory,"_")
			//SubDirectory = ProjectFolder + ":TOF:" + "TOF_" + Subdirectory 
			if (DataFolderExists(SubDirectory) != 1) //if subfolder doesn't exist
				NewDataFolder /O $SubDirectory
			endif
		
			FindValue /T=0.01 /V=(TOF*1000) times //find the TOF value in the times wave
		
			if (V_value == -1) //check if the TOF value was found
				//if not, add it and add entry to the numImages wave
				index = numpnts(times);
				Redimension /N=(numpnts(times)+1) times
				times[index] = TOF*1000
			
				Redimension /N=(numpnts(numImages)+1) numImages
				numImages[index] = 1
			else
				//TOF value was found
				index = V_value
				numImages[index] += 1
			endif
		
			//NVAR centerY = $(ProjectFolder + ":yposition") //for PIXIS
			//NVAR centerY = $(ProjectFolder + ":xposition")
		
			//copy the cross sections
			Duplicate /O/R=(centerY-sliceWidth,centerY+sliceWidth) xsec_col $(SubDirectory + ":xsec_col_copy"+ num2str(numImages[index]))
			Duplicate /O/R=(centerX-sliceWidth,centerX+sliceWidth) xsec_row $(SubDirectory + ":xsec_row_copy"+ num2str(numImages[index]))
			
			
		endif
	endfor
	
	variable t, ii, kk;
	String basePath;
	for (kk = 0; kk < 2 ; kk += 1)//loop through boxOn, boxOff cases
		if (kk==0)
			//boxOn case
			basePath = ProjectFolder + ":TOF:boxOn"
			Wave times = $(ProjectFolder + ":TOF:boxOn:times")
			Wave numImages = $(ProjectFolder + ":TOF:boxOn:numImages")
		else
			//boxOff case
			basePath = ProjectFolder + ":TOF:boxOff"
			Wave times = $(ProjectFolder + ":TOF:boxOff:times")
			Wave numImages = $(ProjectFolder + ":TOF:boxOff:numImages")
		endif
		
		for (jj = 0; jj < numpnts(times) ; jj +=1) //loop through subdirectories
			t = times[jj]
			SubDirectory = basePath + ":TOF_" +  ReplaceString(".",num2str(t),"_")
			
			Duplicate /O $(SubDirectory + ":xsec_col_copy1") $(SubDirectory + ":xsec_col_avg")
			Duplicate /O $(SubDirectory + ":xsec_row_copy1") $(SubDirectory + ":xsec_row_avg")
			
			Wave xsec_col_avg = $(SubDirectory + ":xsec_col_avg")
			Wave xsec_row_avg = $(SubDirectory + ":xsec_row_avg")
			xsec_col_avg = 0
			xsec_row_avg = 0
			for (ii = 1; ii < numImages[jj]+1 ; ii += 1)
				Wave tempWv = $(SubDirectory + ":xsec_col_copy" + num2str(ii)) 
				xsec_col_avg += tempWv
				Wave tempWv = $(SubDirectory + ":xsec_row_copy" + num2str(ii)) 
				xsec_row_avg += tempWv
			endfor
			xsec_col_avg = xsec_col_avg/numImages[jj]
			xsec_row_avg = xsec_row_avg/numImages[jj]
			
			Duplicate /O xsec_col_avg $(basePath + ":xsec_col_avg_" + ReplaceString(".",num2str(t),"_"))
			Duplicate /O xsec_row_avg $(basePath + ":xsec_row_avg_" + ReplaceString(".",num2str(t),"_"))
			
			SetScale /I x,  -sliceWidth, sliceWidth, $(basePath + ":xsec_col_avg_" + ReplaceString(".",num2str(t),"_"))
			SetScale /I x,  -sliceWidth, sliceWidth, $(basePath + ":xsec_row_avg_" + ReplaceString(".",num2str(t),"_"))
			
		endfor
	endfor
end

function createChiSqWave()
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	New_IndexedWave("fit_chi_sq","chisqVar");
	Wave G3d_confidenceHistory = $(ProjectFolder + ":IndexedWaves:FitWaves:G3d_confidenceHistory")
	Wave fit_chi_sq = $(ProjectFolder + ":IndexedWaves:fit_chi_sq")
	Duplicate /O/R=[][8,8]  G3d_confidenceHistory fit_chi_sq
end

function generateFakePolyLogData(startTemp,endTemp,deltaTemp,startAlpha,endAlpha)
	Variable startTemp, endTemp, deltaTemp, startAlpha, endAlpha;

	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	
	// References to 
	wave xsec_row = $(ProjectFolder + ":Fit_Info:xsec_row")
	wave xsec_col = $(ProjectFolder + ":Fit_Info:xsec_col")
	wave optdepth = $(ProjectFolder + ":optdepth");
	Wave fit_optdepth = $(ProjectFolder + ":Fit_Info:fit_optdepth")
	Wave res_optdepth = $(ProjectFolder + ":Fit_Info:res_optdepth")
	
	NVAR mass=:Experimental_Info:mass
	NVAR expand_time=:Experimental_Info:expand_time //TOF in ms
	Variable sigma = 3*lambda^2/(2*pi)
	//Setup parameters for fake data from a 3D harmonic trap:
	Variable omegaBar = 2*pi*50;
	Variable temp = startTemp //nK
	
	Variable width = 1e6*sqrt(2*kB*temp*1e-9/mass)*expand_time*1e-3*sqrt( (1+(omegaBar*expand_time*1e-3)^2) / (omegaBar*expand_time*1e-3)^2 ) //um
	
	Variable PLord =2;
	Variable alpha = PLord + 1;
	
	Variable startingTTf = 0.4 
	Variable startingNum = (kB*temp/(startingTTf*hbar*omegaBar))^3*10/6;
	Variable startingFugacity = calcFugacity(startingTTf);
	Variable startingAmp = startingNum*NumPolyLog(PLord,-startingFugacity)*sigma/(2*pi*width^2*NumPolyLog(alpha,-startingFugacity));
	
	
	
	
	//Variable fugacity = 3
	//Variable PLord =0.5
	
	//For 2D PolyLog Testing
	Make/O/D/N=8 temp_params;
	temp_params[0] = 0; //offset
	temp_params[1] = startingAmp; //amplitude
	temp_params[2] = 17.3; //center X
	temp_params[3] =width/sqrt(2); //width X
	temp_params[4] = 205; //center Y
	temp_params[5] = width/sqrt(2); //width Y
	temp_params[6] = startingFugacity; //fugacity
	temp_params[7] = PLord; //PolyLog order
	
	
	NVAR PolyLogOrd = :PolyLogOrderVar
	variable ii, jj
	Variable num
	
	for (jj = startTemp ; jj <= endTemp; jj+=deltaTemp) //loop over image numbers
			
		PolyLogOrd=startAlpha;
		
		//temp_params[1] = 2000*NumPolyLog(PLord,-fugacity)/(NumPolyLog(PLord+1,-fugacity)*(jj/sqrt(2))^2); //scale amplitude to keep atom number constant;
		num	 = startingNum*(jj/startTemp)^alpha; //number ~ T^alpha, this assumes constant fugacity which can't be quite right
		width = 1e6*sqrt(2*kB*jj*1e-9/mass)*expand_time*1e-3*sqrt( (1+(omegaBar*expand_time*1e-3)^2) / (omegaBar*expand_time*1e-3)^2 ) //um
		
		temp_params[1] = num*NumPolyLog(PLord,-startingFugacity)*sigma/(2*pi*width^2*NumPolyLog(alpha,-startingFugacity));
		temp_params[3] = width/sqrt(2); //width X
		temp_params[5] = width/sqrt(2); //width Y
			
		optdepth =ArbPolyLogFit2D(temp_params,x,y)//+gnoise(.1,2);
		xsec_row =  ArbPolyLogFit2D(temp_params,x,0)//+gnoise(.1,2);
		xsec_col = ArbPolyLogFit2D(temp_params,0,x)//+gnoise(.1,2);
		fit_optdepth = optdepth
		res_optdepth = optdepth
		
		for (ii = startAlpha ; ii < endAlpha+0.1 ; ii += 0.1) //Loop over polylog orders
			PolyLogOrd = ii-1;
			refit("");
		endfor

	endfor
end

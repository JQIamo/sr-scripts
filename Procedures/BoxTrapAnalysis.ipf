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
	Sort_IndexedWaves(ProjectFolder,"polyLogOrder;boxOn",2)
	
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
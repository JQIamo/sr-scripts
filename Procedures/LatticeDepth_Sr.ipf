#pragma rtGlobals=1		// Use modern global access method.

function Scattering_Depth_Calibration(startNum,endNum,skipList, numDiffOrders)
	//Make sure batchrun base path has already been set
	variable startNum;
	variable endNum;
	string skipList;
	variable numDiffOrders;
	
	variable numImages = endNum-startNum + 1 - ItemsInList(skipList);
	
	// Get the current path
	//String ProjectFolder = Activate_Top_ColdAtomInfo();
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	//Initialize variable to store which order we're fitting:
	Variable/G $(ProjectFolder + ":diffractedOrder") = nan;
	
	New_IndexedWave("diffractedOrder", ":diffractedOrder");
	
	
	string ROI_name = "P" + num2str(numDiffOrders) + "_L"; 
	string ss;
	variable ii, jj;
	
	for (jj = startNum ; jj <= endNum; jj+=1) //loop over image numbers
		if(WhichListItem(num2str(jj),skipList,";",0,1)==-1) //only load images not in skipList
			BatchRun(-1,jj,0,"")
			dec_update("") //This decrements the fit that is done automatically with BatchRun - this could be optimized to use this auto-fit but for now it's simpler
			for(ii = numDiffOrders*(-1); ii <= numDiffOrders;ii+=1)	//loop over ROIs
				//Build ROI name:
				if (ii < 0)
					ss = "_L"
				elseif (ii == 0)
					ss = ""
				elseif (ii>0)
					ss = "_R"
				endif
				ROI_name = "P" + num2str(abs(ii)) + ss 
	
				LoadROI(ROI_name);
				Variable /G $(ProjectFolder + ":diffractedOrder") = ii;
		
				refit("");
			endfor		
		endif
	endfor					
	
	//Sort by diffracted order and pulse time:			
	Sort_IndexedWaves(ProjectFolder,"diffractedOrder;pulseLatT",2)		

end

function Scattering_Depth_Sorting()
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	Variable numImages = 25;
	variable numDiffOrders =3;
	
	
	Sort_IndexedWaves(ProjectFolder,"diffractedOrder;pulseLatT",2)
	
	NewDataFolder /O $(ProjectFolder + ":LatticePulseCal")
	Duplicate /O /R=(0,numImages-1) $(ProjectFolder + ":IndexedWaves:pulseLatT") $(ProjectFolder + ":LatticePulseCal:pulseLatT")
	Make /O /N=(numImages) totalAtomNumber =0  //Make wave to track total atom number
	Wave tempWave;
	variable order; //the lattice peak order
	variable i =0; //initialize loop counter
	String tempString;
	for (order = numDiffOrders*(-1); order <= numDiffOrders; order+=1) //loop over diffraction orders and grab the appropriate ranges of atom number
		if (order<0)
			tempString = num2str(abs(order)) + "_L"
		elseif (order==0)
			tempString = "0"
		elseif (order>0)
			tempString = num2str(order) + "_R"
		endif
		
		Duplicate /O /R=(0 + i*numImages, numImages*(1+i)-1) $(ProjectFolder + ":IndexedWaves:absnum") $(ProjectFolder + ":LatticePulseCal:num_" + tempString)
		Duplicate /O /R=(0 + i*numImages, numImages*(1+i)-1) $(ProjectFolder + ":IndexedWaves:absnum") tempWave 
		totalAtomNumber += tempWave
		i+=1
	endfor
	Duplicate /O totalAtomNumber $(ProjectFolder + ":LatticePulseCal:totalNum")
	
	for (order = numDiffOrders*(-1); order <= numDiffOrders; order+=1) //loop over diffraction orders and calculate the population in various orders
		if (order<0)
			tempString = num2str(abs(order)) + "_L"
		elseif (order==0)
			tempString = "0"
		elseif (order>0)
			tempString = num2str(order) + "_R"
		endif
		
		Duplicate /O  $(ProjectFolder + ":LatticePulseCal:num_" + tempString) tempWave
		Make /O /N=(numImages)  $(ProjectFolder + ":LatticePulseCal:pop_" + tempString) = tempWave/totalAtomNumber;
	endfor
	
	//Cleanup:
	KillWaves totalAtomNumber, tempWave
	
end
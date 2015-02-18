#pragma rtGlobals=1		// Use modern global access method.

Function DataSorter(Ydata, Xdata,yBaseName,xBaseName)

	wave Ydata, Xdata //data to be sorted
	string yBaseName, xBaseName //base names for resulting waves
	
	//mask the data
	duplicate/FREE/D Ydata, ydTemp
	duplicate/FREE/D Xdata, xdTemp
	
	//sort Ydata and Xdata by Xdata
	sort xdTemp, xdTemp, ydTemp
	
	//Make waves to store results using basename
	Make/O/D/N=1 $(xBaseName + "_Vals")/WAVE=xVals
	Make/O/D/N=1 $(yBaseName + "_Avg")/WAVE=yAvg
	Make/O/D/N=1 $(yBaseName + "_SD")/WAVE=ySD
	Variable numXvals = 1
	Variable i
	Variable prev = -1
	
	//populate results waves
	For(i=0; i < numpnts(xdTemp); i+=1)
		
		If(xdTemp[i]!=xdTemp[i+1])
		
			xVals[numXvals-1] = xdTemp[i]
			InsertPoints numXvals, 1, xVals
			Make/N=(i-prev)/O/D $("dataPnt" + num2str(numXvals))/WAVE=ref
			ref[0,i-prev-1] = ydTemp[prev+p+1]
			WaveStats/Q/Z/M=2 ref
			yAvg[numXvals-1] = V_avg
			InsertPoints numXvals, 1, yAvg
			ySD[numXvals-1] = V_sdev
			InsertPoints numXvals, 1, ySD
			prev = i
			numXvals += 1
			KillWaves ref
			
		endif
		
	endfor
	
	//don't forget the last point
	xVals[numXvals-1] = xdTemp[i-1]
	Make/N=(i-prev-1)/O/D $("dataPnt" + num2str(numXvals))/WAVE=ref
	ref[0,i-prev-1] = ydTemp[prev+p+1]
	WaveStats/Q/Z/M=2 ref
	yAvg[numXvals-1] = V_avg
	ySD[numXvals-1] = V_sdev
	KillWaves ref
	
	//Duplicate the raw sorted data for future use
	//Duplicate/O xdTemp, $(xBaseName + "_sorted")
	//Duplicate/O ydTemp, $(yBaseName + "_sorted")
	
	//check that the procedure is correctly extracting X values
	//print numXvals
	
End

function Dialog_DataSortXYWaves()
	
	variable TargProjectNum;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
	
	Prompt TargProjectNum, "Source Data Series:", popup, ActivePaths
	DoPrompt "Process Data", TargProjectNum
	
	if(V_Flag)
		return -1		// User canceled
	endif
	
	String TargPath = StringFromList(TargProjectNum-1, ActivePaths)
		
	String SavePanel = CurrentPanel
	String SavePath = CurrentPath
	String fldrSav= GetDataFolder(1)
		
	Set_ColdAtomInfo(TargPath)
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	SetDataFolder ProjectFolder;
	
	SetDataFolder :IndexedWaves;
	string ListofWaves = WaveList("*",";","");
	
	variable Xtarg, Ytarg
	string Xbase, Ybase
	Prompt Xtarg, "Target X wave:", popup, ListofWaves
	Prompt Xbase, "Processed X wave name:"
	Prompt Ytarg, "Target Y wave:", popup, ListofWaves
	Prompt Ybase, "Processed Y wave name:"
	DoPrompt "Process Data", Xtarg, Xbase, Ytarg, Ybase
	
	if(V_Flag)
		Set_ColdAtomInfo(SavePath)
		SetDataFolder fldrSav
		return -1		// User canceled
	endif
	
	string Xwave = StringFromList(Xtarg-1, ListofWaves);
	string Ywave = StringFromList(Ytarg-1, ListofWaves);
	wave Xdata = :$Xwave;
	wave Ydata = :$Ywave;
	
	string temp = CleanupName(Xbase, 0);
	Xbase = temp;
	temp = CleanupName(Ybase, 0);
	Ybase = temp;
	
	DataSorter(Ydata, Xdata, Ybase, Xbase);
	
	Set_ColdAtomInfo(SavePath)
	SetDataFolder fldrSav
end

//This function is similar to DataSorter, but it averages both X and Y by a specified X bin size
Function BinnedDataSorter(Ydata, Xdata,yBaseName,xBaseName, BinSize, BinMeth)

	wave Ydata, Xdata //data to be sorted
	string yBaseName, xBaseName //base names for resulting waves
	variable BinSize, BinMeth //size of averaging bin in units of Xdata
	
	//mask the data
	duplicate/FREE/D Ydata, ydTemp
	duplicate/FREE/D Xdata, xdTemp
	
	//sort Ydata and Xdata by Xdata
	sort xdTemp, xdTemp, ydTemp
	
	//Make waves to store results using basename
	Make/O/D/N=1 $(xBaseName + "_Vals")/WAVE=xVals
	Make/O/D/N=1 $(xBaseName + "_bCntrs")/WAVE=xCntrs
	Make/O/D/N=1 $(xBaseName + "_SD")/WAVE=xSD
	Make/O/D/N=1 $(yBaseName + "_Avg")/WAVE=yAvg
	Make/O/D/N=1 $(yBaseName + "_SD")/WAVE=ySD
	Variable numXvals = 1
	Variable i
	Variable prev = 0
	Variable numBins = 1
	Variable DeltaBins
	
	//populate results waves
	if(BinMeth==3)
	
		For(i=0; i < numpnts(xdTemp); i+=1)
		
			If(xdTemp[i]>(xdTemp[0]+BinSize*NumBins))
				//make the bin that we've just stepped out of
				//handle x data
				Make/N=(i-prev)/O/D $("XdataPnt" + num2str(numXvals))/WAVE=xref
				xref[0,i-prev-1] = xdTemp[prev+p]
				WaveStats/Q/Z/M=2 xref
				xVals[numXvals-1] = V_avg
				InsertPoints numXvals, 1, xVals
				xSD[numXvals-1] = V_sdev
				InsertPoints numXvals, 1, xSD
				xCntrs[numXvals-1]=xdTemp[0]+BinSize*(2*numBins-1)/2
				InsertPoints numXvals, 1, xCntrs
				//handle y data
				Make/N=(i-prev)/O/D $("YdataPnt" + num2str(numXvals))/WAVE=yref
				yref[0,i-prev-1] = ydTemp[prev+p]
				WaveStats/Q/Z/M=2 yref
				yAvg[numXvals-1] = V_avg
				InsertPoints numXvals, 1, yAvg
				ySD[numXvals-1] = V_sdev
				InsertPoints numXvals, 1, ySD
			
				numXvals += 1
				//use deltabins to correctly populate empty bins
				DeltaBins = Ceil((xdTemp[i] - xdTemp[0] - BinSize*numBins)/BinSize)
				if(DeltaBins>1)
					variable j
					for(j=1;j<(DeltaBins);j+=1)
					
						xCntrs[numXvals-1]=xdTemp[0]+BinSize*(2*(numBins+j)-1)/2
						xVals[numXvals-1] = xCntrs[numXvals-1]
						InsertPoints numXvals, 1, xCntrs
						InsertPoints numXvals, 1, xVals
						xSD[numXvals-1] = NaN
						InsertPoints numXvals, 1, xSD
						
						yAvg[numXvals-1] = NaN
						InsertPoints numXvals, 1, yAvg
						ySD[numXvals-1] = NaN
						InsertPoints numXvals, 1, ySD
					
					endfor
				endif
				numBins += DeltaBins
				//prev is the first point in the (numBins)th bin
				prev = i
				KillWaves xref, yref
			
			endif
		
		endfor
	
	elseif(BinMeth==2)
	
		For(i=0; i < numpnts(xdTemp); i+=1)
		
			If(abs(xdTemp[i]-xdTemp[i-1])>(BinSize))
				//make the bin that we've just stepped out of
				//handle x data
				Make/N=(i-prev)/O/D $("XdataPnt" + num2str(numXvals))/WAVE=xref
				xref[0,i-prev-1] = xdTemp[prev+p]
				WaveStats/Q/Z/M=2 xref
				xVals[numXvals-1] = V_avg
				InsertPoints numXvals, 1, xVals
				xSD[numXvals-1] = V_sdev
				InsertPoints numXvals, 1, xSD
				//handle y data
				Make/N=(i-prev)/O/D $("YdataPnt" + num2str(numXvals))/WAVE=yref
				yref[0,i-prev-1] = ydTemp[prev+p]
				WaveStats/Q/Z/M=2 yref
				yAvg[numXvals-1] = V_avg
				InsertPoints numXvals, 1, yAvg
				ySD[numXvals-1] = V_sdev
				InsertPoints numXvals, 1, ySD
			
				numXvals += 1
				//use deltabins to correctly skip over empty bins
				DeltaBins = Ceil((xdTemp[i] - xdTemp[0] - BinSize*numBins)/BinSize)
				numBins += DeltaBins
				//prev is the first point in the (numBins)th bin
				prev = i
				KillWaves xref, yref
			
			endif
		
		endfor
		
	elseif(BinMeth==1)
	
		For(i=0; i < numpnts(xdTemp); i+=1)
		
			If(xdTemp[i]>(xdTemp[prev]+BinSize))
				//make the bin that we've just stepped out of
				//handle x data
				Make/N=(i-prev)/O/D $("XdataPnt" + num2str(numXvals))/WAVE=xref
				xref[0,i-prev-1] = xdTemp[prev+p]
				WaveStats/Q/Z/M=2 xref
				xVals[numXvals-1] = V_avg
				InsertPoints numXvals, 1, xVals
				xSD[numXvals-1] = V_sdev
				InsertPoints numXvals, 1, xSD
				//handle y data
				Make/N=(i-prev)/O/D $("YdataPnt" + num2str(numXvals))/WAVE=yref
				yref[0,i-prev-1] = ydTemp[prev+p]
				WaveStats/Q/Z/M=2 yref
				yAvg[numXvals-1] = V_avg
				InsertPoints numXvals, 1, yAvg
				ySD[numXvals-1] = V_sdev
				InsertPoints numXvals, 1, ySD
			
				numXvals += 1
				//use deltabins to correctly skip over empty bins
				DeltaBins = Ceil((xdTemp[i] - xdTemp[0] - BinSize*numBins)/BinSize)
				numBins += DeltaBins
				//prev is the first point in the (numBins)th bin
				prev = i
				KillWaves xref, yref
			
			endif
		
		endfor
		
	elseif(BinMeth==0)
	
		For(i=0; i < numpnts(xdTemp); i+=1)
		
			If(xdTemp[i]>(xdTemp[0]+BinSize*NumBins))
				//make the bin that we've just stepped out of
				//handle x data
				Make/N=(i-prev)/O/D $("XdataPnt" + num2str(numXvals))/WAVE=xref
				xref[0,i-prev-1] = xdTemp[prev+p]
				WaveStats/Q/Z/M=2 xref
				xVals[numXvals-1] = V_avg
				InsertPoints numXvals, 1, xVals
				xSD[numXvals-1] = V_sdev
				InsertPoints numXvals, 1, xSD
				//handle y data
				Make/N=(i-prev)/O/D $("YdataPnt" + num2str(numXvals))/WAVE=yref
				yref[0,i-prev-1] = ydTemp[prev+p]
				WaveStats/Q/Z/M=2 yref
				yAvg[numXvals-1] = V_avg
				InsertPoints numXvals, 1, yAvg
				ySD[numXvals-1] = V_sdev
				InsertPoints numXvals, 1, ySD
			
				numXvals += 1
				//use deltabins to correctly skip over empty bins
				DeltaBins = Ceil((xdTemp[i] - xdTemp[0] - BinSize*numBins)/BinSize)
				numBins += DeltaBins
				//prev is the first point in the (numBins)th bin
				prev = i
				KillWaves xref, yref
			
			endif
		
		endfor
		
	endif
	
	//don't forget the last point
	Make/N=(i-prev)/O/D $("XdataPnt" + num2str(numXvals))/WAVE=xref
	xref[0,i-prev-1] = xdTemp[prev+p]
	WaveStats/Q/Z/M=2 xref
	xVals[numXvals-1] = V_avg
	xSD[numXvals-1] = V_sdev
	Make/N=(i-prev)/O/D $("YdataPnt" + num2str(numXvals))/WAVE=yref
	yref[0,i-prev-1] = ydTemp[prev+p]
	WaveStats/Q/Z/M=2 yref
	yAvg[numXvals-1] = V_avg
	ySD[numXvals-1] = V_sdev
	KillWaves xref, yref
	
	print "Number of empty bins: " + num2str(numBins - numXvals)
	
	//uncomment the lines below to duplicate the raw sorted data for future use
	//Duplicate/O xdTemp, $(xBaseName + "_sorted")
	//Duplicate/O ydTemp, $(yBaseName + "_sorted")
	
	//check that the procedure is correctly extracting X values
	//print numXvals
	
End

function Dialog_BinSortXYWaves()
	
	variable TargProjectNum;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
	
	Prompt TargProjectNum, "Source Data Series:", popup, ActivePaths
	DoPrompt "Process Data", TargProjectNum
	
	if(V_Flag)
		return -1		// User canceled
	endif
	
	String TargPath = StringFromList(TargProjectNum-1, ActivePaths)
		
	String SavePanel = CurrentPanel
	String SavePath = CurrentPath
	String fldrSav= GetDataFolder(1)
		
	Set_ColdAtomInfo(TargPath)
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	SetDataFolder ProjectFolder;
	
	SetDataFolder :IndexedWaves;
	string ListofWaves = WaveList("*",";","");
	
	variable Xtarg, Ytarg
	variable BinSize = 1
	variable BinMeth = 0
	string Xbase, Ybase
	string Method = "Static Edge;Dynamic Edge;Minimum Separation;X Vals from Center;"
	Prompt Xtarg, "Target X wave:", popup, ListofWaves
	Prompt Xbase, "Processed X wave name:"
	Prompt BinSize, "Size of Bin (in units of target X wave):"
	Prompt BinMeth, "Dynamically shift bin edge?", popup, Method
	Prompt Ytarg, "Target Y wave:", popup, ListofWaves
	Prompt Ybase, "Processed Y wave name:"
	DoPrompt "Process Data", Xtarg, Xbase, BinSize, BinMeth, Ytarg, Ybase
	
	if(V_Flag)
		Set_ColdAtomInfo(SavePath)
		SetDataFolder fldrSav
		return -1		// User canceled
	endif
	
	BinMeth -= 1;
	string Xwave = StringFromList(Xtarg-1, ListofWaves);
	string Ywave = StringFromList(Ytarg-1, ListofWaves);
	wave Xdata = :$Xwave;
	wave Ydata = :$Ywave;
	
	string temp = CleanupName(Xbase, 0);
	Xbase = temp;
	temp = CleanupName(Ybase, 0);
	Ybase = temp;
	
	BinnedDataSorter(Ydata, Xdata, Ybase, Xbase, BinSize, BinMeth);
	
	Set_ColdAtomInfo(SavePath)
	SetDataFolder fldrSav
end

//This function separates Xdata and Ydata into several waves in correspondance with several binary keys (specified by DecKeys)
// DecKeys is a semicolon separated list of strings
// Each string is the name of an indexed wave which contains only the values 0 and 1.
Function DecimateData(ProjectFolder, Xdata, Ydata, DecKeys)
	string ProjectFolder
	wave Ydata, Xdata
	string DecKeys
	
	//find number of keys
	variable Nkeys = ItemsInList(DecKeys)
	If(Nkeys>3)
		//you really need more than three tags?!
		return -1
	endif
	//since each wave is binary, the number of waves is a power of 2:
	variable NdecWaves = 2^Nkeys
	
	String fldrSav= GetDataFolder(1);
	SetDataFolder $(ProjectFolder);
	
	variable i
	string DecKeyName
	for(i=0;i<Nkeys;i+=1)
		//All DecKeys must be indexed waves
		DecKeyName = StringFromList(i, DecKeys);
		Wave/D temp = :IndexedWaves:$DecKeyName;
		//find where the keys change value
		FindLevels/P temp, .5
		
		If((2^(i+1)-1)!=V_LevelsFound)
			//Data and DecKeys must be sorted by all DecKeys in the order that they appear in the list
			print "DecimateData: Deckey " + num2str(i+1) + " is not sorted correctly, resort the data series"
			return -1
		endif
		
		//store location of value changes for reference
		wave W_FindLevels = :W_FindLevels;
		W_FindLevels = ceil(W_FindLevels[p]);
		string nametemp = "TransitionWave" + num2str(i+1);
		Duplicate/D/O W_FindLevels, $nametemp
	endfor
	
	//get the last DecKey's transitions to use for decimation
	Duplicate/FREE/O/D $("TransitionWave" + num2str(Nkeys)), FinalKey
	
	variable startPt, endPt
	For(i=0;i<NdecWaves;i+=1)
	
		If(i==0)
			startPt = 0;
		else
			startPt = FinalKey[i-1];
		endif
		if(i<(NdecWaves-1))
			endPt = FinalKey[i];
		else
			endPt = numpnts(Xdata);
		endif
		Duplicate/O/D/R=[startPt,EndPt-1] Xdata, $(":IndexedWaves:DecXdata"+num2str(i))
		Duplicate/O/D/R=[startPt,EndPt-1] Ydata, $(":IndexedWaves:DecYdata"+num2str(i))
	endfor
	
	SetDataFolder fldrSav;
	
End

function Dialog_DecimateIndexedWaves()
	
	variable TargProjectNum;
	variable NumDecKeys;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
	
	// PossNums is the number of key waves that can be used.
	// It is limited at 3 because any more means you should think of a better way to take data
	string PossNums = "1;2;3;"
	Prompt TargProjectNum, "Data Series to Separate:", popup, ActivePaths
	Prompt NumDecKeys, "Number of Waves to separate by:", popup, PossNums
	DoPrompt "Separate Data", TargProjectNum, NumDecKeys
	
	if(V_Flag)
		return -1		// User canceled
	endif
	
	String TargPath = StringFromList(TargProjectNum-1, ActivePaths)
		
	String SavePanel = CurrentPanel
	String SavePath = CurrentPath
	String fldrSav= GetDataFolder(1)
		
	Set_ColdAtomInfo(TargPath)
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	SetDataFolder ProjectFolder;
	
	SVAR IndexedWaves = :IndexedWaves:IndexedWaves;
	String DecWaveNames = "";
	
	variable i;
	for(i=1;i<=NumDecKeys;i+=1)
		
		Variable DecWaveNum
		If(i==1)
			Prompt DecWaveNum, "separate by:", popup, IndexedWaves
		else
			Prompt DecWaveNum, "then separate by:", popup, IndexedWaves
		endif
		
		DoPrompt "Separate Data", DecWaveNum
	
		if(V_Flag)
			Set_ColdAtomInfo(SavePath)
			SetDataFolder fldrSav
			return -1		// User canceled
		endif
		
		If(WhichListItem(StringFromList(DecWaveNum-1, IndexedWaves),DecWaveNames,";",0,1)==-1)
			DecWaveNames = AddListItem(StringFromList(DecWaveNum-1, IndexedWaves), DecWaveNames,";",Inf);
		else
			i-=1;
			print "Dialog_DecimateIndexedWaves: Cannot separate by an indexed wave twice, try again"
		endif
		
	endfor
	
	variable Xtarg, Ytarg
	Prompt Xtarg, "target X wave:", popup, IndexedWaves
	Prompt Ytarg, "target Y wave:", popup, IndexedWaves
	DoPrompt "Separate Data", Xtarg, Ytarg
	
	string Xwave = StringFromList(Xtarg-1, IndexedWaves);
	string Ywave = StringFromList(Ytarg-1, IndexedWaves);
	wave Xdata = :IndexedWaves:$Xwave;
	wave Ydata = :IndexedWaves:$Ywave;
	
	DecimateData(ProjectFolder, Xdata, Ydata, DecWaveNames);
	
	Set_ColdAtomInfo(SavePath)
	SetDataFolder fldrSav
end
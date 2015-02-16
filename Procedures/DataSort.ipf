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
			
		endif
		
	endfor
	
	//don't forget the last point
	xVals[numXvals-1] = xdTemp[i-1]
	Make/N=(i-prev-1)/O/D $("dataPnt" + num2str(numXvals))/WAVE=ref
	ref[0,i-prev-1] = ydTemp[prev+p+1]
	WaveStats/Q/Z/M=2 ref
	yAvg[numXvals-1] = V_avg
	ySD[numXvals-1] = V_sdev
	
	//Duplicate the raw sorted data for future use
	Duplicate/O xdTemp, $(xBaseName + "_sorted")
	Duplicate/O ydTemp, $(yBaseName + "_sorted")
	
	//check that the procedure is correctly extracting X values
	print numXvals
	
End

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
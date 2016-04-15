#pragma rtGlobals=1		// Use modern global access method.

//! @file
//! @brief Function related to re-running a set of data instead of live acquisition.

//!
//! @brief Rerun a set of data
//! @details To use this version of BatchRun, set the file "basePath" with SetBasePath(). (see next function)
//!        The data will be added to the Top RbInfo panel.
//!
//!	@note If startnum is -1, only run "endnum"
//! @param[in] startnum index of first file in batch
//! @param[in] endnum   index of last file in batch
//! @param[in] mode     = 0 => no pause for user, 1 => pause for user.
//! @param[in] skipList unknown, added by DSB
//! @return \b -1 on error
//! @return \b NaN or \b 1 on success
Function BatchRun(startnum,endnum,mode,skipList)
	variable startnum, endnum, mode
	string skipList //; separated list of file numbers to skip

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder ProjectFolder;
	
	NVAR index=:IndexedWaves:index
	
	// Discover the name of the current image window
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
	print ImageWindowName;

	// Parse experiment name from ProjectFolder
	String ExperimentName="test"; // default val is "test"
	ExperimentName=StringByKey_Safe(ExperimentName,"root",ProjectFolder,":",";");

	// Check for BatchFileBaseName
	if (exists(ProjectFolder+":Experimental_Info:BatchFileBasePath")==0)
		Dialog_SetBasePath();
	endif
	SVAR BasePath=$(ProjectFolder+":Experimental_Info:BatchFileBasePath");
	
	// Handle single file run
	String temp, filepath
	if (startnum==-1)
		if(endnum<10000)
			sprintf temp "%.4f" endnum/10000	
			temp = StringByKey("0",temp,".")
		else
			sprintf temp "%d" endnum
		endif
		filepath=BasePath+"_"+temp+".ibw"
		AutoRunV3(ExperimentName, filepath)
		
		SetDataFolder fldrSav;		//return to user path
		return 1
	endif
	
	// Batch run for Active Panel
	String waveNameStr
	variable i
	for(i=startnum; i<=endnum; i+=1)
		if(WhichListItem(num2str(i),skipList,";",0,1)==-1)
			if(i<10000)
				sprintf temp "%.4f" i/10000
				temp = StringByKey("0",temp,".")
			else
				sprintf temp "%d" i
			endif
			filepath=BasePath+"_"+temp+".ibw"
			print filepath

			AutoRunV3(ExperimentName, filepath)		// run command!
		
			//handle user cursor input
			If(mode==1)
		
				//temp folder to store result of user interaction
				NewDataFolder/O root:temp_refitwindow;
				Variable/G root:temp_refitwindow:result = 0;
				NVAR resulttemp = root:temp_refitwindow:result;
				
				//Bring current panel to front
				DoWindow/F $CurrentPanel
			
				//make the panel for user interaction
				NewPanel/K=2/W=(200,200,500,500) as "Check Fit and Adjust Cursors"
				DoWindow/C temp_refitwindow
				AutoPositionWindow/E/M=1/R=$CurrentPanel temp_refitwindow
				
				DrawText 25,20,"Click Continue to proceed to the next file."
				DrawText 25,40,"Reposition cursors and click Refit to rerun this file."
				DrawText 25,60,"Click Skip to proceed to the next file without"
				DrawText 25,80,"saving data to indexed waves."
				PopupMenu refit_SetROI,pos={80,100},size={141,21},bodyWidth=141,proc=SetROI
				PopupMenu refit_SetROI,mode=1,popvalue="Set ROI",value= #"\"Set ROI;Set ROI and zoom;Zoom to ROI;Unzoom\""
				Button refit_1,pos={80,130},size={100,20},title="Continue"
				Button refit_1,proc=BatchRunContinue
				Button refit_2,pos={80,160},size={100,20},title="Refit"
				Button refit_2,proc=BatchRunRefit
				Button refit_3,pos={80,190},size={100,20},title="Skip"
				Button refit_3,proc=BatchRunSkip
			
				//wait for user decision
				PauseForUser temp_refitwindow,$CurrentPanel			
				Variable result = resulttemp;
				KillDataFolder root:temp_refitwindow
				
				//parse user action
				if(result==2) //case skip
			
					//remove bad point
					IndexedWavesDeletePoints(ProjectFolder,index-1,1);
				
				elseif(result==1) //case refit
			
					//remove bad point
					IndexedWavesDeletePoints(ProjectFolder,index-1,1);
					i-=1; //decrement loop index to refit on next iteration
				
			
				elseif(result!=0) //error
					print "BatchRun:  Unexpected action during PauseForUser";
					return -1
				endif
			
			endif
		endif
	endfor

	SetDataFolder fldrSav;		//return to user path
end

//!
//! @brief control for temp_refitwindow in ::BatchRun
Function BatchRunContinue(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR result = root:temp_refitwindow:result;
	result = 0;
	
	DoWindow/K temp_refitwindow
End

//!
//! @brief control for temp_refitwindow in ::BatchRun
Function BatchRunRefit(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR result = root:temp_refitwindow:result;
	result = 1;
	
	DoWindow/K temp_refitwindow
End

//!
//! @brief control for temp_refitwindow in ::BatchRun
Function BatchRunSkip(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR result = root:temp_refitwindow:result;
	result = 2;
	
	DoWindow/K temp_refitwindow
End

function Dialog_DoBatchRun()
	
	variable TargProjectNum;
	variable startNum = -1;
	variable endNum = 1;
	variable pauseMode;
	string skipList;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
	
	// PossNums is the number of key waves that can be used.
	// It is limited at 9 due to restrictions on the number of sort keys in Igor
	string PossModes = "0;1;"
	Prompt TargProjectNum, "Target Series for Batch Run:", popup, ActivePaths
	Prompt pauseMode, "Mode (0 = automatic, 1 = pause for user):", popup, PossModes
	Prompt startNum, "File number of first point (-1 to run only last point, without leading zeroes):"
	Prompt endNum, "File number of last point (without leading zeroes):"
	Prompt skipList, "semicolon separated list of file numbers to skip (without leading zeroes):"
	DoPrompt "Batch Run", TargProjectNum, pauseMode, startNum, endNum, skipList
	
	if(V_Flag)
		return -1		// User canceled
	endif
	
	pauseMode -= 1;
	
	String TargPath = StringFromList(TargProjectNum-1, ActivePaths)
		
	String SavePanel = CurrentPanel
	String SavePath = CurrentPath
	String fldrSav= GetDataFolder(1)
		
	Set_ColdAtomInfo(TargPath)
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	SetDataFolder ProjectFolder;
	
	BatchRun(startNum, endNum, pauseMode, skipList);
	
	Set_ColdAtomInfo(SavePath)
	SetDataFolder fldrSav
end

// Make BatchProcessing more efficient by setting BatchFileBasePath variable instead of modifying code
//!
//! @brief Set BasePath variable for batch processing
//! @details To set a base path:
//!	Run with path as string argument from command line (CTRL-J)
//!	BasePath takes the form
//!		"C:Experiment:Data:<YYYY>:<Month>:<DD>:<Camera>_DDMonYYYY"
//!		BatchRun will insert the underscore, file number and ".ibw" for you.
//! @param[in] basePath value to save as the base path
Function SetBasePath(basePath)
	string basePath
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder ProjectFolder;

	// set BatchFileBasePath
	String/G $(ProjectFolder+":Experimental_Info:BatchFileBasePath")=basePath

	SetDataFolder fldrSav;		//return to user path
end

//!
//! @brief Pop-up dialog box requesting set base path.
//!
//! @return \b -1 on error
//! @return \b NaN on success
function Dialog_SetBasePath()
	
	String Months="January;February;March;April;May;June;July;August;September;October;November;December"
	String Days="01;02;03;04;05;06;07;08;09;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;31"
	String Years="2008;2009;2010;2011;2012;2013;2014;2015;2016;2017"
	String Cams= "FL3_32S2M;Flea3;Flea3_20S4M;Flea2;PIXIS;PI"

	String Month, Day, Year, Cam
	// Build Dialog Box
	Prompt Month, "Month", popup, Months
	Prompt Day, "Day", popup, Days
	Prompt Year, "Year", popup, Years
	Prompt Cam, "Camera", popup, Cams
	DoPrompt "Set BatchRun File basename", Month, Day, Year, Cam

	if(V_Flag)
		return -1		// User canceled
	endif
	
	//Form Base Name
	String baseName="I:Data:"+Year+":"+Month+":"+Day+":"+Cam+"_"+Day+Month[0,2]+Year;
	
	//set base name
	SetBasePath(baseName)
end

//!
//! @brief Pop-up which copies BasePath from one data series to another
//!
//! @return \b -1 on error
//! @return \b NaN on success
Function Dialog_CopyBasePath()

	variable TargProjectNum;
	variable HostProjectNum;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
	
	Prompt HostProjectNum, "Copy Path From...", popup, ActivePaths
	Prompt TargProjectNum, "To...", popup, ActivePaths
	DoPrompt "Copy BatchRun base name", HostProjectNum, TargProjectNum
	
	if(V_Flag)
		return -1		// User canceled
	endif
	
	if(HostProjectNum != TargProjectNum)
	
		String HostPath = StringFromList(HostProjectNum-1, ActivePaths)
		String TargPath = StringFromList(TargProjectNum-1, ActivePaths)
		
		if(exists(HostPath + ":Experimental_Info:BatchFileBasePath"))
			
			SVAR CopiedPath = $(HostPath + ":Experimental_Info:BatchFileBasePath")
			String TempPanel = CurrentPanel
			String TempPath = CurrentPath
			
			Set_ColdAtomInfo(TargPath)
			
			SetBasePath(CopiedPath)
			
			Set_ColdAtomInfo(TempPath)
			
		else
		
			print "CopyBasePath: No Base Path to copy"
			return 0
			
		endif
	endif
	

end

//!
//! @brief Runs from the temp file location (C:Experiment:Data:\<filename\>)
//! @details assuming a Flea2 or Flea3 camera
//! @param[in] fleaNum Which flea version we're running
Function RunTemp(fleaNum)
	variable fleaNum
	
	string projectName
	if(fleaNum==2)
		projectName="THOR"
	elseif(fleaNum==3)
		projectName="XY"
	else
		projectName="THOR"
	endif
	
	AutoRunV3(projectName, "C:Experiment:Data:Flea"+num2str(fleaNum)+"temp.ibw")
end

//!
//! @brief Reset (remove all points from) all indexed waves.
//!
//! @param[in] ProjectFolder Project whose IndexedWaves we're deleting points from
//!
//! @return \b -1 on error
//! @return \b NaN on success
function ReinitializeIndexedWaves(ProjectFolder)
	string ProjectFolder
	
	String fldrSav= GetDataFolder(1);
	SetDataFolder $(ProjectFolder);
	
	NVAR index=:IndexedWaves:Index
	SVAR IndexedWaves=:IndexedWaves:IndexedWaves
	SVAR IndexedVariables = :IndexedWaves:IndexedVariables;
	
	// 2D lists
	SVAR Indexed2DWaveNames = :IndexedWaves:FitWaves:Indexed2DWaveNames;
	SVAR IndexedFitWaves = :IndexedWaves:FitWaves:IndexedFitWaves;
	
	// IndexedWaves contains two ";" separated string lists of IndexedWaves 
	//		and their corresponding IndexedVariables. Additionally, there is
	//		an indexed wave of FileNames. We will redimension all of these to 0:
	
	variable i, npnts;
	string IndexedWave, IndexedVariable;
	
	npnts = ItemsInList(IndexedWaves);
	if (npnts != ItemsInList(IndexedVariables) )
		print "ReinitializeIndexedWaves:  IndexedVariables and IndexedWaves do not match";
		SetDataFolder fldrSav;
		return -1;
	endif
	
	for (i = 0; i < npnts; i+= 1)
		IndexedWave = StringFromList(i, IndexedWaves);
		IndexedVariable = StringFromList(i, IndexedVariables);
		
		// Verify that the wave and variable exist, if not create them
		if (exists(":IndexedWaves:"+IndexedWave)==0)
			print "ReinitializeIndexedWaves:  Expected wave", IndexedWave, "not found, recreating."; 
			Make/O/N=0 :IndexedWaves:$(IndexedWave);
		endif
		
		if (exists(":IndexedWaves:"+IndexedVariable)==0)
			print "ReinitializeIndexedWaves:  Expected variable", IndexedVariable, "not found, recreating."; 
			Variable/G :IndexedWaves:$(IndexedVariable) = nan;
		endif

		// Now assign the variables and update the running wave		
		Wave LocalIndexedWave = :IndexedWaves:$(IndexedWave);
		
		//reset all indexed waves
		Redimension/N=0, LocalIndexedWave;
	endfor
	
	//reset file names
	Wave/T FileNames = :IndexedWaves:FileNames;
	Redimension/N=0, FileNames;
	
	// handle 2D waves
	string Indexed2DWave, IndexedFitWave;
	variable FitWaveLength
	
	npnts = ItemsInList(Indexed2DWaveNames);
	if (npnts != ItemsInList(IndexedFitWaves) )
		print "ReinitializeIndexedWaves:  IndexedFitWaves and Indexed2DWavesNames do not match";
		SetDataFolder fldrSav;
		return -1;
	endif
	
	for (i = 0; i < npnts; i+= 1)
		Indexed2DWave = ":IndexedWaves:FitWaves:" + StringFromList(i, Indexed2DWaveNames);
		IndexedFitWave = StringFromList(i, IndexedFitWaves);
		
		// Verify that the wave and variable exist, if not create them
		if (exists(Indexed2DWave)==0)
			print "ReinitializeIndexedWaves:  Expected 2D wave", Indexed2DWave, "not found, recreating."; 
			Make/O/N=(1,1) $(Indexed2DWave);
		endif
		
		if (exists(IndexedFitWave)==0)
			print "ReinitializeIndexedWaves:  Expected fit wave", IndexedFitWave, "not found, recreating."; 
			Make/O/N=0 $(IndexedFitWave);
		endif
		
		// Now assign the variables and update the running wave		
		WAVE LocalIndexed2DWave = $Indexed2DWave;
		WAVE LocalIndexedFitWave = $IndexedFitWave;
		
		//reset all indexed 2D waves
		Redimension/N=(1,1), LocalIndexed2DWave;
	endfor
	
	index=0;
	
	SetDataFolder fldrSav	// Return path
end

//!
//! @brief Delete points from all indexed waves.
//! @details Also sets variable \p index to an appropriate value on completion
//!
//! @param[in] ProjectFolder Project whose IndexedWaves we're deleting points from
//! @param[in] firstPt       Index of the first point to be deleted
//! @param[in] numPts        Number of points to delete, including \p firstPt
//!
//! @return \b -1 on error
//! @return \b NaN on success
function IndexedWavesDeletePoints(ProjectFolder,firstPt,numPts)
	string ProjectFolder
	Variable firstPt, numPts
	
	String fldrSav= GetDataFolder(1);
	SetDataFolder $(ProjectFolder);
	
	NVAR index=:IndexedWaves:Index
	SVAR IndexedWaves=:IndexedWaves:IndexedWaves
	SVAR IndexedVariables = :IndexedWaves:IndexedVariables;
	
	// 2D lists
	SVAR Indexed2DWaveNames = :IndexedWaves:FitWaves:Indexed2DWaveNames;
	SVAR IndexedFitWaves = :IndexedWaves:FitWaves:IndexedFitWaves;
	
	// IndexedWaves contains two ";" separated string lists of IndexedWaves 
	//		and their corresponding IndexedVariables. Additionally, there is
	//		an indexed wave of FileNames. We will redimension all of these to 0:
	
	variable i, npnts;
	string IndexedWave, IndexedVariable;
	
	npnts = ItemsInList(IndexedWaves);
	if (npnts != ItemsInList(IndexedVariables) )
		print "ReinitializeIndexedWaves:  IndexedVariables and IndexedWaves do not match";
		SetDataFolder fldrSav;
		return -1;
	endif
	
	for (i = 0; i < npnts; i+= 1)
		IndexedWave = StringFromList(i, IndexedWaves);
		IndexedVariable = StringFromList(i, IndexedVariables);
		
		// Verify that the wave and variable exist, if not create them
		if (exists(":IndexedWaves:"+IndexedWave)==0)
			print "ReinitializeIndexedWaves:  Expected wave", IndexedWave, "not found, recreating."; 
			Make/O/N=0 :IndexedWaves:$(IndexedWave);
		endif
		
		if (exists(":IndexedWaves:"+IndexedVariable)==0)
			print "ReinitializeIndexedWaves:  Expected variable", IndexedVariable, "not found, recreating."; 
			Variable/G :IndexedWaves:$(IndexedVariable) = nan;
		endif

		// Now assign the variables and update the running wave		
		Wave LocalIndexedWave = :IndexedWaves:$IndexedWave;
		
		//delete points from all indexed waves
		If(numpnts(LocalIndexedWave) >= numPts)
			DeletePoints/M=0 firstPt, numPts, LocalIndexedWave;
		else
			print "IndexedWavesDeletePoints: ", IndexedWave, "has insufficient points to delete.";
			return -1;
		endif
	endfor
	
	Wave/T FileNames = :IndexedWaves:FileNames;
	//delete points from FileNames
	If(numpnts(FileNames) >= numPts)
		DeletePoints/M=0 firstPt, numPts, FileNames;
	else
		print "IndexedWavesDeletePoints: FileNames has insufficient points to delete.";
		return -1;
	endif
	
	// handle 2D waves
	string Indexed2DWave, IndexedFitWave;
	variable FitWaveLength
	
	npnts = ItemsInList(Indexed2DWaveNames);
	if (npnts != ItemsInList(IndexedFitWaves) )
		print "ReinitializeIndexedWaves:  IndexedFitWaves and Indexed2DWavesNames do not match";
		SetDataFolder fldrSav;
		return -1;
	endif
	
	for (i = 0; i < npnts; i+= 1)
		Indexed2DWave = ":IndexedWaves:FitWaves:" + StringFromList(i, Indexed2DWaveNames);
		IndexedFitWave = StringFromList(i, IndexedFitWaves);
		
		// Verify that the wave and variable exist, if not create them
		if (exists(Indexed2DWave)==0)
			print "ReinitializeIndexedWaves:  Expected 2D wave", Indexed2DWave, "not found, recreating."; 
			Make/O/N=(1,1) $(Indexed2DWave);
		endif
		
		if (exists(IndexedFitWave)==0)
			print "ReinitializeIndexedWaves:  Expected fit wave", IndexedFitWave, "not found, recreating."; 
			Make/O/N=0 $(IndexedFitWave);
		endif
		
		// Now assign the variables and update the running wave		
		WAVE LocalIndexed2DWave = $Indexed2DWave;
		WAVE LocalIndexedFitWave = $IndexedFitWave;
		
		//delete points from all indexed waves
		If(DimSize(LocalIndexed2DWave,0) >= numPts)
			DeletePoints/M=0 firstPt, numPts, LocalIndexed2DWave;
		else
			print "IndexedWavesDeletePoints: ", Indexed2DWave, "has insufficient points to delete.";
			return -1;
		endif
	endfor
	
	//set the index appropriately
	index = (index >= numPts ? index-numPts : 0);
	
	SetDataFolder fldrSav	// Return path
end

//!
//! @brief This function sorts all indexed waves in a data series by specified indexed wave
//!
//! @param[in] ProjectFolder         Project whose indexed waves we will sort
//! @param[in] IndexedSorterWaveName Name of indexed wave we will sort by
//1 @param[in] NumSorterWaves        Unknown, added by DSB
//!
//! @return \b -1 on error
//! @return \b NaN on success
function Sort_IndexedWaves(ProjectFolder,IndexedSorterWaveNames, NumSorterWaves)
	string ProjectFolder
	string IndexedSorterWaveNames
	variable NumSorterWaves
	
	String fldrSav= GetDataFolder(1);
	SetDataFolder $(ProjectFolder);
	
	//reference all indexed waves
	NVAR index=:IndexedWaves:Index
	SVAR IndexedWaves=:IndexedWaves:IndexedWaves
	SVAR IndexedVariables = :IndexedWaves:IndexedVariables;
	Wave/T FileNames = :IndexedWaves:FileNames;
	
	variable i;
	string IndexedSorterWaveName;
	
	For(i=0;i<NumSorterWaves;i+=1)
		IndexedSorterWaveName = StringFromList(i, IndexedSorterWaveNames)
		Wave/D temp = :IndexedWaves:$IndexedSorterWaveName;
		string nametemp = "SorterWave" + num2str(i+1);
		Duplicate/D/O temp, $nametemp
	endfor
	
	Make/O/D/N=(numpnts(temp)) sortIndex1, unsortIndex1
	//This is a hack due to Igor's lack of support for awesome things:
	If(NumSorterWaves==1)
		MakeIndex {SorterWave1, FileNames}, sortIndex1
		KillWaves SorterWave1
	elseif(NumSorterWaves==2)
		MakeIndex {SorterWave1, SorterWave2, FileNames}, sortIndex1
		KillWaves SorterWave1, SorterWave2
	elseif(NumSorterWaves==3)
		MakeIndex {SorterWave1, SorterWave2, SorterWave3, FileNames}, sortIndex1
		KillWaves SorterWave1, SorterWave2, SorterWave3
	elseif(NumSorterWaves==4)
		MakeIndex {SorterWave1, SorterWave2, SorterWave3, SorterWave4, FileNames}, sortIndex1
		KillWaves SorterWave1, SorterWave2, SorterWave3, SorterWave4
	elseif(NumSorterWaves==5)
		MakeIndex {SorterWave1, SorterWave2, SorterWave3, SorterWave4, SorterWave5, FileNames}, sortIndex1
		KillWaves SorterWave1, SorterWave2, SorterWave3, SorterWave4, SorterWave5
	elseif(NumSorterWaves==6)
		MakeIndex {SorterWave1, SorterWave2, SorterWave3, SorterWave4, SorterWave5, SorterWave6, FileNames}, sortIndex1
		KillWaves SorterWave1, SorterWave2, SorterWave3, SorterWave4, SorterWave5, SorterWave6
	elseif(NumSorterWaves==7)
		MakeIndex {SorterWave1, SorterWave2, SorterWave3, SorterWave4, SorterWave5, SorterWave6, SorterWave7, FileNames}, sortIndex1
		KillWaves SorterWave1, SorterWave2, SorterWave3, SorterWave4, SorterWave5, SorterWave6, SorterWave7
	elseif(NumSorterWaves==8)
		MakeIndex {SorterWave1, SorterWave2, SorterWave3, SorterWave4, SorterWave5, SorterWave6, SorterWave7, SorterWave8, FileNames}, sortIndex1
		KillWaves SorterWave1, SorterWave2, SorterWave3, SorterWave4, SorterWave5, SorterWave6, SorterWave7, SorterWave8
	elseif(NumSorterWaves==9)
		MakeIndex {SorterWave1, SorterWave2, SorterWave3, SorterWave4, SorterWave5, SorterWave6, SorterWave7, SorterWave8, SorterWave9, FileNames}, sortIndex1
		KillWaves SorterWave1, SorterWave2, SorterWave3, SorterWave4, SorterWave5, SorterWave6, SorterWave7, SorterWave8, SorterWave9
	else
		print "Sort_IndexedWaves: Invalid number of sort keys"
		SetDataFolder fldrSav
		return -1
	endif
	
	MakeIndex sortIndex1, unsortIndex1
	
	// 2D lists
	SVAR Indexed2DWaveNames = :IndexedWaves:FitWaves:Indexed2DWaveNames;
	SVAR IndexedFitWaves = :IndexedWaves:FitWaves:IndexedFitWaves;
	
	// IndexedWaves contains two ";" separated string lists of IndexedWaves 
	//		and their corresponding IndexedVariables. Additionally, there is
	//		an indexed wave of FileNames. We will sort them all!
	
	
	//handle 1D waves
	variable npnts;
	string IndexedWave, IndexedVariable;
	
	npnts = ItemsInList(IndexedWaves);
	if (npnts != ItemsInList(IndexedVariables) )
		print "Sort_IndexedWaves:  IndexedVariables and IndexedWaves do not match";
		SetDataFolder fldrSav;
		return -1;
	endif
	
	for (i = 0; i < npnts; i+= 1)
		IndexedWave = StringFromList(i, IndexedWaves);
		IndexedVariable = StringFromList(i, IndexedVariables);
		
		// Verify that the wave and variable exist, if not create them
		if (exists(":IndexedWaves:"+IndexedWave)==0)
			print "Sort_IndexedWaves:  Expected wave", IndexedWave, "not found, recreating."; 
			Make/O/D/N=0 :IndexedWaves:$(IndexedWave);
		endif
		
		if (exists(":IndexedWaves:"+IndexedVariable)==0)
			print "Sort_IndexedWaves:  Expected variable", IndexedVariable, "not found, recreating."; 
			Variable/G :IndexedWaves:$(IndexedVariable) = nan;
		endif

		// Now assign the variables and update the running wave		
		Wave LocalIndexedWave = :IndexedWaves:$IndexedWave;
		
		//sort the indexed wave preserving file name association
		IndexSort sortIndex1, LocalIndexedWave
	endfor
	
	// handle 2D waves
	string Indexed2DWave, IndexedFitWave;
	variable FitWaveLength
	
	npnts = ItemsInList(Indexed2DWaveNames);
	if (npnts != ItemsInList(IndexedFitWaves) )
		print "ReinitializeIndexedWaves:  IndexedFitWaves and Indexed2DWavesNames do not match";
		SetDataFolder fldrSav;
		return -1;
	endif
	
	//Make an index to sort the rows of the 2D waves
	//duplicate/FREE temp, sortIndex2
	//sortIndex2 = p;
	//IndexSort sortIndex1, sortIndex2
	
	for (i = 0; i < npnts; i+= 1)
		Indexed2DWave = ":IndexedWaves:FitWaves:" + StringFromList(i, Indexed2DWaveNames);
		IndexedFitWave = StringFromList(i, IndexedFitWaves);
		
		// Verify that the wave and variable exist, if not create them
		if (exists(Indexed2DWave)==0)
			print "Sort_IndexedWaves:  Expected 2D wave", Indexed2DWave, "not found, recreating."; 
			Make/O/D/N=(1,1) $(Indexed2DWave);
		endif
		
		if (exists(IndexedFitWave)==0)
			print "Sort_IndexedWaves:  Expected fit wave", IndexedFitWave, "not found, recreating."; 
			Make/O/D/N=0 $(IndexedFitWave);
		endif
		
		// Now assign the variables and update the running wave		
		WAVE LocalIndexed2DWave = $Indexed2DWave;
		WAVE LocalIndexedFitWave = $IndexedFitWave;
		
		//sort the indexed2Dwave
		Duplicate/FREE LocalIndexed2DWave, tempWave;
		//tempWave = LocalIndexed2DWave[sortIndex1[p]][q]   //this line causing compile error
		LocalIndexed2DWave = tempWave
	endfor
	
	//sort FileNames
	IndexSort sortIndex1, FileNames
	
	SetDataFolder fldrSav	// Return path
end

//!
//! @brief Dialog to pick & sort all indexed wave using a user-selected wave as sort keys
//!
//! @return \b -1 on error
//! @return \b NaN on success
function Dialog_SortIndexedWaves()
	
	variable TargProjectNum;
	variable NumSortKeys;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
	
	// PossNums is the number of key waves that can be used.
	// It is limited at 9 due to restrictions on the number of sort keys in Igor
	string PossNums = "1;2;3;4;5;6;7;8;9;"
	Prompt TargProjectNum, "Data Series to Sort:", popup, ActivePaths
	Prompt NumSortKeys, "Number of Waves to Sort by:", popup, PossNums
	DoPrompt "Sort Data Series", TargProjectNum, NumSortKeys
	
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
	String SorterWaveNames = "";
	
	variable i;
	for(i=1;i<=NumSortKeys;i+=1)
		
		Variable SorterWaveNum
		If(i==1)
			Prompt SorterWaveNum, "Sort by:", popup, IndexedWaves
		else
			Prompt SorterWaveNum, "then Sort by:", popup, IndexedWaves
		endif
		
		DoPrompt "Sort Data Series", SorterWaveNum
	
		if(V_Flag)
			Set_ColdAtomInfo(SavePath)
			SetDataFolder fldrSav
			return -1		// User canceled
		endif
		
		If(WhichListItem(StringFromList(SorterWaveNum-1, IndexedWaves),SorterWaveNames,";",0,1)==-1)
			SorterWaveNames = AddListItem(StringFromList(SorterWaveNum-1, IndexedWaves), SorterWaveNames,";",Inf);
		else
			i-=1;
			print "Dialog_SortIndexedWaves: Cannot sort by an indexed wave twice, try again"
		endif
		
	endfor
	
	print SorterWaveNames
	
	Sort_IndexedWaves(ProjectFolder, SorterWaveNames, NumSortKeys)
	
	Set_ColdAtomInfo(SavePath)
	SetDataFolder fldrSav
end
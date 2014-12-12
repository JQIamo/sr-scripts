#pragma rtGlobals=1		// Use modern global access method.

Menu "ColdAtom"
	"-",""	//make divider line
	"Set BatchRun base name...", Dialog_SetBasePath();
	"Copy BatchRun base name...", Dialog_CopyBasePath();
End


// Rerun a set of data (CDH for RbYb)
//
// To use this version of BatchRun, set the file "basePath" with SetBasePath(). (see next function)
//        The data will be added to the Top RbInfo panel.
//
//	Note: if startnum is -1, only run "endnum"
//   mode = 0 => no pause for user, mode = 1 => pause for user.
Function BatchRun(startnum,endnum,mode)
	variable startnum, endnum, mode

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
		
	endfor

	SetDataFolder fldrSav;		//return to user path
end

Function BatchRunContinue(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR result = root:temp_refitwindow:result;
	result = 0;
	
	DoWindow/K temp_refitwindow
End

Function BatchRunRefit(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR result = root:temp_refitwindow:result;
	result = 1;
	
	DoWindow/K temp_refitwindow
End

Function BatchRunSkip(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR result = root:temp_refitwindow:result;
	result = 2;
	
	DoWindow/K temp_refitwindow
End

// Make BatchProcessing more efficient by setting BatchFileBasePath variable instead of modifying code
// To set a base path:
//	Run with path as string argument from command line (CTRL-J)
//	BasePath takes the form
//		"C:Experiment:Data:<YYYY>:<Month>:<DD>:<Camera>_DDMonYYYY"
//		BatchRun will insert the underscore, file number and ".ibw" for you.
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

// Pop-up dialog box requesting set base path.
function Dialog_SetBasePath()
	
	String Months="January;February;March;April;May;June;July;August;September;October;November;December"
	String Days="01;02;03;04;05;06;07;08;09;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;31"
	String Years="2008;2009;2010;2011;2012;2013;2014;2015;2016;2017"
	String Cams= "Flea3;Flea3_20S4M;Flea2;PIXIS;PI"

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
	String baseName="C:Experiment:Data:"+Year+":"+Month+":"+Day+":"+Cam+"_"+Day+Month[0,2]+Year;
	
	//set base name
	SetBasePath(baseName)
end

// Pop-up which copies BasePath from one data series to another
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

// Runs from the temp file location (C:Experiment:Data:<filename>), assuming a Flea2 or Flea3 camera
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

// Reset all indexed waves.
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

// Delete points from all indexed waves.
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

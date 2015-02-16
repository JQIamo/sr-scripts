#pragma rtGlobals=2	// Use modern global access method.

// ********************************************************
//
// Initilizes all of the global variables in the root:Packages:ColdAtom:
// path that are used to manage the different experimental runs.
// This function should only be called once, the first time this package is opened
//
// ********************************************************

function Init_ColdAtomInfo()

	// Create the required path
	NewDataFolder/O root:Packages;
	NewDataFolder/O root:Packages:ColdAtom;
	
	// The global variables
	if (exists("root:Packages:ColdAtom:CurrentPath") == 0)
		String/G root:Packages:ColdAtom:CurrentPath = "";
	endif 
	
	if (exists("root:Packages:ColdAtom:CurrentPanel") == 0)
		String/G root:Packages:ColdAtom:CurrentPanel = "";
	endif 
	
	// These are a list of all the active paths and their associated panels (in no particular, but the same, order!!)
	if (exists("root:Packages:ColdAtom:ActivePaths") == 0)
		String/G root:Packages:ColdAtom:ActivePaths = "";
	endif
	if (exists("root:Packages:ColdAtom:ActivePanels") == 0)
		String/G root:Packages:ColdAtom:ActivePanels = "";
	endif
end

// ********************************************************
//
// Exists_ColdAtomInfo(ProjectID)
// checks to see if a project in the path CheckFolder exists, retuns 1 if so
//
// ********************************************************

function Exists_ColdAtomInfo(CheckFolder)
	string CheckFolder
	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths;

	// see if the desired item is in the list.
	if (WhichListItem(CheckFolder, ActivePaths) == -1)
		return 0;
	endif
	
	return 1;
end

// ********************************************************
//
// Activate_Top_ColdAtomInfo()
// Locates the top ColdAtomInfo window,  makes that project the active project
// and returns a string to the data path for this project.  If no projects this will be 
// an empty string.
//
// ********************************************************

// This is buggy becuase it is possible that this user has closed a panel and made a
// new one with the name of the expected window.  It always works, however, if
// the top window is a RB_info panel.

function/T Activate_Top_ColdAtomInfo()
	string TopFolder;
	string PanelList;
	variable i, ListIndex;
	
	SVAR ActivePanels = root:Packages:ColdAtom:ActivePanels;	
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths;
	
	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Find the top ColdAtom info panel
	PanelList = WinList("*", ";","WIN:64");	// List of all panels (in top-down order)
	i = 0;
	do
		TopFolder = StringFromList(i, PanelList); i += 1;
		if (StringMatch(TopFolder, ""))
			return "";
		endif
		ListIndex = WhichListItem(TopFolder, ActivePanels);
	while (ListIndex == -1)
	TopFolder = StringFromList(ListIndex, ActivePaths);
	
	// Make the top window the active one
	Set_ColdAtomInfo(TopFolder)
	
	// Return that path
	return TopFolder;
end

// ********************************************************
//
// Rename_ColdAtomInfo
// Sets the active rubiddium project
//
// ********************************************************

function Rename_ColdAtomInfo(RenameFolder, ProjectID)
	string RenameFolder, ProjectID;
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR ActivePanels = root:Packages:ColdAtom:ActivePanels
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
		
	// Verify that the old window does exist
	if (Exists_ColdAtomInfo(RenameFolder) == 0)
		print "Rename_ColdAtomInfo:  source does not exist";
		return 0;
	endif
	
	// Verify that the new window does not exist
	if (Exists_ColdAtomInfo(ProjectID) == 1)
		print "Set_ColdAtomInfo:  target already exists";
		return 0;
	endif

	variable ProjectIDNum = WhichListItem(RenameFolder, ActivePaths);

	// The panels and graphics automaticaly track this type of thing so I need
	// to do nothing there.
	
	// See if I am renaming the ActivePath
	if (stringMatch(CurrentPath, RenameFolder) == 1)
		CurrentPath = ProjectID;
	endif
	
	// Switch the path and it's name in the list (this includes re-ordering the list ;( )
	renamedatafolder $RenameFolder, $( ReplaceString("root:", ProjectID, ""))

	ActivePaths = AddListItem(ProjectID, RemoveListItem(ProjectIDNum, ActivePaths) );
	
	String PanelString = StringFromList(ProjectIDNum, ActivePanels);
	ActivePanels = AddListItem(PanelString, RemoveListItem(ProjectIDNum, ActivePanels) );
	
	// Rename the panel
	String WindowTitle = "ColdAtom:" + ProjectID;
	DoWindow/T $PanelString, WindowTitle;
end


// ********************************************************
//
// Set_ColdAtomInfo
// Sets the active ColdAtom project
//
// ********************************************************

function Set_ColdAtomInfo(SwitchFolder)
	string SwitchFolder;
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR ActivePanels = root:Packages:ColdAtom:ActivePanels
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
	
	// Verify that the new window does exist
	if (Exists_ColdAtomInfo(SwitchFolder) == 0)
		print "Set_ColdAtomInfo: project does not exist";
		return 0;
	endif

	// Find the index in the list of this item.
	variable ProjectIDNum = WhichListItem(SwitchFolder, ActivePaths);

	// Switch the path
	CurrentPath = SwitchFolder;

	// Get the window to activate and bring to front.
	CurrentPanel = StringFromList(ProjectIDNum, ActivePanels);
	DoWindow /F $CurrentPanel;
end


// ********************************************************
//
// Delete_ColdAtomInfo
// removes an active Rubidum data series, including:
//	The display window (if exists)
//	The accociated data and folder
//
// ********************************************************

function Delete_ColdAtomInfo(FolderToDelete)
	String FolderToDelete

	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR ActivePanels = root:Packages:ColdAtom:ActivePanels

	// Verify that the  window does exist
	if (Exists_ColdAtomInfo(FolderToDelete) == 0)
		print "Delete_ColdAtomInfo:  source does not exist";
		return 0;
	endif
	
	variable ProjectIDNum = WhichListItem(FolderToDelete, ActivePaths);
	
	// Do not remove if there is  one or less item in the list
	if ( ItemsInList(ActivePaths) < 1)
		return 0
	endif
	
	// Get the window to kill and kill it.
	String DeleteWindow = StringFromList(ProjectIDNum, ActivePanels);

	DoWindow /K $DeleteWindow;
	ActivePanels = RemoveListItem(ProjectIDNum, ActivePanels);
	
	// Get the path to remove
	String DeletePath = StringFromList(ProjectIDNum, ActivePaths);
	KillDataFolder $DeletePath;
	ActivePaths = RemoveListItem(ProjectIDNum, ActivePaths);

	// Make the first item in the list the current one, unless the list is empty
	if (ItemsInList(ActivePaths) ==0)
		SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
		SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
		CurrentPath = "";
		CurrentPanel = "";
	else
		Set_ColdAtomInfo( StringFromList(0, ActivePaths) );
	endif
end

// ********************************************************
// New_ColdAtomInfo, and calling function.  This is a safe function, in the sence that 
// It will not delete an already existing project.

function Dialog_New_ColdAtomInfo()
	// Ian Spielman 15Sep04
	// This function sets up a new folder
	// to analize data for the ColdAtom BEC project
	string ProjectID;
	variable ExperimentNum;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist
	
	// Build the User Diolog Box
	Prompt ProjectID, "Project Folder"
	Prompt ExperimentNum, "Experiment", popup, " Sr; RbYb; Rubidium I; Rubidium II"
	DoPrompt "ColdAtom BEC Analysis", ProjectID, ExperimentNum;
	ExperimentNum -= 1;
	
	if (V_Flag)
		return -1		// User canceled
	endif
	
	//prevent errors in series creation
	string temp = CleanupName(ProjectID,0)
	ProjectID = temp
	
	String ExperimentID = StringFromList(ExperimentNum, "Sr;RbYb;Rubidium_I;Rubidium_II");
	New_ColdAtomInfo(ProjectID, ExperimentID)
end


function New_ColdAtomInfo(ProjectID, ExperimentID)
	string ProjectID;
	String ExperimentID;	// Which apparatus.
	
	// Verify that the new window does not exist
	// If it does make it the active project
	if (Exists_ColdAtomInfo("root:" + ProjectID) == 1)
		Set_ColdAtomInfo("root:" + ProjectID);
		return 0;
	endif

	// Write a global varible :root:Procedures:ColdAtom:ActiveFolder
	// To identify the currently active window for subsiquent calls
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	ProjectFolder = "root:" + ProjectID;

	// Now install all of the required global variables, waves, and sub-folders.
	NewDataFolder/O $ProjectFolder
	NewDataFolder/O $(ProjectFolder + ":Experimental_Info")
	NewDataFolder/O $(ProjectFolder + ":Fit_Info")
	NewDataFolder/O $(ProjectFolder + ":LineProfiles")


	// *********************************************
	// Setup for Indexed Waves
	Init_IndexedWaves();

	// *********************************************
	// Variables for the panel or those that
	// were not needed for the construction of the window, 
	// but are for analysis functions.

	// Experimental properties
	String/G $(ProjectFolder + ":Experimental_Info:Experiment") = ExperimentID;
	Variable/G $(ProjectFolder + ":Experimental_Info:RotateImage") = 0;
	Variable/G $(ProjectFolder + ":Experimental_Info:RotAng") = 0;
	String/G $(ProjectFolder + ":Experimental_Info:Camera") = "";
	String/G $(ProjectFolder + ":Experimental_Info:DataType") = "Absorption";
	String/G $(ProjectFolder + ":Experimental_Info:ImageType") = "Raw";
	String/G $(ProjectFolder + ":Experimental_Info:ImageDirection") = "";
	String/G $(ProjectFolder + ":Experimental_Info:FileName") = "";
	String/G $(ProjectFolder + ":Experimental_Info:HeaderString") = "";
	Variable/G $(ProjectFolder + ":Experimental_Info:UpdateDataFromFile") = 1;
	Variable/G $(ProjectFolder + ":Experimental_Info:DualAxis") = 0;
	
	Variable/G $(ProjectFolder + ":Experimental_Info:IRace") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:IPinch") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:IBias") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:IQuad") = 60;
	Variable/G $(ProjectFolder + ":Experimental_Info:WaistX") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:WaistZ") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:BeamZ") = nan;
	
	Variable/G $(ProjectFolder + ":Experimental_Info:DipolePower") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:CrDipolePower") = nan;
	
	Variable/G $(ProjectFolder + ":Experimental_Info:detuning") = 0;
	Variable/G $(ProjectFolder + ":Experimental_Info:trapmin0") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:expand_time") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:magnification") = 0.664;
	Variable/G $(ProjectFolder + ":Experimental_Info:delta_pix") = 1;
	Variable/G $(ProjectFolder + ":Experimental_Info:ISatCounts") = inf;
	Variable/G $(ProjectFolder + ":Experimental_Info:PeakOD") = 3.5;
	Variable/G $(ProjectFolder + ":Experimental_Info:Bo") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:omg_ho") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:a_ho") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:omgX") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:omgY") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:omgZ") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:omgXLat") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:omgYLat") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:omgZLat") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:k") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:aspectratio_BEC") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:getscope") = 0;
	Variable/G $(ProjectFolder + ":Experimental_Info:traptype") = 1;
	Variable/G $(ProjectFolder + ":Experimental_Info:flevel") = 1;
	Variable/G $(ProjectFolder + ":Experimental_Info:SrIsotope") = 2;
	Variable/G $(ProjectFolder + ":Experimental_Info:camdir") = 1;
	Variable/G $(ProjectFolder + ":Experimental_Info:theta") = 36;
	Variable/G $(ProjectFolder + ":Experimental_Info:mass") = 1.42655671e-25; //86-Sr mass
	Variable/G $(ProjectFolder + ":Experimental_Info:a_scatt") = 43.619e-3; //86-Sr scattering length

	// Trap properties
	Variable/G $(ProjectFolder + ":Experimental_Info:TrapMin") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:TrapDepth") = nan;
	//Cross Axial scaling
	//Variable/G $(ProjectFolder + ":Experimental_Info:FreqScalingX") = Sqrt(78.017);
	//Single beam axial scaling
	Variable/G $(ProjectFolder + ":Experimental_Info:FreqScalingX") = 12.5/(2*Pi);
	Variable/G $(ProjectFolder + ":Experimental_Info:FreqScalingY") = 157.094/(2*Pi);
	Variable/G $(ProjectFolder + ":Experimental_Info:FreqScalingZ") = 1789.58/(2*Pi);
	Variable/G $(ProjectFolder + ":Experimental_Info:Pc") = .271429;
	Variable/G $(ProjectFolder + ":Experimental_Info:freqX") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:freqY") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:freqZ") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:freqXLat") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:freqYLat") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:freqZLat") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:AspectRatio") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:IMot") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:Moment") = 1;
	
	// BEC input paramaters 
	Variable/G $(ProjectFolder + ":Experimental_Info:CastDum_xscale") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:CastDum_yscale") = nan;
	Variable/G $(ProjectFolder + ":Experimental_Info:CastDum_zscale") = nan;

	// Fit Paramaters and Indexed waves
	
	make/T/O/N=0 $(ProjectFolder + ":IndexedWaves:FileNames");
	New_IndexedWave("xwidth", ":xrms");
	New_IndexedWave("ywidth", ":yrms");
	New_IndexedWave("zwidth", ":zrms");
	New_IndexedWave("num", ":number");
	New_IndexedWave("absnum", ":absnumber");
	New_IndexedWave("amplitude", ":amplitude");
	New_IndexedWave("rho", ":density");
	New_IndexedWave("rho_t0", ":density_t0");
	New_IndexedWave("absrho_t0",":absdensity_t0");
	New_IndexedWave("temp", ":temperature");
	New_IndexedWave("tempH", ":thoriz");
	New_IndexedWave("tempV", ":tvert");
	New_IndexedWave("xpos", ":xposition");
	New_IndexedWave("ypos", ":yposition");
	New_IndexedWave("zpos", ":zposition");
	New_IndexedWave("psd",":PSD");
	New_IndexedWave("num_BEC", ":number_BEC");
	New_IndexedWave("num_TF", ":number_TF");
	New_IndexedWave("rho_BEC", ":density_BEC");
	New_IndexedWave("rho_BEC_t0", ":density_BEC_t0");
	New_IndexedWave("absrho_BEC_t0", ":absdensity_BEC_t0");
	New_IndexedWave("pkopdens", ":amplitude_tf");
	New_IndexedWave("xsize_BEC", ":xwidth_BEC");
	New_IndexedWave("ysize_BEC", ":ywidth_BEC");
	New_IndexedWave("zsize_BEC", ":zwidth_BEC");
	New_IndexedWave("detun", ":Experimental_Info:detuning");
	New_IndexedWave("X_Point_Number", ":IndexedWaves:Index");
	New_IndexedWave("N2T3",":N2T3var");


	Variable/G $(ProjectFolder + ":LineProfiles:slicesource") = 0;
	make/O/N=100 $(ProjectFolder + ":LineProfiles:Slice")
	wave Slice = $(ProjectFolder + ":LineProfiles:Slice")

	// Fitting properties
	Variable/G $(ProjectFolder + ":fit_info:xmax") = inf;
	Variable/G $(ProjectFolder + ":fit_info:ymax") = inf;
	Variable/G $(ProjectFolder + ":fit_info:xmin") = -inf;
	Variable/G $(ProjectFolder + ":fit_info:ymin") = -inf;
	Variable/G $(ProjectFolder + ":fit_info:bgxmax") = inf;
	Variable/G $(ProjectFolder + ":fit_info:bgymax") = inf;
	Variable/G $(ProjectFolder + ":fit_info:bgxmin") = -inf;
	Variable/G $(ProjectFolder + ":fit_info:bgymin") = -inf;
	Variable/G $(ProjectFolder + ":fit_info:findmax") = 1;
	Variable/G $(ProjectFolder + ":fit_info:Fit_Type") = 1;
	Variable/G $(ProjectFolder + ":Fit_Info:slicewidth") = 10;
	Variable/G $(ProjectFolder + ":fit_info:CentersFixed") = 1;
	Variable/G $(ProjectFolder + ":fit_info:Analysis_Type") = 1;
	Variable/G $(ProjectFolder + ":fit_info:DoRealMask") = 0;

	make/O/N=100 $(ProjectFolder + ":Fit_Info:xsec_col")
	make/O/N=100 $(ProjectFolder + ":Fit_Info:xsec_row")
	make/O/N=100 $(ProjectFolder + ":Fit_Info:slice")
	make/O/N=100 $(ProjectFolder + ":Fit_Info:fit_xsec_col")
	make/O/N=100 $(ProjectFolder + ":Fit_Info:res_xsec_col")
	make/O/N=100 $(ProjectFolder + ":Fit_Info:fit_xsec_row")
	make/O/N=100 $(ProjectFolder + ":Fit_Info:res_xsec_row")
	make/O/N=4 $(ProjectFolder + ":Fit_Info:W_coef")
	make/O/N=4 $(ProjectFolder + ":Fit_Info:ver_coef")
	make/O/N=4 $(ProjectFolder + ":Fit_Info:hor_coef")
	make/O/N=6 $(ProjectFolder + ":Fit_Info:TF_ver_coef")
	make/O/N=6 $(ProjectFolder + ":Fit_Info:TF_hor_coef")
	make/O/N=9 $(ProjectFolder + ":Fit_Info:TF_2D_coef")
	make/O/N=25 $(ProjectFolder + ":Fit_Info:PrAlpha")
	// Index every fit	--CDH 09.Feb.2012
	New_Indexed2DWave("ver_coefHistory", ":Fit_Info:ver_coef")
	New_Indexed2DWave("hor_coefHistory", ":Fit_Info:hor_coef")
	New_Indexed2DWave("TF_ver_coefHistory", ":Fit_Info:TF_ver_coef")
	New_Indexed2DWave("TF_hor_coefHistory", ":Fit_Info:TF_hor_coef")
	New_Indexed2DWave("TF_2D_coefHisotry", ":Fit_Info:TF_2D_coefHistory")
	New_Indexed2DWave("Gauss3d_coefHistory", ":Fit_Info:Gauss3d_coef")	// works even though Gauss3d_coef not yet made
	New_Indexed2DWave("G3d_confidenceHistory", ":Fit_Info:G3d_confidence")
	New_Indexed2DWave("PrAlpha_History", ":Fit_Info:PrAlpha")
	
	// Thermal cloud properties
	Variable/G $(ProjectFolder + ":temperature") = nan;
	Variable/G $(ProjectFolder + ":density") = nan;
	Variable/G $(ProjectFolder + ":amplitude") = nan;
	Variable/G $(ProjectFolder + ":number") = nan;
	Variable/G $(ProjectFolder + ":xposition") = nan;
	Variable/G $(ProjectFolder + ":yposition") = nan;
	Variable/G $(ProjectFolder + ":zposition") = nan;
	Variable/G $(ProjectFolder + ":Tc") = nan;
		
	// Imaged cloud properties
	Variable/G $(ProjectFolder + ":xrms") = nan;
	Variable/G $(ProjectFolder + ":yrms") = nan;
	Variable/G $(ProjectFolder + ":zrms") = nan;

	// Initial cloud properties
	Variable/G $(ProjectFolder + ":xrms_t0") = nan;
	Variable/G $(ProjectFolder + ":yrms_t0") = nan;
	Variable/G $(ProjectFolder + ":zrms_t0") = nan;
	Variable/G $(ProjectFolder + ":density_t0") = nan;
	Variable/G $(ProjectFolder + ":PSD") = nan;

	// BEC properties
	Variable/G $(ProjectFolder + ":number_BEC") = nan;
	Variable/G $(ProjectFolder + ":number_TF") = nan;
	Variable/G $(ProjectFolder + ":amplitude_TF") = nan;
	Variable/G $(ProjectFolder + ":chempot") = nan;
	Variable/G $(ProjectFolder + ":chempot_TF") = nan;

	// Imaged BEC properties
	Variable/G $(ProjectFolder + ":xwidth_BEC") = nan;
	Variable/G $(ProjectFolder + ":ywidth_BEC") = nan;
	Variable/G $(ProjectFolder + ":zwidth_BEC") = nan;
	Variable/G $(ProjectFolder + ":density_BEC") = nan;
	Variable/G $(ProjectFolder + ":radius_TF") = nan;
	Variable/G $(ProjectFolder + ":AspectRatio_meas") = nan;
	Variable/G $(ProjectFolder + ":AspectRatio_BEC_meas") = nan;
	
	// Initial BEC properties
	Variable/G $(ProjectFolder + ":xwidth_BEC_t0") = nan;
	Variable/G $(ProjectFolder + ":ywidth_BEC_t0") = nan;
	Variable/G $(ProjectFolder + ":zwidth_BEC_t0") = nan;
	Variable/G $(ProjectFolder + ":density_BEC_t0") = nan;
	Variable/G $(ProjectFolder + ":radius_TF_t0") = nan;
	Variable/G $(ProjectFolder + ":AspectRatio_meas_t0") = nan;
	Variable/G $(ProjectFolder + ":AspectRatio_BEC_meas_t0") = nan;

	// Create some initial waves for the traces and images
	make/O/N=(100,100) $(ProjectFolder + ":optdepth")
	make/O/N=(100,100) $(ProjectFolder + ":ISat")
	make/O/I/N=(100,100) $(ProjectFolder + ":ROI_mask")
	make/O/N=(100,100) $(ProjectFolder + ":Raw1")
	make/O/N=(100,100) $(ProjectFolder + ":Raw2")
	make/O/N=(100,100) $(ProjectFolder + ":Raw3")
	make/O/N=(100,100) $(ProjectFolder + ":Raw4")
	make/O/N=(100,100) $(ProjectFolder + ":Fit_Info:fit_optdepth")	//-CDH: why make this? 2D fits?
	make/O/N=(100,100) $(ProjectFolder + ":Fit_Info:res_optdepth")
	
	// References to 
	wave xsec_row = $(ProjectFolder + ":Fit_Info:xsec_row")
	wave xsec_col = $(ProjectFolder + ":Fit_Info:xsec_col")
	wave optdepth = $(ProjectFolder + ":optdepth");
	Wave fit_optdepth = $(ProjectFolder + ":Fit_Info:fit_optdepth")
	Wave res_optdepth = $(ProjectFolder + ":Fit_Info:res_optdepth")

	NVAR xmin=$(ProjectFolder + ":fit_info:xmin");
	NVAR ymin=$(ProjectFolder + ":fit_info:ymin"); 
	
	SVAR Experiment = $(ProjectFolder + ":Experimental_Info:Experiment");
	// Bring up the window
	strswitch (Experiment)
		case "Rubidium_I": 
			BuildRubidiumIWindow(ProjectFolder);
		Break;
		case "Rubidium_II": // Rubidium II
			BuildRubidiumIIWindow(ProjectFolder);
		Break;
		case "RbYb": 
			BuildRbYbWindow(ProjectFolder);
		Break;
		case "Sr": 
			BuildSrWindow(ProjectFolder);
		Break;
	endswitch
	
	// Add the new panel and project to the globaly mantained list.
	
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR ActivePanels = root:Packages:ColdAtom:ActivePanels
	svar CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	
	ActivePaths = AddListItem(ProjectFolder, ActivePaths);
	ActivePanels = AddListItem(CurrentPanel, ActivePanels);

	// Fabriacate some initial data
	Update_Magnification();		//CDH: not sure why this is called here, none of the properties have been read yet...
	//xsec_row =  (20*exp(-((x) / (xmin / 4))^2)*exp(-((y) / (ymin / 4))^2) < 4 ? 16*exp(-((x) / (xmin / 4))^2) : 4);
	//xsec_col =  (20*exp(-((x) / (xmin / 4))^2)*exp(-((y) / (ymin / 4))^2) < 4 ? 16*exp(-((y) / (ymin / 4))^2) : 4);
	//optdepth = (20*exp(-((x) / (xmin / 4))^2)*exp(-((y) / (ymin / 4))^2) < 4 ? 16*exp(-((x) / (xmin / 4))^2)*exp(-((y) / (ymin / 4))^2) : 4);
	
	//For TriGauss
	//Make/O/D/N=8 temp_params;
	//temp_params[0] = 0;
	//temp_params[1] = 4;
	//temp_params[2] = 0;
	//temp_params[3] = xmin/8;
	//temp_params[4] = 0;
	//temp_params[5] = ymin/8;
	//temp_params[6] = 2;
	//temp_params[7] = ymin/4;
	//optdepth = TriGauss_2D(temp_params,x,y)+gnoise(.1,2);
	//xsec_row = TriGauss_2D(temp_params,x,0)+gnoise(.1,2);
	//xsec_col = TriGauss_2D(temp_params,0,x)+gnoise(.1,2);
	
	//For Gauss2D
	Make/O/D/N=7 temp_params;
	temp_params[0] = 0;
	temp_params[1] = .2;
	temp_params[2] = 0;
	temp_params[3] = abs(xmin/8);
	temp_params[4] = 0;
	temp_params[5] = abs(ymin/8);
	temp_params[6] = 0;
	optdepth = Gauss2D(temp_params,x,y)+gnoise(.1,2);
	xsec_row = Gauss2D(temp_params,x,0)+gnoise(.1,2);
	xsec_col = Gauss2D(temp_params,0,x)+gnoise(.1,2);
	fit_optdepth = optdepth
	res_optdepth = optdepth
	print sqrt(2)*temp_params[5]

	// Add the cursors
	// Transfer the cursors
	AddMissingCursor("A", "optdepth");
	AddMissingCursor("B", "optdepth");
	AddMissingCursor("C", "optdepth");
	AddMissingCursor("D", "optdepth");
	AddMissingCursor("E", "optdepth");
	AddMissingCursor("F", "optdepth");

	ComputeTrapProperties();		// similarly, not sure why this is called here.

	return 0
End

function Copy_ColdAtomInfo(ProjectID, CopyProjPath, CopyExperimentID)
	string ProjectID;
	string CopyProjPath;	// which series to copy data from
	String CopyExperimentID;	// Which apparatus.
	
	// Verify that the new window does not exist
	// If it does make it the active project
	if (Exists_ColdAtomInfo("root:" + ProjectID) == 1)
		Set_ColdAtomInfo("root:" + ProjectID);
		return 0;
	endif

	// Write a global varible :root:Procedures:ColdAtom:ActiveFolder
	// To identify the currently active window for subsiquent calls
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	ProjectFolder = "root:" + ProjectID;

	// Now duplicate all of the required global variables, waves, and sub-folders.
	DuplicateDataFolder $CopyProjPath, $ProjectFolder

	// Bring up the window
	strswitch (CopyExperimentID)
		case "Rubidium_I": 
			BuildRubidiumIWindow(ProjectFolder);
		Break;
		case "Rubidium_II": // Rubidium II
			BuildRubidiumIIWindow(ProjectFolder);
		Break;
		case "RbYb": 
			BuildRbYbWindow(ProjectFolder);
		Break;
		case "Sr": 
			BuildSrWindow(ProjectFolder);
		Break;
	endswitch
	
	// Add the new panel and project to the globaly mantained list.
	
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR ActivePanels = root:Packages:ColdAtom:ActivePanels
	svar CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	
	ActivePaths = AddListItem(ProjectFolder, ActivePaths);
	ActivePanels = AddListItem(CurrentPanel, ActivePanels);

	Update_Magnification();		//CDH: not sure why this is called here, none of the properties have been read yet...
	
	// Add the cursors
	// Transfer the cursors
	AddMissingCursor("A", "optdepth");
	AddMissingCursor("B", "optdepth");
	AddMissingCursor("C", "optdepth");
	AddMissingCursor("D", "optdepth");
	AddMissingCursor("E", "optdepth");
	AddMissingCursor("F", "optdepth");

	ComputeTrapProperties();		// similarly, not sure why this is called here.

	return 0
End

// ******************** UpdatePanelImage ***********************************
// This function updates the image that is found on the RubudiumInfo Panel
// this display is assumed to only hold a single image, so all the other images that might be displayed are
// removed.
Function UpdatePanelImage(imagename)
	String imagename
	
	// Get the current path and front window name
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String WindowName = CurrentPanel + "#ColdAtomInfoImage";	// This is the Image
	String GraphName = CurrentPanel + "#ColdAtomInfoSections"; // This is the 1D graph
	String fldrSav= GetDataFolder(1)

	String OldImageList, ImageToProcess;
	variable i, NumImages, NeedToAdd = 1;

	// Now get a list of all the images on that window, and also a list of the Cursors.
	OldImageList = ImageNameList(WindowName,";");
	
	// See if the desired image is already displayed
	// If it is, just removed the undesired images,
	// If not add it, then remove undesired images.

	String FullImageName = fldrSav + ImageName;
	NumImages = ItemsInList(OldImageList)
	for (i = 0; i < NumImages && NeedToAdd == 1; i+=1)
		ImageToProcess = StringFromList(i,OldImageList);
		WAVE/Z w = ImageNameToWaveRef(WindowName,ImageToProcess);
		ImageToProcess =  GetWavesDataFolder(w, 2 );

		if (cmpstr(ImageToProcess,FullImageName) == 0)
			// Current wave is the one we want to add
			NeedToAdd = 0;
			OldImageList = RemoveListItem(i,OldImageList)
		endif
	endfor

	// Append the desired image
	if (NeedToAdd == 1)
		AppendImage/W=$(WindowName) $(Imagename);
	endif
	
	// Remove the preexisting images
	NumImages = ItemsInList(OldImageList)
	for (i = 0; i < NumImages; i+=1)
		ImageToProcess = StringFromList(i,OldImageList);
		RemoveImage/W=$(WindowName) $(ImageToProcess);
	endfor
	
	// Because the image was added when there were other images there
	// it is possible that it was given a funny name like "AbsImage#1", so ask
	// Igor for the name
	OldImageList = ImageNameList(WindowName,";");	
	ImageToProcess = StringFromList(0,OldImageList);
	
	// Make the new image a rainbow plot and set the scale based on the 1D trace plot
	GetAxis/Q/W=$(GraphName) left
	ModifyImage/W=$(WindowName) $(ImageToProcess) ctab= {V_min,v_max,Grays,0};
		
	// Transfer the cursors
	AddMissingCursor("A", ImageToProcess);
	AddMissingCursor("B", ImageToProcess);
	AddMissingCursor("C", ImageToProcess);
	AddMissingCursor("D", ImageToProcess);
	AddMissingCursor("E", ImageToProcess);
	AddMissingCursor("F", ImageToProcess);
End
// ******************** UpdatePanelGraph ***********************************

Function ComputeTrapProperties()
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	SVAR Experiment = :Experimental_Info:Experiment;

	NVAR Irace = :Experimental_Info:Irace
	NVAR Ipinch = :Experimental_Info:Ipinch
	NVAR Ibias = :Experimental_Info:Ibias

	NVAR IQuad = :Experimental_Info:IQuad;
	NVAR BeamZ = :Experimental_Info:BeamZ;
	NVAR WaistX = :Experimental_Info:WaistX;
	NVAR WaistZ = :Experimental_Info:WaistZ;
	NVAR DipolePower = :Experimental_Info:DipolePower;
	NVAR CrDipolePower = :Experimental_Info:CrDipolePower;

	NVAR Bo = :Experimental_Info:Bo
	NVAR Imot = :Experimental_Info:Imot
	NVAR omg_ho = :Experimental_Info:omg_ho
	NVAR a_ho = :Experimental_Info:a_ho
	NVAR FreqScaling = :Experimental_Info:FreqScaling
	NVAR FreqScalingX = :Experimental_Info:FreqScalingX
	NVAR FreqScalingY = :Experimental_Info:FreqScalingY
	NVAR FreqScalingZ = :Experimental_Info:FreqScalingZ
	NVAR freqX = :Experimental_Info:freqX
	NVAR freqY = :Experimental_Info:freqY
	NVAR freqZ = :Experimental_Info:freqZ
	NVAR freqXLat = :Experimental_Info:freqXLat
	NVAR freqYLat = :Experimental_Info:freqYLat
	NVAR freqZLat = :Experimental_Info:freqZLat
	NVAR Pc = :Experimental_Info:Pc
	NVAR trapmin = :Experimental_Info:trapmin
	NVAR trapdepth = :Experimental_Info:trapdepth
	NVAR aspectratio = :Experimental_Info:aspectratio
	NVAR moment = :Experimental_Info:moment
	NVAR flevel=:Experimental_Info:flevel	
	NVAR omgX = :Experimental_Info:omgX;
	NVAR omgY = :Experimental_Info:omgY;
	NVAR omgZ = :Experimental_Info:omgZ;
	NVAR omgXLat = :Experimental_Info:omgXLat;
	NVAR omgYLat = :Experimental_Info:omgYLat;
	NVAR omgZLat = :Experimental_Info:omgZLat;
	NVAR k = :Experimental_Info:k;
	NVAR aspectratio_BEC = :Experimental_Info:aspectratio_BEC
	NVAR trapmin0 = :Experimental_Info:trapmin0
	NVAR expand_time = :Experimental_Info:expand_time
	NVAR mass=:Experimental_Info:mass
	NVAR a_scatt=:Experimental_Info:a_scatt

	moment = (flevel == 1 ? 1/2 : 1);

	// There is a prefactor on the bias of 1.06 that might need to be changed since I moved
	// the bias in somewhat -- was 0.91

	strswitch (Experiment)
		case "Rubidium_I":  // Ioffe Prichard trap
			Bo = trapmin0/(1.4*0.5*Ipinch)
			Imot=27*Ibias/Irace
	
			trapmin= trapmin0 + (Ibias*.91)*1.4*0.5
			freqX=Irace*.579*(moment)^.5/(0.91*Ibias+Ipinch*Bo)^.5
			freqY=Irace*.579*(moment)^.5/(0.91*Ibias+Ipinch*Bo)^.5
			freqZ=.510*(Ipinch*moment)^.5						
		Break;
		case "Rubidium_II": // Dipole/quadrupole trap
		
			// Factor of 0.783373 converts the computed gradient to the measured
			// gradient (measured by looking at when the trap was anti-gravity)
			
			trapmin= (BeamZ*1e-6) * (IQuad * 62.9545 * 0.783373) + (Ibias * 3.14286) ; // In gauss
			trapmin *= 0.7 * (2*moment); // To MHz
			
			// freqY= sqrt( (2*moment)*0.00320704*(IQuad * 62.9545* 0.783373)/ (BeamZ*1e-6)) / (4*pi);

			trapdepth = 2*DipolePower / (pi * (WaistX*1e-6) * (WaistZ*1e-6))  * 1.55e-4; // In nK

			// freqX= sqrt((1.38e-32) * trapdepth / mass) / (pi*WaistX*1e-6);
			// freqX = sqrt(Freqx^2 + FreqY^2)
			// freqZ=  sqrt((1.38e-32) * trapdepth / mass) / (pi*WaistZ*1e-6);				
		Break;
		case "RbYb":
			// At the moment, we are using a hybrid Quad+dipole trap. 
			// Calculating the trap frequencies given beam power, displacement etc. is a pain in the ass.
			// Instead, we measure the trap frequencies at a couple of dipole beam powers and assume
			// linear scaling of the transverse trap frequencies with the square-root of the dipole power. The 
			// variable "FreqScaling" defines the coefficient of the scaling.
			// The trap frequency in the longitudnal direction is dominated by the magnetic trap and is very
			// insensitive to dipole power. This should be measured once and entered on the front panel in 
			// the Trap properties section.
			freqX = FreqScaling*sqrt(DipolePower);		
			freqZ = FreqScaling*sqrt(DipolePower);
		Break
		case "Sr":
			// At the moment, we are using a hybrid Quad+dipole trap. 
			// Calculating the trap frequencies given beam power, displacement etc. is a pain in the ass.
			// Instead, we measure the trap frequencies at a couple of dipole beam powers and assume
			// linear scaling of the transverse trap frequencies with the square-root of the dipole power. The 
			// variable "FreqScaling" defines the coefficient of the scaling.
			// The trap frequency in the longitudnal direction is dominated by the magnetic trap and is very
			// insensitive to dipole power. This should be measured once and entered on the front panel in 
			// the Trap properties section.
			//freqX = sqrt(0.925+CrDipolePower*FreqScalingX^2);
			//freqX = FreqScalingX*sqrt(exp(LambertWaprx(-Pc^2/DipolePower^2)/2)*(1.01+LambertWaprx(-Pc^2/DipolePower^2))*DipolePower);	
			freqX = 68.5;
			//freqY = FreqScalingY*sqrt(exp(LambertWaprx(-Pc^2/DipolePower^2)/2)*DipolePower);
			freqY = 68.5;	
			//freqZ = FreqScalingZ*sqrt(exp(LambertWaprx(-Pc^2/DipolePower^2)/2)*DipolePower*(LambertWaprx(-Pc^2/DipolePower^2)+1));
			freqZ = 0;
			freqXLat = 0;
			freqYLat = 0;
			freqZLat = 28.5e+3;
			k = 2*pi/(1064e-9);
		Break
	endswitch


	omgX = 2*Pi*freqX;	
	omgY = 2*Pi*freqY;
	omgZ = 2*Pi*freqZ;
	omgXLat = 2*Pi*freqXLat;	
	omgYLat = 2*Pi*freqYLat;
	omgZLat = 2*Pi*freqZLat;

	omg_ho = (omgX*omgY*omgZ)^(1/3);
	a_ho = Sqrt(1.054571596e-34/(mass*omg_ho))*1e6; // hbar = 1.054571596e-34 J s, a_ho microns
	aspectratio=(freqX)/(freqZ);
	aspectratio_BEC = aspectratio;

	// Compute the Castin Dum paramaters
	ComputeCastinDum();

	SetDataFolder fldrSav
End



// ****************************
// This function sets the x and y scale for all of the image related variables
// and slices

Function Update_Magnification() 
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR magnification=:Experimental_Info:magnification
	NVAR delta_pix=:Experimental_Info:delta_pix
	SVAR Camera = :Experimental_Info:Camera

	Wave optdepth=:optdepth
	
	duplicate/O optdepth :Fit_Info:fit_optdepth
	duplicate/O optdepth :Fit_Info:res_optdepth
	Wave fit_optdepth = :Fit_Info:fit_optdepth;
	Wave res_optdepth = :Fit_Info:res_optdepth;

	// Make sure all of the derived waves are of the correct size
	make/O/N=(DimSize(OptDepth,0)) :Fit_Info:xsec_row;
	make/O/N=(DimSize(OptDepth,0)) :Fit_Info:fit_xsec_row;
	make/O/N=(DimSize(OptDepth,0)) :Fit_Info:res_xsec_row;
	make/O/N=(DimSize(OptDepth,1)) :Fit_Info:xsec_col;
	make/O/N=(DimSize(OptDepth,1)) :Fit_Info:fit_xsec_col;
	make/O/N=(DimSize(OptDepth,1)) :Fit_Info:res_xsec_col;
	make/O/N=(DimSize(OptDepth, 0)) :LineProfiles:Slice

	Wave xsec_col=:Fit_Info:xsec_col,xsec_row=:Fit_Info:xsec_row
	Wave fit_xsec_col=:Fit_Info:fit_xsec_col,fit_xsec_row=:Fit_Info:fit_xsec_row
	Wave res_xsec_col=:Fit_Info:res_xsec_col,res_xsec_row=:Fit_Info:res_xsec_row
	Wave Slice = :LineProfiles:Slice
	Variable delta_X, delta_Y, starty, startx
	
	if (stringmatch(Camera,"PixelFly") == 1)	//PixelFly Camera
		delta_X = 6.45/magnification;
		delta_Y = 6.45/magnification;
		starty = -DimSize(OptDepth, 1)*delta_Y/2;
		startx = -DimSize(OptDepth, 0)*delta_X/2;
	elseif (stringmatch(Camera,"PI") == 1)	// PI Camera
		delta_X = 15/magnification;
		delta_Y = 15/magnification;
		startY = -DimSize(OptDepth, 1)*delta_Y/2;
		startX = -DimSize(OptDepth, 0)*Delta_X/2;
	elseif (stringmatch(Camera,"LG3") == 1) // LG3 Frame grabber
		delta_X = 10 / magnification;
		delta_Y = 10 / magnification;
		starty = -DimSize(OptDepth, 1)*Delta_Y / 2;
		startx = -DimSize(OptDepth, 0)*Delta_X / 2;
	elseif (stringmatch(Camera,"THOR") == 1) // Thorlabs CCD Cameras
		delta_X = 7.4 / magnification;
		delta_Y = 7.4 / magnification;
		starty = -DimSize(OptDepth, 1)*Delta_Y / 2;
		startx = -DimSize(OptDepth, 0)*Delta_X / 2;
	elseif (stringmatch(Camera,"Flea2_13S2") == 1) // Flea2 13S2 camera
		delta_X = 3.75 / magnification;
		delta_Y = 3.75 / magnification;
		starty = -DimSize(OptDepth, 1)*Delta_Y / 2;
		startx = -DimSize(OptDepth, 0)*Delta_X / 2;
	elseif (stringmatch(Camera,"PIXIS") == 1) // PI Pixis camera
		delta_X = 2*13 / magnification;
		delta_Y = 2*13 / magnification;
		starty = -DimSize(OptDepth, 1)*Delta_Y / 2;
		startx = -DimSize(OptDepth, 0)*Delta_X / 2;
	elseif (stringmatch(Camera,"Flea3") == 1) // Flea 3 camera
		delta_X = 5.6 / magnification;
		delta_Y = 5.6 / magnification;
       	starty = -DimSize(OptDepth, 1)*Delta_Y / 2;
		startx = -DimSize(OptDepth, 0)*Delta_X / 2;
	elseif (stringmatch(Camera,"Flea3_20S4M") == 1) // Flea 3 camera
		delta_X = 4.4 / magnification;
		delta_Y = 4.4 / magnification;
       	starty = -DimSize(OptDepth, 1)*Delta_Y / 2;
		startx = -DimSize(OptDepth, 0)*Delta_X / 2;
	else
		delta_X = 1/magnification
		delta_Y = 1/magnification
		starty = -DimSize(OptDepth, 1)*delta_Y/2;
		startx = -DimSize(OptDepth, 0)*delta_X/2;
	endif
	
	delta_pix = delta_X;

	// Now update all the effected waves
	SetScale/P x startx,delta_X,"", optdepth
	SetScale/P y starty,delta_Y,"", optdepth
	SetScale/P x startx,delta_X,"", fit_optdepth
	SetScale/P y starty,delta_Y,"", fit_optdepth
	SetScale/P x startx,delta_X,"", res_optdepth
	SetScale/P y starty,delta_Y,"", res_optdepth
	
	SetScale/P x startx,delta_X,"", slice
	SetScale/P x starty,delta_Y,"", xsec_col
	SetScale/P x startx,delta_X,"", xsec_row
	SetScale/P x starty,delta_Y,"", fit_xsec_col
	SetScale/P x startx,delta_X,"", fit_xsec_row
	SetScale/P x starty,delta_Y,"", res_xsec_col
	SetScale/P x startx,delta_X,"", res_xsec_row

	// Sanity check the ROI
	NVAR ymax=:fit_info:ymax, ymin=:fit_info:ymin
	NVAR xmax=:fit_info:xmax, xmin=:fit_info:xmin

	variable Xmin_limit =  DimOffset(OptDepth,0);
	variable Xmax_limit =  DimOffset(OptDepth,0) + DimSize(OptDepth,0)*DimDelta(OptDepth,0);

	variable Ymin_limit =  DimOffset(OptDepth,1);
	variable Ymax_limit = DimOffset(OptDepth,1) + DimSize(OptDepth,1)*DimDelta(OptDepth,1);

	// if I am not inbounds, set them to be the extents of the image.
	// Note that the FALSE case is always the limit values -- this is by design:
	// of Xmin (for example) were Nan for some reason, the comparson will return FALSE
	// and xmin will be set to a number
	
	Xmin = (Xmin > Xmin_limit ? Xmin : Xmin_limit);
	Xmin = (Xmin < Xmax_limit ? Xmin : Xmin_limit);
	Xmax = (Xmax < Xmax_limit ? Xmax : Xmax_limit);
	Xmax = (Xmax > Xmin_limit ? Xmax : Xmax_limit);

	Ymin = (Ymin > Ymin_limit ? Ymin : Ymin_limit);
	Ymin = (Ymin < Ymax_limit ? Ymin : Ymin_limit);
	Ymax = (Ymax < Ymax_limit ? Ymax : Ymax_limit);
	Ymax = (Ymax > Ymin_limit ? Ymax : Ymax_limit);

	SetDataFolder fldrSav
End

// ********************************************************
// ********************************************************
// INDEXED WAVES PROCEDURES
// ********************************************************
// ********************************************************

// The following procedures deal with the management of the running, or indexed waves
// Care is needed because indexed waves can be specified by an image file's header, and thus
// need to be dynamicaly mantained.

// ********************************************************
//
// Init_IndexedWaves
//  creates the empty indexed waves folder with
// "index"  the current index that is to be updated in the indexed wave
// "IndexedWaves" a ";" delimiated list of wave names
// "IndexedVariables" a ";" delimiated list of variables associated with each indexed wave
// where (index = 0, IndexedWaves = "", IndexedVariables = "");
//
// ********************************************************

function Init_IndexedWaves()
	// Get the current path
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Create the required path
	NewDataFolder/O :IndexedWaves;
	
	// The global variables
	Variable/G :IndexedWaves:Index = 0;
	Variable/G :IndexedWaves:autoupdate = 1;
	String/G :IndexedWaves:IndexedWaves = "";
	String/G :IndexedWaves:IndexedVariables = "";
	
	// And for 2d wave indexing of fits	--CDH 09.Feb.2012
	NewDataFolder/O :IndexedWaves:FitWaves;
	String/G :IndexedWaves:FitWaves:Indexed2DWaveNames="";	// the 2D running wave
	String/G :IndexedWaves:FitWaves:IndexedFitWaves="";	// the 1D fit coefs

	SetDataFolder fldrSav
end


// ********************************************************
//
// Exists_IndexedWave(Name)
// checks to see if a project in the path CheckFolder exists, retuns 1 if so
//
// ********************************************************
function Exists_IndexedWave(Name)
	string Name
	// Get the current path
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder;

	SVAR IndexedWaves = :IndexedWaves:IndexedWaves;

	// see if the desired item is in the list.
	if (WhichListItem(Name, IndexedWaves) == -1)

		SetDataFolder fldrSav
		return 0;
	endif
	
	SetDataFolder fldrSav
	return 1;
end

//2D version	--CDH 09.Feb.2012
function Exists_Indexed2DWave(Name)
	string Name
	// Get the current path
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder;

	SVAR Indexed2DWaveNames = :IndexedWaves:FitWaves:Indexed2DWaveNames;

	// see if the desired item is in the list.
	if (WhichListItem(Name, Indexed2DWaveNames) == -1)

		SetDataFolder fldrSav
		return 0;
	endif
	
	SetDataFolder fldrSav
	return 1;
end


// ********************************************************
//
// New_IndexedWave(IndexedWave, IndexedVariable)
// Created a new IndexedWave bound to the variable IndexedVariable
//
// ********************************************************
function New_IndexedWave(IndexedWave, IndexedVariable)
	string IndexedWave;
	string IndexedVariable;
	
	// Verify that the IndexedWave does not already exist!
	if (Exists_IndexedWave(IndexedWave) == 1)
		return 0;
	endif

	// Get the current path
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	SVAR IndexedWaves = :IndexedWaves:IndexedWaves;
	SVAR IndexedVariables = :IndexedWaves:IndexedVariables;


	// Create the wave and variable if needed

	Make/O/D/N=0 $(":IndexedWaves:" + IndexedWave);

	if (exists(IndexedVariable) == 0)
		Variable/G $IndexedVariable = 1;
	endif 
	
	IndexedWaves = AddListItem(IndexedWave, IndexedWaves,";",Inf);
	IndexedVariables = AddListItem(IndexedVariable, IndexedVariables,";",Inf);

	SetDataFolder fldrSav;
end

//2D version	--CDH 09.Feb.2012
function New_Indexed2DWave(Indexed2DWaveName, IndexedFitWave)
	string Indexed2DWaveName;
	string IndexedFitWave;
	
	// Verify that the IndexedWave does not already exist!
	if (Exists_Indexed2DWave(Indexed2DWaveName) == 1)
		return 0;
	endif

	// Get the current path
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	SVAR Indexed2DWaveNames = :IndexedWaves:FitWaves:Indexed2DWaveNames;
	SVAR IndexedFitWaves = :IndexedWaves:FitWaves:IndexedFitWaves;


	// Create the wave and variable if needed

	Make/O/N=(1,1) $(":IndexedWaves:FitWaves:" + Indexed2DWaveName);

	if (exists(IndexedFitWave) == 0)
		Make/N=0 $IndexedFitWave;
	endif 
	
	Indexed2DWaveNames = AddListItem(Indexed2DWaveName, Indexed2DWaveNames,";",Inf);
	IndexedFitWaves = AddListItem(IndexedFitWave, IndexedFitWaves,";",Inf);

	SetDataFolder fldrSav;
end


// ********************************************************
//
// Update_IndexedWaves()
// Updates the indexed waves at the current index to the variable
// to which they are bound.
//
// ********************************************************
function Update_IndexedWaves()
	// Get the current path
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder;

	SVAR IndexedWaves = :IndexedWaves:IndexedWaves;
	SVAR IndexedVariables = :IndexedWaves:IndexedVariables;
	NVAR Index = :IndexedWaves:Index;
	// 2D lists
	SVAR Indexed2DWaveNames = :IndexedWaves:FitWaves:Indexed2DWaveNames;
	SVAR IndexedFitWaves = :IndexedWaves:FitWaves:IndexedFitWaves;
	
	variable i, npnts;
	string IndexedWave, IndexedVariable;
	
	npnts = ItemsInList(IndexedWaves);
	if (npnts != ItemsInList(IndexedVariables) )
		print "Update_IndexedWaves:  IndexedVariables and IndexedWaves do not match";
		SetDataFolder fldrSav;
		return -1;
	endif
	
	for (i = 0; i < npnts; i+= 1)
		IndexedWave = ":IndexedWaves:" + StringFromList(i, IndexedWaves);
		IndexedVariable = StringFromList(i, IndexedVariables);
		
		// Verify that the wave and variable exist, if not create them
		if (exists(IndexedWave)==0)
			print "Update_IndexedWaves:  Expected wave", IndexedWave, "not found, recreating."; 
			Make/O/N=0 $(IndexedWave);
		endif
		
		if (exists(IndexedVariable)==0)
			print "Update_IndexedWaves:  Expected variable", IndexedVariable, "not found, recreating."; 
			Variable/G $(IndexedVariable) = nan;
		endif

		// Now assign the variables and update the running wave		
		Wave LocalIndexedWave = $IndexedWave;
		NVAR LocalIndexedVariable = $IndexedVariable;
		
		// make sure wave is large enough
		if (Index >= numpnts(LocalIndexedWave))
			redimension/N=(Index +1) LocalIndexedWave;
		endif
		
		LocalIndexedWave[Index] = LocalIndexedVariable;
	endfor

	// 2D waves	--CDH 09.Feb.2012
	string Indexed2DWave, IndexedFitWave;
	variable FitWaveLength
	
	npnts = ItemsInList(Indexed2DWaveNames)
	if (npnts != ItemsInList(IndexedFitWaves))
		print "Update_IndexedWaves:  IndexedFitWaves and Indexed2DWaveNames do not match";
		SetDataFolder fldrSav;
		return -1;
	endif
	
	for (i = 0; i < npnts; i+= 1)
		Indexed2DWave = ":IndexedWaves:FitWaves:" + StringFromList(i, Indexed2DWaveNames);
		IndexedFitWave = StringFromList(i, IndexedFitWaves);
		
		// Verify that the wave and variable exist, if not create them
		if (exists(Indexed2DWave)==0)
			print "Update_IndexedWaves:  Expected 2D wave", Indexed2DWave, "not found, recreating."; 
			Make/O/N=(1,1) $(Indexed2DWave);
		endif
		
		if (exists(IndexedFitWave)==0)
			print "Update_IndexedWaves:  Expected fit wave", IndexedFitWave, "not found, recreating."; 
			Make/O/N=0 $(IndexedFitWave);
		endif

		// Now assign the variables and update the running wave		
		WAVE LocalIndexed2DWave = $Indexed2DWave;
		WAVE LocalIndexedFitWave = $IndexedFitWave;
		
		// make sure wave is large enough
		FitWaveLength = numpnts(LocalIndexedFitWave);
		if (dimsize(LocalIndexed2DWave,1) < FitWaveLength)
			Redimension/N=(-1,FitWaveLength) LocalIndexed2DWave;	// columns match Fit wave length
		endif
		if (Index >= dimsize(LocalIndexed2DWave,0))
			redimension/N=(Index +1,-1) LocalIndexed2DWave;
		endif
		
		LocalIndexed2DWave[Index][] = LocalIndexedFitWave[q];
	endfor
	
	
	SetDataFolder fldrSav;
	return 0;
end


// ********************************************************
//
// Graph_IndexedWaves(XIndexedWave, YIndexedWave)
// Makes an XY graph of two indexed waves (later make a list?)
//
// ********************************************************
function Graph_IndexedWaves(XIndexedWave, YIndexedWave)
	string XIndexedWave, YIndexedWave;
	
	// Verify that the IndexedWaves exist!
	if (Exists_IndexedWave(XIndexedWave) == 0)
		print "Graph_IndexedWave: reqested wave does not exist: ", XIndexedWave;
		return 0;
	endif

	if (Exists_IndexedWave(YIndexedWave) == 0)
		print "Graph_IndexedWave: reqested wave does not exist: ", YIndexedWave;
		return 0;
	endif

	// Get the current path
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	Display $(":IndexedWaves:" + YIndexedWave) vs $(":IndexedWaves:" + XIndexedWave);
	Label left YIndexedWave;
	Label bottom XIndexedWave;
	FormatGraph(0, 0, 0);	

	SetDataFolder fldrSav;
end

// **********************Resize_IndexedWaves ********************************
// This utility wave resizes all of the running waves

Function ResizeRunningWaves(wavesize)
	variable wavesize

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Currently I do nothing at all!	 	(But Reset button requires me!)

	SetDataFolder fldrSav
end


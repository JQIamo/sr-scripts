#pragma rtGlobals=1		// Use modern global access method.
#include <Image Line Profile>	// used for making an arbitrary slice
#include <Multi-peak fitting 2.0>

//! @file
//! @brief This file contains various functions that either construct or
//! are directly called by the GUI.
//! @details There should be an absolute minimum of actual analysis performed here

// ********************************************************
// Create the menu structure that the user interacts with

//! @cond DOXY_HIDE_GRAPH_MENU
Menu "ColdAtom"
	"New data series...", Dialog_New_ColdAtomInfo();
	"Rename data series...", Dialog_Rename_ColdAtomInfo();
	"Delete data series...", Dialog_Delete_ColdAtomInfo();
	"Copy data series...", Dialog_Copy_ColdAtomInfo();
	"Bring to front...", Dialog_Set_ColdAtomInfo();
	"Graph indexed Waves...", Dialog_Graph_IndexedWaves();
	"View image header...", Dialog_ViewHeader();
	"Copy ROI cursors...", Dialog_CopyROI();
	"Save ROI...", Dialog_SaveROI();
	"Load ROI...", Dialog_LoadROI();
	"Sort data series...", Dialog_SortIndexedWaves();
	"Separate Data by Key...", Dialog_DecimateIndexedWaves();
	"Process XY wave pair...", Dialog_DataSortXYWaves();
	"Bin Process XY wave pair...", Dialog_BinSortXYWaves();
	"-",""	//make divider line
	"Set BatchRun base name...", Dialog_SetBasePath();
	"Copy BatchRun base name...", Dialog_CopyBasePath();
	"Do BatchRun...", Dialog_DoBatchRun();
End
//! @endcond

//!
//! @brief Create dialog interface to ::Rename_ColdAtomInfo
//! @return \b -1 on cancelled or error
//! @return \b NaN otherwise
function Dialog_Rename_ColdAtomInfo()
	variable ProjectNum;
	string ProjectID;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath

	Prompt ProjectNum, "Rename...", popup, ActivePaths
	Prompt ProjectID, "New name (without \"root:\")"
	DoPrompt "Rename project...", ProjectNum, ProjectID

	if (V_Flag)
		return -1		// User canceled
	endif
	
	Rename_ColdAtomInfo( StringFromList(ProjectNum-1, ActivePaths), "root:" + ProjectID)
end

//!
//! @brief Create dialog interface to ::Set_ColdAtomInfo
//! @return \b -1 on cancelled or error
//! @return \b NaN otherwise
function Dialog_Set_ColdAtomInfo()
	variable ProjectNum;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath

	string title = "Switch from " + CurrentPath + "to...";

	Prompt ProjectNum, title, popup, ActivePaths
	DoPrompt "Switch project...", ProjectNum

	if (V_Flag)
		return -1		// User canceled
	endif
	
	Set_ColdAtomInfo( StringFromList(ProjectNum-1, ActivePaths) )
end


//!
//! @brief Create dialog interface to ::Delete_ColdAtomInfo
//! @return \b -1 on cancelled or error
//! @return \b NaN otherwise
function Dialog_Delete_ColdAtomInfo()
	variable ProjectNum;
	string ProjectID;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR ActivePanels = root:Packages:ColdAtom:ActivePanels

	Prompt ProjectNum, "Item to delete...", popup, ActivePaths
	DoPrompt "ColdAtom BEC Analysis", ProjectNum

	if (V_Flag)
		return -1		// User canceled
	endif

	Delete_ColdAtomInfo( StringFromList(ProjectNum-1, ActivePaths));
end


function Dialog_Copy_ColdAtomInfo()
	// DSB 2/16/15
	// This function copies an entire data series
	string ProjectID;
	variable ProjToCopy

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist
	
	// Build the User Diolog Box
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR ActivePanels = root:Packages:ColdAtom:ActivePanels
	Prompt ProjectID, "New Project Folder"
	Prompt ProjToCopy, "Series to Copy", popup, ActivePaths
	DoPrompt "ColdAtom BEC Analysis", ProjectID, ProjToCopy;
	
	if (V_Flag)
		return -1		// User canceled
	endif
	
	//prevent errors in series creation
	string temp = CleanupName(ProjectID,0)
	ProjectID = temp
	
	String CopyProjPath= StringFromList(ProjToCopy-1, ActivePaths)
	SVAR IDtemp = $(CopyProjPath + ":Experimental_Info:Experiment")
	String CopyExperimentID = IDtemp

	Copy_ColdAtomInfo(ProjectID, CopyProjPath, CopyExperimentID)
end

//!
//! @brief Create new notebook containing contents of wave note
//! @details Assumes wave note has been copied into <em>:Experimental_Info:HeaderString<\em>
//! when the image is loaded from disk.
//!
//! @return \b -1 on cancelled or error
//! @return \b NaN otherwise
function Dialog_ViewHeader()
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	if (strlen(ProjectFolder) == 0)
		print "Dialog_Graph_IndexedWaves:  No project folder found";
		return -1;	// Probabaly have not created any displays.
	endif
	String fldrSav= GetDataFolder(1);
	SetDataFolder ProjectFolder;

	// If a "FileHeader" window is open, close it.
	if ( FindListItem("FileHeader", WinList("*", ";","WIN:16")) != -1)
		KillWindow FileHeader;
	endif

	NewNotebook/F=0/K=1/N=FileHeader

	execute "Notebook FileHeader, text=:Experimental_Info:HeaderString";

	SetDataFolder fldrSav;
end

//!
//! @brief Create dialog interface to ::Graph_IndexedWaves
//! @return \b -1 on cancelled or error
//! @return \b NaN otherwise
function Dialog_Graph_IndexedWaves()
	variable XIndexNum, YIndexNum;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	if (strlen(ProjectFolder) == 0)
		print "Dialog_Graph_IndexedWaves:  No project folder found";
		return -1;	// Probabaly have not created any displays.
	endif
	String fldrSav= GetDataFolder(1);
	SetDataFolder ProjectFolder;

	// Create a dialog box with a list of active InfoProjects
	SVAR IndexedWaves = :IndexedWaves:IndexedWaves;

	string title = "Graph indexed waves in " + ProjectFolder;

	Prompt YIndexNum, "Y Axes", popup, IndexedWaves;
	Prompt XIndexNum, "X Axes", popup, IndexedWaves;	
	DoPrompt title, YIndexNum, XIndexNum

	if (V_Flag)
		return -1		// User canceled
	endif

	Graph_IndexedWaves(StringFromList(XIndexNum-1, IndexedWaves), StringFromList(YIndexNum-1, IndexedWaves));
	SetDataFolder fldrSav;
end

//!
//! @brief Create dialog interface to copy the Region Of Interest from one data series to another
//! @return \b -1 on cancelled or error
//! @return \b NaN otherwise
function Dialog_CopyROI()
	
	variable TargProjectNum;
	variable HostProjectNum;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
	
	Prompt HostProjectNum, "Copy ROI From...", popup, ActivePaths
	Prompt TargProjectNum, "To...", popup, ActivePaths
	DoPrompt "Copy ROI cursor positions", HostProjectNum, TargProjectNum
	
	if(V_Flag)
		return -1		// User canceled
	endif
	
	if(HostProjectNum != TargProjectNum)
	
		String HostPath = StringFromList(HostProjectNum-1, ActivePaths)
		String TargPath = StringFromList(TargProjectNum-1, ActivePaths)
		
		String SavePanel = CurrentPanel
		String SavePath = CurrentPath
		String fldrSav= GetDataFolder(1)
		
		Set_ColdAtomInfo(HostPath)
		String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
		
		String ProjectFolder = Activate_Top_ColdAtomInfo();
		SetDataFolder ProjectFolder
		
		NVAR ymax=:fit_info:ymax,ymin=:fit_info:ymin;
		NVAR xmax=:fit_info:xmax,xmin=:fit_info:xmin;
		NVAR bgymax=:fit_info:bgymax,bgymin=:fit_info:bgymin;
		NVAR bgxmax=:fit_info:bgxmax,bgxmin=:fit_info:bgxmin;
		
		variable x_A = xmax
		variable y_A = ymax
		variable x_B = xmin
		variable y_B = ymin
		variable x_C = bgxmax
		variable y_C = bgymax
		variable x_D = bgxmin
		variable y_D = bgymin
		
		Set_ColdAtomInfo(TargPath)
		ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
		Cursor/I/W=$(ImageWindowName) A, optdepth, x_A, y_A;
		Cursor/I/W=$(ImageWindowName) B, optdepth, x_B, y_B;
		Cursor/I/W=$(ImageWindowName) C, optdepth, x_C, y_C;
		Cursor/I/W=$(ImageWindowName) D, optdepth, x_D, y_D;
		SetROI("",1,"")
		
		Set_ColdAtomInfo(SavePath)
		SetDataFolder fldrSav
	endif
end


// ******************** BuildRubidiumIWindow **********************************************************************
//!
//! @brief Build GUI window for RubidiumI
//! @param[in] ProjectFolder  The data folder to tie this window to.
function BuildRubidiumIWindow(ProjectFolder)
	String ProjectFolder
	
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	String WindowTitle = "Rubidium_I:" + ProjectFolder;
	
	// Make a new window with killing disabeled
	// NewPanel/K=2/W=(370,44,1024,768) as WindowTitle;
	NewPanel/W=(370,44,1024,768) as WindowTitle;
	
	svar CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	CurrentPanel = S_name;
	
	SetDrawLayer UserBack
	DrawText 237,281,"Width [um]"
	DrawText 237,211,"Position [um]"
	DrawText 238,369,"Width [um]"
	DrawText 443,281,"Width [um]"
	DrawText 444,373,"Width [um]"
	DrawLine 28,292,206,292
	
	// Experimental properties
	CheckBox UpdateFromFile,pos={23,24},size={141,14},proc=UpdateFromFile,title="Update properties from file"
	CheckBox UpdateFromFile,value= 1

	SetVariable FileName,pos={89,39},size={119,15},disable=2,title="FileName"
	SetVariable FileName,value= :Experimental_Info:FileName,bodyWidth= 75

	SetVariable CameraID,pos={95,57},size={113,15},disable=2,title="Camera"
	SetVariable CameraID,value= :Experimental_Info:Camera,bodyWidth= 75
	
	SetVariable Irace,pos={48,75},size={160,15},proc=SetBfield,title="Racetrack [Amps]"
	SetVariable Irace,value= :Experimental_Info:Irace,bodyWidth= 75

	SetVariable Ipinch,pos={49,93},size={159,15},proc=SetBfield,title="Pinch Coil [Amps]"
	SetVariable Ipinch,value= :Experimental_Info:IPinch,bodyWidth= 75

	SetVariable Ibias,pos={74,111},size={134,15},proc=SetBfield,title="Bias [Amps]"
	SetVariable Ibias,value= :Experimental_Info:IBias,bodyWidth= 75

	SetVariable TrapMin0,pos={36,129},size={172,15},proc=SetBfield,title="Trap Min @ 0  [MHz]"
	SetVariable TrapMin0,limits={-inf,inf,0.0001},value= :Experimental_Info:TrapMin0,bodyWidth= 75

	SetVariable detuning,pos={91,147},size={117,15},title="Detuning"
	SetVariable detuning,value= :Experimental_Info:Detuning,bodyWidth= 75

	SetVariable expandtime,pos={39,166},size={169,15},title="ExpansionTime [ms]"
	SetVariable expandtime,value= :Experimental_Info:expand_time,bodyWidth= 75

	PopupMenu FindCenter,pos={25,270},size={152,20},proc=ChooseCenter
	PopupMenu FindCenter,mode=1,bodyWidth= 152,popvalue="Find center from max",value= #"\"Find center from max;Center follows cursor;Center from cursor\""

	Button index_reset,pos={26,347},size={45,20},proc=ResetIndex,title="Reset"
	
	PopupMenu popup0,pos={25,187},size={109,20},proc=SetTrapType
	PopupMenu popup0,mode=1,bodyWidth= 109,popvalue="Magnetic Trap",value= #"\"Magnetic Trap;MOT;MOT Diagnostics\""

	PopupMenu flevel,pos={140,187},size={51,20},proc=SetHyperfineLevel
	PopupMenu flevel,mode=1,popvalue="F=1",value= #"\"F=1;F=2\""

	SetVariable magn,pos={0,427},size={139,15},proc=Set_Mag,title="Magnification"
	SetVariable magn,value= :Experimental_Info:magnification,bodyWidth= 60

	SetVariable PeakOD,pos={24,409},size={100,15},proc=Set_PeakOD,title="Peak OD",fSize=9
	SetVariable PeakOD,format="%.2f"
	SetVariable PeakOD,value= :Experimental_Info:PeakOD,bodyWidth= 60
		
	// Fitting properties
	PopupMenu CamDir_popup,pos={25,214},size={109,20},proc=SetCamDir
	PopupMenu CamDir_popup,mode=1,bodyWidth= 109,popvalue="XY imaging"
	PopupMenu CamDir_popup,value= #"\"XY imaging;XZ imaging;\""

	PopupMenu FitTypePopup,pos={25,242},size={109,20},proc=SetFit_Type
	PopupMenu FitTypePopup,mode=1,bodyWidth= 109,popvalue="Thermal 1D",value= #"\"Thermal 1D;TF+Thermal 1D;TF only 1D;TF+Thermal 2D;TF only 2D;Thermal 2D;None\""
		
	Button refit,pos={169,378},size={45,20},proc=Refit,title="Refit"

	PopupMenu AutoUpdate,pos={26,320},size={152,20},proc=SetAutoUpdate
	PopupMenu AutoUpdate,mode=1,bodyWidth= 152,popvalue="Auto increment"
	PopupMenu AutoUpdate,value= #"\"No update;Auto increment;Index from file;\""

	Button manual_update,pos={152,347},size={50,20},proc=ManUpdate,title="Update"
	
	SetVariable IndexDisplay,pos={138,298},size={68,15},title="Index"
	SetVariable IndexDisplay,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable IndexDisplay,value= :IndexedWaves:index
	
	CheckBox GetScopeTrace,pos={25,296},size={91,14},proc=GetScopeTrace,title="Get Scope Trace"
	CheckBox GetScopeTrace,value= 0

	Button dec_update,pos={87,347},size={50,20},proc=dec_update,title="dec."
	
	PopupMenu SetROI,pos={16,378},size={141,20},proc=SetROI
	PopupMenu SetROI,mode=1,bodyWidth= 141,popvalue="Set ROI",value= #"\"Set ROI;Set ROI and zoom;Zoom to ROI;Unzoom\""

	Button Slice,pos={282,425},size={45,20},proc=Call_MakeSlice,title="Slice"

	SetVariable SliceWidth,pos={178,427},size={94,15},title="Slice Width",fSize=9
	SetVariable SliceWidth,format="%d"
	SetVariable SliceWidth,value= :Fit_Info:slicewidth,bodyWidth= 40

	// Trap properties
	SetVariable fx,pos={290,24},size={128,15},title="X trap freq"
	SetVariable fx,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable fx,value= :Experimental_Info:freqX

	SetVariable fy,pos={290,38},size={128,15},title="Y trap freq"
	SetVariable fy,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable fy,value= :Experimental_Info:freqY

	SetVariable fz,pos={290,52},size={128,15},title="Z trap freq"
	SetVariable fz,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable fz,value= :Experimental_Info:freqZ

	SetVariable aspetratio,pos={283,68},size={136,14},title="Aspect Ratio"
	SetVariable aspetratio,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable aspetratio,value= :Experimental_Info:AspectRatio
	
	SetVariable Trapbottom,pos={246,86},size={173,14},title="Trap Minimum [MHz]"
	SetVariable Trapbottom,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable Trapbottom,value= :Experimental_Info:trapmin

	SetVariable valdisp0,pos={243,102},size={176,14},title="Vertical shift current"
	SetVariable valdisp0,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable valdisp0,value= :Experimental_Info:Imot

	// Thermal cloud properties
	SetVariable temp,pos={239,156},size={180,14},title="Temperature [nK]"
	SetVariable temp,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable temp,value= :temperature

	SetVariable number,pos={287,173},size={132,14},title="Number"
	SetVariable number,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable number,value= :number

	SetVariable center_x,pos={238,210},size={50,14},title="X"
	SetVariable center_x,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable center_x,value= :xposition

	SetVariable center_y,pos={303,210},size={50,14},title="Y"
	SetVariable center_y,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable center_y,value= :yposition

	SetVariable center_z,pos={369,210},size={50,14},title="Z"
	SetVariable center_z,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable center_z,value= :zposition

	// Imaged cloud properties
	SetVariable rms_x,pos={238,281},size={50,14},title="X"
	SetVariable rms_x,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_x,value= :xrms

	SetVariable rms_y,pos={304,281},size={50,14},title="Y"
	SetVariable rms_y,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_y,value= :yrms

	SetVariable rms_z,pos={366,281},size={50,14},title="Z"
	SetVariable rms_z,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_z,value= :zrms

	SetVariable dens,pos={238,304},size={180,14},title="Density (1/um^3)"
	SetVariable dens,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable dens,value= :density
	
	// Inital cloud properties
	SetVariable rms_x_t0,pos={241,371},size={47,14},title="X"
	SetVariable rms_x_t0,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_x_t0,limits={0,0,0},barmisc={0,1000},value= :xrms_t0
	
	SetVariable rms_y_t0,pos={303,371},size={46,14},title="Y"
	SetVariable rms_y_t0,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_y_t0,limits={0,0,0},barmisc={0,1000},value= :yrms_t0

	SetVariable rms_z_t0,pos={364,371},size={45,14},title="Z"
	SetVariable rms_z_t0,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_z_t0,limits={0,0,0},barmisc={0,1000},value= :zrms_t0

	SetVariable dens_t0,pos={239,398},size={180,14},title="Density (1/um^3)"
	SetVariable dens_t0,limits={0,0,0},barmisc={0,1000},bodyWidth= 75
	SetVariable dens_t0,value= :density_t0

	// BEC cloud properties
	SetVariable BECnum,pos={448,150},size={184,14},title="Number (absorption)"
	SetVariable BECnum,limits={0,0,0},barmisc={0,1000},bodyWidth= 75
	SetVariable BECnum,value= :number_BEC

	SetVariable BECnum01,pos={477,168},size={150,14},title="Number (TF)"
	SetVariable BECnum01,limits={0,0,0},barmisc={0,1000},bodyWidth= 75
	SetVariable BECnum01,value= :number_TF

	SetVariable chempot,pos={450,187},size={180,14},title="Chemical Potential (Hz)"
	SetVariable chempot,limits={0,0,0},barmisc={0,1000},bodyWidth= 75
	SetVariable chempot,value= :chempot

	// Imaged BEC properties	
	SetVariable BECxrms,pos={446,282},size={50,14},title="X"
	SetVariable BECxrms,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECxrms,value= :xwidth_BEC

	SetVariable BECyrms,pos={508,282},size={50,14},title="Y"
	SetVariable BECyrms,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECyrms,value= :ywidth_BEC

	SetVariable BECzrms,pos={570,282},size={50,14},title="Z"
	SetVariable BECzrms,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECzrms,value= :zwidth_BEC

	SetVariable dens01,pos={447,305},size={180,14},title="Density (1/um^3)"
	SetVariable dens01,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable dens01,value= :density_BEC

	SetVariable R_TF_1,pos={528,262},size={90,14},title="RTF (um)"
	SetVariable R_TF_1,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable R_TF_1,value= :radius_TF

	// Initial BEC properties

	SetVariable BECxrms01,pos={446,375},size={50,14},title="X"
	SetVariable BECxrms01,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECxrms01,value= :xwidth_BEC_t0

	SetVariable BECyrms01,pos={508,375},size={50,14},title="Y"
	SetVariable BECyrms01,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECyrms01,value= :ywidth_BEC_t0

	SetVariable BECzrms01,pos={570,375},size={50,14},title="Z"
	SetVariable BECzrms01,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECzrms01,value= :zwidth_BEC_t0

	SetVariable dens0101,pos={447,398},size={180,14},title="Density (1/um3)"
	SetVariable dens0101,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable dens0101,value= :density_BEC_t0

	SetVariable R_TF,pos={528,351},size={90,14},title="RTF (um)"
	SetVariable R_TF,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable R_TF,value= :radius_TF_t0

	// BEC input paramaters

	SetVariable CastDumX,pos={543,29},size={90,15},proc=SetCastDum,title="X "
	SetVariable CastDumX,value= :Experimental_Info:CastDum_xscale,bodyWidth= 75

	SetVariable CastDumy,pos={558,47},size={75,15},proc=SetCastDum,title="Y "
	SetVariable CastDumy,value= :Experimental_Info:CastDum_yscale,bodyWidth= 75

	SetVariable CastDumz,pos={558,65},size={75,15},proc=SetCastDum,title="Z "
	SetVariable CastDumz,value= :Experimental_Info:CastDum_zscale,bodyWidth= 75

	GroupBox TrapProps2,pos={229,245},size={198,84},title="Imaged cloud (t = timage)"
	GroupBox TrapProps2,fSize=11
	GroupBox TrapProps3,pos={441,245},size={198,84},title="Imaged cloud (t = timage)"
	GroupBox TrapProps3,fSize=11
	GroupBox TrapProps4,pos={441,336},size={198,84},title="Initial cloud (t = 0)"
	GroupBox TrapProps4,fSize=11
	GroupBox TrapProps5,pos={229,336},size={198,84},title="Initial cloud (t = 0)"
	GroupBox TrapProps5,fSize=11
	GroupBox TrapProps6,pos={229,133},size={198,104},title="Thermal cloud properties"
	GroupBox TrapProps6,fSize=11
	GroupBox TrapProps7,pos={441,133},size={198,104},title="BEC cloud properties"
	GroupBox TrapProps7,fSize=11
	GroupBox TrapProps8,pos={229,8},size={198,117},title="Trap properties"
	GroupBox TrapProps8,fSize=11
	GroupBox TrapProps9,pos={441,8},size={198,117},title="Castin-Dum scale paramaters"
	GroupBox TrapProps9,fSize=11
	GroupBox TrapProps0,pos={16,8},size={196,367},title="Experimental properties"
	GroupBox TrapProps0,fSize=11
	Display/W=(16,448,327,710)/HOST=# 
	AppendImage optdepth
	ModifyImage optdepth ctab= {-0.3,3.0,Rainbow,1};
	ModifyGraph gfSize=12,wbRGB=(56797,56797,56797)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph lblMargin(left)=8
	ModifyGraph standoff=0
	ModifyGraph axOffset(left)=0.666667
	ModifyGraph axThick=0.5
	ModifyGraph zeroThick=0.5
	ModifyGraph btLen=3
	ModifyGraph btThick=0.5
	ModifyGraph stLen=2
	ModifyGraph stThick=0.5
	ModifyGraph ttThick=0.5
	ModifyGraph ftThick=0.5
	
	Label left "Y/Z Position [\\f02\\F'Symbol'm\\f00\\]0m\\E]"
	Label bottom "X Position [\\f02\\F'Symbol'm\\f02\\]0m\\E]"
	Cursor/P/I/S=2/H=1/C=(65280,65280,0) A optdepth 453,540;Cursor/P/I/S=2/H=1/C=(65280,0,0) B optdepth 131,142
	RenameWindow #,ColdAtomInfoImage
	SetActiveSubwindow ##
	Display/W=(329,425,640,710)/HOST=#  :fit_info:xsec_col,:fit_info:fit_xsec_col,
	appendToGraph/T :fit_info:xsec_row,:fit_info:fit_xsec_row
	ModifyGraph gfSize=12,wbRGB=(56797,56797,56797)
	ModifyGraph alblRGB(bottom)=(0,0,65280)
	ModifyGraph tlblRGB(bottom)=(0,0,65280)
	ModifyGraph rgb(xsec_col)=(0,0,65280)
	ModifyGraph rgb(fit_xsec_col)=(0,0,65280)
	ModifyGraph alblRGB(top)=(65280,0,0)
	ModifyGraph tlblRGB(top)=(65280,0,0)
	ModifyGraph rgb(xsec_row)=(65280,0,0)
	ModifyGraph rgb(fit_xsec_row)=(65280,0,0)
	ModifyGraph mode(xsec_col)=2,mode(xsec_row)=2
	ModifyGraph lsize(fit_xsec_col)=2,lsize(fit_xsec_row)=2
	ModifyGraph tick=2
	ModifyGraph zero(left)=4
	ModifyGraph mirror(left)=1
	ModifyGraph lblMargin(left)=8
	ModifyGraph standoff=0
	ModifyGraph axOffset(left)=0.666667
	ModifyGraph axThick=0.5
	ModifyGraph zeroThick=0.5
	ModifyGraph btLen=3
	ModifyGraph btThick=0.5
	ModifyGraph stLen=2
	ModifyGraph stThick=0.5
	ModifyGraph ttThick=0.5
	ModifyGraph ftThick=0.5
	ModifyGraph lsize(fit_xsec_row)=0.5
	ModifyGraph lsize(xsec_col)=2,lsize(xsec_row)=2
	Label left "Optical depth\\E"
	Label bottom "Position [\\f02\\F'Symbol'm\\f00\\]0m\\E]"
	SetAxis left -0.5,4
	RenameWindow #,ColdAtomInfoSections
	SetActiveSubwindow ##

	SetDataFolder fldrSav
End
// ******************** BuildRubidiumIWindow *********************************

// ******************** BuildRbYbWindow *********************************
//!
//! @brief Build GUI window for RbYb
//! @param[in] ProjectFolder  The data folder to tie this window to.
function BuildRbYbWindow(ProjectFolder)
	String ProjectFolder
	
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	String WindowTitle = "RbYb:" + ProjectFolder;
	
	// Make a new window with killing disabeled
	//NewPanel/K=2/W=(370,44,1024,768) as WindowTitle;
	NewPanel/K=2 /W=(936,59,1667,805) as WindowTitle;
	
	svar CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	CurrentPanel = S_name;
		
	SetDrawLayer UserBack
	DrawText 281,81,"Width [um]"
	DrawText 513,41,"1/e Radius [um]"
	DrawLine 45,252,223,252
	DrawText 281,41,"Position [um]"
	DrawText 513,84,"TF radius [um]"
	CheckBox UpdateFromFile,pos={40,27},size={141,14},proc=UpdateFromFile,title="Update properties from file"
	CheckBox UpdateFromFile,value= 1
	SetVariable CameraID,pos={107,41},size={115,16},bodyWidth=75,disable=2,title="Camera"
	SetVariable CameraID,value= :Experimental_Info:Camera
	SetVariable IQuad,pos={54,59},size={169,16},bodyWidth=75,proc=Set_TrapParams,title="Quadrupole [Amps]"
	SetVariable IQuad,value= :Experimental_Info:IQuad
	SetVariable Ibias,pos={89,77},size={134,16},bodyWidth=75,proc=Set_TrapParams,title="Bias [Amps]"
	SetVariable Ibias,value= :Experimental_Info:IBias
	SetVariable DipolePower,pos={61,95},size={162,16},bodyWidth=75,proc=Set_TrapParams,title="Dipole Power [W]"
	SetVariable DipolePower,value= :Experimental_Info:DipolePower
	SetVariable detuning,pos={70,113},size={153,16},bodyWidth=75,title="Probe Detuning [lines]"
	SetVariable detuning,value= :Experimental_Info:Detuning
	SetVariable expandtime,pos={50,131},size={173,16},bodyWidth=75,title="ExpansionTime [ms]"
	SetVariable expandtime,value= :Experimental_Info:expand_time
	PopupMenu FindCenter,pos={40,226},size={152,21},bodyWidth=152,proc=ChooseCenter
	PopupMenu FindCenter,mode=2,popvalue="Center follows cursor",value= #"\"Find center from max;Center follows cursor;Center from cursor\""
	Button index_reset,pos={43,307},size={45,20},proc=ResetIndex,title="Reset"
	PopupMenu popup0,pos={40,151},size={127,21},bodyWidth=127,proc=SetTrapType
	PopupMenu popup0,mode=1,popvalue="Magnetic Trap",value= #"\"Magnetic Trap;Quad+Dipole;MOT;MOT Diagnostics\""
	PopupMenu flevel,pos={175,151},size={47,21},proc=SetHyperfineLevel
	PopupMenu flevel,mode=1,popvalue="F=1",value= #"\"F=1;F=2\""
	SetVariable magn,pos={284,357},size={127,16},bodyWidth=60,proc=Set_Mag,title="Magnification"
	SetVariable magn,value= :Experimental_Info:magnification
	SetVariable PeakOD,pos={32,384},size={108,16},bodyWidth=60,proc=Set_PeakOD,title="Peak OD"
	SetVariable PeakOD,fSize=9,format="%.2f"
	SetVariable PeakOD,value= :Experimental_Info:PeakOD
	PopupMenu CamDir_popup,pos={40,176},size={92,21},bodyWidth=92,proc=SetCamDir
	PopupMenu CamDir_popup,mode=2,popvalue="XZ imaging",value= #"\"XY imaging;XZ imaging;\""
	PopupMenu DataType_popup,pos={136,176},size={86,21},bodyWidth=86,proc=SetDataType
	PopupMenu DataType_popup,mode=1,popvalue="Absorption",value= #"\"Absorption;Fluorescence;PhaseContrast;\""
	PopupMenu FitTypePopup,pos={40,201},size={109,21},bodyWidth=109,proc=SetFit_Type
	PopupMenu FitTypePopup,mode=1,popvalue="Thermal 1D",value= #"\"Thermal 1D;TF+Thermal 1D;TF only 1D;TF+Thermal 2D;TF only 2D;Thermal 2D;None\""
	Button refit,pos={186,355},size={45,20},proc=Refit,title="Refit"
	PopupMenu AutoUpdate,pos={43,280},size={152,21},bodyWidth=152,proc=SetAutoUpdate
	PopupMenu AutoUpdate,mode=2,popvalue="Auto increment",value= #"\"No update;Auto increment;Index from file;\""
	Button manual_update,pos={169,307},size={50,20},proc=ManUpdate,title="Update"
	SetVariable IndexDisplay,pos={151,258},size={70,16},bodyWidth=40,title="Index"
	SetVariable IndexDisplay,limits={-inf,inf,0},value= :IndexedWaves:index,noedit= 1
	CheckBox GetScopeTrace,pos={42,256},size={100,14},proc=GetScopeTrace,title="Get Scope Trace"
	CheckBox GetScopeTrace,value= 0
	Button dec_update,pos={104,307},size={50,20},proc=dec_update,title="dec."
	PopupMenu SetROI,pos={35,354},size={141,21},bodyWidth=141,proc=SetROI
	PopupMenu SetROI,mode=1,popvalue="Set ROI",value= #"\"Set ROI;Set ROI and zoom;Zoom to ROI;Unzoom\""
	Button Slice,pos={417,377},size={45,20},proc=Call_MakeSlice,title="Slice"
	SetVariable SliceWidth,pos={313,379},size={98,16},bodyWidth=40,title="Slice Width"
	SetVariable SliceWidth,fSize=9,format="%d",value= :Fit_Info:slicewidth
	SetVariable fx,pos={566,209},size={128,16},bodyWidth=75,title="X trap freq"
	SetVariable fx,limits={-inf,inf,0},value= :Experimental_Info:freqX,noedit= 1
	SetVariable fz,pos={566,248},size={128,16},bodyWidth=75,title="Z trap freq"
	SetVariable fz,limits={-inf,inf,0},value= :Experimental_Info:freqZ,noedit= 1
	SetVariable aspetratio,pos={554,266},size={140,16},bodyWidth=75,title="Aspect Ratio"
	SetVariable aspetratio,limits={-inf,inf,0},value= :Experimental_Info:AspectRatio,noedit= 1
	SetVariable Trapbottom,pos={518,304},size={176,16},bodyWidth=75,title="Trap Minimum [MHz]"
	SetVariable Trapbottom,limits={-inf,inf,0},value= :Experimental_Info:trapmin,noedit= 1
	SetVariable TrapDepth,pos={539,285},size={155,16},bodyWidth=75,title="Trap Depth [nK]"
	SetVariable TrapDepth,limits={-inf,inf,0},value= :Experimental_Info:TrapDepth,noedit= 1
	SetVariable temp,pos={300,167},size={161,16},bodyWidth=75,title="Temperature [nK]"
	SetVariable temp,limits={-inf,inf,0},value= :temperature,noedit= 1
	SetVariable number,pos={345,186},size={116,16},bodyWidth=75,title="Number"
	SetVariable number,limits={-inf,inf,0},value= :number,noedit= 1
	SetVariable PhaseSpace,pos={280,205},size={181,16},bodyWidth=75,title="Phase Space Density"
	SetVariable PhaseSpace,limits={-inf,inf,0},value= :PSD,noedit= 1
	SetVariable rms_x,pos={284,84},size={51,16},bodyWidth=40,title="X"
	SetVariable rms_x,limits={-inf,inf,0},value= :xrms,noedit= 1
	SetVariable rms_y,pos={350,84},size={51,16},bodyWidth=40,title="Y"
	SetVariable rms_y,limits={-inf,inf,0},value= :yrms,noedit= 1
	SetVariable rms_z,pos={412,84},size={51,16},bodyWidth=40,title="Z"
	SetVariable rms_z,limits={-inf,inf,0},value= :zrms,noedit= 1
	SetVariable dens,pos={303,109},size={160,16},bodyWidth=75,title="Density (1/um^3)"
	SetVariable dens,limits={-inf,inf,0},value= :density,noedit= 1
	SetVariable rms_z_t0,pos={643,47},size={57,16},bodyWidth=40,title="Z0"
	SetVariable rms_z_t0,limits={0,0,0},value= :zrms_t0,noedit= 1
	SetVariable rms_y_t0,pos={575,48},size={57,16},bodyWidth=40,title="Y0"
	SetVariable rms_y_t0,limits={0,0,0},value= :yrms_t0,noedit= 1
	SetVariable rms_x_t0,pos={509,48},size={57,16},bodyWidth=40,title="X0"
	SetVariable rms_x_t0,limits={0,0,0},value= :xrms_t0,noedit= 1
	SetVariable dens_t0,pos={513,110},size={188,16},bodyWidth=75,title="Peak Density (1/um^3)"
	SetVariable dens_t0,limits={-inf,inf,0},value= :density_t0,noedit= 1
	SetVariable BECnum,pos={290,262},size={174,16},bodyWidth=75,title="Number (absorption)"
	SetVariable BECnum,limits={0,0,0},value= :number_BEC
	SetVariable BECnum01,pos={326,281},size={138,16},bodyWidth=75,title="Number (TF)"
	SetVariable BECnum01,limits={0,0,0},value= :number_TF
	SetVariable chempot,pos={276,300},size={188,16},bodyWidth=75,title="Chemical Potential (Hz)"
	SetVariable chempot,limits={0,0,0},value= :chempot
	SetVariable Tc,pos={326,319},size={138,16},bodyWidth=75,title="BEC Tc [nK]"
	SetVariable Tc,limits={0,0,0},value= :Tc
	SetVariable CastDumX,pos={513,366},size={60,16},bodyWidth=46,proc=SetCastDum,title="X "
	SetVariable CastDumX,value= :Experimental_Info:CastDum_xscale
	SetVariable CastDumy,pos={576,366},size={58,16},bodyWidth=44,proc=SetCastDum,title="Y "
	SetVariable CastDumy,value= :Experimental_Info:CastDum_yscale
	SetVariable CastDumz,pos={640,366},size={58,16},bodyWidth=44,proc=SetCastDum,title="Z "
	SetVariable CastDumz,value= :Experimental_Info:CastDum_zscale
	GroupBox TrapProps2,pos={273,8},size={198,127},title="Imaged cloud (t = TOF)"
	GroupBox TrapProps2,fSize=11
	GroupBox TrapProps5,pos={500,8},size={211,129},title="Initial cloud (t = 0)"
	GroupBox TrapProps5,fSize=11
	GroupBox TrapProps6,pos={273,145},size={198,86},title="Thermal cloud properties"
	GroupBox TrapProps6,fSize=11
	GroupBox TrapProps7,pos={272,241},size={198,104},title="BEC cloud properties"
	GroupBox TrapProps7,fSize=11
	GroupBox TrapProps8,pos={501,166},size={209,174},title="Trap properties"
	GroupBox TrapProps8,fSize=11
	GroupBox TrapProps9,pos={502,344},size={206,53},title="Castin-Dum scale paramaters"
	GroupBox TrapProps9,fSize=11
	GroupBox TrapProps0,pos={33,8},size={200,336},title="Experimental properties"
	GroupBox TrapProps0,fSize=11
	SetVariable Xpos,pos={284,45},size={51,16},bodyWidth=40,title="X"
	SetVariable Xpos,limits={-inf,inf,0},value= :xposition,noedit= 1
	SetVariable Ypos,pos={350,45},size={51,16},bodyWidth=40,title="Y"
	SetVariable Ypos,limits={-inf,inf,0},value= :yposition,noedit= 1
	SetVariable Zpos,pos={412,45},size={51,16},bodyWidth=40,title="Z"
	SetVariable Zpos,limits={-inf,inf,0},value= :zposition,noedit= 1
	SetVariable DipoleFreqCoef,pos={520,190},size={174,16},bodyWidth=57,proc=Set_TrapParams,title="Trap Frequency Scaling"
	SetVariable DipoleFreqCoef,fSize=9,format="%3.1f"
	SetVariable DipoleFreqCoef,value= :Experimental_Info:FreqScaling
	SetVariable fy,pos={565,228},size={128,16},bodyWidth=75,proc=Set_TrapParams,title="Y trap freq"
	SetVariable fy,fSize=9,format="%2.1f",value= :Experimental_Info:freqY
	SetVariable rms_x_t1,pos={509,87},size={57,16},bodyWidth=40,title="X0"
	SetVariable rms_x_t1,limits={0,0,0},value= :xwidth_BEC_t0,noedit= 1
	SetVariable rms_y_t1,pos={575,86},size={57,16},bodyWidth=40,title="Y0"
	SetVariable rms_y_t1,limits={0,0,0},value= :ywidth_BEC_t0,noedit= 1
	SetVariable rms_z_t1,pos={643,85},size={57,16},bodyWidth=40,title="Z0"
	SetVariable rms_z_t1,limits={0,0,0},value= :zwidth_BEC_t0,noedit= 1
	Display/W=(16,408,388,844)/FG=(FL,,,)/HOST=# 
	AppendImage optdepth
	ModifyImage optdepth ctab= {-0.89003736,4,Grays,0}
	ModifyGraph gfSize=12,wbRGB=(56797,56797,56797)
	ModifyGraph mirror=2
	Cursor/P/A=0/I/S=2/H=1/C=(65525,0,0) A optdepth 396,270;Cursor/P/A=0/I/S=2/H=1/C=(65525,0,0) B optdepth 859,689;Cursor/P/A=0/I/S=2/H=1/C=(65525,0,65525) C optdepth 20,8;Cursor/P/A=0/I/S=2/H=1/C=(65525,0,65525) D optdepth 20,8
	Cursor/P/I/C=(0,0,0) E optdepth 699,526;Cursor/P/I/C=(65525,65525,0) F optdepth 613,491
	RenameWindow #,ColdAtomInfoImage
	SetActiveSubwindow ##
	String fldrSav0= GetDataFolder(1)
	SetDataFolder :Fit_Info:
	Display/W=(390,408,835,843)/HOST=#  xsec_col,fit_xsec_col
	AppendToGraph/T xsec_row,fit_xsec_row
	SetDataFolder fldrSav0
	ModifyGraph gfSize=12,wbRGB=(56797,56797,56797)
	ModifyGraph mode(xsec_col)=2,mode(xsec_row)=2
	ModifyGraph lSize(xsec_col)=2,lSize(fit_xsec_col)=2,lSize(xsec_row)=2,lSize(fit_xsec_row)=0.5
	ModifyGraph rgb(xsec_col)=(0,0,65280),rgb(fit_xsec_col)=(0,0,65280),rgb(xsec_row)=(65280,0,0)
	ModifyGraph rgb(fit_xsec_row)=(65280,0,0)
	ModifyGraph tick=2
	ModifyGraph zero(left)=4
	ModifyGraph mirror(left)=1
	ModifyGraph lblMargin(left)=8
	ModifyGraph standoff=0
	ModifyGraph axOffset(left)=0.666667
	ModifyGraph axThick=0.5
	ModifyGraph tlblRGB(bottom)=(0,0,65280),tlblRGB(top)=(65280,0,0)
	ModifyGraph alblRGB(bottom)=(0,0,65280),alblRGB(top)=(65280,0,0)
	ModifyGraph zeroThick=0.5
	ModifyGraph btLen=3
	ModifyGraph btThick=0.5
	ModifyGraph stLen=2
	ModifyGraph stThick=0.5
	ModifyGraph ttThick=0.5
	ModifyGraph ftThick=0.5
	Label left "Optical depth\\E"
	Label bottom "Position [\\f02\\F'Symbol'm\\f00\\]0m\\E]"
	SetAxis left -0.89003736,4
	Cursor/P A xsec_row 396;Cursor/P B xsec_row 859
	RenameWindow #,ColdAtomInfoSections
	SetActiveSubwindow ##
	
	SetDataFolder fldrSav
End
// ******************** BuildRbYbWindow *********************************


// ******************** BuildRubidiumIIWindow ********************************
//!
//! @brief Build GUI window for Rubidium II
//! @param[in] ProjectFolder  The data folder to tie this window to.
function BuildRubidiumIIWindow(ProjectFolder)
	String ProjectFolder
	
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	String WindowTitle = "Rubidium_II:" + ProjectFolder;
	
	// Make a new window with killing disabeled
	// NewPanel/K=2/W=(370,44,1024,768) as WindowTitle;
	NewPanel/W=(598,44,1440,900) as WindowTitle;
	
	svar CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	CurrentPanel = S_name;
	
	SetDrawLayer UserBack
	DrawText 237,281,"Width [um]"
	DrawText 237,211,"Position [um]"
	DrawText 238,369,"Width [um]"
	DrawText 443,281,"Width [um]"
	DrawText 444,373,"Width [um]"
	DrawLine 28,292,206,292
	
	// Experimental properties
	CheckBox UpdateFromFile,pos={23,24},size={141,14},proc=UpdateFromFile,title="Update properties from file"
	CheckBox UpdateFromFile,value= 1

	SetVariable CameraID,pos={95,38},size={113,15},disable=2,title="Camera"
	SetVariable CameraID,value= :Experimental_Info:Camera,bodyWidth= 75

	SetVariable IQuad,pos={44,53},size={164,15},proc=SetBfield,title="Quadrupole [Amps]"
	SetVariable IQuad,value= :Experimental_Info:IQuad,bodyWidth= 75
	
	SetVariable Ibias,pos={74,68},size={134,15},proc=SetBfield,title="Bias [Amps]"
	SetVariable Ibias,value= :Experimental_Info:IBias,bodyWidth= 75

	SetVariable BeamZ,pos={19,83},size={189,15},proc=SetBfield,title="Beam Displacement [um]"
	SetVariable BeamZ,value= :Experimental_Info:BeamZ,bodyWidth= 75

	SetVariable WaistX,pos={71,98},size={137,15},proc=SetBfield,title="Waist X [um]"
	SetVariable WaistX,value= :Experimental_Info:WaistX,bodyWidth= 75

	SetVariable WaistZ,pos={72,113},size={136,15},proc=SetBfield,title="Waist Z [um]"
	SetVariable WaistZ,value= :Experimental_Info:WaistZ,bodyWidth= 75

	SetVariable DipolePower,pos={51,128},size={157,15},proc=SetBfield,title="Dipole Power [W]"
	SetVariable DipolePower,value= :Experimental_Info:DipolePower,bodyWidth= 75

	SetVariable detuning,pos={91,147},size={117,15},title="Probe Detuning"
	SetVariable detuning,value= :Experimental_Info:Detuning,bodyWidth= 75

	SetVariable expandtime,pos={39,166},size={169,15},title="ExpansionTime [ms]"
	SetVariable expandtime,value= :Experimental_Info:expand_time,bodyWidth= 75

	PopupMenu FindCenter,pos={25,270},size={152,20},proc=ChooseCenter
	PopupMenu FindCenter,mode=1,bodyWidth= 152,popvalue="Find center from max",value= #"\"Find center from max;Center follows cursor;Center from cursor\""

	Button index_reset,pos={26,347},size={45,20},proc=ResetIndex,title="Reset"
	
	PopupMenu popup0,pos={25,187},size={109,20},proc=SetTrapType
	PopupMenu popup0,mode=1,bodyWidth= 109,popvalue="Magnetic Trap",value= #"\"Magnetic Trap;MOT;MOT Diagnostics\""

	PopupMenu flevel,pos={140,187},size={51,20},proc=SetHyperfineLevel
	PopupMenu flevel,mode=1,popvalue="F=1",value= #"\"F=1;F=2\""

	SetVariable magn,pos={0,427},size={139,15},proc=Set_Mag,title="Magnification"
	SetVariable magn,value= :Experimental_Info:magnification,bodyWidth= 60

	SetVariable PeakOD,pos={24,409},size={100,15},proc=Set_PeakOD,title="Peak OD",fSize=9
	SetVariable PeakOD,format="%.2f"
	SetVariable PeakOD,value= :Experimental_Info:PeakOD,bodyWidth= 60
		
	// Fitting properties
	PopupMenu CamDir_popup,pos={25,214},size={109,20},proc=SetCamDir
	PopupMenu CamDir_popup,mode=1,bodyWidth= 109,popvalue="XY imaging"
	PopupMenu CamDir_popup,value= #"\"XY imaging;XZ imaging;\""

	PopupMenu DataType_popup,pos={140,214},size={51,20},proc=SetDataType
	PopupMenu DataType_popup,mode=1,bodyWidth= 109,popvalue="Absorption"
	PopupMenu DataType_popup,value= #"\"Absorption;Fluorescence;PhaseContrast;\""

	PopupMenu FitTypePopup,pos={25,242},size={109,20},proc=SetFit_Type
	PopupMenu FitTypePopup,mode=1,bodyWidth= 109,popvalue="Thermal 1D",value= #"\"Thermal 1D;TF+Thermal 1D;TF only 1D;TF+Thermal 2D;TF only 2D;Thermal 2D;None\""
		
	Button refit,pos={169,378},size={45,20},proc=Refit,title="Refit"

	PopupMenu AutoUpdate,pos={26,320},size={152,20},proc=SetAutoUpdate
	PopupMenu AutoUpdate,mode=1,bodyWidth= 152,popvalue="Auto increment"
	PopupMenu AutoUpdate,value= #"\"No update;Auto increment;Index from file;\""

	Button manual_update,pos={152,347},size={50,20},proc=ManUpdate,title="Update"
	
	SetVariable IndexDisplay,pos={138,298},size={68,15},title="Index"
	SetVariable IndexDisplay,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable IndexDisplay,value= :IndexedWaves:index
	
	CheckBox GetScopeTrace,pos={25,296},size={91,14},proc=GetScopeTrace,title="Get Scope Trace"
	CheckBox GetScopeTrace,value= 0

	Button dec_update,pos={87,347},size={50,20},proc=dec_update,title="dec."
	
	PopupMenu SetROI,pos={16,378},size={141,20},proc=SetROI
	PopupMenu SetROI,mode=1,bodyWidth= 141,popvalue="Set ROI",value= #"\"Set ROI;Set ROI and zoom;Zoom to ROI;Unzoom\""

	Button Slice,pos={282,425},size={45,20},proc=Call_MakeSlice,title="Slice"

	SetVariable SliceWidth,pos={178,427},size={94,15},title="Slice Width",fSize=9
	SetVariable SliceWidth,format="%d"
	SetVariable SliceWidth,value= :Fit_Info:slicewidth,bodyWidth= 40

	// Trap properties
	SetVariable fx,pos={290,24},size={128,15},title="X trap freq"
	SetVariable fx,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable fx,value= :Experimental_Info:freqX

	SetVariable fy,pos={290,38},size={128,15},title="Y trap freq"
	SetVariable fy,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable fy,value= :Experimental_Info:freqY

	SetVariable fz,pos={290,52},size={128,15},title="Z trap freq"
	SetVariable fz,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable fz,value= :Experimental_Info:freqZ

	SetVariable aspetratio,pos={283,68},size={136,14},title="Aspect Ratio"
	SetVariable aspetratio,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable aspetratio,value= :Experimental_Info:AspectRatio
	
	SetVariable Trapbottom,pos={246,86},size={173,14},title="Trap Minimum [MHz]"
	SetVariable Trapbottom,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable Trapbottom,value= :Experimental_Info:trapmin
	
	SetVariable TrapDepth,pos={246,86},size={173,14},title="Trap Depth [nK]"
	SetVariable TrapDepth,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable TrapDepth,value= :Experimental_Info:TrapDepth
	
	// Thermal cloud properties
	SetVariable temp,pos={239,156},size={180,14},title="Temperature [nK]"
	SetVariable temp,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable temp,value= :temperature

	SetVariable number,pos={287,173},size={132,14},title="Number"
	SetVariable number,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable number,value= :number

	SetVariable center_x,pos={238,210},size={50,14},title="X"
	SetVariable center_x,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable center_x,value= :xposition

	SetVariable center_y,pos={303,210},size={50,14},title="Y"
	SetVariable center_y,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable center_y,value= :yposition

	SetVariable center_z,pos={369,210},size={50,14},title="Z"
	SetVariable center_z,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable center_z,value= :zposition

	// Imaged cloud properties
	SetVariable rms_x,pos={238,281},size={50,14},title="X"
	SetVariable rms_x,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_x,value= :xrms

	SetVariable rms_y,pos={304,281},size={50,14},title="Y"
	SetVariable rms_y,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_y,value= :yrms

	SetVariable rms_z,pos={366,281},size={50,14},title="Z"
	SetVariable rms_z,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_z,value= :zrms

	SetVariable dens,pos={238,304},size={180,14},title="Density (1/um^3)"
	SetVariable dens,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable dens,value= :density
	
	// Inital cloud properties
	SetVariable rms_x_t0,pos={241,371},size={47,14},title="X"
	SetVariable rms_x_t0,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_x_t0,limits={0,0,0},barmisc={0,1000},value= :xrms_t0
	
	SetVariable rms_y_t0,pos={303,371},size={46,14},title="Y"
	SetVariable rms_y_t0,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_y_t0,limits={0,0,0},barmisc={0,1000},value= :yrms_t0

	SetVariable rms_z_t0,pos={364,371},size={45,14},title="Z"
	SetVariable rms_z_t0,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable rms_z_t0,limits={0,0,0},barmisc={0,1000},value= :zrms_t0

	SetVariable dens_t0,pos={239,398},size={180,14},title="Density (1/um^3)"
	SetVariable dens_t0,limits={0,0,0},barmisc={0,1000},bodyWidth= 75
	SetVariable dens_t0,value= :density_t0

	// BEC cloud properties
	SetVariable BECnum,pos={458,155},size={170,15},bodyWidth=75,title="Number (absorption)"
	SetVariable BECnum,limits={0,0,0}
	SetVariable BECnum,value= :number_BEC

	SetVariable BECnum01,pos={494,173},size={135,15},bodyWidth=75,title="Number (TF)"
	SetVariable BECnum01,limits={0,0,0}
	SetVariable BECnum01,value= :number_TF

	SetVariable chempot,pos={448,192},size={181,15},bodyWidth=75,title="Chemical Potential (Hz)"
	SetVariable chempot,limits={0,0,0}
	SetVariable chempot,value= :chempot

	SetVariable Tc,pos={498,210},size={132,15},bodyWidth=75,title="BEC Tc [nK]"
	SetVariable Tc,limits={0,0,0}
	SetVariable Tc,value= :Tc

	// Imaged BEC properties	
	SetVariable BECxrms,pos={446,282},size={50,14},title="X"
	SetVariable BECxrms,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECxrms,value= :xwidth_BEC

	SetVariable BECyrms,pos={508,282},size={50,14},title="Y"
	SetVariable BECyrms,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECyrms,value= :ywidth_BEC

	SetVariable BECzrms,pos={570,282},size={50,14},title="Z"
	SetVariable BECzrms,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECzrms,value= :zwidth_BEC

	SetVariable dens01,pos={447,305},size={180,14},title="Density (1/um^3)"
	SetVariable dens01,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable dens01,value= :density_BEC

	SetVariable R_TF_1,pos={528,262},size={90,14},title="RTF (um)"
	SetVariable R_TF_1,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable R_TF_1,value= :radius_TF

	// Initial BEC properties

	SetVariable BECxrms01,pos={446,375},size={50,14},title="X"
	SetVariable BECxrms01,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECxrms01,value= :xwidth_BEC_t0

	SetVariable BECyrms01,pos={508,375},size={50,14},title="Y"
	SetVariable BECyrms01,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECyrms01,value= :ywidth_BEC_t0

	SetVariable BECzrms01,pos={570,375},size={50,14},title="Z"
	SetVariable BECzrms01,limits={-inf,inf,0},noedit=1,bodyWidth= 40
	SetVariable BECzrms01,value= :zwidth_BEC_t0

	SetVariable dens0101,pos={447,398},size={180,14},title="Density (1/um3)"
	SetVariable dens0101,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable dens0101,value= :density_BEC_t0

	SetVariable R_TF,pos={528,351},size={90,14},title="RTF (um)"
	SetVariable R_TF,limits={-inf,inf,0},noedit=1,bodyWidth= 75
	SetVariable R_TF,value= :radius_TF_t0

	// BEC input paramaters

	SetVariable CastDumX,pos={543,29},size={90,15},proc=SetCastDum,title="X "
	SetVariable CastDumX,value= :Experimental_Info:CastDum_xscale,bodyWidth= 75

	SetVariable CastDumy,pos={558,47},size={75,15},proc=SetCastDum,title="Y "
	SetVariable CastDumy,value= :Experimental_Info:CastDum_yscale,bodyWidth= 75

	SetVariable CastDumz,pos={558,65},size={75,15},proc=SetCastDum,title="Z "
	SetVariable CastDumz,value= :Experimental_Info:CastDum_zscale,bodyWidth= 75

	GroupBox TrapProps2,pos={229,245},size={198,84},title="Imaged cloud (t = timage)"
	GroupBox TrapProps2,fSize=11
	GroupBox TrapProps3,pos={441,245},size={198,84},title="Imaged cloud (t = timage)"
	GroupBox TrapProps3,fSize=11
	GroupBox TrapProps4,pos={441,336},size={198,84},title="Initial cloud (t = 0)"
	GroupBox TrapProps4,fSize=11
	GroupBox TrapProps5,pos={229,336},size={198,84},title="Initial cloud (t = 0)"
	GroupBox TrapProps5,fSize=11
	GroupBox TrapProps6,pos={229,133},size={198,104},title="Thermal cloud properties"
	GroupBox TrapProps6,fSize=11
	GroupBox TrapProps7,pos={441,133},size={198,104},title="BEC cloud properties"
	GroupBox TrapProps7,fSize=11
	GroupBox TrapProps8,pos={229,8},size={198,117},title="Trap properties"
	GroupBox TrapProps8,fSize=11
	GroupBox TrapProps9,pos={441,8},size={198,117},title="Castin-Dum scale paramaters"
	GroupBox TrapProps9,fSize=11
	GroupBox TrapProps0,pos={16,8},size={196,367},title="Experimental properties"
	GroupBox TrapProps0,fSize=11
	Display/W=(16,448,431,844)/HOST=# 
	AppendImage optdepth
	ModifyImage optdepth ctab= {-0.3,3.0,Grays,0};
	ModifyGraph gfSize=12,wbRGB=(56797,56797,56797)
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph lblMargin(left)=8
	ModifyGraph standoff=0
	ModifyGraph axOffset(left)=0.666667
	ModifyGraph axThick=0.5
	ModifyGraph zeroThick=0.5
	ModifyGraph btLen=3
	ModifyGraph btThick=0.5
	ModifyGraph stLen=2
	ModifyGraph stThick=0.5
	ModifyGraph ttThick=0.5
	ModifyGraph ftThick=0.5
	
	Label left "Y/Z Position [\\f02\\F'Symbol'm\\f00\\]0m\\E]"
	Label bottom "X Position [\\f02\\F'Symbol'm\\f02\\]0m\\E]"
	Cursor/P/I/S=2/H=1/C=(65280,65280,0) A optdepth 453,540;Cursor/P/I/S=2/H=1/C=(65280,0,0) B optdepth 131,142
	RenameWindow #,ColdAtomInfoImage
	SetActiveSubwindow ##
	Display/W=(436,448,835,843)/HOST=#  :fit_info:xsec_col,:fit_info:fit_xsec_col,
	appendToGraph/T :fit_info:xsec_row,:fit_info:fit_xsec_row
	ModifyGraph gfSize=12,wbRGB=(56797,56797,56797)
	ModifyGraph alblRGB(bottom)=(0,0,65280)
	ModifyGraph tlblRGB(bottom)=(0,0,65280)
	ModifyGraph rgb(xsec_col)=(0,0,65280)
	ModifyGraph rgb(fit_xsec_col)=(0,0,65280)
	ModifyGraph alblRGB(top)=(65280,0,0)
	ModifyGraph tlblRGB(top)=(65280,0,0)
	ModifyGraph rgb(xsec_row)=(65280,0,0)
	ModifyGraph rgb(fit_xsec_row)=(65280,0,0)
	ModifyGraph mode(xsec_col)=2,mode(xsec_row)=2
	ModifyGraph lsize(fit_xsec_col)=2,lsize(fit_xsec_row)=2
	ModifyGraph tick=2
	ModifyGraph zero(left)=4
	ModifyGraph mirror(left)=1
	ModifyGraph lblMargin(left)=8
	ModifyGraph standoff=0
	ModifyGraph axOffset(left)=0.666667
	ModifyGraph axThick=0.5
	ModifyGraph zeroThick=0.5
	ModifyGraph btLen=3
	ModifyGraph btThick=0.5
	ModifyGraph stLen=2
	ModifyGraph stThick=0.5
	ModifyGraph ttThick=0.5
	ModifyGraph ftThick=0.5
	ModifyGraph lsize(fit_xsec_row)=0.5
	ModifyGraph lsize(xsec_col)=2,lsize(xsec_row)=2
	Label left "Optical depth\\E"
	Label bottom "Position [\\f02\\F'Symbol'm\\f00\\]0m\\E]"
	SetAxis left -0.5,4
	RenameWindow #,ColdAtomInfoSections
	SetActiveSubwindow ##

	SetDataFolder fldrSav
End
// ******************** BuildRubidiumIIWindow *********************************

// ******************** BuildSrWindow *********************************
//!
//! @brief Build GUI window for Sr
//! @param[in] ProjectFolder  The data folder to tie this window to.
function BuildSrWindow(ProjectFolder)
	String ProjectFolder
	
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	String WindowTitle = "Sr:" + ProjectFolder;
	
	// Make a new window with killing disabeled
	//NewPanel/K=2/W=(370,44,1024,768) as WindowTitle;
	NewPanel/K=2 /W=(936,59,1667,805) as WindowTitle;
	
	svar CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	CurrentPanel = S_name;
		
	SetDrawLayer UserBack
	DrawText 281,75,"1/e Radius [um]"
	DrawText 281,111,"TF radius [um]"
	DrawText 513,41,"1/e Radius [um]"
	DrawLine 45,272,223,272
	DrawText 281,38,"Position [um]"
	DrawText 513,84,"TF radius [um]"
	
	CheckBox UpdateFromFile,pos={40,27},size={141,14},proc=UpdateFromFile,title="Update properties from file"
	CheckBox UpdateFromFile,value= 1
	
	SetVariable CameraID,pos={107,41},size={115,16},bodyWidth=75,disable=2,title="Camera"
	SetVariable CameraID,value= :Experimental_Info:Camera
	
	SetVariable IQuad,pos={54,59},size={169,16},bodyWidth=75,proc=Set_TrapParams,title="Quadrupole [Amps]"
	SetVariable IQuad,value= :Experimental_Info:IQuad
	
	SetVariable Ibias,pos={89,77},size={134,16},bodyWidth=75,proc=Set_TrapParams,title="Bias [Amps]"
	SetVariable Ibias,value= :Experimental_Info:IBias
	
	SetVariable DipolePower,pos={61,95},size={162,16},bodyWidth=75,proc=Set_TrapParams,title="Dipole Power [W]"
	SetVariable DipolePower,value= :Experimental_Info:DipolePower
	
	SetVariable detuning,pos={70,113},size={153,16},bodyWidth=75,title="Probe Detuning [lines]"
	SetVariable detuning,value= :Experimental_Info:Detuning
	
	SetVariable expandtime,pos={50,131},size={173,16},bodyWidth=75,title="ExpansionTime [ms]"
	SetVariable expandtime,value= :Experimental_Info:expand_time
	
	PopupMenu FindCenter,pos={40,226},size={127,21},bodyWidth=127,proc=ChooseCenter
	PopupMenu FindCenter,mode=2,popvalue="Center follows cursor",value= #"\"Find center from max;Center follows cursor;Center from cursor\""
	
	PopupMenu AnalysisType,pos={172,226},size={57,21},bodyWidth=57,proc=ChooseAnalysis
	PopupMenu AnalysisType,mode=1,popvalue="1 Shot",value= #"\"1 Shot;Basis;PCA\""
	
	PopupMenu trapType,pos={40,151},size={127,21},bodyWidth=127,proc=SetTrapType
	PopupMenu trapType,mode=1,popvalue="Magnetic Trap",value= #"\"Magnetic Trap;Dipole;MOT;MOT Diagnostics;Cross Dipole;Vert. Lattice\""
	
	PopupMenu sriso,pos={175,151},size={47,21},proc=SetIsotope
	PopupMenu sriso,mode=1,popvalue="86",value= #"\"84;86;87;88\""
	
	SetVariable magn,pos={280,357},size={127,16},bodyWidth=60,proc=Set_Mag,title="Magnification"
	SetVariable magn,value= :Experimental_Info:magnification
	
	CheckBox CentFix,pos={415,357},size={127,16},bodyWidth=60,proc=Set_center,title="Fix Centers"
	CheckBox CentFix,value=1
	
	SetVariable PeakOD,pos={32,384},size={108,16},bodyWidth=60,proc=Set_PeakOD,title="Peak OD"
	SetVariable PeakOD,fSize=9,format="%.2f"
	SetVariable PeakOD,value= :Experimental_Info:PeakOD
	
	CheckBox DoMask,pos={145,385},size={127,16},bodyWidth=60,title="Mask",variable=$(ProjectFolder + ":fit_info:DoRealMask") 
	
	SetVariable theta,pos={220,384},size={108,16},bodyWidth=60,proc=Set_theta,title="Imaging Angle"
	SetVariable theta,fSize=9,format="%.2f"
	SetVariable theta,value= :Experimental_Info:theta
	
	PopupMenu CamDir_popup,pos={40,176},size={92,21},bodyWidth=92,proc=SetCamDir
	PopupMenu CamDir_popup,mode=2,popvalue="XZ imaging",value= #"\"XY imaging;XZ imaging;\""
	
	PopupMenu DataType_popup,pos={136,176},size={86,21},bodyWidth=86,proc=SetDataType
	PopupMenu DataType_popup,mode=1,popvalue="Absorption",value= #"\"Absorption;Fluorescence;PhaseContrast;\""
	
	PopupMenu FitTypePopup,pos={40,201},size={109,21},bodyWidth=109,proc=SetFit_Type
	PopupMenu FitTypePopup,mode=1,popvalue="Thermal 1D",value= #"\"Thermal 1D;TF+Thermal 1D;TF only 1D;TF+Thermal 2D;TF only 2D;Thermal 2D;TriGauss 2D;BandMap 1D;Thermal Integral;None\""
	
	CheckBox DualAxisImage,pos={155,205},size={80,16},bodyWidth=60,proc=Set_DualAxis,title="2 Axis Img"
	CheckBox DualAxisImage,value=0
	
	PopupMenu AutoUpdate,pos={43,300},size={152,21},bodyWidth=152,proc=SetAutoUpdate
	PopupMenu AutoUpdate,mode=2,popvalue="Auto increment",value= #"\"No update;Auto increment;Index from file;\""
	
	Button manual_update,pos={169,325},size={50,20},proc=ManUpdate,title="Update"
	
	Button index_reset,pos={43,325},size={45,20},proc=ResetIndex,title="Reset"
	
	Button dec_update,pos={104,325},size={50,20},proc=dec_update,title="dec."
	
	SetVariable IndexDisplay,pos={151,280},size={70,16},bodyWidth=40,title="Index"
	SetVariable IndexDisplay,limits={-inf,inf,0},value= :IndexedWaves:index,noedit= 1
	
	CheckBox GetScopeTrace,pos={42,280},size={100,14},proc=GetScopeTrace,title="Get Scope Trace"
	CheckBox GetScopeTrace,value= 0
	
	PopupMenu SetROI,pos={33,354},size={121,21},bodyWidth=121,proc=SetROI
	PopupMenu SetROI,mode=1,popvalue="Set ROI",value= #"\"Set ROI;Set ROI and zoom;Zoom to ROI;Unzoom\""
	
	Button refit,pos={160,355},size={45,20},proc=Refit,title="Refit"
	
	Button resetcur,pos={210,355},size={65,20},proc=CursorsToROI,title="Cur. to ROI"
	
	Button Slice,pos={435,382},size={45,20},proc=Call_MakeSlice,title="Slice"
	
	SetVariable SliceWidth,pos={335,384},size={98,16},bodyWidth=40,title="Slice Width"
	SetVariable SliceWidth,fSize=9,format="%d",value= :Fit_Info:slicewidth
	
	SetVariable fx,pos={566,209},size={128,16},bodyWidth=75,title="X trap freq"
	SetVariable fx,limits={-inf,inf,0},value= :Experimental_Info:freqX,noedit= 1
	
	SetVariable fz,pos={566,248},size={128,16},bodyWidth=75,title="Z trap freq"
	SetVariable fz,limits={-inf,inf,0},value= :Experimental_Info:freqZ,noedit= 1
	
	SetVariable aspetratio,pos={554,266},size={140,16},bodyWidth=75,title="Aspect Ratio"
	SetVariable aspetratio,limits={-inf,inf,0},value= :Experimental_Info:AspectRatio,noedit= 1
	
	SetVariable Trapbottom,pos={518,304},size={176,16},bodyWidth=75,title="Trap Minimum [MHz]"
	SetVariable Trapbottom,limits={-inf,inf,0},value= :Experimental_Info:trapmin,noedit= 1
	
	SetVariable TrapDepth,pos={539,285},size={155,16},bodyWidth=75,title="Trap Depth [nK]"
	SetVariable TrapDepth,limits={-inf,inf,0},value= :Experimental_Info:TrapDepth,noedit= 1
	
	SetVariable temp,pos={245,175},size={115,16},bodyWidth=35,title="T\Bavg\M [nk]"
	SetVariable temp,limits={-inf,inf,0},value= :temperature,noedit= 1
	
	SetVariable temph,pos={299,175},size={115,16},bodyWidth=35,title="T\Bh"
	SetVariable temph,limits={-inf,inf,0},value= :thoriz,noedit= 1
	
	SetVariable tempv,pos={353,175},size={115,16},bodyWidth=35,title="T\Bv"
	SetVariable tempv,limits={-inf,inf,0},value= :tvert,noedit= 1
	
	SetVariable number,pos={247,197},size={116,16},bodyWidth=57,title="N (fit)"
	SetVariable number,limits={-inf,inf,0},value= :number,format="%.3e",noedit= 1
	
	SetVariable roinum,pos={345,197},size={116,16},bodyWidth=57,title="N (sum)"
	SetVariable roinum,limits={-inf,inf,0},value= :absnumber,format="%.3e",noedit= 1
	
	SetVariable PhaseSpace,pos={280,216},size={181,16},bodyWidth=75,title="Phase Space Density"
	SetVariable PhaseSpace,limits={-inf,inf,0},value= :PSD,noedit= 1
	
	SetVariable rms_x,pos={284,78},size={51,16},bodyWidth=40,title="X"
	SetVariable rms_x,limits={-inf,inf,0},value= :xrms,noedit= 1
	
	SetVariable rms_y,pos={350,78},size={51,16},bodyWidth=40,title="Y"
	SetVariable rms_y,limits={-inf,inf,0},value= :yrms,noedit= 1
	
	SetVariable rms_z,pos={412,78},size={51,16},bodyWidth=40,title="Z"
	SetVariable rms_z,limits={-inf,inf,0},value= :zrms,noedit= 1
	
	SetVariable TF_x,pos={284,114},size={51,16},bodyWidth=40,title="X"
	SetVariable TF_x,limits={-inf,inf,0},value= :xwidth_BEC,noedit= 1
	
	SetVariable TF_y,pos={350,114},size={51,16},bodyWidth=40,title="Y"
	SetVariable TF_y,limits={-inf,inf,0},value= :ywidth_BEC,noedit= 1
	
	SetVariable TF_z,pos={412,114},size={51,16},bodyWidth=40,title="Z"
	SetVariable TF_z,limits={-inf,inf,0},value= :zwidth_BEC,noedit= 1
	
	SetVariable dens,pos={236,134},size={160,16},bodyWidth=35,title="\f02 n \f00 (um^-3, Thml)"
	SetVariable dens,limits={-inf,inf,0},value= :density,noedit= 1
	
	SetVariable densBEC,pos={303,134},size={160,16},bodyWidth=35,title="(BEC)"
	SetVariable densBEC,limits={-inf,inf,0},value= :density_BEC,noedit= 1
	
	SetVariable rms_z_t0,pos={643,47},size={57,16},bodyWidth=40,title="Z0"
	SetVariable rms_z_t0,limits={0,0,0},value= :zrms_t0,noedit= 1
	
	SetVariable rms_y_t0,pos={575,48},size={57,16},bodyWidth=40,title="Y0"
	SetVariable rms_y_t0,limits={0,0,0},value= :yrms_t0,noedit= 1
	
	SetVariable rms_x_t0,pos={509,48},size={57,16},bodyWidth=40,title="X0"
	SetVariable rms_x_t0,limits={0,0,0},value= :xrms_t0,noedit= 1
	
	SetVariable dens_t0,pos={463,110},size={160,16},bodyWidth=40,title="\f02 n \f00 (um^-3,Thml)"
	SetVariable dens_t0,limits={-inf,inf,0},value= :density_t0,noedit= 1
	
	SetVariable densBEC_t0,pos={540,110},size={160,16},bodyWidth=40,title="(BEC)"
	SetVariable densBEC_t0,limits={-inf,inf,0},value= :density_BEC_t0,noedit= 1
	
	SetVariable absdens_t0,pos={463,130},size={160,16},bodyWidth=40,title="\f00 (Thml, sum)"
	SetVariable absdens_t0,limits={-inf,inf,0},value= :absdensity_t0,noedit= 1
	
	SetVariable absdensBEC_t0,pos={540,130},size={160,16},bodyWidth=40,title="(BEC)"
	SetVariable absdensBEC_t0,limits={-inf,inf,0},value= :absdensity_BEC_t0,noedit= 1
	
	SetVariable BECnum,pos={290,265},size={174,16},bodyWidth=75,title="Number (absorption)"
	SetVariable BECnum,limits={0,0,0},value= :number_BEC
	
	SetVariable BECnum01,pos={326,284},size={138,16},bodyWidth=75,title="Number (TF)"
	SetVariable BECnum01,limits={0,0,0},value= :number_TF
	
	SetVariable chempot,pos={280,304},size={100,16},bodyWidth=40,title="\[1 \F'Symbol'm \F]1 (abs, Hz)"
	SetVariable chempot,limits={0,0,0},value= :chempot
	
	SetVariable chempot_TF,pos={414,304},size={50,16},bodyWidth=40,title="(TF, Hz)"
	SetVariable chempot_TF,limits={0,0,0},value= :chempot_TF

	SetVariable Tc,pos={326,322},size={138,16},bodyWidth=75,title="BEC Tc [nK]"
	SetVariable Tc,limits={0,0,0},value= :Tc

	SetVariable CastDumX,pos={513,366},size={60,16},bodyWidth=46,proc=SetCastDum,title="X "
	SetVariable CastDumX,value= :Experimental_Info:CastDum_xscale

	SetVariable CastDumy,pos={576,366},size={58,16},bodyWidth=44,proc=SetCastDum,title="Y "
	SetVariable CastDumy,value= :Experimental_Info:CastDum_yscale

	SetVariable CastDumz,pos={640,366},size={58,16},bodyWidth=44,proc=SetCastDum,title="Z "
	SetVariable CastDumz,value= :Experimental_Info:CastDum_zscale

	GroupBox TrapProps2,pos={273,8},size={198,148},title="Imaged cloud (t = TOF)"
	GroupBox TrapProps2,fSize=11

	GroupBox TrapProps5,pos={500,8},size={211,150},title="Initial cloud (t = 0)"
	GroupBox TrapProps5,fSize=11

	GroupBox TrapProps6,pos={273,158},size={198,84},title="Thermal cloud properties"
	GroupBox TrapProps6,fSize=11

	GroupBox TrapProps7,pos={272,245},size={198,104},title="BEC cloud properties"
	GroupBox TrapProps7,fSize=11

	GroupBox TrapProps8,pos={501,166},size={209,174},title="Trap properties"
	GroupBox TrapProps8,fSize=11

	GroupBox TrapProps9,pos={502,344},size={206,53},title="Castin-Dum scale paramaters"
	GroupBox TrapProps9,fSize=11

	GroupBox TrapProps0,pos={33,8},size={200,342},title="Experimental properties"
	GroupBox TrapProps0,fSize=11

	SetVariable Xpos,pos={284,41},size={51,16},bodyWidth=40,title="X"
	SetVariable Xpos,limits={-inf,inf,0},value= :xposition,noedit= 1

	SetVariable Ypos,pos={350,41},size={51,16},bodyWidth=40,title="Y"
	SetVariable Ypos,limits={-inf,inf,0},value= :yposition,noedit= 1

	SetVariable Zpos,pos={412,41},size={51,16},bodyWidth=40,title="Z"
	SetVariable Zpos,limits={-inf,inf,0},value= :zposition,noedit= 1

	SetVariable DipoleFreqCoef,pos={516,186},size={55,16},bodyWidth=50,proc=Set_TrapParams,title="S\Bx"
	SetVariable DipoleFreqCoef,fSize=9,format="%3.2f"
	SetVariable DipoleFreqCoef,value= :Experimental_Info:FreqScalingX
	
	SetVariable DipoleFreqCoef2,pos={584,186},size={55,16},bodyWidth=50,proc=Set_TrapParams,title="S\By"
	SetVariable DipoleFreqCoef2,fSize=9,format="%3.2f"
	SetVariable DipoleFreqCoef2,value= :Experimental_Info:FreqScalingY
	
	SetVariable DipoleFreqCoef3,pos={651,186},size={55,16},bodyWidth=50,proc=Set_TrapParams,title="S\Bz"
	SetVariable DipoleFreqCoef3,fSize=9,format="%3.2f"
	SetVariable DipoleFreqCoef3,value= :Experimental_Info:FreqScalingZ
	
	SetVariable fy,pos={565,228},size={128,16},bodyWidth=75,title="Y trap freq"
	SetVariable fy,limits={-inf,inf,0},value= :Experimental_Info:freqY,noedit= 1
	
	SetVariable rms_x_t1,pos={509,87},size={57,16},bodyWidth=40,title="X0"
	SetVariable rms_x_t1,limits={0,0,0},value= :xwidth_BEC_t0,noedit= 1
	
	SetVariable rms_y_t1,pos={575,86},size={57,16},bodyWidth=40,title="Y0"
	SetVariable rms_y_t1,limits={0,0,0},value= :ywidth_BEC_t0,noedit= 1
	
	SetVariable rms_z_t1,pos={643,85},size={57,16},bodyWidth=40,title="Z0"
	SetVariable rms_z_t1,limits={0,0,0},value= :zwidth_BEC_t0,noedit= 1
	
	Display/W=(16,408,388,844)/FG=(FL,,,)/HOST=# 
	AppendImage optdepth
	ModifyImage optdepth ctab= {-0.25,*,Grays,0}
	ModifyGraph gfSize=12,wbRGB=(56797,56797,56797)
	ModifyGraph mirror=2
	Cursor/P/A=0/I/S=2/H=1/C=(65525,0,0) A optdepth 50,50;Cursor/P/A=0/I/S=2/H=1/C=(65525,0,0) B optdepth 60,60;Cursor/P/A=0/I/S=2/H=1/C=(0,0,65525) C optdepth 20,8;Cursor/P/A=0/I/S=2/H=1/C=(0,0,65525) D optdepth 30,18
	Cursor/P/I/C=(65525,0,65525) E optdepth 55,55;Cursor/P/I/C=(65525,65525,0) F optdepth 55,55
	RenameWindow #,ColdAtomInfoImage
	SetActiveSubwindow ##
	String fldrSav0= GetDataFolder(1)
	SetDataFolder :Fit_Info:
	Display/W=(390,408,835,843)/HOST=#  xsec_col,fit_xsec_col
	AppendToGraph/T xsec_row,fit_xsec_row
	AppendToGraph/T/L=Lres res_xsec_row
	AppendToGraph/B/L=Lres res_xsec_col
	SetDataFolder fldrSav0
	ModifyGraph gfSize=12,wbRGB=(56797,56797,56797)
	ModifyGraph mode(xsec_col)=2,mode(xsec_row)=2,mode(res_xsec_col)=0,mode(res_xsec_row)=0
	ModifyGraph lSize(xsec_col)=2,lSize(fit_xsec_col)=2,lSize(res_xsec_col)=2,lSize(xsec_row)=2,lSize(fit_xsec_row)=2,lSize(res_xsec_row)=2
	ModifyGraph rgb(xsec_col)=(0,0,65280),rgb(fit_xsec_col)=(0,0,0),rgb(xsec_row)=(65280,0,0)
	ModifyGraph rgb(fit_xsec_row)=(0,0,0),rgb(res_xsec_row)=(45000,0,0),rgb(res_xsec_col)=(0,0,45000)
	ModifyGraph tick=2
	ModifyGraph zero(left)=4
	ModifyGraph zero(Lres)=4
	ModifyGraph mirror(left)=1
	ModifyGraph mirror(Lres)=1
	ModifyGraph lblMargin(left)=8
	ModifyGraph lblPosMode(Lres)=1
	ModifyGraph lblMargin(Lres)=8
	ModifyGraph standoff=0
	ModifyGraph axOffset(left)=0.666667
	ModifyGraph axThick=0.5
	ModifyGraph tlblRGB(bottom)=(0,0,65280),tlblRGB(top)=(65280,0,0)
	ModifyGraph alblRGB(bottom)=(0,0,65280),alblRGB(top)=(65280,0,0)
	ModifyGraph zeroThick=0.5
	ModifyGraph btLen=3
	ModifyGraph btThick=0.5
	ModifyGraph stLen=2
	ModifyGraph stThick=0.5
	ModifyGraph ttThick=0.5
	ModifyGraph ftThick=0.5
	ModifyGraph axisEnab(left)={0.25,1}
	ModifyGraph axisEnab(Lres)={0,0.25}
	ModifyGraph freePos(Lres)=0
	Label left "Optical depth\\E"
	Label Lres "Res. OD\\E"
	Label bottom "Position [\\f02\\F'Symbol'm\\f00\\]0m\\E]"
	SetAxis left -0.25,*
	SetAxis Lres *,*
	Cursor/P A xsec_row 396;Cursor/P B xsec_row 859
	RenameWindow #,ColdAtomInfoSections
	SetActiveSubwindow ##
	
	SetDataFolder fldrSav
End
// ******************** BuildSrWindow *********************************

//Function to copy the info sections graph (bottom left subwindow) from the GUI for export.
Function CopyInfoSections(ProjectFolder)

	String ProjectFolder

	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	String fldrSav0= GetDataFolder(1)
	SetDataFolder :Fit_Info:
	Display/W=(390,408,835,843)  xsec_col,fit_xsec_col
	AppendToGraph/T xsec_row,fit_xsec_row
	AppendToGraph/T/L=Lres res_xsec_row
	AppendToGraph/B/L=Lres res_xsec_col
	SetDataFolder fldrSav0
	ModifyGraph gfSize=12,wbRGB=(56797,56797,56797)
	ModifyGraph mode(xsec_col)=2,mode(xsec_row)=2,mode(res_xsec_col)=0,mode(res_xsec_row)=0
	ModifyGraph lSize(xsec_col)=2,lSize(fit_xsec_col)=2,lSize(res_xsec_col)=2,lSize(xsec_row)=2,lSize(fit_xsec_row)=2,lSize(res_xsec_row)=2
	ModifyGraph rgb(xsec_col)=(0,0,65280),rgb(fit_xsec_col)=(0,0,0),rgb(xsec_row)=(65280,0,0)
	ModifyGraph rgb(fit_xsec_row)=(0,0,0),rgb(res_xsec_row)=(45000,0,0),rgb(res_xsec_col)=(0,0,45000)
	ModifyGraph tick=2
	ModifyGraph zero(left)=4
	ModifyGraph zero(Lres)=4
	ModifyGraph mirror(left)=1
	ModifyGraph mirror(Lres)=1
	ModifyGraph lblMargin(left)=8
	ModifyGraph lblPosMode(Lres)=1
	ModifyGraph lblMargin(Lres)=8
	ModifyGraph standoff=0
	ModifyGraph axOffset(left)=0.666667
	ModifyGraph axThick=0.5
	ModifyGraph tlblRGB(bottom)=(0,0,65280),tlblRGB(top)=(65280,0,0)
	ModifyGraph alblRGB(bottom)=(0,0,65280),alblRGB(top)=(65280,0,0)
	ModifyGraph zeroThick=0.5
	ModifyGraph btLen=3
	ModifyGraph btThick=0.5
	ModifyGraph stLen=2
	ModifyGraph stThick=0.5
	ModifyGraph ttThick=0.5
	ModifyGraph ftThick=0.5
	ModifyGraph axisEnab(left)={0.25,1}
	ModifyGraph axisEnab(Lres)={0,0.25}
	ModifyGraph freePos(Lres)=0
	Label left "Optical depth\\E"
	Label Lres "Res. OD\\E"
	Label bottom "Position [\\f02\\F'Symbol'm\\f00\\]0m\\E]"
	SetAxis left -0.25,*
	SetAxis Lres *,*
	Cursor/P A xsec_row 396;Cursor/P B xsec_row 859
	
	SetDataFolder fldrSav
end

//Function to copy the info sections graph (bottom left subwindow) from the GUI for export.
Function CopyInfoImage(ProjectFolder)

	String ProjectFolder

	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	Display/W=(16,408,388,844)/FG=(FL,,,)
	AppendImage optdepth
	ModifyImage optdepth ctab= {-0.25,*,Grays,0}
	ModifyGraph gfSize=12,wbRGB=(56797,56797,56797)
	ModifyGraph mirror=2
	Cursor/P/A=0/I/S=2/H=1/C=(65525,0,0) A optdepth 50,50;Cursor/P/A=0/I/S=2/H=1/C=(65525,0,0) B optdepth 60,60;Cursor/P/A=0/I/S=2/H=1/C=(0,0,65525) C optdepth 20,8;Cursor/P/A=0/I/S=2/H=1/C=(0,0,65525) D optdepth 30,18
	Cursor/P/I/C=(65525,0,65525) E optdepth 55,55;Cursor/P/I/C=(65525,65525,0) F optdepth 55,55
	
	SetDataFolder fldrSav
end

//!
//! @brief PopupMenuControl handling saving user choices to global variables
Function ChooseCenter(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR findmax=:Fit_Info:findmax
	findmax=popNum;
	
	SetDataFolder fldrSav
End

//!
//! @brief PopupMenuControl handling saving user choices to global variables
Function ChooseAnalysis(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR Analysis_Type=:Fit_Info:Analysis_Type;
	Analysis_Type=popNum;
	
	SetDataFolder fldrSav
End

//!
//! @brief CheckBoxControl handling saving user choices to global variables
Function GetScopeTrace(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR getscope=:Experimental_Info:getscope
	getscope = checked
	
	SetDataFolder fldrSav
End

//!
//! @brief CheckBoxControl handling saving user choices to global variables
Function SetRotateImage(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR RotateImage=:Experimental_Info:RotateImage
	RotateImage = checked
	
	SetDataFolder fldrSav
End


//!
//! @brief PopupMenuControl handling saving user choices to global variables
Function SetTrapType(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR traptype=:Experimental_Info:traptype;	
	traptype=popNum
	
	SetDataFolder fldrSav
End


//!
//! @brief PopupMenuControl handling saving user choices to global variables
//! @detail Also calls ::ComputeTrapProperties to handle update
Function SetHyperfineLevel(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR flevel=:Experimental_Info:flevel

	flevel=popNum
	ComputeTrapProperties();

	SetDataFolder fldrSav
End

//!
//! @brief PopupMenuControl handling saving user choices to global variables
//! @details Handles translating choice into actual atomic mass and scattering length,
//! and calls ::ComputeTrapProperties
Function SetIsotope(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR isotope=:Experimental_Info:SrIsotope
	NVAR mass=:Experimental_Info:mass
	NVAR a_scatt=:Experimental_Info:a_scatt

	isotope=popNum
	if(isotope==1) //84-Sr
		mass=1.39341508e-25;	//Sr-84 mass (kg)
		a_scatt = 6.5031e-3;		// 84-84 scattering length from arXiv:0808.3434 (um)
	elseif(isotope==2) //86-Sr
		mass=1.42655671e-25;  //Sr-86 mass (kg)
		a_scatt = 43.619e-3; 		// 86-86 scattering length from arXiv:0808.3434 (um)
	elseif(isotope==3) //87-Sr
		mass=1.443156956e-25;  //Sr-87 mass (kg)
		a_scatt = 5.089e-3; 		// 87-87 scattering length from arXiv:0808.3434 (um)
	else //88-Sr
		mass=1.459708142e-25;	//Sr-88 mass (kg) 
		a_scatt = -74.06e-6; 		// 88-88 scattering length from arXiv:0808.3434 (um)
	endif
	
	ComputeTrapProperties();

	SetDataFolder fldrSav
End

//!
//! @brief ButtonControl handling calls ::ReinitializeIndexedWaves
Function ResetIndex(ctrlName) : ButtonControl
	String ctrlName

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	ReinitializeIndexedWaves(ProjectFolder);

	SetDataFolder fldrSav
End

//!
//! @brief CheckBoxControl handling saving user choices to global variables
Function UpdateFromFile(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR UpdateDataFromFile = :Experimental_Info:UpdateDataFromFile;
	UpdateDataFromFile = checked;

	SetDataFolder fldrSav
End

//!
//! @brief SetVariableControl calls ::ComputeTrapProperties to handle value changes
Function Set_TrapParams(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav = GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	ComputeTrapProperties();
	
	SetDataFolder fldrSav
End
	
//!
//! @brief SetVariableControl calls ::Update_Magnification to handle value change
Function Set_Mag(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	Update_Magnification();
	
	SetDataFolder fldrSav
End

//!
//! @brief SetVariableControl handling saving user choices to global variables
Function Set_PeakOD(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Nothing to do at this time
	
	SetDataFolder fldrSav
End

//!
//! @brief SetVariableControl handling saving user choices to global variables
Function Set_theta(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Nothing to do at this time
	
	SetDataFolder fldrSav
End

//!
//! @brief CheckboxControl handling saving user choices to global variables
Function Set_center(ctrlName,checked) : CheckboxControl
	String ctrlName
	Variable checked

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR CentersFixed = :Fit_Info:CentersFixed;
	CentersFixed = checked;
	
	SetDataFolder fldrSav
End

//!
//! @brief PopupMenuControl handling saving user choices to global variables
Function Set_DualAxis(ctrlName,checked) : CheckboxControl
	String ctrlName
	Variable checked

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	NVAR DualAxis = :Experimental_Info:DualAxis;

	if(checked)
		//set 2 axis imaging
		DualAxis = 1;
	else
		//set single axis imaging
		DualAxis = 0;
	endif
	
	SetDataFolder fldrSav
End


//!
//! @brief PopupMenuControl handling saving user choices to global variables
Function SetCamDir(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR CamDir = :Experimental_Info:camdir;
	
	CamDir = popNum;

	SetDataFolder fldrSav
End

//!
//! @brief PopupMenuControl handling saving user choices to global variables
Function SetDataType(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	SVAR DataType = :Experimental_Info:DataType;
	
	DataType = popStr;

	SetDataFolder fldrSav
End

//!
//! @brief ButtonControl calls ::AbsImg_AnalyzeImage(OptDepth)
Function Refit(ctrlName) : ButtonControl
	String ctrlName

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	Wave OptDepth=:OptDepth
	// This needs to be selected based upon what axes we are looking at (mode?)
	// Not the camera
	AbsImg_AnalyzeImage(OptDepth)
	
	SetDataFolder fldrSav
End

//!
//! @brief PopupMenuControl handling saving user choices to global variables
Function SetFit_Type(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR fit_type=:Fit_Info:fit_type
	fit_type = popNum

	SetDataFolder fldrSav
End

//!
//! @brief SetVariableControl that calls ::ComputeCastinDum
Function SetCastDum(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	ComputeCastinDum();

	SetDataFolder fldrSav
End

//!
//! @brief Checks provided trap frequencies and makes call to ::CastinDum
Function ComputeCastinDum()
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR omgX=:Experimental_Info:omgX;
	NVAR omgY=:Experimental_Info:omgY;
	NVAR omgZ=:Experimental_Info:omgZ;
	NVAR expand_time = :Experimental_Info:expand_time
	NVAR CastDum_xscale = :Experimental_Info:CastDum_xscale;
	NVAR CastDum_yscale = :Experimental_Info:CastDum_yscale;
	NVAR CastDum_zscale = :Experimental_Info:CastDum_zscale;

	// Verify that all of the desired variables are valid numbers
	If( numtype(omgX) != 0 || numtype(omgY) != 0 || numtype(omgZ) != 0 || numtype(expand_time) != 0 )
		CastDum_xscale = Nan;
		CastDum_yscale = Nan;
		CastDum_zscale = Nan;
		Return 0;
	endif
	

	// Compute the Castin Dum paramaters
	make/D/N=3/O CastinDumWave1, CastinDumWave2
	Wave CastinDumOmega  = CastinDumWave1;
	Wave CastinDumLambda = CastinDumWave2;
	CastinDumOmega  = {omgX,omgY,omgZ};
		
	CastinDum(expand_time / 1000, CastinDumOmega, CastinDumLambda); 	// Expand time is in ms
	
	CastDum_xscale = CastinDumLambda[0];
	CastDum_yscale = CastinDumLambda[1];
	CastDum_zscale = CastinDumLambda[2];
		
	KillWaves CastinDumOmega, CastinDumLambda;

	SetDataFolder fldrSav
End

//!
//! @brief PopupMenuControl translates choice and saves to global variable
Function SetAutoUpdate(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR autoupdate=:IndexedWaves:autoupdate
	autoupdate = popNum-1;
	// 0 -> no update
	// 1 -> auto increment
	// 2 -> index from file
	
	SetDataFolder fldrSav
End

//!
//! @brief ButtonControl that calls ::UpdateWaves
Function ManUpdate(ctrlName) : ButtonControl
	String ctrlName
	UpdateWaves()
End

// ***********************dec_update **********************************************************************
// this function deincrements the running waves of temperature/ density/ number etc.
// 17Oct04: IBS modified to change the length of the waves as well
//!
//! @brief ButtonControl that calls ::IndexedWavesDeletePoints to remove last point from IndexedWaves
Function dec_update(ctrlName) : ButtonControl
	String ctrlName

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR index=:IndexedWaves:index
	
	// deincrement index (of course keep it above zero!)
	IndexedWavesDeletePoints(ProjectFolder,index-1,1);

	SetDataFolder fldrSav
end

//********************************************************************************************************************
//!
//! @brief PopupMenuControl that handles selection of ROI things
Function SetROI(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String WindowName = CurrentPanel + "#ColdAtomInfoImage";
	
	NVAR ymax=:fit_info:ymax,ymin=:fit_info:ymin;
	NVAR xmax=:fit_info:xmax,xmin=:fit_info:xmin;
	NVAR bgymax=:fit_info:bgymax,bgymin=:fit_info:bgymin;
	NVAR bgxmax=:fit_info:bgxmax,bgxmin=:fit_info:bgxmin;
	Variable hold;
	wave/I ROI_mask = :ROI_mask;
	NVAR RotateImage = :Experimental_Info:RotateImage;
	NVAR RotAng = :Experimental_Info:RotAng;

	// First, reset the ROI if requested
	if (popNum==1 || popNum==2)
		ymax = max(vcsr(A,WindowName),vcsr(B,WindowName));
		ymin = min(vcsr(A,WindowName),vcsr(B,WindowName));
		xmax = max(hcsr(A,WindowName),hcsr(B,WindowName));
		xmin = min(hcsr(A,WindowName),hcsr(B,WindowName));
		
		bgymax = max(vcsr(C,WindowName),vcsr(D,WindowName));
		bgymin = min(vcsr(C,WindowName),vcsr(D,WindowName));
		bgxmax = max(hcsr(C,WindowName),hcsr(D,WindowName));
		bgxmin = min(hcsr(C,WindowName),hcsr(D,WindowName));
		
		//construct the ROI_mask
		ROI_mask[][] = 1;
		
		if(RotateImage)
			//Rotate ROI vertices CCW to compensate for image rotation
			Make/O/FREE/D/N=(4,2) RotCoords
			RotCoords[0][] = Abs(q-1)*(cos(-RotAng*pi/180)*xmin - sin(-RotAng*pi/180)*ymin) + q*(sin(-RotAng*pi/180)*xmin + cos(-RotAng*pi/180)*ymin);
			RotCoords[1][] = Abs(q-1)*(cos(-RotAng*pi/180)*xmin - sin(-RotAng*pi/180)*ymax) + q*(sin(-RotAng*pi/180)*xmin + cos(-RotAng*pi/180)*ymax);
			RotCoords[2][] = Abs(q-1)*(cos(-RotAng*pi/180)*xmax - sin(-RotAng*pi/180)*ymin) + q*(sin(-RotAng*pi/180)*xmax + cos(-RotAng*pi/180)*ymin);
			RotCoords[3][] = Abs(q-1)*(cos(-RotAng*pi/180)*xmax - sin(-RotAng*pi/180)*ymax) + q*(sin(-RotAng*pi/180)*xmax + cos(-RotAng*pi/180)*ymax);
			
			//find maximum values in the unrotated coords
			variable xmaxrot = max(max(RotCoords[0][0],RotCoords[1][0]),max(RotCoords[2][0],RotCoords[3][0]));
			variable xminrot = min(min(RotCoords[0][0],RotCoords[1][0]),min(RotCoords[2][0],RotCoords[3][0]));
			variable ymaxrot = max(max(RotCoords[0][1],RotCoords[1][1]),max(RotCoords[2][1],RotCoords[3][1]));
			variable yminrot = min(min(RotCoords[0][1],RotCoords[1][1]),min(RotCoords[2][1],RotCoords[3][1]));
			variable pmax = (xmaxrot - DimOffset(ROI_mask, 0))/DimDelta(ROI_mask,0);
			variable pmin = (xminrot - DimOffset(ROI_mask, 0))/DimDelta(ROI_mask,0);
			variable qmax = (ymaxrot - DimOffset(ROI_mask, 1))/DimDelta(ROI_mask,1);
			variable qmin = (yminrot - DimOffset(ROI_mask, 1))/DimDelta(ROI_mask,1);
			
			Variable i;
			For(i=pmin;i<=pmax;i+=1)
			 
			 	variable xtemp = DimOffset(ROI_mask, 0) + i*DimDelta(ROI_mask,0);
			 	
				Variable j;
				For(j=qmin;j<=qmax;j+=1)
			
					variable ytemp = DimOffset(ROI_mask, 1) + j*DimDelta(ROI_mask,1);
					variable xtemprot = (cos(RotAng*pi/180)*xtemp - sin(RotAng*pi/180)*ytemp);
					variable ytemprot = (sin(RotAng*pi/180)*xtemp + cos(RotAng*pi/180)*ytemp);
					ROI_mask[i][j] = (((xmin < xtemprot) && (xmax > xtemprot) && (ymin < ytemprot) && (ymax > ytemprot)) ? 0 : 1);
			
				endfor
			endfor
		else
		
			ROI_mask = (((xmin < x) && (xmax > x) && (ymin < y) && (ymax > y)) ? 0 : 1);
		
		endif
	endif
		
	// Now rescale
	SVAR camera = :Experimental_Info:camera

	switch(popNum)
		case 1:	// Only set ROI (do nothing here)
			break;
		case 2:	// Set the View to the ROI
			SetAxis/W=$(WindowName) left ymin, ymax;
			
			// If we are the pixelfly reverse the X axes
			if (stringmatch(Camera,"PixelFly") == 1)
				SetAxis/W=$(WindowName) bottom xmax, xmin;
			else
				SetAxis/W=$(WindowName) bottom xmin, xmax;
			endif


			break;
		case 3: // Zoom to the ROI
			SetAxis/W=$(WindowName) left ymin, ymax	;
			
			// If we are the pixelfly reverse the X axes
			if (stringmatch(Camera,"PixelFly") == 1)
				SetAxis/W=$(WindowName) bottom xmax, xmin;
			else
				SetAxis/W=$(WindowName) bottom xmin, xmax;
			endif

			break
		case 4: // Unzoom
			SetAxis/W=$(WindowName)/A left;					

			// If we are the pixelfly reverse the X axes
			if (stringmatch(Camera,"PixelFly") == 1)
				SetAxis/A/R/W=$(WindowName) bottom;
			else
				SetAxis/A/W=$(WindowName) bottom;
			endif

			break
		default:
			print "Error: SetROI: Invalid case";
			break;	
	endswitch

	SetDataFolder fldrSav
End

//!
//! @brief ButtonControl that reads current ROI and moves cursors to bound it.
Function CursorsToROI(ctrlName) : ButtonControl
	String ctrlName
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String WindowName = CurrentPanel + "#ColdAtomInfoImage";
	
	NVAR ymax=:fit_info:ymax,ymin=:fit_info:ymin;
	NVAR xmax=:fit_info:xmax,xmin=:fit_info:xmin;
	NVAR bgymax=:fit_info:bgymax,bgymin=:fit_info:bgymin;
	NVAR bgxmax=:fit_info:bgxmax,bgxmin=:fit_info:bgxmin;
	
	Cursor/I/W=$(WindowName) A, optdepth, xmax, ymax;
	Cursor/I/W=$(WindowName) B, optdepth, xmin, ymin;
	Cursor/I/W=$(WindowName) C, optdepth, bgxmax, bgymax;
	Cursor/I/W=$(WindowName) D, optdepth, bgxmin, bgymin;
	
	SetDataFolder fldrSav
End

//!
//! @brief PopupMenuControl that saves selection to global variables
Function PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR slicesource=:lineprofiles:slicesource

	slicesource = popNum
End


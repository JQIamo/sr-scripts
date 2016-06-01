#pragma rtGlobals=2		// Use modern global access method.

//! @file
//! @brief Allows for saving and retrieval of ROIs
//! @details Add a dialog to allow users to save a ROI with a given name and later apply it to any data series

// *************************************
//!
//! @brief Function to initialize the saved ROI package folder.
//! @details Creates the packages data folder in <b>root:Packages:SavedROIs</b> if necessary.
//! Does not overwrite contents, so technically safe to call multiple times.
//! @note Only need to this function once, the first time the package is opened.

function Init_SavedROIs()

	//Create folder to store ROI coordinates
	NewDataFolder/O root:Packages:SavedROIs;
	
end

//function SaveROI(String DataSeries, String nameROI)



//end

function Dialog_SaveROI()

	variable HostProjectNum;
	String ROI_Name;
	
	Init_SavedROIs()
	Init_ColdAtomInfo();	//Creates the needed variables if they do not already exist
	
	//Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths;
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath;
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	
	Prompt HostProjectNum, "Save ROI From...", popup, ActivePaths
	Prompt ROI_Name, "Saved ROI Name:"
	
	DoPrompt "Save ROI cursor positions", HostProjectNum, ROI_Name;
	
	if (V_Flag)
		return -1			//User canceled
	endif
	
	String ROI_path = "root:Packages:SavedROIs:" + ROI_Name;
	
	//Check if ROI exists by that name already, if not create a subfolder
	if (DataFolderExists(ROI_path))
		DoAlert 1, "ROI already exists, do you want to overwrite?"
		if (V_flag == 2)
			return -1
		endif
	else
		NewDataFolder/O $ROI_path;
	endif
	
	
	String HostPath = StringFromList(HostProjectNum-1, ActivePaths);
	
	String SavePanel = CurrentPanel;
	String SavePath = CurrentPath;
	String fldrSav = GetDataFolder(1);
	
	Set_ColdAtomInfo(HostPath)
	
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	SetDataFolder ProjectFolder
	
	//Get cursor positions:
	NVAR y_max=:fit_info:ymax,y_min=:fit_info:ymin;
	NVAR x_max=:fit_info:xmax,x_min=:fit_info:xmin;
	NVAR bgy_max=:fit_info:bgymax,bgy_min=:fit_info:bgymin;
	NVAR bgx_max=:fit_info:bgxmax,bgx_min=:fit_info:bgxmin;
	
	SetDataFolder ROI_path;
	
	//Save cursor positions:
	Variable/G xmax = x_max
	Variable/G xmin = x_min
	Variable/G ymax = y_max
	Variable/G ymin = y_min
	Variable/G bgxmax = bgx_max
	Variable/G bgxmin = bgx_min
	Variable/G bgymax = bgy_max
	Variable/G bgymin = bgy_min
	
	Set_ColdAtomInfo(SavePath)
	SetDataFolder fldrSav
	
end

function Dialog_LoadROI()
	
	variable TgtProjectNum;
	String ROI_Name;
	
	Init_SavedROIs()
	Init_ColdAtomInfo();	//Creates the needed variables if they do not already exist
	
	//Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths;
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath;
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	
	//Create a dialog box with a list of saved ROIs
	Variable ROIcount = CountObjects("root:Packages:SavedROIs",4); //count number of data folders
	
	String Active_ROIs = "";
	//Loop over data folders, add them to list
	Variable i;
	for(i=0 ; i < ROIcount ; i+=1)	
		Active_ROIs = AddListItem(GetIndexedObjName("root:Packages:SavedROIs",4,i), Active_ROIs)
	endfor												
	//String Active_ROIs = "a;b"
	
	Prompt TgtProjectNum, "Load ROI To:", popup, ActivePaths
	Prompt ROI_Name, "Saved ROI Name:", popup, Active_ROIs
	
	DoPrompt "Load ROI cursor positions", TgtProjectNum, ROI_Name;
	
	if (V_Flag)
		return -1			//User canceled
	endif
	
	String ROI_path = "root:Packages:SavedROIs:" + ROI_Name;
	
	
	
	String TgtPath = StringFromList(TgtProjectNum-1, ActivePaths);
	
	String SavePanel = CurrentPanel;
	String SavePath = CurrentPath;
	String fldrSav = GetDataFolder(1);
	
	Set_ColdAtomInfo(TgtPath)
	
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	SetDataFolder ProjectFolder
	
	//Get saved cursor positions:
	NVAR xmax = $(ROI_path + ":xmax")
	NVAR xmin = $(ROI_path + ":xmin")
	NVAR ymax = $(ROI_path + ":ymax")
	NVAR ymin = $(ROI_path + ":ymin")
	NVAR bgxmax = $(ROI_path + ":bgxmax")
	NVAR bgxmin = $(ROI_path + ":bgxmin")
	NVAR bgymax = $(ROI_path + ":bgymax")
	NVAR bgymin = $(ROI_path + ":bgymin")
	
	//Set Cursor Positions:
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
	Cursor/I/W = $(ImageWindowName) A, optdepth, xmax, ymax;
	Cursor/I/W = $(ImageWindowName) B, optdepth, xmin, ymin;
	Cursor/I/W = $(ImageWindowName) C, optdepth, bgxmax, bgymax;
	Cursor/I/W = $(ImageWindowName) D, optdepth, bgxmin, bgymin;
	SetROI("",1,"")
	
	Set_ColdAtomInfo(SavePath)
	SetDataFolder fldrSav
	
	
	

end

function LoadROI(ROI_Name)

	//This function loads the ROI specified. The data series that the ROI is applied to is the one specified by "CurrentPanel", or the last one that had a button pushed.
	String ROI_Name;
	
	String ROI_path = "root:Packages:SavedROIs:" + ROI_Name;
	if (DataFolderExists(ROI_Path)==0)
		print "ROI Not Found"
		return -1
	endif
	
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	
	//Get saved cursor positions:
	NVAR xmax = $(ROI_path + ":xmax")
	NVAR xmin = $(ROI_path + ":xmin")
	NVAR ymax = $(ROI_path + ":ymax")
	NVAR ymin = $(ROI_path + ":ymin")
	NVAR bgxmax = $(ROI_path + ":bgxmax")
	NVAR bgxmin = $(ROI_path + ":bgxmin")
	NVAR bgymax = $(ROI_path + ":bgymax")
	NVAR bgymin = $(ROI_path + ":bgymin")
	
	//Set Cursor Positions:
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
	Cursor/I/W = $(ImageWindowName) A, optdepth, xmax, ymax;
	Cursor/I/W = $(ImageWindowName) B, optdepth, xmin, ymin;
	Cursor/I/W = $(ImageWindowName) C, optdepth, bgxmax, bgymax;
	Cursor/I/W = $(ImageWindowName) D, optdepth, bgxmin, bgymin;
	SetROI("",1,"")
	
end


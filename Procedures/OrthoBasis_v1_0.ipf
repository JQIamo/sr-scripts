#pragma rtGlobals=2		// Use modern global access method without compatibility mode.

// *************************************
// Function to initialize the GS basis creation/probe reconstruction package.
// Only call this function once, the first time the package is opened.
//
// *************************************

function Init_OrthoBasis()

	//Create folder to store the probe and basis images
	NewDataFolder/O root:Packages:OrthoBasis;

end

// ***********************************************
// Function to make a new stack of probe images for orthonormalization
// ProjectID is the name of the data series which will source the probe images
//
// ***********************************************

function New_ProbeStack(ProjectID)

	string ProjectID
	
	//create package folder if it does not exist
	Init_OrthoBasis();
	
	// Verify that the data series exists
	if (Exists_ColdAtomInfo("root:" + ProjectID) == 0)
		print "New_ProbeStack:  source does not exist";
		return 0;
	endif
	
	//Make a folder to contain the stack and basis
	String fldrSav = GetDataFolder(1);
	string ProbePath = "root:Packages:OrthoBasis:" + ProjectID;
	NewDataFolder/O $ProbePath;
	SetDataFolder ProbePath;
	
	//Initialize the image stack
	If(exists(ProbePath + ":ProbeStack") == 0)
		Make/D/N=(0,0,0) ProbeStack;
	endif
	
	//Initialize probe file tracking wave
	If(exists(ProbePath + ":ProbeFiles") == 0)
		Make/T/N=0 ProbeFiles;
	endif

	SetDataFolder fldrSav;
end

// ***********************************************
// Function to add a probe image to the stack.
// FileName is the name of the file from which the probe image is derived.
// PrImage is the image to add to the stack
//
// ***********************************************

function Add_ProbeImage(FileName, PrImage)

	string FileName
	wave PrImage
	
	//Assumes that the correct project folder has been set by Load_Img
	String fldrSav = GetDataFolder(1);
	
	//Get ProjectID
	string ProjectID = ParseFilePath(0, fldrSav, ":", 1, 0);
	
	//Make sure that all folders and waves exist
	New_ProbeStack(ProjectID)
	string ProbePath = "root:Packages:OrthoBasis:" + ProjectID;
	SetDataFolder ProbePath;
	wave/D ProbeStack = :ProbeStack;
	wave/T ProbeFiles = :ProbeFiles;
	
	If(DimSize(ProbeStack, 2) == 0)
	//This is the first image on the stack
	
		redimension/D/N=(DimSize(PrImage, 0), DimSize(PrImage, 1),1) ProbeStack;
		SetScale/P x, DimOffset(PrImage, 0), DimDelta(PrImage, 0), "", ProbeStack;
		SetScale/P y, DimOffset(PrImage, 1), DimDelta(PrImage, 1), "", ProbeStack;
		ProbeStack[p][q][0] = PrImage[p][q];
		redimension/D/N=(1) ProbeFiles;
		ProbeFiles[0] = FileName;
	
	elseif((DimSize(PrImage, 0) == DimSize(ProbeStack, 0)) && (DimSize(PrImage, 1) == DimSize(ProbeStack, 1)))
	//This is not the first image on the stack
	
		InsertPoints/M=2 Dimsize(ProbeStack, 2), 1, ProbeStack;
		ProbeStack[p][q][Dimsize(ProbeStack, 2) - 1] = PrImage[p][q];
		redimension/D/N=(Dimsize(ProbeFiles, 0) + 1) ProbeFiles;
		ProbeFiles[Dimsize(ProbeFiles, 0) - 1] = FileName;
	
	else
	//handle errors
		
		print "Add_ProbeImage:  Image size does not match stack";
		return 0;
		
	endif
	
	SetDataFolder fldrSav;
end
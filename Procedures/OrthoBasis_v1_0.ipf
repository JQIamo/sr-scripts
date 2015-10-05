#pragma rtGlobals=2		// Use modern global access method without compatibility mode.
//! @file
//! @brief Does generation of OrthoNormalBasis construction via Gram-Schmidt
//! @details OrthoNormal Basis is generated on a per-data folder/project basis

// *************************************
//!
//! @brief Function to initialize the GS basis creation/probe reconstruction package.
//! @details Creates the packages data folder in <b>root:Packages:OrthoBasis</b> if necessary.
//! Does not overwrite contents, so technically safe to call multiple times.
//! @note Only need to this function once, the first time the package is opened.
function Init_OrthoBasis()

	//Create folder to store the probe and basis images
	NewDataFolder/O root:Packages:OrthoBasis;

end

// ***********************************************
//!
//! @brief Function to make a new stack of probe images for orthonormalization
//! @details Checks if a data folder for the given \p ProjectID exists, and if so, makes
//! sure <b>root:Packages:OrthoBasis:\<ProjectID\></b> exists (creating it if necessary), as
//! well as making (if necessary) the following waves within that data folder:
//! + ProbeStack
//! + ProbeFiles
//! + BasisROI
//!
//! @param[in] ProjectID is the name of the data series which will source the probe images
//! @return 0 on error
//! @return 1 on success
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
	
	//Initialize wave to track basis ROI
	If(exists(ProbePath + ":BasisROI") == 0)
		Make/I/N=(0,0) BasisROI;
	endif

	SetDataFolder fldrSav;
	return 1;
end

// ***********************************************
//!
//! @brief Function to add a probe image to the stack.
//! @details Takes a new probe image in and adds it to the current stack of probe images.
//! If this is the first probe image to be added, makes sure the dimensions and scaling
//! of the probe stack match the input probe image.  If this is a new image to an extant
//! probe stack, makes sure the dimensions of the image to add match up with the images
//! already in the probe stack.
//!
//! \p ProjectID is automatically detected from the current data folder path, and the
//! probe stack is generated at <b>root:Packages:OrthoBasis:\<ProjectID\>:ProbeStack</b>,
//! while the matching file names are stored at
//! <b>root:Packages:OrthoBasis:\<ProjectID\>:ProbeFiles</b>
//!
//! @param[in] FileName the name of the file from which the probe image is derived.
//! @param[in] PrImage  the image to add to the stack
//! @return 0 on error
//! @return 1 on success
function Add_ProbeImage(FileName, PrImage)

	string FileName
	wave PrImage
	
	//Assumes that the correct project folder has been set by Load_Img
	String fldrSav = GetDataFolder(1);
	
	//Get ProjectID
	string ProjectID = ParseFilePath(0, fldrSav, ":", 1, 0);
	
	//Make sure that all folders and waves exist
	If(New_ProbeStack(ProjectID) == 1)
		string ProbePath = "root:Packages:OrthoBasis:" + ProjectID;
		SetDataFolder ProbePath;
		wave/D ProbeStack = :ProbeStack;
		wave/T ProbeFiles = :ProbeFiles;
	
		If(DimSize(ProbeStack, 2) == 0)
		//This is the first image on the stack
	
			redimension/D/N=(DimSize(PrImage, 0), DimSize(PrImage, 1),1) ProbeStack;
			SetScale/P x, DimOffset(PrImage, 0), DimDelta(PrImage, 0), "", ProbeStack;
			SetScale/P y, DimOffset(PrImage, 1), DimDelta(PrImage, 1), "", ProbeStack;
			ProbeStack[][][0] = PrImage[p][q];
			redimension/N=(1) ProbeFiles;
			ProbeFiles[0] = FileName;
	
		elseif((DimSize(PrImage, 0) == DimSize(ProbeStack, 0)) && (DimSize(PrImage, 1) == DimSize(ProbeStack, 1)))
		//This is not the first image on the stack
	
			InsertPoints/M=2 Dimsize(ProbeStack, 2), 1, ProbeStack;
			ProbeStack[][][Dimsize(ProbeStack, 2) - 1] = PrImage[p][q];
			redimension/N=(Dimsize(ProbeFiles, 0) + 1) ProbeFiles;
			ProbeFiles[Dimsize(ProbeFiles, 0) - 1] = FileName;
	
		else
		//handle errors
		
			print "Add_ProbeImage:  Image size does not match stack";
			return 0;
		
		endif
		
	endif
	
	//reset datafolder
	SetDataFolder fldrSav;
end

// ***********************************************
//!
//! @brief Function to make the orthonormal basis.
//! @details Uses the "stabilized" Gram-Schimdt process to create an orthonormal basis set of
//! probe images.  It expects an extant probe stack in
//! <b>:root:Packages:OrthoBasis:\<ProjectID\>:ProbeStack</b>
//! and will output the resulting orthonormal basic to
//! <b>:root:Packages:OrthoBasis:\<ProjectID\>:BasisStack</b>
//!
//! @param[in] ProjectID the name of the data series which sourced the probe images
//! @return 0 on error
//! @return 1 on success
//! @sa http://en.wikipedia.org/wiki/Gram%E2%80%93Schmidt_process
function GS_CreateBasis(ProjectID)

	string ProjectID
	
	//Save the current datafolder
	String fldrSav = GetDataFolder(1);
	
	//Make sure that all folders and waves exist
	If(New_ProbeStack(ProjectID) == 1)
	
		//setup wave references
		string ProbePath = "root:Packages:OrthoBasis:" + ProjectID;
		SetDataFolder ProbePath;
		wave/D ProbeStack = :ProbeStack;
		wave/T ProbeFiles = :ProbeFiles;
		
		//check that there are images in the probe stack
		if(Dimsize(ProbeStack, 2) != 0)
			
			//Make sure that the basis does not already exist
			string basisRef = ProbePath + ":BasisStack";
			If(exists(basisRef) == 0)
			
				Duplicate/O/D ProbeStack, $basisRef;
				wave/D BasisStack = :BasisStack;
				wave/I BasisROI = :BasisROI;
				
				//Get the ROI from the correct data series
				SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath;
				string ColdAtomSave = CurrentPath;
				string ProjectFolder = "root:" + ProjectID;
				Set_ColdAtomInfo(ProjectFolder);
				SetDataFolder ProjectFolder;
				
				//get and set the ROI for the basis
				wave/I ROI_mask = :ROI_mask;
				Duplicate/I/O ROI_mask, BasisROI;
				
				//Reset the data series and datafolder
				Set_ColdAtomInfo(ColdAtomSave);
				SetDataFolder(ProbePath);
				
				//mask out the atom region
				//this mask will contain the original probe vectors
				//Duplicate/O/D/FREE BasisStack, BasisStack_maskA, BasisStack_maskB;
			
				variable i;
				//Make the orthogonal basis using Gram-Schmidt
				For(i=0; i<DimSize(BasisStack, 2); i+=1)
				
					//loop through all vectors i.
					
					//for debugging
					//print "i = " + num2str(i);
					
					//make orthogonal to previous vectors
					variable j;
					For(j=i-1; j>=0; j-=1)
					
						//loop through the j vectors previous to i.
						//Get projection of i onto j.
						MatrixOP/O/FREE Projection = (((ProbeStack[][][i]).(BasisROI[][][0]*BasisStack[][][j]))/((BasisStack[][][j]).(BasisROI[][][0]*BasisStack[][][j])));//*BasisStack[][][j];
						
						//Make vector i orthogonal to vector j
						BasisStack[][][i] = BasisStack[p][q][i] - Projection[0]*BasisStack[p][q][j];
						
						//for debugging
						//print "j = " + num2str(j);
					
					endfor
					
				endfor
				
				//remask out the atom region
				//Duplicate/O/D/FREE BasisStack, BasisStack_mask;
				//BasisStack_mask *= BasisROI;
				
				//Normalize the Basis
				variable k;
				For(k=0; k<DimSize(BasisStack, 2); k+=1)
				
					//Get norm of vector k
					MatrixOP/O/FREE Mag_k = ((BasisStack[][][k]).(BasisROI[][][0]*BasisStack[][][k]));
					//Normalize
					BasisStack[][][k] = BasisStack[p][q][k]/(sqrt(Mag_k[0]));
					
					//for debugging
					//print "k = " + num2str(k);
					//print "mag " + num2str(k) + " = " + num2str(sqrt(Mag_k[0]));
				
				endfor
				
			else
			
				print "GS_CreateBasis: Basis already exists";
				return 0;
			
			endif
			
		else
		
			print "GS_CreateBasis: No images in probe stack";
			return 0;
		
		endif
	
	endif
	
	//reset datafolder
	SetDataFolder fldrSav;
end

function Dialog_GS_CreateBasis()
	
	variable TargProjectNum;
	variable startNum = -1;
	variable endNum = 1;
	variable basisSize;
	string skipList;

	Init_ColdAtomInfo();	// Creates the needed variables if they do not already exist

	// Create a dialog box with a list of active InfoProjects
	SVAR ActivePaths = root:Packages:ColdAtom:ActivePaths
	SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel
	
	//run the prompt
	Prompt TargProjectNum, "Target Series for Gram-Schmidt:", popup, ActivePaths
	Prompt basisSize, "Number of images to include in the basis:"
	Prompt startNum, "File number of first point in data range (without leading zeroes):"
	Prompt endNum, "File number of last point in data range (without leading zeroes):"
	Prompt skipList, "semicolon separated list of file numbers to exclude from range (without leading zeroes):"
	DoPrompt "Batch Run", TargProjectNum, basisSize, startNum, endNum, skipList
	
	if(V_Flag)
		return -1		// User canceled
	endif
	
	//set data folders appropriately
	String TargPath = StringFromList(TargProjectNum-1, ActivePaths)
		
	String SavePanel = CurrentPanel
	String SavePath = CurrentPath
	String fldrSav= GetDataFolder(1)
		
	Set_ColdAtomInfo(TargPath)
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	SetDataFolder ProjectFolder;
	String ProjectID = ParseFilePath(0, ProjectFolder, ":", 1, 0);
	
	//ensure Basis mode is active on the data series
	ChooseAnalysis("",2,"")
	
	//get a random sample of the data range
	variable i;
	variable rand, temp, fnum;
	For(i=0;i<basisSize;i+=1)
		rand = (enoise(1, 2)+1)/2; //get a uniform random number from 0 to 1 with Mersenne Twister.
		fnum =round((endNum-startNum)*rand+startNum); //get an integer in the data range
		If(WhichListItem(num2str(fnum),skipList,";",0,1)!=-1)
			i-=1; //If file fnum is already in the basis or is in the skipList, get a new fnum.
		else
			BatchRun(-1, fnum, 0, skipList);
			skipList= AddListItem(num2str(fnum), skipList);
		endif
	endfor
	
	GS_CreateBasis(ProjectID);
	
	Set_ColdAtomInfo(SavePath)
	SetDataFolder fldrSav
end
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
	
	//Initialize global variables to track basis ROI
	If(exists(ProbePath + ":xmaxBasis") == 0)
		Variable/G $(ProbePath + ":xmaxBasis") = 0;
	endif
	
	If(exists(ProbePath + ":ymaxBasis") == 0)
		Variable/G $(ProbePath + ":ymaxBasis") = 0;
	endif
	
	If(exists(ProbePath + ":xminBasis") == 0)
		Variable/G $(ProbePath + ":xminBasis") = 0;
	endif
	
	If(exists(ProbePath + ":yminBasis") == 0)
		Variable/G $(ProbePath + ":yminBasis") = 0;
	endif

	SetDataFolder fldrSav;
	return 1;
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
// Function to make the orthonormal basis.
// 
// ProjectID is the name of the data series which sourced the probe images.
//
// ***********************************************

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
				
				//Get the ROI from the correct data series
				SVAR CurrentPath = root:Packages:ColdAtom:CurrentPath;
				string ColdAtomSave = CurrentPath;
				string ProjectFolder = "root:" + ProjectID;
				Set_ColdAtomInfo(ProjectFolder);
				SetDataFolder ProjectFolder;
				
				//The ROI bounds
				NVAR ymax=:fit_info:ymax,ymin=:fit_info:ymin;
				NVAR xmax=:fit_info:xmax,xmin=:fit_info:xmin;
				NVAR xmaxBasis = $(ProbePath + ":xmaxBasis"), xminBasis = $(ProbePath + ":xminBasis");
				NVAR ymaxBasis = $(ProbePath + ":ymaxBasis"), yminBasis = $(ProbePath + ":yminBasis");
				ymaxBasis = ymax;
				yminBasis = ymin;
				xmaxBasis = xmax;
				xminBasis = xmin;
				
				//Reset the data series and datafolder
				Set_ColdAtomInfo(ColdAtomSave);
				SetDataFolder(ProbePath);
				
				//mask out the atom region
				Duplicate/O/D/FREE BasisStack, BasisStack_mask;
				BasisStack_mask *= ( x < xmaxBasis && x > xminBasis && y < ymaxBasis && y > yminBasis ? 0 : 1);
				
				//Make the orthogonal basis using Gram-Schmidt
				variable i;
				For(i=0; i<DimSize(BasisStack, 2); i+=1)
				
					//loop through all vectors i.
					
					//for debugging
					//print "i = " + num2str(i);
					
					//make orthogonal to previous vectors
					variable j;
					For(j=i-1; j>=0; j-=1)
					
						//loop through the j vectors previous to i.
						//Get projection of i onto j.
						MatrixOP/O/FREE Projection = (((BasisStack_mask[][][i]).(BasisStack_mask[][][j]))/((BasisStack_mask[][][j]).(BasisStack_mask[][][j])));//*BasisStack[][][j];
						
						//Make vector i orthogonal to vector j
						BasisStack[][][i] = BasisStack[p][q][i] - Projection[0]*BasisStack[p][q][j];
						
						//for debugging
						//print "j = " + num2str(j);
					
					endfor
				
					
				endfor
				
				//remask out the atom region
				BasisStack_mask = BasisStack;
				BasisStack_mask *= ( x < xmaxBasis && x > xminBasis && y < ymaxBasis && y > yminBasis ? 0 : 1);
				
				//Normalize the Basis
				variable k;
				For(k=0; k<DimSize(BasisStack, 2); k+=1)
				
					//Get norm of vector k
					MatrixOP/O/FREE Mag_k = ((BasisStack_mask[][][k]).(BasisStack_mask[][][k]))^(1/2);
					//Normalize
					BasisStack[][][k] = BasisStack[p][q][k]/Mag_k;
					
					//for debugging
					//print "k = " + num2str(k);
				
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
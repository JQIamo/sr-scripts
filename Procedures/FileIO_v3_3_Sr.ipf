#pragma rtGlobals=1		// Use modern global access method.


constant OldStyleImage = 1;


// This file contains various functions required for loading image data
// for the rubudium experiment.

/// ********************************************************
// FileNameArray(FileArray, FileName, InitialIndex, FinalIndex)
//
// This function allows for batch processing of many files
// and constructs a list of file names to process
// FileName, InitialIndex, and FinalIndex are all lists of the form:
//
// The return value the list of files with a ; delimination.
//
// FileName: "Macintosh HD:data:PF_02Mar2005_;Macintosh HD:data:PF_03Mar2005_; "
// InitialIndex "23;43"
// FinalIndex "42;55"
//
Function/S FileNameArray(FileNameList, InitialIndex, FinalIndex)
	string FileNameList, InitialIndex, FinalIndex

	variable Initial, Final;
	string NextName, FileName, FileList = "";
		
	variable num = ItemsInList(InitialIndex);
	variable n, i;
	
	If (num != ItemsInList(FinalIndex))
		printf "Error (FileNameArray): List sizes do not match";
		return "";
	endif
	
	for (n = 0; n < num; n += 1)
	
		Initial = str2num( StringFromList(n, InitialIndex) );
		Final = str2num( StringFromList(n, FinalIndex) );
		if (n >= ItemsInList(FileNameList) )
			FileName = StringFromList(ItemsInList(FileNameList)-1, FileNameList);
		else
			FileName = StringFromList(n, FileNameList);
		endif
	
	
		if (Final < Initial)
			printf "Error (FileNameArray): Initial (%d) must be smaller than Final (%d)", Initial, Final;
			return "";
		endif

		for(i = Initial;i <= Final;i = i + 1)
			sprintf NextName, "%s%04d", FileName, i
			FileList = AddListItem(NextName, FileList, ";", Inf); // Inf appends to list
		endfor
	endfor
	
	
	return FileList;
end
	
/// ********************************************************
// AutoRunV3(ProjectID, FileName)
//
// this function is called by one of the camera softwares when an image is ready
// Version three extracts more information from the file header and 
// and relies less on user provided data (unless needed). 
//
// AutoRun is also included as a stub so older procedures will compile
//

Function AutoRun(Mode, ProjectID, FinalName)
	variable Mode;
	String ProjectID, FinalName;
end



Function AutoRunV3(ProjectID, FileName)
	string ProjectID, FileName

	// This creates the specified project if it does not already exist.
	//	New_ColdAtomInfo(ProjectID, "Rubidium_I"); // By Default make for the old experiment...
	//New_ColdAtomInfo(ProjectID, "RbYb");		// Something uses this passed param instead of "experiment" var
	New_ColdAtomInfo(ProjectID, "Sr");
	Set_ColdAtomInfo("root:" + ProjectID);
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Discover the name of the current image window
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";

	Wave OptDepth = :OptDepth
	//variable m;
	
	// First load the image
	Load_Img(OptDepth,FileName);
	duplicate/O OptDepth :Fit_Info:fit_optdepth
	duplicate/O OptDepth :Fit_Info:res_optdepth
	AbsImg_AnalyzeImage(OptDepth);

	// load scope data if checked also build "typical" scope
	// file name here
	string ScopeFile;
	ScopeFile = ReplaceString("PI_", FileName, "SC1_");
	ScopeFile = ReplaceString("PF_", ScopeFile, "SC1_");
	ScopeFile = ReplaceString("THOR_", ScopeFile, "SC1_");
	ScopeFile = ReplaceString("PIXIS_", ScopeFile, "SC1_");
	
	Load_Scope(ScopeFile,OldStyleImage)
	
	// Create "Nugget" of data for labview to read via DDE if it so desires
	if (exists("root:Packages:ColdAtom:ToLabView") == 0)
		String/G root:Packages:ColdAtom:ToLabView = "";
	endif 
	SVAR ToLabView=root:Packages:ColdAtom:ToLabView;
	NVAR index=:IndexedWaves:index
	NVAR number=:number;

	Sprintf ToLabView, "%e;%d;%s", number, index, ""

	
	SetDataFolder fldrSav	
end

//**************************************************************************************************
// This loads an IGOR binary file saved by labview containing one image and header information.
// In the past there were several functions which loaded files for each different camera,
// this has been condenced into this single routine which suffices

Function Load_Img(ImageName,FileName)
	Wave ImageName
	String FileName
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	String LoadedWaveName, TargetWaveName;
	String basename,savename, pathname,fullpathname;
	//String ImageDirection = "";

	SVAR Camera = :Experimental_Info:Camera;
	NVAR RotateImage = :Experimental_Info:RotateImage;
	SVAR Experiment = :Experimental_Info:Experiment;
	SVAR DataType = :Experimental_Info:DataType;
	SVAR ImageType = :Experimental_Info:ImageType;
	SVAR ImageDirection = :Experimental_Info:ImageDirection;
	NVAR magnification = :Experimental_Info:magnification;
	NVAR ISatCounts = :Experimental_Info:ISatCounts;
	NVAR Irace = :Experimental_Info:Irace;
	NVAR Ipinch = :Experimental_Info:Ipinch;
	NVAR Ibias = :Experimental_Info:Ibias;
	NVAR IQuad = :Experimental_Info:IQuad;
	NVAR DipolePower = :Experimental_Info:DipolePower;
	NVAR CrDipolePower = :Experimental_Info:CrDipolePower;
	NVAR trapmin0 = :Experimental_Info:trapmin0;
	NVAR detuning = :Experimental_Info:detuning;
	NVAR expand_time = :Experimental_Info:expand_time;
	NVAR moment = :Experimental_Info:moment;
	NVAR CamDir = :Experimental_Info:camdir;
	NVAR DualAxis = :Experimental_Info:DualAxis;
	NVAR Analysis_Type = :Fit_Info:Analysis_Type;

	Wave Isat = :Isat;
	Wave Raw1 = :Raw1;
	Wave Raw2 = :Raw2;
	Wave Raw3 = :Raw3;
	Wave Raw4 = :Raw4;
	Wave/I ROI_mask = :ROI_mask;
	Wave PrAlpha = :Fit_Info:PrAlpha;

	// FileName should include the full path to the file i.e., "D:Experiment:Data Acquisition:PFabsimg.ibw"

	try
		LoadWave/Q/O FileName; AbortOnRTE; //print "completed load"	
		//CDH: AbortOnRTE doesn't seem to work when file name doesn't exist...
	catch
		print "Error (Load_Img: LoadWave): ", GetRTErrMessage(), "Num: ", GetRTError(1);
		Abort;
	endtry

	//LoadWave/Q/O FileName		//CDH: no need to repeat command since try-catch evaluates it if no error!
	LoadedWaveName =  StringFromList(0,S_waveNames);
	TargetWaveName = NameOfWave(ImageName);

	// If by luck the loaded wave is the same as the target wave do nothing
	if ( stringmatch(LoadedWaveName,TargetWaveName) != 1)
		duplicate/o $(LoadedWaveName), $(TargetWaveName)
		killwaves $(LoadedWaveName)
	endif

	// Switch to double precision numbers
	redimension/D ImageName;		//CDH: does this really work after the fact?

	// Extract relevent system information from the note string, replace all missing information with the pre-assigned values.
	string wavenote = note(imagename);

	SVAR HeaderString = :Experimental_Info:HeaderString;
	HeaderString = ReplaceString("\n", wavenote, "\r");

	SVAR NewFileName = :Experimental_Info:FileName;
	NewFileName = FileName;
	
	NVAR UpdateDataFromFile = :Experimental_Info:UpdateDataFromFile;

	// This code should be made smarter so only valid notes are extracted.
	// Also the second half of the note contains the whole run-file which should be ignored
		
	if  (UpdateDataFromFile == 1)
		Camera = StringByKey_Safe(Camera, "Camera_ID", wavenote, "=","\n");
		Experiment = StringByKey_Safe(Experiment, "Experiment", wavenote, "=","\n");
		DataType = "" ; DataType = StringByKey_Safe(DataType, "DataType", wavenote, "=","\n");
		ImageType = "" ; ImageType = StringByKey_Safe(ImageType, "ImageType", wavenote, "=","\n");
		magnification = NumberByKey_Safe(magnification,"Magnification",wavenote, "=","\n"); 
		ImageDirection = StringByKey_Safe(ImageDirection, "ImageDirection", wavenote, "=","\n");
		
		strswitch(ImageDirection)
			case "XY":
				SetCamDir("",1,"");
			break;
			case "XZ":
				SetCamDir("",2,"");
			break;
			default:
				SetCamDir("",1,"");
			break;
		endswitch
		
		variable DipRat, DipStart, tEnd, tau, DipPowXi, DipPowZi, DipPowXf, DipPowZf, DipPowXRamp,DipPowZRamp
		strswitch(Experiment)    
			case "Sr":
				//Will need to modify as Sr progresses
				// Most info in the header has spaces around " = "--> be sure to add space after variable name
				IQuad = -8*NumberByKey_Safe(IQuad,"MOTcurrent ",wavenote, "=","\n");
				expand_time = NumberByKey_Safe(expand_time,"TOF ",wavenote, "=","\n")*10^3;
				// Dipole trap end depth defined by exponential ramp shape: A*e^(-tEnd/tau)
				DipPowXi = NumberByKey_Safe(3, "DipPowX ",wavenote,"=","\n");
				DipPowXf = NumberByKey_Safe(3, "DipPowX2 ",wavenote,"=","\n");
				DipPowXRamp = NumberByKey_Safe(3, "DipPowXLat ",wavenote,"=","\n");
				DipPowZi = NumberByKey_Safe(3, "DipPowZ ",wavenote,"=","\n");
				DipPowZf = NumberByKey_Safe(3, "DipPowZ2 ",wavenote,"=","\n");
				DipPowZRamp = NumberByKey_Safe(3, "DipPowZ3 ",wavenote,"=","\n");
				tEnd = NumberByKey_Safe(tEnd,"tEvap1 ",wavenote,"=","\n");
				tau = NumberByKey_Safe(tau,"tau ",wavenote,"=","\n");
				//extract dip power at end of evap for ExpRamp2 evap shape:
				DipolePower = ((DipPowXi-DipPowXf)*exp(-tEnd/tau)+DipPowXf);
				//DipolePower = DipPowXf;
				//DipolePower = DipPowXRamp;
				//DipolePower = 3.5;
				CrDipolePower = DipPowZf;
				//CrDipolePower = DipPowZRamp;
				detuning = (1/31.83)*NumberByKey_Safe(NaN,"ProbeDet ", wavenote, "=","\n"); //Sr linewidth from S. Nagel's thesis
			break;
		
			case "RbYb":
				// Most info in the header has spaces around " = "--> be sure to add space after variable name
				IQuad = -30*NumberByKey_Safe(IQuad,"QuadTrap ",wavenote, "=","\n");
				// switched bias supplies ~Jun 2011 - CDH
				//Ibias = -29.372*NumberByKey_Safe(Ibias,"Bias ",wavenote, "=","\n");
				expand_time = NumberByKey_Safe(expand_time,"TOF ",wavenote, "=","\n")*10^3;
				// Dipole trap end depth defined by exponential ramp shape: A*e^(-tEnd/tau)
				DipStart = NumberByKey_Safe(NaN, "DipStart ",wavenote,"=","\n");
				tEnd = NumberByKey_Safe(tEnd,"tEnd ",wavenote,"=","\n");
				tau = NumberByKey_Safe(tau,"tau ",wavenote,"=","\n");
				DipRat = NumberByKey_Safe(1,"DipRat ",wavenote,"=","\n");
				DipolePower = DipRat*DipStart*exp(-tEnd/tau)/1000;
				detuning = (1/6)*NumberByKey_Safe(NaN,"ProbeDet ", wavenote, "=","\n");
			break;
						
			case "Rubidium_II":
				Ibias = NumberByKey_Safe(Ibias,"I_Bias",wavenote, "=","\n");
				expand_time = NumberByKey_Safe(expand_time,"t_Expand",wavenote, "=","\n");
				detuning = NumberByKey_Safe(detuning,"Detuning",wavenote, "=","\n");
			break;
			
			case "Rubidium_I":
			default:
				Irace = NumberByKey_Safe(Irace,"I_Race",wavenote, "=","\n");
				Ipinch = NumberByKey_Safe(Ipinch,"I_Pinch",wavenote, "=","\n");
				trapmin0 = NumberByKey_Safe(trapmin0,"Trap_Min",wavenote, "=","\n");
				Ibias = NumberByKey_Safe(Ibias,"I_Bias",wavenote, "=","\n");
				expand_time = NumberByKey_Safe(expand_time,"t_Expand",wavenote, "=","\n");
				detuning = NumberByKey_Safe(detuning,"Detuning",wavenote, "=","\n");
			Break;
		endswitch

		// Load the information for Indexedwaves
			
		// If requested, update the autoindexing index from the file
		NVAR autoupdate=:IndexedWaves:autoupdate
		if (autoupdate == 2)
			NVAR index=:IndexedWaves:index;
			index = NumberByKey_Safe(index,"Index",wavenote, "=","\n");
		endif

		String IndexedWavesList = StringByKey("IndexedWaves", wavenote, "=","\n");
		String IndexedValuesList = StringByKey("IndexedValues", wavenote, "=","\n");

		variable Num = ItemsInList(IndexedWavesList);
		if (ItemsInList(IndexedValuesList) != Num)
			print "Load_Img: Items in running waves list does not match the number of values provided";
			SetDataFolder fldrSav;
			return -1;
		endif
		
		String IndexedWaveName;
		variable i;
		for (i = 0; i < Num; i += 1)
			IndexedWaveName = StringFromList(i, IndexedWavesList);
			New_IndexedWave(IndexedWaveName, IndexedWaveName);
			
			NVAR IndexedVariable = $(IndexedWaveName);
			IndexedVariable = str2num( StringFromList(i, IndexedValuesList) );
			
		endfor
	endif
		
	// Convert observed quantaties to physical quantities
	strswitch(ImageType)
		case "Raw": // In this case the loaded file contains three images which need to be split apart and processed.
			// First split into three images
			
			// Then perform initial processing
			
			// Subtract the third frame from the first and second.

			variable xsize;
			variable dark;
			strswitch(Camera)
				case "PIXIS":
					xsize = dimsize(ImageName,0)/3;
					redimension/D/N=(xsize, dimsize(ImageName,1)) Raw1, Raw2, Raw3, Raw4, Isat;	
					redimension/I/N=(xsize, dimsize(ImageName,1)) ROI_mask;	
					Raw1 = ImageName[p][q];
					Raw2 = ImageName[p + xsize][q];
					Raw3 = ImageName[p + 2*xsize][q];

					dark = mean(Raw3);

					Raw1 -= dark;
					Raw2 -= dark;
					Raw3 -= dark;
					RotateImage = 1;
				break;
				Default:
					xsize = dimsize(ImageName,0)/3;
					redimension/D/N=(xsize, dimsize(ImageName,1)) Raw1, Raw2, Raw3, Raw4, Isat;	
					redimension/I/N=(xsize, dimsize(ImageName,1)) ROI_mask;
					Raw1 = ImageName[p][q];
					Raw2 = ImageName[p + xsize][q];
					Raw3 = ImageName[p + 2*xsize][q];

					// IBS : to remove read-out noise, just take the average of the dark
					dark = mean(Raw3);

					Raw1 -= dark;
					Raw2 -= dark;
					Raw3 -= dark;
					RotateImage = 0;
				break;
			endswitch

			if (DualAxis == 1)
				strswitch(ImageDirection)
					case "XY":
						//two axis imaging XY ISatCounts goes here
						ISatCounts = inf;
					break;
					case "XZ":
						//two axis imaging XZ ISatCounts goes here
						ISatCounts = inf;
					break;
					default:
						//default imposes no Isat correction
						ISatCounts = inf;
					break;
				endswitch
			elseif(DualAxis == 0)
				strswitch(ImageDirection)
					case "XY":
						//single axis imaging XY ISatCounts goes here
						ISatCounts = 14650;     //measurement on 6/30/2014 for Sr
						//ISatCounts = inf;
					break;
					case "XZ":
						//single axis imaging XZ ISatCounts goes here
						ISatCounts = 52500;     //measurement on 6/30/2014 for Sr
						//ISatCounts = inf;
					break;
					default:
						//default imposes no Isat correction
						ISatCounts = inf;
					break;
				endswitch
			else
				//no Isat correction for unexpected value of DualAxis
				ISatCounts = inf;
			endif

			if (numtype(detuning) != 0 || numtype(ISatCounts) != 0)
				Isat = 0;
			else
				Isat = ((Raw2-Raw3)/ISatCounts);
			endif
			// MatrixFilter/N=3 gauss Raw1
			// MatrixFilter/N=3 gauss Raw2
			// MatrixFilter/N=32 gauss ISat
			redimension/D/N=(xsize, dimsize(ImageName,1)) ImageName		
					
			// Create the correct data
			strswitch(DataType)
				case "Absorption":
				case "Absorbsion": // Account for historical spelling error...
						ImageName = (Raw1-Raw3)/(Raw2-Raw3);
				break
			
				case "Fluorescence":
						ImageName = Raw1-Raw3;
				break

				case "PhaseContrast":
						ImageName = Raw1/Raw2;
				break

				case "RawImage":
						ImageName = Raw1;
				break
			
				default:
						ImageName = Raw1/Raw2;
				break
			endswitch
		break;
		
		default:	// Data is pre-processed (difference for fluresence, ratio for absorption)
				Duplicate/O ImageName, ISat;
				Isat = 0;
		break;
	endswitch


	// Try to discover what camera this is from and set the scaling suitably.  This is based only on
	// the magnification paramater and the physical pixel size in microns / pixel
	Update_Magnification();	
	ComputeTrapProperties();
	
	SetScale/P x dimoffset(ImageName,0),Dimdelta(ImageName,0),"", Raw1;
	SetScale/P y dimoffset(ImageName,1),Dimdelta(ImageName,1),"", Raw1;
	SetScale/P x dimoffset(ImageName,0),Dimdelta(ImageName,0),"", Raw2;
	SetScale/P y dimoffset(ImageName,1),Dimdelta(ImageName,1),"", Raw2;
	SetScale/P x dimoffset(ImageName,0),Dimdelta(ImageName,0),"", Raw3;
	SetScale/P y dimoffset(ImageName,1),Dimdelta(ImageName,1),"", Raw3;
	SetScale/P x dimoffset(ImageName,0),Dimdelta(ImageName,0),"", Raw4;
	SetScale/P y dimoffset(ImageName,1),Dimdelta(ImageName,1),"", Raw4;
	SetScale/P x dimoffset(ImageName,0),Dimdelta(ImageName,0),"", ISat;
	SetScale/P y dimoffset(ImageName,1),Dimdelta(ImageName,1),"", ISat;
	SetScale/P x dimoffset(ImageName,0),Dimdelta(ImageName,0),"", ROI_mask;
	SetScale/P y dimoffset(ImageName,1),Dimdelta(ImageName,1),"", ROI_mask;
	
	strswitch(DataType)
			case "Absorption":
			case "Absorbsion": // Account for spelling error.
				
				//Use or make the orthonormal basis
				If(Analysis_Type == 2)
				
					string fldrTemp = GetDataFolder(1);
					string ProjectID = ParseFilePath(0, fldrTemp, ":", 1, 0);					
					string BasisPath = "root:Packages:OrthoBasis:" + ProjectID;
					If(exists(BasisPath + ":BasisStack") == 0)
						//Push probe image onto the stack.
						Raw4 = (Raw2-Raw3);
						Add_ProbeImage(FileName, Raw4);
					elseif(exists(BasisPath + ":BasisStack") == 1)
						//Project image onto the basis.
						
						//Check that the ROI matches the Basis
						wave/I BasisROI = $(BasisPath + ":BasisROI");
						MatrixOP/FREE/O EqBasis = sum(Abs((BasisROI - ROI_mask)));
						
						If(EqBasis == 0)
							//Since the ROIs match, we can project onto the basis.
							wave BasisStack = $(BasisPath + ":BasisStack");
							
							//Mask out the atom region
							Duplicate/O/D/FREE Raw1, Raw1_mask;
							Raw1_mask -= Raw3;    //Remove the dark counts;
							Raw1_mask *= BasisROI;
							
							//Prepare waves to store dot products and the reconstructed probe image
							Redimension/D/N=(Dimsize(BasisStack, 2)) PrAlpha;
							Raw4 = 0;
							
							//loop over the basis
							variable k;
							For(k = 0; k < Dimsize(BasisStack, 2); k += 1)
							
								//compute the dot product
								MatrixOP/FREE/O AlphaTemp = ((Raw1_mask[][][0]).(BasisStack[][][k]));
								//store dot products
								PrAlpha[k] = AlphaTemp[0];
								//create probe image
								Raw4[][] = Raw4[p][q] + PrAlpha[k]*BasisStack[p][q][k];
								
							endfor
							
							//remake ImageName and Isat using the new probe image
							ImageName = (Raw1-Raw3)/Raw4;
							Isat = Raw4/ISatCounts;
							
						else
							
							print "FileIO: Basis ROI does not match image ROI, remake the basis";	
							
						endif
					else
					
						print "FileIO: Basis has unexpected data type";	
					
					endif
				endif
				
				// ImageName = -ln(ImageName) - Isat * (ImageName-1);
				ImageName = -(ln(ImageName))*(1+Isat);
	
				// remove any non-numbers from the data
				ImageName=(ImageName > -1 ? ImageName : -1);	//This will remove the Nan's
				ImageName=(ImageName !=inf ? ImageName : 5);
				ImageName=(ImageName !=-inf ? ImageName : -1); 
				ImageName=(ImageName !=nan ? ImageName : 5);
				
			break
			
			case "Fluorescence":
				ImageName = ImageName;
				//for Isat calibration:
				MatrixOP/O IsatCtsWave = sum(ImageName);
			break

			case "PhaseContrast":
				ImageName = ImageName;
			break

			case "RawImage":
				ImageName = ImageName;
			break
			
			default:
				ImageName = ImageName;
			break
	endswitch

	
	if (RotateImage)
		NVAR RotAng = :Experimental_Info:RotAng;
		RotAng = 54;
		ImageRotate/Q/O/E=0/A=(RotAng) ImageName;
		Update_Magnification();			// CDH: why is this here??	
	endif
	
	SetDataFolder fldrSav;
end 
// ************************************** Load_Img**************************************************

//************************************ LoadScope **************************************************
// This function loads in the scope traces that have been saved to a file 
// by labview.
// Old data apprently had atranspose in it.


Function Load_Scope(FileName,Old)
	String FileName
	variable Old
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	String LoadedWaveName, TargetWaveName;
	String basename,savename, pathname,fullpathname;

	NVAR getscope = :Experimental_Info:getscope

	variable n;

	if(getscope)

		// FileName should include the full path to the file i.e., 
		// "D:\Experiment\Data Acquisition\PFabsimg.ibw"

		try
			LoadWave/Q/O FileName; AbortOnRTE;
		catch
			print "Error (Load_Scope: LoadWave): ", GetRTErrMessage(), "Num: ", GetRTError(1);
			Abort;
		endtry

		LoadedWaveName =  StringFromList(0,S_waveNames);
		duplicate/O $(LoadedWaveName) TempWave 
		

		// Now extract the col's of the wave
		if (Old == 0)
			n=dimsize($LoadedWaveName,0)
		else
			n=dimsize($LoadedWaveName,1)
		endif
		
		make/O/n=(n) :Experimental_Info:scopechan1
		make/O/n=(n) :Experimental_Info:scopechan2
		make/O/n=(n) :Experimental_Info:scopechan3
		make/O/n=(n) :Experimental_Info:scopechan4

		wave scopechan1=:Experimental_Info:scopechan1
		wave scopechan2=:Experimental_Info:scopechan2
		wave scopechan3=:Experimental_Info:scopechan3
		wave scopechan4=:Experimental_Info:scopechan4
		
		if (Old == 0)
			scopechan1 = TempWave[p][1];
			scopechan2 = TempWave[p][2];
			scopechan3 = TempWave[p][3];
			scopechan4 = TempWave[p][4];
		else
			scopechan1 = TempWave[0][p];
			scopechan2 = TempWave[1][p];
			scopechan3 = TempWave[2][p];
			scopechan4 = TempWave[3][p];
		endif
		
		// killwaves TempWave
	endif	
	
	SetDataFolder fldrSav;
end 

//*********************************  LoadScope  ***********************************


// ******************************** StringByKey_Safe ***********************************
// This is a save version of the StringByKey command which leaves the old data (DefaultString) unchanged
// if the key is not found

function/T StringByKey_Safe(DefaultString, keyStr, kwListStr, keySepStr, listSepStr)
	String DefaultString;
	String keyStr;
	String kwListStr;
	String keySepStr;
	String listSepStr;

	String Result = StringByKey(keyStr, kwListStr, keySepStr,listSepStr);
		
	if (strlen(Result) == 0)
		return DefaultString;
	endif
	
	return Result;
end

// ******************************** NumberByKey_Safe ***********************************
// This is a save version of the StringByKey command which leaves the old data (DefaultString) unchanged
// if the key is not found

function NumberByKey_Safe(DefaultNumber, keyStr, kwListStr, keySepStr, listSepStr)
	variable DefaultNumber;
	String keyStr;
	String kwListStr;
	String keySepStr;
	String listSepStr;

	variable Result = NumberByKey(keyStr, kwListStr, keySepStr,listSepStr);
	
	if (numtype(Result) == 2) // check if result is NaN (fixed by CDH, 29Sep2011)
		//print "NumberByKey_Safe got a NaN looking for "+keyStr+"."
		return DefaultNumber;
	endif
	
	return Result;
end

// ******************************** MakeDataPanel ***********************************
// Loads a set of data from file and makes a nice panel of the data for printing
//


Function MakeDataPanel(ProjectID, FileName, InitialIndex, FinalIndex)
	string ProjectID, FileName
	variable InitialIndex, FinalIndex
	
	if (FinalIndex < InitialIndex)
		printf "Error: InitialIndex must be smaller than FinalIndex";
		return 0;
	endif

	string FinalName;
	variable i;

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	ResetIndex("");
	
	// ******************************
	// Initilize user specified waves
	// ******************************
	
	string FigureName, WindowName = "";

	Wave optdepth = :optdepth

	NewLayout
	for(i = 0;i <= FinalIndex-InitialIndex;i = i + 1)
		sprintf FinalName, "%s%04d", FileName, i + InitialIndex
		sprintf FigureName, "%s%04d", "TempImage", i
		AutoRunV3(ProjectID, FinalName)
		DoUpdate;

		duplicate/O optdepth $(FigureName)
		Display;AppendImage $(FigureName)
		FormatGraph(1, 1, 0);
		ModifyGraph manTick(bottom)={0,300,0,0},manMinor(bottom)={0,0};
		SetAxis left -500,500;
		SetAxis bottom -500,500 
		ModifyGraph margin(right)=72,width={Aspect,1},height=75
		ModifyImage $(FigureName) ctab= {-0.025,0.25,Grays,0}

		sprintf WindowName, "\\Z07File\\n%s", FinalName;
		TextBox/C/N=text0/A=MC/X=75.00/Y=45.00 WindowName
		
		
		WindowName = WinName(0,1);
		AppendLayoutObject/T=1/F=0 graph $(WindowName);
	endfor

	// Build the panel
	Execute "Tile/A=(7,4)"


	SetDataFolder fldrSav	
	
	return 0;
end


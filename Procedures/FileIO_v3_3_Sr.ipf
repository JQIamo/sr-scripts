#pragma rtGlobals=1		// Use modern global access method.

//! @file
//! @brief This file contains various functions required for loading image data
//! for the Rubidium experiments.

constant OldStyleImage = 1 //!< 0 or 1, sets scope transpose or not. (see ::LoadScope)

// ********************************************************
// FileNameArray(FileArray, FileName, InitialIndex, FinalIndex)
//!
//! @brief Constructs a list of file names to process
//! @details This function allows for batch processing of many files
//! and constructs a list of file names to process
//! FileNameList, InitialIndex, and FinalIndex are all lists of the form:
//!
//! @param[in] FileNameList  ';'-delimited list of file name roots, \em e.g. "Macintosh HD:data:PF_02Mar2005_;Macintosh HD:data:PF_03Mar2005_; "
//! @param[in] InitialIndex  ';'-delimited list of starting file indices \em e.g. "23;43"
//! @param[in] FinalIndex    ';'-delimited list of ending file indices \em e.g. "42;55"
//! @return The list of files with a ';'-delimination between paths.
//! @return Empty string if error.
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
	
//!
//! @brief A stub so older procedures will compile
Function AutoRun(Mode, ProjectID, FinalName)
	variable Mode
	String ProjectID, FinalName
End

// AutoRunV3(ProjectID, FileName)

//!
//! @brief this function is called by one of the camera software when an image is ready
//! @details Version three extracts more information from the file header and 
//! and relies less on user provided data (unless needed).
//!
//! Loads both the image file and any associated scope traces, as well as calling
//! analysis functions.
//!
//! @note Manually comment/uncomment New_ColdAtomInfo for the appropriate experiment
//!
//! @param[in] ProjectID  Name for the data folder to save this under
//! @param[in] FileName   Path to the file to analyze
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

//AutoRunV4 handles camera imaging

//!
//! @brief Handles two simultaneous imaging directions
//! @details Calls ::AutoRunV3 for each of two image files
//!
//! @param[in] ProjectID1, ProjectID2  Name for the data folder to save for this camera
//! @param[in] FileName1, FileName2    Path for image file for this camera
Function AutoRunV4(ProjectID1, FileName1, ProjectID2, FileName2)
	
	String ProjectID1, FileName1, ProjectID2, FileName2
	
	AutoRunV3(ProjectID1, FileName1)
	AutoRunV3(ProjectID2, FileName2)
	
end

// **************************************************************************************************
//!
//! @brief Loads an IGOR binary file saved by LabView containing one image and header information.
//! @details In the past there were several functions which loaded files for each different camera,
//! this has been condensed into this single routine which suffices
//!
//! Pulls information from the wave header of the on-disk image, 
//!
//! @param[out] ImageName  Destination wave for the loaded image
//! @param[in]  FileName   Path to the file to load
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
	NVAR alphaIsat = :Experimental_Info:alphaISat;
	NVAR alphaIsatCal = :Experimental_Info:alphaISatCal;
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
	NVAR isotope = :Experimental_Info:SrIsotope;
	NVAR x_pixels = :Experimental_Info:x_pixels;
	NVAR y_pixels = :Experimental_Info:y_pixels;
	
	NVAR ProbePow = :ProbePow

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
		
		variable DipRat, DipStart, tEnd, tau, DipPowXi, DipPowZi, DipPowXf, DipPowZf, DipPowXRamp,DipPowZRamp,WMfreq
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
				WMfreq = NumberByKey_Safe(0, "WMfreq",wavenote,"=","\n");
				//printf "frequency: %15.12g\r", WMfreq
				detuning = (1/31.99)*NumberByKey_Safe(NaN,"ProbeDet ", wavenote, "=","\n"); //Sr linewidth from NIST spectral database
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
			
			
			strswitch(IndexedWaveName)
				//this is a hack which allows us to turn off acquisition of the WM frequency
				case "WMfreq":
					//printf "frequency: %15.12g\r", WMfreq
					IndexedVariable = WMfreq
					//printf "saved frequency: %15.12g\r", IndexedVariable
				break;
				default:
					IndexedVariable = str2num( StringFromList(i, IndexedValuesList) );
				break;
			endswitch
			
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
			
			//Look at image size now that they have been loaded
			x_pixels = dimsize(Raw1,0)
			y_pixels = dimsize(Raw1,1)
			
			if (stringmatch(Camera,"FL3_32S2M") && stringmatch(ImageDirection,"XY"))
				RotateImage=1
			elseif (stringmatch(Camera,"GS3_28S4M") && stringmatch(ImageDirection,"XZ"))
				RotateImage=1
			endif
			
			if (DualAxis == 1)
				strswitch(ImageDirection)
					case "XY":
						//two axis imaging XY ISatCounts goes here
						ISatCounts = inf;
						alphaIsat = 1;
					break;
					case "XZ":
						//two axis imaging XZ ISatCounts goes here
						ISatCounts = inf;
						alphaIsat = 1;
					break;
					default:
						//default imposes no Isat correction
						ISatCounts = inf;
						alphaIsat = 1;
					break;
				endswitch
			elseif(DualAxis == 0)
				strswitch(ImageDirection)
					case "XY":
						//single axis imaging XY ISatCounts goes here
						
						strswitch(Camera)
							case "PIXIS":
								if (x_pixels == 512)
									//PIXIS is binning pixels
									//ISatCounts = 14650;     //measurement on 6/30/2014 for Sr
									//ISatCounts = 12851;     //measurement on 12/11/2015 for Sr for 2x2 bin, 10 us
									ISatCounts = 10669.1 //measurement on 10/18/2016, binning PIXIS, 10 us exposure
									
									If(isotope==3)	//case Sr87
										alphaIsat = 1.81 //!uncalibrated for pixel binning, using value from unbinned
									else
										alphaIsat = 1.28 //!uncalibrated for pixel binning, using value from unbinned
									endif
								else
									//PIXIS is not binning pixels
									
									//ISatCounts = 4050.06;    //measurement on 10/18/2016, no binning on PIXIS, 10 us
									ISatCounts = 4400; //measurement 10/28/2016, no binning on PIXIS, 10 us, need to adjust this if I change exposureT!
									
									//Variable expTime = 10*1550 / (58515-36805*ProbePow + 5891*ProbePow^2) //exp time used on 11/1/16
									//Variable expTime = 10*1550 / (64233-41103*ProbePow + 6702*ProbePow^2) //exp time used on 11/1/16
									//ISatCounts = 440 * expTime
									
									If(isotope==3)	//case Sr87
										alphaIsat = 1.81 //see lab notebook, 2016.11.07
									else
										alphaIsat = 1.28 //see lab notebook, 2016.11.07
									endif								
									
								endif
								break
							endswitch
										
						
					break;
					case "XZ":
						strswitch(Camera)
							case "GS3_28S4M": //Grasshopper imaging
								//ISatCounts = 1233; //measurement 12/12/16 on grasshopper,
								//alphaIsat = 1.02 //measurement 12/12/16 on grasshopper,
								ISatCounts = 895; //measurement 5/23/17, with correction
								RotateImage = 1; //rotation of a couple degrees needed to level image to gravity (5/23/17)
								if (isotope == 3)		//case Sr87
									alphaIsat = 1; //uncalibrated
								else
									alphaIsat = 1;
								endif
							break;
							default:  //single axis imaging XZ
								ISatCounts = 9999999; 
								alphaIsat = 1; //uncalibrated
							break;
						endswitch;
					break;
					default:
						//default imposes no Isat correction
						ISatCounts = inf;
						alphaIsat = 1
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

	//Make a byte wave version of ROI mask to facilitate average Isat correction and histogramming
	Make/B/U/FREE/N=(DimSize(ROI_mask,0),DimSize(ROI_mask,1)) ROI_mask_byte;
	ROI_mask_byte=ROI_mask;
	
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
	SetScale/P x dimoffset(ImageName,0),Dimdelta(ImageName,0),"", ROI_mask_byte;
	SetScale/P y dimoffset(ImageName,1),Dimdelta(ImageName,1),"", ROI_mask_byte;
	
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
				// See AMO notes from Gretchen (lectures 26 and 27) and Barker NB 3 p. 51 on why this is valid:
				If(isotope==3)	//case Sr87
					//If there is an error, the data for Sr87sigma can be found with Englebert in the AeroFS/Sr87 Correction Tables
					//use the generic load waves dialog to import
					SetDataFolder "root:Packages:Sr87CrossSect";
					
					strswitch(ImageDirection)
					case "XY":
						//The vertical imaging axis uses a circularly polarized probe beam.
						Wave sigma87 = :Sr87sigmaCircular;
						Wave highS = :Sr87sigmaCircular_highS;
						Wave lowS = :Sr87sigmaCircular_lowS;
					break;
					case "XZ":
						//The horizontal imaging axis uses a linearly polarized probe beam.
						Wave sigma87 = :Sr87sigmaLinear;
						Wave highS = :Sr87sigmaLinear_highS;
						Wave lowS = :Sr87sigmaLinear_lowS;
					break;
					default:
						//default to linear polarization
						Wave sigma87 = :Sr87sigmaLinear;
						Wave highS = :Sr87sigmaLinear_highS;
						Wave lowS = :Sr87sigmaLinear_lowS;
					break;
				endswitch
					
					//always need the detunings, which do not depend on image direction
					Wave Dets = :Detunings;
					SetDataFolder ProjectFolder;
					
					//If you had to reload the 87sigma wave, you MUST uncomment the following two lines
					//the first time a new image is loaded so that the interpolation works properly.
					//I'm just going to leave them uncommented to be safe. DSB - 2016
					SetScale/P x, -64, 1, sigma87
					SetScale/P y, .001, .01, sigma87
					variable temp = 31.99*detuning
					//keep an eye out for NaNs in the Isat image since that indicates that there are problems with the Sr87 sigma lookup tables.
					//The new lookup tables should not have a NaN problem, but...
					Isat = (Isat[p][q] > .001 ? (Isat[p][q] < 5.001 ? interp2d(sigma87, temp, Isat[p][q]) : interp(temp,Dets,highS)) : interp(temp,Dets,lowS));
					//Isat is now a local, relative (to peak bosonic Sr absorption), absorption cross-section and not the local saturation parameter
					//Get the average correction:
					ImageStats/R=ROI_mask_byte Isat
					//Print V_avg
					//ImageHistogram/R=ROI_mask_byte Isat
					
					//Pixel by Pixel correction:
					//ImageName = -(ln(ImageName))/Isat
					//Average correction:
					//ImageName = -(ln(ImageName))/V_avg
					
					//new method
					if (alphaIsatCal == 1) //check if we are calibrating the alphaIsat variable
						NVAR alpha = :alphaIsat  //if yes, set alphaIsat to be the same as the indexed wave called alphaIsat
						alphaIsat = alpha;
					endif
					ImageName = -alphaIsat*ln(ImageName)*(1+4*detuning^2) + (Raw2 - Raw1) / IsatCounts 
					
				elseif((isotope==1)||(isotope==2)||(isotope==4))	//case Sr88, Sr86, Sr84
					
					//ImageName = -(ln(ImageName))*(1+4*detuning^2+Isat); //original method
					
					//new method
					if (alphaIsatCal == 1) //check if we are calibrating the alphaIsat variable
						NVAR alpha = :alphaIsat  //if yes, set alphaIsat to be the same as the indexed wave called alphaIsat
						alphaIsat = alpha;
					endif
					
					ImageName = -alphaIsat*ln(ImageName)*(1+4*detuning^2) + (Raw2 - Raw1) / IsatCounts 
					//ImageName = -ln(ImageName)*(1+4*detuning^2) + (Raw2 - Raw1) / (alphaIsat*IsatCounts)
					
				else		//case unknown isotope
				
					//ImageName = -(ln(ImageName))*(1+4*detuning^2+Isat);
					if (alphaIsatCal == 1) //check if we are calibrating the alphaIsat variable
						NVAR alpha = :alphaIsat  //if yes, set alphaIsat to be the same as the indexed wave called alphaIsat
						alphaIsat = alpha;
					endif
					ImageName = -alphaIsat*ln(ImageName)*(1+4*detuning^2) + (Raw2 - Raw1) / IsatCounts 
					
				endif
	
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
		strswitch(Camera)
			case "GS3_28S4M": //Grasshopper imaging
				//RotAng = 0;
				RotAng = 1.96; //rotation angle to align GH with gravity, measured 5/23/17
			break;
			
			case "PIXIS": //PIXIS imaging
				//RotAng = 22;
				//RotAng = 26.67;	//check by minimizing crosscorrelation term in 2D thermal fit on PIXIS (20)
				RotAng = 53.2; //rotation angle to level the main dipole beam
				//RotAng = 6.7 //rotation angle to approximately level cross beam
				//RotAng = 7.43;	// rotation angle to level box on pixis
				//RotAng = 6.967 // rotation angle to level horizontal lattice on PIXIS
				//RotAng =7;	// rotation angle to level box on vert flea
			break;
		endswitch
	
		ImageRotate/Q/O/E=0/A=(RotAng) ImageName;
		Update_Magnification();			// CDH: why is this here??	
	endif
	
	SetDataFolder fldrSav;
end 
// ************************************** Load_Img**************************************************

// ************************************ LoadScope **************************************************
//!
//! @brief This function loads in the scope traces that have been saved to a file by LabView.
//! @details Old data apparently had a transpose in it.
//!
//! @param[in] FileName  The full path to the file containing scope data 
//! @param[in] Old       \b 0 if transpose required (old data)
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
//!
//! @brief This is a save version of the StringByKey command which leaves the old data
//! (DefaultString) unchanged if the key is not found
//! @details
//! 
//! @param[in]  DefaultString  The default return value, used if the key isn't found
//! @param[in]  keyStr         The key to search for in kwListStr
//! @param[in]  kwListStr      String of key-value pairs to be searched
//! @param[in]  keySepStr      Separator between keys and values in \p kwListStr
//! @param[in]  listSepStr     Separator between key-value pairs in \p kwListStr
//! @return Value associated with requested key, or DefaultString if not found.
function/S StringByKey_Safe(DefaultString, keyStr, kwListStr, keySepStr, listSepStr)
	String DefaultString
	String keyStr
	String kwListStr
	String keySepStr
	String listSepStr

	String Result = StringByKey(keyStr, kwListStr, keySepStr,listSepStr);
		
	if (strlen(Result) == 0)
		return DefaultString;
	endif
	
	return Result;
end

// ******************************** NumberByKey_Safe ***********************************
//!
//! @brief This is a save version of the NumberByKey command which leaves the old data 
//! (DefaultNumber) unchanged if the key is not found
//! @details
//! 
//! @param[in]  DefaultNumber  The default return value, used if the key isn't found
//! @param[in]  keyStr         The key to search for in kwListStr
//! @param[in]  kwListStr      String of key-value pairs to be searched
//! @param[in]  keySepStr      Separator between keys and values in \p kwListStr
//! @param[in]  listSepStr     Separator between key-value pairs in \p kwListStr
//! @return Value associated with requested key, or DefaultString if not found.
function NumberByKey_Safe(DefaultNumber, keyStr, kwListStr, keySepStr, listSepStr)
	variable DefaultNumber
	String keyStr
	String kwListStr
	String keySepStr
	String listSepStr

	variable Result = NumberByKey(keyStr, kwListStr, keySepStr,listSepStr);
	
	if (numtype(Result) == 2) // check if result is NaN (fixed by CDH, 29Sep2011)
		//print "NumberByKey_Safe got a NaN looking for "+keyStr+"."
		return DefaultNumber;
	endif
	
	return Result;
end

// ******************************** MakeDataPanel ***********************************
//!
//! @brief Loads a set of data from file and makes a nice panel of the data for printing
//! @details Specifically, it appears to build a layout of absorption images.
//! 
//! @param[in] ProjectID     Data folder to load into when calling ::AutoRunV3
//! @param[in] FileName      Root file path to load for images
//! @param[in] InitialIndex  First index to load
//! @param[in] FinalIndex    Last index to load
//! @return \b 0, always
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


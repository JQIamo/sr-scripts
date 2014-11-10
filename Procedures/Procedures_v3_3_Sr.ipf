#pragma rtGlobals=2	// Use modern global access method and no compatability mode

// This series of functions loads and processes Absorption imagas
// It was modified from previous code on 13Sep04 to load igor binary
// data instead of the earlier loading of raw text.

// ********************************************************
// OUTSTANDING ISSUES:
//
// Checkboxes can have variables associated with them.  It might be a good idea to use that instead of
// calling functions if all the function does is update the variable.
//

// physical parameters for Sr-88, Sr-87, Sr-86.
Constant lambda=0.460862  		//wavelength (um)
//Constant a_scatt = -74.06e-6; 		// 88-88 scattering length from arXiv:0808.3434 (um)
//Constant a_scatt = 5.089e-3; 		// 87-87 scattering length from arXiv:0808.3434 (um)
//Constant a_scatt = 43.619e-3; 		// 86-86 scattering length from arXiv:0808.3434 (um)
//Constant a_scatt = 6.5031e-3;		// 84-84 scattering length from arXiv:0808.3434 (um)
//Constant mass=1.459708142e-25;	//Sr-88 mass (kg)
//Constant mass=1.443156956e-25;  //Sr-87 mass (kg)
//Constant mass=1.42655671e-25;  //Sr-86 mass (kg)
//Constant mass=1.39341508e-25;	//Sr-84 mass (kg)
Constant hbar = 1.05457148e-34	// Hbar! (Js)
Constant kB = 1.38065e-23 		// Boltzman's constant (J/K)
Constant muB = 9.274009e-24 		// Bohr magneton (J/T)
//Constant Er =  3498.98; 			// Recoil energy at the specified wavelength in Hz at 810 nm
//Constant satpar=.25; 				// saturation parameter from light intensity


// ******* AbsImg_AnalyzeImage ****************************************************************************************
// This program analyzes an image either in the XY or XZ direction depending on the panel selection
//  It takes as input
// 	- inputimage  -> the image. It has been pre-processed to divide out the reference signal.
//	
Function AbsImg_AnalyzeImage(inputimage)
	Wave inputimage

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Discover the name of the current image window
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";

	NVAR ymax=:fit_info:ymax, ymin=:fit_info:ymin
	NVAR xmax=:fit_info:xmax, xmin=:fit_info:xmin
	NVAR findmax=:Fit_Info:findmax ,fit_type=:Fit_Info:fit_type
	NVAR camdir=:Experimental_Info:camdir, traptype=:Experimental_Info:traptype
	SVAR DataType=:Experimental_Info:DataType
	NVAR centersFixed=:Fit_Info:CentersFixed		// boolean from checkbox on panel to decide bimodal fit type.

	Wave W_coef=:Fit_Info:W_coef
	
	make/O/N=7 :Fit_Info:Gauss3d_coef
	Wave Gauss3d_coef=:Fit_Info:Gauss3d_coef;
	
	Wave TF_ver_coef=:Fit_Info:TF_ver_coef,TF_hor_coef=:Fit_Info:TF_hor_coef
	Wave TF_2D_coef=:Fit_Info:TF_2D_coef
	Wave optdepth=:optdepth
	Variable row
	
	variable pmax = (xmax - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable pmin = (xmin - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable qmax = (ymax - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	variable qmin = (ymin - DimOffset(inputimage, 1))/DimDelta(inputimage,1);

	// Be sure that the desired image is on the active panel display, and that all of the cursors exist;
	UpdatePanelImage(NameOfWave(optdepth));
	
	// Make sure polylog lookup tables are loaded
	// CheckPolylog()
	
	// If asked, find the maximum absorption point and put cursor E at the max
	// Otherwise use the cursors on the graph
	// The cursors are : 	A,B: red bounding box (ROI)
	//						C,D: pink bounding box (background)
	//						E: black crosshair (initial fit center mark).
	//						F: yellow/green square (fitted center, displayed slices point)
	
	If (fit_Type < 7)
		switch(findmax)
			case 1:	// Max value in the ROI
				ImageStats /M=1 /GS={(xmin),(xmax),(ymin),(ymax)} optdepth  // output globals: V_min, V_minColLoc, V_minRowLoc, (similar for max)
				Cursor /I/P/W=$(ImageWindowName)  E, optdepth, V_maxRowLoc,V_maxColLoc;
				break;
			case 2:	// From the cursor (move cursor to follow located max)
				break;
			case 3:	// From the cursor (but don't move it)
				break
			default:
				print "Error: AbsImg_AnalyzeImage: Invalid case (findmax)";
				break;	
		endswitch
	Endif
	
	// Fit types:
	
	switch(fit_type)
		case 1:	// Thermal 1D
			SimpleThermalFit1D(optdepth,"E"); 	 // do a simple thermal fit (gaussian) based on cursor E.
			UpdateCursor(Gauss3d_coef, "F");	 // put cursor F on fit center
			SimpleThermalFit1D(optdepth,"F") 	 // do a simple thermal fit (gaussian) based on cursor F.
			GetCounts(optdepth)	
			
			ThermalUpdateCloudPars(Gauss3D_Coef) // use cursor F to adjust the on-center amplitude
		break
			
		case 2:	// Thermal 1D and TF
			if(traptype == 1)
				Beep; DoAlert 0, "You cannot get a BEC in just the quad. Choose a Thermal 1D or 2D fit."
				return 0;
			endif
	
			SimpleThermalFit1D(optdepth,"E");  // do a simple thermal fit (gaussian) based on cursor E.
			UpdateCursor(Gauss3d_coef, "F");	 // put cursor F on fit center

			if (centersFixed)
				ThomasFermiFit1D(optdepth,"F",ImageWindowName, fit_type)			// fit with constrained centers
			else
			//	print "free fit"
				ThomasFermiFit1D_free(optdepth,"F",ImageWindowName, fit_type)		// fit with independent centers
			endif
			GetCounts(optdepth)
			
			ThermalUpdateCloudPars(Gauss3D_Coef) // update parameters AFTER bimodal fit!
			TFUpdateCloudPars(Gauss3d_coef, fit_type)
		break
			
		case 3:	// TF only
			if(traptype == 1)
				Beep; DoAlert 0, "You cannot get a BEC in just the quad. Choose a Thermal 1D or 2D fit."
				return 0;
			endif
			SimpleThermalFit1D(optdepth,"E");  	// do a simple thermal fit (gaussian) based on cursor E.
			UpdateCursor(Gauss3d_coef, "F");	// put cursor F on fit center
			ThomasFermiFit1D(optdepth,"F",ImageWindowName, fit_type)
			GetCounts(optdepth)

			TFUpdateCloudPars(Gauss3d_coef, fit_type)
		break
			
		case 4:	// TF + Thermal 2D
			if(traptype == 1)
				Beep; DoAlert 0, "You cannot get a BEC in just the quad. Choose a Thermal 1D or 2D fit."
				return 0;
			endif
			
			ThomasFermiFit2D(optdepth, fit_type)
			UpdateCursor(Gauss3d_coef, "F");	 // put cursor F on fit center
			GetCounts(optdepth)
			Wave fit_xsec_col = :Fit_Info:fit_xsec_col, fit_xsec_row=:Fit_Info:fit_xsec_row, fit_optdepth=:Fit_Info:fit_optdepth
			Wave res_xsec_col = :Fit_Info:res_xsec_col, res_xsec_row=:Fit_Info:res_xsec_row, res_optdepth=:Fit_Info:res_optdepth
			fit_xsec_col = ((p > qmin) && (p < qmax) ? fit_optdepth[pcsr(F,ImageWindowName)][p] : 0);
			fit_xsec_row = ((p > pmin) && (p < pmax) ? fit_optdepth[p][qcsr(F,ImageWindowName)] : 0);
			res_xsec_col = ((p > qmin) && (p < qmax) ? res_optdepth[pcsr(F,ImageWindowName)][p] : 0);
			res_xsec_row = ((p > pmin) && (p < pmax) ? res_optdepth[p][qcsr(F,ImageWindowName)] : 0);
			ThermalUpdateCloudPars(Gauss3D_Coef) // use cursor F to adjust the on-center amplitude
			TFUpdateCloudPars(Gauss3d_coef, fit_type)
		break
			
		case 5:	// TF only 2D
			if(traptype == 1)
				Beep; DoAlert 0, "You cannot get a BEC in just the quad. Choose a Thermal 1D or 2D fit."
				return 0;
			endif

			ThomasFermiFit2D(optdepth, fit_type)
			UpdateCursor(Gauss3d_coef, "F");	 // put cursor F on fit center
			GetCounts(optdepth)
			Wave fit_xsec_col = :Fit_Info:fit_xsec_col, fit_xsec_row=:Fit_Info:fit_xsec_row, fit_optdepth=:Fit_Info:fit_optdepth
			Wave res_xsec_col = :Fit_Info:res_xsec_col, res_xsec_row=:Fit_Info:res_xsec_row, res_optdepth=:Fit_Info:res_optdepth
			fit_xsec_col = ((p > qmin) && (p < qmax) ? fit_optdepth[pcsr(F,ImageWindowName)][p] : 0);
			fit_xsec_row = ((p > pmin) && (p < pmax) ? fit_optdepth[p][qcsr(F,ImageWindowName)] : 0);
			res_xsec_col = ((p > qmin) && (p < qmax) ? res_optdepth[pcsr(F,ImageWindowName)][p] : 0);
			res_xsec_row = ((p > pmin) && (p < pmax) ? res_optdepth[p][qcsr(F,ImageWindowName)] : 0);
			
			TFUpdateCloudPars(Gauss3d_coef, fit_type)
		break
			
		case 6:	// Thermal 2D
			SimpleThermalFit2D(optdepth);  // do a simple thermal fit (gaussian) with autoguessing
			GetCounts(optdepth)
			UpdateCursor(Gauss3d_coef, "F");	 // put cursor F on fit center
			Wave fit_xsec_col = :Fit_Info:fit_xsec_col, fit_xsec_row=:Fit_Info:fit_xsec_row, fit_optdepth=:Fit_Info:fit_optdepth
			Wave res_xsec_col = :Fit_Info:res_xsec_col, res_xsec_row=:Fit_Info:res_xsec_row, res_optdepth=:Fit_Info:res_optdepth
			fit_xsec_col = ((p > qmin) && (p < qmax) ? fit_optdepth[pcsr(F,ImageWindowName)][p] : 0);
			fit_xsec_row = ((p > pmin) && (p < pmax) ? fit_optdepth[p][qcsr(F,ImageWindowName)] : 0);
			res_xsec_col = ((p > qmin) && (p < qmax) ? res_optdepth[pcsr(F,ImageWindowName)][p] : 0);
			res_xsec_row = ((p > pmin) && (p < pmax) ? res_optdepth[p][qcsr(F,ImageWindowName)] : 0);
			ThermalUpdateCloudPars(Gauss3D_Coef) // use cursor F to adjust the on-center amplitude
		break
		
		case 7:	// TriGauss 2D
			TriGaussFit2D(optdepth);  // do a TriGauss fit with autoguessing
			GetCounts(optdepth)
			UpdateCursor(Gauss3d_coef, "F");	 // put cursor F on fit center
			Wave fit_xsec_col = :Fit_Info:fit_xsec_col, fit_xsec_row=:Fit_Info:fit_xsec_row, fit_optdepth=:Fit_Info:fit_optdepth
			Wave res_xsec_col = :Fit_Info:res_xsec_col, res_xsec_row=:Fit_Info:res_xsec_row, res_optdepth=:Fit_Info:res_optdepth
			fit_xsec_col = ((p > qmin) && (p < qmax) ? fit_optdepth[pcsr(F,ImageWindowName)][p] : 0);
			fit_xsec_row = ((p > pmin) && (p < pmax) ? fit_optdepth[p][qcsr(F,ImageWindowName)] : 0);
			res_xsec_col = ((p > qmin) && (p < qmax) ? res_optdepth[pcsr(F,ImageWindowName)][p] : 0);
			res_xsec_row = ((p > pmin) && (p < pmax) ? res_optdepth[p][qcsr(F,ImageWindowName)] : 0);
			ThermalUpdateCloudPars(Gauss3D_Coef) // use cursor F to adjust the on-center amplitude
		break
			
		case 8:	// BandMap 1D
			BandMapFit1D(optdepth);  // do a BandMap fit with autoguessing
			GetCounts(optdepth)
			UpdateCursor(Gauss3d_coef, "F");	 // put cursor F on fit center
			Wave fit_xsec_col = :Fit_Info:fit_xsec_col, fit_xsec_row=:Fit_Info:fit_xsec_row, fit_optdepth=:Fit_Info:fit_optdepth
			Wave res_xsec_col = :Fit_Info:res_xsec_col, res_xsec_row=:Fit_Info:res_xsec_row, res_optdepth=:Fit_Info:res_optdepth
			fit_xsec_col = ((p > qmin) && (p < qmax) ? fit_optdepth[pcsr(F,ImageWindowName)][p] : 0);
			fit_xsec_row = ((p > pmin) && (p < pmax) ? fit_optdepth[p][qcsr(F,ImageWindowName)] : 0);
			res_xsec_col = ((p > qmin) && (p < qmax) ? res_optdepth[pcsr(F,ImageWindowName)][p] : 0);
			res_xsec_row = ((p > pmin) && (p < pmax) ? res_optdepth[p][qcsr(F,ImageWindowName)] : 0);
			ThermalUpdateCloudPars(Gauss3D_Coef) // use cursor F to adjust the on-center amplitude
		break	
			
		default: // Do nothing, just count counts
			GetCounts(optdepth)
		break;
	endswitch

	// Update Front Panel objects
	UpdateCursor(Gauss3d_coef, "F");	 // put cursor F on fit center
	MakeSlice(OptDepth,"F");
	
	if (findmax == 2)	// Cursor follows fit
		UpdateCursor(Gauss3d_coef, "E");	 // put cursor E on fit center
	Endif
	

	// Update the indexed waves and counter.
	UpdateWaves();

	SetDataFolder fldrSav
End
// ******************** AbsImg_AnalyzeImage **************************************************************************

// ******************** UpdateCursor *************************************************************************
// Places the specified cursor at the requested location on the panel image

Function UpdateCursor(Gauss3D_coef,cursorname)
	Wave Gauss3D_coef
	String cursorname

	// Get the current path and active windows
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Discover the name of the current image and graph windows
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
	String GraphWindowName = CurrentPanel + "#ColdAtomInfoSections";
	
	Cursor /I/W=$(ImageWindowName)  $(cursorname), optdepth, Gauss3D_Coef[2],Gauss3D_Coef[4];   // put cursor B on fit center.
	
	SetDataFolder fldrSav
	return 1
End

// ******************** UpdateCursor ****************************************************************************

// ******************** AddMissingCursor *************************************************************************
// If a desired cursor doesn't exist, then add it at the center of the image.
//
// The cursors have default meanings that I enforce here
// A and B define the ROI: Red
// C and D define the  dark region for subtraction for direct number counting: Blue 
// E is the specified peak location (if required for fits): black
// F is the "followed peak location": grey

Function AddMissingCursor(cursorname, ImageName)
	String cursorname, ImageName;
	variable Active;

	// Get the current path and active windows
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Discover the name of the current image and graph windows
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
	String GraphWindowName = CurrentPanel + "#ColdAtomInfoSections";

	Variable CsrExists= strlen(CsrInfo($(cursorname), ImageWindowName)) > 0
	Variable Xpos, YPos;

	if (CsrExists == 0)
		GetAxis/Q /W=$(ImageWindowName)  bottom
		Xpos = (V_min + V_max) / 2; 
		GetAxis/Q /W=$(ImageWindowName)  left
		Ypos = (V_min + V_max) / 2; 
	else
		XPos = hcsr($(cursorname), ImageWindowName);
		YPos = vcsr($(cursorname), ImageWindowName);
	endif
	strswitch (cursorname)
		case "A":
		case "B":
			Cursor /A=(Active)/C=(65525,0,0)/H=1/I/L=0/S=2 /W=$(ImageWindowName)  $(cursorname), $(ImageName), XPos,YPos;   // put cursor "cursorname" on graph center.	
		break;

		case "C":
		case "D":
			Cursor /A=(Active)/C=(0,0,65525)/H=1/I/L=0/S=2 /W=$(ImageWindowName)  $(cursorname), $(ImageName), XPos,YPos;   // put cursor "cursorname" on graph center.	
		break;

		case "E":
			Cursor /A=(Active)/C=(65525,0,65525)/H=0/I/L=0/S=0 /W=$(ImageWindowName)  $(cursorname), $(ImageName), XPos,YPos;   // put cursor "cursorname" on graph center.	
		break;

		case "F":
			Cursor /A=(Active)/C=(0,65525,0)/H=0/I/L=0/S=0 /W=$(ImageWindowName)  $(cursorname), $(ImageName), XPos,YPos;   // put cursor "cursorname" on graph center.	
		break;
			
		default:
			Cursor /A=(Active)/C=(0,65525,0)/H=0/I/L=0/S=0 /W=$(ImageWindowName)  $(cursorname), $(ImageName), XPos,YPos;   // put cursor "cursorname" on graph center.	
		break;
	endswitch
	
	SetDataFolder fldrSav
	return 1
End

// ******************** UpdateCursor ****************************************************************************

// GetCounts
// 
// Most simple analysis function that counts the number of pixels in two area (atoms and reference) and subtracts 
// the mean of the reference from the atoms area, and then sums the atoms, less the mean.

Function GetCounts(inputimage)
	Wave inputimage

	// Get the current path and active windows
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String WindowName = CurrentPanel + "#ColdAtomInfoImage";

	// Cursors A and B define the ROI: Red
	// Cursors C and D define the  dark region for subtraction for direct number counting: Blue 

	variable xmax, xmin;
	variable ymax, ymin;
	variable background;

	// Get the background average

	//ymax = max(vcsr(C,WindowName),vcsr(D,WindowName));
	//ymin = min(vcsr(C,WindowName),vcsr(D,WindowName));
	//Xmax = max(hcsr(C,WindowName),hcsr(D,WindowName));
	//Xmin = min(hcsr(C,WindowName),hcsr(D,WindowName));
	
	//Duplicate/FREE /O inputimage, inputimage_mask;
	//inputimage_mask *= ( x < xmax && x > xmin && y < ymax && y > ymin ? 1 : 0);
	ymax = max(qcsr(C,WindowName),qcsr(D,WindowName));
	ymin = min(qcsr(C,WindowName),qcsr(D,WindowName));
	Xmax = max(pcsr(C,WindowName),pcsr(D,WindowName));
	Xmin = min(pcsr(C,WindowName),pcsr(D,WindowName));
	
	Duplicate/FREE /O inputimage, inputimage_mask;
	inputimage_mask *= ( p < xmax && p > xmin && q < ymax && q > ymin ? 1 : 0);
	background = sum(inputimage_mask)/((xmax-xmin)*(ymax-ymin));

	// Get the total in the interesting region.

	ymax = max(vcsr(A,WindowName),vcsr(B,WindowName));
	ymin = min(vcsr(A,WindowName),vcsr(B,WindowName));
	Xmax = max(hcsr(A,WindowName),hcsr(B,WindowName));
	Xmin = min(hcsr(A,WindowName),hcsr(B,WindowName));

	Duplicate/FREE /O inputimage, inputimage_mask;
	inputimage_mask -= background;
	inputimage_mask *= ( x < xmax && x > xmin && y < ymax && y > ymin ? 1 : 0);
	
	NVAR absnumber=:absnumber
	NVAR detuning=:Experimental_Info:detuning
	NVAR delta_pix=:Experimental_Info:delta_pix
	Variable sigma
	sigma=3*lambda^2/(2*pi*(1+4*detuning^2));
	absnumber = ((sum(inputimage_mask))*delta_pix^2)/sigma
	
	SetDataFolder fldrSav
	return 1;
End

// ******************** SimpleThermalFit1D *************************************************************************
// This function takes a given image, cuts two cross sections (vert, horiz, defined by cursor A in "Image") 
//  and fits the two cross sections to a simple gaussian.  It assumes that xsec_col,xsec_row, ver_coef,
//  hor_coef all exist.  The fit is done using the x and y scaling of the image (i.e. in real length units if you have 
//  scaled them correctly.)  It does not assume that the cursor is on the center of the cloud.
Function SimpleThermalFit1D(inputimage,cursorname)
	Wave inputimage
	String cursorname

	// Get the current path and active windows
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Discover the name of the current image and graph windows
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
	String GraphWindowName = CurrentPanel + "#ColdAtomInfoSections";


	NVAR slicewidth = :Fit_Info:slicewidth
	NVAR DoRealMask = :Fit_Info:DoRealMask
	NVAR xmax=:fit_info:xmax,xmin=:fit_info:xmin
	NVAR ymax=:fit_info:ymax,ymin=:fit_info:ymin
	NVAR PeakOD = :Experimental_Info:PeakOD
	variable i = 0,fitpts;

 	Wave xsec_col=:Fit_Info:xsec_col, xsec_row=:Fit_Info:xsec_row
	Wave fit_xsec_col = :Fit_Info:fit_xsec_col, fit_xsec_row=:Fit_Info:fit_xsec_row
	Wave res_xsec_col = :Fit_Info:res_xsec_col, res_xsec_row=:Fit_Info:res_xsec_row

	Make/O/T/N=2 :Fit_Info:T_Constraints
	wave/T T_Constraints = :Fit_Info:T_Constraints
	String TempString;
	make/O/N=4 :Fit_Info:ver_coef; make/O/N=4 :Fit_Info:hor_coef;
	Wave ver_coef=:Fit_Info:ver_coef, hor_coef=:Fit_Info:hor_coef
	
	variable bgxmax, bgxmin;
	variable bgymax, bgymin;
	variable background, bg_sdev;

	// Get the background average
	
	bgymax = max(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgymin = min(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgxmax = max(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	bgxmin = min(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	
	Duplicate /O inputimage, bg_mask;
	bg_mask *= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? 1 : 0);
	background = sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin));
	bg_mask -= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? background : 0);
	bg_mask = bg_mask^2;
	bg_sdev = sqrt(sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin)-1))
	
	// In this procedure, and other image procedures, the YMIN/YMAX variable
	// is the physical Z axes for XZ imaging.
	
	// **************************************************
	// define the 1-D crosssections which are to be fit:

	MakeSlice(inputimage,cursorname);
	Duplicate /O xsec_row fit_xsec_row xsec_row_mask xsec_row_weight res_xsec_row; fit_xsec_row = nan;
	Duplicate /O xsec_col fit_xsec_col xsec_col_mask xsec_col_weight res_xsec_col; fit_xsec_col = nan;
	
	// Create weight waves which eliminate regions which have an excessive OD from the fit
	
	If(DoRealMask)
	
		//Create mask waves to have a hard boundary at PeakOD if desired.
		xsec_row_mask = (xsec_row[p] > PeakOD ? 0 : 1);
		xsec_col_mask = (xsec_col[p] > PeakOD ? 0 : 1); 
		xsec_row_weight = 1/bg_sdev;
		xsec_col_weight = 1/bg_sdev;
	
	else
	
		// Using the the weight waves creates a soft boundary at PeakOD
		xsec_row_weight = (1/bg_sdev)*exp(-(xsec_row[p] / PeakOD)^2);
		xsec_col_weight = (1/bg_sdev)*exp(-(xsec_col[p] / PeakOD)^2);
		xsec_row_mask = 1;
		xsec_col_mask = 1;
	
	endif
	
	

	// **************************************************
       // Fit coefficients:
       // ver_coef[0] = Amplitude offset
       // ver_coef[1] = Amplitude
       // ver_coef[2] = Position
       // ver_coef[3] = Width (defined as w in exp(-x^2/w^2))
       
	// Fit in the horizontal direction	--CDH: This is the slice display window! 
	Cursor /W=$(GraphWindowName)  A, xsec_row, xmin; 
	Cursor /W=$(GraphWindowName)  B, xsec_row, xmax; 

	// Have igor guess at the fit paramaters, instead of my guesses
	sprintf TempString, "K2 > %e", xmin; T_Constraints[0] = TempString;
	sprintf TempString, "K2 < %e", xmax; T_Constraints[1] = TempString; 
	
	// wave to store confidence intervals
	make/O/N=12 :Fit_Info:G3d_confidence
	Wave G3d_confidence=:Fit_Info:G3d_confidence
	
	Variable V_FitOptions=4
	hor_coef[0] = background; hor_coef[2]=0;
	CurveFit/Q/O/H="1000" gauss  kwCWave=hor_coef xsec_row((xmin),(xmax)) /D=fit_xsec_row /W=xsec_row_weight /M=xsec_row_mask /C=T_Constraints
	//FuncFit/N/Q/H="1010" ThermalSliceFit, hor_coef, xsec_row((xmin),(xmax)) /D=fit_xsec_row /W=xsec_row_mask
	// Perform the Actual fit
	CurveFit /N/G/Q/H="1000" gauss kwCWave=hor_coef, xsec_row((xmin),(xmax)) /D=fit_xsec_row /W=xsec_row_weight /M=xsec_row_mask /R=res_xsec_row /C=T_Constraints
	//FuncFit/N/Q/H="0000" ThermalSliceFit, hor_coef, xsec_row((xmin),(xmax)) /D=fit_xsec_row /W=xsec_row_mask
	
	wave W_sigma = :W_sigma;
	//store the fitting errors
	G3d_confidence[0] = W_sigma[0];
	G3d_confidence[1] = W_sigma[1];
	G3d_confidence[2] = W_sigma[2];
	G3d_confidence[3] = W_sigma[3];
	G3d_confidence[6] = V_chisq;
	G3d_confidence[7] = V_npnts-V_nterms;
	G3d_confidence[8] = G3d_confidence[6]/G3d_confidence[7];
	
	// Fit in the vertical direction:
	sprintf TempString, "K2 > %e", ymin; T_Constraints[0] = TempString;
	sprintf TempString, "K2 < %e", ymax; T_Constraints[1] = TempString; 
	ver_coef[0] = background; ver_coef[2]=0;
	CurveFit/Q/O/H="1000" gauss  kwCWave=ver_coef, xsec_col((ymin),(ymax)) /D=fit_xsec_col /W=xsec_col_weight /M=xsec_col_mask /C=T_Constraints 
	//FuncFit/N/Q/H="1010" ThermalSliceFit, ver_coef, xsec_col((ymin),(ymax))  /D=fit_xsec_col  /W=xsec_col_mask
	
	// Perform the actual fit
	CurveFit /N/G/Q/H="1000" gauss kwCWave=ver_coef, xsec_col((ymin),(ymax)) /D=fit_xsec_col /W=xsec_col_weight /M=xsec_col_mask /R=res_xsec_col /C=T_Constraints
	//FuncFit/N/Q/H="0000" ThermalSliceFit, ver_coef, xsec_col((ymin),(ymax)) /D=fit_xsec_col /W=xsec_col_mask
	
	//store the fitting errors
	G3d_confidence[0] = Sqrt(((G3d_confidence[0])^2+(W_sigma[0])^2)/4);
	G3d_confidence[1] = Sqrt(((G3d_confidence[1])^2+(W_sigma[1])^2)/4);
	G3d_confidence[4] = W_sigma[2];
	G3d_confidence[5] = W_sigma[3];
	G3d_confidence[9] = V_chisq;
	G3d_confidence[10] = V_npnts-V_nterms;
	G3d_confidence[11] = G3d_confidence[9]/G3d_confidence[10];
	
	// Fill in Coefs wave
	make/O/N=6 :Fit_Info:Gauss3d_coef
	Wave Gauss3d_coef=:Fit_Info:Gauss3d_coef

	Gauss3d_coef[0] = (ver_coef[0] + hor_coef[0]) / 2;		// Offset
	Gauss3d_coef[1] = (ver_coef[1] + hor_coef[1]) / 2;		// Amplitude
	Gauss3d_coef[2] = hor_coef[2];                                       // Horizontal position
	Gauss3d_coef[3] = hor_coef[3];						// Horizontal width
	Gauss3d_coef[4] = ver_coef[2];							// Vertical position
	Gauss3d_coef[5] = ver_coef[3];							// Vertical width
	
	killwaves xsec_row_mask, xsec_col_mask, xsec_row_weight, xsec_col_weight;
	SetDataFolder fldrSav
	return 1
End

// ******************** SimpleThermalFit ****************************************************************************

// ******************** SimpleThermalFit2D *************************************************************************
// This function fits the input image to a 2D gaussian an fills in the suitable variables with the result.

Function SimpleThermalFit2D(inputimage)
	Wave inputimage

	// Get the current path and active windows
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR xmax=:fit_info:xmax, xmin=:fit_info:xmin
	NVAR ymax=:fit_info:ymax, ymin=:fit_info:ymin

	NVAR PeakOD = :Experimental_Info:PeakOD
	NVAR DoRealMask = :fit_info:DoRealMask
	
	Wave fit_optdepth = :fit_info:fit_optdepth
	Wave res_optdepth = :fit_info:res_optdepth

	// Create weight waves which softly eliminate regions which have an excessive OD from the fit
	Duplicate /O inputimage, inputimage_mask, inputimage_weight;

	// Coefficent wave	
	make/O/N=7 :Fit_Info:Gauss3d_coef
	Wave Gauss3d_coef=:Fit_Info:Gauss3d_coef
	
	// wave to store confidence intervals
	make/O/N=10 :Fit_Info:G3d_confidence
	Wave G3d_confidence=:Fit_Info:G3d_confidence
	
	// Discover the name of the current image and graph windows
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
	String GraphWindowName = CurrentPanel + "#ColdAtomInfoSections";
	
	variable bgxmax, bgxmin;
	variable bgymax, bgymin;
	variable background, bg_sdev;

	// Get the background average
	
	bgymax = max(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgymin = min(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgxmax = max(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	bgxmin = min(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	
	Duplicate /O inputimage, bg_mask;
	bg_mask *= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? 1 : 0);
	background = sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin));
	bg_mask -= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? background : 0);
	bg_mask = bg_mask^2;
	bg_sdev = sqrt(sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin)-1))
	
	// Create weight waves which softly eliminate regions which have an excessive OD from the fit
	Duplicate /O inputimage, inputimage_mask, inputimage_weight;
	
	If(DoRealMask)
	
		//Create mask waves to have a hard boundary at PeakOD if desired.
		inputimage_mask = (inputimage[p][q] > PeakOD ? 0 : 1);
		inputimage_weight = 1/bg_sdev;
	
	else
	
		inputimage_weight = (1/bg_sdev)*exp(-(inputimage / PeakOD)^2)
		inputimage_mask = 1;
	
	endif
	
	// In this procedure, and other image procedures, the YMIN/YMAX variable
	// is the physical Z axes for XZ imaging.
	
	// **************************************************
	// Perform the fit
	// 1) use Igor's gaussian to get the intial guesses
	// 2) Run a full fit with Igors Gaussian because it is fast.	
	// 3) use the Thermal_2D function to get the final paramaters
	// doing step three is dumb, I've commented it out, DSB 2014.
	
	Variable V_FitOptions=4
	Gauss3d_coef[6] = 0;			// No corrilation term
	Gauss3d_coef[0] = background;		//fix background to average OD in atom free region
	CurveFit /O/N/Q/H="0000000" Gauss2D kwCWave=Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /M=inputimage_mask
	//Uncomment to the two lines below to set guess manually.
	//Gauss3d_coef[6] = 0;			// No corrilation term
	//Gauss3d_coef[0] = background;		//fix background to average OD in atom free region
	CurveFit /G/N/Q/H="0000000" Gauss2D kwCWave=Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /R=res_optdepth /M=inputimage_mask
	
	//store the fitted function as a wave
	variable pmax = (xmax - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable pmin = (xmin - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable qmax = (ymax - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	variable qmin = (ymin - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	fit_optdepth[pmin,pmax][qmin,qmax] = Gauss2D(Gauss3d_coef,x,y);
	
	// Note the sqt(2) on the widths -- this is due to differing definitions of 1D and 2D gaussians in igor
	redimension/N=7 Gauss3d_coef;
	Gauss3d_coef[3] *= sqrt(2); Gauss3d_coef[5] *= sqrt(2);
	//FuncFitMD/N/Q/H="100000" Thermal_2D, Gauss3d_coef, inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /M=inputimage_mask

	wave W_sigma = :W_sigma;
	//store the fitting errors
	G3d_confidence[0] = W_sigma[0];
	G3d_confidence[1] = W_sigma[1];
	G3d_confidence[2] = W_sigma[2];
	G3d_confidence[3] = sqrt(2)*W_sigma[3];
	G3d_confidence[4] = W_sigma[4];
	G3d_confidence[5] = sqrt(2)*W_sigma[5];
	G3d_confidence[6] = W_sigma[6];
	G3d_confidence[7] = V_chisq;
	G3d_confidence[8] = V_npnts-V_nterms;
	G3d_confidence[9] = G3d_confidence[7]/G3d_confidence[8];

	killwaves inputimage_mask, inputimage_weight, bg_mask
		
	SetDataFolder fldrSav
	return 1
End

// ******************** SimpleThermalFit2D ****************************************************************************

// ******************** TriGaussFit2D *************************************************************************
// This function fits the input image to 3 vertically separated 2D gaussian and fills in the suitable variables with the result.

Function TriGaussFit2D(inputimage)
	Wave inputimage

	// Get the current path and active windows
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR xmax=:fit_info:xmax, xmin=:fit_info:xmin
	NVAR ymax=:fit_info:ymax, ymin=:fit_info:ymin

	NVAR PeakOD = :Experimental_Info:PeakOD
	NVAR DoRealMask = :fit_info:DoRealMask
	NVAR k=:Experimental_Info:k
	NVAR mass=:Experimental_Info:mass
	NVAR expand_time=:Experimental_Info:expand_time
	
	Wave fit_optdepth = :fit_info:fit_optdepth
	Wave res_optdepth = :fit_info:res_optdepth

	// Create weight waves which softly eliminate regions which have an excessive OD from the fit
	Duplicate /O inputimage, inputimage_mask, inputimage_weight;

	// Coefficent wave	
	make/O/N=7 :Fit_Info:Gauss3d_coef
	Wave Gauss3d_coef=:Fit_Info:Gauss3d_coef
	
	// wave to store confidence intervals
	make/O/N=11 :Fit_Info:G3d_confidence
	Wave G3d_confidence=:Fit_Info:G3d_confidence
	
	// Discover the name of the current image and graph windows
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
	String GraphWindowName = CurrentPanel + "#ColdAtomInfoSections";
	
	variable bgxmax, bgxmin;
	variable bgymax, bgymin;
	variable background, bg_sdev;

	// Get the background average
	
	bgymax = max(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgymin = min(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgxmax = max(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	bgxmin = min(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	
	Duplicate /O inputimage, bg_mask;
	bg_mask *= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? 1 : 0);
	background = sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin));
	bg_mask -= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? background : 0);
	bg_mask = bg_mask^2;
	bg_sdev = sqrt(sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin)-1))
	
	// Create weight waves which softly eliminate regions which have an excessive OD from the fit
	Duplicate /O inputimage, inputimage_mask, inputimage_weight;
	
	If(DoRealMask)
	
		//Create mask waves to have a hard boundary at PeakOD if desired.
		inputimage_mask = (inputimage[p][q] > PeakOD ? 0 : 1);
		inputimage_weight = 1/bg_sdev;
	
	else
	
		inputimage_weight = (1/bg_sdev)*exp(-(inputimage / PeakOD)^2)
		inputimage_mask = 1;
	
	endif
	
	// In this procedure, and other image procedures, the YMIN/YMAX variable
	// is the physical Z axes for XZ imaging.
	
	// **************************************************
	// Perform the fit
	// 1) use Igor's gaussian to get the intial guesses
	// 2) Run a full fit with Igors Gaussian because it is fast.	
	// 3) use the TriGauss_2D function to get the final parameters
	
	Variable V_FitOptions=4
	CurveFit /O/N/Q/H="1000001" Gauss2D kwCWave=Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /M=inputimage_mask
	Gauss3d_coef[6] = 0;			// No corrilation term
	Gauss3d_coef[0] = background;		//fix background to average OD in atom free region
	CurveFit /G/N/Q/H="0000001" Gauss2D kwCWave=Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /M=inputimage_mask
	
	// Note the sqt(2) on the widths -- this is due to differing definitions of 1D and 2D gaussians in igor
	redimension/N=8 Gauss3d_coef;
	Gauss3d_coef[3] *= sqrt(2); Gauss3d_coef[5] *= sqrt(2)/2;
	Gauss3d_coef[6] = Gauss3d_coef[1]/2; Gauss3d_coef[7] = Gauss3d_coef[5]*2/sqrt(2);//2*hbar*k*expand_time*(1e3)/mass; // 1e3 converts m to um and ms to s simultaneously
	FuncFitMD/NTHR=0/G/N/Q/H="00000000" TriGauss_2D, Gauss3d_coef, inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /R=res_optdepth /M=inputimage_mask

	//store the fitted function as a wave
	variable pmax = (xmax - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable pmin = (xmin - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable qmax = (ymax - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	variable qmin = (ymin - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	fit_optdepth[pmin,pmax][qmin,qmax] = TriGauss_2D(Gauss3d_coef,x,y);

	wave W_sigma = :W_sigma;
	//store the fitting errors
	G3d_confidence[0] = W_sigma[0];
	G3d_confidence[1] = W_sigma[1];
	G3d_confidence[2] = W_sigma[2];
	G3d_confidence[3] = W_sigma[3];
	G3d_confidence[4] = W_sigma[4];
	G3d_confidence[5] = W_sigma[5];
	G3d_confidence[6] = W_sigma[6];
	G3d_confidence[7] = W_sigma[7];
	G3d_confidence[8] = V_chisq;
	G3d_confidence[9] = V_npnts-V_nterms;
	G3d_confidence[10] = G3d_confidence[8]/G3d_confidence[9];

	killwaves inputimage_mask, inputimage_weight, bg_mask
		
	SetDataFolder fldrSav
	return 1
End

// ******************** TriGaussFit2D ****************************************************************************

// ******************** BandMapFit1D *************************************************************************
// This function fits the input image to 3 vertically separated 2D gaussian and fills in the suitable variables with the result.

Function BandMapFit1D(inputimage)
	Wave inputimage

	// Get the current path and active windows
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	NVAR xmax=:fit_info:xmax, xmin=:fit_info:xmin
	NVAR ymax=:fit_info:ymax, ymin=:fit_info:ymin

	NVAR PeakOD = :Experimental_Info:PeakOD
	NVAR DoRealMask = :fit_info:DoRealMask
	NVAR k=:Experimental_Info:k
	NVAR mass=:Experimental_Info:mass
	NVAR expand_time=:Experimental_Info:expand_time
	
	Wave fit_optdepth = :fit_info:fit_optdepth
	Wave res_optdepth = :fit_info:res_optdepth

	// Create weight waves which softly eliminate regions which have an excessive OD from the fit
	Duplicate /O inputimage, inputimage_mask, inputimage_weight;

	// Coefficent wave	
	make/O/N=7 :Fit_Info:Gauss3d_coef
	Wave Gauss3d_coef=:Fit_Info:Gauss3d_coef
	
	// wave to store confidence intervals
	make/O/N=12 :Fit_Info:G3d_confidence
	Wave G3d_confidence=:Fit_Info:G3d_confidence
	
	// Discover the name of the current image and graph windows
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";
	String GraphWindowName = CurrentPanel + "#ColdAtomInfoSections";
	
	variable bgxmax, bgxmin;
	variable bgymax, bgymin;
	variable background, bg_sdev;

	// Get the background average
	
	bgymax = max(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgymin = min(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgxmax = max(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	bgxmin = min(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	
	Duplicate /O inputimage, bg_mask;
	bg_mask *= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? 1 : 0);
	background = sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin));
	bg_mask -= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? background : 0);
	bg_mask = bg_mask^2;
	bg_sdev = sqrt(sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin)-1))
	
	// Create weight waves which softly eliminate regions which have an excessive OD from the fit
	Duplicate /O inputimage, inputimage_mask, inputimage_weight;
	
	If(DoRealMask)
	
		//Create mask waves to have a hard boundary at PeakOD if desired.
		inputimage_mask = (inputimage[p][q] > PeakOD ? 0 : 1);
		inputimage_weight = 1/bg_sdev;
	
	else
	
		inputimage_weight = (1/bg_sdev)*exp(-(inputimage / PeakOD)^2)
		inputimage_mask = 1;
	
	endif
	
	// In this procedure, and other image procedures, the YMIN/YMAX variable
	// is the physical Z axes for XZ imaging.
	
	// **************************************************
	// Perform the fit
	// 1) use Igor's gaussian to get the intial guesses
	// 2) Run a full fit with Igors Gaussian because it is fast.	
	// 3) use the BandMap_1D function to get the final parameters
	// w[0] = offset
	// w[1] = Agband
	// w[2] = x0
	// w[3] = xrmstherm
	// w[4] = z0
	// w[5] = hbk
	// w[6] = BetaJ0
	// w[7] = Aeband
	// w[8] = BetaJ1 
	
	Variable V_FitOptions=4
	CurveFit /O/N/Q/H="1000001" Gauss2D kwCWave=Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /M=inputimage_mask
	Gauss3d_coef[6] = 0;			// No corrilation term
	Gauss3d_coef[0] = background;		//fix background to average OD in atom free region
	CurveFit /G/N/Q/H="0000001" Gauss2D kwCWave=Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /M=inputimage_mask
	
	// Note the sqt(2) on the widths -- this is due to differing definitions of 1D and 2D gaussians in igor
	redimension/N=9 Gauss3d_coef;
	Gauss3d_coef[3] *= sqrt(2);
	Gauss3d_coef[7] = Gauss3d_coef[1]/2; Gauss3d_coef[5] = hbar*k*expand_time*(1e3)/mass; // 1e3 converts m to um and ms to s simultaneously
	Gauss3d_coef[6] = .01; Gauss3d_coef[8] = .01;
	FuncFitMD/NTHR=0/G/N/Q/H="000001000" BandMap_1D, Gauss3d_coef, inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /R=res_optdepth /M=inputimage_mask

	//store the fitted function as a wave
	variable pmax = (xmax - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable pmin = (xmin - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable qmax = (ymax - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	variable qmin = (ymin - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	fit_optdepth[pmin,pmax][qmin,qmax] = BandMap_1D(Gauss3d_coef,x,y);

	wave W_sigma = :W_sigma;
	//store the fitting errors
	G3d_confidence[0] = W_sigma[0];
	G3d_confidence[1] = W_sigma[1];
	G3d_confidence[2] = W_sigma[2];
	G3d_confidence[3] = W_sigma[3];
	G3d_confidence[4] = W_sigma[4];
	G3d_confidence[5] = W_sigma[5];
	G3d_confidence[6] = W_sigma[6];
	G3d_confidence[7] = W_sigma[7];
	G3d_confidence[8] = W_sigma[8];
	G3d_confidence[9] = V_chisq;
	G3d_confidence[10] = V_npnts-V_nterms;
	G3d_confidence[11] = G3d_confidence[9]/G3d_confidence[10];

	killwaves inputimage_mask, inputimage_weight, bg_mask
		
	SetDataFolder fldrSav
	return 1
End

// ******************** BandMapFit1D ****************************************************************************

// ******************** ThomasFermiFit1D *************************************************************************
// This function takes a given image, cuts two cross sections (vert, horiz, defined by a cursor in "image") 
//  and fits the two cross sections to a ThomasFermi distribution.  It assumes that xsec_col,xsec_row, TF_ver_coef,
//  TF_hor_coef all exist.  The fit is done using the x and y scaling of the image (i.e. in real length units if you have 
//  scaled them correctly.)  It assumes that the cursor is on the center of the cloud.

Function ThomasFermiFit1D(inputimage,cursorname,graphname,fit_type)
	Wave inputimage
	String cursorname,graphname
	Variable fit_type

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Discover the name of the current image window
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";

	Wave xsec_col=:Fit_Info:xsec_col, xsec_row=:Fit_Info:xsec_row
	Wave ver_coef=:Fit_Info:ver_coef,hor_coef=:Fit_Info:hor_coef
	Wave fit_xsec_col = :Fit_Info:fit_xsec_col, fit_xsec_row=:Fit_Info:fit_xsec_row
	Wave res_xsec_col = :Fit_Info:res_xsec_col, res_xsec_row=:Fit_Info:res_xsec_row
	Wave TF_hor_coef=:Fit_Info:TF_hor_coef,TF_ver_coef=:Fit_Info:TF_ver_coef
	NVAR xrms=:xrms, yrms=:yrms, zrms=:zrms
	NVAR slicewidth = :Fit_Info:slicewidth
	NVAR xmax=:fit_info:xmax,xmin=:fit_info:xmin
	NVAR ymax=:fit_info:ymax,ymin=:fit_info:ymin
	NVAR DoRealMask = :fit_info:DoRealMask
	NVAR PeakOD = :Experimental_Info:PeakOD
	variable i = 0;
	Variable V_FitOptions=4	// Suppress fit window
	
	// boolean true if TF only, false if TF+thermal
	Variable TFonly	=(fit_type==3 || fit_type==5)
	
	variable bgxmax, bgxmin;
	variable bgymax, bgymin;
	variable background, bg_sdev;

	// Get the background average
	
	bgymax = max(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgymin = min(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgxmax = max(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	bgxmin = min(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	
	Duplicate /O inputimage, bg_mask;
	bg_mask *= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? 1 : 0);
	background = sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin));
	bg_mask -= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? background : 0);
	bg_mask = bg_mask^2;
	bg_sdev = sqrt(sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin)-1))

	// **************************************************
	// define the 1-D crosssections which are to be fit:

	MakeSlice(inputimage,cursorname);
	Duplicate /O xsec_row fit_xsec_row xsec_row_mask xsec_row_weight;
	Duplicate /O xsec_col fit_xsec_col xsec_col_mask xsec_col_weight;
	fit_xsec_row = nan;
	fit_xsec_col = nan;
	
	// Create weight waves which eliminate regions which have an excessive OD from the fit
	
	If(DoRealMask)
	
		//Create mask waves to have a hard boundary at PeakOD if desired.
		xsec_row_mask = (xsec_row[p] > PeakOD ? 0 : 1);
		xsec_col_mask = (xsec_col[p] > PeakOD ? 0 : 1);
		xsec_row_weight = 1/bg_sdev;
		xsec_col_weight = 1/bg_sdev;
	
	else
	
		// Using the the weight waves creates a soft boundary at PeakOD
		xsec_row_weight = (1/bg_sdev)*exp(-(xsec_row / PeakOD)^2);
		xsec_col_weight = (1/bg_sdev)*exp(-(xsec_col / PeakOD)^2);
		xsec_row_mask = 1;
		xsec_col_mask = 1;
	
	endif

	
	// **************************************************
	// Fit coefficients:
	// TF_*_coef[0] = Amplitude Offset.
	// TF_*_coef[1] = Thermal cloud amplitude.
	// TF_*_coef[2] = Position.
	// TF_*_coef[3] = Thermal width (defined as w in exp(-x^2/w^2))
	// TF_*_coef[4] = TF amplitude.
	// TF_*_coef[5] = TF radius.
	Redimension/N=6 TF_hor_coef, TF_ver_coef		// ensure coef. waves have appropriate number of points
	
	// wave to store confidence intervals
	make/O/N=17 :Fit_Info:G3d_confidence
	Wave G3d_confidence=:Fit_Info:G3d_confidence
	
	// Fit in the vertical direction:
	if (TFonly)	// TF fit only, no thermal fit
		TF_ver_coef[0] = background; TF_ver_coef[1] = 0;  // assume that the temperature, amplitude is zero.
		TF_ver_coef[2] = vcsr($cursorname,ImageWindowName);TF_ver_coef[3] = 1;  // set position to the cursor.
		TF_ver_coef[4] = .5;TF_ver_coef[5] = 50;  // guess at the TF values.
		FuncFit /G/N/H="110100"/Q TF_1D, TF_ver_coef, xsec_col((ymin),(ymax))  /W=xsec_col_weight /R=res_xsec_col /M=xsec_col_mask // do the fit with T=0 thermal fixed
	else			// Thermal and TF fit
		TF_ver_coef[0] = ver_coef[0]; TF_ver_coef[1] = ver_coef[1];  // set the known info from the thermal fit.
		TF_ver_coef[2] = ver_coef[2]; TF_ver_coef[3] =ver_coef[3];  // set the known info from the thermal fit.
		TF_ver_coef[4] = .5;TF_ver_coef[5] = 50;  // guess at the TF values.
		FuncFit /G/N/H="111100"/Q g2TF_1D, TF_ver_coef, xsec_col((ymin),(ymax)) /W=xsec_col_weight /M=xsec_col_mask // do the fit with manual initial guess, thermal fit fixed
		FuncFit /G/N/H="100000"/Q g2TF_1D, TF_ver_coef, xsec_col((ymin),(ymax))  /W=xsec_col_weight /R=res_xsec_col /M=xsec_col_mask // redo the fit with better initial guess, all values fitted
	endif			

	wave W_sigma = :W_sigma;
	//store the fitting errors
	G3d_confidence[0] = W_sigma[0];
	G3d_confidence[1] = W_sigma[1];
	G3d_confidence[4] = W_sigma[2];
	G3d_confidence[5] = W_sigma[3];
	G3d_confidence[6] = W_sigma[4];
	G3d_confidence[8] = W_sigma[5];
	G3d_confidence[10] = W_sigma[2];
	G3d_confidence[14] = V_chisq;
	G3d_confidence[15] = V_npnts-V_nterms;
	G3d_confidence[16] = G3d_confidence[14]/G3d_confidence[15];

	// Fit in the horizontal direction
	if (TFonly)	// TF fit only, no thermal fit
		TF_hor_coef[0] = background; TF_hor_coef[1] = 0;  // assume that the temperature, amplitude is zero.
		TF_hor_coef[2] = hcsr($cursorname,ImageWindowName);TF_hor_coef[3] = 1;  // set position to the cursor.
		TF_hor_coef[4] = .5;TF_hor_coef[5] = 50;  // guess at the TF values.
		FuncFit /G/N/H="110100"/Q TF_1D, TF_hor_coef, xsec_row((xmin),(xmax)) /W=xsec_row_weight /R=res_xsec_row /M=xsec_row_mask // do the fit with T=0 thermal fixed
	else 		// Thermal and TF fit
		TF_hor_coef[0] = hor_coef[0]; TF_hor_coef[1] = ver_coef[1];  // set the known info from the thermal fit.
		TF_hor_coef[2] = hor_coef[2];TF_hor_coef[3] = hor_coef[3];  // set the known info from the thermal fit.
		TF_hor_coef[4] = .5;TF_hor_coef[5] = 50;  // guess at the TF values.
		FuncFit /G/N/H="111100"/Q g2TF_1D, TF_hor_coef, xsec_row((xmin),(xmax)) /W=xsec_row_weight /M=xsec_row_mask // do the fit with manual initial guess
		FuncFit /G/N/H="100000"/Q g2TF_1D, TF_hor_coef, xsec_row((xmin),(xmax)) /W=xsec_row_weight /R=res_xsec_row /M=xsec_row_mask // redo the fit with better initial guess
	endif
	
	// Update display waves
	fit_xsec_col = TF_1D(TF_ver_coef,x);
	fit_xsec_row = TF_1D(TF_hor_coef,x);
	
	//store the fitting errors
	G3d_confidence[0] = Sqrt(((G3d_confidence[0])^2+(W_sigma[0])^2)/4);
	G3d_confidence[1] = Sqrt(((G3d_confidence[1])^2+(W_sigma[1])^2)/4);
	G3d_confidence[2] = W_sigma[2];
	G3d_confidence[3] = W_sigma[3];
	G3d_confidence[6] = Sqrt(((G3d_confidence[6])^2+(W_sigma[4])^2)/4);
	G3d_confidence[7] = W_sigma[5];
	G3d_confidence[9] = W_sigma[2];
	G3d_confidence[11] = V_chisq;
	G3d_confidence[12] = V_npnts-V_nterms;
	G3d_confidence[13] = G3d_confidence[11]/G3d_confidence[12];

	// Fill in Coefs wave
	make/O/N=11 :Fit_Info:Gauss3d_coef
	Wave Gauss3d_coef=:Fit_Info:Gauss3d_coef

	Gauss3d_coef[0] = (TF_ver_coef[0] + TF_hor_coef[0]) / 2;		// Amplitude offset
	Gauss3d_coef[1] = (TF_ver_coef[1] + TF_hor_coef[1]) / 2;		// GaussHeight
	Gauss3d_coef[2] = TF_hor_coef[2];				// hor. position (thermal)
	Gauss3d_coef[3] = TF_hor_coef[3];				// thermal hor. width
	Gauss3d_coef[4] = TF_ver_coef[2];				// ver. position (thermal)
	Gauss3d_coef[5] = TF_ver_coef[3];				// thermal ver. width
	Gauss3d_coef[6]  =  (TF_ver_coef[4] + TF_hor_coef[4]) / 2; // TF Height
	Gauss3d_coef[7] = TF_Hor_coef[5];				// RTF hor.
	Gauss3d_coef[8]  = TF_ver_coef[5];			// RTF ver.
	// include these for compability so that we can run bimodal fit w/ or w/o constrained centers
	Gauss3d_coef[9] = TF_hor_coef[2];				// TF hor. position (constrained to be same as thermal)
	Gauss3d_coef[10] = TF_ver_coef[2];			// TF ver. position (constrained to be same as thermal)
	
	killwaves xsec_row_mask, xsec_col_mask, xsec_row_weight, xsec_col_weight;
	
	SetDataFolder fldrSav
End
// ******************** ThomasFermiFit1D ****************************************************************************

// ******************** ThomasFermiFit1D _free *************************************************************************
// This function takes a given image, cuts two cross sections (vert, horiz, defined by a cursor in "image") 
//  and fits the two cross sections to a ThomasFermi distribution.  It assumes that xsec_col,xsec_row, TF_ver_coef,
//  TF_hor_coef all exist.  The fit is done using the x and y scaling of the image (i.e. in real length units if you have 
//  scaled them correctly.)  It assumes that the cursor is on the center of the cloud.
//
// *"_free" version of TF fit provides for independent centers of TF + thermal clouds. -CDH 30.Jan.2012

Function ThomasFermiFit1D_free(inputimage,cursorname,graphname,fit_type)
	Wave inputimage
	String cursorname,graphname
	Variable fit_type

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Discover the name of the current image window
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";

	Wave xsec_col=:Fit_Info:xsec_col, xsec_row=:Fit_Info:xsec_row
	Wave ver_coef=:Fit_Info:ver_coef,hor_coef=:Fit_Info:hor_coef		// SimpleThermal1D results
	Wave fit_xsec_col = :Fit_Info:fit_xsec_col, fit_xsec_row=:Fit_Info:fit_xsec_row
	Wave res_xsec_col = :Fit_Info:res_xsec_col, res_xsec_row=:Fit_Info:res_xsec_row
	Wave TF_hor_coef=:Fit_Info:TF_hor_coef,TF_ver_coef=:Fit_Info:TF_ver_coef
	NVAR xrms=:xrms, yrms=:yrms, zrms=:zrms
	NVAR slicewidth = :Fit_Info:slicewidth
	NVAR xmax=:fit_info:xmax,xmin=:fit_info:xmin
	NVAR ymax=:fit_info:ymax,ymin=:fit_info:ymin
	NVAR DoRealMask = :fit_info:DoRealMask
	NVAR PeakOD = :Experimental_Info:PeakOD
	variable i = 0;
	Variable V_FitOptions=4	// Suppress fit window

	// boolean true if TF only, false if TF+thermal
	Variable TFonly	=(fit_type==3 || fit_type==5)
	
	// **************************************************
	// define the 1-D crosssections which are to be fit:
	MakeSlice(inputimage,cursorname);
	Duplicate /O xsec_row fit_xsec_row xsec_row_mask xsec_row_weight;
	Duplicate /O xsec_col fit_xsec_col xsec_col_mask xsec_col_weight;
	fit_xsec_row = nan;
	fit_xsec_col = nan;
	
	// Create weight waves which eliminate regions which have an excessive OD from the fit
	
	If(DoRealMask)
	
		//Create mask waves to have a hard boundary at PeakOD if desired.
		xsec_row_mask = (xsec_row[p] > PeakOD ? 0 : 1);
		xsec_col_mask = (xsec_col[p] > PeakOD ? 0 : 1);
		xsec_row_weight = 1;
		xsec_col_weight = 1;
	
	else
	
		// Using the the weight waves creates a soft boundary at PeakOD
		xsec_row_weight = exp(-(xsec_row / PeakOD)^2);
		xsec_col_weight = exp(-(xsec_col / PeakOD)^2);
		xsec_row_mask = 1;
		xsec_col_mask = 1;
	
	endif
	
	// **************************************************
	// Fit coefficients:
	// TF_*_coef[0] = Amplitude Offset.
	// TF_*_coef[1] = Thermal cloud amplitude.
	// TF_*_coef[2] = Thermal Position.
	// TF_*_coef[3] = Thermal width (defined as w in exp(-x^2/w^2))
	// TF_*_coef[4] = TF amplitude.
	// TF_*_coef[5] = TF radius.
	// TF_*_coef[6] = TF position
	Redimension/N=7 TF_hor_coef, TF_ver_coef 			// ensure coef. waves have appropriate number of points
	
	// wave to store confidence intervals
	make/O/N=17 :Fit_Info:G3d_confidence
	Wave G3d_confidence=:Fit_Info:G3d_confidence
	
	// Fit in the vertical direction:			//TFOnly won't get to *_free version
	If(TFonly)  // TF fit only, no thrmal fit.
//		TF_ver_coef[0] = 0; TF_ver_coef[1] = 0;  TF_ver_coef[2]=0; // assume that the temperature, amplitude is zero.
//		TF_ver_coef[6] = vcsr($cursorname,ImageWindowName);TF_ver_coef[3] = 1;  // set position to the cursor.
//		TF_ver_coef[4] = 2;TF_ver_coef[5] = 50;  // guess at the TF values.
//		FuncFit /N/H="0111000"/Q TF_1D, TF_ver_coef, xsec_col((ymin),(ymax))  /W=xsec_col_mask // do the fit with T=0 thermal fixed
	else  // TF +thermal fit
		TF_ver_coef[0] = ver_coef[0]; TF_ver_coef[1] = ver_coef[1];  // set the known info from the thermal fit.
		TF_ver_coef[2] = ver_coef[2]; TF_ver_coef[3] =ver_coef[3];  // set the known info from the thermal fit.
		TF_ver_coef[4] = .5;TF_ver_coef[5] = 50;  TF_ver_coef[6] = TF_ver_coef[2]; // guess at the TF values.
		FuncFit /G/N/H="1111000"/Q g2TF_1D_free, TF_ver_coef, xsec_col((ymin),(ymax)) /W=xsec_col_weight /M=xsec_col_mask // do the fit with manual initial guess, thermal fit fixed
		FuncFit /G/N/H="1000000"/Q g2TF_1D_free, TF_ver_coef, xsec_col((ymin),(ymax))  /W=xsec_col_weight /R=res_xsec_col /M=xsec_col_mask // redo the fit with better initial guess, all values fitted
	endif	
	
	wave W_sigma = :W_sigma;
	//store the fitting errors
	G3d_confidence[0] = W_sigma[0];
	G3d_confidence[1] = W_sigma[1];
	G3d_confidence[4] = W_sigma[2];
	G3d_confidence[5] = W_sigma[3];
	G3d_confidence[6] = W_sigma[4];
	G3d_confidence[8] = W_sigma[5];
	G3d_confidence[10] = W_sigma[6];
	G3d_confidence[14] = V_chisq;
	G3d_confidence[15] = V_npnts-V_nterms;
	G3d_confidence[16] = G3d_confidence[14]/G3d_confidence[15];
		

	// Fit in the horizontal direction			//TFOnly won't get to *_free verision
	If(TFonly)  // TF fit only, no thermal fit
//		TF_hor_coef[0] = 0; TF_hor_coef[1] = 0;  TF_hor_coef[2]=0; // assume that the temperature, amplitude is zero.
//		TF_hor_coef[6] = hcsr($cursorname,ImageWindowName);TF_hor_coef[3] = 1;  // set position to the cursor.
//		TF_hor_coef[4] = 2;TF_hor_coef[5] = 50;  // guess at the TF values.
//		FuncFit /N/H="0111000"/Q TF_1D, TF_hor_coef, xsec_row((xmin),(xmax)) /W=xsec_row_mask  // do the fit with T=0 thermal fixed	
	else  // Thermal and TF fit
		TF_hor_coef[0] = hor_coef[0]; TF_hor_coef[1] = ver_coef[1];  // set the known info from the thermal fit.
		TF_hor_coef[2] = hor_coef[2];TF_hor_coef[3] = hor_coef[3];  // set the known info from the thermal fit.
		TF_hor_coef[4] = 2;TF_hor_coef[5] = 50;  TF_hor_coef[6] = TF_hor_coef[2]; // guess at the TF values.
		FuncFit /G/N/H="1111000"/Q g2TF_1D_free, TF_hor_coef, xsec_row((xmin),(xmax)) /W=xsec_row_weight /M=xsec_row_mask// do the fit with manual initial guess
		FuncFit /G/N/H="1000000"/Q g2TF_1D_free, TF_hor_coef, xsec_row((xmin),(xmax)) /W=xsec_row_weight /R=res_xsec_row /M=xsec_row_mask// redo the fit with better initial guess		
	endif
	
	// Update display waves
	fit_xsec_col = g2TF_1D_free(TF_ver_coef,x);
	fit_xsec_row = g2TF_1D_free(TF_hor_coef,x);
	
	//store the fitting errors
	G3d_confidence[0] = Sqrt(((G3d_confidence[0])^2+(W_sigma[0])^2)/4);
	G3d_confidence[1] = Sqrt(((G3d_confidence[1])^2+(W_sigma[1])^2)/4);
	G3d_confidence[2] = W_sigma[2];
	G3d_confidence[3] = W_sigma[3];
	G3d_confidence[6] = Sqrt(((G3d_confidence[6])^2+(W_sigma[4])^2)/4);
	G3d_confidence[7] = W_sigma[5];
	G3d_confidence[9] = W_sigma[6];
	G3d_confidence[11] = V_chisq;
	G3d_confidence[12] = V_npnts-V_nterms;
	G3d_confidence[13] = G3d_confidence[11]/G3d_confidence[12];

	// Fill in Coefs wave
	make/O/N=11 :Fit_Info:Gauss3d_coef
	Wave Gauss3d_coef=:Fit_Info:Gauss3d_coef

	Gauss3d_coef[0] = (TF_ver_coef[0] + TF_hor_coef[0]) / 2;		// Amplitude offset
	Gauss3d_coef[1] = (TF_ver_coef[1] + TF_hor_coef[1]) / 2;		// GaussHeight
	Gauss3d_coef[2] = TF_hor_coef[2];				// hor. position (thermal)
	Gauss3d_coef[3] = TF_hor_coef[3];				// thermal hor. width
	Gauss3d_coef[4] = TF_ver_coef[2];				// ver. position (thermal)
	Gauss3d_coef[5] = TF_ver_coef[3];				// thermal ver. width
	Gauss3d_coef[6]  =  (TF_ver_coef[4] + TF_hor_coef[4]) / 2; // TF Height
	Gauss3d_coef[7] = TF_Hor_coef[5];				// RTF X
	Gauss3d_coef[8]  = TF_ver_coef[5];			// RTF Y	
	Gauss3d_coef[9] = TF_hor_coef[6];				// TF hor. position
	Gauss3d_coef[10] = TF_ver_coef[6];			// TF ver. position
	
	killwaves xsec_row_mask, xsec_col_mask, xsec_row_weight, xsec_col_weight;
	
	SetDataFolder fldrSav
End
// ******************** ThomasFermiFit1D_free ****************************************************************************


// ******************** SimpleThomasFermiFit2D *************************************************************************
// This function fits the input image to a 2D gaussian an fills in the suitable variables with the result.

Function ThomasFermiFit2D(inputimage, fit_type)
	Wave inputimage
	variable fit_type

	// Get the current path and active windows
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	// Discover the name of the current image window
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";

	NVAR xmax=:fit_info:xmax, xmin=:fit_info:xmin
	NVAR ymax=:fit_info:ymax, ymin=:fit_info:ymin
	NVAR DoRealMask = :fit_info:DoRealMask
	NVAR PeakOD = :Experimental_Info:PeakOD

	// Coefficent wave	
	make/O/N=7 :Fit_Info:Gauss3d_coef
	Wave Gauss3d_coef=:Fit_Info:Gauss3d_coef
	Wave fit_optdepth = :Fit_Info:fit_optdepth;
	Wave res_optdepth = :fit_info:res_optdepth
	
	// wave to store confidence intervals
	make/O/N=12 :Fit_Info:G3d_confidence
	Wave G3d_confidence=:Fit_Info:G3d_confidence	

	string Hold;
	
	variable bgxmax, bgxmin;
	variable bgymax, bgymin;
	variable background, bg_sdev;

	// Get the background average
	
	bgymax = max(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgymin = min(qcsr(C,ImageWindowName),qcsr(D,ImageWindowName));
	bgxmax = max(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	bgxmin = min(pcsr(C,ImageWindowName),pcsr(D,ImageWindowName));
	
	Duplicate /O inputimage, bg_mask;
	bg_mask *= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? 1 : 0);
	background = sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin));
	bg_mask -= ( p < bgxmax && p > bgxmin && q < bgymax && q > bgymin ? background : 0);
	bg_mask = bg_mask^2;
	bg_sdev = sqrt(sum(bg_mask)/((bgxmax-bgxmin)*(bgymax-bgymin)-1))
	
	// Create weight waves which softly eliminate regions which have an excessive OD from the fit
	Duplicate /O inputimage, inputimage_mask, inputimage_weight;
	
	If(DoRealMask)
	
		//Create mask waves to have a hard boundary at PeakOD if desired.
		inputimage_mask = (inputimage[p][q] > PeakOD ? 0 : 1);
		inputimage_weight = 1/bg_sdev;
	else
	
		inputimage_weight = (1/bg_sdev)*exp(-(inputimage / PeakOD)^2);
		inputimage_mask = 1;
	
	endif
	
	// In this procedure, and other image procedures, the YMIN/YMAX variable
	// is the physical Z axes for XZ imaging.
	
	// **************************************************
	// Perform the fit
	// 1) use Igor's gaussian to get the intial guesses
	// 2) Run a full fit with Igors Gaussian because it is fast.	
	// 3) use the Thermal_2D function to get the final paramaters
	// 4) Fit to the 3D Thomas Fermi
	
	Variable V_FitOptions=4
	Variable K0 = background;
	Variable K6 = 0;			// No corrilation term
	CurveFit /O/N/Q/H="1000001" Gauss2D kwCWave=Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /M=inputimage_mask
	Gauss3d_coef[6] = 0;			// No corrilation term
	Gauss3d_coef[0] = background;		//fix background to average OD in atom free region
	CurveFit /G/N/Q/H="0000001" Gauss2D kwCWave=Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /M=inputimage_mask
	Gauss3d_coef[3] *= sqrt(2); Gauss3d_coef[5] *= sqrt(2);
	
	// Note the sqt(2) on the widths -- this is due to differing definitions of 1D and 2D gaussians in igor
	redimension/N=9 Gauss3d_coef;

	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = Atherm
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = xrmstherm
	//CurveFitDialog/ w[4] = z0
	//CurveFitDialog/ w[5] = z rmstherm // disabeled
	//CurveFitDialog/ w[6] = ATF
	//CurveFitDialog/ w[7] = Rx_TF
	//CurveFitDialog/ w[8] = Rz_TF
	
	Gauss3d_coef[6] = Gauss3d_coef[1]*(2/3);
	Gauss3d_coef[7] = Gauss3d_coef[3]*1.25;
	Gauss3d_coef[8] = Gauss3d_coef[5]*1.25;

	If( (fit_type == 4) )  // Thermal and TF fit
		//Gauss3d_coef[0] = background;
		Gauss3d_coef[1] /= 6;  // Based on the initial gauss peak assume that the gaussion component is 1/6 the height
		Gauss3d_coef[3] *= 2.5;	// And Twice as wide
		Gauss3d_coef[5] *= 2.5;
		Hold = "000000000"; // fit both thermal widths
	endif
	
	if( (fit_type == 5) )  // TF fit only, no thermal fit
		//Gauss3d_coef[0] = background;
		Gauss3d_coef[1] = 0;
		Hold = "010101000";
	endif
	
	FuncFitMD/G/N/Q/H=(Hold) TF_2D, Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /M=inputimage_mask /R=res_optdepth /W=inputimage_weight /D
	//Gauss3d_coef[5] = Gauss3d_coef[3] ;
	
	wave W_sigma = :W_sigma;
	//store the fitting errors
	G3d_confidence[0] = W_sigma[0];
	G3d_confidence[1] = W_sigma[1];
	G3d_confidence[2] = W_sigma[2];
	G3d_confidence[3] = W_sigma[3];
	G3d_confidence[4] = W_sigma[4];
	G3d_confidence[5] = W_sigma[5];
	G3d_confidence[6] = W_sigma[6];
	G3d_confidence[7] = W_sigma[7];
	G3d_confidence[8] = W_sigma[8];
	G3d_confidence[9] = V_chisq;
	G3d_confidence[10] = V_npnts-V_nterms;
	G3d_confidence[11] = G3d_confidence[9]/G3d_confidence[10];
	
	// Update Display Waves
	variable pmax = (xmax - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable pmin = (xmin - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable qmax = (ymax - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	variable qmin = (ymin - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	fit_optdepth[pmin,pmax][qmin,qmax] = TF_2D(Gauss3d_coef,x,y)
	
	killwaves inputimage_mask, inputimage_weight;
		
	SetDataFolder fldrSav
	return 1
End
// ******************** ThomasFermiFit2D ****************************************************************************
	
// *************** TFUpdateCloudPars ***************************************************************
// This function takes the fit parameters from a Thomas Fermi fitting routine and converts them into 
//  atom cloud parameters
//
// This function assumes that ThermalUpdateCloudPars has already run and updated the thermal paramaters.
// Gauss3D_coef[0] = Offset
// Gauss3D_coef[1] = Amplitude
// Gauss3D_coef[2] = Horizontal Position
// Gauss3D_coef[3] = Thermal Horizontal Width
// Gauss3D_coef[4] = Vertical Position
// Gauss3D_coef[5] = Thermal Vertical Width
// Gauss3D_coef[6] = TF amplitude
// Gauss3D_coef[7] = TF Horizontal width
// Gauss3D_coef[8] = TF Vertical Width

Function TFUpdateCloudPars(Gauss3d_coef,fit_type)	
	Wave Gauss3d_coef
	Variable fit_type

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	Variable sigma, TFonly
	//Variable scalex, scaley,scalez

	// variables for the running indexed waves
	NVAR autoupdate=:IndexedWaves:autoupdate, index=:IndexedWaves:index 

	// experimental information 
	NVAR  trapmin=:Experimental_Info:trapmin
	NVAR aspectratio=:Experimental_Info:aspectratio, moment=:Experimental_Info:moment
	NVAR omgX = :Experimental_Info:omgX;
	NVAR omgY = :Experimental_Info:omgY;
	NVAR omgZ = :Experimental_Info:omgZ;
	NVAR omgXLat = :Experimental_Info:omgXLat;
	NVAR omgYLat = :Experimental_Info:omgYLat;
	NVAR omgZLat = :Experimental_Info:omgZLat;
	NVAR aspectratio_BEC=:Experimental_Info:aspectratio_BEC
	NVAR detuning=:Experimental_Info:detuning,expand_time=:Experimental_Info:expand_time
	NVAR camdir=:Experimental_Info:camdir,traptype=:Experimental_Info:traptype
	NVAR magnification=:Experimental_Info:magnification
	NVAR CastDum_xscale=:Experimental_Info:CastDum_xscale;
	NVAR CastDum_yscale=:Experimental_Info:CastDum_yscale;
	NVAR CastDum_zscale=:Experimental_Info:CastDum_zscale;
	NVAR a_ho = :Experimental_Info:a_ho,omg_ho=:Experimental_Info:omg_ho
	NVAR mass=:Experimental_Info:mass
	NVAR a_scatt=:Experimental_Info:a_scatt
	NVAR theta=:Experimental_Info:theta

	// extracted cloud parameters
	NVAR chempot=:chempot,     radius_TF=:radius_TF,       radius_TF_t0=:radius_TF_t0
	NVAR density=:density,    number=:number,      temperature=:temperature,  PSD=:PSD
	NVAR xrms=:xrms,       yrms=:yrms,         zrms=:zrms
	NVAR xposition=:xposition,        yposition=:yposition,         zposition=:zposition
	NVAR AspectRatio_meas=:AspectRatio_meas,            amplitude=:amplitude
	NVAR density_t0=:density_t0,       xrms_t0=:xrms_t0,        yrms_t0=:yrms_t0,        zrms_t0=:zrms_t0
	NVAR AspectRatio_meas_t0=:AspectRatio_meas_t0,     density_BEC=:density_BEC,      density_BEC_t0=:density_BEC_t0
	NVAR xwidth_BEC=:xwidth_BEC,       ywidth_BEC=:ywidth_BEC,           zwidth_BEC=:zwidth_BEC
	NVAR xwidth_BEC_t0=:xwidth_BEC_t0,       ywidth_BEC_t0=:ywidth_BEC_t0,      zwidth_BEC_t0=:zwidth_BEC_t0
	NVAR AspectRatio_BEC_meas=:AspectRatio_BEC_meas,      AspectRatio_BEC_meas_t0=:AspectRatio_BEC_meas_t0
	NVAR amplitude_TF=:amplitude_TF,     number_BEC=:number_BEC,        number_TF=:number_TF
	NVAR chempot_TF=:chempot_TF

	// sigma=3*lambda^2/(2*pi*(1+satpar+4*detuning^2))      //cross-section, modulo... DETUNING IN LINEWIDTHS
	//sigma=3*lambda^2/(2*pi) ;     //cross-section, detuning and Isat are now included in the optical depth image
	//
	// We set sigma for each cam direction below.

	TFonly = ((fit_type == 3) || (fit_type == 5))
	
	// Compute the Castin Dum paramaters
	ComputeCastinDum();
	
	// Amplitude of the TF fit.
	amplitude_TF = (Gauss3d_coef[6])			
	
	// Now process the TF Fit data
	if(CamDir==1) 			// XY imaging
		sigma=3*lambda^2/(2*pi*(1+4*detuning^2));		// This imaging direction uses a sigma+ probe.
	
		if(traptype==2) 							// Dipole Trap  
			
			xposition = Gauss3d_coef[2]; 			// Cloud positions
			yposition = Gauss3d_coef[4];
			zposition = NAN; 	
					
			xrms = abs(Gauss3d_coef[3])*(!TFonly); // Widths of thermal component.
			yrms = abs(Gauss3d_coef[5])*(!TFonly);  
			zrms = ((xrms+yrms)/2)*(!TFonly);
			number = pi*(zeta3/zeta2)*(xrms*yrms*amplitude/sigma);						// Get number (polylog fit). zetas are approx. of Riemann zeta.
			temperature = (mass/(2*kB))*(zrms*0.001/expand_time)^2*10^9;
			density = amplitude / (sqrt(pi)*sigma*zrms);
			AspectRatio_meas = xrms/yrms; 
			
			xwidth_BEC = abs(Gauss3d_coef[7]);	// TF radii at TOF.
			ywidth_BEC = abs(Gauss3d_coef[8]);
			
			// calculate t=0 widths of the thermal component.
			xrms_t0 = xrms/sqrt(1+(omgX*expand_time*0.001)^2);    
	 		yrms_t0 = yrms/sqrt(1+(omgY*expand_time*0.001)^2);    
			zrms_t0 = zrms/sqrt(1+(omgZ*expand_time*0.001)^2);
			AspectRatio_meas_t0 = xrms_t0/yrms_t0;
			density_t0 = number/((xrms_t0*yrms_t0*zrms_t0)*pi^1.5);
			PSD = density_t0*10^18*(2*pi*hbar^2/(mass*kB*temperature))^1.5;
			
			number_BEC = 2*Pi*xwidth_BEC*ywidth_BEC*amplitude_TF/(5*sigma);	      			// absorption number.
			chempot = ((15*number_BEC*a_scatt/a_ho)^(2/5))*omg_ho/(4*pi);   			     // Chemical Potential
			
			xwidth_BEC_t0 = xwidth_BEC/CastDum_xscale;		  // Use the Castin-Dum scaling parameters to find the size in the trap.
			ywidth_BEC_t0 = ywidth_BEC/CastDum_yscale;  	  
			zwidth_BEC_t0 = sqrt(4*pi*hbar*chempot/(mass*omgZ^2))*10^6;  				 	  
			radius_TF_t0 = (xwidth_BEC_t0*ywidth_BEC_t0*zwidth_BEC_t0)^(1/3);
			zwidth_BEC = zwidth_BEC_t0*CastDum_zscale;
			AspectRatio_BEC_meas_t0 = xwidth_BEC_t0/ywidth_BEC_t0;
			AspectRatio_BEC_meas = xwidth_BEC/ywidth_BEC;
			
			//chempot = ((omg_ho/(4*pi))*((xwidth_BEC_t0*ywidth_BEC_t0*zwidth_BEC_t0)^(1/3)/a_ho)^2);   			     // Chemical Potential
			density_BEC = 15*number_BEC/(8*pi*xwidth_BEC*ywidth_BEC*zwidth_BEC);		// TOF density of BEC.
			density_BEC_t0 = 15*number_BEC/(8*pi*xwidth_BEC_t0*ywidth_BEC_t0*zwidth_BEC_t0);				     // t=0 BEC density
			
			// ************ Old stuff  is old ************
			// zwidth_BEC = CastDum_zscale*zwidth_BEC_t0;  	// use CastDum to go forward in time.
			// radius_TF_t0 =( (xwidth_BEC_t0+ywidth_BEC_t0)*AspectRatio_BEC^(1/3))/2   // average the two values
			// radius_TF = 0.5*(xwidth_BEC+ywidth_BEC)*(CastDum_zscale*AspectRatio_BEC/CastDum_xscale)^(1/3) //run back in time
			// AspectRatio_meas = NAN;
			// AspectRatio_meas_t0 = NAN;
			// AspectRatio_BEC_meas = xwidth_BEC/ywidth_BEC;
			// AspectRatio_BEC_meas_t0 = NAN;  				  // can't measure aspect ratios in XY direction
		
		elseif(traptype==1) 						// Quad
			Beep
			DoAlert 0, "You cannot get a BEC in the quad alone. Choose a Thermal 1D or 2D fit."
			return 0
		endif
		if(TFonly)
			temperature = 0; amplitude = 0;
			density = 0; density_t0 =0;
			PSD = NaN; number=NaN;
		endif
		// chempot = 0.5 * mass * (2*(0.001*xwidth_BEC)^2+ (0.001*ywidth_BEC)^2) / (3*expand_time^2);  // Not a bad guess since we do know the beam is isotropic
		// chempot /= 1.05e-34  * (2*pi);
	
	elseif (CamDir ==2) // XZ imaging
		sigma=3*lambda^2/(2*pi*(1+4*detuning^2));	// This direction uses a linearly polarized probe without a quantization axis.
												// Sr does not care about polarization because the ground state has no hyperfine structure.
		if (traptype==2) // Dipole
			xposition = Gauss3d_coef[2];xrms=abs(Gauss3d_coef[3])*(!TFonly);  // thermal properties, don't do if TFonly
			zposition = Gauss3d_coef[4];zrms=abs(Gauss3d_coef[5])*(!TFonly);  // thermal properties, don't do if TFonly
			yposition = NAN; yrms = (xrms+zrms)/2*(!TFonly);            							   // thermal properties
			AspectRatio_meas = zrms/xrms;    // set the measured thermal aspect ratio at t= texp
			number = pi*(zeta3/zeta2)*(xrms*zrms*amplitude/sigma);						// Get number (polylog fit). zetas are approx. of Riemann zeta.
			temperature = (mass/(2*kB))*(yrms*0.001/expand_time)^2*10^9;
			density = amplitude / (sqrt(pi)*sigma*yrms);

	 		// calculate t=0 widths of the thermal component.
			// undo the rotation relative to the trap axis at the same time
			xrms_t0 = xrms/sqrt((1+(omgX*expand_time*0.001)^2)*cos(pi*theta/180)^2+((omgX/omgY)^2)*(1+(omgY*expand_time*0.001)^2)*sin(pi*theta/180)^2);
			yrms_t0 = xrms_t0*omgX/omgY; 
			zrms_t0 = zrms/sqrt(1+(omgZ*expand_time*0.001)^2);    // run back in time using thermal expansion
			AspectRatio_meas_t0 = zrms_t0/xrms_t0;   // get the t=0 thermal aspect ratio
			density_t0 = number/((xrms_t0*yrms_t0*zrms_t0)*pi^1.5);
			PSD = density_t0*10^18*(2*pi*hbar^2/(mass*kB*temperature))^1.5;
			xrms = xrms_t0*sqrt(1+(omgX*expand_time*0.001)^2);
			yrms = yrms_t0*sqrt(1+(omgY*expand_time*0.001)^2);
			
			xwidth_BEC = abs(Gauss3d_coef[7]);
			zwidth_BEC = abs(Gauss3d_coef[8]);   // set the Thomas Fermi widths
			
			number_BEC = 2*Pi*xwidth_BEC*zwidth_BEC*amplitude_TF/(5*sigma);	      			// absorption number.
			xwidth_BEC_t0 = sqrt(2)*xwidth_BEC/sqrt((CastDum_Xscale^2)*(1+cos(2*Pi*theta/180))+((omgX*CastDum_Yscale/omgY)^2)*(1-cos(2*Pi*theta/180)));
			ywidth_BEC_t0 = xwidth_BEC_t0*(omgX/omgY);
			zwidth_BEC_t0 = zwidth_BEC/CastDum_Zscale;  // run back in time
			//xwidth_BEC_t0 = zwidth_BEC_t0*(omgZ/omgX);
			//ywidth_BEC_t0 = xwidth_BEC_t0*(omgX/omgY);
			xwidth_BEC = CastDum_Xscale*xwidth_BEC_t0;
			ywidth_BEC = CastDum_Yscale*ywidth_BEC_t0;
			AspectRatio_BEC_meas_t0 = zwidth_BEC_t0/xwidth_BEC_t0;  // calculated effectively by Castin Dum
			AspectRatio_BEC_meas = zwidth_BEC/xwidth_BEC;  // the aspect ratio is measurable
			
			chempot = ((15*number_BEC*a_scatt/a_ho)^(2/5))*omg_ho/(4*pi);   			     // Chemical Potential
			radius_TF_t0 = (xwidth_BEC_t0*zwidth_BEC_t0*ywidth_BEC_t0)^(1/3);
			radius_TF = (xwidth_BEC*zwidth_BEC*ywidth_BEC)^(1/3);
			
			density_BEC = 15*number_BEC/(8*pi*xwidth_BEC*ywidth_BEC*zwidth_BEC);		// TOF density of BEC.
			density_BEC_t0 = 15*number_BEC/(8*pi*xwidth_BEC_t0*ywidth_BEC_t0*zwidth_BEC_t0);				     // t=0 BEC density
			
		elseif(traptype==1) // Quad
			Beep
			DoAlert 0, "You cannot get a BEC in the quad alone. Choose a Thermal 1D or 2D fit."
			return 0
		endif
		amplitude_TF = Gauss3d_coef[6];
		if(TFonly)
			amplitude = 0; temperature = 0;
			density = 0;density_t0 = 0;
			PSD = NaN; number=NaN;
		endif
	endif
	
	// density_BEC_t0 = number_BEC*15/(8*Pi*radius_TF_t0^3)
	// number_BEC = number_BEC;
	//density_BEC = 3*amplitude_TF*(CastDum_zscale*AspectRatio_BEC/CastDum_rscale)^(1/3)/(4*sigma*radius_TF)

	number_TF = (a_ho/(15*a_scatt))*(radius_TF_t0/a_ho)^5; // clean up all those extra digits
	chempot_TF = omg_ho*(radius_TF_t0/a_ho)^2/(4*PI);
	
	// number=density*(pi)^(1.5)*(xrms*yrms*zrms)-density*2^3*(xrms*zrms)^(3/2)*(radius_TF/(xrms*zrms)^(1/2)-1/3*(radius_TF/(xrms*zrms)^(1/2))^3+1/10*(radius_TF/(xrms*zrms)^(1/2))^5-1/42*(radius_TF/(xrms*zrms)^(1/2))^7)^3
	// number=density*(pi)^(1.5)*(xrms*yrms*zrms)
	
	SetDataFolder fldrSav	
End
// ******************** TFUpdateCloudPars **************************************************************

// *************** ThermalUpdateCloudPars ***************************************************************
// This function takes the fit parameters from the thermal fitting routine and converts them into 
//  thermal atom cloud parameters.  Note that it does NOT assume that the cursor sits on the center		--CDH: does it? not anymore...
// of the cloud: it corrects for the fact that the cursor may not be on the center of the cloud.
// The supplied cursor/graphname must agree with the cross-sections that were used for the fit.
// This file takes in the fit coefficients and uses them to get number,temp,phase space density... etc.
// Gauss3D_coef[0] = Offset
// Gauss3D_coef[1] = Amplitude
// Gauss3D_coef[2] = Horizontal Position
// Gauss3D_coef[3] = Horizontal Width
// Gauss3D_coef[4] = Vertical Position
// Gauss3D_coef[5] = Vertical Width
Function ThermalUpdateCloudPars(Gauss3D_coef)	
	Wave Gauss3D_coef;

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	Variable sigma
	//Variable scalex, scaley,scalez

	// variables for the running indexed waves
	NVAR autoupdate=:IndexedWaves:autoupdate
	NVAR index=:IndexedWaves:index

	// experimental properties
	NVAR trapmin=:Experimental_Info:trapmin
	NVAR aspectratio=:Experimental_Info:aspectratio, moment=:Experimental_Info:moment
	NVAR omgX = :Experimental_Info:omgX;
	NVAR omgY = :Experimental_Info:omgY;
	NVAR omgZ = :Experimental_Info:omgZ;
	NVAR omgXLat = :Experimental_Info:omgXLat;
	NVAR omgYLat = :Experimental_Info:omgYLat;
	NVAR omgZLat = :Experimental_Info:omgZLat;
	NVAR aspectratio_BEC=:Experimental_Info:aspectratio_BEC
	NVAR detuning=:Experimental_Info:detuning,expand_time=:Experimental_Info:expand_time
	NVAR camdir=:Experimental_Info:camdir,traptype=:Experimental_Info:traptype
	NVAR magnification=:Experimental_Info:magnification
	NVAR IQuad=:Experimental_Info:IQuad
	NVAR flevel=:Experimental_Info:flevel
	NVAR mass=:Experimental_Info:mass
	NVAR a_scatt=:Experimental_Info:a_scatt
	NVAR theta=:Experimental_Info:theta
	NVAR k=:Experimental_Info:k
	
	// extracted information 
	NVAR chempot=:chempot, radius_TF=:radius_TF, radius_TF_t0=:radius_TF_t0
	NVAR density=:density, number=:number, absnumber=:absnumber,temperature=:temperature
	NVAR thoriz=:thoriz, tvert=:tvert
	NVAR xrms=:xrms, yrms=:yrms,zrms=:zrms
	NVAR xposition=:xposition, yposition=:yposition, zposition=:zposition
	NVAR AspectRatio_meas=:AspectRatio_meas,amplitude=:amplitude
	NVAR density_t0=:density_t0, xrms_t0=:xrms_t0, yrms_t0=:yrms_t0,zrms_t0=:zrms_t0
	NVAR absdensity_t0=:absdensity_t0, absdensity_BEC_t0=:absdensity_BEC_t0
	NVAR AspectRatio_meas_t0=:AspectRatio_meas_t0,density_BEC=:density_BEC,density_BEC_t0=:density_BEC_t0
	NVAR xwidth_BEC=:xwidth_BEC, ywidth_BEC=:ywidth_BEC,zwidth_BEC=:zwidth_BEC
	NVAR xwidth_BEC_t0=:xwidth_BEC_t0, ywidth_BEC_t0=:ywidth_BEC_t0,zwidth_BEC_t0=:zwidth_BEC_t0
	NVAR AspectRatio_BEC_meas=:AspectRatio_BEC_meas, AspectRatio_BEC_meas_t0=:AspectRatio_BEC_meas_t0
	NVAR amplitude_TF=:amplitude_TF,number_BEC=:number_BEC,number_TF=:number_TF
	NVAR Tc = :Tc, PSD=:PSD;
	
	// sigma=3*lambda^2/(2*pi*(1+satpar+4*detuning^2))      //cross-section, modulo... DETUNING IN LINEWIDTHS
	// sigma=3*lambda^2/(2*pi) ;     //cross-section, detuning and Isat are now included in the optical depth image
		
	// "amplitude" is used in density, and therefore, the number calculation!
	amplitude = Gauss3D_coef[1];	
	
	if(CamDir==1)              	// XY imaging
		xposition = Gauss3D_coef[2]; xrms=abs(Gauss3D_coef[3]);
		yposition = Gauss3D_coef[4]; yrms = abs(Gauss3D_coef[5]);
		zposition = NAN;
		sigma=3*lambda^2/(2*pi*(1+4*detuning^2)) ;              							// This imaging direction uses a sigma+ probe beam.
		
		if(traptype==1)    	  	// Quad only (Sr coils give 0.97 G/cm/A in z direction)
			zrms = (xrms+yrms)/2; 												// Assume width in 3rd direction is average of x,y; valid of long TOF.
			density = amplitude / (sqrt(pi)*sigma*zrms);								// Get image density.
			//number = pi*(zeta3/zeta2)*(xrms*zrms*amplitude/sigma);				// Get number (polylog fit). zetas are approx. of Riemann zeta.
			number = density*(pi)^(1.5)*(xrms*yrms*zrms);							// Get number (Gaussian fit).
			temperature = (mass/(2*kB))*(zrms*0.001/expand_time)^2;           			// Temp in K calculated from average width assuming long TOF.
			zrms_t0 = kB*temperature/(0.97/100*IQuad*muB/2)*10^6;			// Infer initial size in tight quad direction in um.
			xrms_t0 = zrms_t0*2;													// Sizes in weak direction are twice as big for a quad.
			yrms_t0 = xrms_t0;
			density_t0 = density*(pi^1.5)*xrms*yrms*zrms/(8*xrms_t0*yrms_t0*zrms_t0); // peak density in Quad
		elseif(traptype==2)	 // Dipole
			zrms = (xrms+yrms)/2;												//valid for sufficiently long TOF 
			density = amplitude / (sqrt(pi)*sigma*zrms);								// Get image density.
			//number = pi*(zeta3/zeta2)*(xrms*zrms*amplitude/sigma);				// Get number (polylog fit). zetas are approx. of Riemann zeta.
			number = density*(pi)^(1.5)*(xrms*yrms*zrms);							// Get number. (Gaussian fit)
			temperature = (mass/(2*kB))*((omgY*yrms*10^(-6))^2)/(1+(omgY*.001*expand_time)^2);           			// Temp in K calculated from average width assuming long TOF.
			xrms_t0 = sqrt(2*kB*temperature/(mass*omgX^2))*10^6;					// Initial size in transverse direction in um.
			yrms_t0 = sqrt(2*kB*temperature/(mass*omgY^2))*10^6;					// Initial size in longitudnal direction in um.
			zrms_t0 = sqrt(2*kB*temperature/(mass*omgZ^2))*10^6;
			density_t0 = number/((xrms_t0*yrms_t0*zrms_t0)*pi^1.5)					// Peak density in Quad+Dipole trap
			zrms =zrms_t0*sqrt(1+(omgZ*expand_time*0.001)^2);
			density = amplitude / (sqrt(pi)*sigma*zrms);								// Get better image density estimate.
			absdensity_t0 = absnumber/((xrms_t0*yrms_t0*zrms_t0)*pi^1.5);
		elseif(traptype==3)	// MOT
			zrms = (xrms+yrms)/2;
			temperature = (mass/(4*kB))*((xrms*0.001/(expand_time))^2+(yrms*0.001/(expand_time))^2);
			density = amplitude / (sqrt(pi)*sigma*zrms);	
			number = amplitude*(pi)^(1)*(xrms*yrms)/(sigma);	
		endif

		
	elseif(CamDir ==2)	 	// XZ imaging
		xposition = Gauss3D_coef[2];xrms=abs(Gauss3D_coef[3]);
		yposition = NAN; 
		zposition = Gauss3D_coef[4];zrms=abs(Gauss3D_coef[5]);
		sigma=3*lambda^2/(2*pi*(1+4*detuning^2));									// This imaging direction uses linearly polarized probe without a quantization axis.
		                                                                                                                     // Sr does not care about polarization because the ground state has no hyperfine structure.
				
		if(traptype==1) 		// Quad only (Sr coils give 0.97 G/cm/A in z direction)
			yrms = (zrms+xrms)/2;
			density = amplitude / (sqrt(pi)*sigma*yrms);	
			number = density*(pi)^(1.5)*(xrms*yrms*zrms);							
			temperature = (mass/(2*kB))*(yrms*0.001/expand_time)^2;				// Temp in K calculated from average width assuming long TOF.
			zrms_t0 = kB*temperature/(0.97/100*IQuad*muB/2)*10^6;			// Initial size in tight quad direction in um.
			xrms_t0 = zrms_t0*2;													// Sizes in weak direction are twice as big for a quad.
			yrms_t0 = xrms_t0; 
			density_t0 = density*(pi^1.5)*xrms*yrms*zrms/(8*xrms_t0*yrms_t0*zrms_t0) // peak density in Quad
		elseif(traptype==2) 	// Dipole
			yrms = (zrms+xrms)/2;
			density = amplitude / (sqrt(pi)*sigma*yrms);	
			number = density*(pi)^(1.5)*(xrms*yrms*zrms);
			temperature = (mass/(2*kB))*((omgZ*zrms*10^(-6))^2)/(1+(omgZ*.001*expand_time)^2);				// Temp in K calculated from average width assuming long TOF.
			// calculate t=0 widths of the thermal component.
			// undo the rotation relative to the trap axis at the same time
			xrms_t0 = xrms/sqrt((1+(omgX*expand_time*0.001)^2)*cos(pi*theta/180)^2+((omgX/omgY)^2)*(1+(omgY*expand_time*0.001)^2)*sin(pi*theta/180)^2);
			yrms_t0 = xrms_t0*omgX/omgY; 
			//xrms_t0 = sqrt(2*kB*temperature/(mass*omgX^2))*10^6;
			//yrms_t0 = sqrt(2*kB*temperature/(mass*omgY^2))*10^6;
			zrms_t0 = sqrt(2*kB*temperature/(mass*omgZ^2))*10^6;	
			density_t0 = number/((xrms_t0*yrms_t0*zrms_t0)*pi^1.5);					// Peak density in Dipole trap.
			xrms = xrms_t0*sqrt(1+(omgX*expand_time*0.001)^2);
			yrms = yrms_t0*sqrt(1+(omgY*expand_time*0.001)^2);
			density = number/((xrms*yrms*zrms)*pi^1.5);
			absdensity_t0 = absnumber/((xrms_t0*yrms_t0*zrms_t0)*pi^1.5);
		elseif(traptype==3)	// MOT
			yrms = (xrms+zrms)/2;
			temperature = (mass/(4*kB))*((xrms*0.001/(expand_time))^2+(zrms*0.001/(expand_time))^2);
			thoriz = (mass/(2*kB))*(xrms*0.001/expand_time)^2;
			tvert = (mass/(2*kB))*(zrms*0.001/expand_time)^2;
			density = amplitude / (sqrt(pi)*sigma*yrms);	
			number = amplitude*(pi)^(1)*(xrms*zrms)/(sigma);	
		elseif(traptype==6)     //Vertical 1D Lattice
			yrms = (xrms+zrms)/2;
			temperature = (mass/(4*kB))*(((omgZLat*zrms*10^(-6))^2)/(1+(omgZLat*.001*expand_time)^2)+((omgX*xrms*10^(-6))^2)/(1+(omgX*.001*expand_time)^2));
			thoriz = (mass/(2*kB))*((omgX*xrms*10^(-6))^2)/(1+(omgX*.001*expand_time)^2);
			tvert = (mass/(2*kB))*((omgZLat*zrms*10^(-6))^2)/(1+(omgZLat*.001*expand_time)^2);
			zrms_t0 = zrms/sqrt(1+(omgZLat*expand_time*0.001)^2);
			xrms_t0 = xrms/sqrt(1+(omgX*expand_time*0.001)^2);
			density = amplitude / (sqrt(pi)*sigma*yrms);	
			number = amplitude*(pi)^(1)*(xrms*zrms)/(sigma);	
			//Variable V_0 = getEffVol(temperature*(1e9));
			//absdensity_t0 = absnumber/V_0;
			//density_t0 = number/V_0;
		endif
	endif
	
	PSD = density_t0*10^18*(2*pi*hbar^2/(mass*kB*temperature))^1.5					// Phase space density at t=0
	temperature *= 1e9;
	thoriz *= 1e9;
	tvert *= 1e9;															// Temperature in nK.
	
	
	// Transition Temperature		--CDH: 31.Jan.2012: this is only expressly true just at Tc (where number=Nc)
	//	Tc = (number / 1.2)^(1/3) * hbar * (omgX * omgY * omgZ)^(1/3) / (1.38e-32);

	// Paramaters from Thoms-Fermi fits.
	xwidth_BEC = NAN; ywidth_BEC = NAN; zwidth_BEC = NAN;
	xwidth_BEC_t0=NAN; ywidth_BEC_t0 = NAN; zwidth_BEC_t0 = NAN;
	amplitude_TF = NAN; number_BEC = NAN; number_TF = NAN;
	chempot = NAN; radius_TF = NAN; radius_TF_t0 = NAN;
	density_BEC = NAN; density_BEC_t0 = NAN; absdensity_BEC_t0=NAN;

	SetDataFolder fldrSav	
End
// ******************** ThermalUpdateCloudPars *****************************************************************************

// ***********************UpdateWaves **********************************************************************
// * this function updates the running waves of temperature/ density/ number etc.
Function UpdateWaves()

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	SVAR FileName = :Experimental_Info:FileName;

	NVAR index=:IndexedWaves:index;
	NVAR autoupdate=:IndexedWaves:autoupdate;
	Wave/T FileNames = :IndexedWaves:FileNames
	
	if  (autoupdate)
		Update_IndexedWaves();
	
		// The autoIndexing doesn't yet support text waves :(
		if (Index >= numpnts(LocalIndexedWave))
			redimension/N=(Index +1) FileNames;
		endif
		FileNames[Index] = FileName;
	
		if  (autoupdate == 1)
			index += 1
		endif
	endif 	
	SetDataFolder fldrSav
end

//********************************************************************************************************************
// Definition of fitting funtions for thermal and thomas fermi fits in 1 and 2D

Function Thermal_2D(w,x,z) : FitFunc
	Wave w
	Variable x
	Variable z

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,z) = offset + Atherm*exp(-((x-x0)/xrmstherm)^2-((z-z0)/(zrmstherm))^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ z
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = Atherm
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = xrmstherm
	//CurveFitDialog/ w[4] = z0
	//CurveFitDialog/ w[5] = zrmstherm

	return w[0] + w[1]*exp(-((x-w[2])/w[3])^2-((z-w[4])/(w[5]))^2);
End

Function TF_1D(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = offset + A*( exp(-((x - x0)/sigma_t)^2) ) + B *( ((x-x0)^2)<RTF^2?  (1- ((x - x0)/RTF)^2)^(3/2):0 )
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = sigma_t
	//CurveFitDialog/ w[4] = B
	//CurveFitDialog/ w[5] = RTF
	
	return w[0] + w[1]*( exp(-((x - w[2])/w[3])^2) ) + w[4] *( ((x-w[2])^2)<w[5]^2?  (1- ((x - w[2])/w[5])^2)^(3/2):0 )
End


Function TF_2D(w,x,z) : FitFunc
	Wave w
	Variable x
	Variable z

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,z) = offset + Atherm*exp(-((x-x0)/xrmstherm)^2-((z-z0)/(zrmstherm))^2) + ATF*(((z-z0)/(RZ_TF))^2+((x-x0)*(aspect_TF/RZ_TF))^2<1?(1-((z-z0)/(RZ_TF))^2-((x-x0)*(aspect_TF/RZ_TF))^2)^3/2:0)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ z
	//CurveFitDialog/ Coefficients 9
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = Atherm
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = xrmstherm
	//CurveFitDialog/ w[4] = z0
	//CurveFitDialog/ w[5] = z rmstherm // disabeled
	//CurveFitDialog/ w[6] = ATF
	//CurveFitDialog/ w[7] = Rx_TF
	//CurveFitDialog/ w[8] = Rz_TF
	
	duplicate/O w w_therm ; w_therm[5] = w[2]; // The TF2D fit assumes that the X and Y widths are the same
	
	return Thermal_2d(w_therm,x,z) + w[6]*( ( (z-w[4])/(w[8]) )^2+((x-w[2])/(w[7]))^2<1?(1-( (z-w[4])/(w[8]) )^2-( (x-w[2])/(w[7]) )^2)^(3/2):0)
End

Function TriGauss_2D(w,x,z) : FitFunc
	Wave w
	Variable x
	Variable z

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,z) = offset + Atherm*exp(-((x-x0)/xrmstherm)^2-((z-z0)/(zrmstherm))^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ z
	//CurveFitDialog/ Coefficients 8
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = AmpCenter
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = xrmstherm
	//CurveFitDialog/ w[4] = z0
	//CurveFitDialog/ w[5] = zrmstherm
	//CurveFitDialog/ w[6] = AmpSide
	//CurveFitDialog/ w[7] = PeakSep

	return w[0] + w[1]*exp(-((x-w[2])/w[3])^2-((z-w[4])/(w[5]))^2) + w[6]*(exp(-((x-w[2])/w[3])^2-((z-w[4]-w[7])/(w[5]))^2) + exp(-((x-w[2])/w[3])^2-((z-w[4]+w[7])/(w[5]))^2));
End


// parameter w[4] is the hbar*k momentum converted into position units and must be computed and held for fitting
Function BandMap_1D(w,x,z) : FitFunc
	Wave w
	Variable x
	Variable z

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x,z) = offset + exp(-((x-x0)/xrmstherm)^2)*((((z-z0) <= hbk) && ((z-z0) >= -hbk)) ? Agband*exp(-2*BetaJ0*(1-cos(pi*(z-z0)/hbk))) : (((((z-z0) <= 2*hbk) && ((z-z0) > hbk)) || (((z-z0) >= -2*hbk) && ((z-z0) < -hbk))) ? Aeband*exp(-2*BetaJ1*(1-cos(pi*(z-z0/hbk))) : 0));
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ z
	//CurveFitDialog/ Coefficients 9
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = Agband
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = xrmstherm
	//CurveFitDialog/ w[4] = z0
	//CurveFitDialog/ w[5] = hbk
	//CurveFitDialog/ w[6] = BetaJ0
	//CurveFitDialog/ w[7] = Aeband
	//CurveFitDialog/ w[8] = BetaJ1 

	return w[0] + exp(-((x-w[2])/w[3])^2)*((((z-w[4]) <= w[5]) && ((z-w[4]) >= -w[5])) ? w[1]*exp(-2*w[6]*(1-cos(pi*(z-w[4])/w[5]))) : (((((z-w[4]) <= 2*w[5]) && ((z-w[4]) > w[5])) || (((z-w[4]) >= -2*w[5]) && ((z-w[4]) < -w[5]))) ? w[7]*exp(-2*w[8]*(1-cos(pi*(z-w[4])/w[5]))) : 0));
End

// ******* IntegrateROI ****************************************************************************************
// 
//	- 
Function PI_IntegrateROI(inputimage)
	Wave inputimage
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	Variable sigma

	// experimental information 
	NVAR detuning=:Experimental_Info:detuning
	
	// extracted cloud parameters
	NVAR chempot=:chempot,     radius_TF=:radius_TF,       radius_TF_t0=:radius_TF_t0
	NVAR density=:density,    number=:number,      temperature=:temperature
	NVAR xrms=:xrms,       yrms=:yrms,         zrms=:zrms
	NVAR xposition=:xposition,        yposition=:yposition,         zposition=:zposition
	NVAR AspectRatio_meas=:AspectRatio_meas,            amplitude=:amplitude
	NVAR density_t0=:density_t0,       xrms_t0=:xrms_t0,        yrms_t0=:yrms_t0,        zrms_t0=:zrms_t0
	NVAR AspectRatio_meas_t0=:AspectRatio_meas_t0,     density_BEC=:density_BEC,      density_BEC_t0=:density_BEC_t0
	NVAR xwidth_BEC=:xwidth_BEC,       ywidth_BEC=:ywidth_BEC,           zwidth_BEC=:zwidth_BEC
	NVAR xwidth_BEC_t0=:xwidth_BEC_t0,       ywidth_BEC_t0=:ywidth_BEC_t0,      zwidth_BEC_t0=:zwidth_BEC_t0
	NVAR AspectRatio_BEC_meas=:AspectRatio_BEC_meas,      AspectRatio_BEC_meas_t0=:AspectRatio_BEC_meas_t0
	NVAR amplitude_TF=:amplitude_TF,     number_BEC=:number_BEC,        number_TF=:number_TF

	
	NVAR ymax=:fit_info:ymax, ymin=:fit_info:ymin	
	NVAR xmax=:fit_info:xmax, xmin=:fit_info:xmin
	Variable offset, delta;
	Variable xvals, yvals;
	Variable i,j,avrg,intgrl;

	Make/O/N=512 xwave, ywave;

	offset = DimOffset(inputimage,0);
	delta = DimDelta(inputimage,1);
	
	ymax = (ymax - offset)/delta;
	ymin = (ymin - offset)/delta;
	xmax = (xmax - offset)/delta;
	xmin = (xmin - offset)/delta;
	
	xvals = xmax - xmin + 1;
	yvals = ymax - ymin + 1;
	
	avrg = 0;
	
	xwave[0,xvals] = inputimage[xmin+p][ymin];
	WaveStats/Q/R=[1,xvals] xwave;
	avrg += V_avg;
	ywave[0,yvals] = inputimage[xmin][ymin+p];
	WaveStats/Q/R=[1,yvals] ywave;
	avrg = avrg + V_avg;	
	xwave[0,xvals] = inputimage[xmin+p][ymax];
	WaveStats/Q/R=[1,xvals] xwave;
	avrg = avrg + V_avg;
	ywave[0,yvals] = inputimage[xmax][ymin+p];
	WaveStats/Q/R=[1,yvals] ywave;
	avrg = avrg + V_avg;	
	
	avrg /= 4;
		
	intgrl = 0;
	
	for(i=xmin;i<=xmax;i+=1)
		for(j=ymin;j<=ymax;j+=1)
			intgrl += inputimage[i][j] - avrg;
		endfor
	endfor

	// sigma=3*lambda^2/(2*pi*(1+satpar+4*detuning^2))      //cross-section, modulo... DETUNING IN LINEWIDTHS
	sigma=3*lambda^2/(2*pi) ;     //cross-section, detuning and Isat are now included in the optical depth image

	// extracted cloud parameters
	chempot=nan;  radius_TF=nan;  radius_TF_t0=nan; density=nan;  temperature=nan;  xrms=nan;  
	yrms =nan;  zrms=nan;  xposition=nan;  yposition=nan;  zposition=nan;  AspectRatio_meas=nan;              
	amplitude=nan;  density_t0=nan;        xrms_t0=nan;         yrms_t0=nan;        zrms_t0=nan; 
	AspectRatio_meas_t0=nan;      density_BEC=nan;      density_BEC_t0=nan; 
	xwidth_BEC=nan;        ywidth_BEC=nan;            zwidth_BEC=nan; 
	xwidth_BEC_t0=nan;       ywidth_BEC_t0=nan;       zwidth_BEC_t0=nan; 
	AspectRatio_BEC_meas=nan;      AspectRatio_BEC_meas_t0=nan; 
	amplitude_TF=nan;    number_BEC=nan;        number_TF=nan; 

	number=delta*delta*intgrl/sigma;
	SetDataFolder fldrSav	
End
// ******************** IntegrateROI **************************************************************************

// ******************** MakeSlice **************************************************************************
// This function makes several slices from the current optdepth image
///
// 	xslice :from passed csr
//	yslice :from passed csr
//	slice  :from between the cursors

Function Call_MakeSlice(ctrlName) : ButtonControl
	String ctrlName

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	Wave inputimage = :optdepth

	MakeSlice(inputimage,"F")

	SetDataFolder fldrSav	
End

Function MakeSlice(inputimage,cursorname)
	Wave inputimage
	String cursorname
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder

	// Discover the name of the current image window
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String ImageWindowName = CurrentPanel + "#ColdAtomInfoImage";

	NVAR width = :Fit_Info:slicewidth
	Wave slice = :LineProfiles:slice

	Make/O/N=2 :Fit_Info:xpts, :Fit_Info:ypts
	Wave xpts = :Fit_Info:xpts
	Wave ypts = :Fit_Info:ypts
	
	Make/O/N=1 W_imageLineProfile;
	Wave W_imageLineProfile = W_imageLineProfile;

	// **************************************************
	// Make the diagional Slice
	variable DimWidth;
	xpts = {hcsr(A,ImageWindowName),hcsr(B,ImageWindowName)}
	ypts = {vcsr(A,ImageWindowName),vcsr(B,ImageWindowName)}
	ImageLineProfile  xWave=xpts, yWave=ypts, srcwave= inputimage , width = width

	duplicate /O W_imageLineProfile slice
	
	// Igor normalizes, but I want the true number of counts 
	slice = slice * 2*(width+0.5)
	DimWidth = sqrt((xpts[0]-xpts[1])^2 + (ypts[0]-ypts[1])^2) / 2
	SetScale/I x -Dimwidth,Dimwidth, "", slice

	KillWaves W_imageLineProfile, xpts, ypts;
	
	// **************************************************
	// Make the vert and horz slices

	Wave xsec_col=:Fit_Info:xsec_col, xsec_row=:Fit_Info:xsec_row;
	Wave fit_xsec_col=:Fit_Info:fit_xsec_col, fit_xsec_row=:Fit_Info:fit_xsec_row;
	variable i = 0;


	// **************************************************
	// define the 1-D crosssections
	// This creates a slice of the data centered on the selected cursor,
	// with width neighboring collums averaged.		
	xsec_col = 0; xsec_row = 0;

	for(i = -floor((width-1)/2) ; i<= floor(width/2); i+=1)
		xsec_col = xsec_col + inputimage[pcsr($cursorname,ImageWindowName)+i][p]
	endfor
	xsec_col = xsec_col/width;

	for(i = -floor((width-1)/2) ; i<= floor(width/2); i+=1)
		xsec_row = xsec_row + inputimage[p][qcsr($cursorname,ImageWindowName)+i]
	endfor
	xsec_row = xsec_row/width;
	
	SetDataFolder fldrSav
End
// ******************** MakeSlice **************************************************************************



// ******************** CropImage **************************************************************************
// Crops  or expands an image to the specified bounds (pixel locations).  --CDH: Not called by anything.
// Perhaps I will add another flag after the y1 to declare what type of  crop is done (pixel based or scaled point based).
Function CropImage(Image, x0, y0, x1, y1)
	Wave image;
	variable x0, y0, x1, y1;


	// Points properly ordered if needed
	Variable xmin, xmax, ymin, ymax;	
	xmin = min(x0, x1);
	xmax = max(x0, x1);
	ymin = min(y0, y1);
	ymax = max(y0, y1);

	duplicate/FREE Image CropImage_Internal
	redimension/N=(xmax-xmin+1, ymax-ymin+1) Image; // points are inclusive, so add one
	
	Image = CropImage_Internal[p+xmin][q+ymin];
	
	// Now get the scaling right
	// center the graph at zero.
	setscale/P x -DimDelta(Image, 0) * (xmax-xmin)/2, DimDelta(Image, 0),  Image
	setscale/P y -DimDelta(Image, 1) * (ymax-ymin)/2, DimDelta(Image, 1),  Image
	
	return 0
End
// ******************** CropImage **************************************************************************


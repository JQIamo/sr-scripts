#pragma rtGlobals=1		// Use modern global access method.

//Constant kB = 1.38e-23
//Constant mass = 1.4467e-25		//These constants are already in RbProcedures.
//Constant labmda = 0.7802
Constant zeta3_2 = 2.61238
Constant zeta2 = 1.64493
Constant zeta5_2 = 1.34149
Constant zeta3 = 1.20206

// -----------------------------
//    Proper Thermal Fit Functions (mu=0)
//-----------------------------
// Igor does not support the polylogarithm function.
//     We have made a 1024 point wave (PolyLog2Gaussian.ibw) 
//        in dimensionless variable (x/width) on [-5,5] (xwave is xPolyLog.ibw)
//        from which to interpolate PolyLog[2,x] (in Mathematica syntax).
//     -- 18 Jan 2012 -CDH

//     This is the appropriate function for a slice of an absorption image.
Function ThermalSliceFit(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = A*Interp(x/wx,xWave,yWave)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = wx

	//CheckPolylog();		// ensure polylog lookups are present

	Wave xWave = root:polylog:xPolyLog
	Wave yWave = root:polylog:PolyLog2GaussianNorm

	return w[0]+w[1]*Interp((x-w[2])/w[3],xWave,yWave)
End


//     Use this function to fit the line profile obtained after integrating over one direction
//            of an absorption image (PolyLog[5/2, gaussian] in Mathematica syntax).
//     -- 18 Jan 2012 -CDH
Function ThermalIntFit(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = A*Interp(x/wx,xWave,yWave)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = y0
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = wx

	//CheckPolylog();		// ensure polylog lookups are present
	
	Wave xWave = root:polylog:xPolyLog
	Wave yWave = root:polylog:PolyLog5_2GaussianNorm

	return w[0]+w[1]*Interp((x-w[2])/w[3],xWave,yWave)
End


Function g2TF_1D(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = offset + A*( exp(-((x - x0)/sigma_t)^2) ) + ATF*( ((x-x0)^2)<RTF^2?  (1- ((x - x0)/RTF)^2)^(3/2):0 )
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = Ath
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = xw_th
	//CurveFitDialog/ w[4] = ATF
	//CurveFitDialog/ w[5] = RTF

	//CheckPolylog();		// ensure polylog lookups are present
		
	Wave xWave = root:polylog:xPolyLog
	Wave yWave = root:polylog:PolyLog2GaussianNorm
	
	return w[0]+w[1]*Interp((x-w[2])/w[3],xWave,yWave)+w[4]*( ((x-w[2])^2)<w[5]^2?  (1-((x-w[2])/w[5])^2)^(3/2) : 0 )
End

// thermal (dilogarithm) + TF fit with independent positions
Function g2TF_1D_free(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ //CheckPolylog();		// ensure polylog lookups are present
	//CurveFitDialog/ 
	//CurveFitDialog/ 	
	//CurveFitDialog/ Wave xWave = root:Packages:polylog:xPolyLog
	//CurveFitDialog/ Wave yWave = root:Packages:polylog:PolyLog2GaussianNorm
	//CurveFitDialog/ 
	//CurveFitDialog/ // Choose w[6] for additional position to prevent conflict with existing code.
	//CurveFitDialog/ 
	//CurveFitDialog/ f(x) = offset+Ath*Interp((x-x0_th)/w_th,xWave,yWave)+ATF*( ((x-x0_TF)^2)<RTF^2?  (1-((x-x0_TF)/RTF)^2)^(3/2) : 0 )
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = Ath
	//CurveFitDialog/ w[2] = x0_th
	//CurveFitDialog/ w[3] = w_th
	//CurveFitDialog/ w[4] = ATF
	//CurveFitDialog/ w[5] = RTF
	//CurveFitDialog/ w[6] = x0_TF

	//CheckPolylog();		// ensure polylog lookups are present
	
		
	Wave xWave = root:polylog:xPolyLog
	Wave yWave = root:polylog:PolyLog2GaussianNorm
	
	// Choose w[6] for additional position to prevent conflict with existing code.
	
	return w[0]+w[1]*Interp((x-w[2])/w[3],xWave,yWave)+w[4]*( ((x-w[6])^2)<w[5]^2?  (1-((x-w[6])/w[5])^2)^(3/2) : 0 )
End

//     This is the appropriate function for a thermal-subtracted slice of an absorption image.
Function TFonlySliceFit(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = offset + ATF*( ((x-x0)^2)<RTF^2?  (1- ((x - x0)/RTF)^2)^(3/2):0 )
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = ATF
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = RTF

	return w[0]+w[1]*( (x-w[2])^2 < w[3]^2 ? (1 - ((x-w[2])/w[3])^2)^(3/2) : 0 )
End

// We'll make a folder (root:Packages:polylogs) to contain the lookup waves.
//		This function checks that the waves are there, and prompts the user 
//		to locate them if they are not.
Function CheckPolylog()
	
	// set path to top experiment folder, saving present folder
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
	// Assuming the user has not created the 'root:Packages:polylog:' folder, 
	//     if the folder is there, return. Otherwise make it and load waves.
	if (DataFolderExists("root:Packages:polylog"))
		//print "polylog folder found."
		return 1
	else
		NewDataFolder/S root:Packages:polylog
		LoadWave/H/P=RbYb_User_Procedures ":polylog fits:xPolyLog.ibw"
		LoadWave/H/P=RbYb_User_Procedures ":polylog fits:Polylog2GaussianNorm.ibw"
		LoadWave/H/P=RbYb_User_Procedures ":polylog fits:Polylog5_2GaussianNorm.ibw"
	endif
	
	//return path
	SetDataFolder fldrSav
	return 1
End








// Suspecting that bimodal fits are skewing the extracted temperatures,
//   we will implement a fit to the wings of the thermal distribution.
//      --CDH 24.Jan.2012
//
//   The fitting procedure is as follows:
//      (1) bimodal fit to obtain reasonable guesses (retuires good TF+Thermal 1D fit from panel)
//      (2) Create mask whose width = f*RTF, fraction TBD
//      (3) fit wings to polylog g2
//      (4) Subtract thermal from slice, fit remainder with TF.
//
//   Fit info is stored in ":<ExpFolder>:polyfits" to distinguish it from the standard results.
Function WingFit(filenum, fMask)
	Variable filenum, fMask
	
	//Variable fMask=1.5;  //proportion of RTF to exclude from thermal fit
	
	
	// Assume basePath already set appropriately for BatchRun to load an image.
	BatchRun(filenum, filenum,0,"")
	
	// set path to top experiment folder, saving present folder
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1)
	SetDataFolder ProjectFolder
	
// (1) Compute Initial Guesses ---------------------------------------------------------------------
	// Correct Magnification and refit w/ old procedures to get initial guesses
	NVAR mag=:Experimental_Info:magnification
	mag=2.9; Update_Magnification()
	AbsImg_AnalyzeImage(optdepth)
	
	// Initial (bimodal) guesses are now stored in :Fit_Info:TF_*_coef:
	//   [0] offset
	//   [1] thermal amplitude
	//   [2] position
	//   [3] thermal width
	//   [4] TF amplitude
	//   [5] TF radius
	WAVE TF_ver_coef=:Fit_Info:TF_ver_coef
	WAVE TF_hor_coef=:Fit_Info:TF_hor_coef
// (1) End ---------------------------------------------------------------------------------------------------	

	// Needed waves
	WAVE vSlice=:Fit_Info:xsec_col
	WAVE hSlice=:Fit_Info:xsec_row
	
	// Mask and (bimodal minus thermal fit) waves
	Duplicate/O vSlice, :polyfits:vmask, :polyfits:vsub, :polyfits:g2v_fit, :polyfits:TFv_fit, :polyfits:vSum_fit
	Duplicate/O hSlice, :polyfits:hmask, :polyfits:hsub, :polyfits:g2h_fit, :polyfits:TFh_fit, :polyfits:hSum_fit
	WAVE vMask=:polyfits:vmask, vSub=:polyfits:vsub, g2v_fit=:polyfits:g2v_fit, TFv_fit=:polyfits:TFv_fit, vSum_fit=:polyfits:vSum_fit
	WAVE hMask=:polyfits:hmask, hSub=:polyfits:hsub, g2h_fit=:polyfits:g2h_fit, TFh_fit=:polyfits:TFh_fit, hSum_fit=:polyfits:hSum_fit
	g2v_fit=NaN; g2h_fit=NaN; TFv_fit=NaN; TFh_fit=NaN; vSum_fit=NaN; hSum_fit=NaN;
	 
	// Coefficient waves. For each we fit:
	//    [0] offset
	//    [1] amplitude
	//    [2] position
	//    [3] width
	Make/D/O/N=4 :polyfits:g2vcoef
	Duplicate/O :polyfits:g2vcoef, :polyfits:g2hcoef, :polyfits:TFvcoef, :polyfits:TFhcoef
	WAVE g2vcoef=:polyfits:g2vcoef, g2hcoef=:polyfits:g2hcoef
	WAVE TFvcoef=:polyfits:TFvcoef, TFhcoef=:polyfits:TFhcoef
	
	// Check if AuxSlices plot exists
	DoWindow AuxSlices	
	if (V_flag != 1)
		AuxSlicesPlot()	// Make window if it doesn't exist
	endif
	DoWindow/F AuxSlices	// Bring window to front.
	
// (2) Create Mask Wave ---------------------------------------------------------------
	// exclusion width is multible of RTF
	Variable wMask=fMask*TF_ver_coef[5]
	vMask[x2pnt(vMask,TF_ver_coef[2]-wMask), x2pnt(vMask,TF_ver_coef[2]+wMask)] = NaN;
	wMask=fMask*TF_hor_coef[5]
	hMask[x2pnt(hMask,TF_hor_coef[2]-wMask), x2pnt(hMask,TF_hor_coef[2]+wMask)] = NaN;
// (2) End -------------------------------------------------------------------------------------

// (3) fit wings to polylog g2 -----------------------------------------------------------
	// suppress fit window
	Variable V_FitOptions=4
	
	//initial guesses (first four are thermal guesses):
	g2vcoef=TF_ver_coef; g2hcoef=TF_hor_coef
	// do vert wings fit
	FuncFit/N/Q ThermalSliceFit, g2vcoef, vSlice /M=vMask/D=g2v_fit
	g2v_fit=ThermalSliceFit(g2vcoef,x)
	// and horizontal:
	FuncFit/N/Q ThermalSliceFit, g2hcoef, hSlice /M=hMask/D=g2h_fit
	g2h_fit=ThermalSliceFit(g2hcoef,x)
// (3) End -------------------------------------------------------------------------------------

// (4) Subtract thermal from slice, fit remainder with TF --------------------
	// calculate subtracted profiles and display
	vSub-=g2v_fit; hSub-=g2h_fit
	
	// Check if SubSlices plot exists
	DoWindow SubSlices	
	if (V_flag != 1)
		SubSlicesPlot()	// Make window if it doesn't exist
	endif
	DoWindow/F SubSlices	// Bring window to front.
	
	// take initial guesses from panel-fit
	TFvcoef[0]=0; TFvcoef[1]=TF_ver_coef[4]; TFvcoef[2]=TF_ver_coef[2]; TFvcoef[3]=TF_ver_coef[5]
	TFhcoef[0]=0; TFhcoef[1]=TF_hor_coef[4]; TFhcoef[2]=TF_hor_coef[2]; TFhcoef[3]=TF_hor_coef[5]
	
	// do vertical fit
	FuncFit/N/Q TFonlySliceFit, TFvcoef, vSub /D=TFv_fit
	// and horizontal fit
	FuncFit/N/Q TFonlySliceFit, TFhcoef, hSub /D=TFh_fit
// (4) End -------------------------------------------------------------------------------------	
	
	// update sum_fit waves
	vSum_fit=g2v_fit+TFv_fit; hSum_fit=g2h_fit+TFh_fit
	
	//return path
	SetDataFolder fldrSav
End
// End function WingFit ------------------------------------------------------------------------------------------------------------------------


// Makes an auxilary slices graph, assuming path is top experiment.
Function AuxSlicesPlot()
	PauseUpdate; Silent 1
	Display /N=AuxSlices/W=(331.5,43.25,699,317)/T :Fit_Info:xsec_row
	AppendToGraph :Fit_Info:xsec_col, :polyfits:g2h_fit, :polyfits:g2v_fit
	AppendToGraph :polyfits:hSum_fit, :polyfits:vSum_fit
	ModifyGraph wbRGB=(52224,52224,52224)
	ModifyGraph mode=0, mode(xsec_row)=2, mode(xsec_col)=2
	ModifyGraph marker=19
	ModifyGraph lSize=1.5, lSize(hSum_fit)=1, lSize(vSum_fit)=1
	ModifyGraph rgb(xsec_row)=(65280,0,0),rgb(xsec_col)=(0,0,65280)
	ModifyGraph rgb(g2h_fit)=(0,0,0), rgb(g2v_fit)=(0,52224,0), rgb(hSum_fit)=(0,0,0),rgb(vSum_fit)=(0,52224,0)
	ModifyGraph offset(xsec_row)={0,0.5},offset(g2h_fit)={0,0.5}, offset(hSum_fit)={0,0.5}
	ModifyGraph tick=2
	ModifyGraph mirror(left)=1
	ModifyGraph lblMargin(left)=12,lblMargin(bottom)=9
	ModifyGraph standoff=0
	ModifyGraph tlblRGB(top)=(65280,0,0),tlblRGB(bottom)=(0,0,65280)
	ModifyGraph lblLatPos(bottom)=-1
	Label left "Optical depth"; Label bottom "position [um]"
	SetAxis top -630,630; SetAxis bottom -630,630; SetAxis left -0.2,3.5
	Legend/C/N=text0/J/A=LT "\\s(xsec_row) xsec_row\r\\s(xsec_col) xsec_col\r\\s(g2h_fit) g2h_fit, hSum_fit\r\\s(g2v_fit) g2v_fit, vSum_fit"
End

Function SubSlicesPlot()
	PauseUpdate; Silent 1
	Display /N=SubSlices/W=(331.5,343.25,699,602.75)/T :polyfits:hsub
	AppendToGraph :polyfits:vsub, :polyfits:TFh_fit, :polyfits:TFv_fit
	ModifyGraph wbRGB=(52224,52224,52224)
	ModifyGraph mode(hsub)=2,mode(vsub)=2
	ModifyGraph marker=19
	ModifyGraph lSize=1.5
	ModifyGraph rgb(hsub)=(65280,0,0),rgb(vsub)=(0,0,65280),rgb(TFh_fit)=(0,0,0),rgb(TFv_fit)=(0,52224,0)
	ModifyGraph offset(hsub)={0,0.5},offset(TFh_fit)={0,0.5}
	ModifyGraph tick=2
	ModifyGraph mirror(left)=1
	ModifyGraph lblMargin(left)=12,lblMargin(bottom)=9
	ModifyGraph standoff=0
	ModifyGraph tlblRGB(top)=(65280,0,0),tlblRGB(bottom)=(0,0,65280)
	ModifyGraph lblLatPos(bottom)=-1
	Label left "Optical depth"
	Label bottom "position [um]"
	SetAxis left -0.2,3
	SetAxis top -630,630
	SetAxis bottom -630,630
	Legend/C/N=text0/J/A=LT "\\s(hsub) hsub\r\\s(vsub) vsub\r\\s(TFh_fit) TFh_fit\r\\s(TFv_fit) TFv_fit"
End


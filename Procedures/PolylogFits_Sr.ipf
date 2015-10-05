#pragma rtGlobals=1		// Use modern global access method.
//! @file
//! @brief Implements poly-logarithm which is not built into Igor

//Constant kB = 1.38e-23
//Constant mass = 1.4467e-25		//These constants are already in RbProcedures.
//Constant labmda = 0.7802
Constant zeta3_2 = 2.61238 //!< \f$\zeta(3/2)\f$ (Riemann Zeta of 3/2)
Constant zeta2 = 1.64493   //!< \f$\zeta(2)\f$ (Riemann Zeta of 2)
Constant zeta5_2 = 1.34149 //!< \f$\zeta(5/2)\f$ (Riemann Zeta of 5/2)
Constant zeta3 = 1.20206   //!< \f$\zeta(3)\f$ (Riemann Zeta of 3)

// -----------------------------
//    Proper Thermal Fit Functions (mu=0)
//-----------------------------
//!
//! @brief This is the appropriate function for a slice of an absorption image.
//! @details Igor does not support the polylogarithm function.
//!    We have made a 1024 point wave (PolyLog2Gaussian.ibw) 
//!        in dimensionless variable (x/width) on [-5,5] (xwave is xPolyLog.ibw)
//!        from which to interpolate PolyLog[2,x] (in Mathematica syntax).
//!     -- 18 Jan 2012 -CDH
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


//!
//! @brief Use this function to fit the line profile obtained after integrating over one direction
//!           of an absorption image
//! @details (PolyLog[5/2, gaussian] in Mathematica syntax).
//!    -- 18 Jan 2012 -CDH
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


//!
//! @brief thermal (dilogarithm) + TF fit
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

//!
//! @brief thermal (dilogarithm) + TF fit with independent positions
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

//!
//! @brief This is the appropriate function for a thermal-subtracted slice of an absorption image.
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

//!
//! @brief Checks for polylog waves in the correct location
//! @details We'll make a folder (root:Packages:polylogs) to contain the lookup waves.
//!		This function checks that the waves are there, and prompts the user 
//!		to locate them if they are not.
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







//!
//! @brief fit to the wings of the thermal distribution
//! @details Suspecting that bimodal fits are skewing the extracted temperatures,
//!   we will implement a fit to the wings of the thermal distribution.
//!      --CDH 24.Jan.2012
//!
//!   The fitting procedure is as follows:
//!      (1) bimodal fit to obtain reasonable guesses (retuires good TF+Thermal 1D fit from panel)
//!      (2) Create mask whose width = f*RTF, fraction TBD
//!      (3) fit wings to polylog g2
//!      (4) Subtract thermal from slice, fit remainder with TF.
//!
//!   Fit info is stored in ":<ExpFolder>:polyfits" to distinguish it from the standard results.
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


//!
//! @brief Makes an auxiliary slices graph, assuming path is top experiment.
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

//!
//! @brief Makes an auxiliary slices subplot, assuming path is top experiment.
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

Function DiLogApprox(z)
//Approximation for di-logarithm (polylog of order 2)
//Based on matlab procedure by Didier Clamond
//Computes Li_2 (z)

	//Initialize:
	Variable z;
	Variable d = 0;
	Variable s = 1
	
	if (z == 1)
		return pi^2/6;
	endif
	
	//For large moduli, map onto unit circle |z| <= 1
	if (abs(z)>1)
		d = -1.64493406684822643 - 0.5*ln(-z)^2;
		s = -s;
		z = 1/z;
	endif
	
	//For large positive real parts: mapping onto the unit circle with Re(z) <= 1/2
	if (real(z) > 0.5)
		d = d + s*( 1.64493406684822643 - ln((1-z)^ln(z)) );
		s = -s;
		z = 1-z;
	endif
	
	//Transformation to Debeye function and rational approximation
	z = -ln(1-z);
	
s = s*z;
	
d = d - 0.25*s*z;
	
z = z*z;
	
s = s*(1+z*(6.3710458848408100e-2+z*(1.04089578261587314e-3+z*4.0481119635180974e-6)));
	
s = s/(1+z*(3.5932681070630322e-2+z*(3.20543530653919745e-4+z*4.0131343133751755e-7)));
	
d = d + s; 
		
	return d;
	
End

Function/Wave DiLogApproxWave(z)
//Approximation for di-logarithm (polylog of order 2)
//Based on matlab procedure by Didier Clamond
//Computes Li_2 (z)
//This version operates on a wave instead of a variable

	//Initialize:
	Wave z;
	Variable waveSize = numpnts(z);
	Make/D/FREE/O/N=(waveSize) dw, sw;
	dw = 0;
	sw = 1;
	
	//Find entries equal to 1:
	matrixop/O/Free out1=equal(abs(z),1);
	matrixop/O/Free notOut1 = greater(z,1) + greater(1,z);
	matrixop/O/Free out1 = out1*pi*pi;
	out1 = out1/6;
	//if (z == 1)
	//	return pi^2/6;
	//endif
	
	//For large moduli, map onto unit circle |z| <= 1
	matrixop/O caseA = greater(abs(z),1);
	matrixop/O notCaseA = greater(1,abs(z)); // + equal(1,abs(z)); this case is handled above
	matrixop/O/Free temp =ln(-z);
	matrixop/O temp = ReplaceNaNs(temp, 0)
	matrixop/O temp = Replace(temp,-inf,0) //fixes infinity when input is 0
	matrixop/O dw = dw +caseA*(-0.5*temp*temp-1.64493406684822643);
	matrixop/O sw =sw*notCaseA+(-sw*caseA); //(s -> -s for entries of z >1)
	matrixop/O z = z*notCaseA +caseA/z;
	matrixop/O z = replaceNaNs(z,0); //fixes NaN when input is 0
	
	//if (abs(z)>1)
	//	d = -1.64493406684822643 - 0.5*ln(-z)^2;
	//	s = -s;
	//	z = 1/z;
	//endif
	
	//For large positive real parts: mapping onto the unit circle with Re(z) <= 1/2
	matrixop/O/Free caseB = greater(real(z),0.5);
	matrixop/O/Free notCaseB = greater(0.5,real(z)) + equal(0.5,real(z)));
	matrixop/O/Free temp = ln(powR(-z+1,ln(z)));
	matrixop/O temp = caseB*(dw+sw*(-temp+ 1.64493406684822643))
	matrixop/O temp = ReplaceNaNs(temp, 0)
	matrixop/O dw = temp*caseB+ dw*notcaseB;
	matrixop/O sw = sw*notCaseB + (-sw*caseB);
	matrixop/O z = z*notCaseB + caseB*(-z+1);


	//if (real(z) > 0.5)
	//	d = d + s*( 1.64493406684822643 - ln((1-z)^ln(z)) );
	//	s = -s;
	//	z = 1-z;
	//endif
	
	//Transformation to Debeye function and rational approximation
	matrixop/O z = -ln(-z+1);
	matrixop/O sw = sw*z;
	matrixop/O dw = dw - 0.25*sw*z;
	matrixop/O z = z*z;
	matrixop/O sw = sw*(1+z*(6.3710458848408100e-2+z*(1.04089578261587314e-3+z*4.0481119635180974e-6)));
	matrixop/O sw = sw/(1+z*(3.5932681070630322e-2+z*(3.20543530653919745e-4+z*4.0131343133751755e-7)));
	matrixop/O dw = dw + sw; 
	
	matrixop/O dw = dw*notOut1 + out1;
	return dw;
	
	//z = -ln(1-z);
	//s = s*z;
	//d = d - 0.25*s*z;
	//z = z*z;
	//s = s*(1+z*(6.3710458848408100e-2+z*(1.04089578261587314e-3+z*4.0481119635180974e-6)));
	//s = s/(1+z*(3.5932681070630322e-2+z*(3.20543530653919745e-4+z*4.0131343133751755e-7)));
	//d = d + s; 
		
	//return d;
	
End

Function TF_FD_2D(w,x,z) : FitFunc
	Wave w
	Variable x
	Variable z
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = offset + A*DiLogApprox(-f*exp( (-1/2)* ( ((x-x0)/sigma_x)^2 + ((z-z0)/sigma_z)^2 ) ) ) / DiLogApprox(-f)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ z
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = sigma_x
	//CurveFitDialog/ w[4] = z0
	//CurveFitDialog/ w[5] = sigma_z
	//CurveFitDialog/ w[6] = fugacity
	
	return w[0] + w[1]*DiLogApprox(-w[6]*exp( -(1/2)*(((x-w[2])/w[3])^2 + ((z-w[4])/w[5])^2) ) ) / DiLogApprox(-w[6])
End

Function TF_FD_2D_AAO(pw,yw,xw,zw) : FitFunc
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = offset + A*DiLogApprox(-f*exp( (-1/2)* ( ((x-x0)/sigma_x)^2 + ((z-z0)/sigma_z)^2 ) ) ) / DiLogApprox(-f)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ z
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = sigma_x
	//CurveFitDialog/ w[4] = z0
	//CurveFitDialog/ w[5] = sigma_z
	//CurveFitDialog/ w[6] = fugacity
	
	Wave pw
	Wave yw
	Wave xw
	Wave zw
	
	Variable waveSize = numpnts(xw);
	Make/D/FREE/O/N=(waveSize) tempW1, tempW2;
	Variable tempV = DiLogApprox(-pw[6]);
	Variable fac1 = -1/(2*pw[3]^2);
	Variable fac2 = -1/(2*pw[5]^2);
	MatrixOP /O tempW1 = fac1*(xw-pw[2])*(xw-pw[2]) + fac2*(zw-pw[4])*(zw-pw[4]) ;
	//MatrixOP /O tempW1 =  -(1/2)*(powR((xw-pw[2])/pw[3],2) + powR((zw-pw[4])/pw[5],2)) ;
	
	MatrixOP /O tempW2 = -pw[6]*exp(tempW1);
	
	//Non vectorized version of approximation, this way is a little slower:
	//tempW2 = DiLogApprox(tempW2);
	//MatrixOP /O tempW2 = tempW2/tempV;
	//MatrixOP/O yw = pw[0] + pw[1]*tempW2;
	
	
	Wave tempW3 = DiLogApproxWave(tempW2);
	MatrixOP /O tempW3 = tempW3/tempV;
	MatrixOP/O yw = pw[0] + pw[1]*tempW3;
	
	
	//MatrixOP tempW = -pw[6]*exp( -(1/2)*(powR((xw-pw[2])/pw[3],2) + powR((zw-pw[4])/pw[5],2)) );
	//tempW = DiLogApprox(tempW);
	//MatrixOP yw = pw[0] + pw[1]*tempW/tempV;
	
	//return w[0] + w[1]*DiLogApprox(-w[6]*exp( -(1/2)*(((x-w[2])/w[3])^2 + ((z-w[4])/w[5])^2) ) ) / DiLogApprox(-w[6])
End

Function AAO_Test(w, yw, xw, zw) : FitFunc
	wave w
	wave yw
	wave xw
	wave zw
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = offset
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 2
	//CurveFitDialog/ x
	//CurveFitDialog/ z
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = Amplitude
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = sigma_x
	//CurveFitDialog/ w[4] = z0
	//CurveFitDialog/ w[5] = sigma_z
	//yw = w[0] + w[1]*exp( (-1/2)*( ((xw-w[2])/w[3])*((xw-w[2])/w[3]) +((zw-w[4])/w[5])*((zw-w[4])/w[5]) ) )
	MatrixOp/O step1 =  ((xw-w[2])/w[3])*((xw-w[2])/w[3]) +((zw-w[4])/w[5])*((zw-w[4])/w[5])
	MatrixOp/O  yw = w[0] + w[1]*exp( -step1/2 )
End


	
Function FermiDiracFit2D(inputimage)
	Wave inputimage
	
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
	NVAR fugacity = :fugacity

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
	
	Variable V_FitOptions=4 //this suppresses the curve fit window
	Variable K0 = background;
	Variable K6 = 0;			// No correlation term
	//tic()
	//Generate guess:
	CurveFit /O/N/Q/H="0000001" Gauss2D kwCWave=Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /M=inputimage_mask
	Gauss3d_coef[6] = 0;			// No correlation term
	Gauss3d_coef[0] = background;		//fix background to average OD in atom free region
	
	//Fit with 2D Gaussian:
	CurveFit /G/N/Q/H="0000001" Gauss2D kwCWave=Gauss3d_coef inputimage((xmin),(xmax))((ymin),(ymax)) /W=inputimage_weight /M=inputimage_mask /R=res_optdepth
	//Gauss3d_coef[3] *= sqrt(2); Gauss3d_coef[5] *= sqrt(2);
	//make radial average of the gaussian
	// Update Display Waves
	variable pmax = (xmax - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable pmin = (xmin - DimOffset(inputimage, 0))/DimDelta(inputimage,0);
	variable qmax = (ymax - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	variable qmin = (ymin - DimOffset(inputimage, 1))/DimDelta(inputimage,1);
	fit_optdepth[pmin,pmax][qmin,qmax] = Gauss2D(Gauss3d_coef,x,y)
	MakeRadialAverage(fit_optdepth,2);
	MakeRadialAverage(res_optdepth,4);
	//toc()
	// Note the sqt(2) on the widths -- this is due to differing definitions of 1D and 2D gaussians in igor
	
	//2D Fermi Dirac Fit uses the following parameters:
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = x0
	//CurveFitDialog/ w[3] = sigma_x
	//CurveFitDialog/ w[4] = z0
	//CurveFitDialog/ w[5] = sigma_z
	//CurveFitDialog/ w[6] = fugacity
	Gauss3d_coef[6] = 100000; //Initial guess for fugacity
	
	//tic()
	//This is the original, slower version:
	//FuncFitMD/G/N/Q/H="0000000" TF_FD_2D, Gauss3d_coef, inputimage((xmin),(xmax))((ymin),(ymax)) /M=inputimage_mask /R=res_optdepth /W=inputimage_weight 

	//This AAO (all at once) fit function uses matrix operations and executes faster than the regular version (speed up depends on size of ROI)
	FuncFitMD/G/N/Q/H="0000000" TF_FD_2D_AAO, Gauss3d_coef, inputimage((xmin),(xmax))((ymin),(ymax)) /M=inputimage_mask /R=res_optdepth /W=inputimage_weight 
	//toc()
	
	//print Gauss3d_coef; //temporary
	fugacity = Gauss3d_coef[6]

	wave W_sigma = :W_sigma;
	//store the fitting errors - come back and update this once I figure out the right format
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
	fit_optdepth[pmin,pmax][qmin,qmax] = TF_FD_2D(Gauss3d_coef,x,y)
	MakeRadialAverage(fit_optdepth,1);
	MakeRadialAverage(res_optdepth,3);
	MakeRadialAverage(inputimage,0);
	
	//update slices, possibly move this elsewhere
	Wave fit_xsec_col = :Fit_Info:fit_xsec_col, fit_xsec_row=:Fit_Info:fit_xsec_row
	Wave res_xsec_col = :Fit_Info:res_xsec_col, res_xsec_row=:Fit_Info:res_xsec_row
	fit_xsec_col = ((p > qmin) && (p < qmax) ? fit_optdepth[pcsr(F,ImageWindowName)][p] : 0);
	fit_xsec_row = ((p > pmin) && (p < pmax) ? fit_optdepth[p][qcsr(F,ImageWindowName)] : 0);
	res_xsec_col = ((p > qmin) && (p < qmax) ? res_optdepth[pcsr(F,ImageWindowName)][p] : 0);
	res_xsec_row = ((p > pmin) && (p < pmax) ? res_optdepth[p][qcsr(F,ImageWindowName)] : 0);
	
	killwaves inputimage_mask, inputimage_weight;
		
	SetDataFolder fldrSav
	return 1
End

Function CalcTTf(fugacity)
//This function calculates the ratio of T to Tf given a fugacity. The result is given by solving the equation:
// Polylog(3,-fugacity) = -1/(6*(T/Tf)^3)
//The polylog is computed by numerical integration
	Variable fugacity
	return (-1/(6*NumPolyLog(3, -fugacity)))^(1/3)
End

Function NumPolyLog(v,z)

//This function attempts to evaluate the polylog order v with argument z by direct integration
//For arguments with z<=0 and v >0, this is done by direct integration of the Fermi-Dirac Integral and 
//by direct integration of the Bose-Einstein Integral for 0 <= z < 1
//Note: I could slightly simplify this function by only ever looking at the Bose-Einstein Integral - results are the same
	
	Variable v
	Variable z
	
	Variable /G root:polylog:v = v;
	Variable /G root:polylog:z = z;
	
	if (z <= 0 && v > 0)
		//Evaluate the PolyLog as a Fermi Dirac Integral:

		return (-1/gamma(v))*integrate1D(fermiDiracIntegral, 0, 100,2) //Gaussian quadrature gives better results
	elseif ( z >= 0 && z <= 1 && v > 0)
		if (z < 1 || v > 1)
			//Evaluate the PolyLog as a Bose Einstein Integral:
			return(1/gamma(v))*integrate1D(boseEinsteinIntegral,0,100,2) //Gaussian quadrature gives better results
		endif
	endif
	
End


Function fermiDiracIntegral(x)

	Variable x
	
	NVAR v = root:polylog:v;
	NVAR z = root:polylog:z;
	
	Variable z_local = - z;
	
	return x^(v-1) / ( (1/z_local)*exp(x)+1 );
	
End

Function boseEinsteinIntegral(x)
	
	Variable x
	NVAR v = root:polylog:v;
	NVAR z = root:polylog:z
	
	return  x^(v-1) / ( (1/z)*exp(x)-1 );
	
End

function tic()
	variable/G tictoc = startMSTimer
end
 
function toc()
	NVAR/Z tictoc
	variable ttTime = stopMSTimer(tictoc)
	printf "%g seconds\r", (ttTime/1e6)
	killvariables/Z tictoc
end
	
	
//Polylog approximations from Bhagat et al.
//Define helper functions:

Function eta_partial_sums(v,j)
	// Eta Function  
      //Eq. 17 (partial sums) following V. Bhagat, et al., On the evaluation of generalized
      //BoseEinstein and FermiDirac integrals, Computer Physics Communications,
      // Vol. 155, p.7, 2003
      // Used for approximations of Bose-Einstein integrals 
      
      Variable v, j;
      Variable n, out;
      out = 0
      for (n=1 ; n < j+1 ; n+=1)
      		out = out + (-1)^(n+1) / n^v;
      	endfor
      	return out;
      	
End

function zeta_approx6(x)
        //Zeta Function  
        // Eq. 18, 6th order tau approximation for zeta
        // following V. Bhagat, et al., On the evaluation of generalized
        // BoseEinstein and FermiDirac integrals, Computer Physics Communications,
        // Vol. 155, p.7, 2003
        // Used for approximations of Bose-Einstein integrals 
        // This function diverges at x=1 and is not valid at x <0
 
 	Variable x;
 	Variable prefactor, numerator, denominator;
 	
      prefactor = 2^(x-1) / ( 2^(x-1)-1 );
      numerator = 1 + 36*2^x*eta_partial_sums(x,2) + 315*3^x*eta_partial_sums(x,3)
      numerator += 1120*4^x*eta_partial_sums(x,4) + 1890*5^x*eta_partial_sums(x,5)
      numerator += 1512*6^x*eta_partial_sums(x,6) + 462*7^x*eta_partial_sums(x,7);
      denominator = 1 + 36*2^x + 315*3^x + 1120*4^x + 1890*5^x + 1512*6^x +462*7^x;
      
      return prefactor * numerator / denominator;
end

function zeta(x)
	//Zeta Function  
      // Uses Eq. 18, 6th order tau approximation for zeta but also corrects for large negative x by using Eq. 26
      // following V. Bhagat, et al., On the evaluation of generalized
      // BoseEinstein and FermiDirac integrals, Computer Physics Communications,
      // Vol. 155, p.7, 2003
      // Used for approximations of Bose-Einstein integrals 
      
      Variable x;
      
      if (x >= 0)
      		return zeta_approx6(x);
      	else
      		return zeta_approx6(1-x) *pi^(x-1) * 2^x * gamma(1-x) *cos(pi*(1-x)/2);
      	endif
end


function s_partial_sum(v,z,j)
	//S Function
	//Eq. 12 (partial sums) following V. Bhagat, et al., On the evaluation of generalized
      //BoseEinstein and FermiDirac integrals, Computer Physics Communications,
      // Vol. 155, p.7, 2003
      // Used for approximations of Bose-Einstein integrals 
      
      Variable v, z, j;
      Variable out = 0;
      Variable i;
      for (i = 1 ; i < j+1 ; i+=1)
      		out += z^i/(i+1)^v;
      	endfor
      	return out
 end
 
 function b_zeta(v,i)
 	//b zeta function for evaluation Eq. 27
 	//b_i = zeta(v-i)
 	//Following V. Bhagat, et al., On the evaluation of generalized
      //BoseEinstein and FermiDirac integrals, Computer Physics Communications,
      // Vol. 155, p.7, 2003
      // Used for approximations of Bose-Einstein integrals 
      
      Variable v, i;
      return zeta(v-i);
 end
 
 function BEpolylog(v,z)
 	//Computes the v-based polylogarithm of z: Li_v(z)
 	//Following V. Bhagat, et al., On the evaluation of generalized
 	//BoseEinstein and FermiDirac integrals, Computer Physics Communications,
 	// Vol. 155, p.7, 2003
 	//Note: returns NaN for integer v
 	
 	Variable v, z;
 	Variable preterm, numerator, denominator, alpha;
 	
 	//if z > 0.55
 	
 	alpha = -ln(z); 
 	
	preterm = gamma(1-v)/alpha^(1-v);
	numerator = b_zeta(v,0) - alpha*( b_zeta(v,1) - 4*b_zeta(v,0)*b_zeta(v,4)/7/b_zeta(v,3) ) ;
	numerator += alpha^2*( b_zeta(v,2)/2 + b_zeta(v,0)*b_zeta(v,4)/7/b_zeta(v,2) - 4*b_zeta(v,1)*b_zeta(v,4)/7/b_zeta(v,3) ) ;
	numerator -=  alpha^3*( b_zeta(v,3)/6 - 2*b_zeta(v,0)*b_zeta(v,4)/105/b_zeta(v,1) + b_zeta(v,1)*b_zeta(v,4)/7/b_zeta(v,2) - 2*b_zeta(v,2)*b_zeta(v,4)/7/b_zeta(v,3) );
 	denominator = 1 + alpha*4*b_zeta(v,4)/7/b_zeta(v,3) + alpha^2*b_zeta(v,4)/7/b_zeta(v,2) 
 	denominator += alpha^3*2*b_zeta(v,4)/105/b_zeta(v,1) + alpha^4*b_zeta(v,4)/840/b_zeta(v,0);
 	return preterm + numerator / denominator;
      
end

function test()
	Make/O/N=5 testA = {0.75,1,0,-4,-5};
	//Wave testC = DiLogApproxWave(testA);
	//print testC
end

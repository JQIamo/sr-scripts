#pragma rtGlobals=1		// Use modern global access method.

function Scattering_Depth_Calibration(startNum,endNum,skipList, numDiffOrders,depthGuess)
	//This function analyzes a sequence of images in order to calibrate a lattice depth based on Kapitza-Dirac scattering. The data should be taken with 
	//short (1-100us works well) pulses of constant lattice beam power immediately followed by a TOF. The sequenced variable should be named pulseLatT.
	//In order for this script to work, you first need to define multiple ROIs around the various diffracted order. The 0th order peak ROI should be named P0, 
	//the first order on the right should be named P1_R, the first order on the left should be named P1_L, etc. 
	//Make sure batchrun base path has already been set
	//The current working directory must be set to the data series that you're going to use 
	//Inputs: startNum: image number of the first image
	//		endNum: image number of the last image
	//		skipList: list of "bad" images to skip, format should be like: "1424;1426;1430"
	//		numDiffOrders: number of populated diffracted orders, must be at least 1 or else you're not doing Kapitza-Dirac scattering
	//		depthGuess - guess for lattice depth, this is used to generate the initial guess when curve fitting
	
	variable startNum;
	variable endNum;
	string skipList;
	variable numDiffOrders;
	variable depthGuess
	
	variable numImages = endNum-startNum + 1 - ItemsInList(skipList);
	
	// Get the current path
	//String ProjectFolder = Activate_Top_ColdAtomInfo();
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	//Initialize variable to store which order we're fitting:
	Variable/G $(ProjectFolder + ":diffractedOrder") = nan;
	
	New_IndexedWave("diffractedOrder", ":diffractedOrder");
	
	
	string ROI_name;
	string ss;
	variable ii, jj;
	
	for (jj = startNum ; jj <= endNum; jj+=1) //loop over image numbers
		if(WhichListItem(num2str(jj),skipList,";",0,1)==-1) //only load images not in skipList
			BatchRun(-1,jj,0,"")
			dec_update("") //This decrements the fit that is done automatically with BatchRun - this could be optimized to use this auto-fit but for now it's simpler
			for(ii = numDiffOrders*(-1); ii <= numDiffOrders;ii+=1)	//loop over ROIs
				//Build ROI name:
				if (ii < 0)
					ss = "_L"
				elseif (ii == 0)
					ss = ""
				elseif (ii>0)
					ss = "_R"
				endif
				ROI_name = "P" + num2str(abs(ii)) + ss 
	
				LoadROI(ROI_name);
				Variable /G $(ProjectFolder + ":diffractedOrder") = ii;
		
				refit("");
			endfor		
		endif
	endfor					
	
	//Call the sorting function that makes convenient waves, plots them, and fits the result
	Variable numIm = endNum - startNum + 1 - ItemsInList(skipList);
	Scattering_Depth_Sorting(numIm, numDiffOrders,depthGuess)

end

function Scattering_Depth_Sorting(numImages,numDiffOrders,depthGuess)
	//This function makes a number of waves that will be convenient for plotting and fitting the population in the various diffracted orders. 
	//The output waves are saved in the folder "LatticePulseCal" below the data series
	//The current working directory must be set to the data series that you're going to use 
	//This function also generates a plot of the 0th and 1st order populations as well as the ratio of the 1st order to 0th order populations. 
	//The ratio is fit to extract trap depth
	//Inputs: numImages - number of images in the data series
	//		numDiffOrders -  number of populated diffracted orders
	//		depthGuess - guess for lattice depth, this is used to generate the initial guess when curve fitting
	//Outputs (saved waves in LatticePulseCal folder): 
	//		pulseLatT - lattice pulse time (s) (typically use this as your "X" data series when plotting)
	//		num_0, num_1_L, etc. - atom number in the 0th, 1st diffracted order on left, etc. peak
	//		pop_0, pop_1_L, etc. - fraction of atom population in 0th, 1st diffracted order on left, etc. peak
	//		pop_1_avg, etc - average of population in 1st order diffracted peaks,
	//		ratio_1_0 - ratio of population in 1st order peak to 0th order peak
	//		mask_0, mask_1, mask_ratio_1_0 - mask waves to filter out bad points when fitting
	
	
	Variable numImages
	Variable numDiffOrders
	Variable depthGuess
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	
	//Sort Indexed Waves
	Sort_IndexedWaves(ProjectFolder,"diffractedOrder;pulseLatT",2)
	
	//Make a new data folder to store the waves created below
	NewDataFolder /O $(ProjectFolder + ":LatticePulseCal")
	
	//Make a wave to hold the pulse time
	Duplicate /O /R=(0,numImages-1) $(ProjectFolder + ":IndexedWaves:pulseLatT") $(ProjectFolder + ":LatticePulseCal:pulseLatT")
	
	//Loop over the various diffraction orders and save waves with the atom number for those waves
	Make /O /N=(numImages) totalAtomNumber =0  //Initialize a wave to track total atom number
	Wave tempWave;
	variable order; //the lattice peak order
	variable i =0; //initialize loop counter
	String tempString;
	for (order = numDiffOrders*(-1); order <= numDiffOrders; order+=1) //loop over diffraction orders and grab the appropriate ranges of atom number
		if (order<0)
			tempString = num2str(abs(order)) + "_L"
		elseif (order==0)
			tempString = "0"
		elseif (order>0)
			tempString = num2str(order) + "_R"
		endif
		
		Duplicate /O /R=(0 + i*numImages, numImages*(1+i)-1) $(ProjectFolder + ":IndexedWaves:absnum") $(ProjectFolder + ":LatticePulseCal:num_" + tempString)
		Duplicate /O /R=(0 + i*numImages, numImages*(1+i)-1) $(ProjectFolder + ":IndexedWaves:absnum") tempWave 
		totalAtomNumber += tempWave
		i+=1
	endfor
	Duplicate /O totalAtomNumber $(ProjectFolder + ":LatticePulseCal:totalNum")
	
	//loop over diffraction orders and calculate the population in various orders
	for (order = numDiffOrders*(-1); order <= numDiffOrders; order+=1) 
		if (order<0)
			tempString = num2str(abs(order)) + "_L"
		elseif (order==0)
			tempString = "0"
		elseif (order>0)
			tempString = num2str(order) + "_R"
		endif
		
		Duplicate /O  $(ProjectFolder + ":LatticePulseCal:num_" + tempString) tempWave
		Make /O /N=(numImages)  $(ProjectFolder + ":LatticePulseCal:pop_" + tempString) = tempWave/totalAtomNumber;
	endfor
	
	//Calculate the average population in each order:
	for (order = 1; order <= numDiffOrders; order+=1)
		Duplicate /O $(ProjectFolder + ":LatticePulseCal:pop_" + num2str(order) + "_L") tempWave1
		Duplicate /O $(ProjectFolder + ":LatticePulseCal:pop_" + num2str(order) + "_R") tempWave2
		Make /O /N=(numImages) $(ProjectFolder + ":LatticePulseCal:pop_" + num2str(order) + "_avg") = (tempWave1 + tempWave2)/2;
	endfor
	
	//Calculate ratio of first order population to zeroth order:
	Duplicate /O $(ProjectFolder + ":LatticePulseCal:pop_1_avg") tempWave1
	Duplicate /O $(ProjectFolder + ":LatticePulseCal:pop_0") tempWave2
	Make /O /N=(numImages) $(ProjectFolder + ":LatticePulseCal:ratio_1_0") = tempWave1/tempWave2;
	
	//Make mask waves to use for fitting. These wave exclude populations less than 0 or greater than 1 because these are likely outliers where something weird happened with atom counting
	Make /O /N=(numImages) $(ProjectFolder + ":LatticePulseCal:mask_0") = (tempWave2 <= 1 && tempWave2 >= 0)
	Make /O /N=(numImages) $(ProjectFolder + ":LatticePulseCal:mask_1") = (tempWave1 <= 1 && tempWave1 >= 0)
	Make /O /N=(numImages) $(ProjectFolder + ":LatticePulseCal:mask_ratio_1_0") = (tempWave1/tempWave2 >= 0)
	
	if (numDiffOrders == 1)
		//Plot some of the results
		Display $(ProjectFolder + ":LatticePulseCal:pop_0"), $(ProjectFolder + ":LatticePulseCal:pop_1_avg"), $(ProjectFolder + ":LatticePulseCal:ratio_1_0") vs $(ProjectFolder + ":LatticePulseCal:pulseLatT")
	
		//Format Graph
		ModifyGraph mode(pop_0)=3,marker(pop_0)=8
		ModifyGraph mode(pop_1_avg)=3,marker(pop_1_avg)=8,rgb(pop_1_avg)=(0,12800,52224)
		ModifyGraph mode(ratio_1_0)=3,marker(ratio_1_0)=18,rgb(ratio_1_0)=(0,26112,0)
		Legend/C/N=text0
		Label left "Population"
		Label bottom "Pulse Time (s)"
		SetAxis left 0,1
	
		//Fit to ratio:	
		Make/D/N=3/O W_coef
		W_coef[0] = {0,1,depthGuess}
		FuncFit/NTHR=0/TBOX=768 LatPulseRatio1_0FitFunc W_coef  $(ProjectFolder + ":LatticePulseCal:ratio_1_0") /X=$(ProjectFolder + ":LatticePulseCal:pulseLatT") /M=$(ProjectFolder + ":LatticePulseCal:mask_ratio_1_0") /D 
		ModifyGraph rgb(fit_ratio_1_0)=(0,26112,13056)
	endif
	
	
	
	if (numDiffOrders>1)
		Display $(ProjectFolder + ":LatticePulseCal:pop_0"), $(ProjectFolder + ":LatticePulseCal:pop_1_avg"), $(ProjectFolder + ":LatticePulseCal:pop_2_avg") vs $(ProjectFolder + ":LatticePulseCal:pulseLatT")
		//Format Graph
		ModifyGraph mode(pop_0)=3,marker(pop_0)=8
		ModifyGraph mode(pop_1_avg)=3,marker(pop_1_avg)=8,rgb(pop_1_avg)=(0,12800,52224)
		ModifyGraph mode=3,marker(pop_2_avg)=17,rgb(pop_2_avg)=(0,26112,0)
		
		if (numDiffOrders>2)
			//add population in 3rd order peaks to plot
			AppendToGraph $(ProjectFolder + ":LatticePulseCal:pop_3_avg") vs $(ProjectFolder + ":LatticePulseCal:pulseLatT")
			ModifyGraph mode=3,marker(pop_3_avg)=18,rgb(pop_3_avg)=(19712,0,39168)
		endif
		
		//Fit to pop0:	
		Make/D/N=4/O W_coef
		W_coef[0] = {0,1,depthGuess,0}
		FuncFit/H="0001"/NTHR=0/TBOX=768 LatPulseFitFunc W_coef  $(ProjectFolder + ":LatticePulseCal:pop_0") /X=$(ProjectFolder + ":LatticePulseCal:pulseLatT") /D 
		ModifyGraph mode(fit_pop_0)=0
		
		//Fit to pop1:
		Make/D/N=4/O W_coef
		W_coef[0] = {0,1,depthGuess,1}
		FuncFit/H="0001"/NTHR=0/TBOX=768 LatPulseFitFunc W_coef  $(ProjectFolder + ":LatticePulseCal:pop_1_avg") /X=$(ProjectFolder + ":LatticePulseCal:pulseLatT") /D 
		ModifyGraph rgb(fit_pop_1_avg)=(0,12800,52224)
		ModifyGraph mode(fit_pop_1_avg)=0
		
		//Fit to pop2:
		Make/D/N=4/O W_coef
		W_coef[0] = {0,1,depthGuess,2}
		FuncFit/H="0001"/NTHR=0/TBOX=768 LatPulseFitFunc W_coef  $(ProjectFolder + ":LatticePulseCal:pop_2_avg") /X=$(ProjectFolder + ":LatticePulseCal:pulseLatT") /D 
		ModifyGraph rgb(fit_pop_2_avg)=(0,26112,0)
		ModifyGraph mode(fit_pop_2_avg)=0
		if (numDiffOrders>2)
			
			//Fit to pop3:
			Make/D/N=4/O W_coef
			W_coef[0] = {0,1,depthGuess,3}
			FuncFit/H="0001"/NTHR=0/TBOX=768 LatPulseFitFunc W_coef  $(ProjectFolder + ":LatticePulseCal:pop_3_avg") /X=$(ProjectFolder + ":LatticePulseCal:pulseLatT") /D 
			ModifyGraph rgb(fit_pop_3_avg)=(19712,0,39168)
			ModifyGraph mode(fit_pop_3_avg)=0
		endif
		Legend/C/N=text0
		Label left "Population"
		Label bottom "Pulse Time (s)"
		SetAxis left 0,1
	endif
		
	//Cleanup:
	KillWaves totalAtomNumber, tempWave, tempWave1, tempWave2
	
end

Function LatPulseDiffEq(pw, tt, cw, dcdt)
	//This function defines the differential equation which governs the population in the various orders for Kapitza-Dirac scattering. 
	//See, for example, eq. 4 of arXiv:0907.3507v1
	
	Wave pw //parameter wave (input) pw[0] = V0 (trap depth) in units of Er, 
	
	Variable tt //t value at which to calculate derivatives
	
	Wave cw //wave containing real and imaginary parts of the various c coefficients:
		//cw[0] = c0 real
		//cw[1] = c0 imag
		//cw[2] = c1 real
		//cw[3] = c1 imag
		//cw[4] = c2 real
		//cw[5] = c2 imag
		//cw[6] = c3 real
		//cw[7] = c3 imag
		//cw[8] = c4 real
		//cw[9] = c4 imag
		//cw[10] = c1m real
		//cw[11] = c1m imag
		//cw[12] = c2m real
		//cw[13] = c2m imag
		//cw[14] = c3m real
		//cw[15] = c3m imag
		//cw[16] = c4m real
		//cw[17] = c4m imag
	Wave dcdt //wave to receive dc[i]/dt (output)
	
	Variable hbar = 0.0000758034; //(hbar in units of Er for Sr84: 2m/(hbar*k^2)
	Variable/c ki = cmplx(0,1) //declare complex constant.  Don't edit this.  Do use "ki" as a replacement for sqrt(-1)
	Variable/c alphaP = -ki*4/hbar; //variable to use in place of alpha/(tau*i), in units of Er
	Variable/c betaP = -ki*pw[0]/(4*hbar); //variable to use in place of Beta/(4*tau*i), in units of Er
	
	variable/C C0 = cmplx(cw[0],cw[1]), C1 = cmplx(cw[2],cw[3]), C2 = cmplx(cw[4],cw[5]), C3=cmplx(cw[6],cw[7]), C4=cmplx(cw[8],cw[9])
	variable/C C1m = cmplx(cw[10],cw[11]), C2m = cmplx(cw[12],cw[13]), C3m = cmplx(cw[14],cw[15]), C4m = cmplx(cw[16],cw[17])
	
	//Define diff equation:
	//  c[j]' == j^2 * alphaP* c[j] + betaP * (c[j-1] + 2*c[j] + c[j+1])
	
	dcdt[0] =real( betaP*(C1m + 2*C0 + C1) )
	dcdt[1] =imag( betaP*(C1m + 2*C0 + C1) )
	
	dcdt[2] =real(  alphaP*C1+betaP*(C0 + 2*C1 + C2) )
	dcdt[3] =imag(alphaP*C1+betaP*(C0 + 2*C1 + C2) )
	
	dcdt[4] =real( 4*alphaP*C2+betaP*(C1 + 2*C2 + C3) )
	dcdt[5] =imag( 4*alphaP*C2+betaP*(C1 + 2*C2 + C3) )
	
	dcdt[6] =real(9*alphaP*C3+betaP*(C2 + 2*C3 + C4) )
	dcdt[7] =imag(9*alphaP*C3+betaP*(C2 + 2*C3 + C4) )
	
	dcdt[8] =real(16*alphaP*C4+betaP*(C3 + 2*C4) )
	dcdt[9] =imag(16*alphaP*C4+betaP*(C3 + 2*C4) )
	
	dcdt[10] =real(alphaP*C1m+betaP*(C0 + 2*C1m + C2m))
	dcdt[11] =imag(alphaP*C1m+betaP*(C0 + 2*C1m + C2m))
	
	dcdt[12] =  real(4*alphaP*C2m+betaP*(C1m + 2*C2m + C3m))
	dcdt[13] =  imag(4*alphaP*C2m+betaP*(C1m + 2*C2m + C3m))
	
	dcdt[14] =  real(9*alphaP*C3m+betaP*(C2m + 2*C3m + C3m))
	dcdt[15] =  imag(9*alphaP*C3m+betaP*(C2m + 2*C3m + C3m))
	
	dcdt[16] = real(16*alphaP*C4m+betaP*(C3m + 2*C4m))
	dcdt[17] = imag(16*alphaP*C4m+betaP*(C3m + 2*C4m))
	
	return 0
	
End

Function LatPulsePop(tau,V0,order)
//This function numerically integrates the differential equation governing Kapitza-Dirac scattering to calculate the expected population in a given order:
//Inputs: tau - pulse duration (s)
//		V0 - trap depth (in units of recoil energy, Er)
//		order - diffraction order (0, 1, 2, 3, or 4) 
//Outputs: population in given order (0-1)
	
	Variable tau, V0, order
	
	if (tau==0)
		if (order==0)
			return 1
		else
			return 0
		endif
	endif
	
	Make/D/O/Free parWave={V0}	// parameter wave to pass to diff equation (just trap depth for now)
	
	Make /D/O/Free/N=(2,18) cWave; //wave to store the initial and computed c coefficients from the diff eq
	SetScale /P x 0,tau,cWave;
	
	//Set initial conditions
	cWave[0][0]=1; //inital population of c0 is 1, all others are zero
	Variable i;
	for(i=1;i<18;i+=1)	
		cWave[0][i]=0									
	endfor												

	//Perform integration
	IntegrateODE  LatPulseDiffEq, parWave, cWave
	
	if (order ==0)
		return magsqr(cmplx(cWave[1][0],cWave[1][1]))
	elseif (order == 1)
		return magsqr(cmplx(cWave[1][2],cWave[1][3]))
	elseif (order == 2)
		return  magsqr(cmplx(cWave[1][4],cWave[1][5]))
	elseif (order == 3)
		return magsqr(cmplx(cWave[1][6],cWave[1][7]))
	elseif( order == 4)
		return magsqr(cmplx(cWave[1][8],cWave[1][9]))
	else
		return -1 //error: order should be an integer between 0 and 4 inclusive
	endif
	
end

function LatPulseFitFunc(w,t) : FitFunc

	Wave w
	Variable t

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = offset + A* LatPulsePop(tau,V0,order)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ t
	//CurveFitDialog/ Coefficients 4
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = V0
	//CurveFitDialog/ w[3] = order
	
	return w[0] + w[1]*LatPulsePop(t,w[2],w[3])
end

function LatPulseRatio1_0FitFunc(w,t) : FitFunc

	Wave w
	Variable t

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = offset + A* LatPulsePop(tau,V0,order)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ t
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = offset
	//CurveFitDialog/ w[1] = A
	//CurveFitDialog/ w[2] = V0
	
	return w[0] + w[1]*(LatPulsePop(t,w[2],1)/LatPulsePop(t,w[2],0))
end

Function defineKipDirROIs(numOrders,direction)
	Variable numOrders
	String direction
	
	//variable hbar = 1.0545718e-34 //this is already defined as a global variable
	
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String WindowName = CurrentPanel + "#ColdAtomInfoImage";
	
	NVAR k = $(ProjectFolder + ":Experimental_Info:k")
	NVAR mass = $(ProjectFolder + ":Experimental_Info:mass")
	NVAR expand_time = $(ProjectFolder + ":Experimental_Info:expand_time")
	
	//Get the center coordinates
	Variable centerX, centerY
	centerX = hcsr(F, WindowName) //F is the green cursor that should be at the center of the 0th order peak
	centerY = vcsr(F,WindowName)
	
	//Calculate the distance corresponding to hbar*k of momentum (hbar*k*TOF/m)
	Variable hbar_k = 1e6*hbar*k*expand_time*1e-3/mass //(constants are there to convert m to um and ms to s)
	
	//Define the ROI around the center peak:
	Cursor/I/W=$(WindowName) A, optdepth, (centerX+hbar_k), (centerY+hbar_k)
	Cursor/I/W=$(WindowName) B, optdepth, (centerX-hbar_k), (centerY-hbar_k)
	if (stringmatch(direction,"H"))
		//place bg region below 
		Cursor/I/W=$(WindowName) C, optdepth, (centerX+hbar_k*(numOrders*2+1)), (centerY-hbar_k)
		Cursor/I/W=$(WindowName) D, optdepth, (centerX-hbar_k*(numOrders*2+1)), (centerY-3*hbar_k)
		
		//place bg region above 
		//Cursor/I/W=$(WindowName) C, optdepth, (centerX+hbar_k*(numOrders*2+1)), (centerY+hbar_k)
		//Cursor/I/W=$(WindowName) D, optdepth, (centerX-hbar_k*(numOrders*2+1)), (centerY+3*hbar_k)
	elseif (stringmatch(direction,"V"))
		//place bg region to the left
		Cursor/I/W=$(WindowName) C, optdepth, (centerX-hbar_k), (centerY+hbar_k*(numOrders*2+1))
		Cursor/I/W=$(WindowName) D, optdepth, (centerX-3*hbar_k), (centerY-hbar_k*(numOrders*2+1))
		
		//place bg region to the right
		//Cursor/I/W=$(WindowName) C, optdepth, (centerX+hbar_k), (centerY+hbar_k*(numOrders*2+1))
		//Cursor/I/W=$(WindowName) D, optdepth, (centerX+3*hbar_k), (centerY-hbar_k*(numOrders*2+1))
	endif
	//Set the ROI
	SetROI("",1,"")
	//Save the ROI
	SaveROI(ProjectFolder,"P0")
	
	
	String ROIname
	Variable j
	for (j=1 ; j <= numOrders ; j+=1) 
		if (stringmatch(direction,"H"))	//move cursors to next peak to the right
			Cursor/I/W=$(WindowName) A, optdepth, (centerX+hbar_k*(2*j+1)), (centerY+hbar_k)
			Cursor/I/W=$(WindowName) B, optdepth, (centerX+hbar_k*(2*j-1)), (centerY-hbar_k)
		elseif (stringmatch(direction,"V"))	//move cursors to next peak above
			Cursor/I/W=$(WindowName) A, optdepth, (centerX+hbar_k), (centerY+hbar_k*(2*j+1))
			Cursor/I/W=$(WindowName) B, optdepth, (centerX-hbar_k), (centerY+hbar_k*(2*j-1))
		endif
		ROIname = "P" + num2str(j) + "_R"
		SetROI("",1,"")
		SaveROI(ProjectFolder,ROIname)
		
		if (stringmatch(direction,"H"))	//move cursors to next peak to the left
			Cursor/I/W=$(WindowName) A, optdepth, (centerX-hbar_k*(2*j+1)), (centerY+hbar_k)
			Cursor/I/W=$(WindowName) B, optdepth, (centerX-hbar_k*(2*j-1)), (centerY-hbar_k)
		elseif (stringmatch(direction,"V"))	//move cursors to next peak below
			Cursor/I/W=$(WindowName) A, optdepth, (centerX+hbar_k), (centerY-hbar_k*(2*j+1))
			Cursor/I/W=$(WindowName) B, optdepth, (centerX-hbar_k), (centerY-hbar_k*(2*j-1))
		endif
		ROIname = "P" + num2str(j) + "_L"
		SetROI("",1,"")
		SaveROI(ProjectFolder,ROIname)
	
	endfor
	
	
end
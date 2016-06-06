#pragma rtGlobals=1		// Use modern global access method.

function Scattering_Depth_Calibration(startNum,endNum,skipList, numDiffOrders)
	//Make sure batchrun base path has already been set
	variable startNum;
	variable endNum;
	string skipList;
	variable numDiffOrders;
	
	variable numImages = endNum-startNum + 1 - ItemsInList(skipList);
	
	// Get the current path
	//String ProjectFolder = Activate_Top_ColdAtomInfo();
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	//Initialize variable to store which order we're fitting:
	Variable/G $(ProjectFolder + ":diffractedOrder") = nan;
	
	New_IndexedWave("diffractedOrder", ":diffractedOrder");
	
	
	string ROI_name = "P" + num2str(numDiffOrders) + "_L"; 
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
	
	//Sort by diffracted order and pulse time:			
	Sort_IndexedWaves(ProjectFolder,"diffractedOrder;pulseLatT",2)		

end

function Scattering_Depth_Sorting()
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	Variable numImages = 25;
	variable numDiffOrders =3;
	
	
	Sort_IndexedWaves(ProjectFolder,"diffractedOrder;pulseLatT",2)
	
	NewDataFolder /O $(ProjectFolder + ":LatticePulseCal")
	Duplicate /O /R=(0,numImages-1) $(ProjectFolder + ":IndexedWaves:pulseLatT") $(ProjectFolder + ":LatticePulseCal:pulseLatT")
	Make /O /N=(numImages) totalAtomNumber =0  //Make wave to track total atom number
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
	
	for (order = numDiffOrders*(-1); order <= numDiffOrders; order+=1) //loop over diffraction orders and calculate the population in various orders
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
	
	//Cleanup:
	KillWaves totalAtomNumber, tempWave
	
end

Function LatPulseDiffEq(pw, tt, cw, dcdt)
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

function test()
	Variable ii
	Make /N=(101)/O testT
	for (ii=0;ii <102 ; ii+=1)
		testT[ii]=ii*1e-6
	endfor
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
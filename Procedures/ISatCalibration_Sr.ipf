#pragma rtGlobals=1		// Use modern global access method.


function importImagesAlphaISatCal(startNum,endNum,skipList,startAlpha,endAlpha,deltaAlpha)
//This function loads a sequence of images (with starting file number startNum, ending file number endNum, and skipping the files
//in skipList) using a range of different alpha values. Alpha is a variable used to correct for deviations from the ideal atomic cross 
//section and saturation intensity. See Ben's thesis, section 4.3.2.
 	Variable startNum, endNum, startAlpha, endAlpha, deltaAlpha
 	string skipList

	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	
		variable ii, jj
	
	//setup variables to do the calibration:
	NVAR alphaIsatCalBoolean = :Experimental_Info:alphaISatCal //this variable indicates if we are calibrating the alphaIsat variable (1=true, 0=false)
	alphaIsatCalBoolean = 1;
	New_IndexedWave("alphaIsat",":alphaIsat")
	NVAR alpha = :alphaIsat
	
	
	//Make a new data folder to store the waves created below
	String ISatCalFolder = ProjectFolder + ":ISatCalibration"
	NewDataFolder /O $ISatCalFolder
	
	//Make a wave to hold the alpha values:
	Variable numAlphaVals = round((endAlpha-startAlpha)/deltaAlpha)+1
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":alphaIsat")
	Wave alphaIsatCal =  $(ISatCalFolder + ":alphaIsat")
	
	Variable alphaCount = 0;
	
	Variable numImages = endNum - startNum + 1 - ItemsInList(skipList);
	
	for (ii = startAlpha ; ii < endAlpha+deltaAlpha; ii += deltaAlpha) //loop over alpha values
		alpha = ii
		alphaIsatCal[alphaCount] = ii //save this alpha value
		
		for (jj = startNum ; jj <= endNum; jj+=1) //loop over image numbers
			if(WhichListItem(num2str(jj),skipList,";",0,1)==-1) //only load images not in skipList
				BatchRun(-1,jj,0,"") //load current image
			endif
		endfor
		
		alphaCount +=1
		
	endfor
		
	//Make a wave to hold the std deviation of the atom number
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":absnumStdDev")
	Wave absnumStdDev = $(ISatCalFolder + ":absnumStdDev")
	
	//Make a wave to hold the std deviation of the peak OD
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":amplitudeStdDev")
	Wave amplitudeStdDev = $(ISatCalFolder + ":amplitudeStdDev")
	

	
//	Variable imgIndex = 0
//	alphaCount = 0
//	for (ii = startAlpha ; ii < endAlpha+deltaAlpha; ii += deltaAlpha) //loop over alpha values
//		WaveStats /Q/R=(imgIndex,imgIndex+numImages-1) $(ProjectFolder + ":IndexedWaves:absnum")
//		absnumStdDev[alphaCount] = V_sdev
//		WaveStats /Q/R=(imgIndex,imgIndex + numImages - 1) $(ProjectFolder + ":IndexedWaves:amplitude")
//		amplitudeStdDev[alphaCount] = V_sdev
//		alphaCount += 1
//		imgIndex += numImages -1
//	endfor
//	
//	Display :ISatCalibration:absnumStdDev vs :ISatCalibration:alphaIsat
//	CurveFit/NTHR=0/TBOX=768 gauss  :ISatCalibration:absnumStdDev /X=:ISatCalibration:alphaIsat /D 			
End

Function analyzeIsatCal(numImages,startAlpha,endAlpha,deltaAlpha, plot)
	Variable numImages, startAlpha, endAlpha, deltaAlpha, plot
	
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	
	Variable numAlphaVals = round((endAlpha-startAlpha)/deltaAlpha)+1

	//Make a new data folder to store the waves created below
	String ISatCalFolder = ProjectFolder + ":ISatCalibration"
	NewDataFolder /O $ISatCalFolder
	
	//Make a wave to hold the std deviation of the atom number
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":absnumStdDev")
	Wave absnumStdDev = $(ISatCalFolder + ":absnumStdDev")
	
	//Make a wave to hold the mean of the atom number
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":absnumMean")
	Wave absnumMean = $(ISatCalFolder + ":absnumMean")
	
	//Make a wave to hold the std deviation of the peak OD
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":amplitudeStdDev")
	Wave amplitudeStdDev = $(ISatCalFolder + ":amplitudeStdDev")
	
	//Make a wave to hold the mean of the peak OD
	Make /O /N=(numAlphaVals) $(ISatCalFolder + ":amplitudeMean")
	Wave amplitudeMean = $(ISatCalFolder + ":amplitudeMean")
	
	//Make a wave to hold the probe powers
	Duplicate /O /R=(0,numImages-1) $(ProjectFolder + ":IndexedWaves:ProbePow") $(ISatCalFolder + ":ProbePow")
	Wave probePow =  $(ISatCalFolder + ":ProbePow")
	
	//Make waves to hold fit parameters
	Make /O/N=(numAlphaVals) $(ISatCalFolder + ":absnum_slope")
	Wave absnum_slope = $(ISatCalFolder + ":absnum_slope")
	Make /O/N=(numAlphaVals) $(ISatCalFolder + ":amplitude_slope")
	Wave amplitude_slope = $(ISatCalFolder + ":amplitude_slope")

	Variable imgIndex = 0
	Variable alphaCount = 0
	Variable ii
	String tempStr
	Make /O/N=2 fitCoef
	for (ii = startAlpha ; ii < endAlpha+deltaAlpha; ii += deltaAlpha) //loop over alpha values
		WaveStats /Q/R=(imgIndex,imgIndex+numImages-1) $(ProjectFolder + ":IndexedWaves:absnum")
		absnumStdDev[alphaCount] = V_sdev
		absnumMean[alphaCount] = V_avg
		WaveStats /Q/R=(imgIndex,imgIndex + numImages - 1) $(ProjectFolder + ":IndexedWaves:amplitude")
		amplitudeStdDev[alphaCount] = V_sdev
		amplitudeMean[alphaCount] = V_avg
		
		//Make wave for the absnum and amplitudes at various alpha values
		tempStr = ReplaceString(".",num2str(ii),"_");
		Duplicate /O /R=(imgIndex,imgIndex+numImages-1) $(ProjectFolder + ":IndexedWaves:absnum") $(ISatCalFolder + ":absnum_" + tempStr) 
		Duplicate /O /R=(imgIndex,imgIndex+numImages-1) $(ProjectFolder + ":IndexedWaves:amplitude") $(ISatCalFolder + ":amplitude_" + tempStr) 
		Wave temp_absnum = $(ISatCalFolder + ":absnum_" + tempStr)
		Wave temp_amplitude = $(ISatCalFolder + ":amplitude_" + tempStr)
		//print imgIndex
		//print imgIndex + numImages - 1
		//Generate slopes of absnum and amplitude as a function of ProbePow:
		CurveFit /N/Q /NTHR=0 line kwCWave=fitCoef temp_absnum /X=probePow
		//wave W_sigma = :W_sigma;
		absnum_slope[alphaCount] = fitCoef[1]
		
		CurveFit /N/Q /NTHR=0 line kwCWave=fitCoef temp_amplitude /X=probePow
		//wave W_sigma = :W_sigma;
		amplitude_slope[alphaCount] = fitCoef[1]
	
		alphaCount += 1
		imgIndex += numImages 
	endfor
	
	if (plot == 1)
		Display absnumStdDev vs :ISatCalibration:alphaIsat
		AppendToGraph/R absnum_slope vs :ISatCalibration:alphaIsat
		ModifyGraph mode(absnumStdDev)=3
		ModifyGraph mode(absnum_slope)=3,marker(absnum_slope)=8;
		ModifyGraph useMrkStrokeRGB(absnum_slope)=1;
		ModifyGraph mrkStrokeRGB(absnum_slope)=(0,0,52224)
		ModifyGraph zero(right)=1
		Label left "Atom Number Std Dev"
		Label bottom "Alpha"
		Label right "Atom Number Slope"
		CurveFit/NTHR=0/TBOX=768 gauss  absnumStdDev /X=:ISatCalibration:alphaIsat /D 
		CurveFit/NTHR=0 line  absnum_slope /X=:ISatCalibration:alphaIsat /D 
		ModifyGraph rgb(fit_absnum_slope)=(0,0,52224)
		Wave W_coef = :W_coef
		Wave W_sigma = :W_sigma
		Variable alpha0 = -W_coef[0]/W_coef[1]
		Variable zero_stdDev = alpha0*sqrt((W_sigma[0]/W_coef[0])^2 + (W_sigma[1]/W_coef[1])^2)
		String str = "zero slope: " + num2str(-W_coef[0]/W_coef[1]) + " ± " + num2str(zero_stdDev)
		TextBox/C/N=text0/A=MC str
		
		Display amplitudeStdDev vs :ISatCalibration:alphaIsat
		AppendToGraph/R amplitude_slope vs :ISatCalibration:alphaIsat
		ModifyGraph mode(amplitudeStdDev)=3
		ModifyGraph mode(amplitude_slope)=3,marker(amplitude_slope)=8;
		ModifyGraph useMrkStrokeRGB(amplitude_slope)=1;
		ModifyGraph mrkStrokeRGB(amplitude_slope)=(0,0,52224)
		ModifyGraph zero(right)=1
		Label left "Peak OD Std Dev"
		Label bottom "Alpha"
		Label right "Peak OD Slope"
		CurveFit/NTHR=0/TBOX=768 gauss  amplitudeStdDev /X=:ISatCalibration:alphaIsat /D 
		CurveFit/NTHR=0 line  amplitude_slope /X=:ISatCalibration:alphaIsat /D 
		ModifyGraph rgb(fit_amplitude_slope)=(0,0,52224)
		alpha0 = -W_coef[0]/W_coef[1]
		zero_stdDev = alpha0*sqrt((W_sigma[0]/W_coef[0])^2 + (W_sigma[1]/W_coef[1])^2)
		str = "zero slope: " + num2str(-W_coef[0]/W_coef[1]) + " ± " + num2str(zero_stdDev)
		TextBox/C/N=text0/A=MC str
	endif
	
end

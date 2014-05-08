#pragma rtGlobals=1		// Use modern global access method.
#include "BatchRun_v3_3_Sr"

// This updated version of the procedure loads files based on 
//	":Experimental_Info:BatchFileBasePath" (prompting user 
//	to set it, if it does not exist). As such, the basePath is stored 
//	in the ACTIVE Panel's file structure (in AI_Traces folder).
Function BatchLoadAI(startnum,endnum)
	variable startnum, endnum

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder ProjectFolder;

	// Make "AI_Traces" folder, if it doesn't already exist (won't overwrite existing contents)
	NewDataFolder/O/S AI_Traces	

	// Parse experiment name from ProjectFolder
	String ExperimentName="test"; // default val is "test"
	ExperimentName=StringByKey_Safe(ExperimentName,"root",ProjectFolder,":",";");

	// Check for AIBaseName
	if (exists(ProjectFolder+":Experimental_Info:AIBasePath")==0)
		Dialog_SetAIBasePath();
	endif
	SVAR BasePath=$(ProjectFolder+":Experimental_Info:AIBasePath");
	
	String filepath, temp, waveNameStr
	variable i
	for(i=startnum; i<=endnum; i+=1)
		sprintf temp "%.4f" i/10000
		temp = StringByKey("0",temp,".")
		filepath=BasePath+"_"+temp+".ibw"
		LoadWave/O filepath
		//All files have name AI_Traces, so rename
		Duplicate/O AI_Traces, $("AI_Traces"+num2str(i)); KillWaves AI_Traces
	endfor
	
	SetDataFolder fldrSav;		//return to user path
end

Function BatchGraphTrace(startnum, endnum,channel)
	variable startnum, endnum, channel
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder $(ProjectFolder+":AI_Traces");
	
	variable i
	for(i=startnum; i<=endnum; i+=1)
		WAVE w=$("AI_Traces"+num2str(i))
		if (i==startnum)
			Display w[][2*channel+1] vs w[][2*channel]					
		else
			AppendToGraph w[][2*channel+1] vs w[][2*channel]
		endif
	endfor
	
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph standoff=0
	//Label left "Fluorescence (V)"
	//Label bottom "Time (s)"
	//SetAxis bottom 0.95,1.15
	
	SetDataFolder fldrSav;		//return to user path
end

Function AppendTraces(startnum,endnum,channel)
	variable startnum,endnum,channel

	variable i
	for (i=startnum; i<=endnum; i+=1)
		Wave w=$("AI_Traces"+num2str(i))
		AppendToGraph w[][2*channel+1] vs w[][2*channel]
	endfor
end

Function SetAIBasePath(basePath)
	string basePath
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder ProjectFolder;

	// set BatchFileBasePath
	String/G $(ProjectFolder+":Experimental_Info:AIBasePath")=basePath

	SetDataFolder fldrSav;		//return to user path
end

// Pop-up dialog box requesting set base path for AI traces.
function Dialog_SetAIBasePath()
	
	String Months="January;February;March;April;May;June;July;August;September;October;November;December"
	String Days="01;02;03;04;05;06;07;08;09;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;31"
	String Years="2008;2009;2010;2011;2012;2013;2014;2015"

	String Month, Day, Year, Cam
	// Build Dialog Box
	Prompt Month, "Month", popup, Months
	Prompt Day, "Day", popup, Days
	Prompt Year, "Year", popup, Years
	DoPrompt "Set AI File basename", Month, Day, Year

	if(V_Flag)
		return -1		// User canceled
	endif
	
	//Form Base Name
	String baseName="C:Experiment:Data:"+Year+":"+Month+":"+Day+":AI_"+Day+Month[0,2]+Year;
	
	//set base name
	SetAIBasePath(baseName)
end

// Store base path for automatically loading Tek scope traces.
Function SetTekBasePath(basePath)
	string basePath
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder ProjectFolder;

	// set BatchFileBasePath
	String/G $(ProjectFolder+":Experimental_Info:TekBasePath")=basePath

	SetDataFolder fldrSav;		//return to user path
end

// Pop-up dialog box requesting set base path for Tek traces.
function Dialog_SetTekBasePath()
	
	String Months="January;February;March;April;May;June;July;August;September;October;November;December"
	String Days="01;02;03;04;05;06;07;08;09;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;31"
	String Years="2008;2009;2010;2011;2012;2013;2014;2015"

	String Month, Day, Year, Cam
	// Build Dialog Box
	Prompt Month, "Month", popup, Months
	Prompt Day, "Day", popup, Days
	Prompt Year, "Year", popup, Years
	DoPrompt "Set Tek File basename", Month, Day, Year

	if(V_Flag)
		return -1		// User canceled
	endif
	
	//Form Base Name
	String baseName="C:Experiment:Data:"+Year+":"+Month+":"+Day+":Tek_"+Day+Month[0,2]+Year;
	
	//set base name
	SetTekBasePath(baseName)
end



// --------------------------------------------------
//		Old stuff...

// Make wave of first point in each run to look at offset
Function CollectOffset(startnum, endnum, channel)
	variable startnum, endnum, channel
	
	Make/D/O/N=(endnum-startnum+1) Offset
	
	variable i, temp=0
	for(i=startnum; i<=endnum; i+=1)
		WAVE w=$("AI_Traces"+num2str(i))
		Offset[(i-startnum)] = w[0][2*channel+1]
		temp+=w[0][2*channel+1]
	endfor
	//print temp/(endnum-startnum+1)
	return temp/(endnum-startnum+1)
end

// Fit MOT load traces to extract rate and time constant and plot
Function AnalyzeMOTLoad(startnum, endnum, channel, scanVar, varStart, varEnd)
	variable startnum, endnum, channel
	string scanVar			// name of scanned experimental parameter
	variable varStart, varEnd	// starting/ending value for scanned parameter
	
	// Load the AI Traces
	// add check to see if alredy loaded?
	//BatchLoadAI(startnum, endnum)
	
	Make/D/O/N=((endnum-startnum+1),3*3+2) $(scanVar)
	WAVE parWave=$(scanVar)
	//SetScale/I x,varStart,varEnd, "MHz", parWave
	
	// Declare fit variables
	Wave W_fitConstants, W_sigma, W_coef, maskWave
	variable V_chisq
	
	// Fit waves and grab fit constants
	variable i
	for(i=startnum; i<=endnum; i+=1)
		WAVE w=$("AI_Traces"+num2str(i))
		
		// It's easier to use built in CurveFit and calculate R, offset
		CurveFit/M=2/W=0/Q exp_XOffset,  w[*][2*channel+1]/X=w[*][2*channel]//M=maskWave
		//calculate parameters of interest (bkgd=y0+A, R=-A/tau, tau)
		parWave[(i-startnum)][0] = W_coef[0] + W_coef[1]		//bkgd
		parWave[(i-startnum)][1] = -W_coef[1]/W_coef[2]			// R (loading rate)
		parWave[(i-startnum)][2] = W_coef[2]					// tau (loss time)
		// Store original fit variables
		parWave[(i-startnum)][3] = W_coef[0]				//y0
		parWave[(i-startnum)][4] = W_sigma[0]				//y0_sigma
		parWave[(i-startnum)][5] = W_coef[1]				//A
		parWave[(i-startnum)][6] = W_sigma[1]				//A_sigma
		parWave[(i-startnum)][7] = W_coef[2]				//tau
		parWave[(i-startnum)][8] = W_sigma[2]				//tau_sigma
		parWave[(i-startnum)][9] = W_fitConstants[0]			//Constant X0
		parWave[(i-startnum)][10] = V_chisq				//V_chisq
	endfor
	//KillWaves W_coef
	
	// Plot parameters
	Preferences 1
	Display parWave[][1];DelayUpdate 
	AppendToGraph/R parWave[][2];DelayUpdate
	Label left "Loading Rate (V s\\S-1\\M)";DelayUpdate
	Label bottom scanVar;DelayUpdate
	Label right "\\K(65280,0,0)Tau (s)"
end

Function SaveFitData(w,index)
	Wave w
	variable index
	
	Wave W_coef,W_sigma, W_fitConstants
	variable V_chisq
	
	w[(index)][0] = W_coef[0] + W_coef[1]		//bkgd
	w[(index)][1] = -W_coef[1]/W_coef[2]		// R (loading rate)
	w[(index)][2] = W_coef[2]					// tau (loss time)
	// Store original fit variables
	w[(index)][3] = W_coef[0]				//y0
	w[(index)][4] = W_sigma[0]			//y0_sigma
	w[(index)][5] = W_coef[1]				//A
	w[(index)][6] = W_sigma[1]			//A_sigma
	w[(index)][7] = W_coef[2]				//tau
	w[(index)][8] = W_sigma[2]			//tau_sigma
	w[(index)][9] = W_fitConstants[0]		//Constant X0
	w[(index)][10] = V_chisq				//V_chisq
	
end

// Plot AI trace data for 1D scans
Function PlotScan(wFits, xWave, col)
	Wave wFits, xWave
	variable col		// fit parameter, as given in the comments above
	
	Display wFits[][col] vs xWave; DelayUpdate
	ModifyGraph tick=2,mirror=1,standoff=0; DelayUpdate
	ModifyGraph mode=3,marker=19; DelayUpdate
	Label bottom "MOT Repump Detuning (MHz)"; 
	
end


// Plot AI trace data for 2D scans
Function PlotContour(baseName, col)
	string baseName
	variable col		// fit parameter, as given in the comments above
	
	variable r=13, c=11	// dimensions of the scan
	
	Make/D/O/N=(r,c) $(baseName + "2D_"+num2str(col))
	WAVE dw = $(baseName + "2D_"+num2str(col))
	SetScale/P x -30,3,"MHz", dw;DelayUpdate
	SetScale/P y -3,-3,"MHz", dw;
	
	variable i,j
	for (j=0; j<c; j+=1)
		WAVE w=$(baseName +"_"+ num2str(3*(j+1)))
		//WAVE w=$(baseName + num2str(j))
		for(i=0; i<r; i+=1)
			dw[i][j]=w[i][col]
		endfor
	endfor
	
	Display; AppendMatrixContour dw
end

//Calibrate number at fixed MOT detuning
Function Fluor2Num(MOTf_index)
	variable MOTf_index 	// sequence number (starting with 0) for desired MOT detuning
	
	WAVE num	// make sure PWD is correct...
	
	Make/D/O/N=(8,3) Num2Fluor2D
	WAVE dw=Num2Fluor2D
	
	variable i, offset=10, index, channel=7
	for(i=0; i<8; i+=1)
		index=MOTf_index+i*12+offset
		WAVE w=$("AI_Traces"+num2str(index))		// Fluorescence Wave
		
		dw[i][0] = num[index]			// number from abs img
		dw[i][1] = w[dimsize(w,0)][2*channel+1]		// sample last point of flurescence wave
		dw[i][2] = dw[i][0]/dw[i][1]		// number per volt (careful of gain!!)
	endfor
	
end




// Calculate Voltage from fit to calibrate number:
// 	parWave is the fit results from AnalyzeMOTLoad()
//	t is time in seconds along the fit
Function CalNumber(parWave, destWaveName,t)
	wave parWave
	string destWaveName
	variable t							// time is seconds to calc voltage
	
	variable n=DimSize(parWave,0)		// total points in wave
	Make/D/O/N=(n) $(destWaveName)
	WAVE destWave =$(destWaveName)
	
	variable i
	for(i=0; i<=n; i+=1)
		//evaluate y(t)=y0+Aexp(-t/tau)
		destWave[i] = (parWave[i][3]+parWave[i][5]*Exp(-t/parWave[i][7]))	
	endfor
end

// This function rescales a wave by a scaling function
//	We used it to convert Rb cell transmission to frequency.
Function BatchRescale(startnum, endnum,deltaT)
	variable startnum, endnum,deltaT
	WAVE sFunc=Trans2Freq //Scaling wave
	
	variable i
	String wsStr
	for(i=startnum; i<=endnum; i+=1)
		//Create target wave
		wsStr="AI_scaled"+num2str(i)
		Make/D/O/N=500 $wsStr
		WAVE ws=$wsStr
		// Change from Transmission voltage to Frequency with ScaleWave
		WAVE w=$("AI_Traces"+num2str(i))
		ws[]=sFunc(w[p][15])
		SetScale/P x 0,deltaT,"ms", $wsStr		//Add appropriate units
		SetScale d 0,0,"MHz", $wsStr
	endfor
end

// Offset a set of 'num' traces by 'sp' ("waterfall" plot)
Function Waterfall(num,sp)
	variable num, sp
	
	variable i
	for(i=0; i<num; i+=1)
		ModifyGraph offset[i]={0,sp*i}; DelayUpdate
	endfor
	
	DoUpdate
end

// Offset a set of 'num' traces by 'sp' ("waterfall" plot)
Function WaterfallSide(num,sp)
	variable num, sp
	
	variable i
	for(i=0; i<num; i+=1)
		ModifyGraph offset[i]={sp*i,0}; DelayUpdate
	endfor
	
	DoUpdate
end

// Offset a set of 'num' traces by 'sp' ("waterfall" plot)
Function WaterfallBoth(num,spx, spy)
	variable num, spx, spy
	
	variable i
	for(i=0; i<num; i+=1)
		ModifyGraph offset[i]={spx*i,spy*i}; DelayUpdate
	endfor
	
	DoUpdate
end

// waves are numbered [0,1,2,...]
Function WaterfallPartial(first, num,sp)
	variable first, num, sp
	
	variable i
	for(i=first; i<(num+first); i+=1)
		ModifyGraph offset[i]={0,sp*(i-first)}; DelayUpdate
	endfor
	
	DoUpdate
end
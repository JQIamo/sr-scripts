#pragma rtGlobals=1		// Use modern global access method.

#include "AILoadProcedures_v3_3_Sr"
#include "BatchRun_v3_3_Sr"

// 22Apr2012 -- CDH
// Wrote these procedures for more convenient processing of LightShift data.


// Copy Lattice Peak result wave
function CopyPeak(pkLabel)
	string pkLabel		// format "#(m,z,p)"
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder ProjectFolder;
	
	// Create file structure
	NewDataFolder/O root:Analysis
	NewDataFolder/O root:Analysis:RawPeaks
	
	// copy num_BEC and rename; also xpos, ypos.
	string newFol="root:analysis:RawPeaks"
	Duplicate/O $(":IndexedWaves:num_BEC"), $(newFol+":num_BEC_"+pkLabel)
	// only save position of central peak
	if( (strsearch(pkLabel,"z",0) > 0) )	// negative if not found
		Duplicate/O $(":IndexedWaves:xpos"), $(newFol+":xpos_"+pkLabel)
		Duplicate/O $(":IndexedWaves:ypos"), $(newFol+":ypos_"+pkLabel)
	endif
	
	SetDataFolder fldrSav	// Return path
end


// BatchRun + copy waves.
function BatchLatticePeak(startnum, endnum, pkLabel)
	variable startnum, endnum
	string pkLabel
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder ProjectFolder;
	
	NVAR autoupdate=:IndexedWaves:autoupdate
	NVAR findmax=:Fit_Info:findmax
	NVAR fit_type=:Fit_Info:fit_type
	NVAR slicewidth=:Fit_Info:slicewidth
	NVAR traptype=:Experimental_Info:traptype
	NVAR flevel=:Experimental_Info:flevel
	NVAR camdir=:Experimental_Info:camdir
	
	// Set fit settings to ensure consistency
	traptype=2 //Quad+Dipole
	flevel=1
	camdir=1	//XY imaging
	findmax=1	// set "Find center from max"
	fit_type=3	// TF only 1D
	slicewidth=4
		
	// SetROI based on pkLabel
	SVAR CurrentPanel = root:Packages:ColdAtom:CurrentPanel;
	String WindowName = CurrentPanel + "#ColdAtomInfoImage";
	if( (strsearch(pkLabel,"p",0) > 0) )	// top right ROI, negative if not found
		Cursor/I/P/W=$(WindowName) A, optdepth, (647-120), (487-120)
		Cursor/I/P/W=$(WindowName) B, optdepth, 647, 487
	elseif( (strsearch(pkLabel,"m",0) > 0) )	// bottom left ROI, negative if not found
		Cursor/I/P/W=$(WindowName) A, optdepth,0, 0
		Cursor/I/P/W=$(WindowName) B, optdepth, 120, 120
	else		// default,  assume center peak
		Cursor/I/P/W=$(WindowName) A, optdepth, (324-100), (244-100)
		Cursor/I/P/W=$(WindowName) B, optdepth, (324+100), (244+100)
	endif
	SetROI("",1,"") // Ensure ROI has been set
		
	// Auto increment, reset index (and clear num_BEC)
	ReInitializeIndexedWaves(ProjectFolder)
	autoupdate=1 // set auto increment

	// Do the fits; copy waves to :Analysis:RawPeaks
	BatchRun(startnum, endnum,0,"")
	CopyPeak(pkLabel)
	
	SetDataFolder fldrSav	// Return path
end

// Calculate frac, tot for lattice peaks
function AnalyzeLatticePeak(num)
	variable num
	
	// Get the current path
	String fldrSav= GetDataFolder(1);
	SetDataFolder root:Analysis:RawPeaks;
	
	// Make local references. Naming MUST be "num_BEC_#(m,p,z)".
	string baseName="num_BEC_"+num2str(num)
	WAVE wz=$(baseName+"z")
	WAVE wm=$(baseName+"m")
	WAVE wp=$(baseName+"p")
	// Creat result waves
	Duplicate/O wz, $("tot"+num2str(num)), $("frac"+num2str(num))
	WAVE wTot=$("tot"+num2str(num))
	WAVE wFrac=$("frac"+num2str(num))
	
	wTot = wz + wm + wp			// total fitted atoms
	wFrac = (wm + wp)/wTot		// total diffracted fraction
	
	// Display vs ypos, cull any points outside a range.
	
	SetDataFolder fldrSav	// reset Path
end

// automate analysis of multiple raw peak fits.
function BatchAnalyzeLatticePeaks(startnum,endnum)
	variable startnum, endnum
	
	variable i
	for(i=startnum; i<=endnum; i+=1)
		AnalyzeLatticePeak(i)
	endfor
end


// Grab average photodiode voltage from Tek scope traces.
//		We only want to pull the maximum signal. Do so by:
//			(1) Find entire pulse train average. Only keep points above 0.9*2*full_avg
//			(2) From average of resulting wave, re-cut at 95%
//			(3) Save final avg, sdev.
function PullPDVoltage(startnum, endnum)
	variable startnum, endnum
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
		
	// Create file structure
	NewDataFolder/O root:Analysis
	NewDataFolder/O/S root:Analysis:PDtraces
	
	// Create waves to store average voltate, sdev
	variable npnts=(endnum-startnum+1)
	Make/O/N=(npnts) PD_Voltage_avg
	SetScale/I x, startnum, endnum, "fnum", PD_Voltage_avg	// x-scale is filenum
	Duplicate/O PD_Voltage_avg, PD_Voltage_sdev
	WAVE wAvg=PD_Voltage_avg
	WAVE wSdev=PD_Voltage_sdev
	
	// Check for AIBaseName, prompt if necessary
	if (exists(ProjectFolder+":Experimental_Info:TekBasePath")==0)
		Dialog_SetTekBasePath();
	endif
	SVAR BasePath=$(ProjectFolder+":Experimental_Info:TekBasePath");
	
	// Load and process each wave
	String filepath, temp
	variable i, nrows
	for(i=startnum; i<=endnum; i+=1)
		sprintf temp "%.4f" i/10000
		temp = StringByKey("0",temp,".")
		filepath=BasePath+"_"+temp+".ibw"
		LoadWave/O/Q filepath
		
		// Loaded wave has name "PDvoltage". Wavenote contains time-scaling.
		WAVE wTek=PDvoltage
		SetScale/P x 0,(str2num(note(wTek))),"s",wTek
		SetScale/I d 0,0,"V", wTek
		
		Duplicate/O PDvoltage, PDvoltage_peaks
		WAVE wTek_peaks=PDvoltage_peaks
		// Find rough average from average of pulse train (to remove influnce of outlier max)
		wavestats/Q wTek
		wTek_peaks*=(WTek>(0.9*2*V_avg)? 1 : Nan)
		// Refine based on 95% average of rough estimate
		wavestats/Q wTek_peaks
		wTek_peaks*=(WTek>(0.95*V_avg)? 1: Nan)
		wavestats/Q wTek_peaks	// calculate final average
		// note: looked at removing baseline, but it was ~1-2 mV +/- 1-2mV.
		
		// save average in PD_Voltage_ waves
		PD_Voltage_avg[(i-startnum)]=V_avg
		PD_Voltage_sdev[(i-startnum)]=V_sdev	
	endfor
	
	print "Saved results for "+num2str(npnts)+" shots in PD_voltage_avg/_sdev."
	Display PD_voltage_avg 
	ModifyGraph mode=2, tick=2, mirror=1, standoff=0
	ErrorBars PD_Voltage_avg Y,wave=(PD_Voltage_sdev,PD_Voltage_sdev)
	Label left "PD voltage (V)"; Label bottom "File number"
	
	SetDataFolder fldrSav	// Return path
end

// break up long series into lambda-label voltages
function SplitPDvoltage(stnum, endnum)
	variable stnum, endnum		//set-label numbers
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder root:Analysis
	
	// wave references for PDavg, PDsdev -- x-scaled by filenum
	WAVE wPDavg= :PDtraces:PD_Voltage_avg
	WAVE wPDsdev = :PDtraces:PD_Voltage_sdev
	// These waves contain first and last filenumbers, with x-scaling by set-label
	WAVE w_st = fnum_st
	WAVE w_end = fnum_end
	
	variable i, p_st, p_end, npnts
	for (i=stnum; i<=endnum; i+=1)
		// get p reference (no x-scaling in functions)
		p_st= x2pnt( wPDavg, w_st[x2pnt(w_st, i)] )
		p_end= x2pnt( wPDavg, w_end[x2pnt(w_end, i)] )
		npnts=(p_end-p_st+1)
		
		// save waves by set-label
		Duplicate/O/R=[p_st,p_end] wPDavg, $(":PDtraces:PD_Voltage_avg"+num2str(i))
		Duplicate/O/R=[p_st,p_end] wPDsdev, $(":PDtraces:PD_Voltage_sdev"+num2str(i))
		SetScale/P x, (w_st[x2pnt(w_st, i)]),1,"fnum", $(":PDtraces:PD_Voltage_avg"+num2str(i)),$(":PDtraces:PD_Voltage_sdev"+num2str(i))
	endfor
	
	SetDataFolder fldrSav
end


// Rescale fraction data by PD voltage
function RescaleByPD(stnum, endnum)
	variable stnum, endnum		// set-labels, not f-num.
	
	// Get the current path
	String fldrSav= GetDataFolder(1);
	SetDataFolder root:Analysis
	
	WAVE wPDV = :PDtraces:PD_Voltage_avg
	WAVE w_st = fnum_st
	WAVE w_end = fnum_end
	
	variable i, p_st, p_end
	for (i=stnum; i<=endnum; i+=1)
		Duplicate $(":RawPeaks:frac"+num2str(i)), $("frac"+num2str(i)+"_PDscaled")
		WAVE wFsc = $("frac"+num2str(i)+"_PDscaled") // local ref to scaled wave
		// calculate the p-index in PDvoltage wave
		p_st= x2pnt(wPDV, w_st[(x2pnt(w_st,i))])
		p_end= x2pnt(wPDV, w_end[(x2pnt(w_end,i))])
		// make temp. wave from range
		Duplicate/O/R=[p_st,p_end] wPDV, wInt
		wFsc/=wInt
	endfor
	KillWaves wInt
	
	SetDataFolder fldrSav
end

// Plot set-labeled items versus one-another.
//		function assumes all base-names are give w.r.t. :Analysis:
function PlotVSLabel(ystr, yapp, xstr, xapp, stnum, endnum)
	string ystr, yapp, xstr, xapp
	variable stnum, endnum
	
	// Get the current path
	String fldrSav= GetDataFolder(1);
	SetDataFolder root:Analysis
	
	variable i
	for (i=stnum; i<=endnum; i+=1)
		// waves to plot
		WAVE wy=$(ystr+num2str(i)+yapp)
		WAVE wx=$(xstr+num2str(i)+xapp)
		if (i==stnum)
			print ystr+num2str(i)+yapp+" vs "+xstr+num2str(i)+xapp
			Display wy vs wx
		else
			print ystr+num2str(i)+yapp+" vs "+xstr+num2str(i)+xapp
			AppendToGraph wy vs wx
		endif
	endfor
	ModifyGraph tick=2,mirror=1,standoff=0
	
	SetDataFolder fldrSav
end

// Run wavestats on item located at dataStr (assuming w.r.t. Analysis folder)
//		Creates summary wave for avg, sdev
function CollectStats(dataStr, appStr, stnum, endnum)
	string dataStr, appStr		// app str comes after set-label (i.e. xpos_3z)
	variable stnum, endnum 	// set-label

	// Get the current path
	String fldrSav= GetDataFolder(1);
	SetDataFolder root:Analysis
	
	// Create waves to save average, sdev
	Make/D/O/N=(endnum-stnum+1) $(dataStr+appstr+"_avg")
	WAVE wAvg = $(dataStr+appstr+"_avg")
	SetScale/I x,stnum, endnum, "", wAvg
	Duplicate/O wAvg, $(dataStr+appstr+"_sdev")
	WAVE wSdev = $(dataStr+appstr+"_sdev")
	
	variable i
	for (i=stnum; i<=endnum; i+=1)
		WAVE wData = $(dataStr+num2str(i)+appstr)
		wavestats/Q wData
		
		wAvg[(i-stnum)]=V_avg
		wSdev[(i-stnum)]=V_sdev
	endfor
	
	SetDataFolder fldrSav
end

// Get LS from frac data and get statistics.
function CollectLS(fracStr, appStr, stnum, endnum)
	string fracStr, appStr
	variable stnum, endnum		//set-label
	
	// Get the current path
	String fldrSav= GetDataFolder(1);
	SetDataFolder root:Analysis
	
	// reference number of pulses (x-pnt scaling to set-label)
	WAVE wN=Npulses
	
	variable i, N
	for (i=stnum; i<=endnum; i+=1)
		WAVE wF=$(fracStr+num2str(i)+appStr)
		Duplicate/O wF, $("LS"+num2str(i)+appStr)
		WAVE wLS=$("LS"+num2str(i)+appStr)
		
		// get number of pulses
		N=wN[x2pnt(Npulses,i)]
		
		// calculate light shift
		wLS = Pop2LS( wF[p], N )
	endfor
	// get average, sdev
	CollectStats("LS", appStr, stnum, endnum)
	
	SetDataFolder fldrSav
end




// Maps total 2 hbar k  population to lightshift
//		Based on Mathematica simulation... these numbers from 11 pulses, N*V up to 15.
function Pop2LS(frac, Npulses)
	variable frac, Npulses
	
	return asin(sqrt(frac/0.94))/(0.181*Npulses)
end


//---------------------------------------------------------------
//		older procedures...

// Collects statistics from lambda-points, after taking sqrt(frac#) and
//	optionally scaling by PDvoltage.
//		startnum, endnum = run labels
//		intMode	= 0: scale intensity by norm. Retro Power. (default)
//				= 1: scale by PD voltage.
//	procdure ASSUMES waves PD_Voltage_avg, fnum_(st,end) in ProjectFolder:AI_Traces.
function CalcLightShiftSqrt(startnum, endnum, subFldrStr, appStr, intMode)
	variable startnum, endnum, intMode
	string subFldrStr	// path RELATIVE to "Analysis" folder (no leading ":")
	string appStr	// pass "" for appStr if starting from frac.

	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder $(ProjectFolder+":AI_Traces")

	
	// reference PD_voltage, and filenumber start/end waves
	WAVE w_st = fnum_st
	WAVE w_end = fnum_end
	WAVE wPDV = PD_Voltage_avg	// x-scaling is filenumber.
		
	// Create result waves
	SetDataFolder root:Analysis
	WAVE wPow_rel = P_retro_rel// retro power, relative to average PER LAMBDA point
	
	variable npnts=(endnum-startnum+1)
	if(intMode==1)
		Make/D/O/N=(npnts) $("LSsqrt"+appStr+"_scaled")
		WAVE wLSavg = $("LSsqrt"+appStr+"_scaled")
		Duplicate/O wLSavg, $("LSsdev"+appStr+"_scaled")
		WAVE wLSsdev = $("LSsdev"+appStr+"_scaled")
	else
		Make/D/O/N=(npnts) $("LSsqrt"+appStr)
		WAVE wLSavg = $("LSsqrt"+appStr)
		Duplicate/O wLSavg, $("LSsdev"+appStr)
		WAVE wLSsdev = $("LSsdev"+appStr)
	endif
	
	// compute statistics
	variable i, p1, p2
	for (i = startnum; i <= endnum; i += 1)
		
		// Calculate sqrt of population (prop. to lattice depth)
		WAVE wFrac=$(":"+subFldrStr+":frac"+num2str(i)+appStr)
		Duplicate/O wFrac, $("sqrt"+num2str(i)+appStr)
		WAVE wSqrt=$("sqrt"+num2str(i)+appStr)
		wSqrt=sqrt(wFrac)			// lattice depth proportional to sqrt of population fraction
		
		// Re-scale by PD voltage before calculating wavestats, if requested.
		if (intMode==1)		// scale by PD voltage PER SHOT
			Duplicate/O wSqrt, $("sqrt"+num2str(i)+appStr+"_scaled")
			WAVE wSqrt=$("sqrt"+num2str(i)+appStr+"_scaled")		// reassign local reference
			
			p1=x2pnt(wPDV, (w_st[x2pnt(w_st,i)]))	// get point from file number.
			p2=x2pnt(wPDV,w_end[x2pnt(w_end,i)])
			Duplicate/O/R=[p1,p2] wPDV, wInt			// make temporary PD intenisty wave from range
			
			wSqrt/=wInt		// scale by intensity (sqrt(frac) ~ light shift ~ intensity)
		else
			wSqrt/= wPow_rel[(i-startnum)]	// simply scale by P-retro for that lambda-point
		endif
		
		wavestats/Q wSqrt		// wavestats writes to numeric vars V_(stat)
		wLSavg[i-startnum] = V_avg
		wLSsdev[i-startnum] = V_sdev
	
	endfor
	KillWaves wInt		// delete temporary wave
	
	SetDataFolder fldrSav	//reset Path
end

// Fit to population data (w/ parabola)
//		startnum, endnum = run labels
//		intMode	= 0: scale intensity by norm. Retro Power. (default)
//				= 1: scale by PD voltage.
//	procdure ASSUMES waves PD_Voltage_avg, fnum_(st,end) in ProjectFolder:AI_Traces.
function CalcLightShiftPop(startnum, endnum, subFldrStr, appStr, intMode)
	variable startnum, endnum, intMode
	string subFldrStr	// path RELATIVE to "Analysis" folder (no leading ":")
	string appStr	// pass "" for appStr if starting from frac.
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder $(ProjectFolder+":AI_Traces")

	
	// reference PD_voltage, and filenumber start/end waves
	WAVE w_st = fnum_st
	WAVE w_end = fnum_end
	WAVE wPDV = PD_Voltage_avg	// x-scaling is filenumber.
		
	// Create result waves
	SetDataFolder root:Analysis
	WAVE wPow_rel = P_retro_rel// retro power, relative to average PER LAMBDA point	
	
	variable npnts=(endnum-startnum+1)
	if(intMode==1)
		Make/D/O/N=(npnts) $("LSpop"+appStr+"_scaled")
		WAVE wLSavg = $("LSpop"+appStr+"_scaled")	
		Duplicate/O wLSavg, $("LSpop_sdev"+appStr+"_scaled")
		WAVE wLSsdev = $("LSpop_sdev"+appStr+"_scaled")
	else
		Make/D/O/N=(npnts) $("LSpop"+appStr)
		WAVE wLSavg = $("LSpop"+appStr)
		Duplicate/O wLSavg, $("LSpop_sdev"+appStr)
		WAVE wLSsdev = $("LSpop_sdev"+appStr)
	endif
	
	// compute statistics
	variable i, p1, p2
	for (i = startnum; i <= endnum; i += 1)
		
		// Calculate sqrt of population (prop. to lattice depth)
		WAVE wFrac=$(":"+subFldrStr+":frac"+num2str(i)+appStr)
		Duplicate/O wFrac, $("pop"+num2str(i)+appStr)
		WAVE wPop=$("pop"+num2str(i)+appStr)
		
		// Re-scale by PD voltage before calculating wavestats, if requested.
		if (intMode==1)		// scale by PD voltage PER SHOT
			Duplicate/O wPop, $("pop"+num2str(i)+appStr+"_scaled")
			WAVE wPop=$("pop"+num2str(i)+appStr+"_scaled")		// reassign local reference
			
			p1=x2pnt(wPDV, (w_st[x2pnt(w_st,i)]))	// get point from file number.
			p2=x2pnt(wPDV,w_end[x2pnt(w_end,i)])
			Duplicate/O/R=[p1,p2] wPDV, wInt			// make temporary PD intenisty wave from range
			wInt=wInt^2;
			wPop/=wInt	// scale by intensity^2 (frac ~ light shift^2 ~ intensity^2)
		else
			wPop/= (wPow_rel[(i-startnum)])^2	// simply scale by P-retro for that lambda-point	
		endif
		
		wavestats/Q wPop	// wavestats writes to numeric vars V_(stat)
		wLSavg[i-startnum] = V_avg
		wLSsdev[i-startnum] = V_sdev
	
	endfor
	KillWaves wInt		// delete temporary wave
	
	SetDataFolder fldrSav	//reset Path
end

// Culling data by y-position
//
//	We've noticed that the weakest diffraction points at a give lambda are correlated to an extreme yposition.
//	This function will collect and plot the data for comparision and determination of ypos cutoffs.
function PlotPeaksVs(pkWaveBase, startnum, endnum, xWaveStr)
	string pkWaveBase, xWaveStr
	variable startnum, endnum
	
	// set directory arrow
	String fldrSav= GetDataFolder(1);
	SetDataFolder $("root:Analysis:RawPeaks")
	
	string destFolderStr = "root:Analysis:CullTest"
	NewDataFolder/O $(destFolderStr)
	
	Display; // create plot to append traces to
	variable i
	string pkWaveStr
	for (i=startnum; i<=endnum; i+=1)
	
	// make normalized waves for easier comparison
	pkWaveStr = pkWaveBase+num2str(i)
	NormPeak(pkWaveStr, destFolderStr)
	
	//Plot normalized peaks
	WAVE wNorm=$(destFolderStr+":"+pkWaveStr+"_norm")
	WAVE xW=$(xWaveStr+"_"+num2str(i)+"z")
	
	AppendToGraph wNorm vs xW
	endfor
	
	// Clean up graph
	ModifyGraph mode=3, marker=8
	ModifyGraph tick=2, mirror=1, standoff=0
	Label left "Norm. "+pkWaveBase
	Label bottom xWaveStr
	
	SetDataFolder fldrSav	//reset Path
end

// Called by PlotPeaksVS; normalizes points to average for comparison plotting
function NormPeak(pkWaveStr, destFolderStr)
	string pkWaveStr, destFolderStr
	
	// Duplicate wave (assuming function called after putting directory in right place)
	WAVE wPk=$(pkWaveStr)
	Duplicate/O wPk, $(destFolderStr+":"+pkWaveStr+"_norm")
	WAVE wNorm=$(destFolderStr+":"+pkWaveStr+"_norm")
	
	// normalize wave
	wavestats/Q wPk
	wNorm/=V_avg
end

// Normalize set to average.
function NormPeaks(pkWaveBase, stnum, endnum, appendStr, pkWaveFldrStr, destFolderStr)
	string pkWaveBase, pkWaveFldrStr, appendStr, destFolderStr
	variable stnum, endnum
	
	// set directory arrow
	String fldrSav= GetDataFolder(1);
	SetDataFolder $pkWaveFldrStr
	
	variable i
	string pkWaveStr
	for (i=stnum; i<=endnum; i+=1)
		pkWaveStr=pkWaveBase+num2str(i)+appendStr
		NormPeak(pkWaveStr, destFolderStr)
	endfor
	
	SetDataFolder fldrSav	// reset Path
end

// We want to remove those shots where ypos is outside a given region.
function CullPeaks(startnum, endnum, ymin, ymax)
	variable startnum, endnum	// lambda-point label
	variable ymin, ymax	// in um, boundaries for "extreme" ypos

	// set directory arrow
	String fldrSav= GetDataFolder(1);
	SetDataFolder $("root:Analysis:RawPeaks")
	
	string destFolderStr = "root:Analysis:CullTest"
	NewDataFolder/O $(destFolderStr)
	
	// duplicate frac waves, removing "extreme" points
	variable i
	for (i=startnum; i<=endnum; i+=1)
		WAVE wFrac = $("frac" + num2str(i))
		Duplicate wFrac, $(destFolderStr+":frac"+num2str(i)+"_culled")
		WAVE wCull = $(destFolderStr+":frac"+num2str(i)+"_culled")
		WAVE wY=$("ypos_"+num2str(i)+"z")
		
		wCull*=( wY > ymax ? NaN : 1)
		wCull*=( wY < ymin ? NaN : 1)
	endfor
	

	SetDataFolder fldrSav	//reset Path	
end




// --------------------------------------------------
//		PD voltage for Light Shift zero measurements (4/2012)
// --------------------------------------------------
//	We recorded lattice laser intensity on AI1_7 with a 10 ms pulse (1 ms lead-in and end).
//		This will pull avg and sdev from final third of pulse.
//	NO NEED to run any "load" functions as written!
function PullPDVoltage_old(startnum, endnum)
	variable startnum, endnum
	
	// Get the current path
	String ProjectFolder = Activate_Top_ColdAtomInfo();
	String fldrSav= GetDataFolder(1);
	SetDataFolder $(ProjectFolder+":AI_Traces");
	
	// Create waves to store average voltate, sdev
	variable npnts=(endnum-startnum+1)
	Make/O/N=(npnts) PD_Voltage_avg
	SetScale/I x, startnum, endnum, PD_Voltage_avg
	Duplicate/O PD_Voltage_avg, PD_Voltage_sdev
	//WAVE wAvg=PD_Voltage_avg
	//WAVE wSdev=PD_Voltage_sdev
	
	// Check for AIBaseName, prompt if necessary
	if (exists(ProjectFolder+":Experimental_Info:AIBasePath")==0)
		Dialog_SetAIBasePath();
	endif
	SVAR BasePath=$(ProjectFolder+":Experimental_Info:AIBasePath");
	
	// Load and process each wave
	String filepath, temp, waveNameStr
	variable i, nrows
	for(i=startnum; i<=endnum; i+=1)
		sprintf temp "%.4f" i/10000
		temp = StringByKey("0",temp,".")
		filepath=BasePath+"_"+temp+".ibw"
		LoadWave/O/Q filepath
		
		// Loaded wave has name AI_Traces. Pull PD_Trace and set time scale.
		WAVE wAI=AI_Traces
		nrows=dimSize(wAI,0)
		Make/O/N=(nrows) PD_Trace
		PD_Trace=wAI[p][15]	// 15th col has ch. 7
		SetScale/I x, (1000*wAI[0][14]), (1000*wAI[npnts-1][14]), "ms", PD_Trace
		
		// get statistics on last third, save in PD_Voltage_ waves
		WaveStats/Q/R=(7.0,10.7) PD_Trace
		PD_Voltage_avg[(i-startnum)]=V_avg
		PD_Voltage_sdev[(i-startnum)]=V_sdev	
	endfor
	
	print "Saved results for "+num2str(npnts)+" shots in PD_voltage_avg/_sdev."
	Display PD_voltage_avg 
	ModifyGraph mode=2, tick=2, mirror=1, standoff=0
	ErrorBars PD_Voltage_avg Y,wave=(PD_Voltage_sdev,PD_Voltage_sdev)
	Label left "PD voltage (V)"; Label bottom "File number"
	
	SetDataFolder fldrSav	// Return path
end

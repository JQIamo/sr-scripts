#pragma rtGlobals=2	// Use modern global access method and no compatability mode
//! @file
//! @brief Various tools and menus for making Figures

// ===================================================================
// Create Menu Items for these tools
// ===================================================================

//! @cond DOXY_HIDE_GRAPH_MENU
Menu "Graph"
	Submenu "ColdAtom Figures..."
			"Clean and Process Graph", Call_FormatGraph()
			"Add Legend", AddGenericLegend("")
			"Label Axes", Label_Axes()
			"Label dIdV vs V", Label_dIdV_vs_V()
	End
End
//! @endcond

// ===================================================================
// Analysis Functions
// ===================================================================

//!
//! @brief Extract a column from a specified matrix
//! @details Also sets all the scaling and dimensions to match the initial wave.
//!
//! @warning \p yvalue refers to the actual scaled value, not the index
//! @param[in]  yvalue  The value (<b>NOT INDEX</b>) to extract data from \p zwave 
//! @param[in]  zwave   Wave to extract values from
//! @param[out] newwave Wave to put the extracted data in, <em>will be overwritten</em>
function ColFromMatrix(yvalue, zwave, newwave)
	// Ian Spielman 7-7-99
	// Updated for NIST image processing 14Aug2004

	variable yvalue
	wave zwave, newwave
	Variable j, index
	variable xsize, ysize
	variable xmin, xmax
	xsize = DimSize(zwave, 0)
	ysize = DimSize(zwave, 1)
	
	// Make the wave the correct size
	make/O/N=(xsize) newwave
	
	// x axes loop
	j = 0;
	do
		newwave[j] = zwave[j](yvalue)
		j += 1
	while(j < xsize)
	
	// Now put the proper wave stats in
	xmin = DimOffset(zwave,0)
	xmax = DimOffset(zwave,0) + DimSize(zwave,0)*DimDelta(zwave,0)
	SetScale/I x xmin, xmax, WaveUnits(zwave, 0), newwave
End

//!
//! @brief Extract a row from a specified matrix
//! @details Also sets all the scaling and dimensions to match the initial wave.
//!
//! @warning \p xvalue refers to the actual scaled value, not the index
//! @param[in]  xvalue  The value (<b>NOT INDEX</b>) to extract data from \p zwave 
//! @param[in]  zwave   Wave to extract values from
//! @param[out] newwave Wave to put the extracted data in, <em>will be overwritten</em>
function RowFromMatrix(xvalue, zwave, newwave)
	// Ian Spielman 7-7-99
	// Updated for NIST image processing 14Aug2004

	variable xvalue
	wave zwave, newwave
	Variable j, index
	variable xsize, ysize
	variable ymin, ymax
	xsize = DimSize(zwave, 0)
	ysize = DimSize(zwave, 1)

	// Make the wave the correct size
	make/O/N=(ysize) newwave
	
	// y axes loop
	j = 0;
	do
		newwave[j] = zwave(xvalue)[j]
		j += 1
	while(j < ysize)
	
	// Now put the proper wave stats in
	ymin = DimOffset(zwave,0)
	ymax = DimOffset(zwave,0) + DimSize(zwave,0)*DimDelta(zwave,0)
	SetScale/I x ymin, ymax, WaveUnits(zwave, 0), newwave
End


// ===================================================================
// Begin Functions
// ===================================================================

//!
//! @brief Calls a dialog to get user input on graph formatting decisions.
//! @return \b 0 on success
//! @return \b -1 on user cancellation
function Call_FormatGraph()
	// [[No idea what the following two lines of comment were in reference to ZSS 2015-01-09]]
	// Ian Spielman 06Sep01
	// This function calls the Load_Four_Wire_Data Function, and asks the
	// User for the proper parameters
	string xlabel="b", ylabel="r"
	variable voltagescale=10E-6,current=1E-8
	string pathname="",filename=""
	variable Destination=1, AddLegend = 1, FormattingAdvice=1, ToCommandLine=2
	
	
	// Build the User Dialog Box
	Prompt Destination, "Destination", popup "Lab; Presentation; PRL; Nature; Science; Rev. Sci. Inst.; Thesis"
	Prompt AddLegend, "Legend", popup "No; Yes"
	Prompt FormattingAdvice, "Advice", popup "No; Yes"
	Prompt ToCommandLine, "Display Command", popup "No; Yes"
	DoPrompt "Graph Layout", Destination, AddLegend, FormattingAdvice, ToCommandLine
	
	if (V_Flag)
		return -1		// User cancelled
	endif
	
	FormatGraph(Destination, AddLegend, FormattingAdvice-1);

	if (ToCommandLine == 2) 
		printf "¥FormatGraph(%d, %d, %d)\r", Destination, AddLegend, FormattingAdvice-1
	endif
	
	return 0
End

//!
//! @brief This function makes an Igor graph obey specific formatting rules proper for 
//! specific venues
//! @note Expected to be called only from ::Call_FormatGraph
//! @details Valid options for Journal are
//!  + "Lab"  = 1
//!  + "Presentations" = 2
//!  + "PRL" = 3
//!  + "Nature" = 4   [Reduction to 80% size]
//!  + "Science" = 5
//!  + "Review of Scientific Instrumentation" = 6
//!  + "Thesis" = 7
//! @param[in] Journal   Numeric option indicating which journal
//! @param[in] AddLegend Value of 2 includes a legend
//! @param[in] Advice    Value of 1 gives advice
function FormatGraph(Journal, AddLegend, Advice)
	
	Variable Journal, AddLegend, Advice;
	
	Variable temp
	String Axes
	
	// First do the generic journal independent stuff
	HideInfo
	ModifyGraph tick=2,standoff=0,btLen=3,stLen=2
	ModifyGraph grid=0,minor=0
	// SetAxis/A/N=1

	If (AddLegend == 2)
		AddGenericLegend("")
	endif

	// Only mirror if no opposite axes
	Axes = AxisList("");
	if (stringmatch(Axes, "!*right*" ))
		ModifyGraph mirror(left)=1		
	Endif
	if (stringmatch(Axes, "!*left*" ))
		ModifyGraph mirror(right)=1		
	Endif
	if (stringmatch(Axes, "!*top*" ))
		ModifyGraph mirror(bottom)=1		
	Endif
	if (stringmatch(Axes, "!*bottom*" ))
		ModifyGraph mirror(top)=1		
	Endif

	if (Journal == 1) // For Internal Use
		// Print "Formatting for Lab Use..."
		// Line Thickness Stuff
		// ModifyGraph lsize=0.5
		ModifyGraph gFont="CMU Serif Roman"
		ModifyGraph gfSize=12
		ModifyGraph zeroThick=0.5
		ModifyGraph axThick=0.5
		ModifyGraph btThick=0.5
		ModifyGraph ftThick=0.5
		ModifyGraph stThick=0.5
		ModifyGraph ttThick=0.5
		
		// Colorize the trace
		IBSColorizeTraces( 1, 1)
	endif

	if (Journal == 2) // For Presentations
		Print "Formatting for Presentations..."
		ModifyGraph gFont="Cochin", gfSize=14
		// Line Thickness Stuff
		ModifyGraph lsize=2
		ModifyGraph zeroThick=2
		ModifyGraph axThick=2
		
		ModifyGraph margin=37
		ModifyGraph margin(top)=12
		
		ModifyGraph width=180,height=166
		
	endif

	if (Journal == 3) // For PRL
		print "Formatting Figure for PRL..."
		// PRL figures look best with NewCentury Schoolbook Fonts
		ModifyGraph gFont="CMU Serif Roman", gfSize=9// , rgb=(0,0,0)
		
		// Line Thickness Stuff
		ModifyGraph lsize=0.5
		ModifyGraph zeroThick=0.5
		ModifyGraph axThick=0.5
		ModifyGraph btThick=0.5
		ModifyGraph ftThick=0.5
		ModifyGraph stThick=0.5
		ModifyGraph ttThick=0.5

		// The Figure should be 250points wide
		ModifyGraph width=180
	endif

	if (Journal == 4) // For Nature Assuming Reduction to 80%
		print "Formatting Figure for Nature..."
		// Nature requires Arial fonts at 8 point AFTER REDUCTION
		ModifyGraph gFont="Arial", gfSize=10, rgb=(0,0,0)

		// Line Thickness Stuff
		ModifyGraph lsize=0.31
		ModifyGraph zeroThick=0.31
		ModifyGraph axThick=0.31
		ModifyGraph btThick=0.31
		ModifyGraph ftThick=0.31
		ModifyGraph stThick=0.31
		ModifyGraph ttThick=0.31

		// The Figure should be 112mm wide (317 points)
		ModifyGraph width=317
		if (Advice == 1) //See if the user wants advice on Nature Figures
			Print "0 - The figure should be 112mm wide for reduction to 80%, with 10 point Arial font"
			Print "1 - All lettering should be in lower case with the fist letter capatlized"
			Print "2 - Units should have a single space between the number and the unit"
			Print "     and should be SI, or use the nomeclature common to the field.  Thousands"
			Print "     should be sepeaited by a comma, e.g. 1,000"
			Print "3 - Use scale bars instead of magnification factors, with the length of the bar"
			print "     defined in the legend, rather than on the bar itself"
			Print "4 - Be sure Text is always over white.  Create a white box for the text if needed"
			Print "5 - Where possible text, including keys to symbols, should be in the legand"
			Print "     rather than on the figure"
		endif
	endif

	if (Journal == 5) // For Science Assuming Single collums wide
		print "Formatting Figure for Science"
		// Science requires Arial fonts at 8 point AFTER REDUCTION
		ModifyGraph height=0,gFont="Helvetica",gfSize=9
		
		// Line Thickness Stuff
		ModifyGraph lsize=1
		ModifyGraph zeroThick=1
		ModifyGraph axThick=1
		ModifyGraph btThick=1
		ModifyGraph ftThick=1
		ModifyGraph stThick=1
		ModifyGraph ttThick=1
		ModifyGraph lblMargin(bottom)=10
		// The Figure should be 2.3" wide (165.6) for a single collumn
		ModifyGraph width=165.6
		ModifyGraph margin(left)=33,margin(bottom)=36
		ModifyGraph margin(top)=10, margin(right)=12

		ModifyGraph width=(165.6 - 33 - 12)
		ModifyGraph height=(165.6 - 36 - 10)

		if (Advice == 1) //See if the user wants advice on Nature Figures
			Print "No advice right now"
		endif
	endif

	
	if (Journal == 6) // For Rev. Sci. Inst
		print "Formatting Figure for Rev. Sci. Inst..."
		// Rev. Sci. Inst.  figures lrequire with New Times roman
		ModifyGraph gFont="CMU Serif Roman", gfSize=10, rgb=(0,0,0)
		
		// Line Thickness Stuff
		ModifyGraph lsize=0.5
		ModifyGraph zeroThick=0.5
		ModifyGraph axThick=0.5
		ModifyGraph btThick=0.5
		ModifyGraph ftThick=0.5
		ModifyGraph stThick=0.5
		ModifyGraph ttThick=0.5

		// The Figure should be 243 points wide (3 3/8", 72 points/inch)
		ModifyGraph width=243
	endif

	if (Journal == 7) // Thesis
		print "Formatting Figure for IBS thesis..."
		ModifyGraph gFont="CMU Serif Roman", gfSize=11, rgb=(0,0,0)
		
		// Line Thickness Stuff
		ModifyGraph lsize=0.5
		ModifyGraph zeroThick=0.5
		ModifyGraph axThick=0.5
		ModifyGraph btThick=0.5
		ModifyGraph ftThick=0.5
		ModifyGraph stThick=0.5
		ModifyGraph ttThick=0.5

		// The Figure should be 243 points wide (3 3/8", 72 points/inch)
		ModifyGraph width=243
	endif

	
End

//!
//! @brief Extracts information from the "note" field of a wave
//! and uses it to build a legend for the graph in question 
//! @param[in] GraphName Name of graph to add a legend to. Empty String uses top graph.
function AddGenericLegend(GraphName)
	string GraphName
	string ListOfTraces, LegendString,CurrentWave, NoteString;
	variable i, items;
	Wave TraceWave;
	// This function extracts information from the "note" field of a wave
	// and uses it to build a legend for the graph in question
	// "" for graphname will use the top graph


	// first get a list of the waves on the graph
	ListOfTraces =  TraceNameList(GraphName, ";", 1 );
	items = ItemsInList(ListOfTraces);
		
	// Now loop over these guys
	for(i = 0;i < items;i = i + 1)
		// Get The Full Path Info from the wave
		CurrentWave = StringFromList(i, ListOfTraces);
		NoteString = GetWavesDataFolder(TraceNameToWaveRef(GraphName, CurrentWave),2);
		NoteString = CurrentWave;
		
		sprintf NoteString, "\\s(%s) %s",  CurrentWave,  NoteString;
		if (i==0)
			LegendString = "\\Z08\\[0" + NoteString
		else
			LegendString = LegendString + "\r"+ NoteString;
		endif		
	endfor
	
	Legend /X=0.00/Y=0.00/W=$GraphName/C/N=IBSLegend/J/M/A=LT LegendString
End

//!
//! @brief Colorize the waves in the top graph, with given lightness and saturation starting hue.
//! @details Written by Kevin Boyce with tweaks by Howard Rodstein with more tweaks from IBS
//! Lightness, saturation and starting hue vary between 0 and 1.
//! NOTE: lightness and saturation are really cheap approximations.
//! For that matter, so is hue, which is a real simple rgb circle.
//! Colors are evenly distributed in "hue", except around
//! green-blue, where they move more quickly, since color perception
//! isn't as good there.  I generally call it with lightness=0.9 and 
//! saturation=1.
//!
//! @param[in] lightness
//! @param[in] saturation
//!
//! @return \b NaN on success
//! @return \b -1 on error 
Function IBSColorizeTraces(lightness, saturation)
	Variable lightness, saturation
	String Graph
	Variable rmin, rmax, gmin, gmax, bmin,bmax, phi, r,g,b
	Variable k, km

	Graph = WinName(0, 1)
	if (strlen(Graph) == 0)
		return -1
	endif

	// Find the number of traces on the top graph
	String tnl = TraceNameList( "", ";", 1 )
	km = ItemsInList(tnl)
	if (km <= 0)
		return -1
	endif
	
	k = 0
	
	Do
		if (k==0)
			r = 0
			b = 0
			g = 0
		else
			r = IBSGetColor( lightness, saturation, (k-1)/km, 1 )
			g = IBSGetColor( lightness, saturation, (k-1)/km, 2 )
			b = IBSGetColor( lightness, saturation, (k-1)/km, 3 )	
		endif
		ModifyGraph/W=$Graph/Z rgb[k]=( r, g, b ) 
		k+=1
	while(k< km)
End

//!
//! @brief Picks colors for ::IBSColorizeTraces.
//! @details Written by Kevin Boyce with tweaks by Howard Rodstein with more tweaks from IBS
//!
//! @param[in] lightness
//! @param[in] saturation
//! @param[in] ratio      how far around our "color circle" we are (on interval [0,1) )
//! @param[in] gun        which color component (r,g,b)=(1,2,3)
//!
//! @return red, green, or blue color value adjusted for "even" visual differences
Function IBSGetColor(lightness, saturation, ratio, gun)
	Variable lightness, saturation
	Variable ratio, gun
	Variable rmin, rmax, gmin, gmax, bmin,bmax, phi, r,g,b

	bmax = 65535*lightness
	bmin = 65535*max(min((lightness-saturation), 1), 0)
	
	// Reduce red and green maximum values, since red is brighter
	// than blue, and green is brighter still.  This started out using
	// CIE values, but that didn't look good, so it's just empirical now.
	rmin = bmin/1; rmax = bmax/1
	gmin = bmin/1.5; gmax = bmax/1.5
	
	phi= ratio * (2*PI)		// phi will determine the "hue".
	
	// Make phi move faster between 1.5 and 2.5, since color
	// sensitivity is less in that region.
	if( phi > 2.5 )
		phi += 1
	else
		if( phi > 1.5 )
			phi += (phi-1.5)
		endif
	endif
	
	// Calculate r, g, or b
	if( phi < 2*PI/3 )
		if( 1 == gun )
			return rmin + (rmax-rmin)*(1+cos(phi))/2
		else
			if( 2 == gun )
				return gmin + (gmax-gmin)*(1+cos(phi-2*PI/3))/2
			else
				return bmin
			endif
		endif
	else
		if( phi < 4*PI/3 )
			if( 1 == gun )
				return rmin
			else
				if( 2 == gun )
					return gmin + (gmax-gmin)*(1+cos(phi-2*PI/3))/2
				else
					return bmin + (bmax-bmin)*(1+cos(phi-4*PI/3))/2
				endif
			endif
		else
			if( 1 == gun )
				return rmin + (rmax-rmin)*(1+cos(phi))/2
			else
				if( 2 == gun )
					return gmin
				else
					return bmin + (bmax-bmin)*(1+cos(phi-4*PI/3))/2
				endif
			endif
		endif
	endif
End


// The Following functions assist in labeling axes

//!
//! @brief Fills two strings with all of the supported labels
//! @param[in] index whether to return English or command form of labels
//! @return if index == 1 then the English is returned
//! @return otherwise the commands are returned
function/s Label_List(index)
	variable index
	string EnglishText, LabelText;

	// Define all the Labels and all the English Equvilents

	EnglishText = "None"
	LabelText = ""

	EnglishText += ";Position [um]"
	LabelText += ";Position [\\uu\\f02\\F'Symbol'm\\]0m]"

	EnglishText += ";Line Width [um]"
	LabelText += ";Width [\\u\\f02\\F'Symbol'm\\]0m]"

	EnglishText += ";Temperature"
	LabelText += ";Temperature [\\uK]"
	
	EnglishText += ";Inverse Temperature"
	LabelText += ";1/T [K\\S-1\\M]"

	EnglishText += ";Density"
	LabelText += ";Density [x10\S11\Mcm\S-2\M]"
	
	EnglishText += ";Time"
	LabelText += ";Time [\\us]"
	
	EnglishText += ";Frequency"
	LabelText += ";Frequency [\\uHz]"
	
	if (index == 1)
		return EnglishText
	else
		return LabelText
	endif
End

//!
//! @brief Displays a dialog to help the user apply labels to top graph's axes
function Label_Axes()
	variable LAxes = 1, RAxes = 0, BAxes = 1, TAxes = 0;
	string LLabel="", RLabel="", BLabel="", TLabel="";
	string LabelText = "", EnglishText = "", Axes, CurrentAxes
	variable i

	// Define all the Labels and all the English Equvilents

	EnglishText = Label_List(1)
	LabelText = Label_List(0)
	
	// This function labels a  graph and asks the user what to put on each axes
	
	Prompt LAxes, "Left axes", popup EnglishText;
	Prompt RAxes, "Right Axes", popup EnglishText;
	Prompt BAxes,"Bottom Axes", popup EnglishText;
	Prompt TAxes, "Top Axes", popup EnglishText;
	DoPrompt "Axes Labels", LAxes, RAxes, BAxes, TAxes
	
	// Build the label strings
	// Select Label Strings
	
	LLabel = StringFromList(LAxes-1,  LabelText);
	RLabel = StringFromList(RAxes-1,  LabelText);
	BLabel = StringFromList(BAxes-1,  LabelText);
	TLabel = StringFromList(TAxes-1,  LabelText);

	// Find the active axes
	Axes = AxisList("");
	if (stringmatch(Axes, "*left*" ) && stringmatch(LLabel, "") == 0)
		Label left, LLabel
		printf  "Label left, \"%s\";", LLabel
	Endif
		
	if (stringmatch(Axes, "*right*" ) && stringmatch(RLabel, "") == 0)
		Label right, RLabel
		printf "Label right, \"%s\";", RLabel
	Endif 
		
	if (stringmatch(Axes, "*bottom*" ) && stringmatch(BLabel, "") == 0)
		Label bottom, BLabel
		printf "Label bottom, \"%s\";", BLabel
	Endif
		
	if (stringmatch(Axes, "*top*" ) && stringmatch(TLabel, "") == 0)
		Label top, TLabel
		printf "Label top, \"%s\";", TLabel
	Endif
	printf "\r";
End

//!
//! @brief This function labels a dVdV vs V graph
function Label_dIdV_vs_V()
	string LLabel="",  BLabel=""
	string LabelText = "",  Axes

	// Define all the Labels

	LabelText = Label_List(0)
		
	// Select Label Strings
	
	LLabel = StringFromList(1,  LabelText);
	BLabel = StringFromList(8,  LabelText);

	// Find the active axes
	Axes = AxisList("");
	if (stringmatch(Axes, "*left*" ) && stringmatch(LLabel, "") == 0)
		Label left, LLabel
	Endif
				
	if (stringmatch(Axes, "*bottom*" ) && stringmatch(BLabel, "") == 0)
		Label bottom, BLabel
	Endif
End

// -------------------------------------------------

function BECMovieFormation(startNum,endNum,skipList)
	Variable startNum, endNum;
	String skipList;

	//String ProjectFolder = Activate_Top_ColdAtomInfo();
	SVAR ProjectFolder = root:Packages:ColdAtom:CurrentPath;
	cd ProjectFolder
	String currentTEvapStr;
	NewDataFolder /O SavedImages
	
	//loop over images
	Variable jj;
	for (jj = startNum ; jj <= endNum; jj+=1) //loop over image numbers
		if(WhichListItem(num2str(jj),skipList,";",0,1)==-1) //only load images not in skipList
			BatchRun(-1,jj,0,"")
			
			//save optdepth 2D wave
			NVAR currentTEvap =:tEvap1
			currentTevap = 10*currentTevap;
			currentTEvapStr = num2str(currentTEvap)
			Duplicate :optdepth $(":SavedImages:optdepth" + currentTEvapStr)
			
			//save cross sections:
			Duplicate :Fit_Info:xsec_col $(":SavedImages:xsec_col" + currentTEvapStr)
			Duplicate :Fit_Info:fit_xsec_col $(":SavedImages:fit_xsec_col" + currentTEvapStr)
			Duplicate :Fit_Info:xsec_row $(":SavedImages:xsec_row" + currentTEvapStr)
			Duplicate :Fit_Info:fit_xsec_row $(":SavedImages:fit_xsec_row" + currentTEvapStr)
			
			//save cross section residuals
			Duplicate :Fit_Info:res_xsec_col $(":SavedImages:res_xsec_col" + currentTEvapStr)
			Duplicate :Fit_Info:res_xsec_row $(":SavedImages:res_xsec_row" + currentTEvapStr)
		endif
	endfor	

end

Function plotOptdepth(optdepth)
	Wave optdepth
	String wvName = NameOfWave(optdepth)
	//NewImage optdepth
	PauseUpdate; Silent 1		// building window...
	Display /W=(495.75,48.5,687,179)
	AppendImage optdepth
	ModifyImage $(wvName) ctab= {-0.1,3.5,Geo,0}
	ModifyGraph margin(left)=40,margin(bottom)=28,margin(top)=3,margin(right)=52,gFont="Times New Roman"
	ModifyGraph gfSize=10,gmSize=2,width=100,height={Aspect,1}
	ModifyGraph mirror=2
	ModifyGraph lblMargin=1
	ModifyGraph standoff=0
	ModifyGraph lblPosMode=1
	ModifyGraph axisOnTop=1
	ModifyGraph btLen=4
	ModifyGraph btThick=1
	ModifyGraph stLen=2
	ModifyGraph stThick=1
	ModifyGraph tlOffset(bottom)=-3
	//ModifyGraph manTick(left)={-775,200,0,0},manMinor(left)={3,0}
	//ModifyGraph manTick(bottom)={-550,250,0,0},manMinor(bottom)={4,0}
	Label left "\\f02z\\f00 (\\F'Symbol'm\\F'Times New Roman'm)"
	Label bottom "\\f02x\\f00 (\\F'Symbol'm\\F'Times New Roman'm)"
	SetAxis left -500,500
	SetAxis bottom -500,500
	ColorScale/C/N=OD/F=0/H={2,0,5}/A=LT/X=101.00/Y=-6.00 image=$(wvName), height=99
	ColorScale/C/N=OD width=12, tickLen=3, nticks=3//, font="Times New Roman"//, fsize=10
	ColorScale/C/N=OD lblMargin=0
	AppendText "Optical Depth"
end

function plotXsecs(num)
	Variable num
	
	Wave xsec_col = $(":SavedImages:xsec_col" + num2str(num))
	Wave fit_xsec_col = $(":SavedImages:xsec_col" + num2str(num))
	Wave xsec_row = $(":SavedImages:xsec_row" + num2str(num))
	Wave fit_xsec_row = $(":SavedImages:xsec_row" + num2str(num))
	
	Display /W=(285.75,251,516.75,453.5) xsec_col
	AppendToGraph/T xsec_row
	
	SetAxis left -0.2,3.5
	SetAxis bottom -250,350
	SetAxis top -300,300
	ModifyGraph margin(left)=31,margin(bottom)=26,margin(top)=26,margin(right)=11,gFont="Times New Roman"
	ModifyGraph gfSize=10,gmSize=2,width=190,height={Aspect,0.8}
	ModifyGraph rgb($(NameofWave(xsec_col)))=(27756,34438,50372),rgb($(NameofWave(xsec_row)))=(53199,24929,16705)
	ModifyGraph mode($(NameofWave(xsec_col)))=3,marker($(NameofWave(xsec_col)))=16, msize($(NameofWave(xsec_col)))=1
	ModifyGraph mode($(NameofWave(xsec_row)))=3,marker($(NameofWave(xsec_row)))=16, msize($(NameofWave(xsec_row)))=1
	ModifyGraph tick(left)=2,mirror(left)=1,minor(left)=1,standoff(left)=0
	ModifyGraph tick(bottom)=2,minor(bottom)=1,standoff(bottom)=0
	ModifyGraph tick(top)=2,minor(top)=1,standoff(top)=0
	Label left "Optical Depth"
	Label bottom "\\f02z\\f00 (\\F'Symbol'm\\F'Times New Roman'm)"
	Label top "\\f02x\\f00 (\\F'Symbol'm\\F'Times New Roman'm)"
	
	//ModifyGraph mode($(NameOfWave(xsec_col)))=2,mode($(NameofWave(xsec_row)))=2
	//ModifyGraph lSize($(NameofWave(xsec_col)))=2,lSize($(NameofWave(xsec_row)))=2
	
//	PauseUpdate; Silent 1		// building window...
//	Display /W=(285.75,251,516.75,453.5) xsec_col//,fit_xsec_col
//	AppendToGraph/T xsec_row//,fit_xsec_row
//	//AppendToGraph/L=Lres/T res_xsec_row
//	//AppendToGraph/L=Lres res_xsec_col
//	//SetDataFolder fldrSav0
//	ModifyGraph margin(left)=31,margin(bottom)=26,margin(top)=26,margin(right)=11,gFont="Times New Roman"
//	ModifyGraph gfSize=10,gmSize=2,width=190,height={Aspect,0.8}
//	ModifyGraph mode($(NameOfWave(xsec_col)))=2,mode($(NameofWave(xsec_row)))=2

//	//ModifyGraph lSize($(NameofWave(xsec_col)))=2,lSize($(NameofWave(fit_xsec_col)))=1.25,lSize($(NameofWave(xsec_row)))=2,lSize($(NameofWave(fit_xsec_row)))=1.25
//	//ModifyGraph lSize(res_xsec_row)=2,lSize(res_xsec_col)=2
//	//ModifyGraph rgb($(NameofWave(xsec_col)))=(27756,34438,50372),rgb($(NameofWave(fit_xsec_col)))=(0,0,0),rgb($(NameofWave(xsec_row)))=(53199,24929,16705)
//	//ModifyGraph rgb($(NameofWave(fit_xsec_row)))=(0,0,0)//,rgb(res_xsec_row)=(53199,24929,16705),rgb(res_xsec_col)=(27756,34438,50372)
//	ModifyGraph tick=2
//	ModifyGraph zero(Lres)=4
//	ModifyGraph mirror(left)=1,mirror(Lres)=1
//	ModifyGraph lblMargin(left)=1,lblMargin(bottom)=1,lblMargin(Lres)=1
//	ModifyGraph standoff=0
//	ModifyGraph zeroThick(left)=0.5,zeroThick(bottom)=0.5,zeroThick(top)=0.5,zeroThick(Lres)=1
//	ModifyGraph lblPosMode=1
//	ModifyGraph lblPos(left)=35
//	ModifyGraph axisOnTop=1
//	ModifyGraph btLen=4
//	ModifyGraph btThick=1
//	ModifyGraph stLen=2
//	ModifyGraph stThick=1
//	ModifyGraph ttThick=0.5
//	ModifyGraph ftThick=0.5
//	ModifyGraph tlOffset(top)=1
//	ModifyGraph freePos(Lres)=0
//	ModifyGraph axisEnab(left)={0.28,1}
//	ModifyGraph axisEnab(Lres)={0,0.22}
//	ModifyGraph manTick(left)={0,1,0,1},manMinor(left)={3,0}
//	ModifyGraph manTick(bottom)={-750,100,0,0},manMinor(bottom)={3,0}
//	ModifyGraph manTick(top)={-550,100,0,0},manMinor(top)={3,0}
//	ModifyGraph manTick(Lres)={0,1,0,1},manMinor(Lres)={3,0}
//	Label left "Optical Depth"
//	Label bottom "\\f02z\\f00 (\\F'Symbol'm\\F'Times New Roman'm)"
//	Label top "\\f02x\\f00 (\\F'Symbol'm\\F'Times New Roman'm)"
//	Label Lres "Fit Res."
//	SetAxis left -0.2,3.5
//	SetAxis bottom -500,500
//	SetAxis top -500,500
//	SetAxis Lres -1,1
end

function plotallImages()
	Variable i;
	String wvName;
	For(i=1; i < 34 ; i+=1)
		wvName = ":SavedImages:optdepth" + num2str(i)
		plotOptdepth($(wvName))
	endFor
end

Function makeBECMovie()
	Duplicate /O :SavedImages:optDepth1 movieWave
	
	Display /W=(495.75,48.5,687,179) /N=MovieGraph
	AppendImage movieWave
	ModifyImage movieWave ctab= {-0.1,3.5,Geo,0}
	ModifyGraph margin(left)=50,margin(bottom)=40,margin(top)=3,margin(right)=70,gFont="Times New Roman"
	ModifyGraph gfSize=16,gmSize=2,width=400,height={Aspect,1}
	ModifyGraph mirror=2
	ModifyGraph lblMargin=1
	ModifyGraph standoff=0
	ModifyGraph lblPosMode=1
	ModifyGraph axisOnTop=1
	ModifyGraph btLen=4
	ModifyGraph btThick=1
	ModifyGraph stLen=2
	ModifyGraph stThick=1
	ModifyGraph tlOffset(bottom)=-3
	//ModifyGraph manTick(left)={-775,200,0,0},manMinor(left)={3,0}
	//ModifyGraph manTick(bottom)={-550,250,0,0},manMinor(bottom)={4,0}
	Label left "\\f02z\\f00 (\\F'Symbol'm\\F'Times New Roman'm)"
	Label bottom "\\f02x\\f00 (\\F'Symbol'm\\F'Times New Roman'm)"
	SetAxis left -500,500
	SetAxis bottom -500,500
	ColorScale/C/N=OD/F=0/H={2,0,5}/A=LT/X=102.00/Y=-1.50 image=movieWave, height=398
	ColorScale/C/N=OD width=12, tickLen=5, nticks=3//, font="Times New Roman"//, fsize=10
	ColorScale/C/N=OD lblMargin=0
	AppendText "Optical Depth"
	
	String movieName = "BEC_formation.avi"
	NewMovie /F=10/L/O as movieName
	
	Variable i;
	String wvName;
	For(i=1; i < 34 ; i+=1)
		wvName = ":SavedImages:optdepth" + num2str(i)
		Duplicate /O $(wvName) movieWave
		DoUpdate
		AddMovieFrame
	endFor
	
	CloseMovie
	Killwindow MovieGraph
	Killwaves movieWave
end
#pragma rtGlobals=1		// Use modern global access method.

Function DataSorter(Ydata, Xdata,yBaseName,xBaseName)

	wave Ydata, Xdata //data to be sorted
	string yBaseName, xBaseName //base names for resulting waves
	
	//mask the data
	duplicate/FREE/D Ydata, ydTemp
	duplicate/FREE/D Xdata, xdTemp
	
	//sort Ydata and Xdata by Xdata
	sort xdTemp, xdTemp, ydTemp
	
	//Make waves to store results using basename
	Make/O/D/N=1 $(xBaseName + "_Vals")/WAVE=xVals
	Make/O/D/N=1 $(yBaseName + "_Avg")/WAVE=yAvg
	Make/O/D/N=1 $(yBaseName + "_SD")/WAVE=ySD
	Variable numXvals = 1
	Variable i
	Variable prev = -1
	
	//populate results waves
	For(i=0; i < numpnts(xdTemp); i+=1)
		
		If(xdTemp[i]!=xdTemp[i+1])
		
			xVals[numXvals-1] = xdTemp[i]
			InsertPoints numXvals, 1, xVals
			Make/N=(i-prev)/O/D $("dataPnt" + num2str(numXvals))/WAVE=ref
			ref[0,i-prev-1] = ydTemp[prev+p+1]
			WaveStats/Q/Z/M=2 ref
			yAvg[numXvals-1] = V_avg
			InsertPoints numXvals, 1, yAvg
			ySD[numXvals-1] = V_sdev
			InsertPoints numXvals, 1, ySD
			prev = i
			numXvals += 1
			
		endif
		
	endfor
	
	//don't forget the last point
	xVals[numXvals-1] = xdTemp[i-1]
	Make/N=(i-prev-1)/O/D $("dataPnt" + num2str(numXvals))/WAVE=ref
	ref[0,i-prev-1] = ydTemp[prev+p+1]
	WaveStats/Q/Z/M=2 ref
	yAvg[numXvals-1] = V_avg
	ySD[numXvals-1] = V_sdev
	
	//Duplicate the raw sorted data for future use
	Duplicate/O xdTemp, $(xBaseName + "_sorted")
	Duplicate/O ydTemp, $(yBaseName + "_sorted")
	
	//check that the procedure is correctly extracting X values
	print numXvals
	
End
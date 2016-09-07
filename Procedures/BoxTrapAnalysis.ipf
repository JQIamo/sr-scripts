#pragma rtGlobals=1		// Use modern global access method.

function boxTOFimportImages(startNum,endNum,skipList,startAlpha,endAlpha)
 	Variable startNum, endNum, startAlpha, endAlpha
 	string skipList


	NVAR PolyLogOrd = :PolyLogOrderVar
	variable ii, jj
	
	for (jj = startNum ; jj <= endNum; jj+=1) //loop over image numbers
		if(WhichListItem(num2str(jj),skipList,";",0,1)==-1) //only load images not in skipList
			PolyLogOrd=startAlpha;
			BatchRun(-1,jj,0,"") //load the current image
			for (ii = startAlpha+0.1 ; ii < endAlpha+0.1 ; ii += 0.1) //Loop over polylog orders
				PolyLogOrd = ii;
				refit("");
			endfor
		endif
	endfor
				

End
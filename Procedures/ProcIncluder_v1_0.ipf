#pragma rtGlobals=2		// Use modern global access method.

//Use this procedure to include all additional procedure files
//This is for easier use with GitHub.
//#include <AllStatsProcedures>
#include "CastinDum_v3_3_Sr"
#include "FigureProcessing_v3_3_Sr"
//#include "GraphProcedures_v3_2RbYb"
#include "FileIO_v3_3_Sr"
#include "GUI_v3_3_Sr"
#include "Info_v3_3_Sr"
#include "Procedures_v3_3_Sr"
//#include "LatticeAnalyze_RbYb"
#include "BatchRun_v3_3_Sr"		// Automates re-running data; use SetBasePath("basePath") to pick folder
#include "PolylogFits_Sr"
#include "LightShiftAnalysis_Sr"
#include "DataSort"
#include "3BodyAnalysis_0_1"
#include "OrthoBasis_v1_0"

Function tempEstimation88(w,t) : FitFunc
	Wave w
	Variable t

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(t) = sqrt(s0^2 + (2e12/1.06e-2)*temp*t^2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ t
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = s0
	//CurveFitDialog/ w[1] = temp

	return sqrt(w[0]^2 + (2e12/1.06e-2)*w[1]*t^2)
End

Function DipFreqScale(w, pow) : FitFunc
	Wave w
	Variable pow
	
	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(pow) = sqrt(w[0]+w[1]*pow)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ pow
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = offsetFreq
	//CurveFitDialog/ w[1] = scaling

	return sqrt(w[0]+w[1]*pow)
End

Function LambertWaprx(z)
	Variable z
	
	//This function returns an approximation of the LambertW for z in (-1/e, 0).
	//The error is less than 1% over the range of validity.

	return e*z/(1+((2*e*z+2)^(-1/2)+1/(e-1)-1/sqrt(2))^(-1))
End
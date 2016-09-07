#pragma rtGlobals=2		// Use modern global access method.
//! @file
//! @brief Use this procedure to include all additional procedure files
//! @details This is for easier use with GitHub.
//!
//! Also includes some generic fitting & utility functions which may be moved

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
#include "SaveROI_v3_5"
#include "LatticeDepth_Sr"
#include "BoxTrapAnalysis"

//!
//! @brief
//! @details created by the Curve Fitting dialog
//!
//! @param[in] w ??
//! @param[in] t ??
//! @return
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

//!
//! @brief
//! @details created by the Curve Fitting dialog
//!
//! @param[in] w   ??
//! @param[in] pow ??
//! @return
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

//!
//! @brief Returns an approximation of the LambertW for z in (-1/e, 0)
//! @details The error is less than 1% over the range of validity.
//!
//! @param[in] z in (-1/e, 0)
//! @return LambertW(z)
Function LambertWaprx(z)
	Variable z
	
	//This function returns an approximation of the LambertW for z in (-1/e, 0).
	//The error is less than 1% over the range of validity.

	return e*z/(1+((2*e*z+2)^(-1/2)+1/(e-1)-1/sqrt(2))^(-1))
End

//!
//! @brief
//! @details created by the Curve Fitting dialog
//!
//! @param[in] w   ??
//! @param[in] pow ??
//! @return
Function VertFreqFit(w, pow) : FitFunc
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
	//CurveFitDialog/ w[0] = Amp
	//CurveFitDialog/ w[1] = Pcritical

	return (abs(pow) >= (sqrt(e)*w[1]) ? 2*w[0]*Sqrt(exp(LambertWaprx(-w[1]^2/pow^2)/2)*pow*(LambertWaprx(-w[1]^2/pow^2)+1)) : 0)
End

//!
//! @brief
//! @details created by the Curve Fitting dialog
//!
//! @param[in] w   ??
//! @param[in] pow ??
//! @return
Function TransFreqFit(w, pow) : FitFunc
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
	//CurveFitDialog/ w[0] = Amp
	//CurveFitDialog/ w[1] = Pcritical

	return (abs(pow) >= (sqrt(e)*w[1]) ? 2*w[0]*Sqrt(exp(LambertWaprx(-w[1]^2/pow^2)/2)*pow) : 0)
End

//!
//! @brief Calculates the axial trap frequency given the transverse trap frequencies
//! @warning This function is only valid for Sr88 but the numerical prefactor (A) can be changed to switch species.
//!
//! @param[in] P ??
//! @param[in] f_y y-trap frequency
//! @param[in] f_z z-trap frequency
//! @param[in] f_lat ??
//! @return axial trap frequency
Function AxialFreq(P,f_y,f_z,f_lat)
	Variable P, f_y, f_z, f_lat
	
	//This function returns the axial trap frequency given the transverse trap frequencies.
	//The function is only valid for Sr88 but the numerical prefactor (A) can be changed to switch species.
	
	Variable q = 2*pi/(1.064e-6);
	Variable A = 2*pi*5.6051*10^(-7); //see SrLatticePot.nb in AeroFS folder
	Variable T = (q^2*A*sqrt(P*f_z*f_y)/(pi*f_lat^2)-1)^(-1);
	//print T
	//print sqrt(8*pi^3*(f_y^4+f_z^4)/sqrt(f_y*f_z*(1+T)^2*P*A^2*q^4))/(2*pi)
	return round(10*sqrt(8*pi^3*(f_y^4+f_z^4)/sqrt(f_y*f_z*(1+T)^2*P*A^2*q^4))/(2*pi))/10
End
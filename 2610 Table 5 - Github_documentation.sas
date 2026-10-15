*********************************************************************************************************
Non-genetic risk factors associated with glenohumeral osteoarthritis-related shoulder arthroplasty
*********************************************************************************************************;
*~~~~~~~~~~~~~~~~~
|    TABLE 5     |
*~~~~~~~~~~~~~~~~~;

ODS output 	FitStatistics= fit_THA
			ParameterEstimates= par_THA;
proc phreg data=THA_analysis;
class gender (ref="Female") racecat (ref="White") edcat(ref='College/University') bmicat_new (ref="Healthy (18.5 <= BMI < 25.0 kg/m2)") smoking (ref="Never") 
	mins_vigor_cat (ref="0 MET minutes") manwork1 (ref='Never/rarely') income (ref='Less than 18,000')/ param=ref order=internal;
model years_fu_THA*THA(0) = age_enroll_10 gender racecat edcat bmicat_new smoking  mins_vigor_cat  manwork1 income  /RL  TIES=EFRON;
title "THA";
run;
ODS output close;


data par_THA;
set par_THA;
HR_CI=compress(round(HazardRatio,.01)||"("||round(HRLowerCL,.01)||"-"||round(HRUpperCL,.01)||")");
run;


proc print data=par_THA;run;


*****************;

ODS output 	FitStatistics= fit_TKA
			ParameterEstimates= par_TKA;
proc phreg data=TKA_analysis;
class gender (ref="Female") racecat (ref="White") edcat(ref='College/University') bmicat_new (ref="Healthy (18.5 <= BMI < 25.0 kg/m2)") smoking (ref="Never") 
	mins_vigor_cat (ref="0 MET minutes") manwork1 (ref='Never/rarely') income (ref='Less than 18,000')/ param=ref order=internal;
model years_fu_TKA*TKA(0) = age_enroll_10 gender racecat edcat bmicat_new smoking  mins_vigor_cat  manwork1 income  /RL  TIES=EFRON;
title "TKA";
run;

ODS output close;


data par_TKA;
set par_TKA;
HR_CI=compress(round(HazardRatio,.01)||"("||round(HRLowerCL,.01)||"-"||round(HRUpperCL,.01)||")");
run;

proc print data=par_TKA;run;
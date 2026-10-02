/*
Note:
  Code to set up format: 01
  Code for Table 2: 02, 03, 04
  Code for Table 3 (age-adjusted models): 05
  Code for Table 3 (multivariate model as "01_all participants_race"): 06
  Code for Table 4 (multivariate model as "02_no-chronic neck/shoulder patients_race"): 10
  Code for Supplemental Figures: 05, 07
  Code for Supplemental Tables: 08, 09, 11
*/
******************************************************************;
%let data = tsa.official_tsa_oa_revise;
*01_Set format;
proc format;
value gender 1 = 'Male' 0 = 'Female';
value racecat  1 = "White"
			   2 = "Black"
			   3 ="Asian"
			   4 = "Mixed"
			   5 = "Other"
			   6 = "Unknown";
			   
value edcat 1 = 'O levels/GCSES or CSEs'
			2 = 'A levels'
			3 = 'NVQ, HND, HNCs'
			4 = 'Other professional qualifications'
			5 = 'College/University' 
			0 = 'None of the list'
			99 = 'Unknown';
			
value bmicat 	0 = 'Underweight (BMI < 18.5 kg/m2)' 
				1 = 'Healthy (18.5 <= BMI < 25.0 kg/m2)'
				2 = 'Overweight (25.0 <= BMI < 30.0 kg/m2)'
				3 = 'Obese (30.0 kg/m2 <= BMI)'
				999 = 'Unknown BMI';															
value bmicat_mo 0 = 'Underweight or Healthy' 
				1 = 'Underweight or Healthy'
				2 = 'Overweight'
				3 = 'Obese'
				999 = 'Unknown BMI';	
				
value manwork 1 = 'Never/rarely'
				2 = 'Sometimes'
				3 = 'Usually'
				4 = 'Always'
				99 = 'Unknown';																	
				
value smoking 0 =  'Never'
				1 =  'Former'
				2 =  'Current'
				99 = 'Unknown';
				
value income 	-3 = 'Prefer not to answer'
			   -1 = 'Do not know'
			   1 = 'Less than 18,000'
			   2 = '18,000 to 30,999'
			   3 = '31,000 to 51,999'
			   4 = '52,000 to 100,000'
			   5 = 'Greater than 100,000'
			   99 = 'Unknown'; /* -3 & -1 */

value mins_vigor_cat   1 = '0 MET minutes'
					   2 = '1-240 MET minutes'
					   3 = '241-960 MET minutes'
					   4 = '961-10080 MET minutes'
					   99 = 'Unknown';

value mins_sum_cat   1 = '0-55 minutes'
					   2 = '56-100 minutes'
					   3 = '101-180 minutes'
					   4 = '181+ minutes';
value history	1 ='Yes'
				0 ='No';
value tsa 1 = "TSA"
		  0 = "No TSA";
value agecat	1='40-50 years old'
				2='51-60 years old'
				3='61+ years old';
run;

proc sort data=&data;
	by tsa_oa_final;
run;

/***to evaluate the % of SAs occurring after 2016***/
data check;
	set &data;
	if tsa_oa_date^=. & tsa_oa_date<MDY(1,1,2017) then earlytsa=1;
	else earlytsa=0;
	if tsa_oa_date=. then earlytsa=.;
	run;
proc freq data=check;
	tables earlytsa;
	run;  /*39% of SAs occurring after 2016, 61% occurring 2016 or earlier*/

proc univariate data=&data;
	where tsa_oa_final=1;
	var  follow_year_ceil; /*time to shoulder arthroplasty*/
	run; /*Median time to shoulder arthroplasty=7 years, IQR=5-10 years*/
/*****/


data data;
	set &data;
	if age_enroll <= 50 then agecat=1;
	else if 50<age_enroll<=60 then agecat=2;
	else if 60<age_enroll then agecat=3;
	age_decade = age_enroll/10;
	if edcat=77 then edcat=0;
	if mins_vigor_cat=. then mins_vigor_cat=99;
	if icd_dislocate_1st=. then icd_dislocate_1st=0;
	lgtime=log(follow_year_ceil);
	if tsa_oa_final=1 then status=1;  /*status outcome variable to use in competing risk analysis*/
	else if tsa_oa_final=0 & date_of_death=. then status=0;
	else if tsa_oa_final=0 & date_of_death^=. then status=2;
	format mins_vigor_cat $mins_vigor_cat.
	agecat $agecat.;
	if end_date>MDY(12, 31, 2016) then end_date2=MDY(12, 31, 2016);
	else if end_date<=MDY(12, 31, 2016) then end_date2=end_date;
	earlyfu=(end_date2-start_date)/365.25;
run;

proc means data=data n mean sum;
	var follow_year earlyfu; /**59% of follow-up occurred in the period 2006-2016**/
	run;

******************************************************************;

*02. Mean and range: Continuous variables;
*Age and Townsend;
title"tsa_oa_final = 1";
proc means data=data MAXDEC=1 mean median q1 q3 min max N;
	var age_enroll townsend;
	where tsa_oa_final = 1;
run;

title"tsa_oa_final = 0";
proc means data=data MAXDEC=1 mean median q1 q3 min max N;
	var age_enroll townsend;
	where tsa_oa_final = 0;
run;

******************************************************************;


*03. P value: Continuous variables (Wilcoxon test);
title "Wilconxon test";
proc npar1way wilcoxon data=data;
  class tsa_oa_final;
  var age_enroll townsend;
  format tsa_oa_final tsa.;
run;

******************************************************************;

*04. P value: Categorical variables (Chi-square);
proc sort data=data;
	by tsa_oa_final;
run;

* Frequency on categorical variables by TSA / NO-TSA group; 
title"Chi-square on categorical variables(not for manwork1)";
PROC FREQ DATA=data;
	TABLE agecat*tsa_oa_final
		  gender*tsa_oa_final
		  racecat*tsa_oa_final
		  edcat*tsa_oa_final
		  bmicat*tsa_oa_final
		  smoking*tsa_oa_final
		  mins_vigor_cat*tsa_oa_final
		  mins_sum_cat*tsa_oa_final
		  manwork1*tsa_oa_final
		  income*tsa_oa_final/ norow nocum nopercent CHISQ;									
	format gender gender. racecat racecat. edcat edcat. bmicat bmicat_mo. 
			smoking smoking. mins_vigor_cat mins_sum_cat mins_vigor_cat.
			manwork1 manwork. income income.
			tsa_oa_final tsa.;
run;

title"Chi-square on categorical variables(manwork1)";
PROC FREQ DATA=data;
	TABLE manwork1*tsa_oa_final/ norow nocum nopercent CHISQ;
	format manwork1 manwork. tsa_oa_final tsa.;
	where manwork1 ~= 99;
run;

******************************************************************;
*05. Age-adjusted models;
 proc phreg data=data;
        model follow_year_ceil*tsa_oa_final(0) = age_decade/ties=efron rl;
    run;

*Categorical variables;
%macro ageadjust(variable,format,reference,title);
    ODS SELECT ParameterEstimates ModelANOVA;   
    title "Age-adjusted Model on &title.";
    proc phreg data=data;
        class &variable.(ref=&reference.);
        model follow_year_ceil*tsa_oa_final(0) = age_decade &variable./ties=efron rl;
        format &variable. &format.;
    run;
%mend;

%ageadjust(gender,gender.,"Female",Sex);
%ageadjust(racecat,racecat.,"White",Race/Ethnicity);
%ageadjust(edcat,edcat.,"College/University",Education);
%ageadjust(bmicat,bmicat_mo.,"Underweight or Healthy",BMI);
%ageadjust(smoking,smoking.,"Never",Smoking);
%ageadjust(mins_vigor_cat,mins_vigor_cat.,"0 MET minutes",MET vigorous activity(mins/week));
%ageadjust(mins_sum_cat,mins_sum_cat.,"0-55 minutes",Summed minutes activity category);
%ageadjust(manwork1,manwork.; where manwork1 ~= 99,"Never/rarely",Jobs involves heavy manual or physical work);
%ageadjust(manwork1,manwork., "Never/rarely",Jobs involves heavy manual or physical work);
%ageadjust(income,income.,"Less than 18,000",Income);
%ageadjust(sh_surg_1499,history.,"No",History of shoulder dislocation);

*Continuous variables;
ODS SELECT ParameterEstimates;   
title "Age-adjusted Model on Townsend Deprivation Index";
proc phreg data=data;
	model follow_year_ceil*tsa_oa_final(0) = age_decade townsend/ties=efron rl;
run;


/**Checking proportional hazards***/
 proc phreg data=data;
        model follow_year_ceil*tsa_oa_final(0) = age_decade aget/ties=efron rl;
		aget=age_decade*log(follow_year_ceil); /*P<0.0001*/
    run;
 proc phreg data=data;
 		class gender(ref="Female");
        model follow_year_ceil*tsa_oa_final(0) = gender gendert/ties=efron rl;
		gendert=gender*log(follow_year_ceil); /*P=0.1219*/
    run;
 proc phreg data=data;
 		class racecat(ref=first);
        model follow_year_ceil*tsa_oa_final(0) = racecat racet/ties=efron rl;
		racet=racecat*log(follow_year_ceil); /*P=0.8944*/
    run;
 proc phreg data=data;
 		where edcat^=99;
		class edcat(ref=last);
        model follow_year_ceil*tsa_oa_final(0) = edcat edt/ties=efron rl;
		edt=edcat*log(follow_year_ceil); /*P=0.8521*/
    run;
 proc phreg data=data;
 		where bmicat^=999;
		class bmicat(ref=first);
        model follow_year_ceil*tsa_oa_final(0) = bmicat bmit/ties=efron rl;
		bmit=bmicat*log(follow_year_ceil); /*P=0.2185*/
    run;
 proc phreg data=data;
 		where smoking^=99;
		class smoking(ref=first);
        model follow_year_ceil*tsa_oa_final(0) = smoking smoket/ties=efron rl;
		smoket=smoking*log(follow_year_ceil); /*P=0.2564*/
    run;
 proc phreg data=data;
 		where mins_vigor_cat^=99;
		class mins_vigor_cat(ref=first);
        model follow_year_ceil*tsa_oa_final(0) = mins_vigor_cat vigort/ties=efron rl;
		vigort=mins_vigor_cat*log(follow_year_ceil); /*P=0.0147*/
    run;		
 proc phreg data=data;
 		where manwork1^=99;
		class manwork1(ref=first);
        model follow_year_ceil*tsa_oa_final(0) = manwork1 mant/ties=efron rl;
		mant=manwork1*log(follow_year_ceil); /*P=0.6748*/
    run;	
 proc phreg data=data;
 		where income^=99;
		class income(ref=first);
        model follow_year_ceil*tsa_oa_final(0) = income incomet/ties=efron rl;
		incomet=income*log(follow_year_ceil); /*P=0.5062*/
    run;				
/*Supplemental Figure 2A*/
proc lifetest data=data plot=(s, lls);
	time follow_year*tsa_oa_final(0);
	strata agecat;
	run;
/*Supplemental Figure 2B*/
proc lifetest data=data plot=(s, lls);
	where mins_vigor_cat^=99;
	time follow_year*tsa_oa_final(0);
	strata mins_vigor_cat;
	run;

******************************************************************;

*06. Multivariate models;
*Multivariate model with selected variables among all population;   
title "Multivariate Cox model";
title2 "variables: age in decade, gender, race, education, bmi, smoking, MET vigorous activity, job involves heavy work, income";
title3 "Among all participants";
proc phreg data=data;
	class 	gender(ref="Female") 
			racecat(ref="White")
			edcat(ref="College/University") 
			bmicat(ref="Underweight or Healthy") 
			smoking(ref="Never") 
			mins_vigor_cat(ref="0 MET minutes")
			manwork1(ref="Never/rarely")
			income(ref="Less than 18,000");
	model follow_year_ceil*tsa_oa_final(0) = 
					age_decade gender racecat edcat bmicat smoking
					mins_vigor_cat manwork1 income/ties=efron rl;
	format gender gender. 
			racecat racecat.
			edcat edcat. 
			bmicat bmicat_mo. 
			smoking smoking.
			mins_vigor_cat mins_vigor_cat.
			manwork1 manwork.
			income income.;
run;   
/***********************************************/

*07.Cumulative Incidence in Supplemental Figure 1, 2C, and 2D;
/*Create overall K-M curve for SA risk*/
proc phreg data=data;
model follow_year*tsa_oa_final(0)=/ties=efron rl;
baseline out=surv survival=s lower=lcl upper=ucl;
output out=pts atrisk=n;
run;

data ci; set surv; ci=1-s; lclci=1-lcl; uclci=1-ucl; run;  /*changing from K-M curve to cumulative incidence curve*/

axis1 label=(h=1.5 "Follow-up Years in the UK Biobank") order=0 to 15 by 1 value=(h=1.25) major=(h=1 w=1) minor=none;
axis2 label=(h=1.5 angle=90 "Proportion with OA-related Shoulder Arthroplasty") order=(0 to 0.005 by 0.001) value=(h=1.5) major=(h=1 w=1) minor=(h=1 w=1 number=4);
symbol1 c=black i=stepj l=1 w=2;
symbol2 c=gray i=stepj l=2 w=2;
symbol3 c=gray i=stepj l=2 w=2;

proc gplot data=ci; 
plot ci*follow_year/  overlay haxis=axis1 vaxis=axis2 noframe;
run; quit;

/*/*Create K-M curve for SA risk by agecat*/
proc phreg data=data;
strata agecat;
model follow_year*tsa_oa_final(0)=/ties=efron rl;
baseline out=surv survival=s lower=lcl upper=ucl;
output out=pts atrisk=n;
run;

data ci; set surv; ci=1-s; lclci=1-lcl; uclci=1-ucl; run;  /*changing from K-M curve to cumulative incidence curve*/

axis1 label=(h=1.5 "Follow-up Years in the UK Biobank") order=0 to 15 by 1 value=(h=1.25) major=(h=1 w=1) minor=none;
axis2 label=(h=1.5 angle=90 "Proportion with OA-related Shoulder Arthroplasty") order=(0 to 0.005 by 0.001) value=(h=1.5) major=(h=1 w=1) minor=(h=1 w=1 number=4);
symbol1 c=black i=stepj l=1 w=1;
symbol2 c=black i=stepj l=2 w=1;
symbol3 c=black i=stepj l=4 w=1;

proc gplot data=ci; 
plot ci*follow_year=agecat/  overlay haxis=axis1 vaxis=axis2 legend=legend1 noframe;
run; quit;

/*/*Create K-M curve for SA risk by physical activity*/
proc phreg data=data;
where mins_vigor_cat^=99;
strata mins_vigor_cat;
model follow_year*tsa_oa_final(0)=/ties=efron rl;
baseline out=surv survival=s lower=lcl upper=ucl;
output out=pts atrisk=n;
run;

data ci; set surv; ci=1-s; lclci=1-lcl; uclci=1-ucl; run;  /*changing from K-M curve to cumulative incidence curve*/

axis1 label=(h=1.5 "Follow-up Years in the UK Biobank") order=0 to 15 by 1 value=(h=1.25) major=(h=1 w=1) minor=none;
axis2 label=(h=1.5 angle=90 "Proportion with OA-related Shoulder Arthroplasty") order=(0 to 0.005 by 0.001) value=(h=1.5) major=(h=1 w=1) minor=(h=1 w=1 number=4);
symbol1 c=black i=stepj l=1 w=1;
symbol2 c=black i=stepj l=2 w=1;
symbol3 c=black i=stepj l=4 w=1;
symbol4 c=black i=stepj l=34 w=1;

proc gplot data=ci; 
plot ci*follow_year=mins_vigor_cat/  overlay haxis=axis1 vaxis=axis2 legend=legend1 noframe;
run; quit;

/*****************************************************************/

*08.Time-varying covariates;
data padummy;
	set data;
	if mins_vigor_cat=2 then pa1=1;
	else pa1=0;
	if mins_vigor_cat=3 then pa2=1;
	else pa2=0;
	if mins_vigor_cat=4 then pa3=1;
	else pa3=0;
	if mins_vigor_cat=99 then pa4=1;
	else pa4=0;  
	run;
/*Supplemental Table 1*/
title "Multivariate Cox model with time-varying age covariate";
title2 "variables: age in decade <7 fu years, age in decade >=7 fu years, gender, race, education, bmi, smoking, MET vigorous activity, job involves heavy work, income";
title3 "Among all participants";
proc phreg data=padummy;
	class 	gender(ref="Female") 
			racecat(ref="White")
			edcat(ref="College/University") 
			bmicat(ref="Underweight or Healthy") 
			smoking(ref="Never") 
			mins_vigor_cat(ref="0 MET minutes")
			manwork1(ref="Never/rarely")
			income(ref="Less than 18,000");
	model follow_year_ceil*tsa_oa_final(0) = 
					age_time1 age_time2 gender racecat edcat bmicat smoking
					pa1time1 pa2time1 pa3time1 pa4time1 pa1time2 pa2time2 pa3time2 pa4time2 pa1time3 pa2time3 pa3time3 pa4time3 manwork1 income/ties=efron rl;
	format gender gender. 
			racecat racecat.
			edcat edcat. 
			bmicat bmicat_mo. 
			smoking smoking.
			mins_vigor_cat mins_vigor_cat.
			manwork1 manwork.
			income income.;
	if follow_year_ceil<7 then do; age_time1=age_decade; end; else do; age_time1=0; end;
	if follow_year_ceil>=7 then do; age_time2=age_decade; end; else do; age_time2=0; end;
	if follow_year_ceil<=2 then do; pa1time1=pa1; pa2time1=pa2; pa3time1=pa3; pa4time1=pa4; end; else do; pa1time1=0; pa2time1=0; pa3time1=0; pa4time1=0; end;
	if 2<follow_year_ceil<=5 then do; pa1time2=pa1; pa2time2=pa2; pa3time2=pa3; pa4time2=pa4; end; else do; pa1time2=0; pa2time2=0; pa3time2=0; pa4time2=0; end;
	if 5<follow_year_ceil then do; pa1time3=pa1; pa2time3=pa2; pa3time3=pa3; pa4time3=pa4; end; else do; pa1time3=0; pa2time3=0; pa3time3=0; pa4time3=0; end;
run;  
/*************************************************************/

*09.Sub-distribution model to account for competing risks;
/*Supplemental Table 3*/ 
proc phreg data=data;
	class gender(ref="Female") 
			racecat(ref="White")
			edcat(ref="College/University") 
			bmicat(ref="Underweight or Healthy") 
			smoking(ref="Never") 
			mins_vigor_cat(ref="0 MET minutes")
			manwork1(ref="Never/rarely")
			income(ref="Less than 18,000")/param=ref;
	model follow_year_ceil*status(0)=age_decade gender racecat edcat bmicat smoking
					mins_vigor_cat manwork1 income/ties=efron eventcode=1;
	hazardratio 'Subdist Haz' age_decade/diff=pairwise;
	hazardratio 'Subdist Haz' gender/diff=pairwise;
	hazardratio 'Subdist Haz' smoking/diff=pairwise;
	hazardratio 'Subdist Haz' racecat/diff=pairwise;
	hazardratio 'Subdist Haz' edcat/diff=pairwise;
	hazardratio 'Subdist Haz' bmicat/diff=pairwise;
	hazardratio 'Subdist Haz' mins_vigor_cat/diff=pairwise;
	hazardratio 'Subdist Haz' manwork1/diff=pairwise;
	hazardratio 'Subdist Haz' income/diff=pairwise;
		format gender gender. 
			racecat racecat.
			edcat edcat. 
			bmicat bmicat_mo. 
			smoking smoking.
			mins_vigor_cat mins_vigor_cat.
			manwork1 manwork.
			income income.;
run;
/**************************************************************/


*10.Multivariate model among people without chronic shoulder and neck pain (baseline);
/*Table 4*/
title "Multivariate Cox model";
title2 "variables: age in decade, gender, race, education, bmi, smoking, MET vigorous activity, job involves heavy work, income";
title3 "Among non-chronic-shoulder or non-neck pain participants";
proc phreg data=data;
	class 	gender(ref="Female") 
			racecat(ref="White")
			edcat(ref="College/University") 
			bmicat(ref="Underweight or Healthy") 
			smoking(ref="Never") 
			mins_vigor_cat(ref="0 MET minutes")
			manwork1(ref="Never/rarely")
			income(ref="Less than 18,000");
	model follow_year_ceil*tsa_oa_final(0) = 
					age_decade gender racecat edcat bmicat smoking
					mins_vigor_cat manwork1 income/ties=efron rl;
	format gender gender. 
			racecat racecat.
			edcat edcat. 
			bmicat bmicat_mo. 
			smoking smoking.
			mins_vigor_cat mins_vigor_cat.
			manwork1 manwork.
			income income.;
	where neck_pain ne 1 and sh_surg_1499 ne 1;
run;

/***********************************************/
*11.Multiple Imputation Sensitivity analysis;
/*Supplemental Table 2*/
data data_missing;
	set &data;
	age_decade = age_enroll/10;
	if edcat=77 then edcat=0;
	if income=99 then income=.;
	if racecat=6 then racecat=.;
	if edcat=99 then edcat=.;
	if bmicat=999 then bmicat=.;
	if smoking=99 then smoking=.;
	if mins_vigor_cat=99 then mins_vigor_cat=.;
run;

proc mi data=data_missing nimpute=5 seed=61085 out=imputed;
	var follow_year_ceil age_decade gender tsa_oa_final edcat income racecat bmicat smoking mins_vigor_cat;
	class edcat income racecat bmicat smoking mins_vigor_cat;
	fcs logistic;
	run;	

proc phreg data=imputed;
	class 	gender(ref="Female") 
			racecat(ref="White")
			edcat(ref="College/University") 
			bmicat(ref="Underweight or Healthy") 
			smoking(ref="Never") 
			mins_vigor_cat(ref="0 MET minutes")
			manwork1(ref="Never/rarely")
			income(ref="Less than 18,000");
	model follow_year_ceil*tsa_oa_final(0) = 
					age_decade gender racecat edcat bmicat smoking
					mins_vigor_cat manwork1 income/ties=efron rl;
	ods output ParameterEstimates=phreg_parms;
	format gender gender. 
			racecat racecat.
			edcat edcat. 
			bmicat bmicat_mo. 
			smoking smoking.
			mins_vigor_cat mins_vigor_cat.
			manwork1 manwork.
			income income.;
		by _imputation_;
	run;

data phreg_parms2;
	set phreg_parms;
	if Parameter="racecat" then racecat=ClassVal0; else racecat="";
	if Parameter="edcat" then edcat=ClassVal0; else edcat="";
	if Parameter="bmicat" then bmicat=ClassVal0; else bmicat="";
	if Parameter="smoking" then smoking=ClassVal0; else smoking="";
	if Parameter="mins_vigor_cat" then mins_vigor_cat=ClassVal0; else mins_vigor_cat="";
	if Parameter="manwork1" then manwork1=ClassVal0; else manwork1="";
	if Parameter="income" then income=ClassVal0; else income="";
	run;
proc mianalyze parms(classvar=full)=phreg_parms2;
	class edcat income racecat bmicat smoking mins_vigor_cat manwork1;
	modeleffects age_decade gender racecat edcat bmicat smoking mins_vigor_cat manwork1 income;
	run; 

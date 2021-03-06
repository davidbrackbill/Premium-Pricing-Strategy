/* Instruction 1: Import ptf.sas7bdat and creation of variable Age into work.ptf */
Libname data '/folders/myshortcuts/Project_Database';
data work.ptf;
set data.ptf;
numage= int((Policy_Starting_Date-Birthdate)/365);
informat age $15.;
if numage <= 21
then age='-21';
else if  21<numage<=35
then age ='21-35';
else if  35 < numage <= 60
then age='35-60';
else if numage > 60
then age='+60';
drop numage
run;
/* Instruction 2: Import cars.csv as work.cars, creation of variable hp into work.cars and merging work.ptf and work.cars */
proc import out = work.cars
datafile = '/folders/myshortcuts/Project_Database/cars.csv'
DBMS=csv
replace;
getnames=yes;
run;
data work.cars;
set work.cars;
informat hp $15.;
if horsepower <=150 then hp='low';
else if 150<horsepower<=300 then hp='medium';
else if horsepower> 300 then hp='high';
run;
proc sort data=work.ptf out=work.ptf;
by cars_id;
run;
proc sort data=work.cars out=work.cars;
by cars_id;
run;
data work.ptf;
merge work.cars work.ptf;
by cars_id;
run;
/* Instruction 3: Import zip.txt, add density variable, merge with work.ptf */
proc import out = work.CA_ZIP_CODE
datafile = '/folders/myshortcuts/Project_Database/CA_ZIP_CODE.TXT'
replace;
delimiter=" ";
getnames=yes;
run;
data work.CA_ZIP_CODE;
set work.CA_ZIP_CODE;
informat density $15.;
if population <= 4000 then density='low';
else if 4000 < population <= 30000 then density='medium';
else if population > 30000 then density="high";
run;
proc sort data=work.ptf out=work.ptf;
by zip_code;
run;
proc sort data=work.CA_ZIP_CODE out=work.CA_ZIP_CODE;
by zip_code;
run;
data work.ptf;
merge work.CA_ZIP_CODE work.ptf;
by zip_code;
run;
/* Instruction 4: Import claims into data lib, merge  with work.ptf (only rows present in claims) 
by policyholderid and policystarting date as the database work.claims */
proc sort data= data.claims out=data.claims;
by policyholder_id policy_starting_date;
run;
proc sort data= work.ptf out=work.ptf;
by policyholder_id policy_starting_date;
run;
data work.claims;
merge data.claims (in=a) work.ptf (in=b);
by policyholder_id policy_starting_date;
if a;
run;
proc print data=work.claims (obs=2);
run;
/* Instruction 5: In work.claims make var "year" for year of ongoing contract.
Create work.claims_summary that includes # of claims (nb_claims), avg cost (cost) for each year and profile */
data work.claims;
set work.claims;
Format year Year4.;
year = POLICY_STARTING_DATE;
run;
proc means data=work.claims stackodsoutput mean n ;
var claims_cost;
class year age density hp;
ods output summary=work.claims_summary(drop=_control_ variable n) ;
run;
data work.claims_summary;
set work.claims_summary;
Rename Nobs=nb_claims mean=cost;
run;
/* Instruction 6: Do the same things for work.ptf and work.ptf_summary including (nb) */
data work.ptf;
set work.ptf;
Format year Year4.;
year = POLICY_STARTING_DATE;
run;
proc means data=work.ptf stackodsoutput n ;
class year age density hp;
ods output summary=work.ptf_summary(drop=_control_ variable label n) ;
run;
proc sort data=work.ptf_summary out=work.ptf_summary nodupkey;
by _all_;
run;
proc sort data=work.ptf_summary out=work.ptf_summary;
by year age density hp;
run;
data work.ptf_summary;
set work.ptf_summary;
Rename Nobs=nb;
run;
proc print data=work.ptf_summary (obs=25);
run;
/* Instruction 7: merge claims_summary and ptf_summary by age, density, hp and year.
Compute the frequency*/
proc sort data=work.ptf_summary out=work.ptf_summary;
by age density hp year;
run;
proc sort data=work.claims_summary out=work.claims_summary;
by age density hp year;
run;
data work.summary;
merge work.claims_summary work.ptf_summary;
by age density hp year;
freq= nb_claims/nb;
run;
proc print data=work.summary;
run;
/* Instruction 8: Take the highest frequency for each profile and assign these to work.freq.
Keep only age density hp and cost on this DB.*/
data work.freq;
set work.summary;
keep age density hp year freq;
run;
proc sort data=work.freq out=work.freq;
by descending freq age density hp year ;
run;
proc sort data=work.freq out=work.freq nodupkey;
by age density hp;
run;
/* Instruction 9: Take the highest average cost "cost" for each profile from work.summary 
and keep only "age "density" "hp" and "cost" */
data work.cost;
set work.summary;
keep age density hp year cost;
run;
proc sort data=work.cost out=work.cost;
by descending cost age density hp year ;
run;
proc sort data=work.cost out= work.cost nodupkey;
by age density hp;
run;
/* Instruction 10: Merge work.cost and work.freq by "age "density" "hp" into work.pp 
and create variable "pp" that calculates the pure premium (Freq*cost) */
proc sort data=work.cost;
by age density hp;
run;
proc sort data=work.freq;
by age density hp;
run;
data work.pp;
merge work.cost work.freq;
by age density hp;
pp= cost*freq;
run;
/* Instruction 11: Create variable "lp" in work.pp where lp=pp*(1+loading factor of .05) */
data work.pp;
set work.pp;
lp = pp*1.05;
run;
/* Instruction 12: Put "age" "density" "hp" "lp" and new variables "pA" "pB" "pC" into work.price 
where pA = lp*1.05, pB=lp*1.1, pC=lp*1.15 */
data work.price;
set work.pp;
drop year cost freq;
pA=lp*1.05;
pB=lp*1.1 ;
pC=lp*1.15;
run;
/* Instruction 13: Import prospect.csv as work.prospect. Add "hp" "density" and "age" variables. 
access these by using database work.ptf*/
proc import out=work.prospect
datafile= '/folders/myshortcuts/Project_Database/Prospect.csv'
DBMs=csv
replace;
getnames=yes;
run;
data work.prospect;
set work.prospect;
numage= int((21915-Birthdate)/365);
informat age $15.;
if numage <= 21
then age='-21';
else if  21<numage<=35
then age ='21-35';
else if  35 < numage <= 60
then age='35-60';
else if numage > 60
then age='+60';
drop numage
run;
proc sort data=work.prospect out=work.prospect;
by cars_id;
run;
data work.prospect;
merge work.prospect work.cars;
by cars_id;
run;
proc sort data=work.prospect out=work.prospect;
by zip_code;
run;
data work.prospect;
merge work.CA_ZIP_CODE work.prospect;
by zip_code;
keep prospect_id age density hp;
run;
/* Instruction 14: merge work.prospect with work.price by "age" "density" "hp"*/
proc sort data=work.prospect;
by age density hp;
run;
proc sort data=work.price;
by age density hp;
run;
data work.prospect;
merge work.prospect work.price;
by age density hp;
if prospect_id='.' then delete; 
run;
/* Instruction 15: Following the marketing formula, create "prob_a" "prob_b" "prob_c" in work.prospect */
data work.prospect;
set work.prospect;
prob_a= 1/(1+exp(-.1*(lp/pA)+(.002*(pA-lp))));
prob_b= 1/(1+exp(-.1*(lp/pB)+(.002*(pB-lp))));
prob_c= 1/(1+exp(-.1*(lp/pC)+(.002*(pC-lp))));
run;
/* Instruction 16: create "accept_a" "accept_b" "accept_c" booleans if their corresponding prob
are > .5 */
data work.prospect;
set work.prospect;
if prob_a>.5 then accept_a=1;
else accept_a=0;
if prob_b>.5 then accept_b=1;
else accept_b=0;
if prob_c>.5 then accept_c=1;
else accept_c=0;
run;
/* Instruction 17: Calculate the revenue for each strategy in work.table_volume.
compute revenue variables and then analyze using proc means */
data work.prospect;
set work.prospect;
revenue_a=pa*accept_a;
revenue_b=pb*accept_b;
revenue_c=pc*accept_c;
run;
proc means data=work.prospect stackodsoutput sum;
var revenue_a revenue_b revenue_c;
ods output summary=work.table_volume(drop=_control_ n) ;
run;
/* Instruction 18: Compute the profit in work.prospect by creating variable "pi_n" for each strategy
that subracts the revenue_n by the loaded premium lp given acceptance */
data work.prospect;
set work.prospect;
if accept_a=1 then pi_a=revenue_a-lp;
else pi_a=0;
if accept_b=1 then pi_b=revenue_b-lp;
else pi_b=0;
if accept_c=1 then pi_c=revenue_c-lp;
else pi_c=0;
run;
/* Instruction 19: Calculate the profit for each strategy in work.table_volume.
analyze profit variables using proc means */
proc means data=work.prospect stackodsoutput sum;
var pi_a pi_b pi_c;
ods output summary=work.table_profit(drop=_control_ n) ;
run;
/* Instruction 20-29 Make pdf report */
options nodate pdfpageview=fitpage;
ods noproctitle;
ods pdf style=journal File= '/folders/myshortcuts/Project_Database/final_report_Brackbill.pdf'
startpage=no;
Title1 "Homework Project PSTAT130";
title2 "David Brackbill";
title3 "davidbrackbill@ucsb.edu";
ods layout gridded;
proc sort data=work.ptf;
by age density hp;
run;
proc sort data=work.pp;
by age density hp;
run;
data work.ptf_pp;
merge work.ptf work.pp;
by age density hp;
run;
data work.ptf_pp;
set work.ptf_pp;
if policy_starting_date^=21550 then delete;
run;
proc means data=work.ptf_pp stackodsoutput noobs mean;
title 'Frequency of Claims by Age';
var freq;
class age;
ods output summary=work.table_profit(drop=_control_ n) ;
run;
proc means data=work.ptf_pp stackodsoutput noobs mean;
title 'Frequency of Claims by Population Density';
var freq;
class density;
ods output summary=work.table_profit(drop=_control_ n) ;
run;
proc means data=work.ptf_pp stackodsoutput noobs mean;
title 'Frequency of Claims by Vehicle Horsepower';
var freq;
class hp;
ods output summary=work.table_profit(drop=_control_ n);
run;
proc means data=work.ptf_pp stackodsoutput noobs mean;
title 'Claim Cost by Age';
var cost;
class age;
ods output summary=work.table_profit(drop=_control_ n) ;
run;
proc means data=work.ptf_pp stackodsoutput noobs mean;
title 'Claim Cost by Population Density';
var cost;
class density;
ods output summary=work.table_profit(drop=_control_ n) ;
run;
proc means data=work.ptf_pp stackodsoutput noobs mean;
title 'Claim Cost by Vehicle Horsepower';
var cost;
class hp;
ods output summary=work.table_profit(drop=_control_ n);
run;
proc means data=work.ptf_pp stackodsoutput noobs mean;
title 'Average Pure Premium of the Current Portfolio';
var pp;
ods output summary=work.table_profit(drop=_control_ n);
run;
proc sort data=work.pp;
by pp;
run;
proc print data=work.pp (obs=1) noobs;
var age density hp;
title 'Factors for the Lowest Premium';
run;
proc sort data=work.pp;
by descending pp;
run;
proc print data=work.pp (obs=1) noobs;
var age density hp;
title 'Factors for the Highest Premium';
run;
data work.table_volume_modifier;
   input variable $9. Strategy $11.;
   datalines;
revenue_a Strategy A
revenue_b Strategy B
revenue_c Strategy C
;
run;
data work.table_volume (drop=variable);
merge work.table_volume work.table_volume_modifier;
by variable;
run;
proc print data=work.table_volume noobs;
title 'Volume of New Business by Strategy';
run;
data work.table_profit_modifier;
   input variable $4. Strategy $11.;
   datalines;
pi_a Strategy A
pi_b Strategy B
pi_c Strategy C
;
run;
proc means data=work.prospect stackodsoutput sum;
var pi_a pi_b pi_c;
ods output summary=work.table_profit(drop=_control_ n) ;
run;
data work.table_profit (drop=variable);
merge work.table_profit work.table_profit_modifier;
by variable;
run;
proc print data=work.table_profit noobs;
title 'Volume of New Profit by Strategy';
run;
data work.final_price;
set work.price;
keep age density hp pB;
rename pB=best_price;
run;
proc print data=work.final_price noobs;
run;

ods layout end;
ODS PDF Close;
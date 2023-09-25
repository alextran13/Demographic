libname p1 '/home/u63485840/SAS Clinical trial projects/Rang Project 1';
proc import datafile='/home/u63485840/SAS Clinical trial projects/Rang Project 1/ADSL.xlsx'
out=p1.demo
dbms=xlsx
replace;
getnames=yes;
run;

/* PART A */

/* Select records and variables */
data demo1;
set p1.demo;
if ittfl='Y';
run;


/* Set up Total treatment variable */
data demo2;
set demo1;
output;
trt01a='All';
output;
run;

/* Set up trt variable for future code */
data demo3;
length trt $10.;
set demo2;
if index(trt01a,'Drug A')>0 then do;
	trt='a';
	ord=1;end;
if index(trt01a, 'Placebo')>0 then do;
	trt='b';
	ord=2;end;
if index(trt01a, 'All')>0 then do;
	trt='all';
	ord=3;end;
keep usubjid trt ord age sex race ethnic country;
run;

proc sort; by usubjid ord; run;

/* Big N=XXXX for column header */
proc sql noprint;
select count(distinct usubjid) into: N1-:N3 from demo3
group by ord
order by ord;
quit;
%put &N1 &N2 &N3;

/* Summary Stats for Age */
proc summary data=demo3 nway;
class trt;
var age;
output out=age_sum
N=_N Mean=_Mean Median=_Median STD=_STD Min=_Min Max=_Max;
run;

/* Decimal alignment for Summary Stats of Age */
Data age_decimal;
set age_sum;
N=Compress(put(_N,3.));
Mean=compress(put(_mean,4.1));
median=compress(put(_median,4.1));
STD=compress(put(_STD,5.2));
Min=compress(put(_Min,2.));
Max=Compress(put(_max,2.));
Age='^_^_^';
run;


/* Transpose Age data */
proc transpose data=age_decimal out=tr_age1;
id trt;
var n mean median std min max age;
run;

/* Reformat Age data */
data tr_age2;
set tr_age1;
length cat stat $100.;
cat='AGE';
stat=_Name_;
	if stat = 'Age' then do;
	stat = 'Age'; od=1; end;
	if stat='N' then do;
	stat='N'; od=2;end;
	if stat='Mean' then do;
	stat='Mean';od=3;end;
	if stat='median' then do;
	stat='Median';od=4;end;
	if stat='STD' then do;
	stat='STD';od=5;end;
	if stat='Min' then do;
	stat='Min';od=6;end;
	if stat='Max' then do;
	stat='Max';od=7;end;
a1=input(a,best.);
b1=input(b,best.);
all_=input(b,best.);
drop a b all;
drop _name_;
druga=put(a,3.);
drugb=put(b,3.);
drugall=put(all,3.); 

if stat='Age' then druga='^_^_^';
if stat='Age' then drugb='^_^_^';
if stat='Age' then drugall='^_^_^';
run;



/* Change data type */
data tr_age3;
set tr_age2;
a=a1;
b=b1;
all=all_;
drop a1 b1 all_;
run;

proc sort data=tr_age3 out=tr_age4;
by od;
run;



/* Sex count*/
proc freq data= demo3 noprint;
tables trt*sex/out=gender (drop=percent);
run;

data gender;
length cat Stat $100.;
set gender;
Cat='GENDER (%)';
if sex='M' then do;
	stat='Male'; od=1; end;
if sex='F' then do;
	stat='Female'; od=2; end;

run;

proc sort data=gender; by cat od;run;

proc transpose data=gender out=tr_gen;
by cat od stat;
id trt;
var count;
run;

/* Race count*/
proc freq data=demo3 noprint;
tables trt*race/out=race (drop=percent);
run;

data race;
length cat stat $100.;
set race;
Cat='RACE (%)';
if race= 'American Indian or Alaska Native' then do;
	stat='American Indian or Alaska Native'; od=1; end;
if race='Asian' then do;
	stat='Asian';od=2;end;
if race='Black' then do;
	stat='Black';od=3;end;
if race='Multiracial' then do;
	stat='Multiracial';od=4;end;
if race='Native Hawaiian or Pacific Islander' then do;
	stat='Native Hawaiian or Pacific Islander';od=5;end;
if race='White' then do;
	stat='White';od=7;end;
if race='Other' then do;
	stat='Other';od=6;end;
run;

proc sort data=race; by od ; run;

proc transpose data=race out=tr_race;
by cat od stat;
id trt;
var count;
run;


/* Ethnic count*/
proc freq data=demo3 noprint;
tables trt*ethnic/out=ethnic (drop=percent);
run;

data ethnic;
length cat stat $100.;
set ethnic;
Cat='ETHNICITY (%)';
if ethnic= 'Hispanic' then do;
	stat='Hispanic'; od=1; end;
if ethnic='Non-Hispanic' then do;
	stat='Non-Hispanic';od=2;end;

run;

proc sort data=ethnic; by od ; run;

proc transpose data=ethnic out=tr_ethnic;
by cat od stat;
id trt;
var count;
run;

/* Country count*/
proc freq data=demo3 noprint;
tables trt*country/out=country (drop=percent);
run;

data country;
length cat stat $100.;
set country;
Cat='COUNTRY (%)';
if country= 'Canada' then do;
	stat='Canada'; od=1; end;
if country='USA' then do;
	stat='USA';od=2;end;
	
run;

proc sort data=country; by od ; run;

proc transpose data=country out=tr_country;
by cat od stat;
id trt;
var count;
run;

/* Set up the Sex and Race counts */
Data combined;
length cat stat druga drugb drugall $100.;
set tr_age4 tr_gen tr_race tr_ethnic tr_country;
if stat ne 'Age';
if a=. then druga='0';
	else if a=&N1 then druga=put(a,3.)||' (100%)';
	else druga=put(a,3.)||' ('||put(a/&N1*100,4.1)||')';
if b=. then drugb='0';
	else if b=&N2 then drugb=put(b,3.)||' (100%)';
	else drugb=put(b,3.)||' ('||put(b/&N2*100,4.1)||')';
if all=. then drugall='0';
	else if all=&N3 then drugall=put(all,3.)||' (100%)';
	else drugall=put(all,3.)|| ' ('||put(all/&N3*100,4.1)||')';
drop a b all _name_ _label_;
run;


/* Final report format */

ods pdf file='/home/u63485840/SAS Clinical trial projects/Rang Project 1/Project 1 output/demo.pdf';
ods escapechar="^";
options nodate nonumber;

title font=normal "Demographic and Baseline Characteristics Summary";
title2 font=normal "All Randomized Subjects";

proc report data=combined nowd headline headskip split= "|" missing
style = {outputwidth=90%} wrap
style(report)=[rules=none frame=hsides]
style(header)={just=C}
style(header)=[bordercolor=black borderbottomcolor=black];

column cat stat 
('Treatment' druga drugb) drugall;

define cat/Group order order=data noprint

style (column)= [just=L cellwidth=30% fontweight=bold]
style (header)= [just=L cellwidth=30%];


define stat/group order order=data "Statistic"
style (column)= [just=L cellwidth=30%]
style (header)= [just=C cellwidth=30%];
rbreak after / summarize;

define druga/group order order=data "Active Drug A | N=&N1"
style (column)= [just=C cellwidth=15%]
style (header)= [just=C cellwidth=15%];

define drugb/group order order=data "Placebo | N=&N2"
style (column)= [just=C cellwidth=15%]
style (header)= [just=C cellwidth=15%];


define drugall/group order order=data "Total | N=&N3"
style (column)= [just=C cellwidth=15%]
style (header)= [just=C cellwidth=15%];

compute before cat;
line @1 cat $20.;
endcomp;
run;

ods pdf close;



















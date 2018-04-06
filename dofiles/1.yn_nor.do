*----------------------------------------------------------------------------------------------------*
*- CEQ Mex 2012: Net Market Income. 
*- Household survey: Encuesta Nacional de Ingreso y Gasto de los Hogares (ENIGH) 2012.
*- Author: Sandra Martinez-Aguilar and Enrique de la Rosa based on the previous 
*- work of John Scott, Enrique de la Rosa and Rodrigo Aranda.
*- Last Date of modification: March 15th, 2018.
*- Practical Information: This do-file builds Net Market Income, which is the 
*- starting point for the construction of the othe 8 CEQ Core Income Concepts.
*----------------------------------------------------------------------------------------------------*

#delimit;

use folioviv foliohog numren clave ing_tri using "${Ingresos}", clear;

replace ing_tri=ing_tri*4; 
*1 ---------LABOR INCOME----------;
       *Selecting the relevant keys;
		gen double ing_lab_in=ing_tri if (clave>="P001" & clave<="P009") | clave=="P011" | (clave>="P013" & clave<="P016") 
                             | clave=="P018" | clave=="P020" | clave=="P021" | clave=="P022" 
							 | clave=="P035" | clave=="P036"
							 | clave=="P067" | clave=="P068" | (clave>="P069" & clave<="P081");

*2 ---------PROPERTY AND CAPITAL INCOME----------;
        *Selecting the relevant keys;
		gen double ing_ren_in=ing_tri if  clave=="P012" | clave=="P019" | (clave>="P023" & clave<="P031");

*3 ---------TRANSFERS----------;
        *Selecting the relevant keys;		
		
		gen double ing_tra_in=ing_tri if (clave>="P032" & clave<="P033") | clave=="P037" | (clave>="P039" & clave<="P041");
	    gen double ing_pen_in=ing_tri if (clave>="P032" & clave<="P033");
		gen double pen_con_in=ing_tri if (clave=="P032");
   
   *3.1 GOVERNMENT TRANSFERS, these variables will be used to construct disposable income;	

        gen ent=substr(folioviv,1,2);
		
		gen double dtr_schp_in =ing_tri if clave=="P038"; // Government scholarships;
		gen double dtr_opor_in =ing_tri if clave=="P042"; // OPORTUNIDADES;
		gen double dtr_cmpo_in =ing_tri if clave=="P043"; // PROCAMPO;
		gen double dtr_70ms_in =ing_tri if clave=="P044"; // Non contributory pensions: 70 and over;
		gen double dtr_pcmx_in =ing_tri if clave=="P045" & ent=="09"; //  Non contributory pensions:Mexico City;
		gen double dtr_amyr_in =ing_tri if clave=="P045" & ent!="09"; // Other elderly benefits;
		gen double dtr_pali_in =ing_tri if clave=="P046"; // Food programme;
		gen double dtr_empt_in =ing_tri if clave=="P047"; // Employment programme ;
		gen double dtr_otrs_in =ing_tri if clave=="P048"; // Other social programs;
		
*4 ---------OTHER INCOMES----------;
	 *Selecting the relevant keys;
		gen double ing_otin_in=ing_tri if  clave=="P049";	

*5 ---------SELF-CONSUMPTION----------;
		*Para obtener el ingreso por autoconsumo, se seleccionan las claves de ingreso correspondientes;
		gen double ing_autc_in=ing_tri if (clave=="P010" & clave<="P017");	

*The total income of each household is estimated;
collapse (sum)  ing_lab_in ing_ren_in ing_tra_in ing_otin_in ing_autc_in ing_pen_in dtr_* pen_con_in , by(folioviv foliohog numren);
    
		label var ing_lab_in "Ingreso corriente monetario laboral";
		label var ing_ren_in "Ingreso corriente monetario por rentas";
		label var ing_tra_in "Ingreso corriente monetario por transferencias";
		label var ing_otin_in "Otros Ingresos";
		label var ing_autc_in "Autoconsumo"	;					 
        		
		sort  folioviv foliohog numren;
		tempfile ing_cor_in;
		save `ing_cor_in', replace;

*Drop observations of inviduals who do not belong to the household definition 
 (guests and domestic workers);
use folioviv foliohog numren parentesco using "${Pobla12}", clear;

joinby folioviv foliohog numren using `ing_cor_in', unmatched(both) _merge(m);
tab m;
drop m;
drop if parentesco>="400" & parentesco <"500";
drop if parentesco>="700" & parentesco <"800";

save `ing_cor_in', replace;
gen pen_con_ri=(pen_con_in!=. & pen_con_in!=.);

tempvar x;
gen `x'=1;
bys folioviv foliohog: egen hsize=sum(`x');
		
*Generate variables at capita level;
		
foreach x in ing_lab ing_ren ing_tra ing_autc ing_otin ing_pen
  pen_con {;
	replace  `x'_in= 0 if `x'_in==. ;
	bys folioviv foliohog: egen double `x'_hh=sum(`x'_in);
	gen double `x'_pc=`x'_hh/hsize;
};
     
	
save `ing_cor_in', replace;

*Add income that was not at individual level;
use factor_hog folioviv  foliohog estim_alqu transf_hog trans_inst ing_cor 
	ingtrab rentas transfer estim_alqu otros_ing remu_espec tot_integ otra_rem
	using "${Concen}", clear;
	
joinby folioviv foliohog  using `ing_cor_in', unmatched(both) _merge(m);
save `ing_cor_in', replace;	
tab m;
drop m;

foreach x in ing_cor ingtrab rentas transfer otros_ing remu_espec transf_hog trans_inst estim_alqu {;
	replace  `x'=0 if `x'==. ;
	replace  `x'=`x'*4;
	gen double `x'_pc=`x'/hsize; 
	
};
	
replace ing_lab_pc= ing_lab_pc + remu_espec_pc;
replace ing_tra_pc= ing_tra_pc + transf_hog_pc + trans_inst_pc ;
   
 *----------------------------------------------------------------------------------------* 
                          Generating Net Market Income & Taxable Income
 *----------------------------------------------------------------------------------------* ;
egen double yn_pc = rowtotal(ing_lab_pc ing_ren_pc ing_tra_pc ing_otin_pc  estim_alqu_pc);
egen double yt_pc=rowtotal(ing_lab_pc ing_ren_pc);

*ing_autc_pc;
drop __000000;
keep folioviv foliohog numren factor_hog   yt_pc yn* dtr* ing_pen_in pen_con_ri hsize parentesco pen_con_in pen_con_pc pen_con_hh;
   tabstat dtr_empt_in [w=factor_hog], stat(sum) col(stat) format(%15.0gc);

   
save "${mod}yn_anual.dta", replace;


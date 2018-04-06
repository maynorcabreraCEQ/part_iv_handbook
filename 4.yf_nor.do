*----------------------------------------------------------------------------------------------------*
*- CEQ Mex 2012: Final Income. 
*- Household survey: Encuesta Nacional de Ingreso y Gasto de los Hogares (ENIGH) 2012.
*- Author: Sandra Martinez-Aguilar and Enrique de la Rosa based on the previous 
*- work of John Scott, Enrique de la Rosa and Rodrigo Aranda.
*- Last Date of modification: March 15th, 2018.
*- Practical Information: This do-file builds Consumable Income, which based on Consumable Income.
*----------------------------------------------------------------------------------------------------*  
	#delimit;

*---------------EDUCATION---------------------------;		
	use   folioviv foliohog numren parentesco asis_esc segpop nivel grado tipoesc inst_* servmed*  using "${Pobla12}", clear ;
	drop if parentesco>="400" & parentesco <"500";
	drop if parentesco>="700" & parentesco <"800";
	sort   folioviv foliohog;
	joinby folioviv foliohog numren using "${mod}yc_anual.dta", unmatched(both) _merge(m);		
	
	scalar gpc_ed1=  72989000000/ 4096377; /* Pre escolar*/;
	scalar gpc_ed2= 226266000000/13526632; /* Primaria*/;
	scalar gpc_ed3= 148416000000/6094293; /*Secuandoria lower */;
	scalar gpc_ed4=  94872000000/4979028; /*secundaria upper */;
	scalar gpc_ed5= 164836258500/2856910; /* terciaria */;
	
	destring nivel, replace;
	destring tipoesc, replace;
	destring asis_esc, replace;
	
	gen edu_pres_ri = (asis_esc	  ==1 &  nivel==1 );
	gen edu_prim_ri = (asis_esc	  ==1 &  nivel==2 );
	gen edu_lsec_ri = (asis_esc	  ==1 &  nivel==3 );
	gen edu_usec_ri = (asis_esc	  ==1 & (nivel==4 | nivel==5 ));
	gen edu_sect_ri = (edu_lsec_ri==1 |  edu_usec_ri==1);
	gen edu_terc_ri = (asis_esc	  ==1 & (nivel>=6 & nivel<=9 ));
	
	tabstat *ri [w=factor_hog] if tipoesc==1, stat(sum) col(stat) f(%19.2f);

	* we impute the benefit to students who attend public education ;
	gen double  edu_pres_in=gpc_ed1*0.42 if nivel==1 & (asis_esc==1 & tipoesc==1); /* Preschool*/;
	gen double  edu_prim_in=gpc_ed2*0.42 if nivel==2 & (asis_esc==1 & tipoesc==1); /* Primaty*/;
	gen double  edu_lsec_in=gpc_ed3*0.42 if nivel==3 & (asis_esc==1 & tipoesc==1); /* Lower Secondary  */;
	gen double  edu_usec_in=gpc_ed4*0.42 if (nivel==4  | nivel==5 ) & (asis_esc==1 & tipoesc==1); /*Upper Secondary */;
	gen double  edu_terc_in=gpc_ed5*0.42 if (nivel==6  | nivel==7 | nivel==8 | nivel==9) & (asis_esc==1 & tipoesc==1); /*Tertiary */;
	egen double  edu_sect_in=rowtotal(edu_lsec_in edu_usec_in);
	tabstat edu_terc_in edu_usec_in [w=factor_hog] if tipoesc==1, stat(sum) col(stat) f(%19.2f);

	foreach var of  varlist edu_* {;
		replace `var'=0 if `var'==. ;
	};
	 
	gen edu_pres_ti= (edad>=3 & edad<=5); 
	gen edu_prim_ti= (edad>=6 & edad<=11); 
	gen edu_lsec_ti= (edad>=12 & edad<=14); 
	gen edu_usec_ti= (edad>=15 & edad<=17); 
	gen edu_sect_ti= (edad>=12 & edad<=17); 
	gen edu_terc_ti= (edad>=18 & edad<=25); 
	tabstat edu_*_ti [w=factor], c(stats) stats(sum) f(%19.2f);
			
*---------------Health---------------------------;	
    *Affiliates by institution
	inst_1 Institución médica IMSS 
	inst_2 Institución médica ISSSTE 
	inst_3 Institución médica ISSSTE estatal
	inst_4 Institución médica PEMEX 
	inst_5 Institución médica Otro
	;
	
	scalar imss= 207477129770.785;
	scalar issste= 60218446754.779; 
	scalar imss_OP=  10100473110.084; 
	scalar pemex=  12924664388.454; 
	scalar ssa=    137226459548; 
	scalar SP=    83083630438.4251; 
	scalar otros=   2367943272.74699;
	
	* IMSS Affiliates;
	destring inst_*, replace;
	sum inst_1 [w=factor_hog];
	gen double hlt_imss_in=inst_1*0.42*(imss/ r(sum_w)) ;
	gen double hlt_imss_ri=(inst_1==1);		
    
	* ISSSTE Affiliates (excluds State ISSSTE );
	gen i=(inst_2==2);
	sum i [w=factor_hog] if i==1;		
	gen double hlt_iste_in=i*0.42*(issste/ r(sum_w));
	gen double hlt_iste_ri=i;
	drop i;
	
	* IMSS-Oportunidades beneficiaries;
	gen i=(servmed_4=="04");
	sum i [w=factor_hog] if i==1;
	gen double hlt_imso_in=(servmed_4=="04")*0.4*(imss_OP/ r(sum_w));
	gen double hlt_imso_ri=(servmed_4=="04");
	drop i;
	
	* PEMEX Affiliates;
	recode inst_4 4=1; 
	sum inst_4 [w=factor_hog] if inst_4==1;
	gen double hlt_pemx_in=(inst_4==1)*0.4*(pemex/ r(sum_w));
	gen double hlt_pemx_ri=(inst_4==1);
    tabstat  hlt_pemx_in [w=factor_hog], c(stats) stats(sum) f(%19.2f);
	
	* SSA federal;
	gen i=(servmed_1=="01" | servmed_2=="02");
	sum i [w=factor_hog] if i==1;
	gen double hlt_ssa_in=i*0.42*(ssa/ r(sum_w)) ;
	gen double hlt_ssa_ri=i;
	drop i;
	
	* Seguro Popular (Popular health insurance);
	destring segpop, replace;
	recode segpop 2=0;
	sum segpop [w=factor_hog] if segpop==1;
	gen double hlt_spop_in=(segpop==1)*0.4*(SP/ r(sum_w)) ;
	gen double hlt_spop_ri=(segpop==1);				
			
    foreach x in edu_pres edu_prim edu_lsec edu_usec edu_sect edu_terc
	             hlt_iste hlt_imso  hlt_ssa hlt_spop hlt_pemx hlt_imss {;
	replace `x'_in=0 if `x'_in==.;
	bys folioviv foliohog: egen double `x'_hh=sum(`x'_in);
	gen double `x'_pc=`x'_hh/hsize;
	};		 
		 
*----------------------------------------------------------------------------------------* 
                               Generating Final Income
*----------------------------------------------------------------------------------------*; 
	egen double yf_pc=rowtotal(yc 
	                  edu_pres_pc edu_prim_pc  edu_lsec_pc edu_usec_pc edu_terc_pc
					  hlt_iste_pc hlt_imso_pc  hlt_ssa_pc hlt_spop_pc hlt_pemx_pc hlt_imss_pc);
		drop m  grado  inst*  segpop   servmed_*;			  
	  save "${mod}yf_anual.dta", replace;

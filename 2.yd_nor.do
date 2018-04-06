*----------------------------------------------------------------------------------------------------*
*- CEQ Mex 2012: Disposable Income. 
*- Household survey: Encuesta Nacional de Ingreso y Gasto de los Hogares (ENIGH) 2012.
*- Author: Sandra Martinez-Aguilar and Enrique de la Rosa based on the previous 
*- work of John Scott, Enrique de la Rosa and Rodrigo Aranda.
*- Last Date of modification: March 15th, 2018.
*- Practical Information: This do-file builds Disposable Income, which based on 
*- Net Market Income.
*----------------------------------------------------------------------------------------------------* 

#delimit;

use folioviv foliohog numren parentesco sexo asis_esc edad nivel grado tipoesc 
    otorg_b tiene_b nivelaprob peso pres_alta residencia using "${Pobla12}", clear;
        drop if parentesco>="400" & parentesco <"500";
		drop if parentesco>="700" & parentesco <"800";

joinby folioviv foliohog numren using "${mod}yn_anual.dta", unmatched(both) _merge(m);
    tab m;
	drop m;
	
*---------------OPORTUNIDADES---------------------------;	
*Amount of the benefits correspond to June-December 2012;
	*https://www.gob.mx/cms/uploads/attachment/file/102826/1er_INFORME_SEDESOL_2013_1_.pdf;
	
*After analyzing the amounts reported in the survey for this program, we decided not to trust the survey.
 Amounts were inconsistent and many of them too far from what it made sense. 
 We decided to construct this program by component trusting the survey in terms of the beneficiaries, but 
 in terms of the amount received;
	gen dtr_opor_ri = (dtr_opor_in!=0 & dtr_opor_in!=.);
	rename dtr_opor_in opor_in_old;
	*drop dtr_opor_hh dtr_opor_pc;
	bys folioviv foliohog: egen dtr_opor_rh=max(dtr_opor_ri);
	bys folioviv foliohog: gen n=_n;
	tab dtr_opor_rh [w=factor_hog] if n==1;
	bys folioviv foliohog: egen x=sum(dtr_opor_ri);

	
	*-----OPORTUNIDADES: Scholarship Component------------;	
	** Beneficiaries: Every individual who reported receiving a scholarship from oportunidades;
	   * We rely on the survey;
	gen opo_beca_ri= (dtr_opor_ri==1 & asis_esc=="1" & tipoesc=="1" & otorg_b =="1" & tiene_b=="1");
	**Amount:we applied the amount per  level and grade (according to the rules of Oportunidades);
	
		gen double opo_beps_in=0;
		replace opo_beps_in=165*10 + 330 if opo_beca_ri==1 & edad<=18 & nivel=="2" & (grado=="1" | grado=="2" |grado=="3" |grado=="4" ) ;
		replace opo_beps_in=250*10 + 330 if opo_beca_ri==1 & edad<=18 & nivel=="2" & grado=="5" ;
		replace opo_beps_in=330*10 + 330 if opo_beca_ri==1 & edad<=18 & nivel=="2" & grado=="6";
	    replace opo_beps_in=480*10 + 410 if opo_beca_ri==1 & edad<=18 & nivel=="3" & grado=="1" & sexo=="1";
	    replace opo_beps_in=510*10 + 410 if opo_beca_ri==1 & edad<=18 & nivel=="3" & grado=="1" & sexo=="2";
	    replace opo_beps_in=510*10 + 410 if opo_beca_ri==1 & edad<=18 & nivel=="3" & grado=="2" & sexo=="1";
	    replace opo_beps_in=565*10 + 410 if opo_beca_ri==1 & edad<=18 & nivel=="3" & grado=="2" & sexo=="2";
	    replace opo_beps_in=535*10 + 410 if opo_beca_ri==1 & edad<=18 & nivel=="3" & grado=="3" & sexo=="1";
	    replace opo_beps_in=620*10 + 410 if opo_beca_ri==1 & edad<=18 & nivel=="3" & grado=="3" & sexo=="2";
	    
		gen double opo_bems_in=0;
		replace opo_bems_in=810*10 + 415  if opo_beca_ri==1 & edad>=14 & edad<=21 & (nivel=="4" | nivel=="5") & grado=="1" & sexo=="1";
 		replace opo_bems_in=930*10 + 415  if opo_beca_ri==1 & edad>=14 & edad<=21 & (nivel=="4" | nivel=="5") & grado=="1" & sexo=="2";
 		replace opo_bems_in=870*10 + 415  if opo_beca_ri==1 & edad>=14 & edad<=21 & (nivel=="4" | nivel=="5") & grado=="2" & sexo=="1";
 		replace opo_bems_in=995*10 + 415  if opo_beca_ri==1 & edad>=14 & edad<=21 & (nivel=="4" | nivel=="5") & grado=="2" & sexo=="2";
 		replace opo_bems_in=925*10 + 415  if opo_beca_ri==1 & edad>=14 & edad<=21 & (nivel=="4" | nivel=="5") & grado=="3" & sexo=="1";
 		replace opo_bems_in=1055*10 + 415 if opo_beca_ri==1 & edad>=14 & edad<=21 & (nivel=="4" | nivel=="5") & grado=="3" & sexo=="2";
	
	**recipient identifier of the scholarship component;
	    gen opo_beps_ri=(opo_beps_in!=0 & opo_beps_in!=.);
		bys folioviv foliohog: egen opo_beps_rh=max(opo_beps_ri); // Educación primaria y secundaria;
		
		gen opo_bems_ri=(opo_bems_in!=0 & opo_bems_in!=.); // Educación Media;
		bys folioviv foliohog: egen opo_bems_rh=max(opo_bems_ri);
		
	**Total amount per household received by scholarships;	    
		egen double opo_becas_in=rowtotal(opo_beps_in opo_bems_in);		
		bys folioviv foliohog: egen double opo_becas_hh=sum(opo_becas_in);
		
	**Applying maximum amounts per household (according to the rules of Oportunidades);		
		replace opo_becas_hh=2320*12 if opo_becas_hh>=2320*12 & opo_bems_rh==1;
		replace opo_becas_hh=1265*12 if opo_becas_hh>=1265*12 & opo_bems_rh==0 & opo_beps_rh==1;
		
	*-----OPORTUNIDADES:Young people with opportunities component------------;
		
		*gen opo_jov1_ri= (dtr_opor_ri==1 & asis_esc=="1" & tipoesc=="1" & otorg_b =="1" & tiene_b=="1" & (nivel=="4" | nivel=="5") & grado=="3" & edad<=22);
	    gen opo_jove_ri= (dtr_opor_ri==1 & asis_esc=="2" & nivelaprob=="4" & edad<=22);
	    gen double opo_jove_in=0;
		replace opo_jove_in = 4599 if opo_jove_ri==1;
		bys folioviv foliohog: egen double opo_jove_hh= sum(opo_jove_in);
	
	*-----OPORTUNIDADES:Elderly component------------;		
	    *36,761;
	    gen opo_admy_ri= (dtr_opor_ri==1 & edad>=70 & 
		                 (dtr_70ms_in==0 | dtr_70ms_in==.) & 
						 (ing_pen_in==0 | ing_pen_in==.));
		tab opo_admy_ri [w=factor_hog] if peso=="1" | pres_alta=="1";
		
		
		gen double opo_admy_hh=345*12  if opo_admy_ri==1 & hsize==1 ;
	
	*-----OPORTUNIDADES:Food component-------------------------------------;
		*Beneficiaries ADM RECORDS:*5.8 millions;

		gen infan9=(edad<=9 & dtr_opor_rh==1);
	    bys folioviv foliohog:egen infan9_h=sum(infan9);
		replace infan9_h=3 if infan9_h>3 ;
		
		gen double opo_ali_hh=0;
		replace opo_ali_hh= ((315 + 130) + infan9_h*115)*12 if dtr_opor_rh==1 ;
	   
	   
	 *-----OPORTUNIDADES:Total-------------------------------------; 
		egen double dtr_opor_hh= rowtotal(opo_ali_hh opo_becas_hh opo_admy_hh opo_jove_hh);
	   
   ** Applying maximum amounts per household (according to the rules of Oportunidades);		
		replace  dtr_opor_hh=2765*12 if dtr_opor_hh>2765*12 & opo_bems_rh==1 ;
		replace  dtr_opor_hh=1710*12 if dtr_opor_hh>1710*12 & opo_bems_rh==0 & opo_beps_rh==1;
		 
		 gen double dtr_opor_pc=dtr_opor_hh/hsize;
		
		tabstat dtr_opor_pc [w=factor_hog], stat(sum) c(stat) format(%15.0gc) ; 
	    drop infan9 infan9_h;
		
*---------------Non contributory pensions: 70 and over--------------------------;
	*After analyzing the amounts reported in the survey for this program, we decided not to trust the survey.
      Amounts were inconsistent and many of them too far from what it made sense. 
      We decided to trust the survey in terms of beneficiaries, but in terms of the amount received;
 
		tab dtr_70ms_in;
	** Beneficiaries: Every individual who reported receiving a scholarship from Oportunidades;
	**Recipient identifier;
		gen dtr_70ms_ri=(dtr_70ms_in!=0 & dtr_70ms_in!=.);
		tab dtr_70ms_ri [w=factor_hog];
    **Amount:we imputed the amount according to the rules of the program;

		replace dtr_70ms_in = 6000 if dtr_70ms_ri==1;	
	
		tabstat dtr_70ms_in [w=factor_hog], stat(sum) col(stat) format(%15.0gc);
		
	****Target identifier;
	    gen  dtr_70ms_ti=0;
		replace    dtr_70ms_ti=1 if ( pen_con_in==0 | pen_con_in==. ) & edad>=70;
		tabstat dtr_70ms_ti [w=factor], c(stats) stats(sum) f(%19.2f);
		
*---------------FOOD SUPPORT PROGRAM------------------------------------;		
		*After analyzing the amounts reported in the survey for this program, we decided not to trust the survey.
         Amounts were inconsistent and many of them too far from what it made sense. 
		 We decided to trust the survey in terms of the beneficiaries, but 
		 in terms of the amount received;
		*Beneficiaries ADM RECORDS: 637,000 FAMILIAS;		
		
		** Beneficiaries: Every individual who reported receiving a scholarship from oportunidades;
		tab dtr_pali_in;
		**Recipient identifier;
		gen dtr_pali_ri =(dtr_pali_in!=. & dtr_pali_in!=0);
		bys folioviv foliohog:egen dtr_pali_rh=max(dtr_pali_ri);
		tab dtr_pali_ri [w=factor_hog];
		drop dtr_pali_in  ;
		
		gen infan9=(edad<=9 & dtr_opor_rh!=1 & dtr_pali_rh==1);
	    bys folioviv foliohog:egen infan9_h=sum(infan9);
		replace infan9_h=0 if infan9_h==.;
		replace infan9_h=3 if infan9_h>3 ;
		
	    **Amount:we imputed the amount according to the rules of the program;
		gen double dtr_pali_hh= 0;
		replace dtr_pali_hh= (310 + 130 + infan9_h*115)*12 if dtr_pali_rh==1;

		gen double dtr_pali_pc=dtr_pali_hh/hsize;
		tabstat dtr_pali_pc [w=factor_hog], stat(sum) col(stat) format(%15.0gc);
		
		
	*tabstat dtr_pali_pc [w=factor_hog], stat(sum) col(stat) format(%15.0gc);
		
		drop dtr_pali_ri dtr_pali_rh;
		**Recipient identifier;
		gen dtr_pali_rh =(dtr_pali_hh!=. & dtr_pali_hh!=0);
		tab dtr_pali_rh [w=factor_hog] if n==1; 
		
*---------------PROGRAMA DE EMPLEO TEMPORAL-----------------------------------;			
		*After analyzing the amounts reported in the survey for this program, we decided limit 
		 limit the amount reported in the survey. Some of the amounts were too far from what it made sense. 
		 We limited the amount of the survet to the maximum amount permited according to the rules
		 of the program. 
		 **Recipient identifier;
		  gen dtr_empt_ri =(dtr_empt_in!=. & dtr_empt_in!=0);
		  
		  **Amount:we imputed the amount according to the rules of the program;
		  replace dtr_empt_in=62.33*132 if dtr_empt_in>=62.33*132 & dtr_empt_ri==1;
		  tab dtr_empt_ri [w=factor_hog];
		  tabstat dtr_empt_in [w=factor_hog], stat(sum) col(stat) format(%15.0gc);
				
*---------------PROGRAMA PROCAMPO---------------------------------------------;		
		  **Recipient identifier;
		  gen dtr_cmpo_ri =(dtr_cmpo_in!=. & dtr_cmpo_in!=0);

*---------------PROGRAMA BECAS------------------------------------------------;		
		  **Recipient identifier;
		   gen dtr_schp_ri =(dtr_schp_in!=. & dtr_schp_in!=0);
		
*---------------NON CONTRIBUTORY PENSIONS MEXICO CITY---------------------------;			
		**After analyzing the amounts reported in the survey for this program, we decided not to trust the survey.
         Amounts were inconsistent and many of them too far from what it made sense. 
		 We decided to trust the survey in terms of the beneficiaries, but 
		 in terms of the amount received; 
		 
		 **Recipient identifier;
		  gen dtr_pcmx_ri = (dtr_pcmx_in!=. & dtr_pcmx_in!=0);
		  tab dtr_pcmx_ri [w=factor_hog];
		 **Amount:we imputed the amount according to the rules of the program;
		  replace dtr_pcmx_in= 934.95*12 if dtr_pcmx_ri==1;
		
		**Target identifier;
		gen ent=substr(folioviv,1,2);
		gen  dtr_pcmx_ti=0;
		replace dtr_pcmx_ti=1 if edad>=68 & ent=="09"; 
		tabstat dtr_pcmx_ti [w=factor], c(stats) stats(sum) f(%19.2f);
		
		gen dtr_amyr_ri = (dtr_amyr_in!=. & dtr_amyr_in!=0);
		
		gen dtr_otrs_ri = (dtr_otrs_in!=. & dtr_otrs_in!=0);
		
		**Transforming variables into per capita level;
		foreach x in  dtr_schp dtr_cmpo dtr_70ms dtr_amyr  dtr_empt dtr_otrs dtr_pcmx {;
			replace  `x'_in= 0 if `x'_in==. ;
			bys folioviv foliohog: egen double `x'_hh=sum(`x'_in);
			gen double `x'_pc=`x'_hh/hsize;
		};
		
		
	local trans_gob =
	   "dtr_schp_pc 
		dtr_opor_pc
		dtr_cmpo_pc
		dtr_70ms_pc
		dtr_pcmx_pc
		dtr_amyr_pc
		dtr_pali_pc
		dtr_empt_pc
		dtr_otrs_pc"
		;
		
*----------------------------------------------------------------------------------------* 
                               Generating Disposable Income
*----------------------------------------------------------------------------------------*; 

	egen double yd_pc = rowtotal(yn_pc `trans_gob');	
	
	*Cleaning the dataset;
	 drop infan9  infan9_h  opo* tiene_b  otorg_b   nivelaprob  residencia  peso  pres_alta   ing_pen_in x dtr_opor_ri ent;
 
 save "${mod}yd_anual.dta", replace;
  



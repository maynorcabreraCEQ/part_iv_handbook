*----------------------------------------------------------------------------------------------------*
*- CEQ Mex 2012: Infrastructure and Labels and Harmonization of the dataset. 
*- Household survey: Encuesta Nacional de Ingreso y Gasto de los Hogares (ENIGH) 2012.
*- Author: Sandra Martinez-Aguilar and Enrique de la Rosa based on the previous 
*- work of John Scott, Enrique de la Rosa and Rodrigo Aranda.
*- Last Date of modification: March 15th, 2018.
*- Practical Information: This do-file add the infrastructure varibles, labels 
*- all the variables and harmonized the dataset.
*----------------------------------------------------------------------------------------------------*

#delimit;	
*1. ---------Infrastructure----------;	

use folioviv mat_pared mat_techos mat_pisos drenaje disp_elec disp_agua upm est_dis using "${vivienda}", clear;

	gen inf_walls=0 ;
	replace inf_walls=1 if mat_pared=="6" | mat_pared=="7" | mat_pared=="8"  ;
	label var inf_walls  "Quality walls:tabique,ladrillo,block,piedra,concreto"  ;
	label val inf_walls yesno ;
		
	gen inf_roof=0;
	replace inf_roof=1 if mat_techos=="4" | mat_techos=="5" | mat_techos=="6" | mat_techos=="7" | mat_techos=="8" | mat_techos=="9" ;
	label var inf_roof   "Roofing material: viguetas con bovedilla, madera, terrado con viguería, lamina metalica, de asbesto, palma, teja, o de calidad superior";
	 label val inf_roof yesno;
	 
	gen inf_floor=0;
	replace inf_floor=1 if mat_pisos=="2" | mat_pisos=="3";
	label var inf_floor  "Quality floor:Piso firme (laminado, mosaico, madera)";
	 label val inf_floor yesno;
	
	gen inf_sewage=0;
	replace inf_sewage=1 if drenaje=="1" | drenaje=="2";
	label var inf_sewage "Quality sanitation: drenaje conectado a la red publica o a una fosa septica";
	 label val inf_sewage yesno;
	
	gen inf_elect=0;
	replace inf_elect=1 if disp_elec=="1" | disp_elec=="2"| disp_elec=="3" | disp_elec=="4";
	label var inf_elect  "Access to electricity" ;
	 label val inf_elect yesno;
	
	gen inf_water=0;
	replace inf_water=1 if disp_agua=="1" | disp_agua=="2";
	label var inf_water  "Access to piped water" ;
	label val inf_water yesno;

	keep folioviv  upm est_dis inf*;
	joinby folioviv  using "${mod}ym_anual.dta", unmatched(both) _merge(m);	

	tab m;
	drop m;

    joinby folioviv foliohog numren using "${mod}yf_anual.dta", unmatched(both) _merge(m);
	
	tab m;
	drop m;
	
	tempfile infra;
	save `infra', replace;
	use folioviv foliohog tam_loc using "${Concen}", clear ;
	joinby folioviv foliohog using `infra', unmatched(both) _merge(m);
	
	tab m;
	drop m;
	
	destring tam_loc, replace;
	gen urban = (tam_loc==1 | tam_loc==2 |tam_loc==3);
	drop tam_loc;
	drop yd_hh;
	
	joinby folioviv foliohog using "${OPOR}", unmatched(both) _merge(m);
	tab m;
	drop m;
	replace dtr_opor_ti=0 if parentesco>="102";
	replace dtr_opor_rh=0 if parentesco>="102";
	replace dtr_pali_rh=0 if parentesco>="102";
	rename dtr_opor_ti dtr_opor_th;
	
*2. ---------Harmonization and Labels----------;	    
    
*1.- Survey and household variables;
* a.-Survey variables;
    label def yesno 0 "No" 1 "Yes" ; 
	rename factor_hog weight;
    label var weight "Sampling weight"     ;		
	
	gen double pline_ext = 9603.1 if urban==0 ;
	replace pline_ext = 13505.0 if urban==1;
	gen double pline_mod = 17877.1 if urban==0 ;
	replace pline_mod= 27943.8 if urban==1 ;
	
	label var pline_ext "National Extreme Poverty Line" ;
	label var pline_mod "National Moderate Poverty Line" ;
	
*b.- household variables ;
	label var urban "Living in urban area"  ;
	label def urban 0 "Rural" 1 "Urban" ;
	label val urban urban ;
	egen hhid = concat(folioviv  foliohog);
	label var hhid  "Household Identifier"  ;
	label var hsize "Household size" ;	

*2.-Household member variables ;
    rename numren memb_no ;
	label var memb_no "Correlative number of member";
	rename edad age  ;
	label var age "Age of the household members" ;
	rename sexo gender  ;
	destring gender, replace ;
	recode gender (2=1)(1=0) ;
	label var gender "Gender [0Male,1Female]" ;
	label def sex 0 "Male" 1 "Female" ;
	label val gender sex ;
	
	destring parentesco, replace;
	gen relation=0;
	replace relation=1 if parentesco<=102 ; 
	replace relation=2 if (parentesco>=201 & parentesco<=204) ;
	replace relation=3 if (parentesco>=301 & parentesco<=305) ;
	replace relation=4 if parentesco==601 | parentesco==602 | parentesco==615 ;
	replace relation=5 if (parentesco>=603 & parentesco<=614) | (parentesco>=616 & parentesco<=621) |  parentesco==623;
	replace relation=6 if parentesco==622 | parentesco>=701 | parentesco==501 | parentesco==502 | parentesco==503 | (parentesco>=401 & parentesco<=461);
	label var relation "Relationship to household head" ;
	
	   label def headrelation 
				1 "Head" 
				2 "Spouse/partner" 
				3 "Son/daughter (of the head of the household and/or of the partner of the head of the household)"  
				4 "Parents Mother/father in law" 
				5 "Other relatives"
				6 "Other non relative"
				 ;
		label val relation headrelation ;
        
		gen hhead=(relation==1) ;
		label var hhead "Household head" ;
		
		destring tipoesc, replace ;
		rename tipoesc type_school ;
		recode type_school (3=4);
		
		
        label var type_school "Type of school that it is attending (public, private, semi-private)" ;
				label def type_school 
				1 "Public" 
				2 "Private" 
				3 "Semi-private (subzided by government)" 
				4 "Other"
				 ;
		label val type_school type_school ;

		
		
		destring asis_esc nivel, replace;
		gen level_school=0 ;
		replace level_school=1 if asis_esc==1 & nivel==1 ;
		replace level_school=2 if asis_esc==1 & nivel==2 ;
		replace level_school=3 if asis_esc==1 & nivel==3 ;
		replace level_school=4 if asis_esc==1 & (nivel==4 | nivel==5) ;
		replace level_school=5 if asis_esc==1 & (nivel==3 | nivel==4 | nivel==5);
		replace level_school=6 if asis_esc==1 & nivel==6; 
		replace level_school=7 if asis_esc==1 & (nivel==7 | nivel==8);
		replace level_school=8 if asis_esc==1 & nivel==9 ;
		replace level_school=0 if asis_esc==0;
	
		label var level_school "Level of schooling that is attending" ;
						    	
			label def level_school 
				0 "Not attending" 
				1 "Preschool [0-5]" 
				2 "Primary [6-11]" 
				3 "Lower secondary [12-14]" 
				4 "Upper secondary [15-17]" 
				5 "Secondary [12-17]" 
				6 "Post-secondary [18-20]"
				7 "Tertiary (Bachelor’s or equivalent) [18-23]" 
				8 "Master, Doctoral or equivalent [23-28]"
				9 "Other (non specified before)"
				 ;
			label val level_school level_school	 ;         

      tab level_school type_school [w=weight];
	  **exit;
		
		gen at_school=(asis_esc==1);
		label var at_school "Currently attending school";
		label var at_school yesno ;
		
*Contributory pensions;
	 
	 label var pen_con_in  "Contributory pensions (individual)";
	 label var pen_con_hh  "Contributory pensions (household)";
	 label var pen_con_pc  "Contributory Pensions (per capita)" ;
	 
	 label var pen_con_ri  "Recipient Contributory Pensions (per capita)" ;

*Direct Taxes and Contributions;

	label var dtx_isr_in "Personal Income Tax Natural person(individual)";
	label var dtx_isr_ri "Tax Payers Personal Income Tax";
	label var dtx_isr_rh "Personal Income Tax Natural person(household reipient)";
	label var dtx_isr_hh "Personal Income Tax Natural person (household)";
	label var dtx_isr_pc "Personal Income Tax Natural Person(per capita)";

	label var con_ims_in  "Contributions to the Social Security IMSS (individual)";
	label var con_ist_in  "Contributions to the Social Security ISSSTE (individual)";
	label var con_pims_in "Contributions to pensions IMSS (individual)";
	label var con_pist_in "Contributions to pensions ISSSTE(individual)";
	
	label var con_ims_hh  "Contributions to the Social Security IMSS (household)";
	label var con_ist_hh  "Contributions to the Social Security ISSSTE (household)";
	label var con_pims_hh "Contributions to pensions IMSS (household)";
	label var con_pist_hh "Contributions to pensions ISSSTE (household)";
			
	label var con_ims_pc  "Contributions to the Social Security IMSS (per capita)";
	label var con_ist_pc  "Contributions to the Social Security ISSSTE (per capita)";
	label var con_pims_pc "Contributions to pensions IMSS (per capita)";
	label var con_pist_pc "Contributions to pensions ISSSTE (per capita)";
	
	label var con_ims_ri   "Contribution payer to the Social Security IMSS"; 
	label var con_ist_ri   "Contribution payer to the Social Security IMSS"; 
	label var con_pims_ri  "Contribution payer to pensions IMSS";
	label var con_pist_ri  "Contribution payer to pensions ISSSTE";

*Direct transfers;

	label var dtr_schp_in "Scholarship (individual)";
	label var dtr_cmpo_in "NCT Procampo (individual)";
	label var dtr_70ms_in "NCP 70 y mas (individual)";
	label var dtr_amyr_in "NCC Adultos Mayores (individual)";
	label var dtr_empt_in "NCC PET empleo temporal (individual)";
	label var dtr_pcmx_in "NCP Ciudad de Mexico (individual)";
	label var dtr_otrs_in "NCC Otros (individual)";
	
	label var dtr_pali_pc "NCC Apoyo Alimentario (per capita)";
	label var dtr_otrs_pc "NCC Otros (per capita)";

	label var dtr_schp_pc "Scholarship (per capita)";
	label var dtr_cmpo_pc "NCT Procampo (per capita)";
	label var dtr_70ms_pc "NCP 70 y mas (per capita)";
	label var dtr_amyr_pc "NCC Adultos Mayores (per capita)";
	label var dtr_pcmx_pc "NCP Ciudad de Mexico (per capita)" ;
	label var dtr_empt_pc "NCC PET empleo temporal (per capita)";
	label var dtr_opor_pc "CCT Oportunidades (per capita)";

	label var dtr_schp_hh "Scholarship (household)";
	label var dtr_cmpo_hh "NCT Procampo (household)";
	label var dtr_70ms_hh "NCP 70 y mas (household)";
	label var dtr_amyr_hh "NCC Adultos Mayores (household)";
	label var dtr_empt_hh "NCC PET empleo temporal (household)";
	label var dtr_opor_hh "CCT Oportunidades (household)";
	label var dtr_pali_hh "NCC Apoyo Alimentario (household)";
	label var dtr_otrs_hh "NCC Otros (household)";
	label var dtr_pcmx_hh "NCP Ciudad de Mexico (household)";
	
	label var dtr_70ms_ri "Recipient of NCP 70 y mas";
	label var dtr_empt_ri "Recipient of NCC PET empleo temporal";
	label var dtr_cmpo_ri "Recipient of NCT Procampo";
	label var dtr_schp_ri "Recipient of Scholarship";
	label var dtr_pcmx_ri "Recipient of NCP Ciudad de Mexico";	
	label var dtr_opor_rh "Recipient of CCT Oportunidades";
	label var dtr_pali_rh "Recipient of NCC Apoyo Alimentario";	
	label var dtr_amyr_ri "Recipient of NCC Adultos Mayores";
	
	label var dtr_70ms_ti "Target of NCP 70 y mas";
	label var dtr_pcmx_ti "Traget of NCP Ciudad de Mexico";
	label var dtr_opor_th "Target of CCT Oportunidades";
	
 *Health ;
 
	 label var hlt_imss_in "In-Kind Health Benefits IMSS: Contributory (individual)";
	 label var hlt_iste_in "In-Kind Health Benefits ISSSTE: Contributory (individual)";
	 label var hlt_imso_in "In-Kind Health Benefits IMSS-OPORTUNIDADES: Non Contributory (individual)";
	 label var hlt_pemx_in "In-Kind Health Benefits PEMEX: Contributory (individual)";
	 label var hlt_ssa_in  "In-Kind Health Benefits SRIA DE SALUD: Non Contributory (individual)";
	 label var hlt_spop_in "In-Kind Health Benefits SEGURO POPULAR: Non Contributory (individual)";
	 
	 label var hlt_imss_hh "In-Kind Health Benefits IMSS: Contributory (household)";
	 label var hlt_iste_hh "In-Kind Health Benefits ISSSTE: Contributory (household)";
	 label var hlt_imso_hh "In-Kind Health Benefits IMSS-OPORTUNIDADES: Non Contributory (household)";
	 label var hlt_pemx_hh "In-Kind Health Benefits PEMEX: Contributory (household)";
	 label var hlt_ssa_hh  "In-Kind Health Benefits SRIA DE SALUD: Non Contributory (household)";
	 label var hlt_spop_hh "In-Kind Health Benefits SEGURO POPULAR: Non Contributory (household)";
	 
	 label var hlt_imss_pc "In-Kind Health Benefits IMSS: Contributory (per capita)";
	 label var hlt_iste_pc "In-Kind Health Benefits ISSSTE: Contributory (per capita)";
	 label var hlt_imso_pc "In-Kind Health Benefits IMSS-OPORTUNIDADES: Non Contributory (per capita)";
	 label var hlt_pemx_pc "In-Kind Health Benefits PEMEX: Contributory (per capita)";
	 label var hlt_ssa_pc  "In-Kind Health Benefits SRIA DE SALUD: Non Contributory (per capita)";
	 label var hlt_spop_pc "In-Kind Health Benefits SEGURO POPULAR: Non Contributory (per capita)";
	 
	 label var hlt_imss_ri "Recipients of In-Kind Health Benefits IMSS: Contributory";
	 label var hlt_iste_ri "Recipients of In-Kind Health Benefits ISSSTE: Contributory";
	 label var hlt_imso_ri "Recipients of In-Kind Health Benefits IMSS-OPORTUNIDADES: Non Contributory";
	 label var hlt_pemx_ri "Recipients of In-Kind Health Benefits PEMEX: Contributory";
	 label var hlt_ssa_ri  "Recipients of In-Kind Health Benefits SRIA DE SALUD: Non Contributory";
	 label var hlt_spop_ri "Recipients of In-Kind Health Benefits SEGURO POPULAR: Non Contributory";

	 
 *Education;

     label var edu_pres_in "In-Kind Education Benefits: pre-school Level (individual)";
     label var edu_prim_in "In-Kind Education Benefits: primary Level (individual)";
	 label var edu_lsec_in "In-Kind Education Benefits: lower secondary Level (individual)";
	 label var edu_usec_in "In-Kind Education Benefits: upper secondary Level (individual)";
	 label var edu_terc_in "In-Kind Education Benefits: tertiary Level (individual)";
	 
	 label var edu_pres_pc "In-Kind Education Benefits: pre-school Level (per capita)";
     label var edu_prim_pc "In-Kind Education Benefits: primary Level (per capita)";
	 label var edu_lsec_pc "In-Kind Education Benefits: lower secondary Level (per capita)";
	 label var edu_usec_pc "In-Kind Education Benefits: upper secondary Level (per capita)";
	 label var edu_sect_pc "In-Kind Education Benefits: secondary total (per capita)";
	 label var edu_terc_pc "In-Kind Education Benefits: tertiary Level (per capita)";
	 
	 label var edu_pres_hh "In-Kind Education Benefits: pre-school Level (household)";
     label var edu_prim_hh "In-Kind Education Benefits: primary Level (household)";
	 label var edu_lsec_hh "In-Kind Education Benefits: lower secondary Level (household)";
	 label var edu_usec_hh "In-Kind Education Benefits: upper secondary Level (household)";
	 label var edu_terc_hh "In-Kind Education Benefits: tertiary Level (household)";
	 
     label var edu_pres_ri "Recipients of In-Kind Education Benefits: pre-school Level";
     label var edu_prim_ri "Recipients of In-Kind Education Benefits: primary Level";
	 label var edu_lsec_ri "Recipients of In-Kind Education Benefits: lower secondary Level";
	 label var edu_usec_ri "Recipients of In-Kind Education Benefits: upper secondary Level";
	 label var edu_sect_ri "Recipients of In-Kind Education Benefits: total secondary Level";
	 label var edu_terc_ri "Recipients of In-Kind Education Benefits: tertiary Level";	 

	 label var edu_pres_ti "Target of In-Kind Education Benefits: pre-school Level";
     label var edu_prim_ti "Target of In-Kind Education Benefits: primary Level";
	 label var edu_lsec_ti "Target of In-Kind Education Benefits: lower secondary Level";
	 label var edu_usec_ti "Target of In-Kind Education Benefits: upper secondary Level";
	 label var edu_sect_ti "Target of In-Kind Education Benefits: total secondary Level";
	 label var edu_terc_ti "Target of In-Kind Education Benefits: tertiary Level";
	 
	
 	
*Subsidies;

	 label var sub_gaso_hh "Subsidy to Gasoline (household)";
	 label var sub_gasl_hh "Subsidy to Gas LP (household)";
	 label var sub_elec_hh "Subsidy electricity LP (household)";
	 
	 label var sub_gaso_pc "Subsidy to Gasoline (per capita)";
	 label var sub_gasl_pc "Subsidy to Gas LP (per capita)";
	 label var sub_elec_pc "Subsidy to electricity (per capita)";
	 
	 label var sub_gaso_rh "Recipient of Subsidy to Gasoline";
	 label var sub_gasl_rh "Recipient of Subsidy to Gas LP";
	 label var sub_elec_rh "Recipient of Subsidy to electricity";
 
 *Indirect taxes; 
	label var itx_iva_hh  "Value-Added Tax (household)";
	label var itx_itab_hh "Tobaco Excises (household)";
	label var itx_ibal_hh "Alcoholic Beverages Excises (household)";
	label var itx_icev_hh "Beer Excises (household)";
	label var itx_icom_hh "Communications Excises (household)";
	label var itx_iene_hh "Energy Beverages Excises (household)";
		
	label var itx_iva_pc  "Value-Added Tax (per capita)";
	label var itx_itab_pc "Tobaco Excises (per capita)";
	label var itx_ibal_pc "Alcoholic Beverages Excises (per capita)";
	label var itx_icev_pc "Beer Excises (per capita)";
	label var itx_icom_pc "Communications Excises (per capita)";
	label var itx_iene_pc "Energy Beverages Excises (per capita)";
	
	label var itx_iva_rh  "Tax payer Value-Added Tax (per capita)";
	label var itx_itab_rh "Tax payer Tobaco Excises (per capita)";
	label var itx_ibal_rh "Tax payer Alcoholic Beverages Excises (per capita)";
	label var itx_icev_rh "Tax payer Beer Excises (per capita)";
	label var itx_icom_rh "Tax payer Communications Excises (per capita)";
	label var itx_iene_rh "Tax payer Energy Beverages Excises (per capita)";

*Core Income Concepts (Per capita);
	 label var ym_pc "Market Income (per capita)";
	 label var yn_pc "Net Market Income (per capita)";
	 label var yp_pc "Market Income plus pensions (per capita)";
	 label var yg_pc "Gross Income (per capita)";
	 label var yt_pc "Taxable Income (per capita)";
   	 label var yd_pc "Disposable Income (per capita)";
	 label var yc_pc "Consumable Income (per capita)";
	 label var yf_pc "Final Income (per capita)";
	
*Otros;

rename upm psu	;
label var psu "Primary sampling Unit";

rename est_dis	strata ;
label var strata "Sampling stratum";

drop asis_esc nivel parentesco edu_sect_hh edu_sect_in;

order hhid hsize weight urban hhead relation gender age pline_ext pline_mod  ym* pen* yp* con* dtx* yn* dtr* yd* sub* yc* ;

save "${mod}CEQ_Mex_2012_Feb13.dta", replace;
 

*----------------------------------------------------------------------------------------------------*
*- CEQ Mex 2012: Final Income. 
*- Household survey: Encuesta Nacional de Ingreso y Gasto de los Hogares (ENIGH) 2012.
*- Author: Sandra Martinez-Aguilar and Enrique de la Rosa based on the previous 
*- work of John Scott, Enrique de la Rosa and Rodrigo Aranda.
*- Last Date of modification: March 15th, 2018.
*- Practical Information: This do-file builds Market Income plus Pensions , 
*- which is based on Net Market Income.
*----------------------------------------------------------------------------------------------------*
	#delimit;
	
*---------------------------Income Tax and Social Security Contributions ---------------------------*;
*---------------------------Personal Income Tax ---------------------------*;
*1 Deductions
  1)School tuition 
  2)Compulsory school transportation included in the tuition. Mexico City only.
  3)Payments for medical & dental fees, and hospital expenses.
  4)Funeral expenses.
  5)Payment for Health insurance, complementary  or independent from the health insurance covered by social insurance.
;
  
	* Medical and funeral expenses are obtained from the  household expenses dataset; 	
		use folioviv foliohog  gasto_tri clave using "${Gasto_h}", clear;
       
	   *Medical expense;
	    gen double ded_med_hh=gasto_tri*4 if 
		(clave>="J001" & clave<="J002") |                 /*Birth */
		(clave>="J007" & clave<="J008") | clave=="J012" | /*Pregnancy*/
		(clave>="J016" & clave<="J018") |                 /*medical consultation*/
		 clave=="J036" |                                  /*weight control*/
		 clave=="J039" | clave=="J040"                    /*hospital care*/
		 ;
	    replace ded_med_hh=0 if ded_med_hh==.; 	
		gen   double con_spop_hh  = gasto_tri*4 if clave=="J072";				
		gen   double ded_fun_hh  = gasto_tri*4 	if clave=="N002";
		replace  ded_fun_hh=0 if ded_fun_hh==.;
		collapse (sum) ded* con_spop_hh, by(folioviv foliohog);
        tempfile deducciones1;
		save `deducciones1', replace;
		
	* 	Tuition, transportation and popular insurance expenses are obtained from the individual expenses dataset;	
		use folioviv foliohog numren gasto_tri clave colegia using "${Gasto_p}", clear;
		replace colegia = colegia*10;
		rename colegia g_colegia_in;
		gen   double g_tran_in  = gasto_tri*4/12*10 if clave=="E013";	
		foreach var of varlis g_colegia_in g_tran_in  {;
			replace `var'=0 if `var'==. ;
		};
		
		collapse (sum) g* , by(folioviv foliohog numren);
        tempfile deducciones2;
		save `deducciones2', replace;
		
	* Merging both datasets with the population dataset ;	
		use folioviv foliohog numren parentesco asis_esc tipoesc nivel segpop  inst* inscr_1 edad using "${Pobla12}", clear;
		*We do not include guest or domestic workers;		
		gen ent=substr(folioviv,1,2);
		
		joinby folioviv foliohog  using `deducciones1', unmatched(both) _merge(m);
		drop m;
		joinby folioviv foliohog numren using `deducciones2', unmatched(both) _merge(m);
		
		drop if parentesco>="400" & parentesco <"500";
		drop if parentesco>="700" & parentesco <"800";
		tab m;
		drop m;
		 replace ded_med_hh=0 if ded_med_hh==.; 
		 replace  ded_fun_hh=0 if ded_fun_hh==.;
		 
	* Tuition;
		gen pres=(asis_esc=="1" &  tipoesc=="2" & nivel=="1");
		gen prim=(asis_esc=="1" &  tipoesc=="2" & nivel=="2");
		gen sec =(asis_esc=="1" &  tipoesc=="2" & nivel=="3");
		gen tec =(asis_esc=="1" &  tipoesc=="2" & nivel=="4");
		gen bac =(asis_esc=="1" &  tipoesc=="2" & nivel=="5");		
		
		gen double ded_colegia = 0;
		replace ded_colegia = g_colegia_in if g_colegia_in<=14200 & pres==1 ;
		replace ded_colegia = 14200        if g_colegia_in>14200  & pres==1 ;
		replace ded_colegia = g_colegia_in if g_colegia_in<=12900 & prim==1 ;
		replace ded_colegia = 12900        if g_colegia_in>12900  & prim==1 ;
		replace ded_colegia = g_colegia_in if g_colegia_in<=19900 & sec==1 ;
		replace ded_colegia = 19900        if g_colegia_in>19900  & sec==1 ;
		replace ded_colegia = g_colegia_in if g_colegia_in<=17100 & tec==1 ;
		replace ded_colegia = 17100        if g_colegia_in>17100  & tec==1 ;
		replace ded_colegia = g_colegia_in if g_colegia_in<=24500 & bac==1 ;
		replace ded_colegia = 24500        if g_colegia_in>24500  & bac==1 ;
		
		gen colegia_ri=(g_colegia_in!=. & g_colegia_in!=0) ;
		gen ded_colegia_ri =(ded_colegia!=. & ded_colegia!=0) ;
		
	* School Transportation;	
		gen trans=(asis_esc=="1" &  tipoesc=="2" & (nivel=="2" | nivel=="3") & ent=="09");
		gen double ded_trans=0;
		replace  ded_trans = g_tran_in if trans==1;
		replace ded_trans=0 if ded_trans==.;
		
		bys folioviv foliohog: egen  double colegia_rh=max(colegia_ri);
		bys folioviv foliohog: egen  double ded_colegia_rh=max(ded_colegia_ri);
        
		bys folioviv foliohog: egen  double ded_coleg_hh=sum(ded_colegia);
		bys folioviv foliohog: egen  double ded_trans_hh=sum(ded_trans);
				
		egen  double ded_educa_hh=rowtotal(ded_coleg_hh ded_trans_hh);
		tempfile deducciones3;
        save `deducciones3', replace;			

*2----------Identifying  incomes that pay direct taxes (ISR) ;
		use "${Ingresos}", clear;
		keep folioviv foliohog clave ing_tri numren;
		gen double ing_an=ing_tri*4;	
	
	* Wages that pay ISR (tax base);
		gen double ing_subp=ing_an if (clave>="P001" & clave<="P003") | (clave=="P006") /*| (clave>="P008" & clave<="P009") */;
		gen double ing_subs=ing_an if (clave=="P014");         
		gen double ing_indp=ing_an if (clave>="P011" & clave<="P012") ;			
		gen double ing_inds=ing_an if (clave>="P018" & clave<="P019");
		
	* Income from business and professional activities;
		gen double ing_npp=ing_an if (clave>="P068" & clave<="P074");
		gen double ing_nps=ing_an if (clave>="P075" & clave<="P081");

	* Property income;
		gen double ing_renta=ing_an if clave>="P023" | clave<="P024" | clave=="P030";
	
	* Interest;
		gen double ing_intp=ing_an if (clave>="P026" & clave<="P029");	

*3----------Identifying  incomes used to calculate the payment of contributions 
		efectivo por cuota diaria (P001) 
		gratificaciones (P005) , 
		percepciones (P006) , 
		aguinaldo (P009)
		alimentación, 
		habitación, 
		primas (incluye prima vacacional) (P007), 
		comisiones (P003), 
		prestaciones en especie 
		excluding Reparto Utilidades (Articulo 27 LSS) horas extras 
		Se divide entre 30
		;
		gen double bi_sp=ing_an if (clave>="P001" & clave<="P003") | (clave>="P005" & clave<="P007") | (clave=="P009") ;
		gen double bi_in=ing_an if (clave>="P011" | clave>="P018") ;
        
		collapse (sum) ing_sub*  ing_ind* ing_np* ing_renta ing_int bi*, by(folioviv foliohog numren);
		tempfile ingresos;
		save `ingresos', replace ;
		
	* Merge with labor dataset;
		use folioviv foliohog numren subor indep tiene_suel pres* id_trabajo contrato com_fis reg_cont 
		clas_emp sinco using "${Trabajos}", clear;
		destring id_trabajo, replace;
		
		gen subordi= (subor=="1");
		gen indepen= (indep=="1");
		gen sarafore=(pres_8=="08");
		gen pmedica=(pres_1=="01" );
		gen tiene_sueldo=(tiene_suel=="1");
		
		keep folioviv foliohog numren id_trabajo subordi indepen sarafore pmedica tiene_sueldo contrato com_fis reg_cont clas_emp sinco;
		reshape wide subordi indepen sarafore pmedica tiene_sueldo contrato com_fis reg_cont clas_emp sinco, i(folioviv foliohog numren) j(id_trabajo);

		joinby folioviv foliohog numren using `ingresos', unmatched(both) _merge(m);
		tab m;
		drop m;
		joinby folioviv foliohog numren using `deducciones3', unmatched(both) _merge(m);
		tab m;
		drop m;
		save `ingresos', replace ;	
		
	* Building the taxable base for ISR;
        gen afiliado=(inst_1=="1" | inst_2=="2" | inst_3=="3" | inst_4=="4");
		gen sueldo1=(ing_subp!=. & ing_subp!=0);
		gen sueldo2=(ing_subs!=. & ing_subs!=0);
		gen sueldo3=(ing_indp!=. & ing_indp!=0);
		gen sueldo4=(ing_inds!=. & ing_inds!=0);
		gen paga_imp=(sarafore1==1 | afiliado==1) & (inscr_1=="1");
					
		gen double ing_lab1 =ing_subp if (sarafore1==1 | afiliado==1) & (inscr_1=="1");
		gen double ing_lab2 =ing_subs if (sarafore2==1 | afiliado==1) & (inscr_1=="1");
		gen double ing_lab3 =ing_indp if ((sarafore1==1 | afiliado==1) & tiene_sueldo1==1) 
		                     | (com_fis1=="1" | com_fis1=="2")  ;
		gen double ing_lab4 =ing_inds if ((sarafore2==1 | afiliado==1) & tiene_sueldo2==1) 
		                     | (com_fis2=="1" | com_fis2=="2")  ;
							 
		egen double ing_lab5=rowtotal(ing_lab*);
		drop ing_lab1 ing_lab2 ing_lab3 ing_lab4;
		rename ing_lab5 ing_lab_in;

		gen double ing_neg1=ing_npp if (com_fis1=="1" | com_fis1=="1" | reg_cont1=="1");
		gen double ing_neg2=ing_nps if (com_fis2=="1" | com_fis2=="1" | reg_cont2=="1");
		egen double ing_neg3=rowtotal(ing_neg1 ing_neg2);
		drop ing_neg1 ing_neg2 ;
		rename ing_neg3 ing_neg_in;
		
		foreach  i in ing_lab_in ing_neg_in ing_intp bi_sp bi_in {;
		replace `i'=0 if `i'==.;
		gen double `i'_ai=0;
		replace `i'_ai= (`i')/(1- 0.0192)                           if                    (`i')/(1- 0.0192)<=  5952.84;
		replace `i'_ai= (`i' - 5952.84*0.0640 +  114.24)/(1-0.0640) if ((`i' - 5952.84*0.0640 +  114.24)/(1-0.0640)>  5952.84 &  (`i' - 5952.84*0.0640 +  114.24)/(1-0.0640)<= 50524.92);
		replace `i'_ai= (`i' -50524.92*0.1088 + 2966.76)/(1-0.1088) if ((`i' -50524.92*0.1088 + 2966.76)/(1-0.1088)> 50524.92 &  (`i' -50524.92*0.1088 + 2966.76)/(1-0.1088)<= 88793.04);
		replace `i'_ai= (`i'- 88793.04*0.1600 + 7130.88)/(1-0.1600) if ((`i'- 88793.04*0.1600 + 7130.88)/(1-0.1600)> 88793.04 &  (`i'- 88793.04*0.1600 + 7130.88)/(1-0.1600)<=103218.00);
		replace `i'_ai= (`i'-103218.00*0.1792 + 9438.60)/(1-0.1792) if ((`i'-103218.00*0.1792 + 9438.60)/(1-0.1792)>103218.00 &  (`i'-103218.00*0.1792 + 9438.60)/(1-0.1792)<=123580.20);
		replace `i'_ai= (`i'-123580.20*0.2136 +13087.44)/(1-0.2136) if ((`i'-123580.20*0.2136 +13087.44)/(1-0.2136)>123580.20 &  (`i'-123580.20*0.2136 +13087.44)/(1-0.2136)<=249243.48);
		replace `i'_ai= (`i'-249243.48*0.2352 +39929.04)/(1-0.2352) if ((`i'-249243.48*0.2352 +39929.04)/(1-0.2352)>249243.48 &  (`i'-249243.48*0.2352 +39929.04)/(1-0.2352)<=392841.96);
		replace `i'_ai= (`i'-392841.96*0.3000 +73703.40)/(1-0.3000) if ((`i'-392841.96*0.3000 +73703.40)/(1-0.3000)>392841.96 );
	};	
	    egen double igrav=rowtotal(ing_lab_in_ai ing_neg_in_ai ing_intp_ai) ;		
		gen double  dtx_isr_in=0;
		replace dtx_isr_in= (igrav          )*0.0192          if                    igrav<=  5952.84;
		replace dtx_isr_in= (igrav - 5952.84)*0.0640+  114.24 if (igrav>  5952.84 & igrav<= 50524.92);
		replace dtx_isr_in= (igrav -50524.92)*0.1088+ 2966.76 if (igrav> 50524.92 & igrav<= 88793.04);
		replace dtx_isr_in= (igrav- 88793.04)*0.1600+ 7130.88 if (igrav> 88793.04 & igrav<=103218.00);
		replace dtx_isr_in= (igrav-103218.00)*0.1792+ 9438.60 if (igrav>103218.00 & igrav<=123580.20);
		replace dtx_isr_in= (igrav-123580.20)*0.2136+13087.44 if (igrav>123580.20 & igrav<=249243.48);
		replace dtx_isr_in= (igrav-249243.48)*0.2352+39929.04 if (igrav>249243.48 & igrav<=392841.96);
		replace dtx_isr_in= (igrav-392841.96)*0.3000+73703.40 if (igrav>392841.96 );

		gen dtx_isr_ri=(dtx_isr_in!=. & dtx_isr_in!=0);
		bys folioviv foliohog: egen dtx_isr_rh=sum(dtx_isr_ri);		
		
		gen nieto1=(parentesco=="609" & asis_esc=="1" & tipoesc=="2");
		gen nieto2=(parentesco=="609");

		bys folioviv foliohog: egen  nieto1_h=max(nieto1);
		bys folioviv foliohog: egen  nieto2_h=max(nieto2);
		
		gen jefe_npaga=(parentesco=="101" & dtx_isr_ri==0);
		gen espo_npaga=(parentesco=="201" & dtx_isr_ri==0);	
		gen hijos=(parentesco>="301" & parentesco<="305");
		gen hijo_npaga=((parentesco>="301" & parentesco<="305") & dtx_isr_ri==0);
		gen hijo_paga=((parentesco>="301" & parentesco<="305") & dtx_isr_ri==1);
		bys folioviv foliohog: egen  hijo_npaga_h=max(hijo_npaga);
		bys folioviv foliohog: egen  hijo_paga_h=max(hijo_paga);
		bys folioviv foliohog: egen  jefe_npaga_h=max(jefe_npaga);
		bys folioviv foliohog: egen  espo_npaga_h=max(espo_npaga);
		bys folioviv foliohog: egen  no_hijos_h=max(hijos);
		
		gen padre_npaga_h	 =(jefe_npaga_h==1 & espo_npaga_h==1);				
		gen nadie_paga_h	 =(padre_npaga_h==1 & hijo_npaga_h==1);
		replace nadie_paga_h = 1 if  padre_npaga_h==1 & no_hijos_h==0 & nieto2_h==1;
 		
		*The above expenses will be deductible when they are for you, your spouse, partner, children, grandchildren, parents or grandparents,
          provided that such persons have not received income in 2012 equal to or greater than the minimum wage;
		
		scalar SMA = 22812.78; /*minimum annual wage*/
		
				
	* Building taxable base considering deductions;	
		 gen double ded_igrav= 0;
		 replace ded_igrav=igrav;
	* only one person  pays taxes in the household;

		replace ded_igrav = igrav - ded_educa_hh - ded_med_hh - ded_fun_hh if dtx_isr_rh==1 & dtx_isr_ri==1; 
		
	* more than one person  pay taxes in the household
	  1) we assess who is paying higher taxes;
	 
		bys folioviv foliohog: egen double max_tax=max(dtx_isr_in) if dtx_isr_rh>1  & dtx_isr_ri==1 & ((parentesco=="101" | parentesco=="201") | (parentesco>="301" & parentesco<="305" & padre_npaga_h==1) | (parentesco=="609" & nadie_paga_h==1));
		bys folioviv foliohog: egen double col_max=max(dtx_isr_in) if dtx_isr_rh>1  & dtx_isr_ri==1 & ((parentesco=="101" | parentesco=="201") | (parentesco>="301" & parentesco<="305" & nieto1_h==1));

	* 2) we assumed that who pay higher taxes will use the deduction in his/her favor;	
		gen paga_deducion_ri= (dtx_isr_in==max_tax);
		bys folioviv foliohog: egen double paga_deducion_hh=sum(paga_deducion_ri);
		
		gen paga_colegia_ri= (dtx_isr_in==col_max);
		bys folioviv foliohog: egen double paga_colegia_hh=sum(paga_colegia_ri);
		

		replace ded_igrav = igrav - ded_educa_hh  if dtx_isr_rh>=2 & dtx_isr_ri==1 & paga_colegia_ri==1 & paga_colegia_hh==1 ;

    
	* 3) If two or more individuals pay the same amount of taxes, we assign the deduction to the household head;
		
		replace ded_igrav = igrav - ded_educa_hh            if dtx_isr_rh>1 & dtx_isr_ri==1 & paga_colegia_ri==1  & paga_colegia_hh>1 & parentesco=="101";
		
		replace ded_igrav = ded_igrav - ded_med_hh - ded_fun_hh if dtx_isr_rh>1 & dtx_isr_ri==1 & paga_deducion_ri==1 & paga_deducion_hh==1;

		replace ded_igrav = ded_igrav - ded_med_hh - ded_fun_hh if dtx_isr_rh>1 & dtx_isr_ri==1 & paga_deducion_ri==1 & paga_deducion_hh>1 & parentesco=="101";
        replace ded_igrav=0 if ded_igrav<0 | ded_igrav==.;
		
        br folioviv foliohog numren parentesco dtx_isr_rh dtx_isr_ri paga_colegia_ri col_max paga_colegia_hh  paga_deducion_ri  dtx_isr_in max_tax igrav ded_igrav 
		 nivel tipoesc asis_esc g_colegia_in ded_colegia ded_coleg_hh g_tran_in ded_trans_hh ded_educa_hh  ded_med_hh
		      if dtx_isr_rh>=2 & paga_colegia_hh>1 ;	
		
		drop dtx_isr_in dtx_isr_ri dtx_isr_rh;
		
		gen double  dtx_isr_in=0;
		replace dtx_isr_in= (ded_igrav          )*0.0192          if                        ded_igrav<=  5952.84;
		replace dtx_isr_in= (ded_igrav - 5952.84)*0.0640+  114.24 if (ded_igrav>  5952.84 & ded_igrav<= 50524.92);
		replace dtx_isr_in= (ded_igrav -50524.92)*0.1088+ 2966.76 if (ded_igrav> 50524.92 & ded_igrav<= 88793.04);
		replace dtx_isr_in= (ded_igrav- 88793.04)*0.1600+ 7130.88 if (ded_igrav> 88793.04 & ded_igrav<=103218.00);
		replace dtx_isr_in= (ded_igrav-103218.00)*0.1792+ 9438.60 if (ded_igrav>103218.00 & ded_igrav<=123580.20);
		replace dtx_isr_in= (ded_igrav-123580.20)*0.2136+13087.44 if (ded_igrav>123580.20 & ded_igrav<=249243.48);
		replace dtx_isr_in= (ded_igrav-249243.48)*0.2352+39929.04 if (ded_igrav>249243.48 & ded_igrav<=392841.96);
		replace dtx_isr_in= (ded_igrav-392841.96)*0.3000+73703.40 if (ded_igrav>392841.96 );
		replace dtx_isr_in=0  if dtx_isr_in<0;
		gen dtx_isr_ri=(dtx_isr_in!=. & dtx_isr_in!=0);
		bys folioviv foliohog: egen dtx_isr_rh=sum(dtx_isr_ri);
		

*---------------------------Contributions---------------------------*;
* Contribution base;
       
		gen ocupa=substr(sinco1,1,1);
   
	* All contributions, but contributions to pensions; 
		gen double con_ims_in=0;
		replace con_ims_in =bi_sp_ai/(1-0.0238) *(0.07618) + SMA*0.204 if  inst_1=="1" & inscr_1=="1"  & (bi_sp_ai/(1-0.0238)>SMA & bi_sp_ai/(1-0.0238)<=SMA*25);
		replace con_ims_in =SMA*25              *(0.07618) + SMA*0.204  if  inst_1=="1" & inscr_1=="1" & (bi_sp_ai/(1-0.0238)>SMA*25);
		replace con_ims_in =SMA                 *(0.07618) + SMA*0.204  if  inst_1=="1" & inscr_1=="1" & (bi_sp_ai/(1-0.0238)<=SMA);
        
		replace con_ims_in = 1371.3 if tiene_sueldo1==1 & inst_1=="1" & inscr_1=="1" & edad>0   & edad<=19 ;
		replace con_ims_in = 1602.6 if tiene_sueldo1==1 & inst_1=="1" & inscr_1=="1" & edad>=20 & edad<=39 ;
		replace con_ims_in = 2395.4 if tiene_sueldo1==1 & inst_1=="1" & inscr_1=="1" & edad>=40 & edad<=59 ;
		replace con_ims_in = 3604.7 if tiene_sueldo1==1 & inst_1=="1" & inscr_1=="1" & edad>=60 ;
        replace con_ims_in =con_ims_in*0.84;
        gen con_ims_ri=(con_ims_in!=. & con_ims_in!=0);
	  	gen double con_ist_in=0;
		replace con_ist_in =bi_sp_ai*0.17/(1-0.10625)*(0.1947) if  (ocupa=="1" | ocupa=="2") & (inst_2=="2" | inst_3=="3" ) & inscr_1=="1" & bi_sp_ai*0.17/(1-0.10625)>= SMA & bi_sp_ai*0.17/(1-0.10625)<=SMA*25;
		replace con_ist_in =SMA*25*(0.1947)                    if  (ocupa=="1" | ocupa=="2") & (inst_2=="2" | inst_3=="3" ) & inscr_1=="1" & bi_sp_ai*0.17/(1-0.10625)>=SMA*25;
		replace con_ist_in =SMA*(0.1947)                       if  (ocupa=="1" | ocupa=="2") & (inst_2=="2" | inst_3=="3" ) & inscr_1=="1" &                                 bi_sp_ai*0.17/(1-0.10625)<=SMA;
		replace con_ist_in =bi_sp_ai*0.5/(1-0.10625)*(0.1947)  if  (ocupa!="1" & ocupa!="2") & (inst_2=="2" | inst_3=="3" ) & inscr_1=="1" & bi_sp_ai*0.5/(1-0.10625)>=SMA  & bi_sp_ai*0.5/(1-0.10625)<=SMA*25;
		replace con_ist_in =SMA*25                   *(0.1947) if  (ocupa!="1" & ocupa!="2") & (inst_2=="2" | inst_3=="3" ) & inscr_1=="1" & bi_sp_ai*0.5/(1-0.10625)>=SMA*25;
		replace con_ist_in =SMA                      *(0.1947) if  (ocupa!="1" & ocupa!="2") & (inst_2=="2" | inst_3=="3" ) & inscr_1=="1" &                                 bi_sp_ai*0.5/(1-0.10625)<=SMA;
        gen con_ist_ri=(con_ist_in!=. & con_ist_in!=0);   
   
	*Contributions to pensions ;   
		gen double con_pims_in=0;
		replace    con_pims_in =bi_sp_ai/(1-0.0238) *(0.06275)  if  inst_1=="1" & inscr_1=="1" & (bi_sp_ai/(1-0.0238)>=SMA & bi_sp_ai/(1-0.0238)<=SMA*25);
		replace con_pims_in =SMA*25                 *(0.06275) if  inst_1=="1" & inscr_1=="1" & (bi_sp_ai/(1-0.0238)>=SMA*25);
		replace con_pims_in =SMA                    *(0.06275) if  inst_1=="1" & inscr_1=="1" & (bi_sp_ai/(1-0.0238)<=SMA);
        replace con_pims_in=con_pims_in*0.84;
		
		gen con_pims_ri=(con_pims_in!=. & con_pims_in!=0);		  
		gen double con_pist_in=0;
		replace    con_pist_in =bi_sp_ai*0.17/(1-0.10625) *(0.113) if (ocupa=="1" | ocupa=="2") & (inst_2=="1" | inst_3=="1" ) & inscr_1=="1" & bi_sp_ai*0.17/(1-0.10625)>=SMA & bi_sp_ai*0.17/(1-0.10625)<=SMA*25;
		replace    con_pist_in =SMA*25                    *(0.113) if (ocupa=="1" | ocupa=="2") & (inst_2=="2" | inst_3=="3" ) & inscr_1=="1" & bi_sp_ai*0.17/(1-0.10625)>=SMA*25;
		replace    con_pist_in =SMA                       *(0.113) if (ocupa=="1" | ocupa=="2") & (inst_2=="2" | inst_3=="3" ) & inscr_1=="1" &                                  bi_sp_ai*0.17/(1-0.10625)<=SMA;
		replace    con_pist_in =bi_sp_ai*0.5/(1-0.10625)  *(0.113) if (ocupa!="1" & ocupa!="2") & (inst_2=="1" | inst_3=="1" ) & inscr_1=="1" & bi_sp_ai*0.5/(1-0.10625)>=SMA   & bi_sp_ai*0.5 /(1-0.10625)<=SMA*25;
		replace    con_pist_in =SMA*25                    *(0.113) if (ocupa!="1" & ocupa!="2") & (inst_2=="2" | inst_3=="3" ) & inscr_1=="1" & bi_sp_ai*0.5/(1-0.10625)>=SMA*25;
		replace    con_pist_in =SMA                       *(0.113) if (ocupa!="1" & ocupa!="2") & (inst_2=="2" | inst_3=="3" ) & inscr_1=="1" &                                  bi_sp_ai*0.5/(1-0.10625)<=SMA;
        gen con_pist_ri=(con_pist_in!=. & con_pist_in!=0);
	         
		joinby folioviv foliohog numren using "${mod}yd_anual.dta", unmatched(both) _merge(m);
		tab m;
		drop m;
        tabstat con_ims_in con_pims_in [w=factor_hog] , stat(sum) col(stat) f(%19.2f); 
        
		foreach x in  dtx_isr con_pims con_pist con_ims con_ist  { ;
			replace  `x'_in= 0 if `x'_in==. ;
			bys folioviv foliohog: egen double `x'_hh=sum(`x'_in) ;
			gen double `x'_pc = `x'_hh/hsize ;
		};

*----------------------------------------------------------------------------------------* 
               Generating Market Income plus Pensions and Gross Income
*----------------------------------------------------------------------------------------*; 
   egen double yp_pc=rowtotal(yn_pc dtx_isr_pc con_ims_pc con_ist_pc);
   
   	local trans_gob =
	   "
	    dtr_schp_pc 
		dtr_opor_pc
		dtr_cmpo_pc
		dtr_70ms_pc
		dtr_amyr_pc
		dtr_pali_pc
		dtr_empt_pc
		dtr_otrs_pc
		dtr_pcmx_pc
		"
		;
   egen double yg_pc = rowtotal(yp_pc `trans_gob');
   bys folioviv foliohog: egen double igrav_hh = sum(igrav);   
   
   drop contrato* sinco* clas_emp* reg_cont* com_fis* subordi* indepen* sarafore* pmedica* tiene_sueldo* ing* bi* inst* segpop ent ded* igrav* g* sueldo*
   n ocupa hijo* jefe* nieto* afiliado* paga* pr* sec tec bac col* inscr_1  con_spop_hh  trans espo* padre* nadie* max* no_hijos_h ;
   save "${mod}yp_anual.dta", replace;
 

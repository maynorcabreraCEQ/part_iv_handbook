*----------------------------------------------------------------------------------------------------**
*- CEQ Mex 2012: Consumable Income. 
*- Household survey: Encuesta Nacional de Ingreso y Gasto de los Hogares (ENIGH) 2012.
*- Author: Sandra Martinez-Aguilar and Enrique de la Rosa based on the previous 
*- work of John Scott, Enrique de la Rosa and Rodrigo Aranda.
*- Last Date of modification: March 15th, 2018.
*- Practical Information: This do-file builds Consumable Income, which based on Disposable Income.
*----------------------------------------------------------------------------------------------------*  

#delimit;

use "${Gasto_h}", clear;

keep if clave=="F007" | clave=="F008" | clave=="F009" | clave=="G009" |  clave=="R001" |  clave=="B002" |  clave=="B004" |  clave=="B005"  |  clave=="B006" ;

gen double gasol_hh=gasto_tri*4 if clave=="F007" | clave=="F008"; //spending on  Magna Gasoline (07)| Premium Gasoline(08);
gen double diese_hh=gasto_tri*4 if clave=="F009"; // spending onDiesel y Gas (09);
gen double gasLP_hh=gasto_tri*4 if clave=="G009"; //spending on Liquid Gas ; 
gen double elect_hh1=gasto_tri*2 if clave=="R001"; //spending on electricity;
gen double trans_hh1=gasto_tri*4 if (clave=="B002" |  clave=="B004" |  clave=="B005"  |  clave=="B006");
collapse (sum) gasol_hh diese_hh gasLP_hh elect_hh1 trans_hh1, by(folioviv foliohog);
gen inf_elect1_hh=(elect_hh1!=. & elect_hh1!=0);
tab inf_elect1_hh;
drop inf_elect1_hh;

tempfile subsidios;
save `subsidios', replace; 

*---------------SUBSIDIES---------------------------;
		use "${Gasto_p}", clear;
		gen double elect_hh2=gas_nm_tri*2 if clave=="R001"; 
		gen double trans_hh2=gasto_tri*4 if (clave=="B002" |  clave=="B004" |  clave=="B005"  |  clave=="B006");
		collapse (sum) elect_hh2 trans_hh2, by(folioviv foliohog) ;

		joinby folioviv foliohog using `subsidios', unmatched(both) _merge(m);
		tab m;
		drop m;
		egen double elect_hh=rowtotal(elect_hh1 elect_hh2);
		egen double trans_hh=rowtotal(trans_hh1 trans_hh2);
		drop elect_hh1 elect_hh2;
 
		joinby folioviv foliohog using "${mod}yd_anual.dta", unmatched(both) _merge(m);
		tab m;
		drop m;
		save `subsidios', replace; 
		use folioviv foliohog gasto_mon using "${Concen}", clear; 
		joinby folioviv foliohog using  `subsidios', unmatched(both) _merge(m);
		tab m;
		drop m;
		
		
	*---------------FUEL SUBSIDY: DIRECT ---------------------------;	
  
	    scalar s_gasol_2012=102931323031.331;
	
	   
	    egen double combus=rowtotal(gasol_hh diese_hh);
		sum combus [w=factor] if numren=="01";
        gen double sub_gaso_hh= s_gasol_2012*combus/r(sum)*0.41;
		tabstat  sub_* [w=factor_hog] if numren=="01", c(stats) stats(sum) f(%19.2f);
		
	*---------------FUEL SUBSIDY: INDIRECT EFFECT TROUGH TRANSPORTATION---------------------------;
        scalar s_transp_2012=71061829945;
		sum trans_hh [w=factor] if numren=="01";
        gen double sub_sitr_hh= s_transp_2012*trans_hh/r(sum)*0.41;
		tabstat  sub_* [w=factor_hog] if numren=="01", c(stats) stats(sum) f(%19.2f);
		
	*---------------FUEL SUBSIDY: INDIRECT EFFECT TROUGH GOODS AND SERVICES---------------------------;		
			scalar t_isub_bs_2012=48764147023.6059;
			replace trans_hh=0 if trans_hh==. ;
			replace   combus=0 if combus==. ;
			
			gen gasto_tot=gasto_mon*4-trans_hh-combus;
			sum gasto_tot [w=factor] if numren=="01";
			gen sub_sibs_hh=t_isub_bs_2012*gasto_tot/r(sum)*0.41;
			
	tabstat  sub_* [w=factor_hog] if numren=="01", c(stats) stats(sum) f(%19.2f);
   
	 egen double aux=rowtotal(sub_gaso_hh sub_sitr_hh sub_sibs_hh);
	 drop sub_gaso_hh trans_hh sub_sibs_hh;
	 gen double sub_gaso_hh=aux;
	 drop aux;
         tabstat  sub_* [w=factor_hog] if numren=="01", c(stats) stats(sum) f(%19.2f);
	
	*---------------SUBSIDY TO GAS LP---------------------------;	

		scalar s_gaslp_2012=25000000000; 
		
		sum gasLP_hh [w=factor] if numren=="01";
        gen double sub_gasl_hh = s_gaslp_2012*gasLP_hh/r(sum)*0.41;
		tabstat  sub_* [w=factor_hog] if numren=="01", c(stats) stats(sum) f(%19.2f);
	
		
	*---------------SUBSIDY TO ELECTRICITY---------------------------;	
	
		gen inf_elec_rh=(elect_hh!=. & elect_hh!=0);
		tab inf_elec_rh [w=factor_hog] if n==1;

		scalar s_elect_2012=77438411168;
		                    
        gen ent=substr(folioviv,1,2);
		gen double kw =0 ;
		replace kw= elect_hh/0.954 if ent=="01" ; //Aguascalientes;
		replace kw= elect_hh/1.200 if ent=="02" ; //Baja California;
		replace kw= elect_hh/1.135 if ent=="03" ; //Baja California Sur;
		replace kw= elect_hh/0.463 if ent=="04" ; //Campeche;
		replace kw= elect_hh/1.010 if ent=="05" ; //Coahuila;
		replace kw= elect_hh/0.917 if ent=="06" ; //Colima;
		replace kw= elect_hh/0.938 if ent=="07" ; //Chiapas;
		replace kw= elect_hh/0.976 if ent=="08" ; //Chihuahua;
		replace kw= elect_hh/1.827 if ent=="09" ; //Distrito Federal;
		replace kw= elect_hh/0.968 if ent=="10" ; //Durango;
		replace kw= elect_hh/1.000 if ent=="11" ; //Guanajuato;
		replace kw= elect_hh/0.924 if ent=="12" ; //Guerrero;
		replace kw= elect_hh/0.925 if ent=="13" ; //Hidalgo;
		replace kw= elect_hh/1.114 if ent=="14" ; //Jalisco;
		replace kw= elect_hh/0.939 if ent=="15" ; //México;
		replace kw= elect_hh/0.913 if ent=="16" ; //Michoacán; 
		replace kw= elect_hh/1.013 if ent=="17" ; //Morelos;
		replace kw= elect_hh/0.633 if ent=="18" ; //Nayarit;
		replace kw= elect_hh/1.049 if ent=="19" ; //Nuevo León;
		replace kw= elect_hh/0.920 if ent=="20" ; //Oaxaca;
		replace kw= elect_hh/0.963 if ent=="21" ; //Puebla;
		replace kw= elect_hh/0.996 if ent=="22" ; //Querétaro;
		replace kw= elect_hh/0.960 if ent=="23" ; //Quintana Roo;
		replace kw= elect_hh/0.956 if ent=="24" ; //San Luis Potosí;
		replace kw= elect_hh/0.968 if ent=="25" ; //Sinaloa;
		replace kw= elect_hh/1.052 if ent=="26" ; //Sonora;
		replace kw= elect_hh/1.155 if ent=="27" ; //Tabasco;
		replace kw= elect_hh/0.999 if ent=="28" ; //Tamaulipas;
		replace kw= elect_hh/0.979 if ent=="29" ; //Tlaxcala;
		replace kw= elect_hh/0.971 if ent=="30" ; //Veracruz;
		replace kw= elect_hh/0.988 if ent=="31" ; //Yucatán;
		replace kw= elect_hh/0.993 if ent=="32" ; //Zacatecas;
   
		gen double g_elect=0;
		replace g_elect=kw*3.615 if ent=="01" ; //Aguascalientes;
		replace g_elect=kw*3.525 if ent=="02" ; //Baja California;
		replace g_elect=kw*3.459 if ent=="03" ; //Baja California Sur;
		replace g_elect=kw*3.438 if ent=="04" ; //Campeche;
		replace g_elect=kw*3.517 if ent=="05" ; //Coahuila;
		replace g_elect=kw*3.534 if ent=="06" ; //Colima;
		replace g_elect=kw*3.579 if ent=="07" ; //Chiapas;
		replace g_elect=kw*3.471 if ent=="08" ; //Chihuahua;
		replace g_elect=kw*3.900 if ent=="09" ; //Distrito Federal;
		replace g_elect=kw*3.407 if ent=="10" ; //Durango;
		replace g_elect=kw*3.603 if ent=="11" ; //Guanajuato;
		replace g_elect=kw*3.502 if ent=="12" ; //Guerrero;
		replace g_elect=kw*3.622 if ent=="13" ; //Hidalgo;
		replace g_elect=kw*3.587 if ent=="14" ; //Jalisco;
		replace g_elect=kw*3.825 if ent=="15" ; //México;
		replace g_elect=kw*3.622 if ent=="16" ; //Michoacán; 
		replace g_elect=kw*3.705 if ent=="17" ; //Morelos;
		replace g_elect=kw*3.513 if ent=="18" ; //Nayarit;
		replace g_elect=kw*3.420 if ent=="19" ; //Nuevo León;
		replace g_elect=kw*3.593 if ent=="20" ; //Oaxaca;
		replace g_elect=kw*3.622 if ent=="21" ; //Puebla;
		replace g_elect=kw*3.619 if ent=="22" ; //Querétaro;
		replace g_elect=kw*3.486 if ent=="23" ; //Quintana Roo;
		replace g_elect=kw*3.621 if ent=="24" ; //San Luis Potosí;
		replace g_elect=kw*3.430 if ent=="25" ; //Sinaloa;
		replace g_elect=kw*3.566 if ent=="26" ; //Sonora;
		replace g_elect=kw*3.479 if ent=="27" ; //Tabasco;
		replace g_elect=kw*3.362 if ent=="28" ; //Tamaulipas;
		replace g_elect=kw*3.615 if ent=="29" ; //Tlaxcala;
		replace g_elect=kw*3.554 if ent=="30" ; //Veracruz;
		replace g_elect=kw*3.481 if ent=="31" ; //Yucatán;
		replace g_elect=kw*3.642 if ent=="32" ; //Zacatecas;

	    replace g_elect=0 if g_elect==.;
	    replace elect_hh=0 if elect_hh==.;		
		
		gen double sub_elec_hh=g_elect-elect_hh;
		replace sub_elec_hh=sub_elec_hh*0.92;
		*br foliohog folioviv g_elect kw elect_hh ent sub_elec_hh if sub_elec_hh<0;
		
		gen double sub_elec_pc=sub_elec_hh/hsize;		
		
		tempfile yc;
		save `yc', replace;
		
*---------------INDIRECTS TAXES ---------------------------;
	*Collecting the data;
		use "${Gasto_h}", clear;
		append using "${Gasto_p}";
		
		gen gasto_totalm =gasto_tri*4;
		gen gasto_totalnm=gas_nm_tri*4; 
		gen durablesm=gasto_tri if 
		(clave>="K026" & clave>="K036") |
		(clave>="K038" & clave>="L013") |
		(clave>="L017" & clave>="L018") |
		(clave>="M007" & clave>="M011") ;
		
		gen durablesnm=gas_nm_tri*4 if 
		(clave>="K026" & clave>="K036") |
		(clave>="K038" & clave>="L013") |
		(clave>="L017" & clave>="L018") |
		(clave>="M007" & clave>="M011") ;
		
		egen g_total_hh=rowtotal(gasto_totalm gasto_totalnm);
		egen g_durables_hh=rowtotal(durablesm durablesnm);

		collapse (sum) g_total_hh g_durables_hh, by(folioviv foliohog); 
		replace g_total_hh=0 if g_total_hh==.;
		replace g_durables_hh=0 if g_durables_hh==.;
		gen gasto_itx_hh=g_total_hh- g_durables_hh;
		
		tempfile gastoTot;
		save `gastoTot', replace;
		
		use "${Gasto_h}", clear;
		append using "${Gasto_p}";
		
	*We keep the monetary expenses;
		keep if tipo_gasto=="G1" | tipo_gasto=="G2";
		sort folioviv foliohog;
		tempfile impuestos;
		save `impuestos', replace;
		
	*We add a variable that allows to distinguish between rural and urban;
		use folioviv foliohog tam_loc ubica_geo using "${Concen}", clear;
	    gen rural=cond(tam_loc=="4",1,0); //4=Towns with less than 2500 inhabitants;
		sort folioviv foliohog;
		merge 1:m folioviv foliohog using `impuestos';
		tab _merge;
		drop _merge;
		save `impuestos', replace;
		
*---------------IVA (Value Added Tax)---------------------------;
		*IVA 2012: 579,987 millones;
		*Statutory rate:
				11% in border towns
				16% in non border towns
				;
		*expenditure variable is annualized;
		gen double gas_an=gasto_tri*4;
	
		*we drop the folowing placea of purchase :
			01 Mercado
			02 Tianguis o mercado sobre ruedas
			03 Vendedores ambulantes
			12 Loncherias, fondas, torterias , cocinas economicas, cenadurias
			17 Persona particular;
		
			drop if rural==1 & (lugar_comp=="01" | lugar_comp=="02" | lugar_comp=="03" | lugar_comp=="12" | lugar_comp=="17");

		*Identification of border towns http://www.adnpolitico.com/congreso/2013/10/30/en-que-ciudades-fronterizas-se-homologara-el-iva-a-16;
			gen ent=substr(folioviv,1,2);
			gen entmun=substr(ubica_geo,1,5);
			gen frontera=0;
			replace frontera=1 if ent=="02" | ent=="03" | ent=="23";
		*Sonora;
			replace frontera=1 if entmun=="26055" | 
			entmun=="26048" |
			entmun=="26070" |
			entmun=="26017" |
			entmun=="26004" |
			entmun=="26060" |
			entmun=="26043" |
			entmun=="26059" |
			entmun=="26019" |
			entmun=="26039" |
			entmun=="26002" ;
		*Chihuahua;
			replace frontera=1 if entmun=="08035" |
			entmun=="08005" |
			entmun=="08037" |
			entmun=="08028" |
			entmun=="08053" |
			entmun=="08052" |
			entmun=="08042" ;
		*Coahuila;
			replace frontera=1 if entmun=="05023" |
			entmun=="05002" |
			entmun=="05014" |
			entmun=="05025" |
			entmun=="05022" |
			entmun=="05012" |
			entmun=="05013";
		*Nuevo Leon municipio de anahuac;
			replace frontera=1 if entmun=="19005" ;
		*Tamaulipas;
			replace frontera=1 if entmun=="28027" |
			entmun=="228014" |
			entmun=="228024" |
			entmun=="228025" |
			entmun=="228007" |
			entmun=="228015" |
			entmun=="228032" |
			entmun=="228033" |
			entmun=="228022";

		*Chiapas;
			replace frontera=1 if entmun=="07065" |
			entmun=="07059" |
			entmun=="07114" |
			entmun=="07116" |
			entmun=="07115" |
			entmun=="07052" |
			entmun=="07041" |
			entmun=="07099" |
			entmun=="07034" |
			entmun=="07035" |
			entmun=="07006" |
			entmun=="07110" |
			entmun=="07053" |
			entmun=="07057" |
			entmun=="07089" |
			entmun=="07015" |
			entmun=="07105" |
			entmun=="07102" |
			entmun=="07055" |
			entmun=="07087" ;
		*Tabasco;
			replace frontera=1 if entmun=="27017" | entmun=="27001";
		*Campeche;
			replace frontera=1 if entmun=="04010" | entmun=="04011";                   		
			
		*we drop purchases outside the country;
			drop if lugar_comp=="08";        

		*The  VAT rate is calculated as the pre-tax expenditure multiplied by the VAT rate
		  The factor is as follows for the non border towns 1/(1+0.16)*0.16 and for border towns 1/(1+0.11)*0.11;			
		    gen double itx_iva_hh=0;	
	
		*Taxed food;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & ((clave>="A198" & clave<="A202") | (clave>="A243" & clave<="A247") | clave=="A069" | clave<="A071"); 
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & ((clave>="A198" & clave<="A202") | (clave>="A243" & clave<="A247") | clave=="A069" | clave<="A071");
		
		*Non-alcoholic beverages
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave=="A216" | clave=="A217"| (clave>="A220" & clave<="A221")); 
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & (clave=="A216" | clave=="A217"| (clave>="A220" & clave<="A221"));
			
		*Alcoholic beverages & Tobacco;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave>="A223" & clave<="A241") ;
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & (clave>="A223" & clave<="A241") ;
		
		*CLOTHING, FOOTWEAR AND ACCESSORIES;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 &  (clave>="H001" & clave<="H136");
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 &  (clave>="H001" & clave<="H136");
		
		*UTILITIES, MAINTENANCE AND COMBUSTIBLES SERVICES;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & ( (clave>="G005" & clave<="G012") | (clave>="G014" & clave<="G016") | (clave=="R001" | clave=="R003")  
			| (clave>="R005" & clave<="R011") | clave=="R013");
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & ( (clave>="G005" & clave<="G012") | (clave>="G014" & clave<="G016") | (clave=="R001" | clave=="R003") 
			| (clave>="R005" & clave<="R011") | clave=="R013");
			
		*CLEANING AND CARE OF THE HOUSE;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 &  (clave>="C001" & clave<="C024");
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 &  (clave>="C001" & clave<="C024");
			
		*GLASSWARE, TABLEWARE AND HOUSEHOLD UTENSILS ;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave>="I001" & clave<="I026");
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & (clave>="I001" & clave<="I026");
			
		*HOUSEHOLD AND HOUSING MAINTENANCE;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave>="K001" & clave<="K045");
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & (clave>="K001" & clave<="K045");
			
		*HEALTH CARE;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & ((clave=="J002" | clave=="J003" | clave=="J006"   | clave=="J015" | clave=="J019") 
			| (clave>="J011" & clave<="J012") | clave=="J040" | clave=="J041" | clave=="J043" |  clave=="J060" | (clave>="J065" & clave<="J071"));			
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & ((clave=="J002" | clave=="J003" | clave=="J006"   | clave=="J015" | clave=="J019") 
			| (clave>="J011" & clave<="J012") | clave=="J040" | clave=="J041" | clave=="J043" | clave=="J060" | (clave>="J066" & clave<="J071"));
			
		*COMMUNICATIONS;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave>="F001" & clave<="F006") ;
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & (clave>="F001" & clave<="F006") ;
			
		*FUEL, MAINTENANCE AND SERVICES FOR VEHICLES;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave>="F007" & clave<="F014") ;
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & (clave>="F007" & clave<="F014") ;
			
		*EDUCATION;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave=="E017" | clave=="E020" |clave=="E021" |clave=="E025" |clave=="E026"| clave=="E027" | clave=="E029" | clave=="E030" |  clave=="E032" | clave=="E033" |clave=="E034" ) 
			|    clave=="R009";
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & (clave=="E017" | clave=="E020" |clave=="E021" |clave=="E025" |clave=="E026"| clave=="E027" | clave=="E029" | clave=="E030" |  clave=="E032" | clave=="E033" |clave=="E034" ) 
			|    clave=="R009";
			
		*PERSONAL CARE;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave>="D001" & clave<="D026") ;
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & (clave>="D001" & clave<="D026") ;
		
		*OTHER EXPENDITURE;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & ((clave>="N001" & clave<="N005") | (clave>="N008" & clave<="N010") );
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & ((clave>="N001" & clave<="N005") | (clave>="N008" & clave<="N010") );

		*GIFTS;
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave=="T901" | clave=="T903"  | clave=="T904" 
			| (clave>="T906" & clave<="T910") |(clave>="T912" & clave<="T916") );
			replace itx_iva_hh=gas_an*0.099099099 if frontera==1 & (clave=="T901" | clave=="T903"  | clave=="T904" 
			| (clave>="T906" & clave<="T910") |(clave>="T912" & clave<="T916") );

        *LEISURE ITEMS
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave>="L001" & clave<="L028"); 
            replace itx_iva_hh=gas_an*0.099099099 if frontera==0 & (clave>="L001" & clave<="L028");

		*TRANSPORTATION 
			replace itx_iva_hh=gas_an*0.137931034 if frontera==0 & (clave>="M002" & clave<="M018"); 
            replace itx_iva_hh=gas_an*0.099099099 if frontera==0 & (clave>="M002" & clave<="M018");   
	        replace itx_iva_hh=itx_iva_hh*0.755;
			
*---------------EXCISE TAX: IEPS---------------------------;
          scalar iva =1/(1+0.16); 			
			           
		*Cigars;
			gen double itx_itab_hh=0;
			
				replace itx_itab_hh=gas_an*iva*(1/(1+1.6))*1.6    if  clave=="A239" |  clave=="A240";
		*Leaf and chopped Tobacco
				replace itx_itab_hh=gas_an*iva*(1/(1+0.304))*0.304 if  clave=="A241" ;
		
		*Alcoholic beverages more than 20 Degrees of alcohol;
			gen double itx_ibal_hh=0;
			
				replace itx_ibal_hh=gas_an*iva*(1/(1+0.53))*0.53 if  clave=="A223" | clave=="A225" | clave=="A229" 
				| clave=="A230" | clave=="A233" | clave=="A235" | clave=="A236" | clave=="A237" ;  

		*Alcoholic beverages 14 - 20 degrees of alcohol;
				replace itx_ibal_hh=gas_an*iva*(1/(1+0.3))*0.3 if  clave=="A226" | clave=="A227" ; 

		*Alcoholic beverages less than 14 degrees of alcohol;
				replace itx_ibal_hh=gas_an*iva*(1/(1+0.265))*0.265 if  clave=="A228" | clave=="A231" 
				| clave=="A232" | clave=="A234" | clave=="A238"; 

		*Beers;
			gen double  itx_icev_hh=0;
				replace itx_icev_hh=gas_an*iva*(1/(1+0.265))*0.265 if  clave=="A224";
		*Telecommunications service;

			gen double itx_icom_hh=0;
				replace itx_icom_hh=gas_an*iva*(1/(1+0.03))*0.03 if  (clave>="R005" & clave>="R011")
				| clave=="F004" | clave=="F006"; 
		*Energy drinks;
			gen double itx_iene_hh=0;
				replace itx_iene_hh=gas_an*iva*(1/(1+0.25))*0.25 if  (clave=="A221"); 

		collapse (sum) itx_* (mean) rural, by(folioviv foliohog) ;
	    joinby folioviv foliohog using `gastoTot', unmatched(both) _merge(m);
		tab m;
		drop m;
		
		joinby folioviv foliohog using `yc' , unmatched(both) _merge(m);
		tab m;
		drop m;		
		
        drop sub_elec_pc;
        local sub "sub_gaso sub_gasl sub_elec";
		local itx "itx_iva itx_itab itx_ibal itx_icev itx_icom itx_iene";		
		bys folioviv foliohog: egen double yd_hh=sum(yd_pc);		
		
		foreach x in  `itx' {;
		replace `x'_hh=0 if `x'_hh==. ;
		replace `x'_hh=`x'_hh/gasto_itx_hh*yd_hh;
		gen     `x'_rh=(`x'_hh!=. & `x'_hh!=0);
		};
			
		foreach x in  `sub'  `itx' {;
		replace `x'_hh=0 if `x'_hh==. ;
		gen double `x'_pc=`x'_hh/hsize;		
		};
		
		
*----------------------------------------------------------------------------------------* 
                               Generating Consumable Income
*----------------------------------------------------------------------------------------*; 
		gen double yc_pc= yd_pc + sub_gaso_pc + sub_gasl_pc + sub_elec_pc
		                  -itx_iva_pc   - itx_itab_pc - itx_ibal_pc 
						  - itx_icev_pc - itx_icom_pc - itx_iene_pc;
	
	
	*cleaning dataset
	   drop g_total_hh  g_durables_hh   gasto_itx_hh gasol_hh diese_hh  gasLP_hh   elect_hh  combus  n ent kw g_elect rural   inf_elec_rh ; 		  
		
		gen sub_gasl_rh=(sub_gasl_pc!=. & sub_gasl_pc!=0);
		gen sub_elec_rh=(sub_elec_pc!=. & sub_elec_pc!=0);
		gen sub_gaso_rh=(sub_gaso_pc!=. & sub_gaso_pc!=0);
		
				tabstat  sub_gaso_pc sub_gasl_pc [w=factor_hog] , c(stats) stats(sum) f(%19.2f);
                tabstat itx_iva_pc [w=factor], stat(sum) format(%15.0fc) col(stat);
				
       drop trans_hh2 trans_hh1 gasto_tot gasto_mon sub_sitr_hh ;
 save  "${mod}yc_anual.dta", replace;

*----------------------------------------------------------------------------------------------------*
*- CEQ Mex 2012: Final Income. 
*- Household survey: Encuesta Nacional de Ingreso y Gasto de los Hogares (ENIGH) 2012.
*- Author: Sandra Martinez-Aguilar and Enrique de la Rosa based on the previous work of John Scott, Enrique de la Rosa and Rodrigo Aranda.
*- Last Date of modification: March 15th, 2018.
*- Practical Information: This do-file builds Market Income , which based on Market Income plus Pensions.
*----------------------------------------------------------------------------------------------------*
	#delimit;

  use "${mod}yp_anual.dta", clear;
  
 *----------------------------------------------------------------------------------------* 
               Generating Market Income
*----------------------------------------------------------------------------------------*; 
  
  gen double ym_pc=yp_pc-pen_con_pc+con_pims_pc +con_pist_pc;
   
  save "${mod}ym_anual.dta", replace;

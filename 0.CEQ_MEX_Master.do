*----------------------------------------------------------------------------------------------------*
*- Master do file CEQ Mexico 2012
*- Household survey: Encuesta Nacional de Ingreso y Gasto de los Hogares (ENIGH) 2012
*- Authors: Sandra Martinez-Aguilar and Enrique de la Rosa based on the previous 
*- work of John Scott, Enrique de la Rosa and Rodrigo Aranda.
*- Last Date of modification: March 15th, 2018.
*- Practical Information on how to use this do file:

/*
a.- This do file is designed to facilitate of the following 8 do files: 
      1.yn_nor.do  
      2.yd_nor.do 
      3.yc_nor.do
      4.yf_nor.do  
      5.yp_nor.do 
      6.ym_nor.do 
      7.TargetOportunidades.do
      8.Infrastructure&Labels.do 


b.- The aforementioned Do-files will be used to construct the Harmonized Dataset for Mexico's CEQ Assessment 2012. 
c.- This do-file sets all the directories to be used for running each one of 8 do-files by using 
    globals in the form "${name of the global}". The advantage of using this is that facilitate 
  collaborative work. Anyone can easily run all the do files whether on IOS or windows by only 
  changing the directory in this do file.. 
*/
**----------------------------------------------------------------------------------------------------*
clear all
global clear
set more off

*Setting directories
********************************************************************************************
global path  "/Users/SMA/Dropbox/Work/Nora/CEQ Assesments/Review/CEQ MEX IN PROGRESS/Deliverables Indepentend Study/SMA-EDLR/2012/"
global enigh "${path}3. DATA/Original/RAW/ENIGH/" 
global mod   "${path}3. DATA/Original/MOD/" 		//*main working folder where the processed data sets are stored*/
global do    "${path}4. DO FILES/Original/"
global log_path "${do}Log" 
global Trabajos "${enigh}Trabajos.dta" 
global Ingresos "${enigh}Ingresos.dta" 
global Pobla12  "${enigh}Pobla12.dta"
global Concen   "${enigh}Concen.dta"
global Gasto_h  "${enigh}G_hogar.dta"
global Gasto_p  "${enigh}G_person.dta"
global vivienda "${enigh}Vivienda.dta"
global OPOR  	"${mod}target_opor12.dta"


* This part of the do file will run 8 do files one by one
  do "${do}1.yn_nor.do"  
  do "${do}2.yd_nor.do" 
  do "${do}3.yc_nor.do"
  do "${do}4.yf_nor.do"  
  do "${do}5.yp_nor.do" 
  do "${do}6.ym_nor.do" 
  do "${do}7.TargetOportunidades.do"
  do "${do}8.Infrastructure&Labels.do" 
 


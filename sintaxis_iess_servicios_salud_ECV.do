

*===================================================================================*
* Sintaxis para estimar el número de afiliados y beneficiarios potenciales			    *
* atendidos en establecimientos de Salud del IESS con el uso de la 					        *
* Encuesta de Condiciones de Vida 2013 - 2014									                    	*
*																	    			                                        *
*===================================================================================*
* Elaborado por:																	
* VELASCO, CARLOS
* 
* Modificado por:
* VELASCO, CARLOS														    
*===================================================================================*

set more off

/* Uso de la ENSANUT

Variables a usarse:

pse01: pse01. es afiliado o aporta al
pd06: parentesco con el jefe(a) de hogar, serviría para identificar a los potenciales beneficiarios.
ps08: ps08. a dónde acudió por la enfermedad
ps29: ps29. dónde estuvo hospitalizado
ps41: ps41. a dónde acudió para hacerse chequear
ps57: ps57. dónde estuvo hospitalizado la última vez
*/

global dir "C:\Users\GILDA GUTIERREZ\Desktop\An_Encuestas\Bases_trabajo_ECV\Bases"
global dir1 "C:\Users\GILDA GUTIERREZ\Desktop\An_Encuestas\Bases_trabajo_ECV\Resultados"
cd "${dir}

use ECV6R_PERSONAS.dta, clear


/*
***DPA de Provincia y Cantón a partir del identificador del Hogar***

replace identif_hog= subinstr(identif_hog," ","",.)
gen dpa_prov= substr(identif_hog,1,2)
merge m:m dpa_prov using "DPA_Parroquia_2017.dta", assert(match) keep(match) keepusing(dpa_desprov) nogen

gen dpa_canton= substr(identif_hog,1,4)
merge m:m dpa_canton using "DPA_Parroquia_2017.dta", assert(match) keep(match) keepusing(dpa_descan) nogen


label var dpa_prov "DPA provincia"
label var dpa_canton "DPA cantón"
label var dpa_desprov "Provincia"
label var dpa_descan "Cantón"

save ECV6R_PERSONAS.dta, replace

*/

/*Persona con afiliación a cualquiera de los 3 seguros del IESS:
General, Voluntario o Social Campesino

Los 3 seguros tienen derecho a usar los establecimientos del Seguro General de Salud*/

gen iess_af=3 if ps72a==3 | ps72b==3
replace iess_af=2 if ps72a==2 | ps72b==2
replace iess_af=1 if ps72a==1 | ps72b==1

label define iess_af 1"Seguro General" 2"Seguro Voluntario" 3"Seguro Campesino" 99"Sin seguro IESS"
label values iess_af iess_af

replace iess_af=99 if iess_af==.
label var iess_af "Afiliados al IESS: Seguro General, Voluntario o Social Campesino"


***Jefes de hogar y Conyuges afiliados al IESS***

gen iess_jc=1 if iess_af<4 &(pd04==1|pd04==2)
replace iess_jc=0 if iess_jc==.
label var iess_jc "Jefes de hogar y Conyuges afiliados al IESS: Seguro General, Voluntario o Social Campesino"


***Hogar con jefe de hogar o conyuge que tiene seguro IESS***
egen iess_hog=sum(iess_jc), by(identif_hog)
replace iess_hog=1 if iess_hog>0
replace iess_hog=0 if iess_hog==.
label var iess_hog "Hogares con al menos un Jefe de hogar o Cónyuge afiliado al IESS"

***Se adopta el tipo de seguro del jefe de hogar o conyuge***
***Prevalecen por orden de prioridad:
***1. Seguro General
***2. Seguro Voluntario
***3. Seguro Campesino

egen iess_hog1=min(iess_af) if iess_hog==1, by(identif_hog)
label var iess_hog "Categoría del seguro de Jefe de hogar o Cónyuge "
label var iess_hog1 "Tipo de seguro que prevalece en el hogar"

*** Potenciales Beneficiarios: conyuges e hijos menores de 18 años***


gen iess_benf=2 if (iess_af>3 & iess_hog1==1)&(pd04==2|(pd04==3&edad<18))
replace iess_benf=4 if (iess_af>3 & iess_hog1==2)&(pd04==2|(pd04==3&edad<18))
replace iess_benf=6 if (iess_af>3 & iess_hog1==3)&(pd04==2|(pd04==3&edad<18))
replace iess_benf=99 if iess_benf==.

label var iess_benf "Conyuges o Hijos menores de 18 potenciales beneficiarios del Seguro de Salud"

label define iess_benf  2"Beneficiario Seguro General" 4"Beneficiario Seguro Voluntario" 6"Beneficiario Seguro Campesino" 99"N/A", replace
label values iess_benf iess_benf

***Afiliados y beneficiarios***

replace iess_af=5 if iess_af==3
replace iess_af=3 if iess_af==2


gen af_benf_iess=iess_benf
replace af_benf_iess=iess_af if iess_af!=99
label var af_benf_iess "Suma de Afiliados y potenciales beneficiarios del Seguro de Salud"

label define af_benf_iess 1"Seguro General" 2"Beneficiario Seguro General" 3"Seguro Voluntario" 4"Beneficiario Seguro Voluntario" 5"Seguro Campesino" 6"Beneficiario Seguro Campesino" 99"Sin seguro IESS", replace
label values af_benf_iess af_benf_iess

replace iess_af=2 if iess_af==3
replace iess_af=3 if iess_af==5

***Población enferma***
gen enf=1 if (ps34==1|ps45==1)|(ps57==1|ps61<3)|(ps63==1|pf07a==1)
replace enf=0 if enf==.
label var enf "Tuvo alguna enfermedad o se realizó controles preventivos"

label define enf 1"SI" 0"NO"
label values enf enf

***ATENCIONES POR ESTABLECIMIENTO DE SALUD***

***No se atendió***
gen atencion= 1 if (ps36<6 | ps47<6) | (ps61<3 |ps63==1 | pf07a==1)
replace atencion=0 if atencion==.
label var atencion "Recibió atención SI(1) NO(0)"

label define atencion 1"SI" 0"NO"
label values atencion atencion


gen est_s=7 if atencion==0

***No le atendió un profesional de salud***
***Se consideran profesionales de la salud: Médico, Ginecólogo Dentista, Psicólogo, Obstetriz y Enfermera o auxiliar***
gen prof_s=1 if atencion==1 &((ps36==2|ps36==3)| (ps47==2|ps47==3) | (ps64<5| pf11<4|pf11==5))
replace est_s=6 if (prof_s==. & atencion==1)
drop prof_s

***Lugar donde fue atendido***
***PRIVADO***

/*En las categorías: Consultorio particular, Botica o Farmacia, Casa o Domicilio y Otro, solamente se consideran 
las atenciones realizadas por: Médico, Ginecólogo Dentista, Psicólogo, Obsteriz y Enfermera o auxiliar*/

#delimit ;
replace est_s=5 if ps38==9|ps49==9|ps65==9|pf09==9|
ps38==10|ps49==10|ps65==10|pf09==10|
((ps36==2|ps36==3)&(ps38>10))|						
((ps47==2|ps47==3)&(ps49>10))|						
(((ps64==1|ps64==2)|(ps64==3|ps64==4))&(ps65>10))|	
(((pf11==1|pf11==2)|(pf11==3|pf11==5))&(pf09>10));		
#delimit cr


***MUNICIPAL / PROVINCIAL***
replace est_s=4 if ps38==8|ps49==8|ps65==8|pf09==8

***ISSFA/ISSPOL***
replace est_s=3 if ps38==3|ps49==3|ps65==3|pf09==3

***MSP***
#delimit ;
replace est_s=2 if ps38==1|ps49==1|ps65==1|pf09==1|
ps38==4|ps49==4|ps65==4|pf09==4|
ps38==7|ps49==7|ps65==7|pf09==7;
#delimit cr

***IESS***
#delimit ;
replace est_s=1 if ps38==2|ps49==2|ps65==2|pf09==2|
ps38==5|ps49==5|ps65==5|pf09==5|
ps38==6|ps49==6|ps65==6|pf09==6;
#delimit cr


***No sabe / No responde***
replace est_s=98 if (ps36==. & ps47==.) & (ps61==. & ps63==.) &(ps64==. & pf07a==.)



***No requirió atención en salud***
replace est_s=99 if enf==0


label var est_s "Establecimiento de salud donde fue atendido"
label define est_s 1"IESS" 2"MSP" 3"ISSFA/ISSPOL" 4"Municipal/Provincial" 5"Privado" 6"No le atendió profesional de salud" 7"No se atendió" 98"No sabe/No responde" 99"No requirió atención en salud", replace
label values est_s est_s


/*
***Para verificar el cruce de la información***

gen cuenta=1
collapse (count) cuenta, by(atencion af_benf_iess enf est_s ps36 ps38 ps47 ps49 ps61 ps63 ps64 ps65 pf06a pf07a pf09 pf11)

export excel using "revisar_sitios_salud.xlsx",  firstrow(variables) replace */



***CUADROS***

*Afiliados

cd "${dir1}
tabout af_benf_iess [iw=fexp] using afiliacion.txt if af_benf_iess<7 , cells (freq col) replace

*Base agregada para generación de tabla dinámica en Excel
gen cuenta=1
collapse (count) poblacion=cuenta [iw=fexp], by(dpa_prov dpa_desprov dpa_canton dpa_descan af_benf_iess enf atencion est_s)

export excel using "collapse_iess_ecv2014.xlsx",  firstrow(variables) replace


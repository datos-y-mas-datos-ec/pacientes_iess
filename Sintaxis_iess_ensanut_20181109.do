

*===================================================================================*
* Sintaxis para estimar el número de afiliados y beneficiarios potenciales			*
* atendidos en establecimientos de Salud del IESS con el uso de la 					*
* Encuesta Nacional de Salud y Nutrición											*
*																	    			*
* Fecha de elaboración:        	8 de noviembre de 2018				 				*
* Fecha Última modificación:   	9 de noviembre de 2019								*
* Fecha de entrega:				9 de noviembre de 2019  	 			   			*
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

global dir "C:\Users\GILDA GUTIERREZ\Desktop\An_Encuestas\Bases_trabajo"
cd "${dir}

use ensanut_cnecs.dta, clear

***Identificador de hogar***

tostring(ciudad), gen (dpa_parr)
gen lparr=strlen(dpa_parr)
replace dpa_parr="0"+dpa_parr if lparr==5
drop lparr
label var dpa_parr "DPA Parroquia - ENSANUT 2012"

gen dpa_prov=substr(dpa_parr,1,2)
label var dpa_prov "DPA Provincia - ENSANUT 2012"

gen dpa_cant=substr(dpa_parr,1,4)
label var dpa_cant "DPA Canton - ENSANUT 2012"

tostring(zona), gen (dpa_zona)
gen lzona=strlen(dpa_zona)
replace dpa_zona="00"+dpa_zona if lzona==1
replace dpa_zona="0"+dpa_zona if lzona==2
drop lzona
label var dpa_zona "DPA Zona - ENSANUT 2012"

tostring(sector), gen (dpa_sector)
gen lsector=strlen(dpa_sector)
replace dpa_sector="00"+dpa_sector if lsector==1
replace dpa_sector="0"+dpa_sector if lsector==2
drop lsector
label var dpa_sector "DPA Sector - ENSANUT 2012"

tostring(vivienda), gen (viv)
gen lviv=strlen(viv)
replace viv="0"+viv if lviv==1
drop lviv
label var viv "Vivienda - ENSANUT 2012"

tostring(hogar), gen (hog)
gen lhog=strlen(hog)
replace hog="0"+hog if lhog==1
drop lhog
label var hog "Hogar - ENSANUT 2012"

gen idhogar= dpa_parr+dpa_zona+dpa_sector+viv+hog
label var idhogar "Identificación del hogar - ENSANUT 2012"

/*Persona con afiliación a cualquiera de los 3 seguros del IESS:
General, Voluntario o Social Campesino

Los 3 seguros tienen derecho a usar los establecimientos del Seguro General de Salud*/

gen iess_af=1 if pse01<4
replace iess_af=0 if iess_af==.
label var iess_af "Afiliados al IESS: Seguro General, Voluntario o Social Campesino"


***Jefes de hogar y Conyuges afiliados al IESS***

gen iess_jc=1 if pse01<4 &(pd06==1|pd06==2)
replace iess_jc=0 if iess_jc==.
label var iess_jc "Jefes de hogar y Conyuges afiliados al IESS: Seguro General, Voluntario o Social Campesino"


***Hogar con jefe de hogar o conyuge que tiene seguro IESS***

egen iess_hog=sum(iess_jc), by(idhogar)
replace iess_hog=1 if iess_hog>0
replace iess_hog=0 if iess_hog==.
label var iess_hog "Hogares con al menos un Jefe de hogar o Conyuge afiliado al IESS"

*** Potenciales Beneficiarios: conyuges e hijos menores de 18 años***
gen iess_benf=1 if (iess_af!=1 & iess_hog==1)&(pd06==2|(pd06==3&pd03<18))
replace iess_benf=0 if iess_benf==.
label var iess_benf "Conyuges o Hijos menores de 18 potenciales beneficiarios del Seguro de Salud"

***Suma de afiliados y beneficiarios***
gen af_benf_iess=iess_af+iess_benf
label var af_benf_iess "Suma de Afiliados y potenciales beneficiarios del Seguro de Salud"


***PACIENTES ATENDIDOS EN ESTABLECIMIENTOS DEL IESS***

***Consulta Externa***

gen ce=1 if (ps08==5|ps08==6)|(ps41==5&ps41==6)
replace ce=0 if ce==.
label var ce "Personas atendidas en Consulta Externa"

***Hospitalización***
gen ho=1 if (ps29==2 | ps57==2)
replace ho=0 if ho==.
label var ho "Personas atendidas en Hospitalización"

***Afiliados y beneficiarios que recibieron al menos una (1) atención en un establecimiento del IESS***
gen pac_at=1 if (ho==1|ce==1)
replace pac_at=0 if pac_at==.
label var pac_at "Personas atendidas en un establecimiento del IESS"


***AFILIADOS Y BENEFICIARIOS IESS ATENDIDOS EN ESTABLECIMIENTOS DEL IESS***

***IESS - Consulta Externa***

gen ce_iess=1 if af_benf_iess==1 & ((ps08==5|ps08==6)|(ps41==5&ps41==6))
replace ce_iess=0 if ce_iess==.
label var ce_iess "Afiliados y Beneficiarios IESS atendidos en Consulta Externa"

***IESS - Hospitalización***
gen ho_iess=1 if af_benf_iess==1 & (ps29==2 | ps57==2)
replace ho_iess=0 if ho_iess==.
label var ho_iess "Afiliados y Beneficiarios IESS atendidos en Hospitalización"

***Afiliados y beneficiarios que recibieron al menos una (1) atención en un establecimiento del IESS***
gen pac_iess=1 if af_benf_iess==1 & (ho==1|ce==1)
replace pac_iess=0 if pac_iess==.
label var pac_iess "Afiliados y Beneficiarios IESS atendidos en un establecimiento del IESS"

***TABLAS***


***Instalar tabout***
*ssc install tabout

*Afiliados
tabout dpa_prov pse01 [iw=pw] if iess_af==1 using af.txt , cells (freq row) replace

*Beneficiarios
tabout dpa_prov iess_benf [iw=pw] if iess_benf==1 using benef.txt , cells (freq row) replace

*Personas atendidas por afiliación al IESS y servicio
tabout ce af_benf_iess [iw=pw] using ce.txt , cells (freq row) replace
tabout ho af_benf_iess [iw=pw] using ho.txt , cells (freq row) replace
tabout pac_at af_benf_iess [iw=pw] using pa_at.txt , cells (freq row) replace

*Afiliados y beneficiarios atendidos
tabout dpa_prov ce_iess [iw=pw] using ce_iess.txt , replace
tabout dpa_prov ho_iess [iw=pw] using ho_iess.txt , replace
tabout dpa_prov pac_iess [iw=pw] using pa_at_iess.txt , replace

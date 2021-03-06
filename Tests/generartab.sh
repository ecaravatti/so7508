#!/bin/bash
#Script para generar lotes de prueba
#para archivos <periodo>.<area>
#
#$1 = periodo
#$2 = area

numRegistro=0

while [ $numRegistro -le 80 ]
do
	floor=100000
	range=999999

	#Generar codigo de area (6 digitos)
	codigoArea=0
	while [ $codigoArea -le $floor ]
	do
  		codigoArea=$[$RANDOM * 35] 
  		let "codigoArea %= $range"  
	done

	#Generar id (6 digitos)
	idConcepto=0
	while [ $idConcepto -le $floor ]
	do
  		idConcepto=$[$RANDOM * 35] 
  		let "idConcepto %= $range"  
	done
	
	#Generar max x comprobante(nnnnnn.dd)
	range=100
	floor=10
	montoEntero=$RANDOM
	
	montoDecimal=0
	while [ $montoDecimal -le $floor ]
	do
		montoDecimal=$RANDOM
		let "montoDecimal %= $range"
	done
	maxComprobante="${montoEntero}.${montoDecimal}"
	
	#Generar max x concepto(nnnnnn.dd)
	montoEntero=$RANDOM

	montoDecimal=0
	while [ $montoDecimal -le $floor ]
	do
		montoDecimal=$RANDOM
		let "montoDecimal %= $range"
	done
	maxConcepto="${montoEntero}.${montoDecimal}"

	#Generar limite repeticiones (5 digitos)
	floor=10000
	range=99999
	limRepeticiones=0
	while [ $limRepeticiones -le $floor ]
	do
  		limRepeticiones=$[$RANDOM * 4] 
  		let "limRepeticiones %= $range"  
	done
	
	echo "$codigoArea;$idConcepto;$maxComprobante;$maxConcepto;$limRepeticiones" >> cxa.tab
	
	let "numRegistro++";
done 

echo "Creado archivo cxa.tab"
exit 0

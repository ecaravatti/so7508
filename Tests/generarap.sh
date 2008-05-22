#!/bin/bash
#Script para generar lotes de prueba
#para archivos <area>.<periodo>
#
#$1 = area
#$2 = periodo

if [ $# != 2 ]
then
	echo "Uso: ./generarap.sh <area> <periodo>"
	exit 1
fi

numRegistro=0
nombreArchivo="${1}.${2}"
str0=$$

while [ $numRegistro -le 25 ]
do
	range=32
	floor=100000	
	
	#Generar dia (2 digitos entre 00 y 31)
	dia=$RANDOM
	let "dia %= $range"
	if [ $dia -lt 10 ]
	then
		dia="0${dia}"
	fi

	#Generar id (6 digitos)
	range=999999
	idConcepto=0
	while [ $idConcepto -le $floor ]
	do
  		idConcepto=$[$RANDOM * 35] 
  		let "idConcepto %= $range"  
	done
	
	#Generar comprobante (string aleatorio - EDIT: Tifi me pidio que sean numeros)
	#range=10
	#str1=$( echo "str0" | md5sum | md5sum )
	#inicial=$RANDOM
	#final=$RANDOM
	#let "inicial %= $range"
	#let "final %= $range"
	#comprobante="${str1:$inicial:$final}"
	#str0=$comprobante
	comprobante=$RANDOM

	#Generar importe(nnnnnn.dd)
	range=100
	floor=10
	montoEntero=$RANDOM
	montoDecimal=0
	while [ $montoDecimal -le $floor ]
	do
		montoDecimal=$RANDOM
		let "montoDecimal %= $range"	
	done
	importe="${montoEntero}.${montoDecimal}"
	
	echo "$dia;$comprobante;$idConcepto;$importe" >> "$nombreArchivo"
	
	let "numRegistro++";
done 

echo "Creado archivo $nombreArchivo"
exit 0

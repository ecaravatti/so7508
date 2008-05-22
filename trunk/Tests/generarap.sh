#!/bin/bash
#Script para generar lotes de prueba
#para archivos <periodo>.<area>
#
#$1 = area
#$2 = periodo

if [ $# != 2 ]
then
	echo "Uso: ./generarap.sh <periodo> <area>"
	exit 1
fi

numRegistro=0
floor=100000
range=0
nombreArchivo="${1}.${2}"
str0=$$

while [ $numRegistro -le 25 ]
do
	#Generar dia (2 digitos)
	range=100	
	dia=$RANDOM
	let "dia %= $range"

	#Generar id (6 digitos)
	range=999999
	idConcepto=0
	while [ "$idConcepto" -le $floor ]
	do
  		idConcepto=$[$RANDOM * 35] 
  		let "idConcepto %= $range"  
	done
	
	#Generar comprobante (string aleatorio)
	range=10
	str1=$( echo "str0" | md5sum | md5sum )
	inicial=$RANDOM
	final=$RANDOM
	let "inicial %= $range"
	let "final %= $range"
	comprobante="${str1:$inicial:$final}"
	str0=$comprobante

	#Generar importe(nnnnnn.dd)
	range=100
	montoEntero=$RANDOM
	montoDecimal=$RANDOM
	let "montoDecimal %= $range"
	importe="${montoEntero}.${montoDecimal}"
	
	echo "$dia;$comprobante;$idConcepto;$importe" >> "$nombreArchivo"
	
	let "numRegistro++";
done 

echo "Creado archivo $nombreArchivo"
exit 0

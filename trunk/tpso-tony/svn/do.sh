__FNC_RET_VAL__=0

############################################################
# Calcula un numero en punto flotante(3 decimales) aleatorio
#
# Args: $1 -> MAX , $2 -> MIN
#
# Return : double
doublerand(){
rand $1 $2
n=${__FNC_RET_VAL__}
rand 1000 0
__FNC_RET_VAL__=$n.${__FNC_RET_VAL__}
}

############################################################
# Calcula un numero aleatorio
#
# Args: $1 -> MAX , $2 -> MIN
#
# Return : rand
rand(){
w=$(hexdump -n4 -e\"%u\" /dev/random)
let w=($w%$1)+$2
__FNC_RET_VAL__=$w
}

############################################################
# Devuelve de manera aleatorio alguna alicutoa
#
# Args:
#
# Return : alicuota
getAlicuota(){
rand 3 1

if [ ${__FNC_RET_VAL__} -eq 3 ]
then	
	__FNC_RET_VAL__=21
elif [ ${__FNC_RET_VAL__} -eq 2 ]
then
	__FNC_RET_VAL__=10.5	
else
	__FNC_RET_VAL__=27
fi
}

############################################################
# Script:
#
# Args: $1 Maximo valor a poner en el campo de importe neto gravado
# 	$2 Minimo valor a poner en el campo de importe neto gravado
#	$3 Cantidad de registros a crear
#	$4 Fecha a poner el campo Fecha
#	$5 Nombre,CUIT,Tipo a completar en cada campo
#
# Return : temp.datos cargado con registros segun lo indicado arriba


# Arreglo el problema del separador decimal en awk
t_LANG=$LANG
LANG=C

count=1
fecha=$4
for i in $(seq 1 $3)
do
	ocount=$(echo $count | awk '{printf("%05d",$0)}')
	rand 3 1
	if [ ${__FNC_RET_VAL__} -eq 3 ]
	then
		doublerand $1 $2
		n1=${__FNC_RET_VAL__}
		doublerand $1 $2
		n2=${__FNC_RET_VAL__}
		doublerand $1 $2
		n3=${__FNC_RET_VAL__}
		doublerand $1 $2
		excentos=${__FNC_RET_VAL__}
		getAlicuota
		ali1=${__FNC_RET_VAL__}
		getAlicuota
		ali2=${__FNC_RET_VAL__}
		getAlicuota
		ali3=${__FNC_RET_VAL__}
		imp1=$(echo "scale=3;$ali1*$n1/100" | bc )
		imp2=$(echo "scale=3;$ali2*$n2/100" | bc )
		imp3=$(echo "scale=3;$ali3*$n3/100" | bc )
		total=$(echo "scale=3;$n1+$imp1+$n2+$imp2+$n3+$imp3+$excentos" | bc)
		
		echo "$5,$ocount,$fecha,$n1,$ali1,$imp1,$n2,$ali2,$imp2,$n3,$ali3,$imp3,$excentos,$total" >> temp.datos
	elif [ $? -eq 2 ]
	then
		doublerand $1 $2
		n1=${__FNC_RET_VAL__}
		doublerand $1 $2
		n2=${__FNC_RET_VAL__}
		doublerand $1 $2
		excentos=${__FNC_RET_VAL__}
		getAlicuota
		ali1=${__FNC_RET_VAL__}
		getAlicuota
		ali2=${__FNC_RET_VAL__}
		imp1=$(echo "scale=3;$ali1*$n1/100" | bc )
		imp2=$(echo "scale=3;$ali2*$n2/100" | bc )
		total=$(echo "scale=3;$n1+$imp1+$n2+$imp2+$excentos" | bc )		

		echo "scale=3;$5,$ocount,$fecha,$n1,$ali1,$imp1,$n2,$ali2,$imp2,$excentos,$total" >> temp.datos
	else
		doublerand $1 $2
		n1=${__FNC_RET_VAL__}
		doublerand $1 $2
		excentos=${__FNC_RET_VAL__}
		getAlicuota
		ali1=${__FNC_RET_VAL__}
		imp1=$(echo "scale=3;$ali1*$n1/100" | bc )
		total=$(echo "scale=3;$n1+$imp1+$excentos" | bc)

		echo "$5,$ocount,$fecha,$n1,$ali1,$imp1,$excentos,$total" >> temp.datos
	fi
	let count=$count+1	
done

LANG=$t_LANG

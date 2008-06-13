#! /usr/bin/bash

#! /bin/bash

###############################################################
#Inicializacion
# VALORES POR DEFECTO

NCORRIDA_INICIAL=1000
MAX_SEQ=99999

# VARIABLE PARA RETORNO DE FUNCIONES
__FCN_RETURN_VALUE__=0

###############################################################
# Crea el archivo de iva del registro dado
#
# Args: $1 -> registro a utilizar para crear archivo de iva
# 	$2 -> periodo
# 	$3 -> CAE
#
crearIvaC(){
cuit=$(echo $1 | cut -f 1 -d,)
tipo=$(echo $1 | cut -f 3 -d,)
fecha=$(echo $1 | cut -f 5 -d, | sed -n 's/\([0-9][0-9]\)-\([0-9][0-9]\)-\([0-9]\{4\}\)/\1\/\2\/\3/p')

ncampos=$(echo $1 | awk -F, '{print NF}')

# Arreglo el problema del separador decimal en awk
t_LANG=$LANG
LANG=C

if [ $ncampos -eq 16 ]
then
	# Existen los 3 campos de impuestos
	total=$(echo $1 | awk -F, '{print $15+($6*$7/100)+$6+($9*$10/100)+$9+($12*$13/100)+$12}' )
	exentos=$(echo $1 | cut -f 15 -d,)
	neto=$(echo $1 | awk -F, '{print $6+$9+$12}' )
	impuesto=$(echo $1 | awk -F, '{print ($6*$7/100)+($9*$10/100)+($12*$13/100)}' )
elif [ $ncampos -eq 13 ]
then
	# Existen 2 campos de impuestos
	total=$(echo $1 | awk -F, '{print $12+($6*$7/100)+$6+($9*$10/100)+$9}')
	exentos=$(echo $1 | cut -f 12 -d,)
	neto=$(echo $1 | awk -F, '{print $6+$9}' )
	impuesto=$(echo $1 | awk -F, '{print ($6*$7/100)+($9*$10/100)}' )
else
	# Existen solo el campo requerido
	total=$(echo $1 | awk -F, '{print $9+($6*$7/100)+$6}')
	exentos=$(echo $1 | cut -f 9 -d,)
	neto=$(echo $1 | awk -F, '{print $6}' )
	impuesto=$(echo $1 | awk -F, '{print ($6*$7/100)}' )
fi
# Reparo los cambios
LANG=$t_LANG

echo $cuit,$3,$tipo,$fecha,$total,$exentos,$neto,$impuesto >> $GRUPO/ivaC/$2
}

###############################################################
# Actualiza la tabla de comprobantes con los nuevos numeros de secuencia
#
actualizarComprobantes(){
if [ -f $GRUPO/tablas/cpbt.txt ]
then
	for reg in $(cat $GRUPO/tablas/cpbt.txt)
	do
		cuit=$(echo $reg | cut -f 1 -d,)
		tipo=$(echo $reg | cut -f 2 -d,)
 		seq_inicial=$(echo $reg | cut -f 3 -d,)
		# Se actualiza a la ultima usada si se creo algun CAE desde 
		# la ultima actualizacion
		if [ -e $GRUPO/$cuit.$tipo.seq ]
		then
			seq_final=$(tail -n 1 "$cuit.$tipo.seq" | awk -F, '{printf("%05d",$0)}' )
			rm $GRUPO/$cuit.$tipo.seq
		else
			seq_final=$(echo $reg | cut -f 4 -d,)
		fi
		echo "$cuit,$tipo,$seq_inicial,$seq_final" >> $GRUPO/tablas/cpbt.txt.new
	done	
	# Una vez actualizado el archivo maestro con los auxiliares borro el viejo y 
	# el nuevo pasa a ser el maestro
	mv -f "$GRUPO/tablas/cpbt.txt.new" "$GRUPO/tablas/cpbt.txt"
fi

# Se agregan los nuevos registros
for reg in $(ls $GRUPO/ | sed -n '/\.seq$/p')
do
	cuit=$(echo $reg | cut -f 1 -d.)
	tipo=$(echo $reg | cut -f 2 -d.)
	seq_inicial="00001"
	seq_final=$(tail -n 1 "$cuit.$tipo.seq" | awk -F, '{printf("%05d",$0)}' )
	echo "$cuit,$tipo,$seq_inicial,$seq_final" >> $GRUPO/tablas/cpbt.txt
	rm $GRUPO/$cuit.$tipo.seq
done

}

###############################################################
# Calcula el CAE de un registro validado
#
# Args: $1 -> registro a calcular CAE
#
# Return : CAE
#
calcularCAE(){
# Busco si ya existen archivos temporales con secuencias utilizadas
cuit=$(echo $1 | cut -f 1 -d,)
tipo=$(echo $1 | cut -f 3 -d,)

if [ -e  "$cuit.$tipo.seq" ]
then
	# Busco la ultima secuencia utilizada
	seq=$(tail -n 1 "$cuit.$tipo.seq")
else
	# Se busca en la tabla de comprobantes
	reg=$(cat "$GRUPO/tablas/cpbt.txt" 2> /dev/null | sed -n "/^$cuit,$tipo/p")
	if [ -z $reg ]
	then
		# No existe registro alguno por lo tanto inicializo en 0000
		seq=0
	else
		let seq=$(echo $reg | cut -f 4 -d, | bc)
	fi
fi
let seq=$seq+1

# Le doy el formato que debe tener( si es > 9999 -> 0001).
if [ $seq -gt $MAX_SEQ ]
then
	seq=1
fi

# Completo si faltan ceros a la izquierda.
seq_ceros=$(echo $seq | awk '{ printf("%05d",$1)  }')

# Almaceno la secuencia para poder actualizar la tabla de comprobantes luego.
echo "$seq" >> "$cuit.$tipo.seq"

__FCN_RETURN_VALUE__="$seq_ceros$2"
}

###############################################################
# Realiza validaciones para ver si el registro esta bien formado
#
# Args: $1 -> registro a validar
#
# Return : 0 -> esta bien formado , 1 -> esta mal formado
#
validarEstructura(){
# Expresiones regulares para validar registros bien formados. 
# Campos a Validar de los archivos de entrada ( cx -> campo x )
c1='[0-9]\{11\}'
c2='[^,]*'
c3='[FCD]'
c4='[0-9]\{5,\}'

c5='[^,]*'
c6='0*[0-9]\+\(\.[0-9][0-9]\?[0-9]\?\)\?'
c7='0*\(7\(\.\(2[5-9]\|[3-9][0-9]\?\)\)\|[8-9]\(\.[0-9][0-9]\?\)\?\|[12][0-9]\(\.[0-9][0-9]\?\)\?\)'
c8='0*[0-9]\+\(\.[0-9][0-9]\?[0-9]\?\)\?'
	
# (Opcionales -> se validan igual que el 6,7,8 pero son opcionales)
# 9,10,11  -> (6,7,8)?
# 12,13,14 -> (6,7,8)?
	
c15='0*[0-9]\+\(\.[0-9][0-9]\?[0-9]\?\)\?'
c16='0*[0-9]\+\(\.[0-9][0-9]\?[0-9]\?\)\?'
	
rechazado=$(echo $1 | grep -v "^$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8\(,$c6,$c7,$c8\)\?\(,$c6,$c7,$c8\)\?,$c15,$c16$")

if [ $rechazado ]
then
	return 1
else
	return 0
fi
}

#################################################################
# Valida que una fecha sea valida
#
# Args: $1 -> Fecha aaaammdd
#
# Return : 0 -> fecha valida ; 1 -> fecha invalida
#
validarFecha(){
 # Si no devuelve el numero de segundos desde el 01-01-1970 la fecha
 # no es valida
 $(date -d $1 +%s | grep -q "^[0-9]*$")
 
 # Solo para explicitar que es lo que se devuelve
 return $?
}

#################################################################
# Realiza las validaciones de cada campo particular:
#	Denominacion==Nombre | Razon Social en la tabla ctbyt.txt
#	FechaComprobante <= Periodo.
#	Delta(Importe Total)~+-0.3 centavos.
#
# Args: $1 -> registro a validar
#
# Return : 0 -> la logica es correcta , 1 -> logica incorrecta.
#

validarLogica(){
# Obtengo la cantidad de campos de la linea.
ncampos=$(echo $1 | awk -F, '{print NF}')

# Se valida que el nombre o razon social corresponda al cuit segun lo 
# ingresado en la tabla de contribuyentes.

cuit=$(echo $1 | cut -f 1 -d,)
denominacion=$(echo $1 | cut -f 2 -d,)
nombre=$(cat "$GRUPO/tablas/ctbyt.txt" | sed -n "s/^\([^,]*\),$cuit,.*$/\1/p")
if [ $denominacion != $nombre ]
then
	return 1
fi


# Se valida que fecha <= periodo.
 # - Se invierte la fecha para pode compararlos numericamente
fecha=$(echo $1 | cut -f 5 -d, | sed -n 's/\([0-9][0-9]\)-\([0-9][0-9]\)-\([0-9]\{4\}\)/\3\2\1/p')

# Se valida la fecha
validarFecha $fecha
if [ $? -eq 1 ]
then
	return 1
fi

# Debo quitarle los dias para poder compararla con el periodo
# Valido mientras fecha = aaaammdd
fecha=$(echo $fecha | cut -b 1-6 )

# Se valida que sea <= periodo
if [ $fecha -gt $2 ]
then
	return 1
fi

# Se calcula el impuesto y se comprueba que este en el rango
# de +- 3 centavos.
	
# Arreglo el problema del separador decimal en awk
t_LANG=$LANG
LANG=C

if [ $ncampos -eq 16 ]
then
	# Existen los 3 campos de impuestos
	total_calc=$(echo $1 | awk -F, '{print $15+($6*$7/100)+$6+($9*$10/100)+$9+($12*$13/100)+$12}' )
	total=$(echo $1 | awk -F, '{print $16}' )
elif [ $ncampos -eq 13 ]
then
	# Existen 2 campos de impuestos
	total_calc=$(echo $1 | awk -F, '{print $12+($6*$7/100)+$6+($9*$10/100)+$9)}')
	total=$(echo $1 | awk -F, '{print $13}' )
else
	# Existen solo el campo requerido
	total_calc=$(echo $1 | awk -F, '{print $9+($6*$7/100)+$6}')
	total=$(echo $1 | awk -F, '{print $10}' )
fi
# Reparo los cambios
LANG=$t_LANG

# Redondeo el 3 decimal y trunco a dos decimales para poder comparar contra 0.3
delta=$(echo "scale=2;(($total-$total_calc)+0.005)/1" | bc -q)
res=$( echo "$delta<=0.03" | bc -q)
if [ $res -eq 1 ]
then
	res=$( echo "$delta>=-0.03" | bc -q)
	if [ $res -eq 1 ]
	then
		return 0		
	fi
fi
return 1
}

###########################################################################
# procesarRecibidos: 	Recorre todos los archivos en /recibidos/ y realiza 
#			las validaciones y calculos necesarios.
#

procesarRecibidos(){
# Modifico el IFS para evitar conflictos
IFS='
'
# Obtengo el numero de corrida de la ultima corrida + 1.
ncorrida=$(ls $GRUPO/recibidos/procesados/ | sed 's/^.*\.\([^.]*\)$/\1/' | sort -nr | head -n 1)
if [ $ncorrida ]
then
	let ncorrida=ncorrida+1
else
	# NULL == FALSE
	ncorrida=$NCORRIDA_INICIAL
fi 

# Cuento la cantidad de archivos a procesar
nprocesar=$(ls -F $GRUPO/recibidos | sed '/.*\/$/d' | wc -l)
# Grabo Log
grabaL.sh '*******'"INICIO DE Corrida $ncorrida. Archivos a procesar $nprocesar."'*******'

# Recorro cada archivo en la carpeta recibidos
for arch in $(ls -F $GRUPO/recibidos | sed '/.*\/$/d')
do
    grabaL.sh "Inicio del proceso de archivo $arch."
	# Inicializo las varialbes que cuentan la cantidad de registros correctos e incorrectos
	let ok=0
	let nok=0
	periodo=$(echo $arch | cut -f 2 -d.)	
	# Archivo donde guardar registros procesados
	out=$GRUPO/recibidos/procesados/$arch.$ncorrida

	for linea in $(cat $GRUPO/recibidos/$arch)
	do
		validarEstructura $linea
		res=$?
		if [ $res -eq 1 ]
		then		
			echo $linea,RECHAZADO >> $out
			let nok=$nok+1
		else
			echo "El registro esta bien formado, validando logica."
			validarLogica $linea $periodo
			res=$?
			if [ $res -eq 1 ]
			then
				echo $linea,RECHAZADO >> $out
				let nok=$nok+1
			else
				echo "Todo en orden, calculando CAE"
				calcularCAE $linea
				CAE=${__FCN_RETURN_VALUE__}
				echo "CAE calculado, creando archivo de iva."
				crearIvaC $linea $periodo $CAE
				echo $linea,$CAE >> $out
				let ok=$ok+1
			fi
		fi
	done # Fin del recorrido del archivo
	
	# Lo borro sin confirmacion
	rm -f $GRUPO/recibidos/$arch
		
	# Grabo Log
	grabaL.sh "Fin del proceso de archivo $arch. Registros procesados ok: $ok. Registros rechazados: $nok. "
done # Fin del recorrido de archivos

echo "Actualizando tabla de comprobantes."
# Actualizo la tabla cpbt.txt con el ultimo numero de seq usado para el CAE
actualizarComprobantes
	

# Grabo Log
grabaL.sh '*******'"FIN Corrida $ncorrida."'*******'
}

###########################################################################
# Arranque del script: Se realizan chequeos para saber si la ejecucion es 
# manual o automatica, en caso de ser manual debe haberse ejecutado el iniciaC
#

echo "Ejecutando ValidCo.sh..."
if [ $GRUPO ]
then
	procesarRecibidos
else
	echo "Error!,No se ejecuto iniciaC previamente."
fi

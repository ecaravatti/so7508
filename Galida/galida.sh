#!/bin/bash

# Constantes
ERROR=1
OK=0


# Paths
path=/home/estefania/Facu/SistemasOperativos/gastos
reci=$path/arridir/reci
reci_ok=$reci/ok
reci_rech=$reci/rech
a_procesar=$path/gastodir/aproc
log=$path/logdir
gastos_conf=$path/confdir/gastos.conf
conceptos_x_area=$path/confdir/cxa.tab

PATH=$PATH:/home/estefania/Facu/SistemasOperativos/gastos/bin
export PATH


# Recibe el archivo a ordenar en $1 y deja el ordenado en $a_procesar
ordenar_archivo()
{
	# ordena por el campo 1, luego por el 3 y luego por el 2.
	sort -o "$reci_ok/$arch.ord" -t';' +0 -1 +2 -3 +1 -n "$reci_ok/$arch"
	
	echo "ya ordene el archivo."
	rm $reci_ok/$arch

	mover.sh "$reci_ok/$arch.ord" "$a_procesar" "galida"
	glog.sh "galida" "Archivo ordenado $arch.ord." "GALIDA"

	return $OK
}

validar_bisiesto()
{
	return $OK
}

# Recibe el id concepto
validar_concepto()
{
	echo "estoy en validar_concepto. Quiero buscar $1 en: $conceptos_x_area"
	local concepto_encontrado=$(cut -d';' -f 2 $conceptos_x_area | grep -c "^$1$")

	echo " si $concepto_encontrado es cero no hubo match con el grep"
	
	if [ "$concepto_encontrado" -eq 0 ]
	then 
		return $ERROR	
	else
		return $OK
	fi	

}

# $1: dia
# $2: mes
# $3: anio
validar_dia()
{
	# Valida que sea un numero de 2 digitos.
	local dia_valido=$(echo $1 | grep -c '^[0-3][0-9]$')

	# Valida que sea un numero menor a 32
	if [ "$1" -gt 31 ]
	then
		return $ERROR
	fi

	if [ "$dia_valido" -eq 1 ]
	then
		validar_bisiesto $1 $2 $3
	else
		return $ERROR
	fi
}

# $1 Recibe el importe
validar_importe()
{
	local importe_valido=$(echo $1 | grep -c '^[0-9]*\.[0-9][0-9]$')
	
	if [ "$importe_valido" -eq 1 ]
	then
#		echo "el importe $1  paso la primer validacion importe_valido:$importe_valido es decir encontro un match en el grep con el formato numerico"
		importe_valido=$(echo $1 | grep -c '^0*\.00$')
		
		if [ "$importe_valido" -eq 1 ]
		then 
			echo "importe nulo"
			return $ERROR
		fi
		echo "importe no nulo"
		return $OK
	else
		return $ERROR
	fi
}

# Recibe el nombre del archivo a validar
validar_registros_archivo() 
{
	local numero_registro=0
	local resultado=0
	local cantidad_registros_erroneos=0

	for linea in `cat $reci/$1`
	do
		resultado=0
		numero_registro=`expr $numero_registro + 1`
		
		echo "linea: $linea"
		cantidad_campos=$(echo $linea | awk -F';' '{print NF}')
		echo "cant campos: $cantidad_campos"
				
		if [ "$cantidad_campos" -eq 4 ]
		then
			dia=$( echo $linea | awk -F';' '{print $1}')
			comprobante=$(echo $linea | awk -F';' '{print $2}')
			id_concepto=$(echo $linea | awk -F';' '{print $3}')
			importe=$(echo $linea | awk -F';' '{print $4}')

			anio=$(echo $1 | cut -c 8-11)
			mes=$(echo $1 | cut -c 12-13)

#			echo "anio y mes del archivo: $anio $mes"

			validar_dia $dia $mes $anio
			local dia_valido="$?"

			if [ "$dia_valido" -eq "$ERROR" ]
			then
				glog.sh "galida" "El registro $numero_registro es rechazado debido a fecha invalida." "GALIDA"
				# Resultado indica que hay error
				resultado=1
				continue
			fi

			validar_importe $importe
			local importe_valido="$?"

			if [ "$importe_valido" -eq "$ERROR" ]
			then 
				glog.sh "galida" "El registro $numero_registro es rechazado debido a importe invalido." "GALIDA"
				resultado=1
				continue
			fi
			
			validar_concepto $id_concepto
			local concepto_valido="$?"

			if [ "$concepto_valido" -eq "$ERROR" ]
			then
				resultado=1
				glog.sh "galida" "El registro $numero_registro es rechazado debido a concepto invalido." "GALIDA"
				continue
			fi

			# TODO: Validar comprobante

		else
			echo "Cant de campos invalida"
			glog.sh "galida" "El registro $numero_registro es rechazado debido a cantidad de campos invalida." "GALIDA"
			resultado=1
			continue
		fi
		
		if [ "$resultado" -gt 0 ]
			then
				# Incremento la cantidad de registros erroneos
				cantidad_registros_erroneos=`expr $cantidad_registros_erroneos + 1`
				echo "REGS ERROR: $cantidad_registros_erroneos"
		fi
	done
	
	# Si hubieron regitros invalidos retorno archivo con error
	if [ "$cantidad_registros_erroneos" -gt 0 ]
	then 
		return $ERROR
	else
		return $OK
	fi
	
}

# Si el archivo ordenado ya existe (ya fue procesado), devuelve ERROR, de lo contrario devuelve OK
verificar_archivo_ordenado()
{
	echo "estoy verificando el arch ordenado $1"
	local existe=$(ls -l $a_procesar | grep -c "$1.ord")
	if [ "$existe" -eq 1 ]
	then
		return $ERROR
	else
		return $OK
	fi
}

#Recibe el nombre del archivo
validar_anio()
{
	#obtengo los caracteres correspondientes al año
	local anio=$(echo $1 | cut -c 8-11)

	echo "el anio a validar es: $anio"

	local anio_maximo=$(sed -n 4p $gastos_conf | cut -f 3 -d\ )

	echo "el anio_maximo es: $anio_maximo"
	
	# anio >= anio_maximo
	if [ "$anio" -ge "$anio_maximo" ] 
	then
		echo "anio valido"
		return $OK
	else
		echo "anio invalido"
		return $ERROR
	fi
}


# Recibe un string a buscar dentro del archivo. 
#Devuelve la cantidad de ocurrencias del mismo.
buscar_en_archivo()
{
	echo "estoy en buscar_en_archivo. Quiero buscar en: $area_tab"
	local resultado=$(cat $area_tab | grep "$1;" | wc -l)
	echo "encontro el area?: $resultado"
	return $resultado
}

# Recibe como argumento el nombre de archivo.
validar_area()
{
	echo "estoy validando area. en \$1 hay: $1"
	#obtengo los primeros 6 caracteres
	local area=$(echo $1 | cut -c 1-6)

	echo "en area me queda: $area"

	buscar_en_archivo $area
	area_encontrada="$?"

	echo "sali de buscar archivo, area_encontrada: $area_encontrada"

	return $area_encontrada
}

validar_nombre_archivo()
{	
	#primero valida que el formato sea codigo de area[6caracteres numericos].fecha[6caracteres numericos]
	local resultado=$(echo $1 | grep -c '^[0-9]\{6\}\.[0-9]\{6\}$')
	
	echo "resultadoGlobal: $resultado"

	#si el nombre del archivo es del formato correcto
	if [ "$resultado" -eq 1 ] 
		then
		echo "voy a validar area"
		validar_area $1
		resultado="$?"

		echo "resultadoArea: $resultado"

		if [ "$resultado" -gt 0 ] 
			then # Si el area es valida
	
			echo "voy a validar año"
			validar_anio $1 # Valido el anio
			resultado="$?"

			echo "resultado de validar_anio: $resultado"
			
			if [ "$resultado" = 0 ] 
				then
				return $OK
			else
				return $ERROR
			fi

		else
			return 	$ERROR	

		fi

	else 
		return $ERROR	
	fi
}

glog.sh "galida" "Inicio de Ejecución." "GALIDA"

cantidad_archivos_procesados=0
cantidad_archivos_duplicados=0
cantidad_archivos_rechazados=0
cantidad_archivos_aceptados=0

for arch in `ls $reci`
do
	if [ ! -d $arch ] 
	then
		validar_nombre_archivo $arch
		archivo_valido="$?"
			
		echo "VALIDACION NOMBRE ARCHIVO: $archivo_valido"
		if [ "$archivo_valido" -eq "$OK" ]
		then		
			cantidad_archivos_procesados=`expr $cantidad_archivos_procesados + 1`
			echo "ARCH PROC: $cantidad_archivos_procesados"
			echo "********************************************************************************************** "
			echo " "
			echo " "
			echo "ARCHIVO $arch"	
		
			glog.sh "galida" "Validando archivo $arch" "GALIDA"
	
			verificar_archivo_ordenado $arch
			resultado="$?"
		
			echo "verificar_archivo_ordenado: $resultado"
		
			if [ "$resultado" -eq "$ERROR" ]
			then
		
				echo "El archivo esta duplicado.. lo muevo a rechazados"
				cantidad_archivos_duplicados=`expr $cantidad_archivos_duplicados + 1`
				cantidad_archivos_rechazados=`expr $cantidad_archivos_rechazados + 1`
	
				echo "ARCH DUPL: $cantidad_archivos_duplicados"
				echo "ARCH RECH: $cantidad_archivos_rechazados"
	
				mover.sh "$reci/$arch" "$reci_rech" "galida" "Archivo duplicado, ya existe un archivo del mismo nombre para procesar."
			else
				echo "El arch no existe, voy a validar los registros."
				
				validar_registros_archivo $arch
				resultado="$?"
	
				echo "ya valide los registros: $resultado"
				if [ "$resultado" -eq "$ERROR" ]
				then
					mover.sh "$reci/$arch" "$reci_rech" "galida" "Archivo rechazado, algún registro no corresponde al formato adecuado"
					echo "Muevo el archivo $arch a $reci_rech"
					cantidad_archivos_rechazados=`expr $cantidad_archivos_rechazados + 1`
				else
					mover.sh "$reci/$arch" "$reci_ok" "galida" "Archivo aceptado"
					
					echo "MUevo el archivo $arch a $reci_ok"
	
					ordenar_archivo $arch
					cantidad_archivos_aceptados=`expr $cantidad_archivos_aceptados + 1`
				fi
			fi
		fi
	fi
done

# se fija si esta corriendo gontro.pl
gontro_corriendo=$( ps aux | grep -c gontro )	

echo "gontro_corriendo: $gontro_corriendo"

if [ $gontro_corriendo -lt 2 ] 
then
	echo "perl gontro.pl &" #TODO: llamarlo posta!
else
	echo "esta corriendo gontro!"
fi

echo "PROCESADOS: $cantidad_archivos_procesados DUPLICADOS:$cantidad_archivos_duplicados RECHAZADOS:$cantidad_archivos_rechazados ACEPTADOS: $cantidad_archivos_aceptados"

glog.sh "galida" "Cantidad de archivos procesados: $cantidad_archivos_procesados" "GALIDA"
glog.sh "galida" "Cantidad de archivos duplicados: $cantidad_archivos_duplicados" "GALIDA"
glog.sh "galida" "Cantidad de archivos rechazados: $cantidad_archivos_rechazados" "GALIDA"
glog.sh "galida" "Cantidad de archivos aceptados: $cantidad_archivos_aceptados" "GALIDA"
glog.sh "galida" "Fin de ejecucion" "GALIDA"

exit 0
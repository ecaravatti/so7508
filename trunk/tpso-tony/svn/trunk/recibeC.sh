#Precondiciones:
# Se debe ejecutar antes el comando IniciaC
# Deben estar seteadas las variables de entorno necesarias
#
#Postcondiciones:
# Se crea el demonio RecibeC que corre en background hasta que sea detenido con el comando correspondiente

# ------------------------------SETEO VARIABLES ----------------------------------------
NOMBRE_DEMONIO="recibeC.sh"
#Configuro el tiempo que va a dormir el demonio
DORMIR=5
# ----------------------------- Variables PATH de los directorios --------------------
# Uso archivos comenzados con . para que queden ocultos
###########################################
#Archivo para almacenar resultadostemporales
F_CUMPLEN=$GRUPO/".cumplen.tmp" 
F_NO_CUMPLEN=$GRUPO/".no_cumplen.tmp" 
F_TEMP=$GRUPO/".temporal.tmp" 
#Archivo para determinar si el proceso esta corriendo (contiene el PID del momento en que es lanzado el demonio)
F_CORRIENDO=$GRUPO/"demonio_recibec.pid" 
F_TABLA_CONTRIBUYENTES=$GRUPO/tablas/ctbyt.txt

#Directotios de input
D_ARRIBOS=$GRUPO/arribos
D_TABLAS=$GRUPO/tablas

#Directorios de output
D_RECIBIDOS=$GRUPO/recibidos
D_NORECIBIDOS=$GRUPO/norecibidos
D_LOG=$GRUPO/log

#Nombres de carpetas utilizadas
C_RECIBIDOS=recibidos
C_PROCESADOS=procesados
C_ARRIBOS=arribos

# ----------------------------- Variables PATH de los procesos externos utilizados --------------------
C_LOGUEAR=$GRUPO/"grabaL.sh"
C_VALIDCO=$GRUPO/"validCo.sh"
NOMBRE_VALIDCO="validCo.sh"

#------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------


#--------------------------------------FUNCIONES DEL DEMONIO RECIBEC--------------------------------


# ejecutar_ciclo()
# Esta funcion ejecuta un ciclo infinito
# El ciclo ejecuta cada 5 segundos
ejecutar_ciclo(){
	
	#El demonio corre mientras exista el archivo F_CORRIENDO
	while [ -f "$F_CORRIENDO" ]
	do
		#ejecuta la funcion de procesamiento
		procesar_archivos
		#chequeo que siga estando el archivo que indica que el demonio esta corriendo
		if [ -f "$F_CORRIENDO" ]
		then
			sleep $DORMIR
		fi
	done

}

procesar_archivos(){
#Grabo Log

	hay_archivos
	comenzar="$?" #Resultado de la funcion anterior
	#Hay archivos, proceso (1 indica que no hay archivos a procesar)
	# Si hay algun archivo, ya sea valido o no, invoco al validCo
	if [ "$comenzar" != "1" ]
	then
		$C_LOGUEAR "Inicio Ciclo"
		#Verifico el formato de los archivos
		# 11 digitos, un punto y 6 digitos
		verificar_formato
		
		for archivo in $(cat "$F_NO_CUMPLEN")
		do
			$C_LOGUEAR "Nombre de Archivo Incorrecto: "$archivo""
			mover_no_cumplen "$archivo"
		done # Fin del recorrido de archivos
		
		
		#Verifico que el CUIT figure en el nombre del archivo de contribuyentes
		verificar_contribuyente
		
		for archivo in $(cat "$F_NO_CUMPLEN")
		do
			$C_LOGUEAR "Nro de CUIT inexistente: "$archivo""
			mover_no_cumplen "$archivo"
		done # Fin del recorrido de archivos
		

		#Verifico que la fecha que figura en el nombre del archivo sea mayor o igual
		# que la fecha de habilitacion que figura en el archivo de contribuyentes
		verificar_periodo

		for archivo in $(cat "$F_NO_CUMPLEN")
		do
			$C_LOGUEAR "Periodo No Habilitado "$archivo""
			mover_no_cumplen "$archivo"
		done # Fin del recorrido de archivos
		

		#Verifico que la fecha que figura en el nombre del archivo este dentro
		# del rango valido de fechas
		verificar_no_vencido

		for archivo in $(cat "$F_NO_CUMPLEN")
		do
			$C_LOGUEAR "Periodo Fuera de Rango "$archivo""
			mover_no_cumplen "$archivo"
		done # Fin del recorrido de archivos

		#PARA LOS ARCHIVOS QUE ESTAN OK	
		#Archivos que pasaron todas las validaciones (quedaron dentro del archivo F_CUMPLEN
		for archivo in $(cat "$F_CUMPLEN")
		do
			mover_cumplen "$archivo"
		done # Fin del recorrido de archivos

		#Llamo al validCo
		# Si la corrida es automatica, llamo al validCo si no se esta ejecutando
		#Sino no
		if [ "$AUTO" == "SI" ]
		then
			#Me fijo si esta corriendo el proceso validCo
			#ps -A lista todos los procesos
			#Me fijo si el proceso validCo esta ejecutando
			check=$(ps -A | grep "$NOMBRE_VALIDCO")

			if [ -z "$check" ]
			then
				#No esta corriendo, lo lanzo
				"$C_VALIDCO" &
				#Obtengo el pid del proceso validCo
				comando=$(ps | grep ""$NOMBRE_VALIDCO"")
				pidValidCo=$(echo $comando | cut -d ' ' -f1)

				#Imprimo mensaje
				echo "*************************************************"
				echo "* ValidCo coriendo bajo el numero: "$pidValidCo" *"
				echo "*************************************************"
			else
				#Ya esta corriendo
				echo "*************************************************"
				echo "* Error al Invocar ValidCo   		      *"
				echo "*************************************************"
			fi

		fi
		
		#Boro los archivos temporales si existen
		if [ -f "$F_CUMPLEN" ]
		then
			rm "$F_CUMPLEN"
		fi
		
		if [ -f "$F_NO_CUMPLEN" ]
		then
			rm "$F_NO_CUMPLEN"
		fi

		$C_LOGUEAR "Fin de Ciclo"
	fi

}


# start_daemon_recibec()
# Esta funcion lanza al demonio recibec
# Se debe frenar con el stop_daemon_recibec
# Si se sale sin frenar al demonio, se debe ejecutar el start_daemon_recibec_forzado
start_daemon_recibec(){
	
	#Se fija si esta corriendo
	if [ -f "$F_CORRIENDO" ]
	then
		echo El demonio recibeC ya esta corriendo
		return 1
	else
	#Si no corre, lo lanza
		#Crea el archivo $F_CORRIENDO
		echo  >"$F_CORRIENDO"
		#Ejecuto el ciclo infinito en background
		ejecutar_ciclo &
		#Guardo el process ID en el archivo F_CORRIENDO
		# La existencia de dicho archivo, indica que el demonio esta corriendo
		echo $! >"$F_CORRIENDO"
		return 0
	fi
}


# start_daemon_recibec_forzado()
# Esta funcion lanza al demonio recibec en caso de que se haya cerrado en mal estado
start_daemon_recibec_forzado(){
	stop_daemon_recibec
	start_daemon_recibec
}



#stop_daemon_recibec
# Frena al demonio correctamente
# Borra el archivo $F_CORRIENDO
stop_daemon_recibec(){

	if [ -f "$F_CORRIENDO" ]
	then
		rm "$F_CORRIENDO"
	fi
	
}

#ps_daemon_recibec()
# Devuelve el estado del demonio
# 0 si no esta corriendo
# 1 si esta corriendo correctamente
# 2 si fue terminado bruscamente (no se borro el archivo F_CORRIENDO al terminar el demonio)
#IMPORTANTE: salida 2 indica que se debe ejecutar stop_daemon_recibec() antes de volver a lanzar el demonio, o
#se debe arrancar el demonio con start_daemon_recibec_forzado()
ps_daemon_recibec(){

	if [ -f "$F_CORRIENDO" ]
	then
		PID_ARCHIVO=$(head -n1 "$F_CORRIENDO")
		#Me fijo si el numero de proceso existe, y si el nombre del proceso coincide con el del demonio
		PID_ACTUAL=$(ps -p "$PID_ARCHIVO" | grep "$NOMBRE_DEMONIO")
		#si el pid_actual no esta vacio
		if [ -z "$PID_ACTUAL" ]
		then
			#el demonio no esta corriendo pero el archivo F_CORRIENDO no se borro
			return 2
		else
			#salida con 1, el demonio esa corriendo
			return 1
		fi
	else
		#el demonio no esta corriendo
		return 0
	fi

}


#get_id_demonio_recibec()
#Devuelve el id del proceso recibec
get_id_demonio_recibec(){

	if [ -f "$F_CORRIENDO" ]
	then
		PID_ARCHIVO=$(head -n1 "$F_CORRIENDO")
		#Me fijo si el numero de proceso existe, y si el nombre del proceso coincide con el del demonio
		echo $PID_ARCHIVO
	else
		echo "El demonio recibec no esta corriendo"
	fi
}	

#Devuelve 0 si hay archivos en ARRIBOS, 1 sino
hay_archivos(){

	resultado_archivos=$(ls "$D_ARRIBOS")
	#No hay archivos
	if [ -z "$resultado_archivos" ]
	then
		return 1
	else
		return 0
	fi
}


#verificar_formato()
#Verifica que el formato del archivo sea correcto, en el archivo temporal CUMPLEN deja los nombres los
# los archivos validos, en NO_CUMPLEN deja los nombres de los archivos que no tienen el formato requerido
#Formato archivo valido:
# 11 digitos
# punto
# 6 digitos
verificar_formato(){
	#Hago un ls en la carpeta recibidos
	#Guardo en TEMP1 los que cumplen formato
	ls "$D_ARRIBOS" | grep  '[0-9]\{11\}\.[0-9]\{6\}$' >$F_CUMPLEN
	#Guardo en TEMP2 los que no cumplen formato
	ls "$D_ARRIBOS" | grep -v '[0-9]\{11\}\.[0-9]\{6\}$' >$F_NO_CUMPLEN

}


#verificar_contribuyente()
#Verifica que el contribuyente figure en la tabla de contribuyentes
# Se trabaja con el contenido del archivo $F_CUMPLEN, ya que contiene todos los nombres
#de archivos con formato valido (evita problemas si subieron un archivo luego de que haya corrido el validar_formato())
verificar_contribuyente(){

	#Vacio el archivo de no_cumplen y el temporal
	cat >"$F_NO_CUMPLEN"
	cat >"$F_TEMP"

	for archivo in $(cat "$F_CUMPLEN")
	do		
		#Obtengo el numero de contribuyente (primeros 11 caracteres)
		contribuyente=$(echo "$archivo" | sed 's/^\([^\.]*\)\..*$/\1/g')

		#Me fijo si el numero de contribuyente esta dentro del archivo de contribuyentes
		encontrado=$(cat "$F_TABLA_CONTRIBUYENTES" | sed 's/^\([^,]*\),\([^,]*\),.*$/\2/g' | grep "$contribuyente")

		#Si es vacio el nombre significa que no lo encontro
		if [ -z "$encontrado" ]
		then
			echo $archivo >>$F_NO_CUMPLEN
		else
			echo $archivo >>$F_TEMP
		fi
	done
	
	#Guardo en el archivo F_CUMPLEN lo que esta en el temporal
	cat "$F_TEMP" >"$F_CUMPLEN"
	#Elimino el archivo temporal
	rm "$F_TEMP"
}



#verificar_periodo()
#Verifica que la fecha que figura en el nombre del archivo sea mayor o igual a la que figura en 
#el archivo de contribuyentes
#HIPOTESIS: El numero de contribuyente que viene en el archivo de contribuyentes, es unico, no puede repetirse
verificar_periodo(){

	#Vacio el archivo de no_cumplen y el temporal
	cat >"$F_NO_CUMPLEN"
	cat >"$F_TEMP"

	for archivo in $(cat "$F_CUMPLEN")
	do		

		#Obtengo el numero de contribuyente (primeros 11 caracteres) (Lo uso para buscar la fecha)
		# Ya se que esta dentro del archivo porque paso la segunda validacion
		contribuyente=$(echo "$archivo" | sed 's/^\([^\.]*\)\..*$/\1/g')

		#Obtengo la fecha del archivo (ultimos 6 caracteres)
		fecha_archivo=$(echo "$archivo" | sed 's/^\([^\.]*\)\.\(*\)*/\2/g')

		#Obtengo los registros que tengan el numero de contribuyente que busco
		# (solo puede ser uno)
		# Y de ese registro, obtengo la fecha
		fecha_contribuyente=$(cat "$F_TABLA_CONTRIBUYENTES" | grep "$contribuyente" | sed 's/^\([^,]*\),\([^,]*\),\([0-9]\{6\}\).*$/\3/g')

		#La fecha del archivo debe ser mayor o igual que la fecha que figura en contribuyente
		if [ "$fecha_archivo" -lt "$fecha_contribuyente" ]
		then
			echo $archivo >>$F_NO_CUMPLEN
		else
			echo $archivo >>$F_TEMP
		fi
	done
	
	#Guardo en el archivo F_CUMPLEN lo que esta en el temporal
	cat "$F_TEMP" >"$F_CUMPLEN"
	#Elimino el archivo temporal
	rm "$F_TEMP"
}


#verificar_no_vencido()
#Verifica que la fecha que figura en el nombre del archivo pertenezca al rango de fechas validas
#HIPOTESIS: El numero de contribuyente que viene en el archivo de contribuyentes, es unico, no puede repetirse
verificar_no_vencido(){

	#Vacio el archivo de no_cumplen y el temporal
	cat >"$F_NO_CUMPLEN"
	cat >"$F_TEMP"

	for archivo in $(cat "$F_CUMPLEN")
	do		

		#Obtengo la fecha del archivo (ultimos 6 caracteres) (AAAAMM)
		fecha_archivo=$(echo "$archivo" | sed 's/^\([^\.]*\)\.\(*\)*/\2/g')

		#Obtengo el año del nombre del archivo (primeros 4 digitos)
		anio_archivo=$(echo "$fecha_archivo" | sed 's/^\([0-9]\{4\}\).*$/\1/g')

		#Obtengo el mes del nombre del archivo (ultimos 2 digitos)
		mes_archivo=$(echo "$fecha_archivo" | sed 's/^\([0-9]\{4\}\)\([0-9]\{2\}\)$/\2/g')

		#Obtengo el año actual AAAA
		# %Y = AAAA
		anio_actual=$(date +%Y)

		#Obtengo el mes actual AAAA
		# %m = MM
		mes_actual=$(date +%m)

		#Valido que el mes del archivo este en el rango 1-12
		if [ $mes_archivo -gt 12 -o $mes_archivo -lt 1 ]
		then
			echo $archivo >>$F_NO_CUMPLEN
		else
	
			let dif_anios=anio_actual-anio_archivo
			let dif_meses=mes_actual-mes_archivo
	
			#Analizo el valor de la dvariable diferencia
	
			#Si es cero, estoy en el mismo año
			if [ $dif_anios -eq 0 ]
			then
				#La diferencia de meses debe estar entre -1 (uno de anticipacion) y 2 (2 de antiguedad)
				if [ $dif_meses -ge -1 -a $dif_meses -le 2 ]
				then #CUMPLE
					echo $archivo >>$F_TEMP
				else #NO CUMPLE
					echo $archivo >>$F_NO_CUMPLEN
				fi
			#El año del archivo es un año anterior al actual. Ejemplo: Año act 2007, año arch 2006
			elif [ $dif_anios -eq 1 ]
			then
				#La diferencia de meses debe ser -10 o -11
				#Casos permitidos:
					#Mes actual: 1	Mes archivo: 12 y 11 (1-12 = -11 && 1-11=-10)
					#Mes actual 2 	Mes archiv: 11	(1-11=-10)
				if [ $dif_meses -eq -10 -o $dif_meses -eq -11 ]
				then #CUMPLE
					echo $archivo >>$F_TEMP
				else #NO CUMPLE
					echo $archivo >>$F_NO_CUMPLEN
				fi
			#El año del archivo es un año posterior al actual. Ejemplo: Año act 2007, año arch 2008
			elif [ $dif_anios -eq -1 ]
			then
				#La diferencia de meses debe ser de 11
				#Casos permitidos:
					#Mes actual: 12	Mes archivo: 1 (12-1=11)	
				if [ $dif_meses -eq 11 ]
				then #CUMPLE
					echo $archivo >>$F_TEMP
				else #NO CUMPLE
					echo $archivo >>$F_NO_CUMPLEN
				fi
			else #NO CUMPLE
				echo $archivo >>$F_NO_CUMPLEN
			fi 
		fi
	done
	
	#Guardo en el archivo F_CUMPLEN lo que esta en el temporal
	cat "$F_TEMP" >"$F_CUMPLEN"
	#Elimino el archivo temporal
	rm "$F_TEMP"
}




#mover_no_cumplen()
#$1 es el nombre del archivo que se desea mover
#Mueve los archivos que no cumplen las condiciones a la carpeta norecibidos
#En caso de que ya exista en dicha carpeta un archivo con el mismo nombre, lo descarta
mover_no_cumplen(){
	
	#Si el archivo existe en no_recibidos no lo muevo, solo lo borro de arribos
	if [ -f "$D_NORECIBIDOS"/"$1" ]
	then
		rm "$D_ARRIBOS"/"$1"
	else
		mv "$D_ARRIBOS"/"$1" "$D_NORECIBIDOS"
	fi

}	

#mover_cumplen()
#$1 es el nombre del archivo que se desea mover
#Mueve los archivos que cumplen las condiciones a la carpeta recibidos
#En caso de que ya exista en dicha carpeta un archivo con el mismo nombre, le agrega un numero de secuencia 
# al final y lo mueve a no recibidos
mover_cumplen(){
	
	nombre_archivo="$1"
	#En lista obtengo todos los archivos que tienen el mismo nombre que el que debo guardar
	lista=$(ls "$D_RECIBIDOS" | grep  "$1")

	#Si no existe, lo mando a RECIBIDOS
	if [ -z "$lista" ]
	then
		mv "$D_ARRIBOS"/"$1" "$D_RECIBIDOS"/"$nombre_archivo"
		#No se debe modificar el nombre del archivo
		$C_LOGUEAR "Archivo Recibido "$nombre_archivo""
	else
		#Esta repetido, lo mando a NO_RECIBIDOS con su numero de secuencia
		nsecuencia=1
		lista2=$(ls "$D_NORECIBIDOS" | grep  "$1")
		for archivos in "$lista2"
		do
			let nsecuencia=nsecuencia+1
		done # Fin del recorrido de archivos
		
		#El nombre del archivo destino se debe modificar
		nombre_archivo="$1".$nsecuencia
		mv "$D_ARRIBOS"/"$1" "$D_NORECIBIDOS"/"$nombre_archivo"
		$C_LOGUEAR "Archivo Duplicado "$nombre_archivo""
	fi

}	

#Arranque en modo automatico
arranque_automatico(){
	#Arranca desde el iniciaC
	#Me fijo el estado del demonio recibeC
	ps_daemon_recibec
	resultado="$?"
	if [ "$resultado" = 0 ]
	then
	#No esta corriendo, lo lanzo
		start_daemon_recibec
	elif [ "$resultado" = 1 ]
	then
		echo "El demonio recibeC ya esta corriendo"
	else
	#quedo en mal estado, no esta corriendo pero el archivo F_CORRIENDO no se borro
	#Lo ejecuto en forma forzada
		start_daemon_recibec_forzado
	fi
}


#Menu para mostrar las opciones del comando en arranque en modo manual
menu(){
echo
echo "Uso del comando recibeC en forma manual: ./recibeC.sh [parametro]"
echo
echo "Valores del parametro:"
echo
echo "		start: lanza al demonio recibeC"
echo
echo "		stop: detiene al demonio recibeC"
echo
echo "		id: devuelve el pid del proceso recibeC"
echo
echo "		status: devuelve el estado del proceso recibeC"
echo
echo "		start_forzado: frena y vuelve a lanzar recibeC (reset)"
echo
echo "		help: muestra el menu de opciones"
echo
echo
}

#Arranque en modo manual. Se utiliza el primer parametro con que se invoca al comando.
arranque_manual(){

	menu

	if [ "$#" -ne 1 -o -z "$1" ]
	then
		echo "Uso: recibeC parametro"
		echo
		return 1
	fi


	if [ "$1" = "start" ]
	then
		echo "Lanzando demonio recibeC"
		start_daemon_recibec
	elif [ "$1" = "stop" ]
	then
		echo "Frenando demonio recibeC"
		stop_daemon_recibec
	elif [ "$1" = "id" ]
	then
		echo "Id del demonio recibeC: " get_id_demonio_recibec
	elif [ "$1" = "status" ]
	then
		ps_daemon_recibec
		if [ "$?" = 0 ]
		then
			echo "El demonio recibeC no esta corriendo"
		elif  [ "$?" = 1 ]
		then
			echo "El demonio recibeC esta corriendo"
		else
			echo "El demonio fue terminado bruscamente (para lanzar usar el parametro start_forzado)"
		fi

	elif [ "$1" = "start_forzado" ]
	then
		echo "Lanzando demonio recibeC en forma forzada"
		start_daemon_recibec_forzado
	elif [ "$1" = "help" ]
	then
		menu
	else
		echo "Parametro del comando recibec no reconocido"
		echo
		return 1
	fi
	return 0
}


#-------------------------- PRINCIPAL  ----------------------------

#Me fijo si es modo automatico o manual
if [ "$AUTO" = "SI" ]
then
	arranque_automatico
elif [ "$AUTO" = "NO" ]
then
	arranque_manual "$1"
else
	echo "Primero se debe ejecutar el comando iniciaC"
fi

echo " >  Ejecutando Auto-Extractor."
echo " >  Trabajo Practico de Sistemas Operativos."
echo " >  Grupo 7"

echo " >> Comenzando el proceso de instalacion."
grupo="grupo7"

# No puede existir ya una carpeta con el nombre de $grupo
if [ -d $(pwd)/$grupo ]
then
	echo " >> Error, la carpeta $grupo ya existe en este directorio."
fi

echo " >> Creando la estructura de directorios."

mkdir -m 755 $(pwd)/$grupo 2>> $HOME/instaC.log
mkdir -m 755 $(pwd)/$grupo/arribos 2>> $HOME/instaC.log
mkdir -m 755 $(pwd)/$grupo/log 2>> $HOME/instaC.log
mkdir -m 755 $(pwd)/$grupo/consultas 2>> $HOME/instaC.log
mkdir -m 755 $(pwd)/$grupo/ivaC 2>> $HOME/instaC.log
mkdir -m 755 $(pwd)/$grupo/norecibidos 2>> $HOME/instaC.log
mkdir -m 755 $(pwd)/$grupo/prueba 2>> $HOME/instaC.log
mkdir -m 755 $(pwd)/$grupo/recibidos 2>> $HOME/instaC.log
mkdir -m 755 $(pwd)/$grupo/recibidos/procesados 2>> $HOME/instaC.log
mkdir -m 755 $(pwd)/$grupo/tablas 2>> $HOME/instaC.log

# Si el log no es nulo entonces surgio algun error al crear los directorios
if [ ! -z $(cat $HOME/instaC.log) ]
then
	echo "Error al tratar de crear la estructura de directorios, mostrando log de errores:".
	cat $HOME/instaC.log	
	exit 1
fi

rm  $HOME/instaC.log 

echo " >> Estructura de directorios creada correctamente."
echo ""
echo ""
echo " >> Creando archivos de comandos."


echo " >>> Creando $(pwd)/$grupo/grabaL.sh."
cat << ! >> $(pwd)/$grupo/grabaL.sh
#! /usr/bin/bash

##################
# Imprime mensaje,fecha y usuario en un archivo de log
# con el nombre del proceso que lo invoco
#
# Arg1 -> Mensaje
#

# Busco el nombre del proceso que invoco el log.
# Si es un script le quito el .sh
cmd=\$(ps -p \$PPID -o "%a" | sed -n 's/^.*\.\/\([^.]*\)\.sh.*\$/\1/p')

if [[ !(-d "\$GRUPO/log/") ]]
then
	mkdir \$GRUPO/log/	
fi

echo \$1			>> "\$GRUPO/log/\$cmd.log"
echo \$(date  +%d/%m/%y)	>> "\$GRUPO/log/\$cmd.log"
echo \$(whoami)		>> "\$GRUPO/log/\$cmd.log"
!
chmod -f 777 $(pwd)/$grupo/grabaL.sh


echo " >>> Creando $(pwd)/$grupo/validCo.sh."
cat << ! >> $(pwd)/$grupo/validCo.sh
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
# Args: \$1 -> registro a utilizar para crear archivo de iva
# 	\$2 -> periodo
# 	\$3 -> CAE
#
crearIvaC(){
cuit=\$(echo \$1 | cut -f 1 -d,)
tipo=\$(echo \$1 | cut -f 3 -d,)
fecha=\$(echo \$1 | cut -f 5 -d, | sed -n 's/\([0-9][0-9]\)-\([0-9][0-9]\)-\([0-9]\{4\}\)/\1\/\2\/\3/p')

ncampos=\$(echo \$1 | awk -F, '{print NF}')

# Arreglo el problema del separador decimal en awk
t_LANG=\$LANG
LANG=C

if [ \$ncampos -eq 16 ]
then
	# Existen los 3 campos de impuestos
	total=\$(echo \$1 | awk -F, '{print \$15+(\$6*\$7/100)+\$6+(\$9*\$10/100)+\$9+(\$12*\$13/100)+\$12}' )
	exentos=\$(echo \$1 | cut -f 15 -d,)
	neto=\$(echo \$1 | awk -F, '{print \$6+\$9+\$12}' )
	impuesto=\$(echo \$1 | awk -F, '{print (\$6*\$7/100)+(\$9*\$10/100)+(\$12*\$13/100)}' )
elif [ \$ncampos -eq 13 ]
then
	# Existen 2 campos de impuestos
	total=\$(echo \$1 | awk -F, '{print \$12+(\$6*\$7/100)+\$6+(\$9*\$10/100)+\$9}')
	exentos=\$(echo \$1 | cut -f 12 -d,)
	neto=\$(echo \$1 | awk -F, '{print \$6+\$9}' )
	impuesto=\$(echo \$1 | awk -F, '{print (\$6*\$7/100)+(\$9*\$10/100)}' )
else
	# Existen solo el campo requerido
	total=\$(echo \$1 | awk -F, '{print \$9+(\$6*\$7/100)+\$6}')
	exentos=\$(echo \$1 | cut -f 9 -d,)
	neto=\$(echo \$1 | awk -F, '{print \$6}' )
	impuesto=\$(echo \$1 | awk -F, '{print (\$6*\$7/100)}' )
fi
# Reparo los cambios
LANG=\$t_LANG

echo \$cuit,\$3,\$tipo,\$fecha,\$total,\$exentos,\$neto,\$impuesto >> \$GRUPO/ivaC/\$2
}

###############################################################
# Actualiza la tabla de comprobantes con los nuevos numeros de secuencia
#
actualizarComprobantes(){
if [ -f \$GRUPO/tablas/cpbt.txt ]
then
	for reg in \$(cat \$GRUPO/tablas/cpbt.txt)
	do
		cuit=\$(echo \$reg | cut -f 1 -d,)
		tipo=\$(echo \$reg | cut -f 2 -d,)
 		seq_inicial=\$(echo \$reg | cut -f 3 -d,)
		# Se actualiza a la ultima usada si se creo algun CAE desde 
		# la ultima actualizacion
		if [ -e \$GRUPO/\$cuit.\$tipo.seq ]
		then
			seq_final=\$(tail -n 1 "\$cuit.\$tipo.seq" | awk -F, '{printf("%05d",\$0)}' )
			rm \$GRUPO/\$cuit.\$tipo.seq
		else
			seq_final=\$(echo \$reg | cut -f 4 -d,)
		fi
		echo "\$cuit,\$tipo,\$seq_inicial,\$seq_final" >> \$GRUPO/tablas/cpbt.txt.new
	done	
	# Una vez actualizado el archivo maestro con los auxiliares borro el viejo y 
	# el nuevo pasa a ser el maestro
	mv -f "\$GRUPO/tablas/cpbt.txt.new" "\$GRUPO/tablas/cpbt.txt"
fi

# Se agregan los nuevos registros
for reg in \$(ls \$GRUPO/ | sed -n '/\.seq\$/p')
do
	cuit=\$(echo \$reg | cut -f 1 -d.)
	tipo=\$(echo \$reg | cut -f 2 -d.)
	seq_inicial="00001"
	seq_final=\$(tail -n 1 "\$cuit.\$tipo.seq" | awk -F, '{printf("%05d",\$0)}' )
	echo "\$cuit,\$tipo,\$seq_inicial,\$seq_final" >> \$GRUPO/tablas/cpbt.txt
	rm \$GRUPO/\$cuit.\$tipo.seq
done

}

###############################################################
# Calcula el CAE de un registro validado
#
# Args: \$1 -> registro a calcular CAE
#
# Return : CAE
#
calcularCAE(){
# Busco si ya existen archivos temporales con secuencias utilizadas
cuit=\$(echo \$1 | cut -f 1 -d,)
tipo=\$(echo \$1 | cut -f 3 -d,)

if [ -e  "\$cuit.\$tipo.seq" ]
then
	# Busco la ultima secuencia utilizada
	seq=\$(tail -n 1 "\$cuit.\$tipo.seq")
else
	# Se busca en la tabla de comprobantes
	reg=\$(cat "\$GRUPO/tablas/cpbt.txt" 2> /dev/null | sed -n "/^\$cuit,\$tipo/p")
	if [ -z \$reg ]
	then
		# No existe registro alguno por lo tanto inicializo en 0000
		seq=0
	else
		let seq=\$(echo \$reg | cut -f 4 -d, | bc)
	fi
fi
let seq=\$seq+1

# Le doy el formato que debe tener( si es > 9999 -> 0001).
if [ \$seq -gt \$MAX_SEQ ]
then
	seq=1
fi

# Completo si faltan ceros a la izquierda.
seq_ceros=\$(echo \$seq | awk '{ printf("%05d",\$1)  }')

# Almaceno la secuencia para poder actualizar la tabla de comprobantes luego.
echo "\$seq" >> "\$cuit.\$tipo.seq"

__FCN_RETURN_VALUE__="\$seq_ceros\$2"
}

###############################################################
# Realiza validaciones para ver si el registro esta bien formado
#
# Args: \$1 -> registro a validar
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
	
rechazado=\$(echo \$1 | grep -v "^\$c1,\$c2,\$c3,\$c4,\$c5,\$c6,\$c7,\$c8\(,\$c6,\$c7,\$c8\)\?\(,\$c6,\$c7,\$c8\)\?,\$c15,\$c16\$")

if [ \$rechazado ]
then
	return 1
else
	return 0
fi
}

#################################################################
# Valida que una fecha sea valida
#
# Args: \$1 -> Fecha aaaammdd
#
# Return : 0 -> fecha valida ; 1 -> fecha invalida
#
validarFecha(){
 # Si no devuelve el numero de segundos desde el 01-01-1970 la fecha
 # no es valida
 \$(date -d \$1 +%s | grep -q "^[0-9]*\$")
 
 # Solo para explicitar que es lo que se devuelve
 return \$?
}

#################################################################
# Realiza las validaciones de cada campo particular:
#	Denominacion==Nombre | Razon Social en la tabla ctbyt.txt
#	FechaComprobante <= Periodo.
#	Delta(Importe Total)~+-0.3 centavos.
#
# Args: \$1 -> registro a validar
#
# Return : 0 -> la logica es correcta , 1 -> logica incorrecta.
#

validarLogica(){
# Obtengo la cantidad de campos de la linea.
ncampos=\$(echo \$1 | awk -F, '{print NF}')

# Se valida que el nombre o razon social corresponda al cuit segun lo 
# ingresado en la tabla de contribuyentes.

cuit=\$(echo \$1 | cut -f 1 -d,)
denominacion=\$(echo \$1 | cut -f 2 -d,)
nombre=\$(cat "\$GRUPO/tablas/ctbyt.txt" | sed -n "s/^\([^,]*\),\$cuit,.*\$/\1/p")
if [ \$denominacion != \$nombre ]
then
	return 1
fi


# Se valida que fecha <= periodo.
 # - Se invierte la fecha para pode compararlos numericamente
fecha=\$(echo \$1 | cut -f 5 -d, | sed -n 's/\([0-9][0-9]\)-\([0-9][0-9]\)-\([0-9]\{4\}\)/\3\2\1/p')

# Se valida la fecha
validarFecha \$fecha
if [ \$? -eq 1 ]
then
	return 1
fi

# Debo quitarle los dias para poder compararla con el periodo
# Valido mientras fecha = aaaammdd
fecha=\$(echo \$fecha | cut -b 1-6 )

# Se valida que sea <= periodo
if [ \$fecha -gt \$2 ]
then
	return 1
fi

# Se calcula el impuesto y se comprueba que este en el rango
# de +- 3 centavos.
	
# Arreglo el problema del separador decimal en awk
t_LANG=\$LANG
LANG=C

if [ \$ncampos -eq 16 ]
then
	# Existen los 3 campos de impuestos
	total_calc=\$(echo \$1 | awk -F, '{print \$15+(\$6*\$7/100)+\$6+(\$9*\$10/100)+\$9+(\$12*\$13/100)+\$12}' )
	total=\$(echo \$1 | awk -F, '{print \$16}' )
elif [ \$ncampos -eq 13 ]
then
	# Existen 2 campos de impuestos
	total_calc=\$(echo \$1 | awk -F, '{print \$12+(\$6*\$7/100)+\$6+(\$9*\$10/100)+\$9)}')
	total=\$(echo \$1 | awk -F, '{print \$13}' )
else
	# Existen solo el campo requerido
	total_calc=\$(echo \$1 | awk -F, '{print \$9+(\$6*\$7/100)+\$6}')
	total=\$(echo \$1 | awk -F, '{print \$10}' )
fi
# Reparo los cambios
LANG=\$t_LANG

# Redondeo el 3 decimal y trunco a dos decimales para poder comparar contra 0.3
delta=\$(echo "scale=2;((\$total-\$total_calc)+0.005)/1" | bc -q)
res=\$( echo "\$delta<=0.03" | bc -q)
if [ \$res -eq 1 ]
then
	res=\$( echo "\$delta>=-0.03" | bc -q)
	if [ \$res -eq 1 ]
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
ncorrida=\$(ls \$GRUPO/recibidos/procesados/ | sed 's/^.*\.\([^.]*\)\$/\1/' | sort -nr | head -n 1)
if [ \$ncorrida ]
then
	let ncorrida=ncorrida+1
else
	# NULL == FALSE
	ncorrida=\$NCORRIDA_INICIAL
fi 

# Cuento la cantidad de archivos a procesar
nprocesar=\$(ls -F \$GRUPO/recibidos | sed '/.*\/\$/d' | wc -l)
# Grabo Log
grabaL.sh '*******'"INICIO DE Corrida \$ncorrida. Archivos a procesar \$nprocesar."'*******'

# Recorro cada archivo en la carpeta recibidos
for arch in \$(ls -F \$GRUPO/recibidos | sed '/.*\/\$/d')
do
    grabaL.sh "Inicio del proceso de archivo \$arch."
	# Inicializo las varialbes que cuentan la cantidad de registros correctos e incorrectos
	let ok=0
	let nok=0
	periodo=\$(echo \$arch | cut -f 2 -d.)	
	# Archivo donde guardar registros procesados
	out=\$GRUPO/recibidos/procesados/\$arch.\$ncorrida

	for linea in \$(cat \$GRUPO/recibidos/\$arch)
	do
		validarEstructura \$linea
		res=\$?
		if [ \$res -eq 1 ]
		then		
			echo \$linea,RECHAZADO >> \$out
			let nok=\$nok+1
		else
			echo "El registro esta bien formado, validando logica."
			validarLogica \$linea \$periodo
			res=\$?
			if [ \$res -eq 1 ]
			then
				echo \$linea,RECHAZADO >> \$out
				let nok=\$nok+1
			else
				echo "Todo en orden, calculando CAE"
				calcularCAE \$linea
				CAE=\${__FCN_RETURN_VALUE__}
				echo "CAE calculado, creando archivo de iva."
				crearIvaC \$linea \$periodo \$CAE
				echo \$linea,\$CAE >> \$out
				let ok=\$ok+1
			fi
		fi
	done # Fin del recorrido del archivo
	
	# Lo borro sin confirmacion
	rm -f \$GRUPO/recibidos/\$arch
		
	# Grabo Log
	grabaL.sh "Fin del proceso de archivo \$arch. Registros procesados ok: \$ok. Registros rechazados: \$nok. "
done # Fin del recorrido de archivos

echo "Actualizando tabla de comprobantes."
# Actualizo la tabla cpbt.txt con el ultimo numero de seq usado para el CAE
actualizarComprobantes
	

# Grabo Log
grabaL.sh '*******'"FIN Corrida \$ncorrida."'*******'
}

###########################################################################
# Arranque del script: Se realizan chequeos para saber si la ejecucion es 
# manual o automatica, en caso de ser manual debe haberse ejecutado el iniciaC
#

echo "Ejecutando ValidCo.sh..."
if [ \$GRUPO ]
then
	procesarRecibidos
else
	echo "Error!,No se ejecuto iniciaC previamente."
fi
!
chmod -f 777 $(pwd)/$grupo/validCo.sh


echo " >>> Creando $(pwd)/$grupo/recibeC.sh."
cat << ! >> $(pwd)/$grupo/recibeC.sh
#! /usr/bin/bash

#! /usr/bin/bash

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
F_CUMPLEN=\$GRUPO/".cumplen.tmp" 
F_NO_CUMPLEN=\$GRUPO/".no_cumplen.tmp" 
F_TEMP=\$GRUPO/".temporal.tmp" 
#Archivo para determinar si el proceso esta corriendo (contiene el PID del momento en que es lanzado el demonio)
F_CORRIENDO=\$GRUPO/"demonio_recibec.pid" 
F_TABLA_CONTRIBUYENTES=\$GRUPO/tablas/ctbyt.txt

#Directotios de input
D_ARRIBOS=\$GRUPO/arribos
D_TABLAS=\$GRUPO/tablas

#Directorios de output
D_RECIBIDOS=\$GRUPO/recibidos
D_NORECIBIDOS=\$GRUPO/norecibidos
D_LOG=\$GRUPO/log

#Nombres de carpetas utilizadas
C_RECIBIDOS=recibidos
C_PROCESADOS=procesados
C_ARRIBOS=arribos

# ----------------------------- Variables PATH de los procesos externos utilizados --------------------
C_LOGUEAR=\$GRUPO/"grabaL.sh"
C_VALIDCO=\$GRUPO/"validCo.sh"
NOMBRE_VALIDCO="validCo.sh"

#------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------


#--------------------------------------FUNCIONES DEL DEMONIO RECIBEC--------------------------------


# ejecutar_ciclo()
# Esta funcion ejecuta un ciclo infinito
# El ciclo ejecuta cada 5 segundos
ejecutar_ciclo(){
	
	#El demonio corre mientras exista el archivo F_CORRIENDO
	while [ -f "\$F_CORRIENDO" ]
	do
		#ejecuta la funcion de procesamiento
		procesar_archivos
		#chequeo que siga estando el archivo que indica que el demonio esta corriendo
		if [ -f "\$F_CORRIENDO" ]
		then
			sleep \$DORMIR
		fi
	done

}

procesar_archivos(){
#Grabo Log

	hay_archivos
	comenzar="\$?" #Resultado de la funcion anterior
	#Hay archivos, proceso (1 indica que no hay archivos a procesar)
	# Si hay algun archivo, ya sea valido o no, invoco al validCo
	if [ "\$comenzar" != "1" ]
	then
		\$C_LOGUEAR "Inicio Ciclo"
		#Verifico el formato de los archivos
		# 11 digitos, un punto y 6 digitos
		verificar_formato
		
		for archivo in \$(cat "\$F_NO_CUMPLEN")
		do
			\$C_LOGUEAR "Nombre de Archivo Incorrecto: "\$archivo""
			mover_no_cumplen "\$archivo"
		done # Fin del recorrido de archivos
		
		
		#Verifico que el CUIT figure en el nombre del archivo de contribuyentes
		verificar_contribuyente
		
		for archivo in \$(cat "\$F_NO_CUMPLEN")
		do
			\$C_LOGUEAR "Nro de CUIT inexistente: "\$archivo""
			mover_no_cumplen "\$archivo"
		done # Fin del recorrido de archivos
		

		#Verifico que la fecha que figura en el nombre del archivo sea mayor o igual
		# que la fecha de habilitacion que figura en el archivo de contribuyentes
		verificar_periodo

		for archivo in \$(cat "\$F_NO_CUMPLEN")
		do
			\$C_LOGUEAR "Periodo No Habilitado "\$archivo""
			mover_no_cumplen "\$archivo"
		done # Fin del recorrido de archivos
		

		#Verifico que la fecha que figura en el nombre del archivo este dentro
		# del rango valido de fechas
		verificar_no_vencido

		for archivo in \$(cat "\$F_NO_CUMPLEN")
		do
			\$C_LOGUEAR "Periodo Fuera de Rango "\$archivo""
			mover_no_cumplen "\$archivo"
		done # Fin del recorrido de archivos

		#PARA LOS ARCHIVOS QUE ESTAN OK	
		#Archivos que pasaron todas las validaciones (quedaron dentro del archivo F_CUMPLEN
		for archivo in \$(cat "\$F_CUMPLEN")
		do
			mover_cumplen "\$archivo"
		done # Fin del recorrido de archivos

		#Llamo al validCo
		# Si la corrida es automatica, llamo al validCo si no se esta ejecutando
		#Sino no
		if [ "\$AUTO" == "SI" ]
		then
			#Me fijo si esta corriendo el proceso validCo
			#ps -A lista todos los procesos
			#Me fijo si el proceso validCo esta ejecutando
			check=\$(ps -A | grep "\$NOMBRE_VALIDCO")

			if [ -z "\$check" ]
			then
				#No esta corriendo, lo lanzo
				"\$C_VALIDCO" &
				#Obtengo el pid del proceso validCo
				comando=\$(ps | grep ""\$NOMBRE_VALIDCO"")
				pidValidCo=\$(echo \$comando | cut -d ' ' -f1)

				#Imprimo mensaje
				echo "*************************************************"
				echo "* ValidCo coriendo bajo el numero: "\$pidValidCo" *"
				echo "*************************************************"
			else
				#Ya esta corriendo
				echo "*************************************************"
				echo "* Error al Invocar ValidCo   		      *"
				echo "*************************************************"
			fi

		fi
		
		#Boro los archivos temporales si existen
		if [ -f "\$F_CUMPLEN" ]
		then
			rm "\$F_CUMPLEN"
		fi
		
		if [ -f "\$F_NO_CUMPLEN" ]
		then
			rm "\$F_NO_CUMPLEN"
		fi

		\$C_LOGUEAR "Fin de Ciclo"
	fi

}


# start_daemon_recibec()
# Esta funcion lanza al demonio recibec
# Se debe frenar con el stop_daemon_recibec
# Si se sale sin frenar al demonio, se debe ejecutar el start_daemon_recibec_forzado
start_daemon_recibec(){
	
	#Se fija si esta corriendo
	if [ -f "\$F_CORRIENDO" ]
	then
		echo El demonio recibeC ya esta corriendo
		return 1
	else
	#Si no corre, lo lanza
		#Crea el archivo \$F_CORRIENDO
		echo  >"\$F_CORRIENDO"
		#Ejecuto el ciclo infinito en background
		ejecutar_ciclo &
		#Guardo el process ID en el archivo F_CORRIENDO
		# La existencia de dicho archivo, indica que el demonio esta corriendo
		echo \$! >"\$F_CORRIENDO"
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
# Borra el archivo \$F_CORRIENDO
stop_daemon_recibec(){

	if [ -f "\$F_CORRIENDO" ]
	then
		rm "\$F_CORRIENDO"
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

	if [ -f "\$F_CORRIENDO" ]
	then
		PID_ARCHIVO=\$(head -n1 "\$F_CORRIENDO")
		#Me fijo si el numero de proceso existe, y si el nombre del proceso coincide con el del demonio
		PID_ACTUAL=\$(ps -p "\$PID_ARCHIVO" | grep "\$NOMBRE_DEMONIO")
		#si el pid_actual no esta vacio
		if [ -z "\$PID_ACTUAL" ]
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

	if [ -f "\$F_CORRIENDO" ]
	then
		PID_ARCHIVO=\$(head -n1 "\$F_CORRIENDO")
		#Me fijo si el numero de proceso existe, y si el nombre del proceso coincide con el del demonio
		echo \$PID_ARCHIVO
	else
		echo "El demonio recibec no esta corriendo"
	fi
}	

#Devuelve 0 si hay archivos en ARRIBOS, 1 sino
hay_archivos(){

	resultado_archivos=\$(ls "\$D_ARRIBOS")
	#No hay archivos
	if [ -z "\$resultado_archivos" ]
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
	ls "\$D_ARRIBOS" | grep  '[0-9]\{11\}\.[0-9]\{6\}\$' >\$F_CUMPLEN
	#Guardo en TEMP2 los que no cumplen formato
	ls "\$D_ARRIBOS" | grep -v '[0-9]\{11\}\.[0-9]\{6\}\$' >\$F_NO_CUMPLEN

}


#verificar_contribuyente()
#Verifica que el contribuyente figure en la tabla de contribuyentes
# Se trabaja con el contenido del archivo \$F_CUMPLEN, ya que contiene todos los nombres
#de archivos con formato valido (evita problemas si subieron un archivo luego de que haya corrido el validar_formato())
verificar_contribuyente(){

	#Vacio el archivo de no_cumplen y el temporal
	cat >"\$F_NO_CUMPLEN"
	cat >"\$F_TEMP"

	for archivo in \$(cat "\$F_CUMPLEN")
	do		
		#Obtengo el numero de contribuyente (primeros 11 caracteres)
		contribuyente=\$(echo "\$archivo" | sed 's/^\([^\.]*\)\..*\$/\1/g')

		#Me fijo si el numero de contribuyente esta dentro del archivo de contribuyentes
		encontrado=\$(cat "\$F_TABLA_CONTRIBUYENTES" | sed 's/^\([^,]*\),\([^,]*\),.*\$/\2/g' | grep "\$contribuyente")

		#Si es vacio el nombre significa que no lo encontro
		if [ -z "\$encontrado" ]
		then
			echo \$archivo >>\$F_NO_CUMPLEN
		else
			echo \$archivo >>\$F_TEMP
		fi
	done
	
	#Guardo en el archivo F_CUMPLEN lo que esta en el temporal
	cat "\$F_TEMP" >"\$F_CUMPLEN"
	#Elimino el archivo temporal
	rm "\$F_TEMP"
}



#verificar_periodo()
#Verifica que la fecha que figura en el nombre del archivo sea mayor o igual a la que figura en 
#el archivo de contribuyentes
#HIPOTESIS: El numero de contribuyente que viene en el archivo de contribuyentes, es unico, no puede repetirse
verificar_periodo(){

	#Vacio el archivo de no_cumplen y el temporal
	cat >"\$F_NO_CUMPLEN"
	cat >"\$F_TEMP"

	for archivo in \$(cat "\$F_CUMPLEN")
	do		

		#Obtengo el numero de contribuyente (primeros 11 caracteres) (Lo uso para buscar la fecha)
		# Ya se que esta dentro del archivo porque paso la segunda validacion
		contribuyente=\$(echo "\$archivo" | sed 's/^\([^\.]*\)\..*\$/\1/g')

		#Obtengo la fecha del archivo (ultimos 6 caracteres)
		fecha_archivo=\$(echo "\$archivo" | sed 's/^\([^\.]*\)\.\(*\)*/\2/g')

		#Obtengo los registros que tengan el numero de contribuyente que busco
		# (solo puede ser uno)
		# Y de ese registro, obtengo la fecha
		fecha_contribuyente=\$(cat "\$F_TABLA_CONTRIBUYENTES" | grep "\$contribuyente" | sed 's/^\([^,]*\),\([^,]*\),\([0-9]\{6\}\).*\$/\3/g')

		#La fecha del archivo debe ser mayor o igual que la fecha que figura en contribuyente
		if [ "\$fecha_archivo" -lt "\$fecha_contribuyente" ]
		then
			echo \$archivo >>\$F_NO_CUMPLEN
		else
			echo \$archivo >>\$F_TEMP
		fi
	done
	
	#Guardo en el archivo F_CUMPLEN lo que esta en el temporal
	cat "\$F_TEMP" >"\$F_CUMPLEN"
	#Elimino el archivo temporal
	rm "\$F_TEMP"
}


#verificar_no_vencido()
#Verifica que la fecha que figura en el nombre del archivo pertenezca al rango de fechas validas
#HIPOTESIS: El numero de contribuyente que viene en el archivo de contribuyentes, es unico, no puede repetirse
verificar_no_vencido(){

	#Vacio el archivo de no_cumplen y el temporal
	cat >"\$F_NO_CUMPLEN"
	cat >"\$F_TEMP"

	for archivo in \$(cat "\$F_CUMPLEN")
	do		

		#Obtengo la fecha del archivo (ultimos 6 caracteres) (AAAAMM)
		fecha_archivo=\$(echo "\$archivo" | sed 's/^\([^\.]*\)\.\(*\)*/\2/g')

		#Obtengo el año del nombre del archivo (primeros 4 digitos)
		anio_archivo=\$(echo "\$fecha_archivo" | sed 's/^\([0-9]\{4\}\).*\$/\1/g')

		#Obtengo el mes del nombre del archivo (ultimos 2 digitos)
		mes_archivo=\$(echo "\$fecha_archivo" | sed 's/^\([0-9]\{4\}\)\([0-9]\{2\}\)\$/\2/g')

		#Obtengo el año actual AAAA
		# %Y = AAAA
		anio_actual=\$(date +%Y)

		#Obtengo el mes actual AAAA
		# %m = MM
		mes_actual=\$(date +%m)

		#Valido que el mes del archivo este en el rango 1-12
		if [ \$mes_archivo -gt 12 -o \$mes_archivo -lt 1 ]
		then
			echo \$archivo >>\$F_NO_CUMPLEN
		else
	
			#let dif_anios=\$anio_actual-\$anio_archivo
			dif_anios=\$(echo "\$anio_actual - \$anio_archivo" | bc )
			#let dif_meses=\$(echo \$mes_actual | bc ) - \$(echo \$mes_archivo | bc)
			#Analizo el valor de la dvariable diferencia
			dif_meses=\$(echo "\$mes_actual - \$mes_archivo" | bc )
			
			#Si es cero, estoy en el mismo año
			if [ \$dif_anios -eq 0 ]
			then
				#La diferencia de meses debe estar entre -1 (uno de anticipacion) y 2 (2 de antiguedad)
				if [ \$dif_meses -ge -1 -a \$dif_meses -le 2 ]
				then #CUMPLE
					echo \$archivo >>\$F_TEMP
				else #NO CUMPLE
					echo \$archivo >>\$F_NO_CUMPLEN
				fi
			#El año del archivo es un año anterior al actual. Ejemplo: Año act 2007, año arch 2006
			elif [ \$dif_anios -eq 1 ]
			then
				#La diferencia de meses debe ser -10 o -11
				#Casos permitidos:
					#Mes actual: 1	Mes archivo: 12 y 11 (1-12 = -11 && 1-11=-10)
					#Mes actual 2 	Mes archiv: 11	(1-11=-10)
				if [ \$dif_meses -eq -10 -o \$dif_meses -eq -11 ]
				then #CUMPLE
					echo \$archivo >>\$F_TEMP
				else #NO CUMPLE
					echo \$archivo >>\$F_NO_CUMPLEN
				fi
			#El año del archivo es un año posterior al actual. Ejemplo: Año act 2007, año arch 2008
			elif [ \$dif_anios -eq -1 ]
			then
				#La diferencia de meses debe ser de 11
				#Casos permitidos:
					#Mes actual: 12	Mes archivo: 1 (12-1=11)	
				if [ \$dif_meses -eq 11 ]
				then #CUMPLE
					echo \$archivo >>\$F_TEMP
				else #NO CUMPLE
					echo \$archivo >>\$F_NO_CUMPLEN
				fi
			else #NO CUMPLE
				echo \$archivo >>\$F_NO_CUMPLEN
			fi 
		fi
	done
	
	#Guardo en el archivo F_CUMPLEN lo que esta en el temporal
	cat "\$F_TEMP" >"\$F_CUMPLEN"
	#Elimino el archivo temporal
	rm "\$F_TEMP"
}




#mover_no_cumplen()
#\$1 es el nombre del archivo que se desea mover
#Mueve los archivos que no cumplen las condiciones a la carpeta norecibidos
#En caso de que ya exista en dicha carpeta un archivo con el mismo nombre, lo descarta
mover_no_cumplen(){
	
	#Si el archivo existe en no_recibidos no lo muevo, solo lo borro de arribos
	if [ -f "\$D_NORECIBIDOS"/"\$1" ]
	then
		rm "\$D_ARRIBOS"/"\$1"
	else
		mv "\$D_ARRIBOS"/"\$1" "\$D_NORECIBIDOS"
	fi

}	

#mover_cumplen()
#\$1 es el nombre del archivo que se desea mover
#Mueve los archivos que cumplen las condiciones a la carpeta recibidos
#En caso de que ya exista en dicha carpeta un archivo con el mismo nombre, le agrega un numero de secuencia 
# al final y lo mueve a no recibidos
mover_cumplen(){
	
	nombre_archivo="\$1"
	#En lista obtengo todos los archivos que tienen el mismo nombre que el que debo guardar
	lista=\$(ls "\$D_RECIBIDOS" | grep  "\$1")

	#Si no existe, lo mando a RECIBIDOS
	if [ -z "\$lista" ]
	then
		mv "\$D_ARRIBOS"/"\$1" "\$D_RECIBIDOS"/"\$nombre_archivo"
		#No se debe modificar el nombre del archivo
		\$C_LOGUEAR "Archivo Recibido "\$nombre_archivo""
	else
		#Esta repetido, lo mando a NO_RECIBIDOS con su numero de secuencia
		nsecuencia=1
		lista2=\$(ls "\$D_NORECIBIDOS" | grep  "\$1")
		for archivos in "\$lista2"
		do
			let nsecuencia=nsecuencia+1
		done # Fin del recorrido de archivos
		
		#El nombre del archivo destino se debe modificar
		nombre_archivo="\$1".\$nsecuencia
		mv "\$D_ARRIBOS"/"\$1" "\$D_NORECIBIDOS"/"\$nombre_archivo"
		\$C_LOGUEAR "Archivo Duplicado "\$nombre_archivo""
	fi

}	

#Arranque en modo automatico
arranque_automatico(){
	#Arranca desde el iniciaC
	#Me fijo el estado del demonio recibeC
	ps_daemon_recibec
	resultado="\$?"
	if [ "\$resultado" = 0 ]
	then
	#No esta corriendo, lo lanzo
		start_daemon_recibec
	elif [ "\$resultado" = 1 ]
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

	if [ "\$#" -ne 1 -o -z "\$1" ]
	then
		echo "Uso: recibeC parametro"
		echo
		return 1
	fi


	if [ "\$1" = "start" ]
	then
		echo "Lanzando demonio recibeC"
		start_daemon_recibec
	elif [ "\$1" = "stop" ]
	then
		echo "Frenando demonio recibeC"
		stop_daemon_recibec
	elif [ "\$1" = "id" ]
	then
		echo "Id del demonio recibeC: " get_id_demonio_recibec
	elif [ "\$1" = "status" ]
	then
		ps_daemon_recibec
		if [ "\$?" = 0 ]
		then
			echo "El demonio recibeC no esta corriendo"
		elif  [ "\$?" = 1 ]
		then
			echo "El demonio recibeC esta corriendo"
		else
			echo "El demonio fue terminado bruscamente (para lanzar usar el parametro start_forzado)"
		fi

	elif [ "\$1" = "start_forzado" ]
	then
		echo "Lanzando demonio recibeC en forma forzada"
		start_daemon_recibec_forzado
	elif [ "\$1" = "help" ]
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
if [ "\$AUTO" = "SI" ]
then
	arranque_automatico
elif [ "\$AUTO" = "NO" ]
then
	arranque_manual "\$1"
else
	echo "Primero se debe ejecutar el comando iniciaC"
fi
!
chmod -f 777 $(pwd)/$grupo/recibeC.sh


echo " >>> Creando $(pwd)/$grupo/iniciaC."
cat << ! >> $(pwd)/$grupo/iniciaC
#! /usr/bin/bash

#!/bin/bash 

#------------------------------------------------------------------------------------------------------------

#PRECONDICIONES:
#Se setean las variables de entorno adecuadas para la ejecucion del tp. 
#Se verifica la version de perl instalada y se inicia el comando recibeC en caso de que no se esté ejecutando.


#POSCONDICIONES:
#Imprime por salida standard los avisos correspondientes a cada ejecucion. Si ocurre algún error termina con codigod e error distinto de 0. En caso contrario, igual a 0.


#VARIABLES GLOBALES---------------------------------------------------------------------------------------------

error_perl='************************************************************
* Para Iniciar el proceso de control de altas              *
* es necesario tener instalado Perl 5 o superior.          *
* Efectue su instalacion e intentelo nuevamente            *
************************************************************'

error_iniciar=' ****** ******  ******  ******  ******  
**     **  **  **  **  **  **  **  **  
****** *****   *****   **  **  *****   
**     **  **  **  **  **  **  **  **  
****** **   ** **   ** ******  **   **   '


#-----------------------------------------------------FUNCIONES-------------------------------------------------

#Precondiciones:
#Verifica la version de perl instalada en el sistema operativo en que se corre el comando.

#Condiciones:
#Si la version es igual o mas nueva que la 5, devuelve una cadena (por salida standard) con la version de perl instalada y retorno con codigo igual a 0. Si la version es mas vieja o no estuviera instalado perl, se devuelve un aviso con el error y termina con codigo distinto de 0.

#verificar Perl
verificarPerl()
{

	perl_instalado=\$(which perl)
	if [ ! -z \$perl_instalado ]
	then
		perl_version=\$(perl -v)
		perl_version=\$(echo \$perl_version | cut -d ' ' -f4)
		perl_version_comp=\$(echo \$perl_version | cut -c 2-2)
		if [ \$perl_version_comp -ge "5" ]
		then
			echo "*****************************************************************
* 'Version de perl instalada: '\$perl_version		       		*
*****************************************************************"
			return 0
		else
			echo "\$error_perl"
			return 1
		fi 
	else
		echo "\$error_perl"
		return 1
	fi

}

#------------------------------------------------------------------------------------------------------------


#Poscondiciones:
#Devuelve 0 si la fecha del sistema es mayor a 2007-09, sino devuelve 0.

verificarFecha()
{
	if [ \$(date '+%Y') -ge 2008 ]
	then
		return 0;
	elif [ \$(date '+%Y') -ge 2007 ]
	then
		if [ \$(date '+%m') -ge 10 ]
		then
			return 0;
		elif [ \$(date '+%m') -ge 09 ]
		then
			if [ \$(date '+%d') -ge 26 ]
			then
				return 0;
			else
			return 1;
			fi
		else
			return 1;
		fi
	else
		return 1;
	fi
}

#------------------------------------------------------------------------------------------------------------


#Precondiciones:
#Inicia el comando recibeC.

#Poscondiciones:
#Si el comando ya esta corriendo, muestra por pantalla un mensaje que indica cuanto hace que se esta corriendo. Si el comando no esta corriendo y la corrida es manual, no se hace nada. Si el comando no se esta ejecutando y la corrida es automatica se invoca al comando recibeC y muestra un mensaje indicando el processID del comando recibeC.

iniciarrecibeC()

{
	comando_a_verificar="recibeC"
	comando=\$(ps | grep "\$comando_a_verificar")
	if [ -z "\$comando" ]
	then
		if [ "\$AUTO" = SI ];
		then
			recibeC.sh
			if [ "\$?" -eq 0 ]; then
				comando=\$(ps | grep \$comando_a_verificar)
				id=\$(echo \$comando | cut -d ' ' -f1)
				echo "****************************************************************
* \$comando_a_verificar corriendo bajo el número: \$id	       *
****************************************************************"
				return 0
			else
				return 1
			fi
		else
			return 0
		fi
	else
		tiempo_corriendo=\$(ps -e | grep \$comando_a_verificar | cut -c15-23)
		echo "el comando recibeC se se encuentra corriendo hace \$tiempo_corriendo"
		return 0
	fi

}

#---------------------------------------------------PRINCIPAL------------------------------------------------
directorio_Actual=\$(history | tail -n2)
dir_Actual1=\$(echo \$directorio_Actual | sed 's/.*\.\(.*\)/\1/')
dir_Actual=\$(echo \$dir_Actual1 | sed 's/\(.*\)\/.*\/\{1\}IniciaC/\1/')


if [ "\$dir_Actual" = 'iniciaC' ]
then
	GRUPO=\$(pwd | sed 's/\(.*\)\/iniciaC/\1/')
else
	if [ "\$dir_Actual" = '/iniciaC' ]
	then
		GRUPO=\$(pwd)
	else
		if [ \$PWD = "/" ]
		then
			GRUPO=\$(pwd)\$dir_Actual
		else
			aux=\$(pwd)/\$dir_Actual
			GRUPO=\$(echo \$aux | sed 's/\(.*\)\/iniciaC/\1/')
		fi
	fi
fi
echo "\$GRUPO"

if [[ -d \$GRUPO && -d \$GRUPO/tablas && -d \$GRUPO/arribos && -d \$GRUPO/prueba && -d \$GRUPO/log && -d \$GRUPO/norecibidos && -d \$GRUPO/recibidos &&  -d \$GRUPO/ivaC && -d \$GRUPO/consultas && -d \$GRUPO/recibidos/procesados ]]
then

	#setear variables de ambiente
	export GRUPO
	export PATH=\$PATH:\$GRUPO
	export DORMIR=5

#	ARCHVA=\$GRUPO/datos/varsAmbiente
	
#	if [ -f \$ARCHVA ]
#	then
#		periodo=\$(grep "periodo=" \$ARCHVA | cut -d '=' -f2)
#	else
#		PERIODO=200703
#		echo "periodo="\$PERIODO >> \$ARCHVA
		
#	fi

#	export periodo=\$PERIODO
	
	#seteo permisos para los comandos y el resto de los archivos
	chmod -R ugo+r *
	chmod ugo+x *
	#verifico fecha ddel sistema
	verificarFecha
	if [ "\$?" = 0 ]
	then
		echo "Fecha valida \$(date '+%d/%m/%Y')"
		salida=0
		verificarPerl
		if [ "\$?" = 0 ]
		then
			echo "Ingrese el tipo de corrida"
			echo "a - AUTO"
			echo "b - MANUAL"
			opcion=c
			while [ "\$opcion" != a -a "\$opcion" != A ]&&[ "\$opcion" != b -a "\$opcion" != B ]
			do
				read opcion	
				if [ -n "\$opcion" ]
				then
					echo "opcion ingresada \$opcion."
					if [ \$opcion = a -o \$opcion = A ]
					then
						AUTO=SI
						echo "Corrida Automatica"
					elif [ \$opcion = b -o \$opcion = B ]
					then
						AUTO=NO
						echo "Corrida Manual"
					else
						echo "Opcion no valida"
					fi
				fi
			done
			export AUTO
			iniciarrecibeC
			if [ "\$?" = 0 ]
			then
				salida=0
			else
				echo "RecibeC sale con Errores"
				salida=1
			fi
		else
			echo "Error de Perl"
			salida=1
		fi
	else
		echo "La fecha del sistema no es correcta"
	fi
else
	echo Los directorios de trabajo no estan creados correctamente
	salida=1
fi


#exit \$salida
#------------------------------------------------------------------------------------------------------------
!
chmod -f 777 $(pwd)/$grupo/iniciaC


echo " >>> Creando $(pwd)/$grupo/consulC.pl."
cat << ! >> $(pwd)/$grupo/consulC.pl
#! /usr/bin/perl
#!usr/bin/perl
use Env; 

############################  ACLARACION DE PASAJE DE PARAMETROS ##########################
#	Sintaxis del comando TPListar.pl

#	ConsulC -h  -> Ayuda de uso del comando

#	ConsulC -1 aaaamm -> Listado de Contribuyentes declarantes en el período aaaamm

#	ConsulC -2 aaaamm aaaamm -> Listado de Compras Declaradas desde aaaamm hasta aaaamm

#	ConsulC -w -[1-2] aaaamm aaaamm -> El listado se almacena en el directorio consultas con el nombre del periodo. Si hay problemas con el path la salida sera la standard


%resultadoConsulta;

@paramValidados;

\$tipoConsulta;


#Se obtiene el tipo de consulta, los parametros segun el tipo y se establece la salida estandard
&validarParametros;


if(\$tipoConsulta==1 || \$tipoConsulta==2)
{
	#Si la consulta es valida se la resuelve
	&resolverConsulta(\$tipoConsulta,\$paramValidados[0],\$paramValidados[1]);
	&mostrarConsulta(\$tipoConsulta);
}
elsif(\$tipoConsulta==0)
{
	#Salida de ayuda
	print("Uso del comando: \n \tConsulC -h	-->  Ayuda de uso del comando\n");

	print("\tConsulC -1 aaaamm --> Listado de Contribuyentes declarantes en el período aaaamm\n");

	print("\tConsulC -2 aaaamm aaaamm --> Listado de Compras Declaradas desde aaaamm hasta aaaamm\n");

	print("\tConsulC -w -[1-2] aaaamm aaaamm --> El listado se almacena en el directorio consultas con el nombre del período. Si hay problemas con el path la salida sera la standard \n");

}
else
{
	#Si hubo error en la consulta se informa
	print("Error en los parametros. Ingrese -h \n");
	exit -1;
}

exit 0;


# Función que valida los parametros. 
# Establece los valores de:
# \$tipoConsulta:
				#2 Consulta por período
				#1 Consulta por contribuyentes
				#0 Ayúda de uso del comando
				#-1 Error en el uso del comando

# @paramValidados:
				#vector con los parametros validos, segun el tipo de consulta
				
sub validarParametros()
{
	
  \$argc=@ARGV;
	\$tipoConsulta=-1;

	if(\$argc==1)
	{
		if(@ARGV[0] eq "-h")
		{
			\$tipoConsulta=0;
		
		}
	}

  elsif(\$argc==2)
	{
    if(@ARGV[0] eq "-1" && length(@ARGV[1])==6 )
		{
			\$tipoConsulta=1;
			
			\$paramValidados[0]=@ARGV[1];
		}
	}

	elsif(\$argc==3)
	{
  	if(@ARGV[0] eq '-2' && length(@ARGV[1])==6 && length(@ARGV[2])==6)
		{
			\$tipoConsulta=2;
			\$paramValidados[0]=@ARGV[1];
			\$paramValidados[1]=@ARGV[2];
		}
	
		elsif(@ARGV[0] eq '-w' && @ARGV[1] eq '-1' && length(@ARGV[2])==6)  
		{
			\$tipoConsulta=1;
			\$paramValidados[0]=@ARGV[2];
			open STDOUT, "> \$GRUPO/consultas/\$paramValidados[0]";
		}
	}
	
	elsif(\$argc == 4)
	{
		if(@ARGV[0] eq '-w' && @ARGV[1] eq '-2' && length(@ARGV[2])==6 && length(@ARGV[3])==6) 
		{
			\$tipoConsulta=2;
			\$paramValidados[0]=@ARGV[2];
			\$paramValidados[1]=@ARGV[3];
			open STDOUT, "> \$GRUPO/consultas/\$paramValidados[0]To\$paramValidados[1]";
			
		}
	}

}

# Función que resuelve la consulta
# Establece los valores de las variables:			
# %resultConsulta:
			#Segun el tipo de consulta las claves seran el contriibuyente o el período. 
			#Los valores seran otra hash con lo acumulado de gravado e impuestoLiquidado
# Parametros:
			#\$_[0] : tipo de consulta
			#\$_[1-2]: Período/s
    
sub resolverConsulta
{
	opendir(DIR, "\$GRUPO/ivaC");

	# Se establece la expresion para leer tomar los archivos segun el tipo de consulta 
	if(\$_[0]==1)
	{
		\$pattern="\$_[1]\\$";
	}
	else
	{
		\$pattern="\([0-9]\{4\}\)\([01][0-9]\)\\$";
	}

	@lista_archivos = sort(grep(/\$pattern/,readdir(DIR)));
	closedir(DIR);
	
	foreach \$arch(@lista_archivos)
	{
		open(ARCH,"\$GRUPO/ivaC/\$arch");
		@registros=<ARCH>;
		
		if(\$_[0]==2)
		{
			#si es del tipo de consulta 2, se compara el rango de períodos			
			if( (\$arch < \$_[1]) || (\$arch > \$_[2])  )
			{
				close(ARCH);
				next;
			}
			# La clave de la consulta es el período, que es el nombre del archivo
			\$claveConsulta=\$arch;
		}
		
		foreach \$linea(@registros)
		{
			@data=split(/,/,\$linea);
			if(\$_[0]==1)
			{
				# Si es un tipo de consulta 1 la clave de la misma es el contribuyente
				\$claveConsulta=\$data[0];
			}
			
			#Preparo los campos que se procesan en la resolucion de la consulta
			%campos= 	(
								'tipoComp'=>\$data[2],
								'importeNetoGravado'=>\$data[6],
								'impuestoLiquidado'=>\$data[7]
								);

			# Se agregan los campos segun la clave de la consulta
			&agregarRegistro(\$claveConsulta, \%campos);
		}
		close(ARCH);	
	}
}

#Función auxiliar de resolverConsulta
#Parametros:
			#\$_[0] : clave de la consulta (puede ser un período o un contribuyente)
			#\$_[1] : referencia a hash que posee los campos tipo de comprobante, importe neto gravado e impuesto liquidado

sub agregarRegistro
{
	my(\$claveConsulta, %campos);
	\$claveConsulta=\$_[0]; \$campos=\$_[1];
	
	# Valores que se procesan segun la clave

	if(\$\$campos{'tipoComp'} eq 'C')
	{
		%{\$resultadoConsulta{\$claveConsulta}}->{'totalOperacionesGravadas'}+=\$\$campos{'importeNetoGravado'};					
		%{\$resultadoConsulta{\$claveConsulta}}->{'totalImpuestoLiquidado'}+=\$\$campos{'impuestoLiquidado'};
	}
	else
	{
		%{\$resultadoConsulta{\$claveConsulta}}->{'totalOperacionesGravadas'}-=\$\$campos{'importeNetoGravado'};					
		%{\$resultadoConsulta{\$claveConsulta}}->{'totalImpuestoLiquidado'}-=\$\$campos{'impuestoLiquidado'};
	}
	

	#Valores de utilizados para calcular el pie del listado. 
	\$resultadoConsulta{'totalGravado'}+=\$\$campos{'importeNetoGravado'};					
	\$resultadoConsulta{'totalLiquidado'}+=\$\$campos{'impuestoLiquidado'};

}

#Función que muestra el listado, en el archivo de salida especificado, el resultado de la consulta 
#Parametros:
			#\$_[0] : Tipo de consulta

sub mostrarConsulta
{

	@fechaActual= localtime;
	\$indiceLeyenda;
	@periodo1=(substr(\$paramValidados[0],4), substr(\$paramValidados[0],0,4));
	@periodo2;

	if(\$_[0]==1)
	{
		\$indiceLeyenda=0;
	}
	else
	{
		@periodo2=(substr(\$paramValidados[1],4), substr(\$paramValidados[1],0,4));
		\$indiceLeyenda=1;
	}

	@tituloListado=("Listado de contribuyentes declarantes en el período \$periodo1[0]-\$periodo1[1] " , "Listado de Compras Declaradas desde \$periodo1[0]-\$periodo1[1] hasta \$periodo2[0]-\$periodo2[1]");
	@cabeceraListado=("Contribuyente:" , "Período:");
	@tituloPiePag=("Cantidad de Contribuyentes: " , "Cantidad de Períodos: ");

	print("\$fechaActual[3]-\$fechaActual[4] \n");
	print("\$tituloListado[\$indiceLeyenda] \n");
	foreach(keys %resultadoConsulta)
	{
		if( !(\$_ eq 'totalGravado') && !(\$_ eq 'totalLiquidado'))
		{
			\$rclave=\$resultadoConsulta{\$_};
			print("\$cabeceraListado[\$indiceLeyenda] \$_ \n");
			print("Suma total de Operaciones Gravadas \t");print( %{\$rclave}->{totalOperacionesGravadas} . "\n");
			print("Suma total de Impuesto Liquidado \t");print( %{\$rclave}->{totalImpuestoLiquidado} . "\n\n\n");
		}
	}

	\$totalConsulta=keys %resultadoConsulta;
	\$totalConsulta-=2;
	if(\$totalConsulta>0)
	{
		\$promedioGravado=  \$resultadoConsulta{'totalGravado'}/\$totalConsulta;
		\$promedioLiquidado=  \$resultadoConsulta{'totalLiquidado'}/\$totalConsulta;
	}
	else
	{
		\$totalConsulta=0;
		\$promedioGravado=  0;
		\$promedioLiquidado=  0;
	}
	
	print("\n\n\n\n");
	print("\$tituloPiePag[\$indiceLeyenda] \$totalConsulta \n");
	print("Promedio de Gravadas: \$promedioGravado \n");
	print("Promedio de Impuesto: \$promedioLiquidado \n");

	close STDOUT;
}
!
chmod -f 777 $(pwd)/$grupo/consulC.pl


echo " >> Archivos de comandos creados correctamente."


echo ""
echo ""
echo " >> Generando archivos de datos."


echo ">>> Creando $(pwd)/$grupo/tablas/cpbt.txt"
cat << ! >> $(pwd)/$grupo/tablas/cpbt.txt
01234567890,F,00001,00003
01234567890,C,00001,00012
34567890123,F,00001,00111
34567890123,C,00001,00111
34567890123,D,00001,00001
45678901234,D,00001,10101
56789012345,C,00001,12424
67890123456,F,00001,99981
78901234567,C,00001,12458
!
chmod -f 666 $(pwd)/$grupo/tablas/cpbt.txt


echo ">>> Creando $(pwd)/$grupo/tablas/ctbyt.txt"
cat << ! >> $(pwd)/$grupo/tablas/ctbyt.txt
Pepe Araos,12345678901,20071212,asd3@asd.com
Jose Esquivo,23456789012,20071201,asd3@asd.com
Armando Esteban Quito,22222222222,20070908,asd2@asd.com
Niels Bhor,11122112232,20070908,asd2@asd.com
Manuel Perea,33333333333,20071008,nnn@nomail.com
Jose Perez,11111111111,20071005,asd@asd.com
Enrique Savio,44444444444,20070918,nnn@nomail.com
Alberto Gonzales,01234567890,20001103,nnn@nomail.com
Roberto Insua,34567890123,20001203,nnn@nomail.com
Ignacio Rodriguez,45678901234,20000203,nnn@nomail.com
Esteban Zeta,56789012345,20000403,nnn@nomail.com
Waldorf Osorio,67890123456,20011003,nnn@nomail.com
Guillermo Cardozo,78901234567,20031003,nnn@nomail.com
!
chmod -f 666 $(pwd)/$grupo/tablas/ctbyt.txt


echo ">>> Creando $(pwd)/$grupo/prueba/0123456789.200309"
cat << ! >> $(pwd)/$grupo/prueba/0123456789.200309
01234567890,Alberto Gonzales,F,00001,05-08-2003,4559.465,27,1231.055,4063.286,9853.806
01234567890,Alberto Gonzales,F,00002,05-08-2003,4135.317,27,1116.535,4215.701,9467.553
01234567890,Alberto Gonzales,F,00003,05-08-2003,4927.877,21,1034.854,7483.901,27,2020.653,10177.112,21,2137.193,2835.681,30617.271
01234567890,Alberto Gonzales,F,00004,05-08-2003,8295.744,27,2239.850,9133.775,19669.369
01234567890,Alberto Gonzales,F,00005,05-08-2003,8601.766,10.5,903.185,8363.785,21,1756.394,6402.253,10.5,672.236,5460.85,32160.469
01234567890,Alberto Gonzales,F,00006,05-08-2003,8722.695,10.5,915.882,1338.926,10977.503
01234567890,Alberto Gonzales,F,00007,05-08-2003,7623.746,27,2058.411,4113.767,13795.924
01234567890,Alberto Gonzales,F,00008,05-08-2003,9027.974,21,1895.874,8611.621,19535.469
01234567890,Alberto Gonzales,D,00009,05-08-2003,9271.208,10.5,973.476,3372.727,10.5,354.136,6991.906,21,1468.300,3310.871,25742.624
01234567890,Alberto Gonzales,F,00010,05-08-2003,7941.219,21,1667.655,8370.284,17979.158
01234567890,Alberto Gonzales,F,00011,05-08-2003,2783.180,21,584.467,7231.264,21,1518.565,8049.576,21,1690.410,5472.138,27329.600
01234567890,Alberto Gonzales,F,00012,05-08-2003,3143.742,21,660.185,6325.93,27,1708.001,967.415,10.5,101.578,3917.332,16824.183
01234567890,Alberto Gonzales,D,00013,05-08-2003,7513.903,21,1577.919,10058.90,21,2112.369,1476.173,10.5,154.998,2133.350,25027.612
01234567890,Alberto Gonzales,F,00014,05-08-2003,8231.982,27,2222.635,8719.747,19174.364
01234567890,Alberto Gonzales,F,00015,05-08-2003,8943.406,10.5,939.057,9346.175,19228.638
01234567890,Alberto Gonzales,F,00016,05-08-2003,6736.212,27,1818.777,8003.90,16558.889
01234567890,Alberto Gonzales,F,00017,05-08-2003,2891.539,10.5,303.611,9423.443,12618.593
01234567890,Alberto Gonzales,F,00018,05-08-2003,1873.618,27,505.876,2064.534,21,433.552,8256.268,27,2229.192,8108.77,23471.810
01234567890,Alberto Gonzales,F,00019,05-08-2003,6120.468,27,1652.526,6585.498,27,1778.084,2364.622,27,638.447,4627.778,23767.423
01234567890,Alberto Gonzales,F,00020,05-08-2003,9827.385,10.5,1031.875,8196.532,10.5,860.635,4985.851,27,1346.179,3765.453,30013.910
01234567890,Alberto Gonzales,F,00021,05-08-2003,6610.227,21,1388.147,2570.116,10568.490
01234567890,Alberto Gonzales,C,00022,05-08-2003,2897.472,10.5,304.234,6948.305,10150.011
01234567890,Alberto Gonzales,F,00023,05-08-2003,1197.519,10.5,125.739,7230.363,8553.621
01234567890,Alberto Gonzales,F,00024,05-08-2003,2638.911,10.5,277.085,2291.734,5207.730
01234567890,Alberto Gonzales,F,00025,05-08-2003,4818.788,27,1301.072,8121.768,10.5,852.785,707.449,21,148.564,1571.161,17521.587
01234567890,Alberto Gonzales,F,00026,05-08-2003,1489.716,27,402.223,1839.162,3731.101
01234567890,Alberto Gonzales,C,00027,05-08-2003,10006.232,21,2101.308,10399.435,27,2807.847,3174.682,21,666.683,2327.902,31484.089
01234567890,Alberto Gonzales,F,00028,05-08-2003,9468.6,10.5,994.203,1157.565,11620.368
01234567890,Alberto Gonzales,F,00029,05-08-2003,3993.62,21,838.660,1201.933,27,324.521,6756.347,27,1824.213,9271.944,24211.238
01234567890,Alberto Gonzales,F,00030,05-08-2003,4581.686,27,1237.055,7120.604,21,1495.326,9081.68,27,2452.053,5663.468,31631.872
01234567890,Alberto Gonzales,F,00031,05-09-2003,4581.686,27,1237.055,7120.604,21,1495.326,9081.68,27,2452.053,5663.468,31631.872
01234567890,Alberto Gonzales,F,00032,05-10-2003,4581.686,27,1237.055,7120.604,21,1495.326,9081.68,27,2452.053,5663.468,31631.872
01234567890,Alberto Gonzales,W,00033,05-08-2003,3993.62,21,838.660,1201.933,27,324.521,6756.347,27,1824.213,9271.944,24211.238
!
chmod -f 666 $(pwd)/$grupo/prueba/0123456789.200309


echo ">>> Creando $(pwd)/$grupo/prueba/01234567890.200710"
cat << ! >> $(pwd)/$grupo/prueba/01234567890.200710
01234567890,Alberto Gonzales,F,00001,05-09-2007,4559.465,27,1231.055,4063.286,9853.806
01234567890,Alberto Gonzales,F,00002,05-09-2007,4135.317,27,1116.535,4215.701,9467.553
01234567890,Alberto Gonzales,F,00003,05-09-2007,4927.877,21,1034.854,7483.901,27,2020.653,10177.112,21,2137.193,2835.681,30617.271
01234567890,Alberto Gonzales,F,00004,05-09-2007,8295.744,27,2239.850,9133.775,19669.369
01234567890,Alberto Gonzales,F,00005,05-09-2007,8601.766,10.5,903.185,8363.785,21,1756.394,6402.253,10.5,672.236,5460.85,32160.469
01234567890,Alberto Gonzales,F,00006,05-09-2007,8722.695,10.5,915.882,1338.926,10977.503
01234567890,Alberto Gonzales,F,00007,05-09-2007,7623.746,27,2058.411,4113.767,13795.924
01234567890,Alberto Gonzales,F,00008,05-09-2007,9027.974,21,1895.874,8611.621,19535.469
01234567890,Alberto Gonzales,D,00009,05-09-2007,9271.208,10.5,973.476,3372.727,10.5,354.136,6991.906,21,1468.300,3310.871,25742.624
01234567890,Alberto Gonzales,F,00010,05-09-2007,7941.219,21,1667.655,8370.284,17979.158
01234567890,Alberto Gonzales,F,00011,05-09-2007,2783.180,21,584.467,7231.264,21,1518.565,8049.576,21,1690.410,5472.138,27329.600
01234567890,Alberto Gonzales,F,00012,05-09-2007,3143.742,21,660.185,6325.93,27,1708.001,967.415,10.5,101.578,3917.332,16824.183
01234567890,Alberto Gonzales,D,00013,05-09-2007,7513.903,21,1577.919,10058.90,21,2112.369,1476.173,10.5,154.998,2133.350,25027.612
01234567890,Alberto Gonzales,F,00014,05-09-2007,8231.982,27,2222.635,8719.747,19174.364
01234567890,Alberto Gonzales,F,00015,05-09-2007,8943.406,10.5,939.057,9346.175,19228.638
01234567890,Alberto Gonzales,F,00016,05-09-2007,6736.212,27,1818.777,8003.90,16558.889
01234567890,Alberto Gonzales,F,00017,05-09-2007,2891.539,10.5,303.611,9423.443,12618.593
01234567890,Alberto Gonzales,F,00018,05-09-2007,1873.618,27,505.876,2064.534,21,433.552,8256.268,27,2229.192,8108.77,23471.810
01234567890,Alberto Gonzales,F,00019,05-09-2007,6120.468,27,1652.526,6585.498,27,1778.084,2364.622,27,638.447,4627.778,23767.423
01234567890,Alberto Gonzales,F,00020,05-09-2007,9827.385,10.5,1031.875,8196.532,10.5,860.635,4985.851,27,1346.179,3765.453,30013.910
01234567890,Alberto Gonzales,F,00021,05-09-2007,6610.227,21,1388.147,2570.116,10568.490
01234567890,Alberto Gonzales,C,00022,05-09-2007,2897.472,10.5,304.234,6948.305,10150.011
01234567890,Alberto Gonzales,F,00023,05-09-2007,1197.519,10.5,125.739,7230.363,8553.621
01234567890,Alberto Gonzales,F,00024,05-09-2007,2638.911,10.5,277.085,2291.734,5207.730
01234567890,Alberto Gonzales,F,00025,05-09-2007,4818.788,27,1301.072,8121.768,10.5,852.785,707.449,21,148.564,1571.161,17521.587
01234567890,Alberto Gonzales,F,00026,05-09-2007,1489.716,27,402.223,1839.162,3731.101
01234567890,Alberto Gonzales,C,00027,05-09-2007,10006.232,21,2101.308,10399.435,27,2807.847,3174.682,21,666.683,2327.902,31484.089
01234567890,Alberto Gonzales,F,00028,05-09-2007,9468.6,10.5,994.203,1157.565,11620.368
01234567890,Alberto Gonzales,F,00029,05-09-2007,3993.62,21,838.660,1201.933,27,324.521,6756.347,27,1824.213,9271.944,24211.238
01234567890,Alberto Gonzales,F,00030,05-09-2007,4581.686,27,1237.055,7120.604,21,1495.326,9081.68,27,2452.053,5663.468,31631.872
01234567890,Alberto Gonzales,F,00031,05-09-2007,4581.686,27,1237.055,7120.604,21,1495.326,9081.68,27,2452.053,5663.468,31631.872
01234567890,Alberto Gonzales,F,00032,05-12-2007,4581.686,27,1237.055,7120.604,21,1495.326,9081.68,27,2452.053,5663.468,31631.872
01234567890,Alberto Gonzales,W,00033,05-09-2007,3993.62,21,838.660,1201.933,27,324.521,6756.347,27,1824.213,9271.944,24211.238
!
chmod -f 666 $(pwd)/$grupo/prueba/01234567890.200710


echo ">>> Creando $(pwd)/$grupo/prueba/11111111111.200711"
cat << ! >> $(pwd)/$grupo/prueba/11111111111.200711
11111111111,Jose Perez,F,00001,11-09-2007,8315.461,27,2245.174,7068.918,17629.553
11111111111,Jose Perez,F,00002,11-09-2007,2071.232,27,559.232,7290.148,9920.612
11111111111,Jose Perez,F,00003,11-09-2007,4371.155,21,917.942,624.287,5913.384
11111111111,Jose Perez,F,00004,11-09-2007,5700.956,21,1197.200,1743.68,8641.836
11111111111,Jose Perez,F,00005,11-09-2007,8630.290,10.5,906.180,10360.214,19896.684
11111111111,Jose Perez,D,00006,11-09-2007,4545.646,27,1227.324,1527.472,7300.442
11111111111,Jose Perez,F,00007,11-09-2007,6397.662,21,1343.509,3073.875,27,829.946,1645.727,21,345.602,8789.432,22425.753
11111111111,Jose Perez,F,00008,11-09-2007,6620.71,10.5,695.174,3918.642,11234.526
11111111111,Jose Perez,F,00009,11-09-2007,698.89,21,146.766,9442.930,10288.586
11111111111,Jose Perez,F,00010,11-09-2007,600.886,27,162.239,7901.452,8664.577
11111111111,Jose Perez,F,00011,11-09-2007,9230.249,21,1938.352,8963.185,20131.786
11111111111,Jose Perez,C,00012,11-09-2007,2312.321,10.5,242.793,9180.837,11735.951
11111111111,Jose Perez,F,00013,11-09-2007,1070.229,21,224.748,2856.307,4151.284
11111111111,Jose Perez,F,00014,11-09-2007,6621.826,27,1787.893,551.856,8961.575
11111111111,Jose Perez,F,00015,11-09-2007,10043.480,10.5,1054.565,3579.337,14677.382
11111111111,Jose Perez,F,00016,11-09-2007,7143.465,27,1928.735,4608.192,13680.392
11111111111,Jose Perez,F,00017,11-09-2007,3443.32,27,929.696,7559.714,11932.730
11111111111,Jose Perez,F,00018,11-09-2007,7017.352,21,1473.643,4891.922,13382.917
11111111111,Jose Perez,F,00019,11-09-2007,1916.116,10.5,201.192,5328.527,7445.835
11111111111,Jose Perez,F,00020,11-09-2007,5877.299,27,1586.870,10310.460,17774.629
11111111111,Jose Perez,F,00020,11-09-2007,5877.2995,27,1586.871,0,7464.171
!
chmod -f 666 $(pwd)/$grupo/prueba/11111111111.200711


echo ">>> Creando $(pwd)/$grupo/prueba/11111111111.20071101"
cat << ! >> $(pwd)/$grupo/prueba/11111111111.20071101
12345678901,Pepe Araos,F,412547,01-10-2007,1001,27,270.27,1002,21,210.42,1004,10.5,105.42,2000,5593.11
12345678901,Pepe Araos,F,412547,01-10-2007,0.123,21,0.03,0.50,10.5,0.05,100,100.703
!
chmod -f 666 $(pwd)/$grupo/prueba/11111111111.20071101


echo ">>> Creando $(pwd)/$grupo/prueba/12124578896.200711"
cat << ! >> $(pwd)/$grupo/prueba/12124578896.200711
12345678901,Pepe Araos,F,412547,01-10-2007,1001,27,270.27,1002,21,210.42,1004,10.5,105.42,2000,5593.11
12345678901,Pepe Araos,F,412547,01-10-2007,0.123,21,0.03,0.50,10.5,0.05,100,100.703
!
chmod -f 666 $(pwd)/$grupo/prueba/12124578896.200711


echo ">>> Creando $(pwd)/$grupo/prueba/12345.200710"
cat << ! >> $(pwd)/$grupo/prueba/12345.200710
45678901234,Ignacio Rodriguez,F,00001,05-08-2004,5375.389,10.5,564.415,5896.430,10.5,619.125,9986.2,21,2097.102,3890.564,28429.225
45678901234,Ignacio Rodriguez,F,00002,05-08-2004,3281.942,27,886.124,2149.10,10.5,225.655,533.944,21,112.128,9303.850,16492.743
45678901234,Ignacio Rodriguez,F,00003,05-08-2004,9068.30,27,2448.441,3699.538,15216.279
45678901234,Ignacio Rodriguez,F,00004,05-08-2004,10434.436,27,2817.297,3580.503,10.5,375.952,6021.49,10.5,632.256,2643.756,26505.690
45678901234,Ignacio Rodriguez,D,00005,05-08-2004,8138.389,27,2197.365,3068.333,27,828.449,6950.98,21,1459.705,8223.529,30866.750
45678901234,Ignacio Rodriguez,F,00006,05-08-2004,753.723,21,158.281,4985.251,27,1346.017,3629.248,10.5,381.071,4246.887,15500.478
45678901234,Ignacio Rodriguez,F,00007,05-08-2004,746.158,10.5,78.346,7014.190,7838.694
45678901234,Ignacio Rodriguez,F,00008,05-08-2004,2926.644,21,614.595,2617.695,27,706.777,3498.568,27,944.613,2426.97,13735.862
45678901234,Ignacio Rodriguez,F,00009,05-08-2004,1178.206,27,318.115,8836.941,10333.262
45678901234,Ignacio Rodriguez,F,00010,05-08-2004,10460.776,10.5,1098.381,9290.127,10.5,975.463,7201.210,21,1512.254,6577.650,37115.861
45678901234,Ignacio Rodriguez,F,00011,05-08-2004,5102.21,10.5,535.732,10298.475,10.5,1081.339,2503.730,21,525.783,587.362,20634.631
45678901234,Ignacio Rodriguez,D,00012,05-08-2004,4363.828,27,1178.233,8914.69,14456.751
45678901234,Ignacio Rodriguez,F,00013,05-08-2004,6576.61,27,1775.684,7007.612,27,1892.055,2070.627,21,434.831,10431.346,30188.765
45678901234,Ignacio Rodriguez,F,00014,05-08-2004,3184.951,10.5,334.419,4316.161,7835.531
45678901234,Ignacio Rodriguez,F,00015,05-08-2004,2529.990,21,531.297,7451.429,21,1564.800,3171.100,21,665.931,9955.149,25869.696
45678901234,Ignacio Rodriguez,F,00016,05-08-2004,3533.559,21,742.047,9777.142,14052.748
45678901234,Ignacio Rodriguez,F,00017,05-08-2004,4282.840,10.5,449.698,10076.342,21,2116.031,5829.722,27,1574.024,6423.619,30752.276
45678901234,Ignacio Rodriguez,D,00018,05-08-2004,7766.743,10.5,815.508,3157.74,21,663.125,8625.210,27,2328.806,4569.616,27926.748
45678901234,Ignacio Rodriguez,F,00019,05-08-2004,1091.812,21,229.280,9618.502,10939.594
45678901234,Ignacio Rodriguez,F,00020,05-08-2004,9223.455,27,2490.332,668.969,12382.756
45678901234,Ignacio Rodriguez,F,00021,05-08-2004,3788.432,27,1022.876,9863.960,14675.268
45678901234,Ignacio Rodriguez,F,00022,05-08-2004,8440.140,27,2278.837,5706.760,16425.737
45678901234,Ignacio Rodriguez,F,00023,05-08-2004,10470.700,21,2198.847,746.696,13416.243
45678901234,Ignacio Rodriguez,F,00024,05-08-2004,9836.780,21,2065.723,8920.23,20822.733
45678901234,Ignacio Rodriguez,F,00025,05-08-2004,7666.197,10.5,804.950,1842.265,10313.412
45678901234,Ignacio Rodriguez,F,00026,05-08-2004,7330.131,21,1539.327,7904.52,16773.978
45678901234,Ignacio Rodriguez,F,00027,05-08-2004,4612.532,27,1245.383,3011.423,8869.338
45678901234,Ignacio Rodriguez,F,00028,05-08-2004,5811.398,21,1220.393,8077.427,15109.218
45678901234,Ignacio Rodriguez,F,00029,05-08-2004,9732.560,27,2627.791,3054.207,27,824.635,8033.151,27,2168.950,7067.606,33508.900
45678901234,Ignacio Rodriguez,F,00030,05-08-2004,2304.571,27,622.234,9273.518,12200.323
!
chmod -f 666 $(pwd)/$grupo/prueba/12345.200710


echo ">>> Creando $(pwd)/$grupo/prueba/12345678901.200711"
cat << ! >> $(pwd)/$grupo/prueba/12345678901.200711
12345678901,Pepe Araos,F,412547,01-10-2007,1001,27,270.27,1002,21,210.42,1004,10.5,105.42,2000,5593.11
12345678901,Pepe Araos,F,412547,01-10-2007,0.123,21,0.03,0.50,10.5,0.05,100,100.703
!
chmod -f 666 $(pwd)/$grupo/prueba/12345678901.200711


echo ">>> Creando $(pwd)/$grupo/prueba/33333333333.200711"
cat << ! >> $(pwd)/$grupo/prueba/33333333333.200711
33333333333,Manuel Perea,F,00001,11-09-2007,7857.919,10.5,825.081,8991.253,10.5,944.081,7063.937,10.5,741.713,7062.98,33486.964
33333333333,Manuel Perea,C,00002,11-09-2007,5845.23,27,1578.212,2580.197,10003.639
33333333333,Manuel Perea,F,00003,11-09-2007,9095.274,21,1910.007,6018.858,17024.139
33333333333,Manuel Perea,F,00004,11-09-2007,4835.771,10.5,507.755,2047.155,7390.681
33333333333,Manuel Perea,F,00005,11-09-2007,8135.170,21,1708.385,828.94,10672.495
33333333333,Manuel Perea,F,00006,11-09-2007,4965.983,10.5,521.428,4347.578,21,912.991,9887.231,10.5,1038.159,9512.959,31186.329
33333333333,Manuel Perea,F,00007,11-09-2007,10388.860,21,2181.660,9958.524,22529.044
33333333333,Manuel Perea,F,00008,11-09-2007,1127.280,21,236.728,2905.75,10.5,305.103,3651.101,10.5,383.365,2358.947,10968.274
33333333333,Manuel Perea,F,00009,11-09-2007,10253.397,27,2768.417,8362.173,21383.987
33333333333,Manuel Perea,D,00010,11-09-2007,7408.458,21,1555.776,4190.946,13155.180
33333333333,Manuel Perea,F,00011,11-09-2007,3306.519,10.5,347.184,10141.760,13795.463
33333333333,Manuel Perea,F,00012,11-09-2007,5951.811,21,1249.880,8877.674,27,2396.971,8544.767,21,1794.401,8568.471,37383.975
33333333333,Manuel Perea,F,00013,11-09-2007,3737.425,27,1009.104,3668.120,8414.649
33333333333,Manuel Perea,F,00014,11-09-2007,10378.912,10.5,1089.785,7835.779,19304.476
33333333333,Manuel Perea,F,00015,11-09-2007,4223.357,27,1140.306,660.155,6023.818
33333333333,Manuel Perea,F,00016,11-09-2007,9682.442,10.5,1016.656,4749.65,15448.748
33333333333,Manuel Perea,F,00017,11-09-2007,8683.676,27,2344.592,9964.146,20992.414
33333333333,Manuel Perea,D,00018,11-09-2007,1390.785,10.5,146.032,9925.473,11462.290
33333333333,Manuel Perea,F,00019,11-09-2007,6395.742,27,1726.850,1688.542,21,354.593,9343.495,10.5,981.066,1372.257,21862.545
33333333333,Manuel Perea,F,00020,11-09-2007,5241.659,10.5,550.374,10338.824,21,2171.153,10151.894,10.5,1065.948,9903.760,39423.612
33333333333,Manuel Perea,F,00021,11-09-2007,3781.33,27,1020.959,4216.499,9018.788
33333333333,Manuel Perea,F,00022,11-09-2007,7506.914,10.5,788.225,4819.953,13115.092
33333333333,Manuel Perea,F,00023,11-09-2007,1337.614,10.5,140.449,5020.881,6498.944
33333333333,Manuel Perea,F,00024,11-09-2007,9843.866,21,2067.211,8672.784,21,1821.284,3720.363,21,781.276,8001.348,34908.132
33333333333,Manuel Perea,C,00025,11-09-2007,2030.925,10.5,213.247,2470.960,4715.132
33333333333,Manuel Perea,F,00026,11-09-2007,4224.86,27,1140.712,8547.328,13912.900
33333333333,Manuel Perea,F,00027,11-09-2007,8862.843,21,1861.197,2557.147,13281.187
33333333333,Manuel Perea,C,00028,11-09-2007,4029.149,21,846.121,9460.47,14335.740
33333333333,Manuel Perea,F,00029,11-09-2007,4697.828,10.5,493.271,4998.460,21,1049.676,8455.97,27,2283.111,9937.496,31915.812
33333333333,Manuel Perea,F,00030,11-09-2007,8283.371,10.5,869.753,1281.418,27,345.982,4902.399,21,1029.503,8736.325,25448.751
33333333333,Manuel Perea,F,00031,99-09-2007,8283.371,10.5,869.753,1281.418,27,345.982,4902.399,21,1029.503,8736.325,25448.751
33333333333,Manuel Perea,F,00032,11-09-2007,1,0.01,0,1 
!
chmod -f 666 $(pwd)/$grupo/prueba/33333333333.200711


echo ">>> Creando $(pwd)/$grupo/prueba/45678901234.200409"
cat << ! >> $(pwd)/$grupo/prueba/45678901234.200409
45678901234,Ignacio Rodriguez,F,00001,05-08-2004,5375.389,10.5,564.415,5896.430,10.5,619.125,9986.2,21,2097.102,3890.564,28429.225
45678901234,Ignacio Rodriguez,F,00002,05-08-2004,3281.942,27,886.124,2149.10,10.5,225.655,533.944,21,112.128,9303.850,16492.743
45678901234,Ignacio Rodriguez,F,00003,05-08-2004,9068.30,27,2448.441,3699.538,15216.279
45678901234,Ignacio Rodriguez,F,00004,05-08-2004,10434.436,27,2817.297,3580.503,10.5,375.952,6021.49,10.5,632.256,2643.756,26505.690
45678901234,Ignacio Rodriguez,D,00005,05-08-2004,8138.389,27,2197.365,3068.333,27,828.449,6950.98,21,1459.705,8223.529,30866.750
45678901234,Ignacio Rodriguez,F,00006,05-08-2004,753.723,21,158.281,4985.251,27,1346.017,3629.248,10.5,381.071,4246.887,15500.478
45678901234,Ignacio Rodriguez,F,00007,05-08-2004,746.158,10.5,78.346,7014.190,7838.694
45678901234,Ignacio Rodriguez,F,00008,05-08-2004,2926.644,21,614.595,2617.695,27,706.777,3498.568,27,944.613,2426.97,13735.862
45678901234,Ignacio Rodriguez,F,00009,05-08-2004,1178.206,27,318.115,8836.941,10333.262
45678901234,Ignacio Rodriguez,F,00010,05-08-2004,10460.776,10.5,1098.381,9290.127,10.5,975.463,7201.210,21,1512.254,6577.650,37115.861
45678901234,Ignacio Rodriguez,F,00011,05-08-2004,5102.21,10.5,535.732,10298.475,10.5,1081.339,2503.730,21,525.783,587.362,20634.631
45678901234,Ignacio Rodriguez,D,00012,05-08-2004,4363.828,27,1178.233,8914.69,14456.751
45678901234,Ignacio Rodriguez,F,00013,05-08-2004,6576.61,27,1775.684,7007.612,27,1892.055,2070.627,21,434.831,10431.346,30188.765
45678901234,Ignacio Rodriguez,F,00014,05-08-2004,3184.951,10.5,334.419,4316.161,7835.531
45678901234,Ignacio Rodriguez,F,00015,05-08-2004,2529.990,21,531.297,7451.429,21,1564.800,3171.100,21,665.931,9955.149,25869.696
45678901234,Ignacio Rodriguez,F,00016,05-08-2004,3533.559,21,742.047,9777.142,14052.748
45678901234,Ignacio Rodriguez,F,00017,05-08-2004,4282.840,10.5,449.698,10076.342,21,2116.031,5829.722,27,1574.024,6423.619,30752.276
45678901234,Ignacio Rodriguez,D,00018,05-08-2004,7766.743,10.5,815.508,3157.74,21,663.125,8625.210,27,2328.806,4569.616,27926.748
45678901234,Ignacio Rodriguez,F,00019,05-08-2004,1091.812,21,229.280,9618.502,10939.594
45678901234,Ignacio Rodriguez,F,00020,05-08-2004,9223.455,27,2490.332,668.969,12382.756
45678901234,Ignacio Rodriguez,F,00021,05-08-2004,3788.432,27,1022.876,9863.960,14675.268
45678901234,Ignacio Rodriguez,F,00022,05-08-2004,8440.140,27,2278.837,5706.760,16425.737
45678901234,Ignacio Rodriguez,F,00023,05-08-2004,10470.700,21,2198.847,746.696,13416.243
45678901234,Ignacio Rodriguez,F,00024,05-08-2004,9836.780,21,2065.723,8920.23,20822.733
45678901234,Ignacio Rodriguez,F,00025,05-08-2004,7666.197,10.5,804.950,1842.265,10313.412
45678901234,Ignacio Rodriguez,F,00026,05-08-2004,7330.131,21,1539.327,7904.52,16773.978
45678901234,Ignacio Rodriguez,F,00027,05-08-2004,4612.532,27,1245.383,3011.423,8869.338
45678901234,Ignacio Rodriguez,F,00028,05-08-2004,5811.398,21,1220.393,8077.427,15109.218
45678901234,Ignacio Rodriguez,F,00029,05-08-2004,9732.560,27,2627.791,3054.207,27,824.635,8033.151,27,2168.950,7067.606,33508.900
45678901234,Ignacio Rodriguez,F,00030,05-08-2004,2304.571,27,622.234,9273.518,12200.323
!
chmod -f 666 $(pwd)/$grupo/prueba/45678901234.200409


echo ">>> Creando $(pwd)/$grupo/prueba/45678901234.200711"
cat << ! >> $(pwd)/$grupo/prueba/45678901234.200711
45678901234,Ignacio Rodriguez,F,00001,10-10-2007,5375.389,10.5,564.415,5896.430,10.5,619.125,9986.2,21,2097.102,3890.564,28429.225
45678901234,Ignacio Rodriguez,F,00002,10-10-2007,3281.942,27,886.124,2149.10,10.5,225.655,533.944,21,112.128,9303.850,16492.743
45678901234,Ignacio Rodriguez,F,00003,10-10-2007,9068.30,27,2448.441,3699.538,15216.279
45678901234,Ignacio Rodriguez,F,00004,10-10-2007,10434.436,27,2817.297,3580.503,10.5,375.952,6021.49,10.5,632.256,2643.756,26505.690
45678901234,Ignacio Rodriguez,D,00005,10-10-2007,8138.389,27,2197.365,3068.333,27,828.449,6950.98,21,1459.705,8223.529,30866.750
45678901234,Ignacio Rodriguez,F,00006,10-10-2007,753.723,21,158.281,4985.251,27,1346.017,3629.248,10.5,381.071,4246.887,15500.478
45678901234,Ignacio Rodriguez,F,00007,10-10-2007,746.158,10.5,78.346,7014.190,7838.694
45678901234,Ignacio Rodriguez,F,00008,10-10-2007,2926.644,21,614.595,2617.695,27,706.777,3498.568,27,944.613,2426.97,13735.862
45678901234,Ignacio Rodriguez,F,00009,10-10-2007,1178.206,27,318.115,8836.941,10333.262
45678901234,Ignacio Rodriguez,F,00010,10-10-2007,10460.776,10.5,1098.381,9290.127,10.5,975.463,7201.210,21,1512.254,6577.650,37115.861
45678901234,Ignacio Rodriguez,F,00011,10-10-2007,5102.21,10.5,535.732,10298.475,10.5,1081.339,2503.730,21,525.783,587.362,20634.631
45678901234,Ignacio Rodriguez,D,00012,10-10-2007,4363.828,27,1178.233,8914.69,14456.751
45678901234,Ignacio Rodriguez,F,00013,10-10-2007,6576.61,27,1775.684,7007.612,27,1892.055,2070.627,21,434.831,10431.346,30188.765
45678901234,Ignacio Rodriguez,F,00014,10-10-2007,3184.951,10.5,334.419,4316.161,7835.531
45678901234,Ignacio Rodriguez,F,00015,10-10-2007,2529.990,21,531.297,7451.429,21,1564.800,3171.100,21,665.931,9955.149,25869.696
45678901234,Ignacio Rodriguez,F,00016,10-10-2007,3533.559,21,742.047,9777.142,14052.748
45678901234,Ignacio Rodriguez,F,00017,10-10-2007,4282.840,10.5,449.698,10076.342,21,2116.031,5829.722,27,1574.024,6423.619,30752.276
45678901234,Ignacio Rodriguez,D,00018,10-10-2007,7766.743,10.5,815.508,3157.74,21,663.125,8625.210,27,2328.806,4569.616,27926.748
45678901234,Ignacio Rodriguez,F,00019,10-10-2007,1091.812,21,229.280,9618.502,10939.594
45678901234,Ignacio Rodriguez,F,00020,10-10-2007,9223.455,27,2490.332,668.969,12382.756
45678901234,Ignacio Rodriguez,F,00021,10-10-2007,3788.432,27,1022.876,9863.960,14675.268
45678901234,Ignacio Rodriguez,F,00022,10-10-2007,8440.140,27,2278.837,5706.760,16425.737
45678901234,Ignacio Rodriguez,F,00023,10-10-2007,10470.700,21,2198.847,746.696,13416.243
45678901234,Ignacio Rodriguez,F,00024,10-10-2007,9836.780,21,2065.723,8920.23,20822.733
45678901234,Ignacio Rodriguez,F,00025,10-10-2007,7666.197,10.5,804.950,1842.265,10313.412
45678901234,Ignacio Rodriguez,F,00026,10-10-2007,7330.131,21,1539.327,7904.52,16773.978
45678901234,Ignacio Rodriguez,F,00027,10-10-2007,4612.532,27,1245.383,3011.423,8869.338
45678901234,Ignacio Rodriguez,F,00028,10-10-2007,5811.398,21,1220.393,8077.427,15109.218
45678901234,Ignacio Rodriguez,F,00029,10-10-2007,9732.560,27,2627.791,3054.207,27,824.635,8033.151,27,2168.950,7067.606,33508.900
45678901234,Ignacio Rodriguez,F,00030,10-10-2007,2304.571,27,622.234,9273.518,12200.323
!
chmod -f 666 $(pwd)/$grupo/prueba/45678901234.200711


echo ">>> Creando $(pwd)/$grupo/prueba/67890123456.200610"
cat << ! >> $(pwd)/$grupo/prueba/67890123456.200610
67890123456,Waldorf Osorio,F,00001,11-09-2006,6713.346,21,1409.802,5335.167,13458.315
67890123456,Waldorf Osorio,F,00002,11-09-2006,4634.267,10.5,486.598,1927.583,27,520.447,5403.589,21,1134.753,5853.977,19961.214
67890123456,Waldorf Osorio,F,00003,11-09-2006,3008.130,21,631.707,8590.199,27,2319.353,7553.436,21,1586.221,7492.534,31181.580
67890123456,Waldorf Osorio,F,00004,11-09-2006,1899.588,10.5,199.456,3032.764,5131.808
67890123456,Waldorf Osorio,F,00005,11-09-2006,9698.170,27,2618.505,7388.671,21,1551.620,2499.871,21,524.972,5845.734,30127.543
67890123456,Waldorf Osorio,F,00006,11-09-2006,10363.954,27,2798.267,2997.779,10.5,314.766,1058.695,21,222.325,7303.187,25058.973
67890123456,Waldorf Osorio,F,00007,11-09-2006,8857.531,27,2391.533,9663.924,20912.988
67890123456,Waldorf Osorio,F,00008,11-09-2006,3010.515,27,812.839,5778.433,21,1213.470,2309.442,10.5,242.491,6473.120,19840.310
67890123456,Waldorf Osorio,F,00009,11-09-2006,9151.592,10.5,960.917,5640.891,10.5,592.293,6110.371,27,1649.800,9147.599,33253.463
67890123456,Waldorf Osorio,F,00010,11-09-2006,8141.549,10.5,854.862,2445.653,11442.064
67890123456,Waldorf Osorio,F,00011,11-09-2006,8210.418,27,2216.812,10094.538,20521.768
67890123456,Waldorf Osorio,F,00012,11-09-2006,2706.177,27,730.667,4133.430,7570.274
67890123456,Waldorf Osorio,F,00013,11-09-2006,2927.325,27,790.377,941.515,21,197.718,10407.306,21,2185.534,915.531,18365.306
67890123456,Waldorf Osorio,F,00014,11-09-2006,9701.187,10.5,1018.624,4578.549,15298.360
67890123456,Waldorf Osorio,F,00015,11-09-2006,5162.290,10.5,542.040,6334.783,21,1330.304,6472.617,21,1359.249,1835.377,23036.660
67890123456,Waldorf Osorio,F,00016,11-09-2006,8517.950,21,1788.769,2036.842,12343.561
67890123456,Waldorf Osorio,F,00017,11-09-2006,4878.167,21,1024.415,1170.676,7073.258
67890123456,Waldorf Osorio,F,00018,11-09-2006,10301.281,27,2781.345,5783.909,18866.535
67890123456,Waldorf Osorio,F,00019,11-09-2006,2356.420,21,494.848,3735.933,6587.201
67890123456,Waldorf Osorio,F,00020,11-09-2006,7859.490,27,2122.062,9693.976,27,2617.373,10071.0,10.5,1057.455,8989.733,42411.089
67890123456,Waldorf Osorio,F,00021,11-09-2006,670.622,10.5,70.415,5442.750,6183.787
67890123456,Waldorf Osorio,F,00022,11-09-2006,5971.235,21,1253.959,1252.773,21,263.082,8033.794,10.5,843.548,9104.202,26722.593
67890123456,Waldorf Osorio,F,00023,11-09-2006,9806.951,10.5,1029.729,6007.434,16844.114
67890123456,Waldorf Osorio,F,00024,11-09-2006,4012.379,27,1083.342,8152.137,21,1711.948,778.107,27,210.088,4623.45,20571.451
67890123456,Waldorf Osorio,F,00025,11-09-2006,8037.953,27,2170.247,8000.727,10.5,840.076,1114.395,21,234.022,9528.166,29925.586
67890123456,Waldorf Osorio,F,00026,11-09-2006,852.874,10.5,89.551,9681.143,10623.568
67890123456,Waldorf Osorio,F,00027,11-09-2006,1359.847,27,367.158,4712.365,6439.370
67890123456,Waldorf Osorio,F,00028,11-09-2006,7860.458,21,1650.696,1729.216,10.5,181.567,4627.766,10.5,485.915,8875.928,25411.546
67890123456,Waldorf Osorio,F,00029,11-09-2006,2803.271,10.5,294.343,8858.103,21,1860.201,5119.37,21,1075.067,6676.318,26686.673
67890123456,Waldorf Osorio,F,00030,11-09-2006,2255.562,21,473.668,2873.88,5603.110
67890123456,Waldorf Osorio,F,00031,11-09-2006,-2255.562,21,-473.668,2873.88,2144.65
67890123456,Waldorf Osorio,F,00032,11-09-2006,8037.953,27,2170.247,8000.727,840.076,1114.395,21,234.022,9528.166,29925.586
67890123456,Waldorf Osorio,F,00033,11-09-2006,0.125,7.25,0.009,0.015,7.25,0.001,9754.952,7.25,707.234,45.80,10508.136
!
chmod -f 666 $(pwd)/$grupo/prueba/67890123456.200610


echo ">>> Creando $(pwd)/$grupo/prueba/67890123456.200708"
cat << ! >> $(pwd)/$grupo/prueba/67890123456.200708
67890123456,Waldorf Osorio,F,00001,11-07-2007,6713.346,21,1409.802,5335.167,13458.315
67890123456,Waldorf Osorio,F,00002,11-07-2007,4634.267,10.5,486.598,1927.583,27,520.447,5403.589,21,1134.753,5853.977,19961.214
67890123456,Waldorf Osorio,F,00003,11-07-2007,3008.130,21,631.707,8590.199,27,2319.353,7553.436,21,1586.221,7492.534,31181.580
67890123456,Waldorf Osorio,F,00004,11-07-2007,1899.588,10.5,199.456,3032.764,5131.808
67890123456,Waldorf Osorio,F,00005,11-07-2007,9698.170,27,2618.505,7388.671,21,1551.620,2499.871,21,524.972,5845.734,30127.543
67890123456,Waldorf Osorio,F,00006,11-07-2007,10363.954,27,2798.267,2997.779,10.5,314.766,1058.695,21,222.325,7303.187,25058.973
67890123456,Waldorf Osorio,F,00007,11-07-2007,8857.531,27,2391.533,9663.924,20912.988
67890123456,Waldorf Osorio,F,00008,11-07-2007,3010.515,27,812.839,5778.433,21,1213.470,2309.442,10.5,242.491,6473.120,19840.310
67890123456,Waldorf Osorio,F,00009,11-07-2007,9151.592,10.5,960.917,5640.891,10.5,592.293,6110.371,27,1649.800,9147.599,33253.463
67890123456,Waldorf Osorio,F,00010,11-07-2007,8141.549,10.5,854.862,2445.653,11442.064
67890123456,Waldorf Osorio,F,00011,11-07-2007,8210.418,27,2216.812,10094.538,20521.768
67890123456,Waldorf Osorio,F,00012,11-07-2007,2706.177,27,730.667,4133.430,7570.274
67890123456,Waldorf Osorio,F,00013,11-07-2007,2927.325,27,790.377,941.515,21,197.718,10407.306,21,2185.534,915.531,18365.306
67890123456,Waldorf Osorio,F,00014,11-07-2007,9701.187,10.5,1018.624,4578.549,15298.360
67890123456,Waldorf Osorio,F,00015,11-07-2007,5162.290,10.5,542.040,6334.783,21,1330.304,6472.617,21,1359.249,1835.377,23036.660
67890123456,Waldorf Osorio,F,00016,11-07-2007,8517.950,21,1788.769,2036.842,12343.561
67890123456,Waldorf Osorio,F,00017,11-07-2007,4878.167,21,1024.415,1170.676,7073.258
67890123456,Waldorf Osorio,F,00018,11-07-2007,10301.281,27,2781.345,5783.909,18866.535
67890123456,Waldorf Osorio,F,00019,11-07-2007,2356.420,21,494.848,3735.933,6587.201
67890123456,Waldorf Osorio,F,00020,11-07-2007,7859.490,27,2122.062,9693.976,27,2617.373,10071.0,10.5,1057.455,8989.733,42411.089
67890123456,Waldorf Osorio,F,00021,11-07-2007,670.622,10.5,70.415,5442.750,6183.787
67890123456,Waldorf Osorio,F,00022,11-07-2007,5971.235,21,1253.959,1252.773,21,263.082,8033.794,10.5,843.548,9104.202,26722.593
67890123456,Waldorf Osorio,F,00023,11-07-2007,9806.951,10.5,1029.729,6007.434,16844.114
67890123456,Waldorf Osorio,F,00024,11-07-2007,4012.379,27,1083.342,8152.137,21,1711.948,778.107,27,210.088,4623.45,20571.451
67890123456,Waldorf Osorio,F,00025,11-07-2007,8037.953,27,2170.247,8000.727,10.5,840.076,1114.395,21,234.022,9528.166,29925.586
67890123456,Waldorf Osorio,F,00026,11-07-2007,852.874,10.5,89.551,9681.143,10623.568
67890123456,Waldorf Osorio,F,00027,11-07-2007,1359.847,27,367.158,4712.365,6439.370
67890123456,Waldorf Osorio,F,00028,11-07-2007,7860.458,21,1650.696,1729.216,10.5,181.567,4627.766,10.5,485.915,8875.928,25411.546
67890123456,Waldorf Osorio,F,00029,11-07-2007,2803.271,10.5,294.343,8858.103,21,1860.201,5119.37,21,1075.067,6676.318,26686.673
67890123456,Waldorf Osorio,F,00030,11-07-2007,2255.562,21,473.668,2873.88,5603.110
67890123456,Waldorf Osorio,F,00031,11-07-2007,-2255.562,21,-473.668,2873.88,2144.65
67890123456,Waldorf Osorio,F,00032,11-07-2007,8037.953,27,2170.247,8000.727,840.076,1114.395,21,234.022,9528.166,29925.586
67890123456,Waldorf Osorio,F,00033,11-07-2007,0.125,7.25,0.009,0.015,7.25,0.001,9754.952,7.25,707.234,45.80,10508.136
!
chmod -f 666 $(pwd)/$grupo/prueba/67890123456.200708


echo ">>> Creando $(pwd)/$grupo/prueba/78901234567.200711"
cat << ! >> $(pwd)/$grupo/prueba/78901234567.200711
78901234567,Guillermo Cardozo,F,00001,01-09-2007,6223.509,21,1306.936,6001.818,13532.263
78901234567,Guillermo Cardozo,F,00002,01-09-2007,8910.503,10.5,935.602,8941.623,18787.728
78901234567,Guillermo Cardozo,F,00003,01-09-2007,8499.130,10.5,892.408,971.776,10363.314
78901234567,Guillermo Cardozo,F,00004,01-09-2007,4901.12,27,1323.302,8616.58,27,2326.476,5149.510,21,1081.397,8233.12,31631.505
78901234567,Guillermo Cardozo,F,00005,01-09-2007,1582.872,27,427.375,6082.536,10.5,638.666,8527.31,21,1790.735,5206.126,24255.620
78901234567,Guillermo Cardozo,F,00006,01-09-2007,8393.722,27,2266.304,6364.829,17024.855
78901234567,Guillermo Cardozo,C,00007,01-09-2007,7153.653,21,1502.267,4438.162,13094.082
78901234567,Guillermo Cardozo,F,00008,01-09-2007,8357.245,10.5,877.510,1897.418,11132.173
78901234567,Guillermo Cardozo,F,00009,01-09-2007,679.433,21,142.680,5491.574,6313.687
78901234567,Guillermo Cardozo,F,00010,01-09-2007,6353.178,27,1715.358,2552.138,10620.674
78901234567,Guillermo Cardozo,F,00011,01-09-2007,4883.562,10.5,512.774,7886.976,13283.312
78901234567,Guillermo Cardozo,F,00012,01-09-2007,7348.428,21,1543.169,7118.905,16010.502
78901234567,Guillermo Cardozo,D,00013,01-09-2007,3366.86,27,909.052,3111.778,7387.690
78901234567,Guillermo Cardozo,F,00014,01-09-2007,5150.255,21,1081.553,2752.413,27,743.151,7699.629,27,2078.899,862.996,20368.896
78901234567,Guillermo Cardozo,F,00015,01-09-2007,1152.232,21,241.968,8884.767,10278.967
78901234567,Guillermo Cardozo,F,00016,01-09-2007,10186.340,27,2750.311,6409.436,19346.087
78901234567,Guillermo Cardozo,F,00017,01-09-2007,4118.73,21,864.933,5268.639,27,1422.532,8906.12,27,2404.652,2923.54,25909.146
78901234567,Guillermo Cardozo,F,00018,01-09-2007,8639.278,10.5,907.124,5508.98,15055.382
78901234567,Guillermo Cardozo,F,00019,01-09-2007,3011.892,21,632.497,4254.739,7899.128
78901234567,Guillermo Cardozo,D,00020,01-09-2007,4723.580,21,991.951,6053.236,11768.767
78901234567,Guillermo Cardozo,F,00021,01-09-2007,1416.758,27,382.524,3610.218,27,974.758,3290.629,27,888.469,1457.552,12020.908
78901234567,Guillermo Cardozo,F,00022,01-09-2007,8313.858,21,1745.910,1192.832,10.5,125.247,902.319,27,243.626,7083.487,19607.279
78901234567,Guillermo Cardozo,F,00023,01-09-2007,9022.827,21,1894.793,6589.859,10.5,691.935,5389.359,21,1131.765,4336.273,29056.811
78901234567,Guillermo Cardozo,F,00024,01-09-2007,7535.656,10.5,791.243,4186.985,10.5,439.633,6032.434,21,1266.811,4938.123,25190.885
78901234567,Guillermo Cardozo,F,00025,01-09-2007,3276.603,21,688.086,4476.7,8441.389
78901234567,Guillermo Cardozo,C,00026,01-09-2007,6074.807,10.5,637.854,1832.624,27,494.808,7804.344,21,1638.912,6422.61,24905.959
78901234567,Guillermo Cardozo,F,00027,01-09-2007,5010.160,10.5,526.066,4318.332,27,1165.949,3770.484,21,791.801,10110.705,25693.497
78901234567,Guillermo Cardozo,F,00028,01-09-2007,4442.59,10.5,466.471,8617.758,21,1809.729,9585.231,27,2588.012,6509.391,34019.182
78901234567,Guillermo Cardozo,F,00029,01-09-2007,3213.769,27,867.717,2215.526,27,598.192,6300.331,27,1701.089,4965.701,19862.325
78901234567,Guillermo Cardozo,F,00030,01-09-2007,996.643,27,269.093,7724.237,8989.973
!
chmod -f 666 $(pwd)/$grupo/prueba/78901234567.200711


echo ">>> Creando $(pwd)/$grupo/prueba/Descripcion_de_pruebas.txt"
cat << ! >> $(pwd)/$grupo/prueba/Descripcion_de_pruebas.txt
Para recibeC:
Nombre de Archivo	| Estado	| Descripcion
------------------------------------------------------------------------------------------------
*11111111111.20071101 	| INVALIDO 	| Fecha invalida no cumple con formato aaaadd.
*12345678901.200711 	| INVALIDO 	| La fecha de habilitacion de este contribuyente es en el futuro.
*78901234567.200710 	| VALIDO 	| La fecha de habilitacion y el nombre del archivo es correcto.
*12124578896.200711 	| INVALIDO 	| El contribuyente no existe en la tabla.
*33333333333.200711	| VALIDO	| La fecha de habilitacion y el nombre del archivo es correcto.
*11111111111.200711	| VALIDO	| La fecha de habilitacion y el nombre del archivo es correcto.
*67890123456.200708 	| VALIDO	| La fecha de habilitacion y el nombre del archivo es correcto.
*45678901234.200711	| VALIDO	| La fecha de habilitacion y el nombre del archivo es correcto.
*01234567890.200710	| VALIDO	| La fecha de habilitacion y el nombre del archivo es correcto.
12345.200710		| INVALIDO 	| No cumple con el formato del archivo

Para validaC:
*78901234567.200710 	| 	 	| 6,17- Error +-3,
*33333333333.200711	|		| 1-30 Validan correctamente, 31- Fecha invalida 32- Alicuota fuera de rango.
*11111111111.200711	|		| 1,7,12,- Error +-3,, 22- Importe neto gravado con mas de 3 decimales.
*67890123456.200610 	| 		| 5,18,24,28,33- Error +-3,  31-Valor negativo en importe neto gravado, 32- Campos opcionales mal formados.
*45678901234.200409	| 		| 2,5,12,16,18,22,23- Error +-3.
*01234567890.200710	| 		| 15,29- Error +-3, 32-Fecha > periodo , 33- Tipo de comprobante inexistente.

Para validaC:
*67890123456.200610 	| 		| Provoca que se reseete el numero de secuencia en la tabla de comprobantes y vuelva a 00001.
!
chmod -f 666 $(pwd)/$grupo/prueba/Descripcion_de_pruebas.txt
echo " >> Archivos de datos creados correctamente"


echo ""
echo ""
echo " > Fin de la instalacion."

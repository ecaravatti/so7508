#!/bin/bash
# ******************************************************************************************************
# Trabajo Práctico de Sistemas Operativos (75.08)
# Primer Cuatrimestre 2008 - Curso Martes
#
# Comando: ginsta.sh
#
# Descripción: este comando se encarga de efectuar la instalación del paquete GASTOS.
#
# Ubicación: 
#
# Variables de Entorno que utiliza: GRUPO
#
# ******************************************************************************************************

FIN_OK=0
ERROR_VARIABLE_GRUPO=1
ERROR_PAQUETE_INSTALADO=2
ERROR_COMPONENTE_INSTALADO=3
ERROR_PERL_NO_INSTALADO=4
ERROR_VERSION_PERL=5
ERROR_ESP_INSUF=6
INSTALACION_ABORTADA=7

GINICI="ginici.sh"
GEMONI="gemoni.sh"
GALIDA="galida.sh"
GONTRO="gontro.pl"
GONTROSUB="gontrosub.pm"
GLOG="glog.sh"
MOVER="mover.sh"

NOMBRE_COMANDO="GINSTA"
ARCHIVO_LOG="gastos.log"
CANCEL_MSG="Proceso de Instalación Cancelado"
PERL_MSG="****************************************************************************
* Para instalar GASTOS es necesario contar con Perl 5 o superior instalado *
* Efectúe su instalación e inténtelo nuevamente                            *
****************************************************************************"
DATAFREE=
BINDIR="$GRUPO/bin"
CONFDIR="$GRUPO/cnf"
ARRIDIR="$GRUPO/arribos"
ANIO=$(date +%Y)
GASTODIR="$GRUPO/gastos"
LOGDIR="$GRUPO/log"
LOGEXT=".log"
LOGSIZE=10

# $1 = Mensaje a mostrar
printAndLog()
{
	echo -e "$1"
	"./$GLOG" "$ARCHIVO_LOG" "$1" "$NOMBRE_COMANDO"
}

# $1 = Variable en la que se almacenará el dato ingresado por el usuario
readAndLog()
{
	read $1
	eval aux=\$$1
	"./$GLOG" "$ARCHIVO_LOG" "$aux" "$NOMBRE_COMANDO"
}

fin()
{
	"./$GLOG" "$ARCHIVO_LOG" "Fin de Ejecución" "$NOMBRE_COMANDO"
}

# $1 = Mensaje a mostrar
# $2 = Código a retornar
die()
{
	printAndLog "$1"
	printAndLog "$CANCEL_MSG"
	fin
	exit "$2"
}

# Función que imprime una lista de los componentes instalados indicando
# el nombre del componente, el usuario y la fecha en que se instaló.
# Recibe los nombres de los componentes concatenados en un string, pero
# deben estar separados por un espacio.
# El segundo parámetro es el path donde se debe buscar el archivo,
# para obtener la información sobre el usuario y la fecha.
# El tercer parámetro debe ser 1 si se desea que se imprima la información
# sobre el usuario y la fecha de instalación del comando, ó 0 en caso contrario.
printComponents()
{
	array=( `echo "$1"` )
	for i in ${array[*]}
	do
		# Separo el nombre del archivo y la extensión
		comando=(`echo ${i} | tr '.' ' '`)
		# Paso el nombre del archivo a mayúscula
		comando=(`echo ${comando[0]} | tr "[:lower:]" "[:upper:]"`)
		longitudComando=${#comando[0]}
		if [ "$3" == 1 ] # Mostrar usuario y fecha
		then
			# Obtengo el usuario que creó el archivo
			usuario=$(ls -l "$2/${i}" | awk '{print $3}')
			# Obtengo la fecha en que se creó el archivo
			fecha=$(ls -l "$2/${i}" | awk '{print $6}')
			if [ $longitudComando -lt 6 ]
			then
				printAndLog "* ${comando[0]}\t\t$usuario\t$fecha\t\t\t\t*"
			else
				printAndLog "* ${comando[0]}\t$usuario\t$fecha\t\t\t\t*"
			fi
		else
			if [ $longitudComando -lt 6 ]
			then
				printAndLog "* ${comando[0]}\t\t\t\t\t\t\t\t*"
			else
				printAndLog "* ${comando[0]}\t\t\t\t\t\t\t*"
			fi
		fi
	done
}

# $1 = Lista de componentes instalados
# $2 = Lista de componentes no instalados
# $3 = Ruta donde se encuentran los componentes
printComponentsList()
{
	printAndLog "*****************************************************************"
	printAndLog "*\tProceso de Instalación del sistema GASTOS\t\t*"
	printAndLog "*\t\tCopyright TPSistemasOp (c)2008\t\t\t*"
	printAndLog "*****************************************************************"
	printAndLog "* Se encuentran instalados los siguientes componentes:\t\t*"

	# Se imprimen los componentes instalados
	printComponents "$1" "$3" 1
	if [ "$2" != "" ]
	then
		printAndLog "* Falta instalar los siguientes componentes:\t\t\t*"
		# Se imprimen los componentes que faltan instalar
		printComponents "$2" "$3" 0
	fi

	printAndLog "*****************************************************************"
	
}

verificarPerl()
{
	perl_instalado=$(which perl)
	if [ ! -z $perl_instalado ]
	then
		version_perl=$(perl -version|grep v[1-9]|sed "s/.*v\([^.]\).*/\1/")
		if [ $version_perl -lt 5 ]
		then
			die "$PERL_MSG" $ERROR_VERSION_PERL
		else
			printAndLog "Versión de Perl instalada: $version_perl"
		fi
	else
		die "$PERL_MSG" $ERROR_PERL_NO_INSTALADO
	fi
}

# $1 = Directorio donde se va a verificar el espacio diponible
obtenerEspacioDisponible()
{
	RETVAL=$(df "$1" | tr -s " " | cut -f4 -d" " | grep ^[0-9]*$)
}

mostrarResumenParametros()
{
	printAndLog "*********************************************************************************************************"
	printAndLog "* Parámetros de la instalación del paquete GASTOS\t\t\t\t\t\t\t*"
	printAndLog "*********************************************************************************************************"
	printAndLog "* Directorio de instalación\t\t: $GRUPO\t\t\t*"
	printAndLog "* Log de la instalación\t\t\t: $GRUPO/$ARCHIVO_LOG\t\t*"
	printAndLog "* Espacio disponible en $GRUPO : $DATAFREE KB\t\t\t\t*"
	printAndLog "* Biblioteca de ejecutables\t\t: $BINDIR\t\t*"
	printAndLog "* Biblioteca de tablas y configuración\t: $CONFDIR\t\t*"
	printAndLog "* Directorio de arribos\t\t\t: $ARRIDIR\t\t*"
	printAndLog "* Año ingresado para aceptar gastos\t: $ANIO\t\t\t\t\t\t\t\t*"
	printAndLog "* Directorio de gastos\t\t\t: $GASTODIR\t\t*"
	printAndLog "* Directorio para archivos de Log\t: $LOGDIR\t\t*"
	printAndLog "* Extensión para los archivos de Log\t: $LOGEXT\t\t\t\t\t\t\t\t*"
	printAndLog "* Máximo para los archivos de Log\t: $LOGSIZE KB\t\t\t\t\t\t\t\t*"
	printAndLog "*********************************************************************************************************"
}

leerEspacioDisponible()
{
	obtenerEspacioDisponible "$GRUPO"
	printAndLog "Espacio disponible en $GRUPO: $RETVAL KB"
	printAndLog "Si considera que el espacio es suficiente, presione ENTER para continuar."
	printAndLog "Si el espacio es insuficiente, presione cualquier otra tecla para cancelar."
	
	readAndLog opcion
	if [ "$opcion" = "" ] # Se presionó ENTER
	then
		DATAFREE=$RETVAL
	else
		die "Espacio en disco insuficiente" $ERROR_ESP_INSUF
	fi
}

leerDirectorioEjecutables()
{
	printAndLog "Ingrese el nombre del directorio de ejecutables: ($BINDIR)"
	readAndLog opcion

	if [ "$opcion" != "" ]
	then
		auxStr=${opcion:0:${#GRUPO}}
		if [ "$auxStr" = "$GRUPO" ] # Si ingresó el path completo
		then
			BINDIR="$opcion"
		else
			BINDIR="$GRUPO/$opcion"
		fi
	fi
}

leerDirectorioConfiguracion()
{
	printAndLog "Ingrese el nombre del directorio para almacenar parámetros y tablas del sistema: ($CONFDIR)"
	readAndLog opcion

	if [ "$opcion" != "" ]
	then
		auxStr=${opcion:0:${#GRUPO}}
		if [ "$auxStr" = "$GRUPO" ] # Si ingresó el path completo
		then
			CONFDIR="$opcion"
		else
			CONFDIR="$GRUPO/$opcion"
		fi
	fi
}

leerDirectorioArribos()
{
	printAndLog "Ingrese el nombre del directorio que permite el arribo de archivos externos: ($ARRIDIR)"
	readAndLog opcion

	if [ "$opcion" != "" ]
	then
		auxStr=${opcion:0:${#GRUPO}}
		if [ "$auxStr" = "$GRUPO" ] # Si ingresó el path completo
		then
			ARRIDIR="$opcion"
		else
			ARRIDIR="$GRUPO/$opcion"
		fi
	fi
}

leerAnioInicial()
{
	printAndLog "Ingrese el año a partir del cual se aceptarán los archivos de gastos: ($ANIO)"
	readAndLog opcion

	if [ "$opcion" != "" ]
	then
		anioIngresado=$(echo "$opcion" | grep ^[1-9][0-9][0-9][0-9]$)
		anioActual=$(date +%Y)
		if [ "$anioIngresado" != "" ] && [ $anioIngresado -le $anioActual ]
		then
			ANIO=$anioIngresado
		else
			printAndLog "El año ingresado es incorrecto."
			leerAnioInicial
		fi
	fi
}

leerDirectorioGastos()
{
	printAndLog "Ingrese el nombre del directorio de archivos de gastos: ($GASTODIR)"
	readAndLog opcion

	if [ "$opcion" != "" ]
	then
		auxStr=${opcion:0:${#GRUPO}}
		if [ "$auxStr" = "$GRUPO" ] # Si ingresó el path completo
		then
			GASTODIR="$opcion"
		else
			GASTODIR="$GRUPO/$opcion"
		fi
	fi
}

leerDirectorioLog()
{
	printAndLog "Ingrese el nombre del directorio de logs del sistema: ($LOGDIR)"
	readAndLog opcion

	if [ "$opcion" != "" ]
	then
		auxStr=${opcion:0:${#GRUPO}}
		if [ "$auxStr" = "$GRUPO" ] # Si ingresó el path completo
		then
			LOGDIR="$opcion"
		else
			LOGDIR="$GRUPO/$opcion"
		fi
	fi
}

leerExtensionArchivoLog()
{
	printAndLog "Ingrese la extensión de los archivos de log: ($LOGEXT)"
	readAndLog opcion

	if [ "$opcion" != "" ]
	then
		auxExt=$(echo "$opcion" | grep ^['.'][a-zA-Z0-9]*$)
		if [ "$auxExt" != "" ] # La extensión es válida
		then
			LOGEXT="$auxExt"
		else
			printAndLog "La extensión ingresada es incorrecta. Debe tener el siguiente formato: .ext"
			leerExtensionArchivoLog
		fi
	fi
}

leerTamanioMaxArchivoLog()
{
	printAndLog "Ingrese el tamaño máximo para los archivos <$LOGEXT> (en KB): ($LOGSIZE)"
	readAndLog opcion

	if [ "$opcion" != "" ]
	then
		auxTam=$(echo "$opcion" | grep ^[0-9]*$)
		if [ "$auxTam" != "" ] # El tamaño es válido
		then
			LOGSIZE="$auxTam"
		else
			printAndLog "El tamaño del archivo es incorrecto."
			leerTamanioMaxArchivoLog
		fi
	fi
}

confirmarInstalacion()
{
	printAndLog "Iniciando Instalación... Está Ud. seguro? (Si/No)"
	readAndLog opcion
	if [ "$opcion" = "No" ] || [ "$opcion" = "no" ]
	then
		die "" $INSTALACION_ABORTADA
	elif [ "$opcion" != "Si" ] && [ "$opcion" != "si" ]
	then
		printAndLog "Opción incorrecta."
		confirmarInstalacion
	fi
}

crearEstructuraDirectorios()
{
	printAndLog "Creando estructura de directorios..."
	mkdir -p -m 755 "$BINDIR"
	mkdir -p -m 755 "$CONFDIR"
	mkdir -p -m 755 "$ARRIDIR/noreci"
	mkdir -p -m 755 "$ARRIDIR/reci/ok"
	mkdir -p -m 755 "$ARRIDIR/reci/rech"
	mkdir -p -m 755 "$GASTODIR/aproc"
	mkdir -p -m 755 "$GASTODIR/proc"
	mkdir -p -m 755 "$LOGDIR"
	mkdir -p -m 755 "$GRUPO/etc"
}

copiarArchivos()
{
	printAndLog "Moviendo archivos ejecutables..."

	# Se copian los ejecutables
	"./$MOVER" "$GEMONI" "$BINDIR" "$ARCHIVO_LOG"
	chmod -f 777 "$BINDIR/$GEMONI"
	printAndLog "Instalación del componente GEMONI completada"

	"./$MOVER" "$GALIDA" "$BINDIR" "$ARCHIVO_LOG"
	chmod -f 777 "$BINDIR/$GALIDA"
	printAndLog "Instalación del componente GALIDA completada"

	"./$MOVER" "$GONTRO" "$BINDIR" "$ARCHIVO_LOG"
	"./$MOVER" "$GONTROSUB" "$BINDIR" "$ARCHIVO_LOG"
	chmod -f 777 "$BINDIR/$GONTRO"
	chmod -f 777 "$BINDIR/$GONTROSUB"
	printAndLog "Instalación del componente GONTRO completada"

	cp "$GLOG" "$BINDIR"
	chmod -f 777 "$BINDIR/$GLOG"
	printAndLog "Instalación del componente GLOG completada"

	cp "$MOVER" "$BINDIR"
	chmod -f 777 "$BINDIR/$MOVER"
	printAndLog "Instalación del componente MOVER completada"

	# Se copian los archivos de prueba
	printAndLog "Moviendo archivos de prueba..."

	for i in `ls "tests/confdir/"`
	do
		"./$MOVER" "tests/confdir/$i" "$CONFDIR" "$ARCHIVO_LOG"
		chmod -f 644 "$CONFDIR/$i"
	done

}

guardarInformacionInstalacion()
{
	archivoConf="$CONFDIR/gastos.conf"
	printAndLog "Creando archivo de configuración..."
	> "$archivoConf"
	echo "Parámetros de instalación del paquete GASTOS" >> "$archivoConf"
	echo "GRUPO = $GRUPO" >> "$archivoConf"
	echo "CONFDIR = $CONFDIR" >> "$archivoConf"
	echo "ANIO = $ANIO" >> "$archivoConf"
	echo "BINDIR = $BINDIR" >> "$archivoConf"
	echo "ARRIDIR = $ARRIDIR" >> "$archivoConf"
	echo "GASTODIR = $GASTODIR" >> "$archivoConf"
	echo "DATAFREE = $DATAFREE KB" >> "$archivoConf"
	echo "LOGDIR = $LOGDIR" >> "$archivoConf"
	echo "LOGEXT = $LOGEXT" >> "$archivoConf"
	echo "MAXLOGSIZE = $LOGSIZE KB" >> "$archivoConf"
	echo "FECINS = `date +%D\ %T`" >> "$archivoConf"
	echo "USERID = `whoami`" >> "$archivoConf"
	chmod -f 644 "$archivoConf"

	# Se guarda la información necesaria para que GONTRO pueda
	# inicializar el ambiente cuando es ejecutado manualmente
	echo "BINDIR = $BINDIR" >> "$GRUPO/etc/gontro.conf"
	echo "ARRIDIR = $ARRIDIR" >> "$GRUPO/etc/gontro.conf"
	echo "GASTODIR = $GASTODIR" >> "$GRUPO/etc/gontro.conf"
	echo "LOGDIR = $LOGDIR" >> "$GRUPO/etc/gontro.conf"
	echo "LOGEXT = $LOGEXT" >> "$GRUPO/etc/gontro.conf"
	echo "MAXLOGSIZE = $LOGSIZE" >> "$GRUPO/etc/gontro.conf"
	chmod -f 644 "$GRUPO/etc/gontro.conf"
}

crearComandoGinici()
{
	printAndLog "Creando el comando Ginici..."

	cat << EOF > "$BINDIR/$GINICI"
#!/bin/bash
# ******************************************************************************************************
# Trabajo Práctico de Sistemas Operativos (75.08)
# Primer Cuatrimestre 2008 - Curso Martes
#
# Comando: ginici.sh
#
# Descripción: este comando se encarga de preparar el entorno de ejecución del TP.
#
# Ubicación: directorio \$BINDIR
#
# Variables de Entorno que utiliza: GRUPO
#
# ******************************************************************************************************

# En el archivo "ginici.conf" se encuentra almacenado el path y el nombre del archivo de configuración
# del sistema GASTOS
ARCHIVO_CONF="../etc/ginici.conf"

FIN_OK=0
ERROR_GEMONI=1
ERROR_GRUPO=2
ERROR_ARCHIVO_CONF=3
ERROR_COMANDO_NO_CORRIENDO=4
ERROR_COMANDO_NO_TERMINADO=5
ARCHIVO_LOG=ginicilog
NOMBRE_COMANDO=GINICI
GLOG=glog.sh

# \$1 = Mensaje para mostrar
printAndLog()
{
	echo -e "\$1"
	"./\$GLOG" "\$ARCHIVO_LOG" "\$1" "\$NOMBRE_COMANDO"
}

# La siguiente función ejecuta GEMONI (si éste no se encuentra corriendo).
# Si el comando ya esta corriendo, muestra por pantalla un mensaje que indica cuanto hace que se esta corriendo.
# Si el comando no esta corriendo, lo ejecuta y muestra el ID del proceso.
iniciarGemoni()
{
	comando_a_verificar="gemoni"
	comando=\$(ps | grep "\$comando_a_verificar")
	if [ -z "\$comando" ]
	then
		gemoni.sh &
		if [ \$? -eq 0 ]
		then
			comando=\$(ps | grep "\$comando_a_verificar")
			id=\$(echo \$comando | awk '{print \$1}')
			echo -e "*****************************************************************
* Demonio corriendo bajo el id: \$id\\t\\t\\t\\t*
*****************************************************************"
			return \$FIN_OK
		else
			echo "Se produjo un error al ejecutar el comando GEMONI"
			return \$ERROR_GEMONI
		fi
	else
		tiempo_corriendo=\$(ps -e | grep \$comando_a_verificar | awk '{print \$3}')
		echo "El comando GEMONI se encuentra corriendo hace \$tiempo_corriendo"
		return \$FIN_OK
	fi
}

if [ ! -f "\$ARCHIVO_CONF" ]
then
	printAndLog "Error: No se ha encontrado el archivo \$ARCHIVO_CONF"
	printAndLog "Inicialización de entorno cancelada."
	exit \$ERROR_ARCHIVO_CONF
fi

read ARCHIVO_CONF_GRAL < \$ARCHIVO_CONF

if [ ! -f "\$ARCHIVO_CONF_GRAL" ]
then
	printAndLog "Error: No se ha encontrado el archivo \$ARCHIVO_CONF_GRAL"
	printAndLog "Inicialización de entorno cancelada."
	exit \$ERROR_ARCHIVO_CONF
fi

echo "Iniciando configuración del entorno..."

i=0
while read linea
do
	vectorParametros[\$i]=\${linea#* = }
	i=\`expr \$i + 1\`
done < \$ARCHIVO_CONF_GRAL

# Se settean las variables de ambiente
export GRUPO=\${vectorParametros[1]}
export CONFDIR=\${vectorParametros[2]}
export ANIO=\${vectorParametros[3]}
export BINDIR=\${vectorParametros[4]}
export PATH="\$PATH:\${vectorParametros[1]}:\${vectorParametros[4]}"
export ARRIDIR=\${vectorParametros[5]}
export GASTODIR=\${vectorParametros[6]}
export LOGDIR=\${vectorParametros[8]}
export LOGEXT=\${vectorParametros[9]}
export LOGSIZE=\`echo "\${vectorParametros[10]}" | sed 's/ KB$//'\`

# Se settea una variable de control para saber si GINICI fue ejecutado
export GINICIEXEC=1

echo "Configuración del entorno completada."

case "\$1" in
"-var")
	eval aux=\\\$\$2
	printAndLog "\$2=\`echo \$aux\`"
	exit \$FIN_OK
	;;
"-id")
	comando_a_verificar="\$2"
	comando=\$(ps | grep "\$comando_a_verificar")
	if [ ! -z "\$comando" ]
	then
		id=\$(echo \$comando | awk '{print \$1}')
		printAndLog "Comando \$2 corriendo bajo el id \$id"
		exit \$FIN_OK
	else
		printAndLog "El comando \$2 no esta corriendo"
		exit \$ERROR_COMANDO_NO_CORRIENDO
	fi
	;;
"-kill")
	comando_a_matar="\$2"
	comando=\$(ps | grep "\$comando_a_matar")
	if [ ! -z "\$comando" ]
	then
		id=\$(echo \$comando | awk '{print \$1}')
		kill -9 \$id
		if [ \$? == 0 ]
		then
			printAndLog "El comando \$2 fue terminado satisfactoriamente"
			exit \$FIN_OK
		else
			printAndLog "No se pudo terminar el comando \$2"
			exit \$ERROR_COMANDO_NO_TERMINADO
		fi
	else
		printAndLog "El comando \$2 no esta corriendo"
		exit \$ERROR_COMANDO_NO_CORRIENDO
	fi
	;;
*)
	;;
esac

# Se invoca a GEMONI (si es que no se encuentra corriendo)
iniciarGemoni

exit \$?

EOF
	
	chmod -f 777 "$BINDIR/$GINICI"

	# Se crea el archivo "ginici.conf" en el cual se le indica a GINICI el nombre
	# del archivo de configuración del sistema (gastos.conf).
	# El nombre incluye el path completo
	echo "$CONFDIR/gastos.conf" > "$GRUPO/etc/ginici.conf"
	chmod -f 644 "$GRUPO/etc/ginici.conf"
}

mostrarComponentesInstaldos()
{
	printAndLog "*****************************************************************"
	printAndLog "* Se encuentran instalados los siguientes componentes:\t\t*"
	componentes="$GINICI $GEMONI $GALIDA $GONTRO $GLOG $MOVER"
	printComponents "$componentes" "$BINDIR" 1
	printAndLog "*****************************************************************"
	printAndLog "* FIN del Proceso de Instalación del Sistema de GASTOS\t\t*"
	printAndLog "*\tCopyright TPSistemasOp (c)2008\t\t\t\t*"
	printAndLog "*****************************************************************"
}

instalar()
{
	printAndLog "La instalación se efectuará a partir del directorio: $GRUPO"
	leerEspacioDisponible
	leerDirectorioEjecutables
	leerDirectorioConfiguracion
	leerDirectorioArribos
	leerAnioInicial
	leerDirectorioGastos
	leerDirectorioLog
	leerExtensionArchivoLog
	leerTamanioMaxArchivoLog
	mostrarResumenParametros
	printAndLog " Presione ENTER para iniciar la instalación o cualquier otra tecla para volver atrás"
	readAndLog opcion
	if [ "$opcion" != "" ]
	then
		# Se vuelven a ingresar todos los valores
		clear
		instalar
	else
		confirmarInstalacion
		crearEstructuraDirectorios
		copiarArchivos
		guardarInformacionInstalacion
		crearComandoGinici
		mostrarComponentesInstaldos
		printAndLog "Presione ENTER para salir"
		readAndLog opcion
	fi	
}

# $1 = Directorio donde guardar el archivo de log de la instalación.
inicializarArchivoLog()
{
	> "$1/$ARCHIVO_LOG"
	"./$GLOG" "$ARCHIVO_LOG" "*******************************************************************" "$NOMBRE_COMANDO"
	"./$GLOG" "$ARCHIVO_LOG" "Inicio de Ejecución. Valor \$GRUPO = <$GRUPO>" "$NOMBRE_COMANDO"
}

verificarComponentesInstalados()
{
	printAndLog "Buscando componentes instalados..."

	cantInstalados=0
	cantNoInstalados=0
	componentes=( $GINICI $GEMONI $GALIDA $GONTRO $GLOG $MOVER )
	archConf=$(find "$GRUPO" -name "gastos.conf")

	if [ ! -z "$archConf" ]
	then
		dirEjecutables=$(grep '^BINDIR' "$archConf" | sed 's/^BINDIR = \(.*\)/\1/')

		if [ ! -z "$dirEjecutables" ] && [ -d "$dirEjecutables" ]
		then
			for i in ${componentes[*]}
			do
				archivoEncontrado=$(find "$dirEjecutables" -name "$i")
				if [ ! -z "$archivoEncontrado" ]
				then
					componentesInstalados[$cantInstalados]=${i}
					let cantInstalados++
				else
					componentesNoInstalados[$cantNoInstalados]=${i}
					let cantNoInstalados++
				fi
			done
		
			if [ ${#componentesInstalados} -ge 1 ]
			then
				# Concateno los arrays para pasárselos a la función
				ci=`echo ${componentesInstalados[*]}`
				cni=`echo ${componentesNoInstalados[*]}`
				printComponentsList "$ci" "$cni" "$dirEjecutables"
				if [ ${#componentesNoInstalados} -ge 1 ]
				then
					die "" $ERROR_COMPONENTE_INSTALADO
				else
					die "" $ERROR_PAQUETE_INSTALADO
				fi				
			fi
		fi
	fi
}

#Le asigno permisos de ejecucion a GLOG y a MOVER
chmod +x $GLOG
chmod +x $MOVER

# Se verifica que la variable GRUPO esté setteada
if [ "$GRUPO" = "" ]
then
	inicializarArchivoLog "."
	die "La variable GRUPO no está setteada" $ERROR_VARIABLE_GRUPO
fi

# Se crea e inicializa el archivo de log
inicializarArchivoLog "$GRUPO"

verificarComponentesInstalados

verificarPerl

instalar

fin

exit $FIN_OK


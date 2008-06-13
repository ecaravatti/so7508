SISTEMA GASTOS
--------------

CONTENIDO
---------

* INSTRUCTIVO DE INSTALACIÓN DEL SISTEMA GASTOS
* INSTRUCTIVO DE EJECUCIÓN DEL SISTEMA GASTOS
* EJEMPLO DE EJECUCIÓN


INSTRUCTIVO DE INSTALACIÓN DEL SISTEMA GASTOS
---------------------------------------------

1º) Crear en el directorio corriente el directorio "grupo03"

	mkdir grupo03

2º) Setear manualmente la variable de entorno $GRUPO

	export GRUPO=$PWD/grupo03
	
3º) Ingresar al directorio grupo03

	cd grupo03
	
4º) Copiar el archivo gastos.tgz en el directorio corriente (grupo03)

	cp <direccion_floppy>/gastos.tgz .
	
	(Por lo general la dirección de la unidad de disquete es /media/floppy)

5º) Descomprimir gastos.tgz de manera de generar gastos.tar

	gzip -d gastos.tgz

6º) Extraer los archivos de gastos.tar

	tar -xvf gastos.tar

7º) Ingresar al directorio "install" que se encuentra del directorio corriente (grupo03)

	cd install

8º) Ejecutar el script de instalación

	./ginsta.sh

9º) Seguir los pasos de la instalación, teniendo en cuenta que cuando GINSTA le solicite el ingreso de algún dato, si presiona ENTER automáticamente se tomará el valor por defecto que se muestra entre paréntesis.



INSTRUCTIVO DE EJECUCIÓN DEL SISTEMA GASTOS
-------------------------------------------

1º) Ingresar al directorio grupo03

2º) Correr el comando GINICI

	grupo03$ ./ginici.sh

	Al ejecutar este comando, el mismo llamará automáticamente al comando GEMONI. Este último a su vez llamará al comando GALIDA, el cual a su vez lanzará el comando GONTRO.

	También se puede invocar al comando GINICI para obtener información útil. Por ejemplo:

	Obtener el valor de una variable de entorno:
		$ ./ginici.sh -var GRUPO
	Resultado:
		$ GRUPO = /home/damian/grupo03

	Obtener el ID de un comando:
		$ ./ginici.sh -id gemoni.sh
	Resultado:
		Comando gemoni.sh corriendo bajo el id 6589
		ó
		El comando gemoni.sh no está corriendo

	Detener un proceso:
		$ ./ginici.sh -kill gemoni.sh
	Resultado:
		El comando gemoni.sh fue terminado satisfactoriamente
		ó
		No se pudo terminar el comando

3º) Puede optar por ejecutar el comando GONTRO manualmente:

	$gontro.pl  
	Realiza el control todas las áreas y periodos determinados por los nombres validos de archivos presentes en $GASTODIR/aproc. Corrida tipo test. Genera un archivo final de informe $GRUPO/informe.proc<numero-corrida>.
	
	$gontro.pl -t
	Ídem anterior.
	
	$gontro.pl 112233 200810
	Procesa todos los archivos pertenecientes al área 112233, del periodo 200811. Corrida tipo test
	
	$gontro.pl -t 112233 200810
	Ídem anterior.
	
	$gontro.pl -t -d -d 
	Corrida tipo test sin parámetros (los -d subsiguientes se ignoran).
	
	$gontro.pl -d 200811
	Corrida tipo definitiva. Realiza el control de todos los archivos pertenecientes al periodo 200811. Confecciona una archivo de informe $GRUPO/informe.proc<numero-corrida>; actualiza las tablas de acumulación $CONFDIR/area.acum y $CONFDIR/cxa.acum; genera archivos resúmenes de gastos extraordinarios ($GASTODIR/proc/<área>.ge) y gastos normales ($GASTODIR/proc/<área>.gn); mueve los archivos ya procesados de $GASTODIR/aproc a $GASTODIR/proc.
	

	
EJEMPLO DE EJECUCIÓN
--------------------

thelonious@thelonious-ubuntu:~/install$ ./ginsta.sh
Buscando componentes instalados...
Versión de Perl instalada: 5
La instalación se efectuará a partir del directorio: /home/thelonious/grupo03
Espacio disponible en /home/thelonious/grupo03: 19551332 KB
Si considera que el espacio es suficiente, presione ENTER para continuar.
Si el espacio es insuficiente, presione cualquier otra tecla para cancelar.

Ingrese el nombre del directorio de ejecutables: (/home/thelonious/grupo03/bin)

Ingrese el nombre del directorio para almacenar parámetros y tablas del sistema: (/home/thelonious/grupo03/cnf)

Ingrese el nombre del directorio que permite el arribo de archivos externos: (/home/thelonious/grupo03/arribos)

Ingrese el año a partir del cual se aceptarán los archivos de gastos: (2008)

Ingrese el nombre del directorio de archivos de gastos: (/home/thelonious/grupo03/gastos)

Ingrese el nombre del directorio de logs del sistema: (/home/thelonious/grupo03/log)

Ingrese la extensión de los archivos de log: (.log)

Ingrese el tamaño máximo para los archivos <.log> (en KB): (10)

*********************************************************************************
* Parámetros de la instalación del paquete GASTOS								*
*********************************************************************************
* Directorio de instalación				: /home/thelonious/grupo03				*
* Log de la instalación					: /home/thelonious/grupo03/gastos.log	*
* Espacio disponible en /home/thelonious/grupo03 : 19551332 KB					*
* Biblioteca de ejecutables				: /home/thelonious/grupo03/bin			*
* Biblioteca de tablas y configuración	: /home/thelonious/grupo03/cnf			*
* Directorio de arribos					: /home/thelonious/grupo03/arribos		*
* Año ingresado para aceptar gastos		: 2008									*
* Directorio de gastos					: /home/thelonious/grupo03/gastos		*
* Directorio para archivos de Log		: /home/thelonious/grupo03/log			*
* Extensión para los archivos de Log	: .log									*
* Máximo para los archivos de Log		: 10 KB									*
*********************************************************************************
 Presione ENTER para iniciar la instalación o cualquier otra tecla para volver atrás

Iniciando Instalación... Está Ud. seguro? (Si/No)
Si
Creando estructura de directorios...
Moviendo archivos ejecutables...
Instalación del componente GEMONI completada
Instalación del componente GALIDA completada
Instalación del componente GONTRO completada
Instalación del componente GLOG completada
Instalación del componente MOVER completada
Moviendo archivos de prueba...
Creando archivo de configuración...
Creando el comando Ginici...
*****************************************************************
* Se encuentran instalados los siguientes componentes:			*
* GINICI	thelonious	2008-05-30								*
* GEMONI	thelonious	2008-05-30								*
* GALIDA	thelonious	2008-05-30								*
* GONTRO	thelonious	2008-05-30								*
* GLOG		thelonious	2008-05-30								*
* MOVER		thelonious	2008-05-30								*
*****************************************************************
* FIN del Proceso de Instalación del Sistema de GASTOS			*
*	Copyright TPSistemasOp (c)2008								*
*****************************************************************
Presione ENTER para salir

thelonious@thelonious-ubuntu:~/grupo03/arribos$ ls
000001.201003   000001.201503  000002.200912  000003.201004  000005.201002  000006.202201  abcdef.200803.txt  noreci              reci
000001.201003~  000002.200112  000003.200804  000004.201503  000006.201005  000008.201202  invalid.txt        operativos.0000001  texto 000001.201001

thelonious@thelonious-ubuntu:~/grupo03/bin$ ./ginici.sh
Iniciando configuración del entorno...
Configuración del entorno completada.
*****************************************************************
* Demonio corriendo bajo el id: 7464							*
*****************************************************************

thelonious@thelonious-ubuntu:~/grupo03/bin$ ./ginici.sh -var GRUPO
Iniciando configuración del entorno...
Configuración del entorno completada.
GRUPO=/home/thelonious/grupo03

thelonious@thelonious-ubuntu:~/grupo03/bin$ ./ginici.sh -id gemoni
Iniciando configuración del entorno...
Configuración del entorno completada.
Comando gemoni corriendo bajo el id 20146


Informe de control del area 000001 para el periodo 201503
Presupuesto Mensual del area: 1250.87
Acumulado Inicial: 0
Acumulado Final:  231969.7
Cantidad de Registros y Total de Gastos normales procesados: 0 0
Cantidad de Registros y Total de Gastos extraordinarios: 25 231969.7

Informe de control del area 000002 para el periodo 200912
Presupuesto Mensual del area: 1980.52
Acumulado Inicial: 0
Acumulado Final:  95562.4
Cantidad de Registros y Total de Gastos normales procesados: 5 481.55
Cantidad de Registros y Total de Gastos extraordinarios: 21 95080.85
Informe de control del area 000003 para el periodo 201004
.
.
<continua>

thelonious@thelonious-ubuntu:~/grupo03/bin$ ./ginici.sh -kill gemoni
Iniciando configuración del entorno...
Configuración del entorno completada.
El comando gemoni fue terminado satisfactoriamente


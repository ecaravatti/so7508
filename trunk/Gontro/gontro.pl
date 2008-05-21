#!usr/bin/perl -w
####################################################################
#	Archivo   : gontro.pl
#	Módulo   : GONTRO
####################################################################
#	75.08 Sistemas Operativos
#	Trabajo práctico
####################################################################
#	Descripción
#		Efectua los controles correspondientes a los registros
#		de los archivos de gastos que se quieran procesar.
#		Emite el informe correspondiente.
####################################################################
#	Integrantes
#		- Alvarez Fantone, Nicolas;
#       - Caravatti, Estefanía;
#		- Garcia Cabrera, Manuel;
#		- Pisaturo, Damian;	
#		- Rodriguez, Maria Laura.
####################################################################

use strict;
use warnings;
use gontrosub;

#Chequear que el entorno haya sido inicializado
gontrosub::estaEntornoInicializado() or gontrosub::logFatalError("El proceso no puede ser iniciado. Entorno no inicializado.");

#Obtencion del numero de corrida
my $procnum = gontrosub::getProcNum();

#Grabar inicio en el archivo de log
gontrosub::log("Inicio de ejecucion");

#Determinar tipo de corrida
my ($corridaValida, $tipoCorrida, $area, $periodo, @argsInvalidos) = gontrosub::getTipoCorrida(@ARGV);

if ($corridaValida == 1) {
	#Grabar tipo de corrida en el archivo de log
	gontrosub::log("Tipo de corrida $tipoCorrida, Area a procesar = $area, Periodo a procesar = $periodo");
   
   	#Obtener nombres de archivos con area y periodo dados
   	my @nombreArchivos = <$ENV{'GASTODIR'}/aproc/$area.$periodo.ord>;

   	#Inicializacion de variables necesarias para el proceso de archivos
   	my ($presupuestoMensual, $gastoAcumulado) = (0, 0);
   	my ($gastosNormales, $gastosExtraordinarios, $montoNormal, $montoExtraordinario) = (0, 0, 0, 0);
   	my ($nuevosMontosxConcepto, $nuevasRepeticionesxConcepto) = (0, 0);
   	my (@conceptos, @conceptosAcumulados) = ();
   	my @datosArchivoGastos = ();

   	#Procesar todos los archivos afectados
   	foreach( @nombreArchivos ) {
   		#Grabar estado de proceso en el archivo de log
   		gontrosub::log("Procesando Archivo: $_");
   		
   		#Obtener area y periodo para el archivo en proceso
   		(/$ENV{'GASTODIR'}\/aproc\/(\d{6}).(\d{6}).ord/) && ($area = $1) && ($periodo = $2);
   		
   		#Obtener presupuesto mensual y gasto acumulado para el area/periodo
      	$presupuestoMensual = gontrosub::getPresupuestoMensual($area, "$ENV{'CONFDIR'}/area.tab");
      	$gastoAcumulado = gontrosub::getGastoAcumulado($area, $periodo, "$ENV{'CONFDIR'}/area.acum");
      	
      	#Obtener conceptos por area (montos maximos y repeticiones)
      	@conceptos = gontrosub::getConceptos($area, "$ENV{'CONFDIR'}/cxa.tab");
      
      	#Obtener conceptos acumulados por area y periodo(montos maximos y repeticiones)
      	@conceptosAcumulados = gontrosub::getConceptosAcumulados($area, $periodo, "$ENV{'CONFDIR'}/cxa.acum");

      	#Crear estructura de datos para el procesamiento de archivo
      	@datosArchivoGastos = ($_, $presupuestoMensual, $gastoAcumulado, @conceptos, @conceptosAcumulados);
      	
      	#Procesamiento de los registros del archivo de gastos
      	($montoExtraordinario, $gastosExtraordinarios,
      	$montoNormal, $gastosNormales,
      	$nuevosMontosxConcepto, $nuevasRepeticionesxConcepto) = gontrosub::procesarArchivoGastos(@datosArchivoGastos);

      	#Si la corrida es definitiva, actualizar las acumulaciones y generar los archivos de gastos 
      	if ("$tipoCorrida" eq "-d") {
			gontrosub::actualizarArea($area, $periodo, $gastoAcumulado + $montoExtraordinario + $montoNormal, "$ENV{'CONFDIR'}/area.acum");
				
			gontrosub::actualizarCxA($area, $periodo, $nuevosMontosxConcepto, $nuevasRepeticionesxConcepto, "$ENV{'CONFDIR'}/cxa.acum");
				
			gontrosub::generarArchivoGN($gastosNormales, "$ENV{'GASTODIR'}/proc/$area.gn") if @{$gastosNormales} > 0; 
				
			gontrosub::generarArchivoGE($gastosExtraordinarios, "$ENV{'CONFDIR'}/proc/$area.ge", "$ENV{'CONFDIR'}/motivos.tab") if @{$gastosExtraordinarios} > 0;
				
			`mover.sh $_ $ENV{'GASTODIR'}/proc/$area.$periodo.ord gontrolog`;
	     }      	
		
      	#Generar informe final y mostrarlo por pantalla
      	gontrosub::generarInforme($area, $periodo, $presupuestoMensual,
      				$gastoAcumulado,$#{$gastosExtraordinarios}, $montoExtraordinario,
      				$#{$gastosNormales}, $montoNormal,
      				"$ENV{'GRUPO'}/informe.proc" . "$procnum");
   	}

} else {
	
	#Mensajes de error ante parametros erroneos
  	foreach(@argsInvalidos) {
  		gontrosub::log("GONTRO: $_: opcion desconocida") &&
		(print "GONTRO: $_: opcion desconocida\n") if ($corridaValida == 2);
       		
		gontrosub::log("GONTRO: $_: area/periodo invalido (6 digitos)") &&
		(print "GONTRO: $_: area/periodo invalido (6 digitos)\n") if ($corridaValida == 3);

       		gontrosub::log("GONTRO: $_: argumento invalido") &&
		(print "GONTRO: $_: argumento invalido\n") if ($corridaValida == 4);
  	}
   	
	gontrosub::log("GONTRO: -d: se esperaba argumento [periodo]") &&
   	(print "GONTRO: -d: se esperaba argumento [periodo]\n") if ($corridaValida == 5);

	print "Uso: GONTRO [-t] [-d periodo] [area|periodo]\n";
};

exit 1;

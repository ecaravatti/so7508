#!/usr/bin/perl -w
####################################################################
#	Archivo   : gontrosub.pl
#	Módulo	  : GONTRO
####################################################################
#	75.08 Sistemas Operativos
#	Trabajo práctico
####################################################################
#	Descripción
#		Paquete de subrutinas empleadas por el modulo GONTRO.
####################################################################
#	Integrantes
#		- Alvarez Fantone, Nicolas;
#       - Caravatti, Estefanía;
#		- Garcia Cabrera, Manuel;
#		- Pisaturo, Damian;	
#		- Rodriguez, Maria Laura.
####################################################################

use Tie::File;
package gontrosub;

sub getProcNum { 

	my @nomArchivoProc = <$ENV{'GRUPO'}/etc/gprocnum.*>;
	
	gontrosub::logFatalError("Imposible determinar numero de corrida. Se esperaba solo un archivo valido en $ENV{'GRUPO'}/etc") if @nomArchivoProc > 1;
	($nomArchivoProc[0] = "$ENV{'GRUPO'}/etc/gprocnum.0") && (`>"$ENV{'GRUPO'}/etc/gprocnum.0"`) if !@nomArchivoProc;
	
	$nomArchivoProc[0] =~ /.*\/.*\.(\d+)/;	
		
	my $procnum = $1 + 1;
	
	`mv $nomArchivoProc[0] $ENV{'GRUPO'}/etc/gprocnum.$procnum`;
	
	return $1;
}

sub iniciarEntorno {
	gontrosub::logFatalError("El archivo de configuracion $ENV{'GRUPO'}/etc/gontro.conf no existe o no tiene permisos de lectura") if !(-r "$ENV{'GRUPO'}/etc/gontro.conf");
	open my $archivoConf, "$ENV{'GRUPO'}/etc/gontro.conf" or gontrosub::logFatalError("Error al abrir archivo de configuracion $ENV{'GRUPO'}/etc/gontro.conf");
	
	foreach ( <$archivoConf> ){
		chomp;
		$_ =~ /(\D+) = (.*)/;
		$ENV{"$1"}="$2";
	}
	
	close $archivoConf or gontrosub::logFatalError("Error al cerrar archivo de configuracion $ENV{'GRUPO'}/etc/gontro.conf");
	return;	
}

sub getTipoCorrida {
    my ($valida, $tipoCorrida, $area, $periodo) = (1, 0, "*", "*");
    my @argsInvalidos = ();
    my @parametros = @_;

    foreach(@parametros) {
    	if (/-./) {
    		if (/-d/) {
    			(!$tipoCorrida) && ($tipoCorrida = "-d");
    		} elsif (/-t/) {
    			(!$tipoCorrida) && ($tipoCorrida="-t");
    		} else {
    			$valida = 2;
    			push(@argsInvalidos, "$_");
    		}
    	} elsif (/\d+/) {
    		if (/(^\d{6})$/) {
    			( ("$periodo" eq "*") && ($periodo = "$1") ) ||
    			( ("$area" eq "*") && ($area = "$1") );
    		} elsif (/\D+/) {
    			$valida=6;
    			push(@argsInvalidos, "$_");
    		} else {
    			$valida = 3;
    			push(@argsInvalidos, "$_");
    		}
    	} else {
    		$valida = 4;
          	push(@argsInvalidos, "$_");
       	}
    }

    #Si no existen opciones, -t por defecto
    (!$tipoCorrida) && ($tipoCorrida = "-t");
    
    #Obliga a especificar un periodo ante la opcion -d
    ($tipoCorrida eq "-d") && ("$periodo" eq "*") && ($valida == 1) && ($valida = 5);

    return ($valida, $tipoCorrida, $area, $periodo, @argsInvalidos);
}

sub getPresupuestoMensual {
    my $area = shift;
    my $nomArchivoArea = shift;
    my $presupuestoMensual = 0;
    
    open(my $tablaAreas, $nomArchivoArea) or gontrosub::logFatalError("Error al abrir archivo $nomArchivoArea");

    foreach( <$tablaAreas> ) {
    	chomp;
    	last if ( (/$area;.*;(\d+\.?\d{2}?)/) && ($presupuestoMensual = $1) );
    }
    
    close $tablaAreas or gontrosub::logFatalError("Error al cerrar archivo $nomArchivoArea");
    
    return $presupuestoMensual;
}

sub getGastoAcumulado {
    my ($area, $periodo, $nombreArchivoAcum) = (shift, shift, shift);
    
    return 0 unless (-f "$nombreArchivoAcum");
    
    open(my $acumuladoAreas, "$nombreArchivoAcum") or gontrosub::logFatalError("Error al abrir $nombreArchivoAcum");
    
    foreach( <$acumuladoAreas> ) {
    	chomp;
    	last if ( (/$area;$periodo;(\d+\.?\d{2}?)/) && ($gastoAcumulado = $1) );
    }
    
    close $acumuladoAreas or gontrosub::logFatalError("Error al cerrar archivo $nombreArchivoAcum");
  

    return $gastoAcumulado;
}

sub getConceptos {
    my ($area, $nombreArchivoCxA) = (shift, shift);
    my (%montoxConcepto, %montoxComprobante, %limiteRepeticiones) = ();

    open(my $tablaCxA, "$nombreArchivoCxA") or gontrosub::logFatalError("Error al abrir $nombreArchivoCxA");
   
    foreach( <$tablaCxA> ) {
    	chomp;
    	(/$area;(\d{6});(\d+\.?\d{2}?);(\d+\.?\d{2}?);(\d{5})/) &&
    	( $montoxConcepto{$1} = $3) &&
       	( $montoxComprobante{$1} = $2) &&
       	( $limiteRepeticiones{$1} = $4);
    }
        
    close $tablaCxA or gontrosub::logFatalError("Error al cerrar $nombreArchivoCxA");

    return (\%montoxConcepto, \%montoxComprobante, \%limiteRepeticiones);
}

sub getConceptosAcumulados {
    my ($area, $periodo, $nombreArchivoCxA) = (shift, shift, shift);
    my (%montoxConcepto, %repeticiones) = ();
	
	return () unless (-f "$nombreArchivoCxA");
	
    open(my $tablaCxAAcum, "$nombreArchivoCxA") or gontrosub::logFatalError("Error al abrir $nombreArchivoCxA");

    foreach( <$tablaCxAAcum> ) {
    	chomp;
    	(/$area;(\d{6});$periodo;(\d+\.?\d{2}?);(\d{5})/) && 
    	($montoxConcepto{$1} = $2) &&
    	($repeticiones{$1} = $3);
   	}

    close $tablaCxAAcum or gontrosub::logFatalError("Error al cerrar $nombreArchivoCxA");

    return (\%montoxConcepto, \%repeticiones);
}

sub procesarArchivoGastos {
    my ($nombreArchivo,
    	$periodo,
        $presupuestoMensual,
        $gastoAcumulado,
        $montoMaximoxConcepto,
        $montoMaximoxComprobante,
        $limiteRepeticiones,
        $montoxConceptoAcumulado,
        $repeticionesxConcepto) = @_;
        
    my $gastoInicial= $gastoAcumulado;
    my (@gastosNormales, @gastosExtraordinarios) = ();
    my ($regNormal, $regExtraordinario) = (0, 0);
    my ($motivoPrincipal, $motivoSecundario) = (0, 0);
    my $esExtraordinario = 0;
    my ($montoNormal, $montoExtraordinario, $fecha) = (0, 0, 0);
    
    $periodo =~ s/(\d{4})(\d{2})/$2$1/;
    
    open (my $archivoGastos, "$nombreArchivo") or gontrosub::logFatalError("Error al abrir $nombreArchivo");
        
    foreach ( <$archivoGastos> ){
    	chomp;
    	$motivoPrincipal = $motivoSecundario = $esExtraordinario = 0;
    	
    	/(\d{2});(.+);(\d{6});(\d+\.?\d{2}?)/;
		
		#Generar campo fecha
		$fecha="$1"."$periodo";
		
        #Gasto acumulado no debe exceder el presupuesto mensual
        $gastoAcumulado += $4;
        if ($gastoAcumulado > $presupuestoMensual) {
        	$motivoPrincipal = 1;
        	$esExtraordinario = 1;      
        }
        
        #Chequear que el concepto exista
        if (!exists $montoMaximoxConcepto->{$3}){
        	((!$motivoPrincipal) && ($motivoPrincipal = 5)) ||
        	($motivoSecundario = 5);
        	$esExtraordinario = 1;
        } else {
        	        
	        #Chequear que el monto acumulado por concepto no supere el maximo establecido
	        $montoxConceptoAcumulado->{$3} += $4;
	        if ($montoxConceptoAcumulado->{$3} > $montoMaximoxConcepto->{$3}) {
        		((!$motivoPrincipal) && ($motivoPrincipal = 2)) ||
        		($motivoSecundario = 2);
	        	$esExtraordinario = 1;
	        }
	
	        #Chequear que las repeticiones acumuladas por concepto no superen su limite
	        $repeticionesxConcepto->{$3}++;
	       	if ($repeticionesxConcepto->{$3} > $limiteRepeticiones->{$3}) {
        		((!$motivoPrincipal) && ($motivoPrincipal = 3)) ||
        		((!$motivoSecundario) && ($motivoSecundario = 3));
	       		$esExtraordinario = 1;
	       	}
	       	
	       	#Chequear que el importe por concepto no exceda el monto maximo por comprobante
	        if ($4 > $montoMaximoxComprobante->{$3}){
        		((!$motivoPrincipal) && ($motivoPrincipal = 4)) ||
        		((!$motivoSecundario) && ($motivoSecundario = 4));
	        	$esExtraordinario = 1;
	        }  
        }
        
        #Construir registro para archivo de gastos normales/extraordinarios
        if ($esExtraordinario){
        	$montoExtraordinario += $4;
        	$regExtraodinario = [$fecha, $3, $2, $4, $motivoPrincipal, $motivoSecundario];
        	push(@gastosExtraordinarios, $regExtraodinario);
        } else {
        	$montoNormal += $4;
        	$regNormal = [$fecha, $3, $2, $4];
        	push(@gastosNormales, $regNormal);
        }
   }
   
   close $archivoGastos or gontrosub::logFatalError("Error al cerrar $nombreArchivo");

   return ( $montoExtraordinario, \@gastosExtraordinarios,  
   			$montoNormal, \@gastosNormales,
   			$montoxConceptoAcumulado, $repeticionesxConcepto);
}

sub actualizarAreaAcum {
	my ($area, $periodo, 
	$nuevoMonto, $nombreArchivo) = (shift, shift, shift, shift);
	
	tie my @lineasTabla, 'Tie::File', $nombreArchivo or gontrosub::logFatalError("Error al asociar el archivo $nombreArchivo");
	
	foreach ( @lineasTabla ){
		chomp;
		last if (s/$area;$periodo;(\d+\.?\d{2}?)/$area;$periodo;$nuevoMonto/g);
	}
	
	untie @lineasTabla or gontrosub::logFatalError("Error al desasociar $nombreArchivo");
	
	return;	
}

sub crearNuevoAreaAcum {
	my @nuevoRegistro = (shift, shift, shift);
	my $nombreArchivo = shift;
	
	open my $archivoAreaAcum, ">>$nombreArchivo" or gontrosub::logFatalError("Error al abrir o crear el archivo $nombreArchivo");
	print $archivoAreaAcum join(';', @nuevoRegistro),"\n";	
	close $archivoAreaAcum or gontrosub::logFatalError("Error al cerrar el archivo $nombreArchivo");
		
	return;
}
sub actualizarArea {
	my ($area, $periodo, 
	$nuevoMonto, $nombreArchivo) = (shift, shift, shift, shift);
	
	if ( -f "$nombreArchivo" ){
		gontrosub::actualizarAreaAcum($area, $periodo, $nuevoMonto, $nombreArchivo);
	} else {
		gontrosub::crearNuevoAreaAcum($area, $periodo, $nuevoMonto, $nombreArchivo);	
	}
	
	return;
}

sub actualizarCxAAcum {
	my ($area, $periodo, 
	$nuevosMontos, $nuevasRepeticiones,
	$nombreArchivo) = (shift, shift, shift, shift, shift);
	my $repeticion = 0;
		
	tie my @lineasTabla, 'Tie::File', $nombreArchivo or gontrosub::logFatalError("No se pudo asociar el archivo $nombreArchivo");

	foreach ( @lineasTabla ){
		chomp;
		(/$area;(\d{6});$periodo;(\d+\.\d{2});\d{5}/) &&
		($repeticion = sprintf "%05s", $nuevasRepeticiones->{$1}) &&
		($_ = "$area;$1;$periodo;$nuevosMontos->{$1};$repeticion");		
	}
	
	untie @lineasTabla or gontrosub::logFatalError("Error al asociar el archivo $nombreArchivo");

	return;	
}

sub crearNuevoCxAAcum {
	my ($area, $periodo, 
	$nuevosMontos, $nuevasRepeticiones,
	$nombreArchivo) = (shift, shift, shift, shift, shift);
	my $repeticion = 0;
	
	open my $archivoCxA, ">>$nombreArchivo" or gontrosub::logFatalError("Error al abrir el archivo $nombreArchivo");
	
	foreach my $concepto (keys %{$nuevosMontos}){
		$repeticion = sprintf "%05s", $nuevasRepeticiones->{$concepto};
		print $archivoCxA "$area;$concepto;$periodo;$nuevosMontos->{$concepto};$repeticion\n";	
	}
	
	close $archivoCxA or gontrosub::logFatalError("Error al cerrar el archivo $nombreArchivo");
	
	return;
}

sub actualizarCxA {
	my ($area, $periodo, 
		$nuevosMontos, $nuevasRepeticiones,
		$nombreArchivo) = (shift, shift, shift, shift, shift);	
		
	if ( -f "$nombreArchivo" ){
		gontrosub::actualizarCxAAcum($area, $periodo, $nuevosMontos, $nuevasRepeticiones, $nombreArchivo);
	} else {
		gontrosub::crearNuevoCxAAcum($area, $periodo, $nuevosMontos, $nuevasRepeticiones, $nombreArchivo);	
	}	
}

sub generarArchivoGN {
	my ($gastosNormales, $nombreArchivo) = (shift, shift);
	
	open (my $archivoGN, ">> $nombreArchivo") or gontrosub::logFatalError("Error al abrir o crear archivo $nombreArchivo");
	
	foreach my $camposRegGN (@{$gastosNormales}){
		print $archivoGN join(';',@{$camposRegGN}),"\n";#"$camposRegGN->[0];$camposRegGN->[1];$camposRegGN->[2];$camposRegGN->[3]\n";		
	}

	close $archivoGN or gontrosub::logFatalError("Error al cerrar archivo $archivoGN");

	return ;
}

sub generarArchivoGE {
	my ($gastosExtraordinarios, $nombreArchivoGE, $nombreArchivoMotivos) = (shift, shift, shift);
	my ($motivoPrincipal, $motivoSecundario) = (0, 0);
	
	open (my $archivoGE, ">> $nombreArchivoGE") or gontrosub::logFatalError("Error al abrir o crear archivo $nombreArchivoGE");
	open (my $archivoMotivos, "$nombreArchivoMotivos") or gontrosub::logFatalError("Error al abrir archivo $nombreArchivoMotivos");
	my @motivos = <$archivoMotivos>;
	chomp @motivos;
	
	foreach my $camposRegGE (@{$gastosExtraordinarios}){
		$motivoPrincipal = $motivoSecundario = 0;
		print $archivoGE "$camposRegGE->[0];$camposRegGE->[1];$camposRegGE->[2];$camposRegGE->[3];";
				
		foreach ( @motivos ){
			/$camposRegGE->[4];(.+)/ && ($motivoPrincipal = "$1");
			/$camposRegGE->[5];(.+)/ && ($motivoSecundario = "$1"); 
			last if $motivoPrincipal && $motivoSecundario;
		}
		
		$motivoPrincipal = "Motivo principal desconocido" if !$motivoPrincipal;
		$motivoSecundario = "Motivo secundario desconocido" if !$motivoSecundario;
		$motivoSecundario = "No existe motivo secundario" if "$camposRegGE->[5]" eq "0"; 
		
		print $archivoGE "$motivoPrincipal;$motivoSecundario\n";		
	}
	
	close $archivoGE or gontrosub::logFatalError("Error al cerrar archivo $nombreArchivoGE");
	close $archivoMotivos or gontrosub::logFatalError("Error al cerrar archivo $nombreArchivoMotivos");
	
	return ;
}

sub generarInforme {
	my ($area, 
		$periodo, 
		$presupuestoMensual,
		$totalxAreaInicial,
		$cantExtraordinarios,
		$montoExtraordinario,
		$cantNormales,
		$montoNormal,
		$nombreInforme) = @_;
		
	$cantNormales++;
	$cantExtraordinarios++;
	my $acumFinal=$totalxAreaInicial + $montoNormal + $montoExtraordinario;
	my $textoInforme = "Informe de control del area $area para el periodo $periodo\n";
	
	$textoInforme.="Presupuesto Mensual del area: $presupuestoMensual\n";
	$textoInforme.="Acumulado Inicial: $totalxAreaInicial\n";
	$textoInforme.="Acumulado Final:  $acumFinal\n";
	$textoInforme.="Cantidad de Registros y Total de Gastos normales procesados: $cantNormales $montoNormal\n";
	$textoInforme.="Cantidad de Registros y Total de Gastos extraordinarios: $cantExtraordinarios $montoExtraordinario\n\n";
	
	open (my $informe, ">> $nombreInforme") or gontrosub::logFatalError("Error al abrir archivo $nombreInforme");
	
	print $informe "$textoInforme";
	#print "$textoInforme";
	
	close $informe or gontrosub::logFatalError("Error al cerrar $nombreInforme");
}

sub log {
	my $logMsg = shift;

	`glog.sh gontrolog "$logMsg" GONTRO`;

	return 1;
}

sub logFatalError {
	my $error = shift;
	
	gontrosub::log("$error");
	die "$error - Error";
}

1;
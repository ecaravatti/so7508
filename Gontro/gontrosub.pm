#!usr/bin/perl -w
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

sub estaEntornoInicializado {
	return 1 if exists $ENV{'GINICIEXEC'}; 
	
	return 0;	
}

sub getProcNum {
	my $procnum = $ENV{'GPROCNUM'};
	$ENV{'GPROCNUM'} = $procnum + 1;		

	return $procnum;
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
    		if (/(\d{6})/) {
    			( ($periodo ne "*") && ($periodo = $1) ) ||
    			( ($area ne "*") && ($area = $1) );
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
    ($tipoCorrida eq "-d") && (!$periodo) && ($valida = 5);

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
    my $presupuestoMensual = 0;
    
    return () unless (-f "$nombreArchivoAcum");
    
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
	
    open(my $tablaCxAAcum, ">$nombreArchivoCxA") or gontrosub::logFatalError("Error al abrir $nombreArchivoCxA");

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
    my ($montoNormal, $montoExtraordinario) = (0, 0);
    my $fecha = "09072008"; #/TODO De donde se saca la fecha?
    
    open (my $archivoGastos, "$nombreArchivo") or gontrosub::logFatalError("Error al abrir $nombreArchivo");
        
    foreach ( <$archivoGastos> ){
    	chomp;
    	$motivoPrincipal = $motivoSecundario = $esExtraordinario = 0;
    	
    	/(\d{2});(.+);(\d{6});(\d+\.?\d{2}?)/;

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
	
	open my $archivoAreaAcum, ">>$nombreArchivo" or gontrosub::logFatalError("Error al abrir el archivo $nombreArchivo");
	print $archivoAreaAcum join(';', @nuevoRegistro);	
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
	
	tie my @lineasTabla, 'Tie::File', $nombreArchivo or gontrosub::logFatalError("No se pudo asociar el archivo $nombreArchivo");

	foreach ( @lineasTabla ){
		chomp;
		s/$area;(\d{6});$periodo;(\d+\.?\d{2}?);\d{5}/$area;$1;$periodo;$nuevosMontos->{$1};$nuevasRepeticiones->{$1}/g;			
	}
	
	untie @lineasTabla or gontrosub::logFatalError("Error al asociar el archivo $nombreArchivo");

	return;
	
}

sub crearNuevoCxAAcum {
	my ($area, $periodo, 
	$nuevosMontos, $nuevasRepeticiones,
	$nombreArchivo) = (shift, shift, shift, shift, shift);
	
	open my $archivoCxA, ">>$nombreArchivo" or gontrosub::logFatalError("Error al abrir el archivo $nombreArchivo");
	
	foreach my $concepto (keys %{$nuevosMontos}){
		print $archivoCxA "$area;$concepto;$periodo;$nuevosMontos->{$concepto};$nuevasRepeticiones->{$concepto}\n";	
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
	
	open (my $archivoGN, ">> $nombreArchivo") or gontrosub::logFatalError("Error al abrir archivo $nombreArchivo");
	
	foreach my $camposRegGN (@{$gastosNormales}){
		print $archivoGN join(';',@{$camposRegGN});#"$camposRegGN->[0];$camposRegGN->[1];$camposRegGN->[2];$camposRegGN->[3]\n";		
	}

	close $archivoGN or gontrosub::logFatalError("Error al cerrar archivo $archivoGN");

	return ;
}

sub generarArchivoGE {
	my ($gastosExtraordinarios, $nombreArchivoGE, $nombreArchivoMotivos) = (shift, shift, shift);
	my ($motivoPrincipal, $motivoSecundario) = (0, 0);
	
	open (my $archivoGE, ">> $nombreArchivoGE") or gontrosub::logFatalError("Error al abrir archivo $nombreArchivoGE");
	open (my $archivoMotivos, $nombreArchivoMotivos) or gontrosub::logFatalError("Error al abrir archivo $nombreArchivoMotivos");
	
	foreach my $camposRegGE (@{$gastosExtraordinarios}){
		$motivoPrincipal = $motivoSecundario = 0;
		print $archivoGE join(';',@{$camposRegGE});#"$camposRegGE->[0];$camposRegGE->[1];$camposRegGE->[2];$camposRegGE->[3];";
		
		foreach ( <$archivoMotivos> ){
			chomp;
			/$camposRegGE->[4];(.+)/ && ($motivoPrincipal = $1);
			/$camposRegGE->[5];(.+)/ && ($motivoSecundario = $1); 
			last if $motivoPrincipal && $motivoSecundario;
		}
		
		$motivoPrincipal = "Motivo desconocido" if !$motivoPrincipal;
		$motivoSecundario = "Motivo desconocido" if !$motivoSecundario;
		
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
		
	$cantNormales = 0 if $cantNormales < 0;
	$cantExtraordinarios = 0 if $cantExtraordinarios < 0;
	
	open (my $informe, ">> $nombreInforme") or gontrosub::logFatalError("Error al abrir archivo $nombreInforme");
		
	print $informe "\nInforme de control del rea $area para el periodo $periodo\n";
	print $informe "Presupuesto Mensual del area: $presupuestoMensual\n";
	print $informe "Acumulado Inicial: $totalxAreaInicial\n";
	print $informe "Acumulado Final: ",  $totalxAreaInicial + $montoNormal + $montoExtraordinario,"\n";
	print $informe "Cantidad de Registros y Total de Gastos normales procesados: $cantNormales $montoNormal\n";
	print $informe "Cantidad de Registros y Total de Gastos extraordinarios: $cantExtraordinarios $montoExtraordinario\n";
	
	close $informe or gontrosub::logFatalError("Error al cerrar $nombreInforme");
}

sub log {
	my $logMsg = shift;

	`glog.sh gontrolog $logMsg GONTRO`;

	return;
}

sub logFatalError {
	my $error = shift;
	
	gontrosub::log("$error");
	die "$error";
}

1;
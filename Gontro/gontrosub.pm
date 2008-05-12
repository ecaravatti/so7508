#!C:/Perl/bin/perl.exe -w
####################################################################
#	Archivo   : gontrosub.pl
#	Módulo	  : GONTRO
####################################################################
#	75.08 Sistemas Operativos
#	Trabajo practico
####################################################################
#	Descripcion
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
	my ($confilename, $procnum, $primerProc) = (shift, 0, 1);
	tie my @lineasconf, 'Tie::File', $confilename or die "No se pude asociar el archivo $confilename: $!";

    foreach(@lineasconf){
       last if ((/GPROCNUM/i) && (s/(\d+)/$1+1/ge) && ($procnum = $1+1) && ($primerProc = 0));
    };

    push(@lineasconf, "GPROCNUM = 0") if $primerProc;
    untie @lineasconf or die "$!";
    
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
    
    open(my $tablaAreas, $nomArchivoArea) or die "$!";

    foreach( <$tablaAreas> ) {
    	last if ( (/$area;.*;(\d+\.\d{2}|\d+)(\n|$)/) && ($presupuestoMensual = $1) );
    }
    
    close $tablaAreas or die "$!";
    
    return $presupuestoMensual;
}

sub getGastoAcumulado {
    my ($area, $periodo, $nombreArchivoAcum) = (shift, shift, shift);
    my $presupuestoMensual = 0;
    
    open(my $acumuladoAreas, $nombreArchivoAcum) or die "$!";
    
    foreach( <$acumuladoAreas> ) {
    	last if ( (/$area;$periodo;(\d+\.\d{2}|\d+)/) && ($gastoAcumulado = $1) );
    }
    
    close $acumuladoAreas;

    return $gastoAcumulado;
}

sub getConceptos {
    my ($area, $nombreArchivoCxA) = (shift, shift);
    my (%montoxConcepto, %montoxComprobante, %limiteRepeticiones) = ();

    open(my $tablaCxA, $nombreArchivoCxA) or die "$!";
   
    foreach( <$tablaCxA> ) {
    	(/$area;(\d{6});(\d+\.\d{2}|\d+);(\d+\.\d{2}|\d+);(\d{5})/) &&
    	( $montoxConcepto{$1} = $3) &&
       	( $montoxComprobante{$1} = $2) &&
       	( $limiteRepeticiones{$1} = $4);
    }
        
    close $tablaCxA or die "$!";

    return (\%montoxConcepto, \%montoxComprobante, \%limiteRepeticiones);
}

sub getConceptosAcumulados {
    my ($area, $periodo, $nombreArchivoCxA) = (shift, shift, shift);
    my (%montoxConcepto, %repeticiones) = ();

    open(my $tablaCxAAcum, $nombreArchivoCxA) or die "$!";

    foreach( <$tablaCxAAcum> ) {
    	(/$area;(\d{6});$periodo;(\d+\.\d{2}|\d+);(\d{5})/) && 
    	($montoxConcepto{$1} = $2) &&
    	($repeticiones{$1} = $3);
   	}

    close $tablaCxAAcum or die "$!";

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
    
    open (my $archivoGastos, $nombreArchivo) or die "$!";
        
    foreach ( <$archivoGastos> ){
    	$motivoPrincipal = $motivoSecundario = $esExtraordinario = 0;
    	
    	/(\d{2});(.+);(\d{6});(\d+\.\d+|\d+)/;

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
   
   close $archivoGastos or die "$!";
   
   return ( $montoExtraordinario, \@gastosExtraordinarios,  
   			$montoNormal, \@gastosNormales,
   			$montoxConceptoAcumulado, $repeticionesxConcepto);
}

sub actualizarArea {
	my ($area, $periodo, 
		$nuevoMonto, $nombreArchivo) = (shift, shift, shift, shift);
	
	tie my @lineasTabla, 'Tie::File', $nombreArchivo or die "No se pude asociar el archivo $nombreArchivo: $!";
	
	foreach ( @lineasTabla ){
		last if (s/$area;$periodo;(\d+\.\d+|\d+)/$area;$periodo;$nuevoMonto/g);
	}
	
	untie @lineasTabla or die "$!";
	
	return;
}

sub actualizarCxA {
	my ($area, $periodo, 
		$nuevosMontos, $nuevasRepeticiones,
		$nombreArchivo) = (shift, shift, shift, shift, shift);
	
	tie my @lineasTabla, 'Tie::File', $nombreArchivo or die "No se pude asociar el archivo $nombreArchivo: $!";

	foreach ( @lineasTabla ){
		s/$area;(\d{6});$periodo;(\d+\.\d+|\d+);\d{5}/$area;$1;$periodo;$nuevosMontos->{$1};$nuevasRepeticiones->{$1}/g;			
	}
	
	untie @lineasTabla or die "$!";

	return;
}

sub generarArchivoGN {
	my ($gastosNormales, $nombreArchivo) = (shift, shift);
	
	open (my $archivoGN, ">> $nombreArchivo") or die "$!";
	
	foreach my $camposRegGN (@{$gastosNormales}){
		print $archivoGN "$camposRegGN->[0];$camposRegGN->[1];$camposRegGN->[2];$camposRegGN->[3]\n";		
	}

	close $archivoGN or die "$!";

	return ;
}

sub generarArchivoGE {
	my ($gastosExtraordinarios, $nombreArchivoGE, $nombreArchivoMotivos) = (shift, shift, shift);
	my ($motivoPrincipal, $motivoSecundario) = (0, 0);
	
	open (my $archivoGE, ">> $nombreArchivoMotivos") or die "$!";
	open (my $archivoMotivos, $nombreArchivoMotivos) or die "$!";
	
	foreach my $camposRegGE (@{$gastosExtraordinarios}){
		$motivoPrincipal = $motivoSecundario = 0;
		print $archivoGE "$camposRegGE->[0];$camposRegGE->[1];$camposRegGE->[2];$camposRegGE->[3];";
		
		foreach ( <$archivoMotivos> ){
			/$camposRegGE->[4];(.+)/ && ($motivoPrincipal = $1);
			/$camposRegGE->[5];(.+)/ && ($motivoSecundario = $1); 
			last if $motivoPrincipal && $motivoSecundario;
		}
		
		$motivoPrincipal = "Motivo desconocido" if !$motivoPrincipal;
		$motivoSecundario = "Motivo desconocido" if !$motivoSecundario;
		
		print $archivoGE "$motivoPrincipal;$motivoSecundario\n";		
	}
	
	close $archivoGE or die "$!";
	close $archivoMotivos or die "$!";
		
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
	
	open (my $informe, ">> $nombreInforme") or die "$!";
		
	print $informe "\nInforme de control del área $area para el período $periodo\n";
	print $informe "Presupuesto Mensual del área: $presupuestoMensual\n";
	print $informe "Acumulado Inicial: $totalxAreaInicial\n";
	print $informe "Acumulado Final: ",  $totalxAreaInicial + $montoNormal + $montoExtraordinario,"\n";
	print $informe "Cantidad de Registros y Total de Gastos normales procesados: $cantNormales $montoNormal\n";
	print $informe "Cantidad de Registros y Total de Gastos extraordinarios: $cantExtraordinarios $montoExtraordinario\n";
	
	close $informe or die "$!";
}


1;
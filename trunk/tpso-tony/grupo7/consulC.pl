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

$tipoConsulta;


#Se obtiene el tipo de consulta, los parametros segun el tipo y se establece la salida estandard
&validarParametros;


if($tipoConsulta==1 || $tipoConsulta==2)
{
	#Si la consulta es valida se la resuelve
	&resolverConsulta($tipoConsulta,$paramValidados[0],$paramValidados[1]);
	&mostrarConsulta($tipoConsulta);
}
elsif($tipoConsulta==0)
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
# $tipoConsulta:
				#2 Consulta por período
				#1 Consulta por contribuyentes
				#0 Ayúda de uso del comando
				#-1 Error en el uso del comando

# @paramValidados:
				#vector con los parametros validos, segun el tipo de consulta
				
sub validarParametros()
{
	
  $argc=@ARGV;
	$tipoConsulta=-1;

	if($argc==1)
	{
		if(@ARGV[0] eq "-h")
		{
			$tipoConsulta=0;
		
		}
	}

  elsif($argc==2)
	{
    if(@ARGV[0] eq "-1" && length(@ARGV[1])==6 )
		{
			$tipoConsulta=1;
			
			$paramValidados[0]=@ARGV[1];
		}
	}

	elsif($argc==3)
	{
  	if(@ARGV[0] eq '-2' && length(@ARGV[1])==6 && length(@ARGV[2])==6)
		{
			$tipoConsulta=2;
			$paramValidados[0]=@ARGV[1];
			$paramValidados[1]=@ARGV[2];
		}
	
		elsif(@ARGV[0] eq '-w' && @ARGV[1] eq '-1' && length(@ARGV[2])==6)  
		{
			$tipoConsulta=1;
			$paramValidados[0]=@ARGV[2];
			open STDOUT, "> $GRUPO/consultas/$paramValidados[0]";
		}
	}
	
	elsif($argc == 4)
	{
		if(@ARGV[0] eq '-w' && @ARGV[1] eq '-2' && length(@ARGV[2])==6 && length(@ARGV[3])==6) 
		{
			$tipoConsulta=2;
			$paramValidados[0]=@ARGV[2];
			$paramValidados[1]=@ARGV[3];
			open STDOUT, "> $GRUPO/consultas/$paramValidados[0]To$paramValidados[1]";
			
		}
	}

}

# Función que resuelve la consulta
# Establece los valores de las variables:			
# %resultConsulta:
			#Segun el tipo de consulta las claves seran el contriibuyente o el período. 
			#Los valores seran otra hash con lo acumulado de gravado e impuestoLiquidado
# Parametros:
			#$_[0] : tipo de consulta
			#$_[1-2]: Período/s
    
sub resolverConsulta
{
	opendir(DIR, "$GRUPO/ivaC");

	# Se establece la expresion para leer tomar los archivos segun el tipo de consulta 
	if($_[0]==1)
	{
		$pattern="$_[1]\$";
	}
	else
	{
		$pattern="\([0-9]\{4\}\)\([01][0-9]\)\$";
	}

	@lista_archivos = sort(grep(/$pattern/,readdir(DIR)));
	closedir(DIR);
	
	foreach $arch(@lista_archivos)
	{
		open(ARCH,"$GRUPO/ivaC/$arch");
		@registros=<ARCH>;
		
		if($_[0]==2)
		{
			#si es del tipo de consulta 2, se compara el rango de períodos			
			if( ($arch < $_[1]) || ($arch > $_[2])  )
			{
				close(ARCH);
				next;
			}
			# La clave de la consulta es el período, que es el nombre del archivo
			$claveConsulta=$arch;
		}
		
		foreach $linea(@registros)
		{
			@data=split(/,/,$linea);
			if($_[0]==1)
			{
				# Si es un tipo de consulta 1 la clave de la misma es el contribuyente
				$claveConsulta=$data[0];
			}
			
			#Preparo los campos que se procesan en la resolucion de la consulta
			%campos= 	(
								'tipoComp'=>$data[2],
								'importeNetoGravado'=>$data[6],
								'impuestoLiquidado'=>$data[7]
								);

			# Se agregan los campos segun la clave de la consulta
			&agregarRegistro($claveConsulta, \%campos);
		}
		close(ARCH);	
	}
}

#Función auxiliar de resolverConsulta
#Parametros:
			#$_[0] : clave de la consulta (puede ser un período o un contribuyente)
			#$_[1] : referencia a hash que posee los campos tipo de comprobante, importe neto gravado e impuesto liquidado

sub agregarRegistro
{
	my($claveConsulta, %campos);
	$claveConsulta=$_[0]; $campos=$_[1];
	
	# Valores que se procesan segun la clave

	if($$campos{'tipoComp'} eq 'C')
	{
		%{$resultadoConsulta{$claveConsulta}}->{'totalOperacionesGravadas'}+=$$campos{'importeNetoGravado'};					
		%{$resultadoConsulta{$claveConsulta}}->{'totalImpuestoLiquidado'}+=$$campos{'impuestoLiquidado'};
	}
	else
	{
		%{$resultadoConsulta{$claveConsulta}}->{'totalOperacionesGravadas'}-=$$campos{'importeNetoGravado'};					
		%{$resultadoConsulta{$claveConsulta}}->{'totalImpuestoLiquidado'}-=$$campos{'impuestoLiquidado'};
	}
	

	#Valores de utilizados para calcular el pie del listado. 
	$resultadoConsulta{'totalGravado'}+=$$campos{'importeNetoGravado'};					
	$resultadoConsulta{'totalLiquidado'}+=$$campos{'impuestoLiquidado'};

}

#Función que muestra el listado, en el archivo de salida especificado, el resultado de la consulta 
#Parametros:
			#$_[0] : Tipo de consulta

sub mostrarConsulta
{

	@fechaActual= localtime;
	$indiceLeyenda;
	@periodo1=(substr($paramValidados[0],4), substr($paramValidados[0],0,4));
	@periodo2;

	if($_[0]==1)
	{
		$indiceLeyenda=0;
	}
	else
	{
		@periodo2=(substr($paramValidados[1],4), substr($paramValidados[1],0,4));
		$indiceLeyenda=1;
	}

	@tituloListado=("Listado de contribuyentes declarantes en el período $periodo1[0]-$periodo1[1] " , "Listado de Compras Declaradas desde $periodo1[0]-$periodo1[1] hasta $periodo2[0]-$periodo2[1]");
	@cabeceraListado=("Contribuyente:" , "Período:");
	@tituloPiePag=("Cantidad de Contribuyentes: " , "Cantidad de Períodos: ");

	print("$fechaActual[3]-$fechaActual[4] \n");
	print("$tituloListado[$indiceLeyenda] \n");
	foreach(keys %resultadoConsulta)
	{
		if( !($_ eq 'totalGravado') && !($_ eq 'totalLiquidado'))
		{
			$rclave=$resultadoConsulta{$_};
			print("$cabeceraListado[$indiceLeyenda] $_ \n");
			print("Suma total de Operaciones Gravadas \t");print( %{$rclave}->{totalOperacionesGravadas} . "\n");
			print("Suma total de Impuesto Liquidado \t");print( %{$rclave}->{totalImpuestoLiquidado} . "\n\n\n");
		}
	}

	$totalConsulta=keys %resultadoConsulta;
	$totalConsulta-=2;
	if($totalConsulta>0)
	{
		$promedioGravado=  $resultadoConsulta{'totalGravado'}/$totalConsulta;
		$promedioLiquidado=  $resultadoConsulta{'totalLiquidado'}/$totalConsulta;
	}
	else
	{
		$totalConsulta=0;
		$promedioGravado=  0;
		$promedioLiquidado=  0;
	}
	
	print("\n\n\n\n");
	print("$tituloPiePag[$indiceLeyenda] $totalConsulta \n");
	print("Promedio de Gravadas: $promedioGravado \n");
	print("Promedio de Impuesto: $promedioLiquidado \n");

	close STDOUT;
}

#!/bin/bash
# recompilar si hace falta
make

# inicializar variables
P=9
Ninicio=$((10000 + 1024 * P))
Nfinal=$((10000 + 1024 * (P+1)))
Npaso=64
N2=200
Nrepeticiones=10
dirDatos=datos_ej1
fDAT=$dirDatos/slow_fast_time.dat
fPNG=$dirDatos/slow_fast_time.png
runslowfast=False

mkdir -p $dirDatos



if [ ! -f "$fDAT" ]; then
	runslowfast=True
	echo "Fichero $fDAT no existe"
fi

if [ $runslowfast == False ]; then
	echo "Ya existe un fichero con datos"
	while true; do
		read -p "Ejecutar de nuevo?[S/N]:" yn
		case $yn in
			[YySs]* ) runslowfast=True; rm $fDAT; break;;
			[Nn]* ) break;;
			* ) echo "Responde con S o N";;
		esac
	done
fi

#solo ejecutamos si no existe el fichero o sí el usuario lo quiere
if [ $runslowfast == True ]; then

	#inicializamos el array donde guardamos la suma de tiempos
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		slow[N]=0
		fast[N]=0
	done

	echo "Running slow and fast..."
	for ((I = 1 ; I <= Nrepeticiones ; I += 1)); do
		for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
			echo -e "Rep $I: $N / $Nfinal"
			slowTime=$(./slow $N | grep 'time' | awk '{print $3}')
			slow[N]=$(echo "${slow[N]}+$slowTime"|bc -l)
			./slow $N2 > /dev/null
			
			fastTime=$(./fast $N | grep 'time' | awk '{print $3}')
			fast[N]=$(echo "${fast[N]}+$fastTime"|bc -l)
			./fast $N2 > /dev/null
		done

		# hacemos la media y guardamos los datos
		# lo hacemos en bucle por si queremos parar antes de que acabe y guardar
		# los datos obtenidos hasta ese momento
		echo -e "N\tslow\tfast" > $fDAT
		for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
			media_s[N]=$(echo "${slow[N]}/$I"|bc -l)
			media_n[N]=$(echo "${fast[N]}/$I"|bc -l)
			echo -e "$N\t${media_s[N]}\t${media_n[N]}" >> $fDAT
		done
	done
fi

echo "Generating plot..."
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Slow-Fast Execution Time";
set ylabel "Execution time (s)";
set xlabel "Matrix Size";
set grid;
set term png;
set key autotitle columnhead
set key outside;
set key right top;
set output "$fPNG";

plot "$fDAT" using 1:2 with lines lw 2 title "slow", \
     "$fDAT" using 1:3 with lines lw 2 title "fast";
replot;
quit;
END_GNUPLOT





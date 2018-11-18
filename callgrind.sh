#!/bin/bash
# recompilar si hace falta
make

# inicializar variables
P=9
Ninicio=$((500 + 256 * P))
Nfinal=$((500 + 256*(P+1)))
Npaso=16
Nrepeticiones=2
fDAT=slow_fast_time.dat
fPNG=slow_fast_time.png


# borrar el fichero DAT y el fichero PNG
rm -f $fDAT fPNG

# generar el fichero DAT vacío
touch $fDAT

echo "Running slow and fast..."
# bucle para N desde P hasta Q 
#for N in $(seq $Ninicio $Npaso $Nfinal);
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	slow[N]=0
	fast[N]=0
done

mkdir -p datos_ej2

runcachegring=False

tam_caches=(1024 2048 4096 8192)

# comprobamos si existen ya los datos para no ejecutar de nuevo
for tam in "${tam_caches[@]}"; do
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		if [ ! -f "datos_ej2/cache_slow_${tam}_${N}.dat" ]; then
			runcachegring=True
			echo "fichero cache_slow_$tam\_$N.dat no existe"
		fi
		if [ ! -f "datos_ej2/cache_fast_${tam}_${N}.dat" ]; then
			runcachegring=True
			echo "fichero cache_fast_$tam_$N.dat no existe"
		fi
	done
done


if [ $runcachegring == False ]; then
	echo "Ya existen ficheros de datos para el ejercicio 2"
	while true; do
		read -p "Ejecutar de nuevo?[S/N]:" yn
		case $yn in
			[YySs]* ) runcachegring=True; rm cache_*.dat; break;;
			[Nn]* ) break;;
			* ) echo "Responde con S o N";;
		esac
	done
fi


if [ $runcachegring == True ]; then
	echo "Ejecutando pruebas ejercicio 2"
	for tam in "${tam_caches[@]}"; do
		echo "tamanio = $tam "
		for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
			echo "Iteration : $N / $Nfinal..."
			echo "    Slow $tam - $N"
			valgrind --tool=cachegrind --I1=$tam,1,64 --D1=$tam,1,64 --LL=8388608,1,64 --cachegrind-out-file=datos_ej2/cache_slow_$tam\_$N.dat ./slow $N > /dev/null 2>&1
			echo "    Fast $tam - $N"
			valgrind --tool=cachegrind --I1=$tam,1,64 --D1=$tam,1,64 --LL=8388608,1,64 --cachegrind-out-file=datos_ej2/cache_fast_$tam\_$N.dat ./fast $N > /dev/null 2>&1
		done
	done
fi


echo "Generando archivos gráficas ejercicio 2"


for tam in "${tam_caches[@]}"; do
	filename="cache_${tam}.dat"
	echo "Generando fichero $filename"
	echo -e "N\tD1mr_slow\tD1mw_slow\tD1mr_fast\tD1mw_fast" > $filename
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		slow=$(cg_annotate --show=D1mr,D1mw datos_ej2/cache_slow_${tam}_${N}.dat | grep TOTAL | awk '{$1=$1};1' | awk '{print $1"\t"$2}' | sed 's/,//g')
		fast=$(cg_annotate --show=D1mr,D1mw datos_ej2/cache_fast_${tam}_${N}.dat | grep TOTAL | awk '{$1=$1};1' | awk '{print $1"\t"$2}' | sed 's/,//g') 
		
		echo -e "$N\t${slow}\t${fast}" >> $filename
	done
done



echo "Generating plot..."
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Slow-Fast Execution Time"
set ylabel "Cache miss rate"
set xlabel "Matrix Size"
set key right bottom
set grid
set term png size 1000,500
set output "lectura.png"
set key outside;
set key right top;
plot "cache_1024.dat" using 1:2 with lines lw 2 title "slow_{1024}", \
     "cache_2048.dat" using 1:2 with lines lw 2 title "slow_{2048}", \
     "cache_4096.dat" using 1:2 with lines lw 2 title "slow_{4096}", \
	 "cache_8192.dat" using 1:2 with lines lw 2 title "slow_{8192}", \
	 "cache_1024.dat" using 1:4 with lines lw 2 title "fast_{1024}", \
	 "cache_2048.dat" using 1:4 with lines lw 2 title "fast_{2048}", \
	 "cache_4096.dat" using 1:4 with lines lw 2 title "fast_{4096}", \
	 "cache_8192.dat" using 1:4 with lines lw 2 title "fast_{8192}",


replot
quit
END_GNUPLOT

gnuplot << END_GNUPLOT
set title "Slow-Fast Execution Time"
set ylabel "Cache miss rate"
set xlabel "Matrix Size"
set key right bottom
set grid
set term png size 1000,500
set output "escritura.png"
set key outside;
set key right top;
plot "cache_1024.dat" using 1:3 with lines lw 2 title "slow_{1024}", \
     "cache_2048.dat" using 1:3 with lines lw 2 title "slow_{2048}", \
     "cache_4096.dat" using 1:3 with lines lw 2 title "slow_{4096}", \
	 "cache_8192.dat" using 1:3 with lines lw 2 title "slow_{8192}", \
	 "cache_1024.dat" using 1:5 with lines lw 2 title "fast_{1024}", \
	 "cache_2048.dat" using 1:5 with lines lw 2 title "fast_{2048}", \
	 "cache_4096.dat" using 1:5 with lines lw 2 title "fast_{4096}", \
	 "cache_8192.dat" using 1:5 with lines lw 2 title "fast_{8192}",


replot
quit
END_GNUPLOT

#!/bin/bash
# recompilar si hace falta
make


# inicializar variables
P=9
#Ninicio=$((0+(64*P)))
#Nfinal=$((0+64*(P+1)))
#Npaso=4

#Ninicio=$((64+64* P))
#Nfinal=$((64+64*(P+1)))
#Npaso=4

Ninicio=$((256+256* P))
Nfinal=$((256+256*(P+1)))
Npaso=16

Nrepeticiones=2
dirDatos=datos_ej3

fDAT=$dirDatos/mult.dat
fPNG_cache=$dirDatos/mult_cache.png
fPNG_time=$dirDatos/mult_time.png

dirTiempos=$dirDatos/tiempos
fTiempos=$dirTiempos/tiempos_${Ninicio}_${Nfinal}_${Npaso}.dat

dirCache=$dirDatos/cache
mkdir -p $dirDatos

medirtiempos=False

if [ ! -f "$fTiempos" ]; then
	medirtiempos=True
	echo "Fichero con tiempos $fTiempos no existe"
fi

if [ $medirtiempos == False ]; then
	echo "Ya existe un fichero con tiempos"
	while true; do
		read -p "Ejecutar de nuevo?[S/N]:" yn
		case $yn in
			[YySs]* ) medirtiempos=True; break;;
			[Nn]* ) break;;
			* ) echo "Responde con S o N";;
		esac
	done
fi

if [ $medirtiempos == True ]; then
	echo "Midiendo tiempos"

	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		matriz[N]=0
		matriz_t[N]=0
	done

	for ((I = 1 ; I <= Nrepeticiones ; I += 1)); do
		for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
			echo "matriz   $I : $N / $Nfinal..."

			matrizTime=$(./matmul $N | grep 'time' | awk '{print $3}')
			matriz[N]=$(echo "${matriz[N]}+$matrizTime"|bc -l)

			echo "matriz_t $I : $N / $Nfinal..."
			matriz_tTime=$(./matmultrans $N | grep 'time' | awk '{print $3}')
			matriz_t[N]=$(echo "${matriz_t[N]}+$matriz_tTime"|bc -l)
		done
		
		# hacemos la media y guardamos los datos
		# lo hacemos en bucle por si queremos parar antes de que acabe y guardar
		# los datos obtenidos hasta ese momento
		echo -e "N\tmatmul\tmatmulfast" > $fTiempos
		for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
			media_matmul[N]=$(echo "${matriz[N]}/$I"|bc -l)
			media_matmultrans[N]=$(echo "${matriz_t[N]}/$I"|bc -l)
			echo -e "tamano-$N\t${media_matmul[N]}\t${media_matmultrans[N]}" >> $fTiempos
		done
	done
fi


runcachegring=False

for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		if [ ! -f "$dirCache/cache_matmul_$N.dat" ]; then
			runcachegring=True
		fi
		if [ ! -f "$dirCache/cache_matmultrans_$N.dat" ]; then
			runcachegring=True
		fi
done


if [ $runcachegring == False ]; then
	echo "Ya existen ficheros de datos para fallos de cache"
	while true; do
		read -p "Ejecutar de nuevo?[S/N]:" yn
		case $yn in
			[YySs]* ) runcachegring=True; break;;
			[Nn]* ) break;;
			* ) echo "Responde con S o N";;
		esac
	done
fi


if [ $runcachegring == True ]; then
	echo "Midiendo fallos caches"
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		Nsiguiente=$((N + Npaso))
		echo "Iteration : $N / $Nfinal..."
		valgrind --tool=cachegrind --cachegrind-out-file=$dirCache/cache_matmul_$N.dat ./matmul $N > /dev/null 2>&1 &
		valgrind --tool=cachegrind --cachegrind-out-file=$dirCache/cache_matmultrans_$N.dat ./matmultrans $N > /dev/null 2>&1 &
		
		if ((Nsiguiente <= Nfinal )); then
			echo "Iteration : $Nsiguiente / $Nfinal..."
			valgrind --tool=cachegrind --cachegrind-out-file=$dirCache/cache_matmul_$Nsiguiente.dat ./matmul $Nsiguiente > /dev/null 2>&1 &
			valgrind --tool=cachegrind --cachegrind-out-file=$dirCache/cache_matmultrans_$Nsiguiente.dat ./matmultrans $Nsiguiente > /dev/null 2>&1 &
			N=Nsiguiente
		fi
		wait
	done
fi

echo "Generando $fDAT"
echo -e "N\ttiempo_mat\tD1mr_mat\tD1mw_mat\ttiempo_mat\tD1mr_mat_t\tD1mw_mat_t" > $fDAT
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	tiempo_mulmat=$(grep tamano-$N $fTiempos| awk '{$1=$1};1' | awk '{print $2}')
	tiempo_mulmattrans=$(grep tamano-$N $fTiempos| awk '{$1=$1};1' | awk '{print $3}')
	datos_cache_mat=$(cg_annotate --show=D1mr,D1mw $dirCache/cache_matmul_${N}.dat | grep TOTAL | awk '{$1=$1};1' | awk '{print $1"\t"$2}' | sed 's/,//g')
	datos_cache_mat_t=$(cg_annotate --show=D1mr,D1mw $dirCache/cache_matmultrans_${N}.dat | grep TOTAL | awk '{$1=$1};1' | awk '{print $1"\t"$2}' | sed 's/,//g')
	echo "$N	$tiempo_mulmat $datos_cache_mat	$tiempo_mulmattrans $datos_cache_mat_t" >> $fDAT
done



echo "Generating plot $fPNG_time ..."
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Execution Time"
set ylabel "Execution time (s)"
set xlabel "Matrix Size"
set key autotitle columnhead
set grid
set term png
set key outside;
set key right top;
set output "$fPNG_time"
plot "$fDAT" using 1:2 with lines lw 2 title "mat", \
     "$fDAT" using 1:5 with lines lw 2 title "mat^T"
replot
quit
END_GNUPLOT

echo "Generating plot2 $fPNG_cache ..."
gnuplot << END_GNUPLOT
set title "Cache failures"
set ylabel "Number of cache misses"
set xlabel "Matrix Size"
set key right bottom
set grid
set term png
set key outside;
set key right top;
set key autotitle columnhead
set output "$fPNG_cache"
plot "$fDAT" using 1:3 with lines lw 2 title "D1mr_{mat}",\
     "$fDAT" using 1:4 with lines lw 2 title "D1mw_{mat}",\
     "$fDAT" using 1:6 with lines lw 2 title "D1mr_{mat^T}",\
     "$fDAT" using 1:7 with lines lw 2 title "D1mw_{mat^T}"

quit
END_GNUPLOT
exit
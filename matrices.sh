#!/bin/bash
# recompilar si hace falta
make


# inicializar variables
P=0
Ninicio=$((0+0))
Nfinal=$((0+80*(P+1)))
Npaso=10

#Ninicio=$((256+256* P))
#Nfinal=$((256+256*(P+1)))
#Npaso=16

Nrepeticiones=2
fDAT=mult.dat
fPNG1=mult_cache.png
fPNG2=mult_time.png
mkdir -p datos_ej3


# borrar el fichero DAT y el fichero PNG
rm -f $fDAT fPNG

# generar el fichero DAT vacío
touch $fDAT

echo "Running slow and fast..."

for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	matriz[N]=0
	matriz_t[N]=0
done


for ((I = 1 ; I <= Nrepeticiones ; I += 1)); do
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		echo "matriz $I : $N / $Nfinal..."

		# ejecutar los programas slow y fast consecutivamente con tamaño de matriz N
		# para cada uno, filtrar la línea que contiene el tiempo y seleccionar la
		# tercera columna (el valor del tiempo). Dejar los valores en variables
		# para poder imprimirlos en la misma línea del fichero de datos

		matrizTime=$(./matmul $N | grep 'time' | awk '{print $3}')
		echo "${matriz[N]}+$matrizTime"
		matriz[N]=$(echo "${matriz[N]}+$matrizTime"|bc -l)
	done

	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		echo "matriz traspuesta $I : $N / $Nfinal..."

		# ejecutar los programas slow y fast consecutivamente con tamaño de matriz N
		# para cada uno, filtrar la línea que contiene el tiempo y seleccionar la
		# tercera columna (el valor del tiempo). Dejar los valores en variables
		# para poder imprimirlos en la misma línea del fichero de datos
		matriz_tTime=$(./matmultrans $N | grep 'time' | awk '{print $3}')
		matriz_t[N]=$(echo "${matriz_t[N]}+$matriz_tTime"|bc -l)
	done
done

for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
  echo "Iteration : $N / $Nfinal..."
  valgrind --tool=cachegrind --cachegrind-out-file=datos_ej3/cache_matmul_$N.dat ./matmul $N > /dev/null 2>&1
  valgrind --tool=cachegrind --cachegrind-out-file=datos_ej3/cache_matmultrans_$N.dat ./matmultrans $N > /dev/null 2>&1
done

echo -e "N\ttiempo_mat\tD1mr_mat\tD1mw_mat\ttiempo_mat\tD1mr_mat_t\tD1mw_mat_t" > $fDAT
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	matriz[N]=$(echo "${matriz[N]}/$Nrepeticiones"|bc -l)
	matriz_t[N]=$(echo "${matriz_t[N]}/$Nrepeticiones"|bc -l)
  datos_cache_mat=$(cg_annotate --show=D1mr,D1mw datos_ej3/cache_matmul_${N}.dat | grep TOTAL | awk '{$1=$1};1' | awk '{print $1"\t"$2}' | sed 's/,//g')
  datos_cache_mat_t=$(cg_annotate --show=D1mr,D1mw datos_ej3/cache_matmultrans_${N}.dat | grep TOTAL | awk '{$1=$1};1' | awk '{print $1"\t"$2}' | sed 's/,//g')

	echo "$N	${matriz[N]} $datos_cache_mat	${matriz_t[N]} $datos_cache_mat_t" >> $fDAT
done






echo "Generating plot..."
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Slow-Fast Execution Time"
set ylabel "Execution time (s)"
set xlabel "Matrix Size"
set key right bottom
set grid
set term png
set key outside;
set key right top;
set output "$fPNG2"
plot "$fDAT" using 1:2 with lines lw 2 title "mat", \
     "$fDAT" using 1:5 with lines lw 2 title "mat_t"
replot
quit
END_GNUPLOT

echo "Generating plot2..."
gnuplot << END_GNUPLOT
set title "Cache failures"
set ylabel "Execution time (s)"
set xlabel "Matrix Size"
set key right bottom
set grid
set term png
set key outside;
set key right top;
set key autotitle columnhead
set output "$fPNG1"
plot "$fDAT" using 1:3 with lines lw 2 title "D1mr_mat",\
     "$fDAT" using 1:4 with lines lw 2 title "D1mw_mat",\
     "$fDAT" using 1:6 with lines lw 2 title "D1mr_mat_t",\
     "$fDAT" using 1:7 with lines lw 2 title "D1mw_mat_t"


quit
END_GNUPLOT

#!/bin/bash
# recompilar si hace falta
make

# inicializar variables
P=9
Ninicio=$((2000 + 1024 * P))
Nfinal=$((2000+1024*(P+1)))
Npaso=64
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

tam_caches=(1024 2048 4096 8192)


for tam in "${tam_caches[@]}"; do
	echo "tamanio = $tam "
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		echo "Iteration $I : $N / $Nfinal..."

		valgrind --tool=callgrind --I1=$tam,1,64 --D1=$tam,1,64 --LL=8388608,1,64 --callgrind-out-file=cache_slow_$tam.dat ./slow N 
		valgrind --tool=callgrind --I1=$tam,1,64 --D1=$tam,1,64 --LL=8388608,1,64 --callgrind-out-file=cache_fast_$tam.dat ./fast N 
	done
done


for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	slow[N]=$(echo "${slow[N]}/$Nrepeticiones"|bc -l)
	fast[N]=$(echo "${fast[N]}/$Nrepeticiones"|bc -l)
	echo "$N	${slow[N]}	${fast[N]}" >> $fDAT

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
set output "$fPNG"
plot "$fDAT" using 1:2 with lines lw 2 title "slow", \
     "$fDAT" using 1:3 with lines lw 2 title "fast"
replot
quit
END_GNUPLOT

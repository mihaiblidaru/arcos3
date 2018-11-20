#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "arqo3.h"

void compute(tipo **a, tipo **b, tipo **c, int n);
void transponer_matriz(tipo **b, tipo **bt, int n);
int main( int argc, char *argv[])
{
  int n;
  tipo **a=NULL, **b=NULL, **bt=NULL, **c=NULL;
  struct timeval fin,ini;

#ifdef PRINT_MAT
	int i, j;
#endif
  printf("Word size: %ld bits\n",8*sizeof(tipo));

  if( argc!=2 )
  {
  printf("Error: ./%s <matrix size>\n", argv[0]);
  return -1;
  }
  n=atoi(argv[1]);

  if(!(a = generateMatrix(n))){
    return -1;
  }

  if(!(b = generateMatrix(n))){
    freeMatrix(a);
    return -1;
  }

	if(!(bt=generateEmptyMatrix(n))){
    freeMatrix(a);
    freeMatrix(b);
    return -1;
  }

  if(!(c=generateEmptyMatrix(n))){
    freeMatrix(a);
    freeMatrix(b);
		freeMatrix(bt);
    return -1;
  }

  gettimeofday(&ini,NULL);
	transponer_matriz(b, bt, n);
  /* Main computation */
  compute(a, bt, c, n);
  /* End of computation */
  gettimeofday(&fin,NULL);
  printf("Execution time: %f\n", ((fin.tv_sec*1000000+fin.tv_usec)-(ini.tv_sec*1000000+ini.tv_usec))*1.0/1000000.0);

#ifdef PRINT_MAT
	for (i = 0; i < n; i++) {
		for (j = 0; j < n; j++) {
			printf("%2lf ", c[i][j]);
		}
		printf("\n");
	}
#endif
  freeMatrix(a);
	freeMatrix(b);
	freeMatrix(bt);
  freeMatrix(c);
  return 0;
}

void transponer_matriz(tipo **b, tipo **bt, int n){
	int i,j;
	for (i = 0; i < n; i++) {
		for (j = 0; j < n; j++) {
			bt[i][j] = b[j][i];
		}
	}
}

void compute(tipo **a, tipo **b, tipo **c, int n){
  int i,j,k, sum;

	for(i = 0; i<n; i++){
    for(j=0; j<n; j++){
      sum = 0;
      for (k = 0; k < n; k++) {
        sum += a[i][k] * b[j][k];
      }
      c[i][j] = sum;
    }
  }
}

LIBS =
LIB_DIR =
FLAGS = -g -Wall -Wextra -Werror -D_GNU_SOURCE #-DPRINT_MAT

.PHONY: clean all

all: fast slow matmul matmultrans

fast: fast.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

slow: slow.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

matmul: matmul.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

matmultrans: matmultrans.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

clean:
	rm -f *.o *~ fast slow matmul matmultrans

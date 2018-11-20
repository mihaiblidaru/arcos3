LIBS =
LIB_DIR =
FLAGS = -g -Wall -Wextra -Werror -D_GNU_SOURCE #-DPRINT_MAT

.PHONY: clean all

all: matmul matmultrans

matmul: matmul.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

matmultrans: matmultrans.c arqo3.c
	gcc $(FLAGS) $(LIB_DIR) -o $@ $^ $(LIBS)

clean:
	rm -f *.o *~ matmul matmultrans

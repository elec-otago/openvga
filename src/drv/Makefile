obj-m = freega.o
KVERSION = $(shell uname -r)
all:
	make -C /lib/modules/$(KVERSION)/build M=$(PWD) modules
clean:
	rm -rf Module.markers modules.order
	make -C /lib/modules/$(KVERSION)/build M=$(PWD) clean

test: testfreega.c dump.c set.c peek.c poke.c newtest.c
	gcc -o test testfreega.c
	gcc -o new newtest.c
	gcc -o dump dump.c
	gcc -o set set.c
	gcc -o peek peek.c
	gcc -o poke poke.c

testclean:
	rm -f test dump set peek poke new

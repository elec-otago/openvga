#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <err.h>

// Currently only 4kB of memory is mapped
// #define	MEM_SIZE	8192
#define	MEM_SIZE	1048576
// #define	MEM_SIZE	8388608
#define	TEST_NUM	10

int freega_open (int* fp)
{
	// Open FreeGA for read/write
	*fp	= open ("/dev/freega", O_RDWR);
	if (*fp == -1) {
		printf ("Didn't work!\n");	//ERROR: (%D)\n", errno);
		return 1;
	}
	
	return	0;
}

void freega_close (int fp)
{
	close (fp);
}


int freega_write_blk (const int* b, const int s, int fd, const unsigned int ad)
{
	lseek (fd, ad, SEEK_SET);
	write (fd, (void*) b, s*4);
	return	0;
}


int freega_read_blk (int* b, const int s, int fd, const unsigned int ad)
{
	lseek (fd, ad, SEEK_SET);
	read (fd, (void*) b, s*4);	// FIXME: Do some checking!
	return	0;
}


unsigned int* rnd_blk (int* b, const int s)
{
	int	i;
	unsigned int*	buf	= (unsigned int*) b;	// TODO: 64-bit safe?
	
	for (i=0; i<s; i++)
		buf [i]	= rand ();
	
	return	buf;
}


int chk_blks (const void* b0, const void* b1, const int s)
{
	int	i;
	int*	buf0	= (int*) b0;
	int*	buf1	= (int*) b1;
	
	for (i=0; i<s; i++) {
		if (buf0 [i] != buf1 [i]) {
			printf ("ERROR @%x: %x %x\n", i, buf0 [i], buf1 [i]);
			return	-1;
		}
	}
	return	0;
}


int main (void)
{
	int	fd, i;
	int*	wb	= (int*) malloc ((size_t) MEM_SIZE);
	int*	rb	= (int*) malloc ((size_t) MEM_SIZE);
	
	freega_open (&fd);
	for (i=0; i<TEST_NUM; i++) {
		rnd_blk (wb, MEM_SIZE/4);
		freega_write_blk (wb, MEM_SIZE/4, fd, 0);
		freega_read_blk (rb, MEM_SIZE/4, fd, 0);
		if (!chk_blks (wb, rb, MEM_SIZE/4))
			printf ("Test Passed OK\n");
	}
	freega_close (fd);
	return 0;
}

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <err.h>

// Currently only 4kB of memory is mapped
#define	MEM_SIZE	4096

static int	fd;

int freega_open ()
{
	// Open FreeGA for read/write
	fd	= open ("/dev/freega", O_RDWR);
	if (fd == -1) {
		printf ("Didn't work!\n");	//ERROR: (%D)\n", errno);
		return 1;
	}
	
	return	0;
}

void freega_close ()
{
	close (fd);	// TODO: Will never get here!
}


unsigned long freega_read_word (int addr)
{
	unsigned long buf;
	
	freega_open ();
	lseek (fd, addr*4, SEEK_SET);
	read (fd, (void*) &buf, 4);
	freega_close ();
	
	return	buf;
}


freega_write_word (int addr, unsigned long word)
{
	freega_open ();
	lseek (fd, addr*4, SEEK_SET);
	write (fd, (void*) &word, 4);
	freega_close ();
}


unsigned long* freega_get (unsigned long* ar, int n)
{
	int	i;
	for (i=0; i<n; i++)
		ar [i]	= freega_read_word (i);
	return	ar;
}


char	hex_lut [16]	= {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
void hex_dump (unsigned long* ar, int n)
{
	int	i, j;
	unsigned long	v;
	for (i=0; i<n; i++) {
		v	= ar [i];
		printf ("%3d:", i);
		for (j=28; j>=0; j-=4)
			printf ("%c", (hex_lut [(v >> j) & 0x0F]));
		printf ("\n");
	}
}


int main (void)
{
	int	fd, i;
	static unsigned long	ar [256];
	
	hex_dump (freega_get (ar, 256), 256);
	
	return 0;
}

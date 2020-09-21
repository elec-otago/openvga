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


char	hex_lut [16]	= {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

unsigned int hexchr2uint (char c)
{
	unsigned int	i;
	i	= ((unsigned int) toupper (c)) - 48;
	if (i > 9)	i -= 7;
	if (i > 15) {
		printf ("ERROR: Invalid hexchar to int conversion.\n");
		exit (1);
	}
	return	i;
}


unsigned int hex2uint (char* str)
{
	int		i	= 0;
	unsigned int	d	= 0;
	
	while (str [i] != '\0')
		d	= (d << 4) | hexchr2uint (str [i++]);
	
	return	d;
}

int main (int argc, char* argv[])
{
	unsigned int	addr, data;
	if (argc != 3) {
		printf ("USAGE: poke <ADDR> <DATA>\n\n");
		exit (1);
	}
	
	addr	= hex2uint (argv [1]);
	data	= hex2uint (argv [2]);
	printf ("Poking address: 0x%x with: %x\n", addr, data);
	freega_write_word (addr, data);
	
	return 0;
}

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <err.h>

// Currently only 4kB of memory is mapped
#define	MEM_SIZE	4096
// #define	MEM_SIZE	8192
// #define	MEM_SIZE	262144
#define	TEST_NUM	100


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


int test_opening ()
{
	int	i;
	
	// First test open and close a few times
	for (i=TEST_NUM; i--; ) {
		if (freega_open ()) {
			printf ("ERROR: Cannot open FreeGA (%d)\n", i);
			return	1;
		}
		freega_close ();
	}
	return	0;
}


int write_rand_block (int words, unsigned long* buf)
{
	int	i;
	
	if (freega_open ()) return 1;

	// Fill the first buffer with random stuff
	for (i=0; i<words; i++)
		buf [i]	= rand ();
	
	write (fd, (void*) buf, words*4);
	
	freega_close ();
	return	0;
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


int test_single_read_write (int num_words)
{
	int	i, j;
	unsigned long	word1, word2;
	
	printf ("test_single_read_write (block_size=%d): ",num_words);
	// Test FreeGA continuously until interrupted by the user
	for (j=TEST_NUM; j--; ) {
		for (i=0; i<num_words; i++) {	// Compare the data
			freega_write_word (i, word1 = rand ());
			word2	= freega_read_word (i);
			
			if (word1 != word2) {
				printf ("ERROR: test_single_read_write @%4d: %lx %lx\n", i, word1, word2);
				return	1;
			}
		}
	}
	
	printf ("OK\n");
	return	0;
}


int test_single_read_write_no_open (int num_words)
{
	int	i, j, ret;
	unsigned long	word1, word2;
	
	ret = 0;
	printf ("test_single_read_write_no_open (block_size=%d): ",num_words);
	// Test FreeGA continuously until interrupted by the user
	freega_open ();
	for (j=TEST_NUM; j--; ) {
		for (i=0; i<num_words; i++) {	// Compare the data
			// freega_write_word (i, word1 = rand ());
			// word2	= freega_read_word (i);
			
			lseek (fd, i*4, SEEK_SET);
			write (fd, (void*) &i, 4);
			
			lseek (fd, i*4, SEEK_SET);
			read (fd, (void*) &word2, 4);
			
			if (i != word2) {
				printf ("ERROR: test_single_read_write_no_open @%4d: %lx %lx\n", i, i, word2);
				ret =	1;
				goto err;
			}
		}
	}
	printf ("OK\n");

err:
	freega_close ();
	return	ret;
}


int test_single_read_write_random_order (int num_words)
{
	int	i, j;
	unsigned long	word1, word2;
	unsigned long*	buf;
	buf	= malloc (MEM_SIZE);
	int	ret	= 0;
	
	printf ("test_single_read_write_random_order (block_size=%d): ",num_words);
	// Test FreeGA continuously until interrupted by the user
	freega_open ();
	for (j=TEST_NUM; j--; ) {
		for (i=0; i<num_words; i++) {
			buf [i]	= rand ();
			lseek (fd, i*4, SEEK_SET);
			write (fd, (void*) &buf [i], 4);
		}
		
		for (i=0; i<num_words*2; i++) {
			int addr = rand () % num_words;
			lseek (fd, addr*4, SEEK_SET);
			read (fd, (void*) &word2, 4);
			
			if (buf [addr] != word2) {
				printf ("ERROR (attempt %d) @%4d: %lx %lx\n", i, addr, buf [addr], word2);
				ret	= 1;
				goto	err;
			}
		}
	}
	printf ("OK\n");
err:
	freega_close ();
	free (buf);
	return	ret;
}


int test_burst_write_single_reads (int num_words)
{
	int	i, j, err;
	unsigned long*	buf1 = NULL;
	unsigned long	buf2;
	
	printf ("test_burst_write_single_reads (block_size=%d): ",num_words);
	err = 0;
	// Initialise the memory buffers
	buf1	= (unsigned long*) malloc ((size_t) MEM_SIZE);
	
	for (j=0; j<TEST_NUM; j++) {
		write_rand_block (num_words, buf1);
		
		for (i=0; i<num_words; i++) {	// Compare the data
			buf2	= freega_read_word (i);
			
			if (buf1[i] != buf2) {
				printf ("ERROR: test_burst_write_single_reads (pass %d) @%4d: %lx %lx\n", j, i, buf1 [i], buf2);
				err =	1;
			}
		}
	}
	
	free (buf1);
	printf ("OK\n");
	
	return	err;
}


int test_burst_read_single_writes (int num_words)
{
	int	i, j, err;
	unsigned long*	buf1 = NULL;
	unsigned long*	buf2 = NULL;
	
	printf ("test_burst_read_single_writes (block_size=%d): ",num_words);
	err = 0;
	// Initialise the memory buffers
	buf1	= (unsigned long*) malloc ((size_t) MEM_SIZE);
	buf2	= (unsigned long*) malloc ((size_t) MEM_SIZE);
	
	for (j=0; j<TEST_NUM; j++ ) {
		for (i=0; i<num_words; i++) {	// Compare the data
			freega_write_word (i, buf1[i] = rand ());
		}
		
		freega_open ();
		// Now read back the data and compare values
		read (fd, (void*) buf2, num_words*4);
		freega_close ();
		
		for (i=0; i<num_words; i++) {	// Compare the data
			if (buf1[i] != buf2[i]) {
				printf ("ERROR: test_burst_read_single_writes (pass %d) at@%4d: %lx %lx\n", j, i, buf1 [i], buf2[i]);
				err =	1;
			}
		}
	}
	
	free (buf1);
	free (buf2);
	printf ("OK\n");

	return	err;
}


int test_bursts (int num_words)
{
	int	i, j;
	unsigned long*	buf1 = NULL;
	unsigned long*	buf2 = NULL;
	
	printf ("test_bursts (block_size=%d): ",num_words);
	
	// Initialise the memory buffers
	buf1	= (unsigned long*) malloc ((size_t) MEM_SIZE);
	buf2	= (unsigned long*) malloc ((size_t) MEM_SIZE);
	
	for (j=0; j<TEST_NUM; j++ ) {
		write_rand_block (num_words, buf1);
	
		if (freega_open ()) return 1;
		lseek(fd,0, SEEK_SET);
		read (fd, (void*) buf2, num_words*4);
		freega_close ();
		
		for (i=0; i<num_words; i++) {	// Compare the data
			if (buf1[i] != buf2[i]) {
				printf ("ERROR: test_burst (pass %d) @%4d: %lx %lx\n", j, i, buf1 [i], buf2 [i]);
				return	1;
			}
		}
	}
	printf ("OK\n");
	
	free (buf1);
	free (buf2);
	
	return	0;
}


int main (void)
{
	int	fd, i;
	// First test open and close a few times
//	if (test_opening ()) return 1;
	
	int	err	= 0;
/*	while (!err) {
		if (err = test_bursts (MEM_SIZE/4))
			printf ("ERROR: test_bursts failed!\n");
	}*/
	
/*	while (!err) {
		if (test_burst_read_single_writes (MEM_SIZE/4))
			printf ("ERROR: test_burst_read_single_writes failed!\n");
	}*/
	
//	while (1) {
	int max_block = MEM_SIZE/4;
	for (i=16; i<=max_block; i*=2) {
		if (test_single_read_write (i)) printf ("ERROR: test_single_read_write failed!\n");
		if (test_single_read_write_no_open (i)) printf ("ERROR: test_single_read_write_no_open failed!\n");
		if (test_single_read_write_random_order (i)) printf ("ERROR: test_single_read_write_random_order failed!\n");
		
		if (test_burst_read_single_writes (i)) printf ("ERROR: test_burst_read_single_writes failed!\n");
		if (test_burst_write_single_reads (i)) printf ("ERROR: test_burst_write_single_reads failed\n");
		if (test_bursts (i)) printf ("ERROR: test_bursts failed\n");
		
		printf ("\n\n\n");
	}
	
	close (fd);	// TODO: Will never get here!
	return 0;
}

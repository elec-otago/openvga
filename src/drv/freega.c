/***************************************************************************
 *                                                                         *
 *   freega.c - The kernel device driver module for FreeGA.                *
 *                                                                         *
 *   Copyright (C) 2006 by Patrick Suggate                                 *
 *   patrick@physics.otago.ac.nz                                           *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/init.h>

#include <linux/pci.h>
#include <linux/tty.h>

#include <asm/uaccess.h>


#define	FREEGA_VENDOR_ID	0x106d
#define	FREEGA_DEVICE_ID	0x9500
#define	FREEGA_NAME		"freega"

#include "freega.h"


MODULE_AUTHOR		("Patrick Suggate <patrick@physics.otago.ac.nz>");
MODULE_DESCRIPTION	("FreeGA device driver.");
MODULE_LICENSE		("GPL");
MODULE_SUPPORTED_DEVICE	("freega");


// Globals to do with FreeGA
static int		freega_major	= 0;
static int		freega_busy	= 0;
static struct pci_dev*	freega_pdev	= NULL;
static void*		freega_mm_addr	= NULL;	// First memory mapped region
static unsigned long	freega_mm_len	= 0;
//	static

// Prototypes for file operations
static int	freega_open	(struct inode*, struct file*);
static int	freega_release	(struct inode*, struct file*);
static ssize_t	freega_read	(struct file*, char*, size_t, loff_t*);
static ssize_t	freega_write	(struct file*, const char*, size_t, loff_t*);


static struct file_operations freega_fops = {
	.read	= freega_read,
	.write	= freega_write,
	.open	= freega_open,
	.release= freega_release
};


static int freega_open (struct inode* inodp, struct file* filp)
{
	if (freega_busy)
		return -EBUSY;
	
	freega_busy++;
	try_module_get (THIS_MODULE);	// Increment usage count
//	printk (KERN_INFO "FreeGA opened.\n");
	filp->f_pos = 0;
	return 0;
}


static int freega_release (struct inode* inodp, struct file* filp)
{
	freega_busy--;
	module_put (THIS_MODULE);	// Decrement usage count
//	printk (KERN_INFO "FreeGA closed.\n");
	
	return 0;
}

/*! This implements the lseek system call. If it is left undefined, then default_llseek from fs/read_write.c is used instead. This updates the f_pos field as expected, and also may change the f_reada field and f_version field.
*/
// static loff_t (*llseek) (struct file *, loff_t, int);

/*! This is used to implement the read system call and to support other occasions for reading files such a loading executables and reading the quotas file. It is expected to update the offset value (last argument) which is usually a pointer to the f_pos field in the file structure, except for the pread and pwrite system calls.
\param off The offset for the read from the start of file
\return The number of bytes read?
*/
static ssize_t freega_read (struct file* filp, char* buf, size_t len, loff_t* off)
{
	int	notsent;
	
//	printk (KERN_ALERT "Offset = %d\n", *off);
	
/*	if (len & 0x03) {
		printk (KERN_ALERT "Reads have to be multiples of four bytes!\n");
		return -EINVAL;
	}
	
	if (*off & 0x03) {
		printk (KERN_ALERT "FreeGA read offset (%d) must be a multiple of four bytes!\n", (int)*off);
		return -EINVAL;
	}
	*/
	if ((*off + len) > freega_mm_len) {
		printk (KERN_ALERT "Cannot read past 4096 bytes!\n");
		return -EINVAL;
	}
	
	// printk (KERN_INFO "FreeGA reading.\n");
	notsent	= copy_to_user (buf, freega_mm_addr + *off, len);
	*off	+= len - notsent;
	
	return len - notsent;
}


static ssize_t freega_write (struct file* filp, const char* buf, size_t len, loff_t* off)
{
	int	notreceived;
	
/*	if (len & 0x03) {
		printk (KERN_ALERT "FreeGA writes have to be multiples of four bytes!\n");
		return -EINVAL;
	}
	
	if (*off & 0x03) {
		printk (KERN_ALERT "FreeGA write offset (%d) must be a multiple of four bytes!\n", (int)*off);
		return -EINVAL;
	}
	*/
	if ((len + *off) > freega_mm_len) {
		printk (KERN_ALERT "FreeGA cannot write past 4096 bytes!\n");
		return -EINVAL;
	}
	
	// printk (KERN_INFO "FreeGA writing.\n");
	notreceived = copy_from_user (freega_mm_addr + *off, buf, len);
	*off	+= len - notreceived;
	return len - notreceived;
}


//#ifdef __use_probe_for_freega
// Look for a FreeGA on the PCI bus, and if found, enable it.
static struct pci_dev* __init probe_for_freega (void)
{
	struct pci_dev *pdev = NULL;
	
	// Look for the FreeGA
	pdev = pci_find_device (FREEGA_VENDOR_ID, FREEGA_DEVICE_ID, NULL);
	
	if(pdev) {
		// Device found, enable it
		if(pci_enable_device (pdev)) {
			printk (KERN_ALERT "Could not enable FreeGA\n");
			return NULL;
		} else
			printk (KERN_INFO "FreeGA enabled\n");
	} else {
		printk (KERN_ALERT "FreeGA not found\n");
		return pdev;	// TODO: Is this OK?
	}
	
	return pdev;
}
//#endif


// Module initialisaton and cleanup routines.
static int __init freega_init (void)
{
	unsigned long	mm_start, mm_end, mm_flags;
	
	// More normal is printk(), but there's less that can go wrong with 
	// console_print(), so let's start simple.
	console_print("Hello, world - this is the kernel speaking\n");
	
	if ( (freega_pdev = probe_for_freega ()) )
	{
		freega_major	= register_chrdev (0, FREEGA_NAME, &freega_fops);
		
		if (freega_major < 0)
		{
			printk (KERN_ALERT "Unable to register FreeGA!\n");
			pci_disable_device (freega_pdev);
			return freega_major;
		}
		
		// TODO: Apparently UDEV can do this
		// mknod ("/dev/freega", S_IFCHR, freega_major);
		
		printk (KERN_INFO "FreeGA major number is: %d\n", freega_major);
		printk (KERN_INFO "Use: `mknod /dev/%s c %d 0'.\n", FREEGA_NAME, freega_major);
		printk (KERN_INFO "Remove /dev/%s when finished.\n\n", FREEGA_NAME);
		
		mm_start	= pci_resource_start	(freega_pdev, 0);
		mm_end		= pci_resource_end	(freega_pdev, 0);
		freega_mm_len	= pci_resource_len	(freega_pdev, 0);
		mm_flags	= pci_resource_flags	(freega_pdev, 0);
		
		if (mm_flags & IORESOURCE_MEM)
			printk (KERN_INFO "FreeGA is memory-mapped.\n");
		else {
			printk (KERN_ALERT "FreeGA memory-mapping failed!\n");
			goto cleanup0;
		}
		
		if (pci_request_regions (freega_pdev, FREEGA_NAME)) {
			printk (KERN_ALERT "FreeGA could not get requested memory mapped region!\n");
			goto cleanup0;
		}
		
		freega_mm_addr	= ioremap (mm_start, freega_mm_len);
		if (!freega_mm_addr) {
			printk (KERN_ALERT "FreeGA could not get re-map memory mapped region!\n");
			goto cleanup1;
		}
		
		printk (KERN_INFO "FreeGA mm_start = %lx\n", mm_start);
		printk (KERN_INFO "FreeGA mm_len   = %lu\n", freega_mm_len);
		printk (KERN_INFO "FreeGA mm_addr  = %lx\n", (unsigned long) freega_mm_addr);
	}
	
	// Non-zero value means failure
	return 0;
	
cleanup1:
	pci_release_regions (freega_pdev);
cleanup0:
	pci_disable_device (freega_pdev);
	unregister_chrdev (freega_major, FREEGA_NAME);
	return -1;
}


static void __exit freega_exit (void)
{
	// Un-map the allocated memory and release FreeGA
	iounmap (freega_mm_addr);
	pci_release_regions (freega_pdev);
	
	// Disable the PCI device
	unregister_chrdev (freega_major, FREEGA_NAME);
	pci_disable_device (freega_pdev);
	
	printk (KERN_INFO "FreeGA Unregistering\n");
}


module_init (freega_init);
module_exit (freega_exit);

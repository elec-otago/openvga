SUBDIRS =  fw_tta16 fw_risc16 drv

all:
	for dir in $(SUBDIRS); do (cd $$dir ; $(MAKE) all); done

clean:
	for dir in $(SUBDIRS); do (cd $$dir ; $(MAKE) clean); done

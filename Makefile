SUBDIRS =  src rtl sim

all:
	for dir in $(SUBDIRS); do (cd $$dir ; $(MAKE) all); done

icarus:
	cd sim && make icarus

clean:
	for dir in $(SUBDIRS); do (cd $$dir ; $(MAKE) clean); done

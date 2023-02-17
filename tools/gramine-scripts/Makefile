# crash Makefile

ifeq ($(DEBUG), 1)
    GRAMINE_LOG_LEVEL = trace
else
    GRAMINE_LOG_LEVEL = error
endif

crash.manifest: crash.manifest.template
	gramine-manifest \
	    -Dlog_level=$(GRAMINE_LOG_LEVEL) \
	    -Dpwd=$(shell pwd) \
	    -Dcrash=$(CRASH) \
	    $< $@

clean:
	rm -rf crash.manifest

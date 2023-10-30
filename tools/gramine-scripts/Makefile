# crash Makefile

ifeq ($(DEBUG), 1)
    GRAMINE_LOG_LEVEL = trace
else
    GRAMINE_LOG_LEVEL = error
endif

crash.manifest.sgx: crash.manifest
	gramine-sgx-sign \
		--manifest $< \
		--output $<.sgx

crash.manifest: crash.manifest.template
	gramine-manifest \
	    -Dlog_level=$(GRAMINE_LOG_LEVEL) \
	    -Dpwd=$(shell pwd) \
	    -Dcrash=$(CRASH) \
	    $< $@

clean:
	rm -rf *.token *.sig *.manifest.sgx *.manifest

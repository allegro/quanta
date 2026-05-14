UNAME := $(shell uname)

# FIXME: pkg-config requires separating CMOzjpeg into distinct repository

ifeq ($(UNAME), Linux)
	MOZJPEG_PREFIX = /opt/mozjpeg
	MOZJPEG_LIB = $(MOZJPEG_PREFIX)/lib64
	export LD_LIBRARY_PATH=$(MOZJPEG_LIB)
else
	BREW_PREFIX := $(shell brew --prefix 2>/dev/null || echo /usr/local)
	MOZJPEG_PREFIX = $(BREW_PREFIX)/opt/mozjpeg
	MOZJPEG_LIB = $(MOZJPEG_PREFIX)/lib
endif

LDFLAGS = -Xlinker -lz -Xlinker -ljpeg -Xlinker -lturbojpeg -Xlinker -L$(MOZJPEG_LIB)
CFLAGS = -Xcc -DNDEBUG -Xcc -I$(MOZJPEG_PREFIX)/include

update:
	swift package update

debug:
	swift build -v -c debug $(LDFLAGS) $(CFLAGS)

release:
	swift build -v -c release $(LDFLAGS) $(CFLAGS)

test:
	TEST_FIXTURES_DIR=`pwd`/Resources/Samples/ swift test $(LDFLAGS) $(CFLAGS)

format:
	swiftformat --disable redundantSelf ./Sources

lint:
	swiftformat --lint --verbose --disable redundantSelf ./Sources

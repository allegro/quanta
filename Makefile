UNAME := $(shell uname)

# FIXME: pkg-config requires separating CMOzjpeg into distinct repository

export LD_LIBRARY_PATH=/opt/mozjpeg/lib64/

ifeq ($(UNAME), Linux)
	PREFIX=/
	LDFLAGS = -Xlinker -lz -Xlinker -ljpeg -Xlinker -lturbojpeg -Xlinker -L${PREFIX}opt/mozjpeg/lib64
	CFLAGS = -Xcc -DNDEBUG -Xcc -I${PREFIX}opt/mozjpeg/include
else
	PREFIX=/usr/local/
	LDFLAGS = -Xlinker -lz -Xlinker -ljpeg -Xlinker -lturbojpeg -Xlinker -L${PREFIX}opt/mozjpeg/lib
	CFLAGS = -Xcc -DNDEBUG -Xcc -I${PREFIX}opt/mozjpeg/include
endif

update:
	swift package update

xcode:
	swift package generate-xcodeproj --xcconfig-overrides custom-settings.xcconfig
	@echo "Add manually TEST_FIXTURES_DIR env to the project in XCode"
	@echo "TEST_FIXTURES_DIR=`pwd`/Resources/Samples"

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

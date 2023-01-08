.PHONY: build

BUILD_DIR=./build

all: make_build_dir
make_build_dir:
	-mkdir -p $(BUILD_DIR)

all: 3rd/imgexporter
	cd 3rd/imgexporter && make
	cp 3rd/imgexporter/3rd/bson/bson.so $(BUILD_DIR)

3rd/imgexporter: 3rd/imgexporter/Makefile
	cd 3rd/imgexporter && make

3rd/imgexporter/Makefile:
	git submodule update --init 3rd/imgexporter
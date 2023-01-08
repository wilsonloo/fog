.PHONY: build

BUILD_DIR=./build
OUTPUT_DIR=./output

all: make_dirs
make_dirs:
	-mkdir -p $(BUILD_DIR)
	-mkdir -p $(OUTPUT_DIR)

all: 3rd/imgexporter
	cd 3rd/imgexporter && make

all: cp_so
cp_so:
	cp 3rd/imgexporter/3rd/bson/bson.so $(BUILD_DIR)
	cp 3rd/imgexporter/3rd/cjson/cjson.so $(BUILD_DIR)

3rd/imgexporter: 3rd/imgexporter/Makefile
	cd 3rd/imgexporter && make

3rd/imgexporter/Makefile:
	git submodule update --init 3rd/imgexporter

clean:
	rm -rf $(BUILD_DIR)
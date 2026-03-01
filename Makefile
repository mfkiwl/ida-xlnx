.PHONY: all release debug loader loader-debug install-loader test test-debug clean purge

LOADER_NAME := zynqmp_boot_image_loader
RELEASE_BUILD_DIR := build-release-optimized
IDA_LOADERS_DIR ?= $(HOME)/.idapro/loaders

all: release

.configure-release:
	cmake --preset release-optimized
	@touch .configure-release

.configure-debug:
	cmake --preset debug
	@touch .configure-debug

release: .configure-release
	cmake --build --preset release-optimized

debug: .configure-debug
	cmake --build --preset debug

loader: .configure-release
	cmake --build --preset release-optimized --target $(LOADER_NAME)

loader-debug: .configure-debug
	cmake --build --preset debug --target $(LOADER_NAME)

install-loader: loader
	@mkdir -p "$(IDA_LOADERS_DIR)"
	@set -e; \
	src="$(RELEASE_BUILD_DIR)/$(LOADER_NAME).dylib"; \
	ext="dylib"; \
	if [ ! -f "$$src" ]; then \
		src="$(RELEASE_BUILD_DIR)/$(LOADER_NAME).so"; \
		ext="so"; \
	fi; \
	if [ ! -f "$$src" ]; then \
		echo "Loader binary not found. Expected $(RELEASE_BUILD_DIR)/$(LOADER_NAME).dylib or $(RELEASE_BUILD_DIR)/$(LOADER_NAME).so" >&2; \
		exit 1; \
	fi; \
	dst="$(IDA_LOADERS_DIR)/$(LOADER_NAME).$$ext"; \
	cp "$$src" "$$dst"; \
	if [ "$$ext" = "dylib" ] && [ "$$(uname -s)" = "Darwin" ]; then \
		codesign -s - "$$dst"; \
	fi; \
	echo "Installed $$dst"

test: .configure-release
	cmake --build --preset release-optimized --target xilinx_loader_tests
	ctest --preset release-optimized

test-debug: .configure-debug
	cmake --build --preset debug --target xilinx_loader_tests
	ctest --preset debug

clean:
	@echo "Cleaning release artifacts..."
	@if [ -d build-release-optimized ]; then cmake --build --preset release-optimized --target clean 2>/dev/null || true; fi
	@echo "Cleaning debug artifacts..."
	@if [ -d build-debug ]; then cmake --build --preset debug --target clean 2>/dev/null || true; fi

purge:
	@echo "Purging all build directories and CMake configurations..."
	rm -rf build-release-optimized build-debug .configure-release .configure-debug

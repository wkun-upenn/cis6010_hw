.PHONY: all clean profile

# Auto-detect CUDA home from nvcc on PATH
CUDA_HOME ?= $(shell dirname $(shell dirname $(shell readlink -f $(shell which nvcc))))
NVCC      := $(CUDA_HOME)/bin/nvcc
NCU       := $(shell which ncu)

# Architecture (override with: make SM=86)
SM ?= 75
GENCODE := -gencode arch=compute_$(SM),code=[compute_$(SM),sm_$(SM)]

CXXSTD   := -std=c++17
LDFLAGS  := -L$(CUDA_HOME)/lib64 -lcublas

SOURCE_FILE := cugemm.cu

all: cugemm.bin cugemm-debug.bin cugemm-profile.bin

# optimized binary
cugemm.bin: $(SOURCE_FILE)
	$(NVCC) $(CXXSTD) $(GENCODE) $^ $(LDFLAGS) -o $@

# debug binary without optimizations, with PTX
cugemm-debug.bin: $(SOURCE_FILE)
	$(NVCC) -g -G -src-in-ptx $(CXXSTD) $(GENCODE) $^ $(LDFLAGS) -o $@

# profiled build with line info
cugemm-profile.bin: $(SOURCE_FILE)
	$(NVCC) -g --generate-line-info -src-in-ptx $(CXXSTD) $(GENCODE) $^ $(LDFLAGS) -o $@

# Run Nsight Compute (no sudo). Override SIZE/REPS/ALGO/REPORT as needed.
SIZE ?= 1024
REPS ?= 1
ALGO ?= 1
REPORT ?= my-profile
profile: cugemm-profile.bin
	$(NCU) --export $(REPORT) --set full ./cugemm-profile.bin --size=$(SIZE) --reps=$(REPS) --algo=$(ALGO) --validate=false

clean:
	rm -f cugemm*.bin *.ncu-rep *.csv


# ----------------------------------------------------------
# Transpose test binary (standalone)
# ----------------------------------------------------------

# ----------------------------------------------------------
# Device info utility
# ----------------------------------------------------------

DEVICE_INFO_SRC := device_info.cu
DEVICE_INFO_BIN := device_info.bin

device_info.bin: $(DEVICE_INFO_SRC)
	$(NVCC) $(CXXSTD) $(GENCODE) $^ -o $@

run-info: device_info.bin
	./$(DEVICE_INFO_BIN)




MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_DIR := .

GPP:= g++
CL:= cl
#GPP:= /sw/gcc/11.2.0/bin/g++

###### CUDA DIRECTORY #########
ifeq ($(CUDA_HOME),)
	CUDA_HOME:="C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.1"
endif
###############################

ifndef CUDA_VERSION
$(warning WARNING: CUDA_VERSION not set. Call make with CUDA string, for example: make cuda11x CUDA_VERSION=115 or make cpuonly CUDA_VERSION=CPU)
####### CUDA VERSION ###########
CUDA_VERSION:=121
################################

endif

ifndef VisualStudioVersion
$(warning WARNING: Visual Studio not found, initializing x64)
#"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
endif

NVCC := $(CUDA_HOME)/bin/nvcc

###########################################

CSRC := csrc
BUILD_DIR:= $(ROOT_DIR)/build

WINLIBS_DIR := c:/app/winlibs

FILES_CUDA := $(CSRC)/ops.cu $(CSRC)/kernels.cu
FILES_CPP := $(CSRC)/pythonInterface.c

# with rtools40
#INCLUDE_NVCC := -I $(CUDA_HOME)/include -I $(ROOT_DIR)/csrc -I $(CONDA_PREFIX)/include -I $(ROOT_DIR)/include -I c:/app/rtools40/mingw64/x86_64-w64-mingw32/include
INCLUDE_NVCC := -I $(CUDA_HOME)/include -I $(ROOT_DIR)/csrc -I $(ROOT_DIR)/include -I $(WINLIBS_DIR)/include
# -I $(WINLIBS_DIR)/x86_64-w64-mingw32/include

#for zig
#INCLUDE_CC := -I $(CUDA_HOME)/include -I $(CUDA_HOME)/include/cuda/std/detail/libcxx/include -I $(ROOT_DIR)/csrc -I $(CONDA_PREFIX)/include -I $(ROOT_DIR)/include -I c:/app/rtools40/mingw64/x86_64-w64-mingw32/include 
# for rtools40/mingw64
#INCLUDE_CC := -I $(ROOT_DIR)/csrc -I $(ROOT_DIR)/include -I $(CUDA_HOME)/include -I $(ROOT_DIR)/include -I c:/app/rtools40/mingw64/x86_64-w64-mingw32/include  -I c:/projects/libunistd/unistd
# for winlibs/mingw64
#INCLUDE_CC := -I $(ROOT_DIR)/csrc -I $(ROOT_DIR)/include -I $(WINLIBS_DIR)/include -I $(CUDA_HOME)/include
# for cl
INCLUDE_CC := /I$(ROOT_DIR)/csrc /I$(ROOT_DIR)/include /I$(WINLIBS_DIR)/include /I$(CUDA_HOME)/include

LIB := -L$(CUDA_HOME)/lib/x64 -lcudart -lcublas -lcublasLt -lcusparse

###### CAREFUL WITH CUDA VERSION HERE ######
LIB_CL := /LIBPATH:"c:/app/cu121/lib/x64" /LIBPATH:"$(VCToolsInstallDir)/lib/x64" cudart.lib cublas.lib cublasLt.lib cusparse.lib
############################################

# NVIDIA NVCC compilation flags
COMPUTE_CAPABILITY += -gencode arch=compute_50,code=sm_50 # Maxwell
COMPUTE_CAPABILITY += -gencode arch=compute_52,code=sm_52 # Maxwell
COMPUTE_CAPABILITY += -gencode arch=compute_60,code=sm_60 # Pascal
COMPUTE_CAPABILITY += -gencode arch=compute_61,code=sm_61 # Pascal
COMPUTE_CAPABILITY += -gencode arch=compute_70,code=sm_70 # Volta

CC_KEPLER := -gencode arch=compute_35,code=sm_35 # Kepler
CC_KEPLER += -gencode arch=compute_37,code=sm_37 # Kepler

# Later versions of CUDA support the new architectures
CC_CUDA11x := -gencode arch=compute_75,code=sm_75
CC_CUDA11x += -gencode arch=compute_80,code=sm_80
CC_CUDA11x += -gencode arch=compute_86,code=sm_86


CC_cublasLt110 := -gencode arch=compute_75,code=sm_75
CC_cublasLt110 += -gencode arch=compute_80,code=sm_80

CC_cublasLt111 := -gencode arch=compute_75,code=sm_75
CC_cublasLt111 += -gencode arch=compute_80,code=sm_80
CC_cublasLt111 += -gencode arch=compute_86,code=sm_86

CC_ADA_HOPPER := -gencode arch=compute_89,code=sm_89
CC_ADA_HOPPER += -gencode arch=compute_90,code=sm_90

CC_RTX := -gencode arch=compute_89,code=sm_89
#CC_RTX += -gencode arch=compute_86,code=sm_86


all: $(BUILD_DIR) env
#	$(NVCC) $(CC_RTX) --use_fast_math -dc $(FILES_CUDA) $(INCLUDE_NVCC) $(LIB) --output-directory $(BUILD_DIR)
#	$(NVCC) $(CC_RTX) -dlink $(BUILD_DIR)/ops.obj $(BUILD_DIR)/kernels.obj -o $(BUILD_DIR)/link.obj
#	$(GPP) -std=c++14 -DBUILD_CUDA -shared $(INCLUDE_CC) $(BUILD_DIR)/ops.obj $(BUILD_DIR)/kernels.obj $(BUILD_DIR)/link.obj $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION).so $(LIB)
	$(CL) /EHsc /TP /std:c++14 /DBUILD_CUDA $(INCLUDE_CC) $(FILES_CPP) /link /dll /out:./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION).dll $(LIB_CL) $(BUILD_DIR)/ops.obj $(BUILD_DIR)/kernels.obj $(BUILD_DIR)/link.obj


cuda110_nomatmul_kepler: $(BUILD_DIR) env
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA110) $(CC_KEPLER) -Xcompiler '-fPIC' --use_fast_math -Xptxas=-v -dc $(FILES_CUDA) $(INCLUDE) $(LIB) --output-directory $(BUILD_DIR) -D NO_CUBLASLT
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA110) $(CC_KEPLER) -Xcompiler '-fPIC' -dlink $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o -o $(BUILD_DIR)/link.o
	$(GPP) -std=c++14 -DBUILD_CUDA -shared -fPIC $(INCLUDE) $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o $(BUILD_DIR)/link.o $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION)_nocublaslt.so $(LIB)

cuda11x_nomatmul_kepler: $(BUILD_DIR) env
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA11x) $(CC_KEPLER) -Xcompiler '-fPIC' --use_fast_math -Xptxas=-v -dc $(FILES_CUDA) $(INCLUDE) $(LIB) --output-directory $(BUILD_DIR) -D NO_CUBLASLT
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA11x) $(CC_KEPLER) -Xcompiler '-fPIC' -dlink $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o -o $(BUILD_DIR)/link.o
	$(GPP) -std=c++14 -DBUILD_CUDA -shared -fPIC $(INCLUDE) $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o $(BUILD_DIR)/link.o $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION)_nocublaslt.so $(LIB)


cuda110_nomatmul: $(BUILD_DIR) env
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA110) -Xcompiler '-fPIC' --use_fast_math -Xptxas=-v -dc $(FILES_CUDA) $(INCLUDE) $(LIB) --output-directory $(BUILD_DIR) -D NO_CUBLASLT
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA110) -Xcompiler '-fPIC' -dlink $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o -o $(BUILD_DIR)/link.o
	$(GPP) -std=c++14 -DBUILD_CUDA -shared -fPIC $(INCLUDE) $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o $(BUILD_DIR)/link.o $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION)_nocublaslt.so $(LIB)

cuda11x_nomatmul: $(BUILD_DIR) env
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA11x) -Xcompiler '-fPIC' --use_fast_math -Xptxas=-v -dc $(FILES_CUDA) $(INCLUDE) $(LIB) --output-directory $(BUILD_DIR) -D NO_CUBLASLT
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA11x) -Xcompiler '-fPIC' -dlink $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o -o $(BUILD_DIR)/link.o
	$(GPP) -std=c++14 -DBUILD_CUDA -shared -fPIC $(INCLUDE) $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o $(BUILD_DIR)/link.o $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION)_nocublaslt.so $(LIB)

cuda118_nomatmul: $(BUILD_DIR) env
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA11x) $(CC_ADA_HOPPER)  -Xcompiler '-fPIC' --use_fast_math -Xptxas=-v -dc $(FILES_CUDA) $(INCLUDE) $(LIB) --output-directory $(BUILD_DIR) -D NO_CUBLASLT
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA11x) $(CC_ADA_HOPPER) -Xcompiler '-fPIC' -dlink $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o -o $(BUILD_DIR)/link.o
	$(GPP) -std=c++14 -DBUILD_CUDA -shared -fPIC $(INCLUDE) $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o $(BUILD_DIR)/link.o $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION)_nocublaslt.so $(LIB)

cuda12x_nomatmul: $(BUILD_DIR) env
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA11x) $(CC_ADA_HOPPER) -Xcompiler '-fPIC' --use_fast_math -Xptxas=-v -dc $(FILES_CUDA) $(INCLUDE) $(LIB) --output-directory $(BUILD_DIR) -D NO_CUBLASLT
	$(NVCC) $(COMPUTE_CAPABILITY) $(CC_CUDA11x) $(CC_ADA_HOPPER) -Xcompiler '-fPIC' -dlink $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o -o $(BUILD_DIR)/link.o
	$(GPP) -std=c++14 -DBUILD_CUDA -shared -fPIC $(INCLUDE) $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o $(BUILD_DIR)/link.o $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION)_nocublaslt.so $(LIB)

cuda110: $(BUILD_DIR) env
	$(NVCC) $(CC_cublasLt110) -Xcompiler '-fPIC' --use_fast_math -Xptxas=-v -dc $(FILES_CUDA) $(INCLUDE) $(LIB) --output-directory $(BUILD_DIR)
	$(NVCC) $(CC_cublasLt110) -Xcompiler '-fPIC' -dlink $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o -o $(BUILD_DIR)/link.o
	$(GPP) -std=c++14 -DBUILD_CUDA -shared -fPIC $(INCLUDE) $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o $(BUILD_DIR)/link.o $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION).so $(LIB)

cuda11x: $(BUILD_DIR) env
	$(NVCC) $(CC_cublasLt111) -Xcompiler '-fPIC' --use_fast_math -Xptxas=-v -dc $(FILES_CUDA) $(INCLUDE) $(LIB) --output-directory $(BUILD_DIR)
	$(NVCC) $(CC_cublasLt111) -Xcompiler '-fPIC' -dlink $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o -o $(BUILD_DIR)/link.o
	$(GPP) -std=c++14 -DBUILD_CUDA -shared -fPIC $(INCLUDE) $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o $(BUILD_DIR)/link.o $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION).so $(LIB)

cuda118: $(BUILD_DIR) env
	$(NVCC) $(CC_cublasLt111) $(CC_ADA_HOPPER) -Xcompiler '-fPIC' --use_fast_math -Xptxas=-v -dc $(FILES_CUDA) $(INCLUDE) $(LIB) --output-directory $(BUILD_DIR)
	$(NVCC) $(CC_cublasLt111) $(CC_ADA_HOPPER) -Xcompiler '-fPIC' -dlink $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o -o $(BUILD_DIR)/link.o
	$(GPP) -std=c++14 -DBUILD_CUDA -shared -fPIC $(INCLUDE) $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o $(BUILD_DIR)/link.o $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION).so $(LIB)

cuda12x: $(BUILD_DIR) env
	$(NVCC) $(CC_cublasLt111) $(CC_ADA_HOPPER) -Xcompiler '-fPIC' --use_fast_math -Xptxas=-v -dc $(FILES_CUDA) $(INCLUDE) $(LIB) --output-directory $(BUILD_DIR)
	$(NVCC) $(CC_cublasLt111) $(CC_ADA_HOPPER) -Xcompiler '-fPIC' -dlink $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o -o $(BUILD_DIR)/link.o
	$(GPP) -std=c++14 -DBUILD_CUDA -shared -fPIC $(INCLUDE) $(BUILD_DIR)/ops.o $(BUILD_DIR)/kernels.o $(BUILD_DIR)/link.o $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cuda$(CUDA_VERSION).so $(LIB)

cpuonly: $(BUILD_DIR) env
	$(GPP) -std=c++14 -shared -fPIC -I $(ROOT_DIR)/csrc -I $(ROOT_DIR)/include $(FILES_CPP) -o ./bitsandbytes/libbitsandbytes_cpu.so

env:
	@echo "ENVIRONMENT"
	@echo "============================"
	@echo "CUDA_VERSION: $(CUDA_VERSION)"
	@echo "============================"
	@echo "NVCC path: $(NVCC)"
	@echo "GPP path: $(GPP) VERSION: `$(GPP) --version | head -n 1`"
	@echo "CUDA_HOME: $(CUDA_HOME)"
	@echo "CONDA_PREFIX: $(CONDA_PREFIX)"
	@echo "PATH: $(PATH)"
	@echo "LD_LIBRARY_PATH: $(LD_LIBRARY_PATH)"
	@echo "============================"

$(BUILD_DIR):
	mkdir -p build
	mkdir -p dependencies

$(ROOT_DIR)/dependencies/cub:
	git clone https://github.com/NVlabs/cub $(ROOT_DIR)/dependencies/cub
	cd dependencies/cub; git checkout 1.11.0

clean:
	rm build/*

cleaneggs:
	rm -rf *.egg*

cleanlibs:
	rm ./bitsandbytes/libbitsandbytes*.so

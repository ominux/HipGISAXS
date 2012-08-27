##
# $Id: Makefile 35 2012-08-09 18:29:50Z asarje $
#
# Project: HipGISAXS
#
# File: Makefile
# Created: June 5, 2012
# Modified: Jul 11, 2012
#
# Author: Abhinav Sarje <asarje@lbl.gov>
##

## base directories
BOOST_DIR = /usr/local/boost_1_49_0
MPI_DIR = /usr/local/openmpi-1.6
CUDA_DIR = /usr/local/cuda
HDF5_DIR = /usr/local/hdf5-1.8.9
Z_DIR = /usr/local/zlib-1.2.7
SZ_DIR = /usr/local/szip-2.1
TIFF_LIB_DIR = /usr/local/lib

## compilers
CXX = $(MPI_DIR)/bin/mpicxx	#g++
H5CC = $(HDF5_DIR)/bin/h5pcc
NVCC = $(CUDA_DIR)/bin/nvcc #-ccbin /usr/local/gcc-4.6.3/bin

## compiler flags
CXX_FLAGS = -std=c++0x -v -Wall -Wextra
## gnu c++ compilers >= 4.3 support -std=c++0x [requirement for hipgisaxs 4.3.x <= g++ <= 4.6.x]
## gnu c++ compilers >= 4.7 also support -std=c++11, but they are not supported by cuda

## boost
BOOST_INCL = -I $(BOOST_DIR)
BOOST_LIBS = -lboost_system -lboost_filesystem

## parallel hdf5
HDF5_INCL = -I$(HDF5_DIR)/include -I$(SZ_DIR)/include -I$(Z_DIR)/include
HDF5_LIBS = -L$(SZ_DIR)/lib -L$(Z_DIR)/lib -L$(HDF5_DIR)/lib -lhdf5 -lz -lsz -lm
HDF5_FLAGS = -Wl,-rpath -Wl,$(HDF5_DIR)/lib
HDF5_FLAGS += -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -D_POSIX_SOURCE -D_BSD_SOURCE

## mpi (openmpi)
MPI_INCL = -I $(MPI_DIR)/include
MPI_LIBS = -L $(MPI_DIR)/lib -lmpi_cxx -lmpi

## cuda
CUDA_INCL = -I$(CUDA_DIR)/include
CUDA_LIBS = -L$(CUDA_DIR)/lib -lcudart -lcufft
NVCC_FLAGS = -Xcompiler -fPIC -Xcompiler -fopenmp -m 64
NVCC_FLAGS += -gencode arch=compute_20,code=sm_20 -gencode arch=compute_30,code=sm_30
NVCC_FLAGS += -Xptxas -v -Xcompiler -v -Xlinker -v
NVCC_FLAGS += -DGPUR #-DKERNEL2 #-DFINDBLOCK
NVLIB_FLAGS = -Xlinker -lgomp
NVLIB_FLAGS += -Wl,-rpath -Wl,$(CUDA_DIR)/lib

## libtiff
TIFF_LIBS = -L $(TIFF_LIB_DIR) -ltiff

## miscellaneous
MISC_INCL =
MISC_FLAGS =

## choose optimization levels, debug flags, gprof flag, etc
#OPT_FLAGS = -g2 -DDEBUG #-v #-G #-pg
OPT_FLAGS = -O3 -DNDEBUG #-v

## choose single or double precision here
PREC_FLAG =			# leave empty for single precision
#PREC_FLAG = -DDOUBLEP	# define this for double precision


## all includes
ALL_INCL = $(MPI_INCL) $(CUDA_INCL) $(BOOST_INCL) $(HDF5_INCL) $(MISC_INCL)

## all libraries
ALL_LIBS = $(BOOST_LIBS) $(MPI_LIBS) $(NVLIB_FLAGS) $(CUDA_LIBS) $(HDF5_LIBS) $(TIFF_LIBS)


PREFIX = $(PWD)
BINARY = hipgisaxs
BIN_DIR = $(PREFIX)/bin
OBJ_DIR = $(PREFIX)/obj
SRC_DIR = $(PREFIX)/src

## all objects
OBJECTS = reduction.o ff_num_gpu.o utilities.o compute_params.o hig_input.o \
		  image.o inst_detector.o inst_scattering.o layer.o qgrid.o read_oo_input.o sf.o \
		  ff_ana.o ff_num.o ff.o shape.o structure.o object2hdf5.o hipgisaxs_main.o

## the main binary
OBJ_BIN = $(patsubst %,$(OBJ_DIR)/%,$(OBJECTS))

$(BIN_DIR)/$(BINARY): $(OBJ_BIN)
	$(CXX) -o $@ $^ $(OPT_FLAGS) $(CXX_FLAGS) $(PREC_FLAG) $(MISC_FLAGS) $(ALL_LIBS)

## cuda compilation
_DEPS_NV = %.cuh
DEPS_NV = $(patsubst %,$(SRC_DIR)/%,$(_DEPS_NV))

#### dont know why is this happenning ...
$(OBJ_DIR)/ff_num_gpu.o: $(SRC_DIR)/ff_num_gpu.cu
	$(NVCC) -c $< -o $@ $(OPT_FLAGS) $(PREC_FLAG) $(ALL_INCL) $(MISC_FLAGS) $(NVCC_FLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cu $(DEPS_NV)
	$(NVCC) -c $< -o $@ $(OPT_FLAGS) $(PREC_FLAG) $(ALL_INCL) $(MISC_FLAGS) $(NVCC_FLAGS)

## hdf5-parallel compilation
_DEPS_HDF = object2hdf5.h
DEPS_HDF = $(patsubst %,$(SRC_DIR)/%,$(_DEPS_HDF))

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c $(DEPS_HDF)
	$(H5CC) -c $< -o $@ $(OPT_FLAGS) $(PREC_FLAG) $(ALL_INCL) $(MISC_FLAGS)

## c++ compilation
_DEPS_CXX = %.hpp
DEPS_CXX = $(patsubst %,$(SRC_DIR)/%,$(_DEPS_CXX))

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp $(DEPS_CXX)
	$(CXX) -c $< -o $@ $(OPT_FLAGS) $(CXX_FLAGS) $(PREC_FLAG) $(ALL_INCL) $(MISC_FLAGS)

.PHONY: clean

clean:
	rm -f $(OBJ_BIN) $(BIN_DIR)/$(BINARY) $(BIN_DIR)/test_conv $(BIN_DIR)/test_read $(BIN_DIR)/test_ff $(BIN_DIR)/test_image

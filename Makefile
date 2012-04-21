ALL=Image.cpp MeshLoader.cpp main.cu
NVFLAGS=-arch=compute_20 -code=sm_20
FLAGS=-g -G #-pg
NVCC=nvcc
EXE=rasterizer_cuda

rasterizer_cuda: $(ALL)
	$(NVCC) $(FLAGS) $(NVFLAGS) -o $(EXE) $^

Image.o: Image.c
	$(NVCC) $(FLAGS) $(NVFLAGS) -o $@ -c $^

MeshLoader.o: MeshLoader.c
	$(NVCC) $(FLAGS) $(NVFLAGS) -o $@ -c $^

main.o: main.cu
	$(NVCC) $(FLAGS) $(NVFLAGS) -o $@ -c $^

clean:
	rm -rf *.o $(EXE)

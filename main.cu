/*
 * main.cpp
 *
 *  Created on: Apr 17, 2012
 *      Author: Wyatt
 */

#include "MeshLoader.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <iostream>
#include "Image.h"
#include <math.h>
#include <cuda.h>

#define MY_WINDOW_SIZE 2000
#define NUM_THREADS 512

#define round_up(x, y) (((x) % (y) == 0) ? ((x)/(y)) : (((x)/(y)) + 1))
#define max(x1, x2) ((x1) > (x2) ? (x1) : (x2))
#define min(x1, x2) ((x1) < (x2) ? (x1) : (x2))

float redColorBuffer[MY_WINDOW_SIZE * MY_WINDOW_SIZE];
float greenColorBuffer[MY_WINDOW_SIZE * MY_WINDOW_SIZE];
float blueColorBuffer[MY_WINDOW_SIZE * MY_WINDOW_SIZE];

int depthBuffer[MY_WINDOW_SIZE * MY_WINDOW_SIZE];
//
//__device__ glm::ivec2 worldToScreen(glm::vec2 point)
//{
//   glm::ivec2 newPoint(0);
//
//    point *= 4;
//
//   newPoint.x = ((point.x + 1) * (MY_WINDOW_SIZE - 1)) / 2;
//   newPoint.y = ((point.y + 1) * (MY_WINDOW_SIZE - 1)) / 2;
////    newPoint.y = (MY_WINDOW_SIZE - 1) - ((point.y + 1) * (MY_WINDOW_SIZE - 1)) / 2;
//
//   return newPoint;
//}
//
//__device__ ScreenTriangle triangleToScreenSpace(Triangle tri)
//{
//   ScreenTriangle screenTri;
//
//   screenTri.v0.x = ((tri.v0.x + 1) * (MY_WINDOW_SIZE - 1)) / 2;
//   screenTri.v0.y = ((tri.v0.y + 1) * (MY_WINDOW_SIZE - 1)) / 2;
//   screenTri.v0z = tri.v0.z;
//
//   screenTri.v1.x = ((tri.v1.x + 1) * (MY_WINDOW_SIZE - 1)) / 2;
//   screenTri.v1.y = ((tri.v1.y + 1) * (MY_WINDOW_SIZE - 1)) / 2;
//    screenTri.v1z = tri.v1.z;
//
//   screenTri.v2.x = ((tri.v2.x + 1) * (MY_WINDOW_SIZE - 1)) / 2;
//   screenTri.v2.y = ((tri.v2.y + 1) * (MY_WINDOW_SIZE - 1)) / 2;
//    screenTri.v2z = tri.v2.z;
//
//    screenTri.normal = glm::normalize(glm::cross(glm::normalize(tri.v1 - tri.v0), glm::normalize(tri.v2 - tri.v0)));
//
//   screenTri.topLeft.x = min(min(screenTri.v0.x, screenTri.v1.x), screenTri.v2.x);
//    screenTri.topLeft.y = min(min(screenTri.v0.y, screenTri.v1.y), screenTri.v2.y);
//
//    screenTri.bottomRight.x = max(max(screenTri.v0.x, screenTri.v1.x), screenTri.v2.x);
//    screenTri.bottomRight.y = max(max(screenTri.v0.y, screenTri.v1.y), screenTri.v2.y);
//
//   return screenTri;
//}

__global__ void drawTriangle(Triangle *tris, int size, float *redColorBuffer_d, float *greenColorBuffer_d,
      float *blueColorBuffer_d, int *depthBuffer_d)
{
   if (blockIdx.x * blockDim.x + threadIdx.x >= size) {
      return;
   }

   Triangle tri = tris[blockIdx.x * blockDim.x + threadIdx.x];
   /*
   tri.v0 = glm::vec3(0.0, 0.5, 0.0);
   tri.v1 = glm::vec3(-0.5, -0.5, 0.0);
   tri.v2 = glm::vec3(0.5, -0.25, 0.0);
   */

   ScreenTriangle screenTri;

   screenTri.v0.x = ((tri.v0.x + 1) * (MY_WINDOW_SIZE - 1)) / 2;
   screenTri.v0.y = ((tri.v0.y + 1) * (MY_WINDOW_SIZE - 1)) / 2;
   screenTri.v0z = tri.v0.z;

   screenTri.v1.x = ((tri.v1.x + 1) * (MY_WINDOW_SIZE - 1)) / 2;
   screenTri.v1.y = ((tri.v1.y + 1) * (MY_WINDOW_SIZE - 1)) / 2;
    screenTri.v1z = tri.v1.z;

   screenTri.v2.x = ((tri.v2.x + 1) * (MY_WINDOW_SIZE - 1)) / 2;
   screenTri.v2.y = ((tri.v2.y + 1) * (MY_WINDOW_SIZE - 1)) / 2;
    screenTri.v2z = tri.v2.z;

    screenTri.normal = glm::normalize(glm::cross(glm::normalize(tri.v1 - tri.v0), glm::normalize(tri.v2 - tri.v0)));

   screenTri.topLeft.x = min(min(screenTri.v0.x, screenTri.v1.x), screenTri.v2.x);
    screenTri.topLeft.y = min(min(screenTri.v0.y, screenTri.v1.y), screenTri.v2.y);

    screenTri.bottomRight.x = max(max(screenTri.v0.x, screenTri.v1.x), screenTri.v2.x);
    screenTri.bottomRight.y = max(max(screenTri.v0.y, screenTri.v1.y), screenTri.v2.y);

   glm::vec3 light = glm::normalize(glm::vec3(1.0, 0.0, 1.0));

    float area = glm::determinant(glm::mat2(screenTri.v2 - screenTri.v0, screenTri.v1 - screenTri.v0));
    float color = max(glm::dot(screenTri.normal, light), 0.0f);

    for (int y = screenTri.topLeft.y; y < screenTri.bottomRight.y; ++y)
    {
        for (int x = screenTri.topLeft.x; x < screenTri.bottomRight.x; ++x)
        {
            if (x >= MY_WINDOW_SIZE || y >= MY_WINDOW_SIZE)
            {
                continue;
            }

            glm::ivec2 point(x, y);

            float a = glm::determinant(glm::mat2(screenTri.v2 - point, screenTri.v1 - point)) / area;
            float b = glm::determinant(glm::mat2(screenTri.v1 - point, screenTri.v0 - point)) / area;
            float g = glm::determinant(glm::mat2(screenTri.v0 - point, screenTri.v2 - point)) / area;

            if (a < 0 || b  < 0 || g < 0)
            {
                continue;
            }

            int depth = (a * screenTri.v0z + b * screenTri.v1z + g * screenTri.v2z) * 10000;

            if (depth > atomicMax(&(depthBuffer_d[(y * MY_WINDOW_SIZE) + x]), depth))
            {
                //depthBuffer_d[(y * MY_WINDOW_SIZE) + x] = depth;

                redColorBuffer_d[(y * MY_WINDOW_SIZE) + x] = color;
                greenColorBuffer_d[(y * MY_WINDOW_SIZE) + x] = color;
                blueColorBuffer_d[(y * MY_WINDOW_SIZE) + x] = color;
            }
        }
    }
}

void writeImageToFile()
{
   Image img(MY_WINDOW_SIZE, MY_WINDOW_SIZE);

   for (int y = 0; y < MY_WINDOW_SIZE; ++y)
   {
      for (int x = 0; x < MY_WINDOW_SIZE; ++x)
      {
         color_t col;
         col.r = redColorBuffer[(y * MY_WINDOW_SIZE) + x];
         col.g = greenColorBuffer[(y * MY_WINDOW_SIZE) + x];
         col.b = blueColorBuffer[(y * MY_WINDOW_SIZE) + x];
         col.f = 1.0f;


         img.pixel(x, y, col);
      }
   }

   img.WriteTga("IMG.tga", false);
}

int main()
{
   float *redColorBuffer_d, *greenColorBuffer_d, *blueColorBuffer_d;
   int *depthBuffer_d;
   Triangle *triangleBuffer_d;

   cudaMalloc((void **) &redColorBuffer_d, sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE);
   cudaMalloc((void **) &greenColorBuffer_d, sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE);
   cudaMalloc((void **) &blueColorBuffer_d, sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE);
   cudaMalloc((void **) &depthBuffer_d, sizeof(int) * MY_WINDOW_SIZE * MY_WINDOW_SIZE);

    for (int i = 0; i < MY_WINDOW_SIZE * MY_WINDOW_SIZE; ++i)
    {
        redColorBuffer[i] = 0.0;
        greenColorBuffer[i] = 1.0;
        blueColorBuffer[i] = 0.0;
        depthBuffer[i] = -2147483648;
//      depthBuffer[i] = FLT_MIN;
    }

   //memset(redColorBuffer, 0.0, sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE);
   cudaMemcpy(redColorBuffer_d, redColorBuffer,
    sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE, cudaMemcpyHostToDevice);

   //memset(greenColorBuffer, 1.0f, sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE);
   cudaMemcpy(greenColorBuffer_d, greenColorBuffer,
    sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE, cudaMemcpyHostToDevice);

   //memset(blueColorBuffer, 0.0, sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE);
   cudaMemcpy(blueColorBuffer_d, blueColorBuffer,
    sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE, cudaMemcpyHostToDevice);

   //memset(depthBuffer, –214748364, sizeof(int) * MY_WINDOW_SIZE * MY_WINDOW_SIZE);
   cudaMemcpy(depthBuffer_d, depthBuffer,
    sizeof(int) * MY_WINDOW_SIZE * MY_WINDOW_SIZE, cudaMemcpyHostToDevice);


   Mesh mesh = loadMesh("bunny10k.m");
   cudaMalloc((void **) &triangleBuffer_d, sizeof(Triangle) * mesh.tris.size());
   cudaMemcpy(triangleBuffer_d, &(mesh.tris[0]), sizeof(Triangle) * mesh.tris.size(), cudaMemcpyHostToDevice);

   int numBlocks = round_up(mesh.tris.size(), NUM_THREADS);


//    for (int i = 0; i < mesh.tris.size(); ++i)
   {
      //std::cout << "Triangle: " << i << std::endl;
      drawTriangle<<<numBlocks, NUM_THREADS>>>(triangleBuffer_d, mesh.tris.size(), redColorBuffer_d, greenColorBuffer_d, blueColorBuffer_d, depthBuffer_d);
   }

   cudaMemcpy(redColorBuffer, redColorBuffer_d,
    sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE, cudaMemcpyDeviceToHost);

   cudaMemcpy(greenColorBuffer, greenColorBuffer_d,
    sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE, cudaMemcpyDeviceToHost);

   cudaMemcpy(blueColorBuffer, blueColorBuffer_d,
    sizeof(float) * MY_WINDOW_SIZE * MY_WINDOW_SIZE, cudaMemcpyDeviceToHost);

   writeImageToFile();
   
   cudaFree(redColorBuffer_d);
   cudaFree(greenColorBuffer_d);
   cudaFree(blueColorBuffer_d);
   cudaFree(depthBuffer_d);

   printf("Done!");

   return 0;
}

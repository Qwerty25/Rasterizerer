/*
 * MeshLoader.cpp
 *
 *  Created on: Apr 20, 2012
 *      Author: Wyatt
 */

#include "MeshLoader.h"
#include <iostream>
#include <fstream>

Mesh loadMesh(std::string filename)
{
    Mesh mesh;

    std::ifstream meshStream(filename.c_str());

    std::string param;
    std::string junk;

    while (meshStream)
    {
        meshStream >> param;

        if (param == "Vertex")
        {
            glm::vec3 vert;
            meshStream >> junk >> vert.x >> vert.y >> vert.z;
            mesh.verts.push_back(vert);
        }
        else if (param == "Face")
        {
            Triangle tri;
            int index;
            meshStream >> junk;

            meshStream >> index;
            tri.v0 = mesh.verts[index - 1];

            meshStream >> index;
            tri.v1 = mesh.verts[index - 1];

            meshStream >> index;
            tri.v2 = mesh.verts[index - 1];

            mesh.tris.push_back(tri);
        }
        else
        {

        }
    }

    for (int i = 0; i < 10; ++i)
    {
        std::cout << "V0 X: " << mesh.tris[i].v0.x << ", Y: " << mesh.tris[i].v0.y << ", Z: " << mesh.tris[i].v0.z << std::endl;
        std::cout << "V1 X: " << mesh.tris[i].v1.x << ", Y: " << mesh.tris[i].v1.y << ", Z: " << mesh.tris[i].v1.z << std::endl;
        std::cout << "V2 X: " << mesh.tris[i].v2.x << ", Y: " << mesh.tris[i].v2.y << ", Z: " << mesh.tris[i].v2.z << std::endl;
    }

    std::cout << "done loading" << std::endl;

    return mesh;
}

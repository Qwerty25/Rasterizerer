/*
 * MeshLoader.h
 *
 *  Created on: Apr 17, 2012
 *      Author: Wyatt
 */

#ifndef MESHLOADER_H_
#define MESHLOADER_H_

#include <vector>
#include "glm/glm.hpp"
#include <string>

struct Triangle
{
	glm::vec3 v0, v1, v2;
	//glm::vec3 normal;
};

struct ScreenTriangle
{
	glm::ivec2 v0, v1, v2;
	float v0z, v1z, v2z;

	glm::vec3 normal;
	glm::vec3 c0, c1, c2;

	glm::ivec2 topLeft, bottomRight;
};

struct Mesh
{
    std::vector<glm::vec3> verts;
	std::vector<Triangle> tris;
};

Mesh loadMesh(std::string filename);

#endif /* MESHLOADER_H_ */

#version 330 core
layout (location = 0) in vec2 position;
layout (location = 1) in vec2 texCoord;

out vec2 TexCoords;

uniform mat3 transform;

void main()
{
    vec3 p = transform * vec3(position, 1.0);
    gl_Position = vec4(p.xy, 0.0, 1.0);
    TexCoords = texCoord;
}
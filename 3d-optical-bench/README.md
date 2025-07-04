# old_fragment v.s. fragment
I was using old_fragmentShader as a copy from the ray tracing example. I then tried to fuse ray tracing and non ray traced meshes in that file. 
I started anew with fragShader when I instead wanted to run ray tracing with ray marching.

# Description 
This project implements a real-time 3D optical bench simulation using WebGL and ray marching
   techniques to recreate optical physics in a browser environment. It features mathematically
   precise lens modeling through signed distance functions (SDFs), where convex lenses are
  rendered as intersections of two spheres and concave lenses as boxes subtracted from
  spheres. Key technical achievements include smooth morphing transitions between lens types
  using SDF blending, physically-based light ray simulation with dynamic path adjustments
  based on focal lengths, real-time ray marching with gradient-based lighting calculations,
  interactive 3D camera controls.
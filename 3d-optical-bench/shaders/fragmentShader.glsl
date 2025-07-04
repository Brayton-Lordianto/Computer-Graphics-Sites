const int NLIGHTS = 2;
const int NSPHERES = 100;
precision mediump float;

uniform float uTime, uFL;
varying vec3 vPos;

uniform vec3 uCamera;
uniform vec3 uCameraDirection;
uniform vec3 uColor;
varying vec3 vNor;
varying float fApplyTransform;

vec3 bgColor = vec3(0.78, 0.87, 0.76);
// ====================================================================

// Cellular noise ("Worley noise") in 3D in GLSL.
// Copyright (c) Stefan Gustavson 2011-04-19. All rights reserved.
// This code is released under the conditions of the MIT license.
// See LICENSE file for details.
// https://github.com/stegu/webgl-noise

// Modulo 289 without a division (only multiplications)
vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

// Modulo 7 without a division
vec3 mod7(vec3 x) {
  return x - floor(x * (1.0 / 7.0)) * 7.0;
}

// Permutation polynomial: (34x^2 + 6x) mod 289
vec3 permute(vec3 x) {
  return mod289((34.0 * x + 10.0) * x);
}

// Cellular noise, returning F1 and F2 in a vec2.
// 3x3x3 search region for good F2 everywhere, but a lot
// slower than the 2x2x2 version.
// The code below is a bit scary even to its author,
// but it has at least half decent performance on a
// modern GPU. In any case, it beats any software
// implementation of Worley noise hands down.

vec2 cellular(vec3 P) {
#define K 0.142857142857 // 1/7
#define Ko 0.428571428571 // 1/2-K/2
#define K2 0.020408163265306 // 1/(7*7)
#define Kz 0.166666666667 // 1/6
#define Kzo 0.416666666667 // 1/2-1/6*2
#define jitter 1.0 // smaller jitter gives more regular pattern

	vec3 Pi = mod289(floor(P));
 	vec3 Pf = fract(P) - 0.5;

	vec3 Pfx = Pf.x + vec3(1.0, 0.0, -1.0);
	vec3 Pfy = Pf.y + vec3(1.0, 0.0, -1.0);
	vec3 Pfz = Pf.z + vec3(1.0, 0.0, -1.0);

	vec3 p = permute(Pi.x + vec3(-1.0, 0.0, 1.0));
	vec3 p1 = permute(p + Pi.y - 1.0);
	vec3 p2 = permute(p + Pi.y);
	vec3 p3 = permute(p + Pi.y + 1.0);

	vec3 p11 = permute(p1 + Pi.z - 1.0);
	vec3 p12 = permute(p1 + Pi.z);
	vec3 p13 = permute(p1 + Pi.z + 1.0);

	vec3 p21 = permute(p2 + Pi.z - 1.0);
	vec3 p22 = permute(p2 + Pi.z);
	vec3 p23 = permute(p2 + Pi.z + 1.0);

	vec3 p31 = permute(p3 + Pi.z - 1.0);
	vec3 p32 = permute(p3 + Pi.z);
	vec3 p33 = permute(p3 + Pi.z + 1.0);

	vec3 ox11 = fract(p11*K) - Ko;
	vec3 oy11 = mod7(floor(p11*K))*K - Ko;
	vec3 oz11 = floor(p11*K2)*Kz - Kzo; // p11 < 289 guaranteed

	vec3 ox12 = fract(p12*K) - Ko;
	vec3 oy12 = mod7(floor(p12*K))*K - Ko;
	vec3 oz12 = floor(p12*K2)*Kz - Kzo;

	vec3 ox13 = fract(p13*K) - Ko;
	vec3 oy13 = mod7(floor(p13*K))*K - Ko;
	vec3 oz13 = floor(p13*K2)*Kz - Kzo;

	vec3 ox21 = fract(p21*K) - Ko;
	vec3 oy21 = mod7(floor(p21*K))*K - Ko;
	vec3 oz21 = floor(p21*K2)*Kz - Kzo;

	vec3 ox22 = fract(p22*K) - Ko;
	vec3 oy22 = mod7(floor(p22*K))*K - Ko;
	vec3 oz22 = floor(p22*K2)*Kz - Kzo;

	vec3 ox23 = fract(p23*K) - Ko;
	vec3 oy23 = mod7(floor(p23*K))*K - Ko;
	vec3 oz23 = floor(p23*K2)*Kz - Kzo;

	vec3 ox31 = fract(p31*K) - Ko;
	vec3 oy31 = mod7(floor(p31*K))*K - Ko;
	vec3 oz31 = floor(p31*K2)*Kz - Kzo;

	vec3 ox32 = fract(p32*K) - Ko;
	vec3 oy32 = mod7(floor(p32*K))*K - Ko;
	vec3 oz32 = floor(p32*K2)*Kz - Kzo;

	vec3 ox33 = fract(p33*K) - Ko;
	vec3 oy33 = mod7(floor(p33*K))*K - Ko;
	vec3 oz33 = floor(p33*K2)*Kz - Kzo;

	vec3 dx11 = Pfx + jitter*ox11;
	vec3 dy11 = Pfy.x + jitter*oy11;
	vec3 dz11 = Pfz.x + jitter*oz11;

	vec3 dx12 = Pfx + jitter*ox12;
	vec3 dy12 = Pfy.x + jitter*oy12;
	vec3 dz12 = Pfz.y + jitter*oz12;

	vec3 dx13 = Pfx + jitter*ox13;
	vec3 dy13 = Pfy.x + jitter*oy13;
	vec3 dz13 = Pfz.z + jitter*oz13;

	vec3 dx21 = Pfx + jitter*ox21;
	vec3 dy21 = Pfy.y + jitter*oy21;
	vec3 dz21 = Pfz.x + jitter*oz21;

	vec3 dx22 = Pfx + jitter*ox22;
	vec3 dy22 = Pfy.y + jitter*oy22;
	vec3 dz22 = Pfz.y + jitter*oz22;

	vec3 dx23 = Pfx + jitter*ox23;
	vec3 dy23 = Pfy.y + jitter*oy23;
	vec3 dz23 = Pfz.z + jitter*oz23;

	vec3 dx31 = Pfx + jitter*ox31;
	vec3 dy31 = Pfy.z + jitter*oy31;
	vec3 dz31 = Pfz.x + jitter*oz31;

	vec3 dx32 = Pfx + jitter*ox32;
	vec3 dy32 = Pfy.z + jitter*oy32;
	vec3 dz32 = Pfz.y + jitter*oz32;

	vec3 dx33 = Pfx + jitter*ox33;
	vec3 dy33 = Pfy.z + jitter*oy33;
	vec3 dz33 = Pfz.z + jitter*oz33;

	vec3 d11 = dx11 * dx11 + dy11 * dy11 + dz11 * dz11;
	vec3 d12 = dx12 * dx12 + dy12 * dy12 + dz12 * dz12;
	vec3 d13 = dx13 * dx13 + dy13 * dy13 + dz13 * dz13;
	vec3 d21 = dx21 * dx21 + dy21 * dy21 + dz21 * dz21;
	vec3 d22 = dx22 * dx22 + dy22 * dy22 + dz22 * dz22;
	vec3 d23 = dx23 * dx23 + dy23 * dy23 + dz23 * dz23;
	vec3 d31 = dx31 * dx31 + dy31 * dy31 + dz31 * dz31;
	vec3 d32 = dx32 * dx32 + dy32 * dy32 + dz32 * dz32;
	vec3 d33 = dx33 * dx33 + dy33 * dy33 + dz33 * dz33;

	// Sort out the two smallest distances (F1, F2)
#if 0
	// Cheat and sort out only F1
	vec3 d1 = min(min(d11,d12), d13);
	vec3 d2 = min(min(d21,d22), d23);
	vec3 d3 = min(min(d31,d32), d33);
	vec3 d = min(min(d1,d2), d3);
	d.x = min(min(d.x,d.y),d.z);
	return vec2(sqrt(d.x)); // F1 duplicated, no F2 computed
#else
	// Do it right and sort out both F1 and F2
	vec3 d1a = min(d11, d12);
	d12 = max(d11, d12);
	d11 = min(d1a, d13); // Smallest now not in d12 or d13
	d13 = max(d1a, d13);
	d12 = min(d12, d13); // 2nd smallest now not in d13
	vec3 d2a = min(d21, d22);
	d22 = max(d21, d22);
	d21 = min(d2a, d23); // Smallest now not in d22 or d23
	d23 = max(d2a, d23);
	d22 = min(d22, d23); // 2nd smallest now not in d23
	vec3 d3a = min(d31, d32);
	d32 = max(d31, d32);
	d31 = min(d3a, d33); // Smallest now not in d32 or d33
	d33 = max(d3a, d33);
	d32 = min(d32, d33); // 2nd smallest now not in d33
	vec3 da = min(d11, d21);
	d21 = max(d11, d21);
	d11 = min(da, d31); // Smallest now in d11
	d31 = max(da, d31); // 2nd smallest now not in d31
	d11.xy = (d11.x < d11.y) ? d11.xy : d11.yx;
	d11.xz = (d11.x < d11.z) ? d11.xz : d11.zx; // d11.x now smallest
	d12 = min(d12, d21); // 2nd smallest now not in d21
	d12 = min(d12, d22); // nor in d22
	d12 = min(d12, d31); // nor in d31
	d12 = min(d12, d32); // nor in d32
	d11.yz = min(d11.yz,d12.xy); // nor in d12.yz
	d11.y = min(d11.y,d12.z); // Only two more to go
	d11.y = min(d11.y,d11.z); // Done! (Phew!)
	return sqrt(d11.xy); // F1, F2
#endif
}
// ====================================================================
// OBJECTS
// ====================================================================

vec3 red = vec3(1.,0.,0.), green = vec3(0.,1.,0.), blue = vec3(0.,0.,1.), white = vec3(1.,1.,1.), black = vec3(0.,0.,0.), yellow = vec3(1.,1.,0.), purple = vec3(1.,0.,1.), cyan = vec3(0.,1.,1.), orange = vec3(1.,0.5,0.), pink = vec3(1.,0.5,0.5), brown = vec3(0.5,0.25,0.);
# define OBJECTS_SIZE 10
# define LINES_SIZE OBJECTS_SIZE * 2
# define OPTICAL_COMPONENTS_SIZE OBJECTS_SIZE * 2

# define LINE_RADIUS 0.0001; 
struct Line { vec3 point1, point2, color; }; // a capsule is a line with two spheres on the end
struct Lines { Line at[LINES_SIZE]; int size; };
struct Sphere { vec3 center, color; float radius;  };
struct Box { vec3 center, color; float radius; };
Line exampleLine = Line(vec3(-1.,0.,-5.), vec3(1.,2.,-3.), vec3(1.,1.,1.)); Line exampleLine2 = Line(vec3(1.,2.,-3.), vec3(1.,-2.,-3.), vec3(1.,1.,1.));
Sphere exampleSphere = Sphere(vec3(0.6,0.,-5.), vec3(1.,0.,0.), 1.); Sphere exampleSphere2 = Sphere(vec3(-0.6,0.,-5.), vec3(1.,0.,0.), 01.);

// a convex lens is twos spheres intersecting 
// a concave lens is a box subtracted from two spheres
float CONVEX_FOCAL_LENGTH = 0.2;
float CONCAVE_FOCAL_LENGTH = -0.2;
//struct LensProperties { float focalLength, thickness, angle; vec3 coordinate; };
struct ConvexLens { Sphere sphere1, sphere2; }; 
struct ConcaveLens { Sphere sphere1, sphere2; Box box; };
// struct OpticalComponent { ConvexLens convexLens; ConcaveLens concaveLens; bool isConvex; float thickness, angle; };
struct OpticalComponent { ConvexLens convexLens; ConcaveLens concaveLens; bool isConvex, isTransitioning; float thickness, angle, focalLength; };
struct OpticalComponents { OpticalComponent at[OPTICAL_COMPONENTS_SIZE]; int size; };
ConvexLens nullConvexLens = ConvexLens(Sphere(vec3(0.,0.,0.), vec3(0.,0.,0.), 0.), Sphere(vec3(0.,0.,0.), vec3(0.,0.,0.), 0.));
ConcaveLens nullConcaveLens = ConcaveLens(Sphere(vec3(0.,0.,0.), vec3(0.,0.,0.), 0.), Sphere(vec3(0.,0.,0.), vec3(0.,0.,0.), 0.), Box(vec3(0.,0.,0.), vec3(0.,0.,0.), 0.));

OpticalComponents opticalComponents;
uniform float focalLengths[10];
uniform Lines lines;

// in a desparate effort to reach the deadline, I will hard code a LOT 
uniform float uSizeOffset1, uSizeOffset2, secondIsConcave; 
uniform float uBackgroundLenses; // if 0, then no background lenses. if 1, then background lenses. if 2, then background lenses and lines

// ====================================================================
// MATHEMATICAL UTILITIES
// ====================================================================
// Rotation matrix around the X axis.
mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(vec3(1, 0, 0), vec3(0, c, -s), vec3(0, s, c));
}

// Rotation matrix around the Y axis.
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(vec3(c, 0, s), vec3(0, 1, 0), vec3(-s, 0, c));
}

// get SDF with the intent of choosing an SDF to an intersection of two spheres
float smoothmax(float distanceToA, float distanceToB, float smoothness) {
    float h = clamp(0.5 + 0.5 * (distanceToB - distanceToA) / smoothness, 0.0, 1.0);
    return mix(distanceToA, distanceToB, h) + smoothness * h * (1.0 - h);
}

// ====================================================================
// OTHER UTILITIES
// ====================================================================

vec3 O = vec3(0.,0.,0.);

// returns the second if x < y
// otherwise return the default value
float ReturnSecondIfXltEdge(float edge, float x, float second, float defaultVal) {
    // if x < edge, step(edge, x) returns 0
    return mix(second, defaultVal, step(edge, x));
}

vec3 ReturnSecondIfXltEdge(float edge, float x, vec3 second, vec3 defaultVal) {
    // if x < edge, step(edge, x) returns 0
    return mix(second, defaultVal, step(edge, x));
}

#define HEIGHT_OF_PLANE -1. // change this to change the height of the floor plane
float getHeightOfPlane() {
    return HEIGHT_OF_PLANE < 1. ? 1000000. : HEIGHT_OF_PLANE;
}

Line line(vec3 from, vec3 to) {
    return Line(from, to, vec3(1.,1.,1.));
}

Sphere SphereWithRadius(float radius) {
    return Sphere(vec3(0.,0.,0.), vec3(1.,1.,1.), radius);
}

bool isTransitioning(float focalLength) {
    return (focalLength != CONVEX_FOCAL_LENGTH && focalLength != CONCAVE_FOCAL_LENGTH);
}

bool isConvex(float focalLength) {
    return focalLength == CONVEX_FOCAL_LENGTH;
}

bool isConcave(float focalLength) {
    return focalLength == CONCAVE_FOCAL_LENGTH;
}

ConcaveLens createConcaveLensObject(vec3 coordinate, float unadjustedThickness) {
    float thickness = unadjustedThickness - 0.15; // now thickness from convex and concave lens are the same by scale
    float rbox = thickness; 
    float a = (sqrt(3.) / 4.) * rbox;
    float xOffset = rbox + a; 
    float rsphere = sqrt(pow(rbox, 2.) + pow(a, 2.));
    float diff = rbox / 0.1 * 0.03; // from experimentation
    float constant = 0.6; // from experimentation
    xOffset += constant;
    rsphere += constant + diff;

    Sphere sphere3 = SphereWithRadius(rsphere); Sphere sphere4 = SphereWithRadius(rsphere);
    Box box = Box(coordinate, vec3(1.,0.,0.), rbox);
    sphere3.center += coordinate; sphere4.center += coordinate;
    sphere3.center.x += xOffset; sphere4.center.x -= xOffset;
    ConcaveLens concaveLens = ConcaveLens(sphere3, sphere4, box);
    return concaveLens;
}

ConvexLens createConvexLensObject(vec3 coordinate, float unadjustedThickness) {
    // if thickness <= 0.5, give thickness - 1, else give .4. Done through experimentation. if you increase this, the lens will be more concave but also smaller (as long as within bounds of thickness)
    // float xOffset = ReturnSecondIfXltEdge(0.51, thickness, thickness - .08, 0.4); // DEPRECATED
    float thickness = unadjustedThickness; // we are using the convex len's thickness as the ground truth
    float diff = 0.3 * thickness;
    float xOffset = thickness - diff;
    float radius = thickness; 
    Sphere sphere1 = SphereWithRadius(radius); Sphere sphere2 = SphereWithRadius(radius);
    sphere1.center.x += xOffset; sphere2.center.x -= xOffset;
    sphere1.center += coordinate; sphere2.center += coordinate;
    ConvexLens convexLens = ConvexLens(sphere1, sphere2);
    return convexLens;
}

// TODO: calculations
OpticalComponent createConcaveLens(vec3 coordinate, float unadjustedThickness) {
    float thickness = unadjustedThickness - 0.15; // now thickness from convex and concave lens are the same by scale
    ConcaveLens concaveLens = createConcaveLensObject(coordinate, unadjustedThickness);
    ConvexLens convexLens = createConvexLensObject(coordinate, unadjustedThickness);
    OpticalComponent component = OpticalComponent(convexLens, concaveLens, false, true, thickness, 0., 0.2);
    return component;
}

OpticalComponent createConvexLens(vec3 coordinate, float unadjustedThickness) {
    float thickness = unadjustedThickness; // we are using the convex len's thickness as the ground truth
    ConvexLens convexLens = createConvexLensObject(coordinate, unadjustedThickness);
    ConcaveLens concaveLens = createConcaveLensObject(coordinate, unadjustedThickness);
    OpticalComponent convexLensComponent = OpticalComponent(convexLens, concaveLens, true, false, thickness, 0., 0.2);
    return convexLensComponent;
}

// ==========================================================
// RAY MARCHING
// ====================================================================

#define MAX_STEPS 100
#define MAX_DIST 100.
#define MIN_DIST 0.01
#define SURF_DIST 0.05

vec4 sphereScene[100];
vec4 box = vec4(0.,0.,-5.,0.5);

struct RayMarchHit { float distance; vec3 colorOfObject; };

RayMarchHit sdfBox(Box B, vec3 P) {
    vec3 C = B.center;
    float r = B.radius;
    vec3 d = abs(P - C) - vec3(r);
    return RayMarchHit(length(max(d, 0.)), B.color);
}

RayMarchHit sdfSphere(vec3 p, Sphere sphere) {
    vec3 C = sphere.center;
    float r = sphere.radius;
    return RayMarchHit(length(p - C) - r, sphere.color);
}

RayMarchHit sdfLine(vec3 p, Line line) {
    vec3 sphere1toSphere2 = line.point2 - line.point1;
    vec3 sphere1toP = p - line.point1;
    float stepsInDirectionOfMidLine = dot(sphere1toP, sphere1toSphere2) / dot(sphere1toSphere2, sphere1toSphere2);
    float clampedStepsInDirectionOfMidLine = clamp(stepsInDirectionOfMidLine, 0., 1.);
    vec3 closestPointOnLine = line.point1 + clampedStepsInDirectionOfMidLine * sphere1toSphere2;
    float distanceToCapsuleSurface = length(p - closestPointOnLine) - LINE_RADIUS;
    return RayMarchHit(distanceToCapsuleSurface, line.color);
}

RayMarchHit sdfConvexLens(vec3 p, ConvexLens lens) {
    float smoothness = 0.05;
    float distToSphere1 = sdfSphere(p, lens.sphere1).distance;
    float distToSphere2 = sdfSphere(p, lens.sphere2).distance;
    float d = smoothmax(distToSphere1, distToSphere2, smoothness);
    return RayMarchHit(d, lens.sphere1.color);
}

RayMarchHit sdfConcaveLens(vec3 p, ConcaveLens lens) { 
    float boxDist = sdfBox(lens.box, p).distance, sphere1Dist = sdfSphere(p, lens.sphere1).distance, sphere2Dist = sdfSphere(p, lens.sphere2).distance;
    float d = boxDist;
    d = max(d, -sphere1Dist);
    d = max(d, -sphere2Dist);
    
    // MARK: CHANGE THIS LATER 
    if (d == boxDist) return RayMarchHit(d, lens.box.color);
    if (d == -sphere1Dist) return RayMarchHit(d, lens.sphere1.color);
    if (d == -sphere2Dist) return RayMarchHit(d, lens.sphere2.color);
    return RayMarchHit(d, vec3(1.,1.,1.));
}

RayMarchHit sdfBlend(vec3 p, OpticalComponent opticalComponent, float focalLength) {
    RayMarchHit caveHit = sdfConcaveLens(p, opticalComponent.concaveLens);
    RayMarchHit vecHit = sdfConvexLens(p, opticalComponent.convexLens);
    RayMarchHit initial, final;
    // the mixFactor goes from 0 to 1, following focalLength from CONCAVE_FOCAL_LENGTH to CONVEX_FOCAL_LENGTH
    float mixFactor = secondIsConcave / 2. + 0.5;
    if (opticalComponent.isConvex) { initial = vecHit; final = caveHit; 
        mixFactor = abs(focalLength - CONCAVE_FOCAL_LENGTH) / abs(CONVEX_FOCAL_LENGTH - CONCAVE_FOCAL_LENGTH);} 
    else { initial = caveHit; final = vecHit;
        mixFactor = abs(focalLength - CONVEX_FOCAL_LENGTH) / abs(CONCAVE_FOCAL_LENGTH - CONVEX_FOCAL_LENGTH); }
    // mixFactor = sin(uTime / 2.) * 0.5 + 0.5;
    mixFactor = secondIsConcave / 2. + 0.5;
    float d = mix(initial.distance, final.distance, mixFactor);
    return RayMarchHit(d, initial.colorOfObject);
}

// MARK: right now, we allow transition for all optical components. Just for now.
RayMarchHit sdfOpticalComponent(vec3 p, OpticalComponent opticalComponent, float focalLength) {
    
    return sdfBlend(p, opticalComponent, focalLength);
    if (isConvex(focalLength)) return sdfConvexLens(p, opticalComponent.convexLens);
    return sdfConcaveLens(p, opticalComponent.concaveLens);
}

// sdf of all the optical components and lines
RayMarchHit sdfScene(vec3 p) {
    float d = getHeightOfPlane();
    vec3 color = vec3(1.,1.,1.);
    RayMarchHit rayMarchHit;
    for (int i = 2; i < OPTICAL_COMPONENTS_SIZE; i++) {
        if (i >= opticalComponents.size) break;

        float focalLength = focalLengths[i];
        OpticalComponent component = opticalComponents.at[i];
        rayMarchHit = sdfOpticalComponent(p, component, focalLength);
        d = min(d, rayMarchHit.distance);
    }
    // 0th index use blend 
    rayMarchHit = sdfBlend(p, opticalComponents.at[0], focalLengths[0]);
    d = min(d, rayMarchHit.distance);
    // 1st index use concave
    rayMarchHit = sdfConvexLens(p, opticalComponents.at[1].convexLens);
    d = min(d, rayMarchHit.distance);
    for (int i = 0; i < LINES_SIZE; i++) {
        if (i >= lines.size) break;

        Line line = lines.at[i];
        rayMarchHit = sdfLine(p, line);
        color = ReturnSecondIfXltEdge(rayMarchHit.distance, d, rayMarchHit.colorOfObject, color);
        d = min(d, rayMarchHit.distance);
    }
    return RayMarchHit(d, vec3(0.18, 0.58, 0.71));
}

float sdfSceneDistance(vec3 p) { return sdfScene(p).distance; }



RayMarchHit rayMarch(vec3 rayOrigin, vec3 rayDir) {
    float accDstToScene = 0.; 
    vec3 color = vec3(1.,1.,1.);
    for (int i = 0; i<MAX_STEPS; i++) {
        vec3 pointOnSphereCast = rayOrigin + rayDir * accDstToScene;
        RayMarchHit rayMarchHit = sdfScene(pointOnSphereCast);
        float currDstToScene = rayMarchHit.distance;
        accDstToScene += currDstToScene;
        if (accDstToScene > MAX_DIST || currDstToScene < MIN_DIST) { color = rayMarchHit.colorOfObject; break; } 
    }
    return RayMarchHit(accDstToScene, color);
}

float rayMarchDistance(vec3 rayOrigin, vec3 rayDir) {
    return rayMarch(rayOrigin, rayDir).distance;
}

// ====================================================================
// LIGHTING ON RAY MARCHING
// ====================================================================

// this calculates the normal of the point for lighting purposes. It does so by calculating little gradients
vec3 calculateNormal(in vec3 p) {
    const vec3 small_step = vec3(0.001, 0.0, 0.0);

    // this uses a swizzle
    float gradient_x = sdfSceneDistance(p + small_step.xyy) - sdfSceneDistance(p - small_step.xyy);
    float gradient_y = sdfSceneDistance(p + small_step.yxy) - sdfSceneDistance(p - small_step.yxy);
    float gradient_z = sdfSceneDistance(p + small_step.yyx) - sdfSceneDistance(p - small_step.yyx);

    vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

// getting shadows with ray marching. It is as simple as ray marching from the intersection point, and checking if that sdf is less than the distance to the light
bool isShadowed(vec3 intersectedPoint, vec3 lightPos) {
    // we have to add the intersected point by a small amount in the direction of the normal, otherwise we will get self-intersection
    vec3 adjustedIntersectedPoint = intersectedPoint + calculateNormal(intersectedPoint) * SURF_DIST;
    float sdtTowardsLight = rayMarchDistance(adjustedIntersectedPoint, lightPos - adjustedIntersectedPoint);
    float dstFromLight = length(lightPos - adjustedIntersectedPoint);
    return sdtTowardsLight < dstFromLight;
}

// if it is in the shadow, apply the shadow effect 
vec3 applyShadow(vec3 diffuse) {
    return diffuse * 1.;
}

// this gets the lighting for a single point which has been hit by the ray 
float getLight(vec3 point, vec3 lightPos, vec3 lightColor) {
    vec3 lightDir = normalize(lightPos - point);
    vec3 normal = calculateNormal(point);
    float diffuse = max(dot(normal, lightDir), 0.0);
    return diffuse;
}

vec3 getColor(vec3 point) {
    vec3 lightPos = vec3(0.,3.,-2.); // vec3(0., 1., 0.);
    vec3 lightColor = vec3(1., 1., 1.);
    float diffuse = getLight(point, lightPos, lightColor);
    vec3 diffuseComponent = vec3(diffuse); 
    if (isShadowed(point, lightPos)) diffuseComponent = applyShadow(diffuseComponent);
    vec3 ambientComponent = vec3(.5);
    return diffuseComponent + ambientComponent;
}

// ====================================================================
// MAIN
// ====================================================================

void initializeLines() {
    // lines.at[0] = line(vec3(-3.,0.,-5.),  opticalComponents.at[0].concaveLens.box.center + opticalComponents.at[0].concaveLens.properties.thickness * vec3(1.,1.,1.));
    // lines.at[1] = line(opticalComponents.at[0].concaveLens.box.center + opticalComponents.at[0].concaveLens.properties.thickness * vec3(1.,1.,1.), opticalComponents.at[1].convexLens.properties.coordinate + opticalComponents.at[1].convexLens.properties.thickness * vec3(0.,1.,1.));
    // lines.at[2] = line(opticalComponents.at[1].convexLens.properties.coordinate + opticalComponents.at[1].convexLens.properties.thickness * vec3(0.,1.,1.), vec3(1.,0.,-5.));
    // lines.at[2] = Line(vec3(1.,-2.,-3.), vec3(-1.,0.,-5.), vec3(1.,1.,1.));
    // lines.size = 3;
}

// float rand() { 
//       const vec2 r = vec2(
//     23.1406926327792690,  // e^pi (Gelfond's constant)
//      2.6651441426902251); // 2^sqrt(2) (Gelfond–Schneider constant)
//   return fract( cos( mod( 123456789., 1e-7 + 256. * dot(vec2(3.,4.),r) ) ) );  

// }
float rand(float seed) {
    float value = fract(sin(seed) * 43758.5453123);
    return value;
}

float randInRange(float min, float max, float seed) {
    vec2 cellularResult = cellular(vec3(seed, seed + 1., seed + 2.));
    float randomValue = mix(cellularResult.x, cellularResult.y, 0.5); // Use the average of F1 and F2
    float scaledValue = mix(min, max, randomValue);
    return scaledValue;
}

void initializeOpticalComponents() {
    float radius = .6;

    // concave lens
    OpticalComponent concaveLensComponent = createConcaveLens(vec3(-2.,0.,-5.), radius + uSizeOffset1);

    // convex lens
    OpticalComponent convexLensComponent = createConvexLens(vec3(1.,0.,-5.), radius + uSizeOffset2);

    opticalComponents.at[0] = convexLensComponent;
    opticalComponents.at[1] = concaveLensComponent;

    if (uBackgroundLenses == 0.) {
        opticalComponents.size = 2;
        return;
    }

    // add a bunch of lenses in the background with a z value of above -10. and a x and y value being randomly between -4 and 4
    for (int i = 2; i < OPTICAL_COMPONENTS_SIZE; i++) {
        float x = randInRange(-4., 4., float(i));
        float y = randInRange(-4., 4., float(i) + 2./5.);
        float z = -10.; 
        OpticalComponent component; 
        if (randInRange(0., 1., float(i) + 2.) > 0.5) {
            component = createConvexLens(vec3(x,y,z), radius);
        } else {
            component = createConcaveLens(vec3(x,y,z), radius);
        }
        opticalComponents.at[i] = component;
    }

    opticalComponents.size = OPTICAL_COMPONENTS_SIZE;
}

void initialize(inout vec3 color, inout vec3 cameraOrigin, inout vec3 cameraDir) {
    color = vec3(0.0, 0.0, 0.0);
    color = bgColor;
    cameraOrigin = uCamera;
    cameraDir = normalize(vec3(vPos.xy, -uFL));
    cameraDir *= rotateY(-uCameraDirection.x);
    cameraDir *= rotateX(-uCameraDirection.y);

    // initialize the optical components and lines
    // order matters here
    initializeOpticalComponents();
    initializeLines();
}

void main(void) {
    // initialize camera ray and color 
    vec3 color, cameraOrigin, cameraDir; initialize(color, cameraOrigin, cameraDir);

    RayMarchHit rayMarchHit = rayMarch(cameraOrigin, cameraDir);
    float dstToScene = rayMarchHit.distance;
    if (dstToScene < MAX_DIST) {
        vec3 intersectionPoint = cameraOrigin + cameraDir * dstToScene;
        color = getColor(intersectionPoint) * rayMarchHit.colorOfObject;
    }

    gl_FragColor = vec4(color, 1.0);
}
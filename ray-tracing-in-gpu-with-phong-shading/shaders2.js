let MAX_SPHERES = 15;

let vertexShader2 = `
   attribute vec3 aPos;
   varying   vec3 vPos;
   void main() {
      gl_Position = vec4(aPos, 1.0);
      vPos = aPos;
   }
`;
let fragmentShader2 = `
   int hitSphereIndex = -1;
   precision mediump float;

   uniform float uTime, uFL;
   uniform vec3  uCursor;
   
   // uC are the colors of the spheres and uS are the spheres themselves
   uniform vec3  uC[`+MAX_SPHERES+`];
   uniform vec4  uS[`+MAX_SPHERES+`];

   uniform float uSmoothness;

   varying vec3  vPos;

    // peach
    vec3 color = vec3(1.,.5,.5);

    #define MAX_STEPS 100
    #define MAX_DIST 100.
    #define MIN_DIST 0.01

    // debug function to make pixel white
    void debugTrue() {
        gl_FragColor = vec4(sqrt(vec3(1.,1.,1.)), 1.);
    }

    vec3 shadedColor(vec3 N, vec3 L, vec3 color) {
        return color * (vec3(.02,.02,.1) + vec3( .9 * max(0., dot(N, L)) ));
    }

        // to shade you use Lambertian/Diffuse shading
    // which uses the point of the sphere, with it's normal, and the ambient light
    vec3 shadeSphere(vec4 S, vec3 P, vec3 L, vec3 color) {
        vec3 C = S.xyz;
        float r = S.w;

        vec3 N = (P - C) / r;
        return shadedColor(N, L, color);
    }

    float raySphereExit(vec3 V, vec3 W, vec4 S) {
        V -= S.xyz;
        float b = dot(V,W);
        float c = dot(V,V) - S.w*S.w;
        float d = b*b - c;
        return d > 0. ? -b + sqrt(d) : -1.;
    }

    vec3 refractRay(vec3 W, vec3 N, float n) {
        vec3 Wv = N * dot(W, N);
        vec3 Wu = (W - Wv) / n;
        return Wu + normalize(Wv) * sqrt(1. - dot(Wu,Wu));
    }


    // the distance function for a sphere
    float sdfSphere(vec4 S, vec3 P) {
       vec3 C = S.xyz;
       float r = S.w;
       return length(P - C) - r;
    }

    float sdfScene(vec3 p) {
        float d = 1000000.;
        for (int i = 0; i < `+MAX_SPHERES+`; i++) {
            d = min(d, sdfSphere(uS[i], p));
        }
        return d;
    }

    vec3 calculate_normal(in vec3 p) {
        const vec3 small_step = vec3(0.001, 0.0, 0.0);

        float gradient_x = sdfScene(p + small_step.xyy) - sdfScene(p - small_step.xyy);
        float gradient_y = sdfScene(p + small_step.yxy) - sdfScene(p - small_step.yxy);
        float gradient_z = sdfScene(p + small_step.yyx) - sdfScene(p - small_step.yyx);

        vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

        return normalize(normal);
    }


    // get dist 
    float getDist2(vec3 P, vec3 L, vec3 W, vec3 V, float prevDist) {
       float dist = 1000000.;
       for (int i = 0; i < `+MAX_SPHERES+`; i++) {
            dist = min(dist, sdfSphere(uS[i], P)); 
            if (dist < MIN_DIST) {
                vec3 actualPoint = (prevDist + dist) * W + V;  
                color = shadeSphere(uS[i], actualPoint, L, uC[i]);
                gl_FragColor = vec4(sqrt(color), 1.);
                break; 
            }
       }
       return dist;
    }

    float smoothIntersection(float d1, float d2, float k) {
        float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0., 1.);
        return mix(d2, d1, h) - k * h * (1. - h);
    }

    float getUnionDist(vec3 P, vec3 L, vec3 W, vec3 V, float prevDist) {
        float distA = 1000000.;
        float distB = 1000000.;
        distB = sdfSphere(uS[`+MAX_SPHERES+`-1], P);
        hitSphereIndex = `+MAX_SPHERES+` - 1;

        for (int i = 0; i < `+MAX_SPHERES+` - 1; i++) {
                // added  
                // ends
                distA = min(distA, sdfSphere(uS[i], P));
                if (smoothIntersection(distA, distB, uSmoothness) < MIN_DIST) {
                    // color it to be the color of the sphere but with a tint of yellow 
                    // and make it fade out as it gets closer to the sphere
                    vec3 actualPoint = (prevDist + distA) * W + V;

                    // the normal is the mix of both normals and the h 
                    float h = clamp(0.5 + 0.5 * (distA - distB) / uSmoothness, 0., 1.);
                    vec3 n1 = (actualPoint - uS[i].xyz) / uS[i].w;
                    vec3 n2 = (actualPoint - uS[`+MAX_SPHERES+`-1].xyz) / uS[`+MAX_SPHERES+`-1].w;
                    vec3 normal = mix(n1, n2, h);
                    vec3 rawColor = mix(uC[i], uC[`+MAX_SPHERES+`-1], h);
                    color = shadedColor(normal, L, rawColor);
                    // color = uC[i];

                    gl_FragColor = vec4(sqrt(color), 1.);
                    break; 
                }
        }
        return min(distA, distB);
    }

    // ray marching 
    float rayMarchUnion(vec3 L, vec3 W, vec3 V) {
         float dist = 0.;
         for (int i = 0; i < MAX_STEPS; i++) {
             vec3 P = V + dist * W;
             float dS = getUnionDist(P, L, W, V, dist);
             dist += dS;
             if (dS < MIN_DIST || dist > MAX_DIST) break;
         }

         return dist;
    }

    float rayMarchOrdinary(vec3 L, vec3 W, vec3 V) {
         float dist = 0.;
         for (int i = 0; i < MAX_STEPS; i++) {
             vec3 P = V + dist * W;
             float dS = getDist2(P, L, W, V, dist);
             dist += dS;
             if (dS < MIN_DIST || dist > MAX_DIST) break;
         }

         return dist;
    }

   

   void main(void) {
        vec3 bgColor = vec3(0.05, 0.05, 0.08);
        color = bgColor;
        // debugTrue();
        vec3 L = normalize(vec3(1.,1.,1.));

        // rotate L over time along the y axis
        L = mat3(
            cos(uTime), 0., sin(uTime),
            0., 1., 0.,
            -sin(uTime), 0., cos(uTime)
        ) * L;
        vec3 V = vec3(0.,0.,uFL);
        vec3 W = normalize(vec3(vPos.xy,-uFL));
        float dist = rayMarchUnion(L, W, V);
        
        gl_FragColor = vec4(sqrt(color), 1.);

        // rayMarchOrdinary(L, W, V);
   }
`;
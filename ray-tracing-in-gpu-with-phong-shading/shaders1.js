
let NLIGHTS  = 2;
let NSPHERES = 80;
let vertexShader1 = `
           attribute vec3 aPos;
           varying   vec3 vPos;
           void main() {
              gl_Position = vec4(aPos, 1.0);
              vPos = aPos;
           }
        `;
        let fragmentShader1 = `
           precision mediump float;
        
           uniform float uTime, uFL;
           uniform vec3  uCursor;
           uniform vec3  uLC[`+NLIGHTS+`];
           uniform vec3  uLD[`+NLIGHTS+`];
           uniform vec4  uSphere[`+NSPHERES+`];
           uniform vec3  uAmbient[`+NSPHERES+`];
           uniform vec3  uDiffuse[`+NSPHERES+`];
           uniform vec4  uSpecular[`+NSPHERES+`];
        
           varying vec3  vPos;
        
           float raySphere(vec3 V, vec3 W, vec4 S) {
              V -= S.xyz;
              float b = dot(V,W);
              float c = dot(V,V) - S.w*S.w;
              float d = b*b - c;
              return d > 0. ? -b - sqrt(d) : -1.;
           }
        
           float raySphereExit(vec3 V, vec3 W, vec4 S) {
              V -= S.xyz;
              float b = dot(V,W);
              float c = dot(V,V) - S.w*S.w;
              float d = b*b - c;
              return d > 0. ? -b + sqrt(d) : -1.;
           }
        
           vec3 shadeSurface(vec3 P, vec3 N, vec3 ambient, vec3 diffuse, vec4 specular, vec3 W) {
              // AMBIENT
              vec3 color = ambient;
        
              for (int l = 0 ; l < `+NLIGHTS+` ; l++) {
        
        
                 float t = -1.;
                 
                 // SHADOWS
                  float epsilon = 0.001;
                  // shoot a ray to each light, if it hits something, then the light is blocked
                  for (int n = 0 ; n < `+NSPHERES+` ; n++)
                     // why do we trace from some point to uLD[l]? 
                     // what is uLD[l]? It is the direction of the light
                     // so we are tracing from the point to the light, and seeing if it hits sphere n
                     // recall ray sphere has V and W, V is the origin, W is the direction
                     // here, V is the point, and W is the direction of the light
                     t = max(t, raySphere(P + epsilon, uLD[l], uSphere[n]));


                 if (t < 0.) { // if the light is not blocked
        
                    // DIFFUSE AND SPECULAR
        
                    // reflection vector 
                    vec3 R = 2. * dot(uLD[l], N) * N - uLD[l];

                    // diffuse vector -- which is really just how much the light is aligned with the normal
                    color += diffuse * max(0., dot(N, uLD[l])) * uLC[l];

                    // specular vector -- which is really just how much the reflection is aligned with the view
                    color += specular.rgb * pow(max(0.,dot(R,-W)),specular.a) * uLC[l];
                 }
              }
        
              return color;
           }
        
           vec3 refractRay(vec3 W, vec3 N, float n) {
              vec3 Wv = N * dot(W, N);
              vec3 Wu = (W - Wv) / n;
              return Wu + normalize(Wv) * sqrt(1. - dot(Wu,Wu));
           }
        
           vec3 bgColor = vec3(0.,0.,.05);
        
           void main(void) {
        
              // SET BACKGROUND COLOR
        
              vec3 color = bgColor;
        
              // FORM THE RAY FOR THIS PIXEL
        
              vec3 V = vec3(0.,0.,uFL);
              vec3 W = normalize(vec3(vPos.xy,-uFL));
        
              // RAY TRACE TO EACH SPHERE, CHOOSING THE NEAREST ONE
        
              float tMin = 1000.;
              for (int n = 0 ; n < `+NSPHERES+` ; n++) {
                 float t = raySphere(V, W, uSphere[n]);
                 if (t > 0. && t < tMin) {
                    tMin = t;
                    vec3 P = V + t * W;
                    vec3 N = normalize(P - uSphere[n].xyz);
                    color = shadeSurface(P, N, uAmbient[n],
                                               uDiffuse[n],
                                               uSpecular[n], W);
        
                  //   // REFRACTION
        
                    float ior = 2.5;
                    vec3  Win  = refractRay(W, N, ior);
                    float tout = raySphereExit(P, Win, uSphere[n]);
                    vec3  Pout = P + tout * Win;
                    vec3  Nout = normalize(Pout - uSphere[n].xyz);
                    vec3  Wout = refractRay(Win, Nout, 1./ior);
        
                  //   vec3 Cg = bgColor; // GLASS COLOR
                    vec3 Cg = color; // GLASS COLOR 
                    float tgMin = 1000.;
                    for (int j = 0 ; j < `+NSPHERES+` ; j++) {
                       float t = raySphere(Pout, Wout, uSphere[j]);
                       if (t > 0. && t < tgMin) {
                          tgMin = t;
                          vec3 P = Pout + t * Wout;
                          vec3 N = normalize(P - uSphere[j].xyz);
                          Cg = shadeSurface(P, N, uAmbient[j],
                                                  uDiffuse[j],
                                                  uSpecular[j], Wout);
                       }
                    }
                    color = mix(color, Cg, .9);
        
                  //   // REFLECTION
                    vec3 Cm = bgColor; // MIRROR COLOR
                    vec3 Wm = 2. * dot(-W, N) * N + W; // direction of the ray going into the mirror
                    vec3 Vprime = P + 0.001 * Wm; // start the ray a little bit away from the surface
                    float tjMin = 1000.;
                    for (int j = 0 ; j < `+NSPHERES+` ; j++) {
                       float tj = raySphere(Vprime, Wm, uSphere[j]);
                       if (tj > 0. && tj < tjMin) {
                          tjMin = tj;
                          vec3 Pj = P + tj * Wm;
                          vec3 Nj = normalize(Pj - uSphere[j].xyz);
                        //   Cm = shadeSurface(Pj, Nj, uAmbient[j],
                        //                             uDiffuse[j],
                        //                             uSpecular[j], Wm);
                       }
                    }
                    //color = mix(color, Cm , .5);//* uSpecular[n].rgb, .5);

                    // why do we have to muliptly by uSpecular[n]
                    color = mix(color, Cm * uSpecular[n].rgb, .5);
                 }
              }
        
              gl_FragColor = vec4(sqrt(color), 1.);
           }
        `;
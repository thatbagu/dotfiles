const uint antiA = 3u; //raise or lower this

// Catppuccin Mocha colors (converted to 0-1 range)
const vec3 mocha_base     = vec3(30, 30, 46) / 255.0;      // #1e1e2e
const vec3 mocha_mantle   = vec3(24, 24, 37) / 255.0;      // #181825  
const vec3 mocha_crust    = vec3(17, 17, 27) / 255.0;      // #11111b
const vec3 mocha_text     = vec3(205, 214, 244) / 255.0;   // #cdd6f4
const vec3 mocha_subtext1 = vec3(186, 194, 222) / 255.0;   // #bac2de
const vec3 mocha_subtext0 = vec3(166, 173, 200) / 255.0;   // #a6adc8
const vec3 mocha_overlay2 = vec3(147, 153, 178) / 255.0;   // #9399b2
const vec3 mocha_overlay1 = vec3(127, 132, 156) / 255.0;   // #7f849c
const vec3 mocha_overlay0 = vec3(108, 112, 134) / 255.0;   // #6c7086
const vec3 mocha_surface2 = vec3(88, 91, 112) / 255.0;     // #585b70
const vec3 mocha_surface1 = vec3(69, 71, 90) / 255.0;      // #45475a
const vec3 mocha_surface0 = vec3(49, 50, 68) / 255.0;      // #313244

// Catppuccin Mocha accent colors
const vec3 mocha_rosewater = vec3(245, 224, 220) / 255.0;  // #f5e0dc
const vec3 mocha_flamingo  = vec3(242, 205, 205) / 255.0;  // #f2cdcd
const vec3 mocha_pink      = vec3(245, 194, 231) / 255.0;  // #f5c2e7
const vec3 mocha_mauve     = vec3(203, 166, 247) / 255.0;  // #cba6f7
const vec3 mocha_red       = vec3(243, 139, 168) / 255.0;  // #f38ba8
const vec3 mocha_maroon    = vec3(235, 160, 172) / 255.0;  // #eba0ac
const vec3 mocha_peach     = vec3(250, 179, 135) / 255.0;  // #fab387
const vec3 mocha_yellow    = vec3(249, 226, 175) / 255.0;  // #f9e2af
const vec3 mocha_green     = vec3(166, 227, 161) / 255.0;  // #a6e3a1
const vec3 mocha_teal      = vec3(148, 226, 213) / 255.0;  // #94e2d5
const vec3 mocha_sky       = vec3(137, 220, 235) / 255.0;  // #89dceb
const vec3 mocha_sapphire  = vec3(116, 199, 236) / 255.0;  // #74c7ec
const vec3 mocha_blue      = vec3(137, 180, 250) / 255.0;  // #89b4fa
const vec3 mocha_lavender  = vec3(180, 190, 254) / 255.0;  // #b4befe

// Array of background colors (darker tones)
const vec3 bgColors[4] = vec3[4](mocha_base, mocha_mantle, mocha_crust, mocha_surface0);

// Array of accent colors for surfaces
const vec3 sfColors[14] = vec3[14](
    mocha_rosewater, mocha_flamingo, mocha_pink, mocha_mauve, 
    mocha_red, mocha_maroon, mocha_peach, mocha_yellow,
    mocha_green, mocha_teal, mocha_sky, mocha_sapphire,
    mocha_blue, mocha_lavender
);

const float err = 1e10;
mat3  fA, cA, fA2, cA2;
vec3  fB, cB, fB2, cB2;
float fC, cC, fC2, cC2;

vec3 bgCol, bgCol2;
vec3 sfCol, sfCol2;

vec3 hash3(uint n) 
{
    //https://www.shadertoy.com/view/llGSzw
	n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    uvec3 k = n * uvec3(n,n*16807U,n*48271U);
    return vec3( k & uvec3(0x7fffffffU))/float(0x7fffffff);
}

mat2x3 boxM(uint n) {
    vec3 U = hash3(n), V = hash3(n + 2568758767u);
    U = sqrt(-2.*log(U));
    V *= 2.*3.14159265;
    return mat2x3(U*cos(V), U*sin(V));
}

vec3 pal(float t, mat4x3 a) {
    //https://www.shadertoy.com/view/ll2GD3
    return a[0] + a[1]*cos(2.*3.14159265*(a[2]*t+a[3]));
}

vec3 getCatppuccinBg(uint seed) {
    return bgColors[seed % 4u];
}

vec3 getCatppuccinSf(uint seed) {
    return sfColors[seed % 14u];
}

void setParams(uint n, out mat3 outFA, out mat3 outCA, out vec3 outFB, out vec3 outCB, 
               out float outFC, out float outCC, out vec3 outBgCol, out vec3 outSfCol) {
    n *= 100u;
    for (uint i = 0u; i < 3u; ++i) {
        mat2x3 tmp = boxM(n++);
        outFA[i] = tmp[0];
        outCA[i] = tmp[1];
        outFA[i][i] /= sqrt(2.);
        outCA[i][i] /= sqrt(2.);
    }

    outFB = 2.*(hash3(n++) - 1.);
    outCB = 2.*(hash3(n++) - 1.);
    outFA *= .3;
    
    outCB *= .3;
    outCA *= .2;
    outCC = 0.;
    outFC = 0.;
    
    outBgCol = getCatppuccinBg(n);
    outSfCol = getCatppuccinSf(n + 7u); // Offset for variety
}

void set(uint n, float blend) {
    // Get parameters for current and next state
    setParams(n, fA, cA, fB, cB, fC, cC, bgCol, sfCol);
    setParams(n + 1u, fA2, cA2, fB2, cB2, fC2, cC2, bgCol2, sfCol2);
    
    // Create a longer hold period - only transition in the last 50% of the cycle
    float transitionStart = 0.05; // Start transitioning at 50% through the cycle
    float t = 0.0;
    if (blend > transitionStart) {
        // Map the last 50% to 0-1 for smooth transition
        t = (blend - transitionStart) / (1.0 - transitionStart);
        // Apply slower easing - much gentler curve
        t = t * t * t * (t * (t * 6.0 - 15.0) + 10.0); // smootherstep
    }
    
    // Interpolate all parameters (matrices need component-wise mixing)
    for(int i = 0; i < 3; i++) {
        fA[i] = mix(fA[i], fA2[i], t);
        cA[i] = mix(cA[i], cA2[i], t);
    }
    fB = mix(fB, fB2, t);
    cB = mix(cB, cB2, t);
    fC = mix(fC, fC2, t);
    cC = mix(cC, cC2, t);
    bgCol = mix(bgCol, bgCol2, t);
    sfCol = mix(sfCol, sfCol2, t);
}

float eval(vec3 x, mat3 A, vec3 B, float C) {
    return dot(x, A*x) + dot(B, x) + C;
}

vec3 grad(vec3 x, mat3 A, vec3 B) {
    return B + A*x + x*A;
}

vec3 param(vec3 x, vec3 d, mat3 A, vec3 B, float C) {
    return vec3(eval(x,A,B,C), dot(grad(x,A,B), d), dot(d, A*d));
}

float func(vec3 x) {
    return eval(x, fA, fB, fC);
}

float cond(vec3 x) { 
    return eval(x, cA, cB, cC);
}

vec3 funcGrad(vec3 x) {
    return grad(x, fA, fB);
}

vec3 condGrad(vec3 x) {
   return grad(x, cA, cB);
}

vec2 solve(vec3 p) {
    float a = p.z, b = p.y, c = p.x;
    float disc = b*b - 4.*a*c;

    if (disc < 0.) return vec2(err);
    
    vec2 tmp;
    
    if (false && abs(a) < 1e-6 )
        tmp = vec2(-c/b, err);
    else if (false && abs(c) < 1e-6)
        tmp = vec2(0., -a/b);
    else {
        tmp.x = (-b - sign(b)*sqrt(disc))/2./a;
        tmp.y = c/a/tmp.x;
    }
    if (tmp.y < tmp.x) tmp = tmp.yx;
    if (tmp.x < 0.)    tmp = vec2(tmp.y, err);
    if (tmp.x < 0.)    tmp = vec2(err);
    return tmp;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    const float duration = 50., speed = 0.2;
    
    // Calculate current state and blend factor
    float timeInCycle = mod(iTime, duration);
    uint currentSeed = uint(iTime / duration) + uint(iRandom * 1000.0);
    float blendFactor = timeInCycle / duration;
    
    set(currentSeed, blendFactor);
    fC -= iTime * speed;
    
    const float delta = 1.5, focal = 1.3;
    
    vec2 uv = (2.*fragCoord - iResolution.xy) / iResolution.y;
    float pixel = 1./iResolution.y;
    
    vec3 ro = vec3(0., 0., 4.);
    
    vec3 colTot = vec3(0.);
    
    for (uint nAA = 0u; nAA < antiA*antiA; ++nAA) {
        const float aaStep = 1./float(antiA);
        vec2 uv1 = vec2(nAA/antiA, nAA%antiA)*aaStep + .5*aaStep;
        uv1 = (uv1 - .5) * 2.*pixel;
        vec3 rd = normalize(vec3(uv+uv1, -focal));
        
        vec3 fPar = param(ro, rd, fA, fB, fC);
        vec3 cPar = param(ro, rd, cA, cB, cC);
        vec2 cIsect = solve(cPar);
        
        vec3 col;
        
        if (cIsect.x < err) {
            float hit = func(ro+rd*cIsect.x);
            vec2 pot = delta * (floor(hit / delta) + vec2(0., 1.));
            vec4 fIsect = vec4(solve(fPar-vec3(pot.x,0.,0.)), solve(fPar-vec3(pot.y,0.,0.)));

            float t = err;
            for (int i = 0; i < 4; ++i) {
                if (fIsect[i] < min(t, cIsect.y) && fIsect[i] > cIsect.x)
                    t = fIsect[i];
            }

            vec3 pos = ro + t*rd;
            vec3 fGrad = funcGrad(pos)/delta;
            vec3 cGrad = condGrad(pos)/abs(cond(pos));
            
            float occ = length(fGrad) / length(cGrad);
            occ = sqrt(occ);
            occ = 1. - occ/sqrt(1. + occ*occ);
            occ = sqrt(occ);
            
            col = t < err ? sfCol * occ : bgCol;
            col = mix(col, sfCol, smoothstep(-2.*pixel, -pixel, -1./cIsect.x));
        }
        else
            col = bgCol;
        colTot += col;
    }
    colTot /= float(antiA*antiA);

    colTot = pow(colTot, vec3(1./2.2));
    fragColor = vec4(colTot,1.0);
}


// Catppuccin Mocha adaptation for personal wallpaper use.

#define getNormal getNormalHex
#define raymarch enchancedRayMarcher

#define FAR 570.
#define INFINITY 1e32
#define FOG 1.
#define PI  3.14159265
#define TAU (2.*PI)
#define PHI 1.618033988749895

// Faster hash — no sin(), just multiplies
float hash12(vec2 p) {
    p = fract(p * vec2(0.1031, 0.1030));
    p += dot(p, p.yx + 33.33);
    return fract((p.x + p.y) * p.x);
}

float noise_3(in vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f*f*(3.0-2.0*f);

    vec2 ii = i.xy + i.z * vec2(5.0);
    float v1 = mix(mix(hash12(ii),           hash12(ii+vec2(1,0)), u.x),
                   mix(hash12(ii+vec2(0,1)), hash12(ii+vec2(1,1)), u.x), u.y);
    ii += vec2(5.0);
    float v2 = mix(mix(hash12(ii),           hash12(ii+vec2(1,0)), u.x),
                   mix(hash12(ii+vec2(0,1)), hash12(ii+vec2(1,1)), u.x), u.y);
    return max(mix(v1, v2, u.z), 0.0);
}

// 4 octaves instead of 7 — big win since fbm is called 94+ times per pixel
float fbm(vec3 x) {
    float r = 0.0, w = 1.0, s = 1.0;
    for (int i = 0; i < 4; i++) {
        w *= 0.5; s *= 2.0;
        r += w * noise_3(s * x);
    }
    return r;
}

// Catppuccin Mocha cycling palette
// PHI*TAU offset (~10.17 rad) seeds a non-zero starting color each launch feels "random"
vec3 mochaColor(float speed, vec3 center, vec3 amp, vec3 phase) {
    float ct = iTime * speed + PHI * TAU;
    return center + amp * cos(ct + phase);
}

vec3 surfaceColor() {
    // cycles Mauve → Lavender → Blue → Sapphire → Teal → back, ~180s period
    return mochaColor(0.035,
        vec3(0.62, 0.58, 0.88),
        vec3(0.18, 0.14, 0.09),
        vec3(0.00, 2.09, 4.19));
}

vec3 lightColor() {
    // offset phase so light and surface never match
    return normalize(mochaColor(0.025,
        vec3(0.70, 0.62, 0.96),
        vec3(0.22, 0.18, 0.10),
        vec3(4.19, 0.00, 2.09)));
}

vec3 saturate(vec3 a)  { return clamp(a, 0.0, 1.0); }
float saturate(float a){ return clamp(a, 0.0, 1.0); }

float smin(float a, float b, float k) {
    float res = exp(-k*a) + exp(-k*b);
    return -log(res)/k;
}

struct geometry {
    float dist;
    float specular;
    float diffuse;
    vec3  color;
};

geometry scene(vec3 p) {
    geometry g;
    float localNoise = fbm(p / 10.) * 2.;
    p.y -= localNoise * .2;
    g.dist = p.y;
    p.y *= 3.5;
    g.dist = smin(g.dist, length(p) - 25., .15 + localNoise * .2);
    g.dist = max(g.dist, -length(p) + 29. + localNoise);
    g.color   = surfaceColor();
    g.diffuse  = 0.;
    g.specular = 22.1;
    return g;
}

const int MAX_ITER = 55;

geometry enchancedRayMarcher(vec3 o, vec3 d, int maxI) {
    geometry mp;
    float tb = (2.1 - o.y) / d.y;
    if (tb < 0.0) { mp.dist = INFINITY; return mp; }

    float t_min  = tb;
    float omega  = 1.3;
    float t      = t_min;
    float candErr= INFINITY, candT = t_min;
    float prevR  = 0., stepL = 0.;
    float pxR    = 1. / 350.;
    // camera is always outside the scene, so functionSign = +1

    for (int i = 0; i < MAX_ITER; ++i) {
        mp = scene(d * t + o);
        float sr = mp.dist;
        float r  = abs(sr);
        bool fail = omega > 1. && (r + prevR) < stepL;
        if (fail) { stepL -= omega * stepL; omega = 1.; }
        else        stepL  = sr * omega * .8;
        prevR = r;
        float err = r / t;
        if (!fail && err < candErr) { candT = t; candErr = err; }
        if (!fail && err < pxR || t > FAR) break;
        t += stepL;
    }

    mp.dist = candT;
    if (t > FAR || candErr > pxR) mp.dist = INFINITY;
    return mp;
}

#define EPSILON .001
vec3 getNormalHex(vec3 pos) {
    float d = scene(pos).dist;
    return normalize(vec3(
        scene(pos + vec3(EPSILON,0,0)).dist - d,
        scene(pos + vec3(0,EPSILON,0)).dist - d,
        scene(pos + vec3(0,0,EPSILON)).dist - d));
}

float getAO(vec3 hitp, vec3 normal, float dist) {
    return clamp(scene(hitp + normal * dist).dist / dist, 0.4, 1.0);
}

vec3 Sky(in vec3 rd, vec3 ldir) {
    vec3  lc        = lightColor();
    float sunAmount = max(dot(rd, ldir), .1);
    float v         = pow(1.2 - max(rd.y, .5), 1.1);
    // horizon: Mocha Blue, zenith: Crust
    vec3 sky = mix(vec3(0.537, 0.706, 0.980), vec3(0.067, 0.067, 0.106), v);
    sky += lc * sunAmount * sunAmount + lc * min(pow(sunAmount, 1e4), 1233.);
    return clamp(sky, 0.0, 1.0);
}

vec3 doColor(in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, geometry obj) {
    vec3  ld    = lp - sp;
    float lDist = max(length(ld / 2.), 0.001);
    ld /= lDist;
    float diff  = max(dot(sn, ld), obj.diffuse);
    float spec  = max(dot(reflect(-ld, sn), -rd), obj.specular / 2.);
    return obj.color * (diff + .15) * spec * 0.1;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy - .5;
    uv.y *= 1.2;

    float t2 = iTime;
    float sk = sin(-t2 * .1) * 48.0;
    float ck = cos(-t2 * .1) * 48.0;

    vec3 light = vec3(0., 7., 100.);

    vec3 ro  = vec3(ck, 18., sk);
    vec3 vrp = vec3(0.);
    vec3 vpn = normalize(vrp - ro);
    vec3 u   = normalize(cross(vec3(0,1,0), vpn));
    vec3 v   = cross(vpn, u);
    vec3 rd  = normalize((ro + vpn) + uv.x*u*iResolution.x/iResolution.y + uv.y*v - ro);

    geometry tr = raymarch(ro, rd, 0);

    vec3 hit = ro + rd * tr.dist;
    vec3 sn  = getNormal(hit);
    float ao = getAO(hit, sn, 10.2);

    vec3 lc  = lightColor();
    vec3 sky = Sky(rd, normalize(light));

    vec3 sceneColor;
    if (tr.dist < FAR) {
        sceneColor  = doColor(hit, rd, sn, light, tr);
        sceneColor *= ao;
        sceneColor  = mix(sceneColor, sky, saturate(tr.dist * 4.5 / FAR));
    } else {
        sceneColor = sky;
    }

    fragColor = pow(vec4(clamp(sceneColor * (1. - length(uv)/3.5), 0., 1.), 1.), vec4(1./1.2));
}

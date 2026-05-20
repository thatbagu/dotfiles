// Copyright Inigo Quilez, 2022 - https://iquilezles.org/
// I am the sole copyright owner of this Work. You cannot
// host, display, distribute or share this Work neither as
// is or altered, in any form including physical and
// digital. You cannot use this Work in any commercial or
// non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it. You
// cannot use this Work to train AI models. I share this
// Work for educational purposes, you can link to it as
// an URL, proper attribution and unmodified screenshot,
// as part of your educational material. If these
// conditions are too restrictive please contact me.

// Catppuccin Mocha color theme adaptation for personal wallpaper use.
// Original: https://www.shadertoy.com/view/7l2GzR

// https://iquilezles.org/articles/intersectors/
vec2 sphIntersect( in vec3 ro, in vec3 rd, float ra )
{
    float b = dot( ro, rd );
    float c = dot( ro, ro ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b-h,-b+h);
}

// https://iquilezles.org/articles/smin/
vec4 smin( vec4 a, vec4 b, float k )
{
    float h = max( k-abs(a.x-b.x), 0.0 )/k;
    float m = h*h*0.5;
    float s = m*k*0.5;
    vec2 r = (a.x<b.x) ? vec2(a.x,m) : vec2(b.x,1.0-m);
    return vec4(r.x-s, mix( a.yzw, b.yzw, r.y ) );
}

// https://iquilezles.org/articles/functions/
float sabs( float x, float k )
{
    return sqrt(x*x+k);
}

vec2 rot( vec2 p, float a )
{
    float co = cos(a);
    float si = sin(a);
    return mat2(co,-si,si,co) * p;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(0.0, cos(cr),sin(cr));
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

//======================================================================
// creature
//======================================================================

vec4 map( in vec3 p, float time )
{
    float d1 = 0.10*sin(-time*6.283185/8.0 +  3.0*p.y);
    float d2 = 0.05*sin( time*10.0         + 60.0*p.y);

    // slowly cycle through catppuccin mocha accent colors
    // base: dark mauve/purple/blue cycling ~every 80s
    // tip:  lavender/sapphire/teal/pink cycling offset
    float ct = iTime * 0.04;
    vec3 bodyBase = vec3(0.22, 0.16, 0.34) + 0.06*cos(ct         + vec3(0.0, 2.1, 4.2));
    vec3 bodyTip  = vec3(0.60, 0.72, 0.96) + 0.14*cos(ct * 0.8   + vec3(4.2, 0.0, 2.1));

    vec4 dcol = vec4(1e20,0.0,0.0,0.0);
    float sc = 1.0;
    for( int i=0; i<12; i++ )
    {
        p.xz = rot(p.xz, 17.0*sc + d1*smoothstep( 5.0, 1.0, float(i)));
        p.yz = rot(p.yz, -1.0*sc + d2*smoothstep( 8.0,11.0, float(i)));

        p.x = sabs(p.x,0.0001*sc) - 0.22*sc;

        float d = (i==11) ? length(p*vec3(1.0,1.0,0.1)) - 0.1*sc
                           : length(p) - 0.1*sc;

        // mid-node uses mocha Text, rest blends bodyBase→bodyTip with a subtle per-point cos tint
        vec3 c = (i==6) ? vec3(0.804, 0.839, 0.957)
                        : mix(bodyBase, bodyTip, float(i)/11.0) + 0.08*cos(vec3(0,1,2) - p*10.0);

        dcol = smin(dcol, vec4(d,c), 0.12*sc);

        sc /= 1.2;
    }

    return dcol;
}

// https://iquilezles.org/articles/nvscene2008/rwwtt.pdf
float calcAO( in vec3 pos, in vec3 nor, in float time )
{
    float occ = 0.0;
    for( int i=0; i<2; i++ )
    {
        float h = 0.01 + 0.4*float(i);
        vec3  w = normalize( nor + normalize(sin(float(i)+vec3(0,2,4))));
        float d = map( pos + h*w, time ).x;
        occ += h-d;
    }
    return clamp( 1.0 - 2.5*occ, 0.0, 1.0 );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos, float dis, in float time )
{
    const vec2 e = vec2(0.001,0.0);
    return normalize( vec3( map( pos + e.xyy, time ).x,
                            map( pos + e.yxy, time ).x,
                            map( pos + e.yyx, time ).x)-dis );
}

//======================================================================
// CITA - Crap In The Air
//======================================================================

vec4 mapCITA( in vec3 pos, in float time )
{
    pos.y += time*0.02;

    const float rep = 1.5;
    vec3 ip = floor(pos/rep);
    vec3 fp = fract(pos/rep);
    vec3 op = vec3( (fp.x<0.0)?-1.0:0.0, (fp.y<0.0)?-1.0:0.0, (fp.z<0.0)?-1.0:0.0 );

    vec4 dr = vec4(1e20);
    for( int i=0; i<2; i++ )
    for( int j=0; j<2; j++ )
    for( int k=0; k<2; k++ )
    {
        vec3 b = vec3( float(i), float(j), float(k) );
        vec3 id = ip + b + op;

        vec3 ra = fract(sin(dot(id,vec3(1,123,1231))+vec3(0,1,2))*vec3(338.5453123,278.1459123,191.1234));
        vec3 o = 0.3*sin(6.283185*time/48.0 + 50.0*ra);
        vec3 r = b - fp + o;

        float d = dot(r,r);
        if( d<dr.x ) dr = vec4(d,r);
    }
    return vec4(sqrt(dr.x)*rep-0.02,dr.yzw);
}

vec4 raycastCITA( in vec3 ro, in vec3 rd, in float px, in float tmax, in float time )
{
    float t = 0.0;
    vec3 res = vec3(0.0);
    for( int i=0; i<64; i++ )
    {
        vec3 pos = ro + t*rd;
        vec4 h = mapCITA( pos, time );
        res = h.yzw;
        if( h.x<0.0005*px*t || t>tmax ) break;
        t += h.x;
    }
    return (t<tmax) ? vec4(t,res) : vec4(-1.0);
}

//======================================================================
// rendering
//======================================================================

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    float time = mod( iTime, 48.0 );

    // smooth orbit: ~35s per revolution, slow vertical drift
    float orbit = iTime * 0.18;
    float camY  = 0.25 + 0.20*sin(iTime * 0.07);
    vec3  ta = 0.05*sin( 6.283185*time/24.0+vec3(0,2,4) );
    vec3  ro = ta + 1.85*vec3( cos(orbit), camY, sin(orbit) );
    float fl = 2.5;

    mat3 ca = setCamera( ro, ta, 0.05 );
    vec3 rd = normalize( ca*vec3(p,fl) );

    // Catppuccin Mocha Crust #11111b as deep background
    vec3 back = vec3(0.067, 0.067, 0.106)*(1.0-clamp(-1.25*rd.y,0.0,1.0));

    float ft = -1.0;
    vec3 col = back;

    vec2 b = sphIntersect( ro, rd, 1.2 );
    if( b.y>0.0 )
    {
        vec4  sum = vec4(0.0);
        float tmax = b.y;
        float t = max(0.0,b.x);
        for( int i=0; i<64 && t<tmax; i++ )
        {
            vec4  res = map( ro + t*rd, time );
            float dis = res.x;

            float dt = (dis>0.0) ? dis*0.8+0.001 : (-dis+0.002);

            if( dis<0.0 )
            {
                if( ft<0.0 ) ft=t;

                vec3  pos = ro + t*rd;
                vec3  nor = calcNormal( pos, res.x, time );
                float occ = calcAO( pos, nor, time );

                vec4 tmp = vec4(res.yzw*res.yzw,min(20.0*dt,1.0));

                float ll = 15.0*exp2(-2.0*t);
                tmp.rgb *= (0.5+0.5*dot(nor,-rd))*ll*3.0/(1.0+ll);

                float fre = clamp(1.0+dot(nor,rd),0.0,1.0);
                tmp.rgb += fre*fre*(0.5+0.5*tmp.rgb)*0.8;

                // Catppuccin Mocha Base #1e1e2e for occlusion shadow
                tmp.rgb *= 1.6*mix(tmp.rgb*0.1+vec3(0.118,0.118,0.180),vec3(1.0),occ*1.4);

                tmp.rgb *= tmp.a;
                sum += tmp*(1.0-sum.a);
                if( sum.a>0.995 ) break;
            }
            t += dt;
        }

        sum = clamp(sum,0.0,1.0);
        col = col*(1.0-sum.w) + sum.xyz;
    }

    // CITA particles: cycle through mocha lavender/blue/sapphire/teal
    vec4 cita = raycastCITA( ro, rd, 2.0/fl, (ft>0.0) ? ft : 15.0, time );
    if( cita.x>0.0 )
    {
        vec3 citacol = 0.70 + 0.25*cos(iTime*0.05 + vec3(0.0, 2.1, 4.2));
        citacol = mix( back, citacol, exp2(-0.1*cita.x*vec3(4.0,3.5,3.0)/fl) );
        float fre = clamp(dot(normalize(cita.yzw),rd),0.0,1.0);
        col = mix( col, citacol, fre*0.3 );
    }

    // slightly cool gamma to complement the blue/purple palette
    col = pow( col, vec3(0.50, 0.48, 0.45) );

    col *= 1.2 - 0.35*length(p);

    col += fract(sin(fragCoord.x*vec3(13,1,11)+fragCoord.y*vec3(1,7,5))*158.391832)/255.0;

    fragColor = vec4(col, 1);
}

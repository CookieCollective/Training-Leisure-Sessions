#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define PI 3.14159

#define REP(p,r) (mod(p + r/2.,r) - r/2.)

mat2 rot(float a)
{
  float ca = cos(a); float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float idA(vec2 p, float n)
{
  return floor((atan(p.y, p.x)) * n / (2. * PI) );
}

vec2 modA(vec2 p, float n)
{
  float a = atan(p.y, p.x);
  a = mod(a, (2. * PI) / n );

  return vec2(cos(a), sin(a)) * length(p);
}

float map(vec3 p)
{
  float dist = 1000.;

  float time = fGlobalTime + p.z * 2.;

  p.z += fGlobalTime;

  p.z = REP(p.z, 3.);


  vec3 cp = p;

  float n = 8.;

  float aid = idA(p.xy, n);
  float a = atan(p.y, p.x);
  
  a *= 5.;

  vec3 dir = normalize(p);

  p += (dir * sin(a) + cos(a) * vec3(0.,0.,1.)) * .75;

  float tor = length(vec2(length(p.xy) - 4.,p.z)) - .45 * pow((sin(a + time) * .5 + .45), 4.);
  dist = min(dist, tor);

  p = cp;
  tor = length(vec2(length(p.xy) - 4.,p.z)) - .05;

  dist = min(dist, tor);

  return dist;
}

vec3 lookAt(vec3 ro, vec3 rt, vec2 uv)
{
  vec3 fd = normalize(rt - ro);
  vec3 ri = cross(vec3(0.,1.,0.), fd);
  vec3 up = cross(fd, ri);

  return normalize(vec3(fd + ri * uv.x + up * uv.y));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 sub = vec3(0.,0.,0.);
  vec3 rd = lookAt(ro, sub, uv);
  vec3 cp = ro;

  float st = 0.; float cd = 0.;
  for(;st < 1.; st += 1. / 128.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd * .5;
  }

  out_color = vec4(1. - st);
}
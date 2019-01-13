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

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

#define PI 3.1415
#define TAU (2.* PI)
#define PHI (.5 * PI)

#define REP(p, r) (mod(p +r,r*2.) - r)

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(sa,-ca,ca,sa);
}

float map(vec3 p)
{
  p = REP(p, 6.);

  float dist = distance(p,vec3(3.,3.,0.)) - 1.;

  return dist;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = vec3(uv, 1.);
  vec3 cp = ro;

  float time = 0.1 * fGlobalTime;
  rd.xy *=rot(time);
  rd.xz *= rot(sin(time));
  rd.yz *= rot(cos(time));

  float cd;
  float s = 0.;
  for(;s < 1.; s+= 1./128)
  {
    cd = map(cp);
    if(cd < .01) 
    {
      break;
    }
    cp += rd * cd * .15;
  }

  float f = (1. - s) * exp(length(cp - ro)*.015);

  out_color = vec4(f);
}
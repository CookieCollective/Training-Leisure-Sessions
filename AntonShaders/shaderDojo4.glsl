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
#define PHI (PI / 2.)
#define TAU (PI * 2.)

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

vec2 repA(vec2 p, float n)
{
  vec2 np = normalize(p);
  float a = atan(np.y,np.x);
  a += 1.;
  a = mod(a + n /2., n) - n /2.;
  return vec2(cos(a),sin(a)) * length(p);
}

float ease(float f)
{
  float ff = floor(f);
  float fr = f - ff;
  return ff + sin(fr * PI - PHI) *.5 + .5;
}

float multiPlex(float t, float c, float n)
{
  float ff = floor(t);
  float fr = t - ff;
  fr= clamp(0,1, fr * n - c);
  return ff + fr;
}

float id = 0;
float map(vec3 p)
{

  p.xz *= rot(ease(multiPlex(fGlobalTime,0, 2)) );
  p.yz *= rot(ease(multiPlex(fGlobalTime,1, 2)) );
//  p.zy *= rot(fGlobalTime * .33);

  p.xy = repA(p.xy, TAU / 4.);

  float s1 = distance(vec3(3.,0.,0.), p) - 1.;
    if(s1  <.01)
{
  id = 1;
}

return s1;
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.01,.0);

  return normalize(
  vec3(
  map(p + e.xyy) - map(p - e.xyy),
  map(p + e.yxy) - map(p - e.yxy),
  map(p + e.yyx) - map(p - e.yyx)
)
);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = ro;

  float st = 0.;
  float cd;

  for(;st < 1.; st +=1./128.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd * .25;
  }
  
  if(id == 1)
{
  vec3 norm = normal(cp);
  float li = dot(norm, normalize(vec3(-1.,-1.,-1.)));
  out_color = vec4(li);
}
else
{
out_color = vec4(0.);
}
}
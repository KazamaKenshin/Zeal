shader_type canvas_item;

#define iResolution 1.0/SCREEN_PIXEL_SIZE
#define iTime TIME
#define fragColor COLOR

uniform bool TWELVE_HOUR_CLOCK = true;
uniform bool GLOWPULSE = true;
uniform vec3 GLOW_COLOR = vec3(1,0.2,0);
uniform bool SHOW_GRID = true;
uniform float GRID : hint_range(0.0, 1.0, 0.01) = 0.1;

uniform float now_time = 0.;
uniform vec2 DISP = vec2(0.45, 0.5);

uniform float scale1 : hint_range(0.01, 0.3, 0.01) = 0.15;
uniform float scale2 : hint_range(0.05, 3.0, 0.05) = 1.0;





// hash function copy from https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}


float noise(vec2 pos) {
    vec2 i = floor(pos);
    vec2 f = fract(pos);

    float a = hash12(i);
    float b = hash12(i + vec2(1, 0));
    float c = hash12(i + vec2(0, 1));
    float d = hash12(i + vec2(1, 1));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

//Distance to a line segment,
float dfLine(vec2 start, vec2 end, vec2 uv)
{
	start *= scale1;
	end *= scale1;

	vec2 line = end - start;
	float frac = dot(uv - start,line) / dot(line,line);
	return distance(start + line * clamp(frac, 0.0, 1.0), uv);
}

//Distance to the edge of a circle.
float dfCircle(vec2 origin, float radius, vec2 uv)
{
	origin *= scale1;
	radius *= scale1;

	return abs(length(uv - origin) - radius);
}

//Distance to an arc.
float dfArc(vec2 origin, float start, float sweep, float radius, vec2 uv, float pi, float tau)
{
	origin *= scale1;
	radius *= scale1;

	uv -= origin;
	uv *= mat2(vec2(cos(start), sin(start)),vec2(-sin(start), cos(start)));

	float offs = (sweep / 2.0 - pi);
	float ang = mod(atan(uv.y, uv.x) - offs, tau) + offs;
	ang = clamp(ang, min(0.0, sweep), max(0.0, sweep));

	return distance(radius * vec2(cos(ang), sin(ang)), uv);
}

//Distance to the digit "d" (0-9).
float dfDigit(vec2 origin, float d, vec2 uv, float pi, float tau)
{
	uv -= origin;
	d = floor(d);
	float dist = 1e6;

	if(d == 0.0)
	{
		dist = min(dist, dfLine(vec2(1.000,1.000), vec2(1.000,0.500), uv));
		dist = min(dist, dfLine(vec2(0.000,1.000), vec2(0.000,0.500), uv));
		dist = min(dist, dfArc(vec2(0.500,1.000),0.000, 3.142, 0.500, uv, pi, tau));
		dist = min(dist, dfArc(vec2(0.500,0.500),3.142, 3.142, 0.500, uv, pi, tau));
		return dist;
	}
	if(d == 1.0)
	{
		dist = min(dist, dfLine(vec2(0.500,1.500), vec2(0.500,0.000), uv));
		return dist;
	}
	if(d == 2.0)
	{
		dist = min(dist, dfLine(vec2(1.000,0.000), vec2(0.000,0.000), uv));
		dist = min(dist, dfLine(vec2(0.388,0.561), vec2(0.806,0.719), uv));
		dist = min(dist, dfArc(vec2(0.500,1.000),0.000, 3.142, 0.500, uv, pi, tau));
		dist = min(dist, dfArc(vec2(0.700,1.000),5.074, 1.209, 0.300, uv, pi, tau));
		dist = min(dist, dfArc(vec2(0.600,0.000),1.932, 1.209, 0.600, uv, pi, tau));
		return dist;
	}
	if(d == 3.0)
	{
		dist = min(dist, dfLine(vec2(0.000,1.500), vec2(1.000,1.500), uv));
		dist = min(dist, dfLine(vec2(1.000,1.500), vec2(0.500,1.000), uv));
		dist = min(dist, dfArc(vec2(0.500,0.500),3.142, 4.712, 0.500, uv, pi, tau));
		return dist;
	}
	if(d == 4.0)
	{
		dist = min(dist, dfLine(vec2(0.700,1.500), vec2(0.000,0.500), uv));
		dist = min(dist, dfLine(vec2(0.000,0.500), vec2(1.000,0.500), uv));
		dist = min(dist, dfLine(vec2(0.700,1.200), vec2(0.700,0.000), uv));
		return dist;
	}
	if(d == 5.0)
	{
		dist = min(dist, dfLine(vec2(1.000,1.500), vec2(0.300,1.500), uv));
		dist = min(dist, dfLine(vec2(0.300,1.500), vec2(0.200,0.900), uv));
		dist = min(dist, dfArc(vec2(0.500,0.500),3.142, 5.356, 0.500, uv, pi, tau));
		return dist;
	}
	if(d == 6.0)
	{
		dist = min(dist, dfLine(vec2(0.067,0.750), vec2(0.500,1.500), uv));
		dist = min(dist, dfCircle(vec2(0.500,0.500), 0.500, uv));
		return dist;
	}
	if(d == 7.0)
	{
		dist = min(dist, dfLine(vec2(0.000,1.500), vec2(1.000,1.500), uv));
		dist = min(dist, dfLine(vec2(1.000,1.500), vec2(0.500,0.000), uv));
		return dist;
	}
	if(d == 8.0)
	{
		dist = min(dist, dfCircle(vec2(0.500,0.400), 0.400, uv));
		dist = min(dist, dfCircle(vec2(0.500,1.150), 0.350, uv));
		return dist;
	}
	if(d == 9.0)
	{
		dist = min(dist, dfLine(vec2(0.933,0.750), vec2(0.500,0.000), uv));
		dist = min(dist, dfCircle(vec2(0.500,1.000), 0.500, uv));
		return dist;
	}

	return dist;
}

//Distance to a number
float dfNumber(vec2 origin, float num, vec2 uv, vec2 digitSpacing, float pi, float tau)
{
	uv -= origin;
	float dist = 1e6;
	float offs = 0.0;

	for(float i = 5.0;i > -3.0;i--)
	{
		float d = mod(num / pow(10.0,i),10.0);

		vec2 pos = digitSpacing * vec2(offs,0.0);

		if(i == 0.0)
		{
			dist = min(dist, dfCircle(vec2(offs+0.9,0.1)*1.1, 0.04,uv));
		}

		if(num > pow(10.0,i) || i == 0.0)
		{
			dist = min(dist, dfDigit(pos, d, uv, pi, tau));
			offs++;
		}
	}
	return dist;
}

//Distance to a number This handles 2 digit integers, leading 0's will be drawn
float dfNumberInt(vec2 origin, int inum, vec2 uv, vec2 digitSpacing, float pi, float tau)
{
    float num = float(inum);
	uv -= origin;
	float dist = 1e6;
	float offs = 0.0;

	for(float i = 1.0;i >= 0.0;i--)
	{
		float d = mod(num / pow(10.0,i),10.0);

		vec2 pos = digitSpacing * vec2(offs,0.0);

        dist = min(dist, dfDigit(pos, d, uv, pi, tau));
        offs++;
	}
	return dist;
}

float dfColon(vec2 origin, vec2 uv) {
	uv -= origin;
	float dist = 1e6;
	float offs = 0.0;

    dist = min(dist, dfCircle(vec2(offs+0.9,0.9)*1.1, 0.04,uv));
    dist = min(dist, dfCircle(vec2(offs+0.9,0.4)*1.1, 0.04,uv));
    return dist;
}

//Length of a number in digits
float numberLength(float n)
{
	return floor(max(log(n) / log(10.0), 0.0) + 1.0) + 2.0;
}

void fragment()
{
	float pi = atan(1.0)*4.0;
	float tau = atan(1.0)*8.0;
	vec2 digitSize = vec2(1.0,1.5) * scale1;
	vec2 digitSpacing = vec2(1.1,1.6) * scale1;

	vec2 aspect = iResolution.xy / iResolution.y;
	vec2 uv = (UV - DISP) * scale2;
	uv.y = - uv.y;

    int hour = int(now_time/3600.);
if (TWELVE_HOUR_CLOCK == true){
	if( hour > 12 ) hour -= 12;
    if( hour == 0 ) hour = 12;
}

    int minute = int(mod(now_time/60.,60.));

	float nsize = numberLength(9999.);
	vec2 pos = -digitSpacing * vec2(nsize,1.0)/2.0;

    vec2 basepos = pos;
    pos.x = basepos.x + 0.16;
	float dist = 1e6;
	dist = min(dist, dfNumberInt(pos, hour, uv,digitSpacing, pi, tau));

    pos.x = basepos.x + 0.39;
	dist = min(dist, dfColon( pos, uv ));

    pos.x = basepos.x + 0.60;
    float dist2 = 1e6;
	dist = min(dist, dfNumberInt(pos, minute, uv, digitSpacing, pi, tau));

	vec3 color = vec3(0);

	float shade = 0.0;

	shade = 0.004 / (dist);

	color += vec3(1,0.2,0) * shade;
if (GLOWPULSE == true){
	color += GLOW_COLOR * shade * noise((uv + vec2(iTime*.5)) * 2.5 + .5);// * 10.*(noise(uv.yx));
}


    float grid;
    if( SHOW_GRID == true){
		 grid = 0.5-max(abs(mod(uv.x*64.0,1.0)-0.5), abs(mod(uv.y*64.0,1.0)-0.5));
	}


    color *= 0.25+vec3(smoothstep(0.0,GRID,grid))*0.75;


	fragColor = vec4( color , 1.0 );
}
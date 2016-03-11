
#define OBJ_SIZE			10
#define PI			3.141592654f
#define EPSILON		0.001f

float3   g_vDx;
float3   g_vDy;
float3   g_vViewDir;
float3   LF;
//int cant_obj = OBJ_SIZE*OBJ_SIZE;
int cant_obj = 5;
//float3   g_vLightPos = float3(3,5,2);
float3   g_vLightPos = float3(0,20,0);
float k_la = 0.5;		// luz ambiente
float	time;

// torus
float3 toro = float3(0,0,0);
float toro_rx = 5;
float toro_ry = 3;

int nro_R = 0;

// Textura que almacena los objetos
texture  g_txObj;
sampler2D g_samObj =
sampler_state
{
    Texture = <g_txObj>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};
texture  g_txObj2;
sampler2D g_samObj2 =
sampler_state
{
    Texture = <g_txObj2>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};
texture  g_txObj3;
sampler2D g_samObj3 =
sampler_state
{
    Texture = <g_txObj3>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};
texture  g_txObj4;
sampler2D g_samObj4 =
sampler_state
{
    Texture = <g_txObj4>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};
texture  g_txObjT;
sampler2D g_samObjT =
sampler_state
{
    Texture = <g_txObjT>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};

texture  g_txDef;
sampler2D g_samDef =
sampler_state
{
    Texture = <g_txDef>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Mirror;
    AddressV = Mirror;
};

texture  g_txDef2;
sampler2D g_samDef2 =
sampler_state
{
    Texture = <g_txDef2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Mirror;
    AddressV = Mirror;
};

texture  g_txDef3;
sampler2D g_samDef3 =
sampler_state
{
    Texture = <g_txDef3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Mirror;
    AddressV = Mirror;
};

texture  g_txColorBuf;
sampler2D g_samColorBuf =
sampler_state
{
    Texture = <g_txColorBuf>;
    MinFilter = NONE;
    MagFilter = NONE;
    MipFilter = NONE;
};

texture  g_txRayDir;
sampler2D g_samRayDir =
sampler_state
{
    Texture = <g_txRayDir>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};

texture  g_txIp;
sampler2D g_samIp =
sampler_state
{
    Texture = <g_txIp>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};

void VS_RayTracing(	float4 Pos : POSITION,float2 Tex : TEXCOORD0,
            out float4 oPos : POSITION,out float2 oTex : TEXCOORD0 )
{
	// Propago Posicion y textura
	oPos = Pos;
	oTex = Tex;
}


float HMap(float x,float y)
{
	float4 tx = tex2Dlod( g_samDef, float4(x*0.001,y*0.001,0,0));
	return (tx.r + tx.g + tx.b);
}

void PS_RayTracing4( float4 Diffuse:COLOR0, float2 Tex : TEXCOORD0,
		out float4 Color : COLOR0)
{
	// Calculo la direccion del rayo u Obtengo la direccion del rayo
	float3 D = normalize(g_vViewDir + g_vDx*(2*Tex.x-1) + g_vDy*(1-2*Tex.y)).rgb;
	float near = 5;
	float far = 40;
	float dt = 0.25;
	int hit = 0;
	float3 pt = LF+D*near;
	int signo = 0;
	int cant = 0;
	float t;
	float3 color_actual = 0;
	for(t=near;t<far && cant<200 && !hit;t+=dt)
	{
		pt = LF + D*t;
		float y = HMap(pt.x,pt.z);
		float dy = y - pt.y;
		if(abs(dy)<0.01)
			hit = 2;
		else
		if(!signo)
			signo = sign(dy);
		else
		if(sign(dy)!=signo)
			hit = 1;
			
		++cant;
	}
	
	if(hit)
	{
		hit = 0;
		float t1 = t-dt;
		float t0 = t1-dt;
		for(int i=0;i<15 && !hit;++i)
		{
			t = (t0+t1)*0.5;
			pt = LF + D*t;
			float dy = HMap(pt.x,pt.z)- pt.y;
			if(abs(dy)<0.01)
				hit = 1;
			else
			if(sign(dy)!=signo)
				t1 = t;
			else
				t0 = t;
		}
	}
	
	if(hit==1)
	{
		// aproximo la normal
		float ds = 1;
		float3 ipx = float3(ds,HMap(pt.x+ds,pt.z)-HMap(pt.x,pt.z),0);
		float3 ipz = float3(0,HMap(pt.x,pt.z+ds)-HMap(pt.x,pt.z),ds);
		float3 N = -normalize(cross(ipx,ipz));
		float3 color_obj = tex2D( g_samDef3, float2(pt.x,pt.z));

		float3 g_vLightDir = normalize(g_vLightPos-pt);
		float kd = saturate(dot(g_vLightDir,N));		// luz diffusa
		float ks = saturate(dot(reflect(g_vLightDir,N), g_vViewDir));
		ks = 0.75*pow(ks,5);		// luz especular
		color_actual = saturate((k_la + (1-k_la)*kd)*color_obj + ks);
	}
		
	Color.a = 1;
	Color.rgb = color_actual;
}



// Pixel Shader trivial
void PS_Draw( float4 Diffuse:COLOR0, float2 Tex : TEXCOORD0,
	out float4 Color : COLOR0 )
{
	Color = tex2D( g_samColorBuf, Tex);
}


void PS_GenerateRays( float4 Diffuse:COLOR0, float2 Tex : TEXCOORD0,
	out float4 Color : COLOR0 )
{
	// Calculo la direccion del rayo
	Color.rgb =  normalize(g_vViewDir + g_vDx*(2*Tex.x-1) + g_vDy*(1-2*Tex.y)); 
	Color.a = 1;
}


technique GenerateRays
{
    pass p0
    {
        VertexShader = compile vs_3_0 VS_RayTracing();
        PixelShader = compile ps_3_0 PS_GenerateRays();
    }
}


technique RayTracing
{
    pass p0
    {
        VertexShader = compile vs_3_0 VS_RayTracing();
        PixelShader = compile ps_3_0 PS_RayTracing4();
    }
}

technique Draw
{
    pass p0
    {
        VertexShader = compile vs_3_0 VS_RayTracing();
        PixelShader = compile ps_3_0 PS_Draw();
    }
}






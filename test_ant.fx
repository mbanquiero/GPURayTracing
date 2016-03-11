
#define OBJ_SIZE			10
#define PI			3.141592654f
#define EPSILON		0.0001f

float3   g_vDx;
float3   g_vDy;
float3   g_vViewDir;
float3   LF;
//int cant_obj = OBJ_SIZE*OBJ_SIZE;
int cant_obj = 2;
float3   g_vLightDir = float3(0,1,0);
float k_la = 0.5;		// luz ambiente

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
};

texture  g_txDef2;
sampler2D g_samDef2 =
sampler_state
{
    Texture = <g_txDef2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

texture  g_txDef3;
sampler2D g_samDef3 =
sampler_state
{
    Texture = <g_txDef3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
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

void PS_RayTracing( float4 Diffuse:COLOR0, float2 Tex : TEXCOORD0,
	out float4 Color : COLOR0 ,out float4 RayDir : COLOR1,out float4 oIp : COLOR2 )
{
	// Calculo la direccion del rayo
	//float3 D =  normalize(g_vViewDir + g_vDx*(2*Tex.x-1) + g_vDy*(1-2*Tex.y)).rgb; 
	// Obtengo la direccion del rayo
	float3 D = tex2D( g_samRayDir, Tex);
	float R = 100000;
	float3 Ip = 0;
	int objsel = -1;
	float4 pobjsel;
	int tipo_sel;
	int i_sel,j_sel;
	float3 color_actual = 0;
	float bc_b,bc_g;		// baricentrias del triangulo
	float3 N;				// normal del objeto que intersecto
	bool ret = false;
	Color.a = 1;
	
	if(nro_R>0)
	{
		LF = tex2D( g_samIp, Tex);
		if(!length(D))
			ret = true;		
	}
	
	
	if(ret)
	{
		// el rayo no intersecta con ningun objeto, dejo el color como estaba
		oIp = RayDir = 0;
		Color.rgb = tex2D( g_samColorBuf, Tex);
	}
	else
	{
		int i = 0;
		int j = 0;
		for(int t=0;t<cant_obj;++t)
		{	
		
			int tipo_obj = tex2D( g_samObjT, float2(j+0.5,i+0.5)/OBJ_SIZE).b*256;
			if(tipo_obj==0)
			{
				// Esfera 
				//------------------------------------------
				// tomo los datos de la esfera
				float4 obj = tex2D( g_samObj, float2(j+0.5,i+0.5)/OBJ_SIZE);
				float3 esfera = obj.xyz;
				float radio = obj.w;
				float3 aux = LF - esfera;
				float c = dot(aux,aux)-radio*radio;
				
			
				// verifico si intersecta con la esfera
				//float B = 2*(D.x*AA + D.y*BB + D.z*CC);
				float B = 2*dot(D,aux);
				float disc = B*B - 4*c;
				if(disc>=0)
				{
					float t0 = (-B-sqrt(disc))/2;
					float t1 = (-B+sqrt(disc))/2;

					if(t0>t1)
					{
						float aux = t1;
						t1 = t0;
						t0 = aux;
					}
					
					// verifico el primer punto
					bool fl = t0>0 && t0<R?true:false;
					// verifico el segundo punto
					bool fl2 = t1>0 && t1<R?true:false;

					// hay 3 casos :
					// intersecta en 2 puntos, en 1 o en ninguno
					if(fl)
					{
						R = t0;
						Ip = LF+D*t0;		// punto de interseccion
						objsel = t;
						pobjsel = obj;
						i_sel = i;
						j_sel = j;
						tipo_sel = 0;
					}
					else
					if(fl2)
					{
						R = t1;
						Ip = LF+D*t1;		// punto de interseccion
						objsel = t;
						pobjsel = obj;
						i_sel = i;
						j_sel = j;
						tipo_sel = 0;
					}
				}
			}
			
			if(tipo_obj==1)
			{
				// Triangulo
				//------------------------------------------
				float3 A = tex2D( g_samObj, float2(j+0.5,i+0.5)/OBJ_SIZE);
				float3 B = tex2D( g_samObj, float2((j+1)+0.5,i+0.5)/OBJ_SIZE);
				float3 C = tex2D( g_samObj, float2((j+2)+0.5,i+0.5)/OBJ_SIZE);
				float3x3 M = float3x3( B-A,C-A,-D);
				float det = determinant(M);
				if(det!=0)
				{
					float3x3 M3 = float3x3( B-A,C-A,LF-A);
					float b,g,t;
					t = determinant(M3)/det;
					if(t>0 && t<R)
					{
						float3x3 M1 = float3x3( LF-A,C-A,-D);
						b = determinant(M1)/det;
						if(b>=0)
						{
							float3x3 M2 = float3x3( B-A,LF-A,-D);
							g = determinant(M2)/det;
							if(g>=0 && b+g<=1)
							{
								// nota: Ip = A*(1-b-g) + B*b + C*g;
								// coordenadas baricentricas: a , b y g 
								// (a+b+g = 1)
								R = t;
								Ip = LF+D*t;		// punto de interseccion
								objsel = t;
								i_sel = i;
								j_sel = j;
								tipo_sel = 1;
								bc_b = b;
								bc_g = g;
								// calculo la normal
								N = -normalize(cross(B-A,C-A));
							}
						}
					}
				}
			}			
				
			// paso al siguiente objeto
			if(j+=8>=1024-8)
			{
				j = 0;
				i++;
			}
			
		}
			
		if(objsel!=-1)
		{
			if(tipo_sel==0)
			{
				// intersecto en la esfera objsel
				float3 centro = pobjsel.xyz;
				N = normalize(centro-Ip);		// normal
				//Color.rgb = 0.5 + 0.5*objsel/(float)cant_obj;
				float u = atan2(N.x,N.z)/(2*PI);
				float v = atan2(N.y,N.z)/(2*PI);
				float3 color_obj;
				if(i_sel%2)
					color_obj = tex2D( g_samDef, float2(u,v));
				else
				if(j_sel%2)
					color_obj = tex2D( g_samDef2, float2(u,v));
				else
					color_obj = tex2D( g_samDef3, float2(u,v));
					
				float kd = dot(N,g_vLightDir);		// luz diffusa
				color_actual = (k_la + (1-k_la)*kd)*color_obj;
			
				
			}
			
			if(tipo_sel==1)
			{
				// nota: Ip = A*(1-b-g) + B*b + C*g;
				// intersecto en el triangulo
				color_actual = 1;
			}
			
			// Calculo la direccion del rayo reflejado
			D = reflect(D,N);
		}
		else
			D = 0;
		
		if(nro_R==0)
			Color.rgb = color_actual;
		else
		{
			float alfa = pow(0.5,nro_R);
			Color.rgb = alfa*color_actual + (1-alfa)*tex2D( g_samColorBuf, Tex);
		}
		
		// out RayDir
		RayDir.xyz = D;
		RayDir.w = 0;
		// out Intersection Point, lo alejo un cierto epsilon, para
		// que en la proxima el rayo no haga interseccion con sigo mismo, pero si con otra
		// parte del mismo objeto (self reflexion) 
		oIp.xyz = Ip+ N*EPSILON;
		oIp.w = 0;
	}
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
        PixelShader = compile ps_3_0 PS_RayTracing();
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



// verifico el primer punto
bool fl = t0>0 && t0<R?true:false;
// verifico el segundo punto
bool fl2 = t1>0 && t1<R?true:false;

// Geometria constructiva
// Objeto Interseccion M Interseccion M2 
float4 M = tex2D( g_samObj2, float2(j+0.5,i+0.5)/OBJ_SIZE);
float4 M2 = tex2D( g_samObj3, float2(j+0.5,i+0.5)/OBJ_SIZE);
if(fl)
{
	float3 pt = LF+D*t0;
	float dist = distance(pt,float3(M.x,M.y,M.z));
	// interseccion
	if(dist>M.w)
		fl = false;
	else
	{
		dist = distance(pt,float3(M2.x,M2.y,M2.z));
		if(dist>M2.w)
			fl = false;
	}
}
if(fl2)
{
	float3 pt = LF+D*t1;
	float dist = distance(pt,float3(M.x,M.y,M.z));
	// interseccion
	if(dist>M.w)
		fl2 = false;
	else
	{
		dist = distance(pt,float3(M2.x,M2.y,M2.z));
		if(dist>M2.w)
			fl2 = false;
	}
}


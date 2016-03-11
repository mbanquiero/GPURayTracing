
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

float voxel_dx = 256;
float voxel_dy = 24;
float voxel_dz = 256;

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

texture  g_txVoxel;
sampler2D g_samVoxel =
sampler_state
{
    Texture = <g_txVoxel>;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = NONE;
};

texture  g_txBitwise;
sampler2D g_samBitwise =
sampler_state
{
    Texture = <g_txBitwise>;
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


void PS_RayVoxel( float4 Diffuse:COLOR0, float2 Tex : TEXCOORD0,out float4 Color : COLOR0  )
{
	Color.a = 1;
	Color.rgb = 0;

	// Calculo la direccion del rayo u Obtengo la direccion del rayo
	float3 D = normalize(g_vViewDir + g_vDx*(2*Tex.x-1) + g_vDy*(1-2*Tex.y)).rgb;
	
	// ecuacion del rayo
	// LF + K*D 
	
	// Ray marching 
	float3 p = LF;
	bool ret = false;
	for(int i=0;i<128 && !ret;++i)
	{
		float u = p.x / voxel_dx + 0.5;
		float v = p.z / voxel_dz + 0.5;
		
		float4 voxel = tex2Dlod( g_samVoxel, float4(u,v,0,0));
		
		float byte;
		float k;
		if(p.y<=7.5)
		{
			byte = voxel.r;
			k = round(p.y);
		}
		else
		if(p.y<=15.5)
		{
			byte =  voxel.g;
			k = round(p.y - 8);
		}
		else
		if(p.y<=23.5)
		{
			byte =  voxel.b;
			k = round(p.y - 16);
		}
		else
		{
			byte = 0;
			k = 0;
		}
		
		k = clamp(k,0,8);
		
		/*
		if(byte>0)
		{
			Color.rgb = voxel.rgb;
			ret = true;
		}*/
		
		//byte = round(byte);
		/*
		for(int s=0;s<k;++s)
			byte/=2;
		if(byte%2==1)
		{
			Color.rgb = voxel.rgb;
			ret = true;
		}*/
		
		k = pow(2,k);
		//float bit = tex2Dlod(g_samBitwise,float4(1,1,0,0)).b * 255;
		float bit = tex2Dlod(g_samBitwise,float4(byte,k/256.0,0,0)).b;
		
		if(bit>0)
		{
			Color.rgb = voxel.rgb;
			ret = true;
		}

		// Heightmap
		/*
		float k = (voxel.r * 0.222 + voxel.g * 0.707 + voxel.b* 0.071) * voxel_dy;
		if(p.y <= k)
		{
			Color.rgb = voxel.rgb;
			ret = true;
		}
		*/
		
		// Avanzo el rayo
		p = p + D;
	}
}


void PS_RayTracing( float4 Diffuse:COLOR0, float2 Tex : TEXCOORD0,
	out float4 Color : COLOR0 ,out float4 RayDir : COLOR1,out float4 oIp : COLOR2 )
{
	// Calculo la direccion del rayo u Obtengo la direccion del rayo
	float3 D = nro_R==0?
		normalize(g_vViewDir + g_vDx*(2*Tex.x-1) + g_vDy*(1-2*Tex.y)).rgb:
		tex2D( g_samRayDir, Tex);
	float3 antD = D;
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
		if(D.x>1.5)
			ret = true;		
	}
	
	
	if(ret)
	{
		// el rayo no intersecta con ningun objeto, dejo el color como estaba
		oIp = RayDir = 0;
		RayDir.x = 2;
		Color.rgb = tex2D( g_samColorBuf, Tex);
	}
	else
	{
		int i = 0;
		int j = 0;
		for(int n=0;n<cant_obj;++n)
		{	
		
			int tipo_obj = tex2D( g_samObjT, float2(j+0.5,i+0.5)/OBJ_SIZE).b*256;
			if(tipo_obj==0 || tipo_obj==2)
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
					
					/*
					// Geometria constructiva
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
						
						// diferencia
						//if((tipo_obj==0 && dist<M.w) || (tipo_obj==2 && dist>=M.w))
						//	fl = false;
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
							
						// diferencia
						//if((tipo_obj==0 && dist<M.w) || (tipo_obj==2 && dist>=M.w))
						//	fl2 = false;
					}
					*/
				
					// hay 3 casos :
					// intersecta en 2 puntos, en 1 o en ninguno
					if(fl)
					{
						R = t0;
						Ip = LF+D*t0;		// punto de interseccion
						objsel = n;
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
						objsel = n;
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
				float3 B = tex2D( g_samObj2, float2(j+0.5,i+0.5)/OBJ_SIZE);
				float3 C = tex2D( g_samObj3, float2(j+0.5,i+0.5)/OBJ_SIZE);
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
								objsel = n;
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
			if(++j==OBJ_SIZE)
			{
				j = 0;
				i++;
			}
			
		}
			
		if(objsel!=-1)
		{
			float3 color_obj = 0;
			float3   g_vLightDir = normalize(g_vLightPos-Ip);
			
			if(tipo_sel==0)
			{
				// intersecto en la esfera objsel
				float3 centro = pobjsel.xyz;
				N = normalize(Ip-centro);		// normal
				float u = atan2(N.x,N.z)/(2*PI);
				float v = N.y/2+0.5;
				/*
				if(j_sel==0)
					color_obj.r = 1;
				else
				if(j_sel==1)
					color_obj.g = 1;
				else
				if(j_sel==2)
					color_obj.b = 1;
				*/
				
				color_obj = tex2D( g_samDef3, float2(u,v)*5);

			}
			
			if(tipo_sel==1)
			{
				// nota: Ip = A*(1-b-g) + B*b + C*g;
				// intersecto en el triangulo
				// tomo los datos del objeto
				float4 A = tex2D( g_samObj, float2(j_sel+0.5,i_sel+0.5)/OBJ_SIZE);
				float4 B = tex2D( g_samObj2, float2(j_sel+0.5,i_sel+0.5)/OBJ_SIZE);
				float4 C = tex2D( g_samObj3, float2(j_sel+0.5,i_sel+0.5)/OBJ_SIZE);
				float4 D = tex2D( g_samObj4, float2(j_sel+0.5,i_sel+0.5)/OBJ_SIZE);
				
				// tomo las coordenadas uv de cada punto
				float2 txA = float2(A.w,D.x);
				float2 txB = float2(B.w,D.y);
				float2 txC = float2(C.w,D.z);
				// interpolo la textura en el triangulo				
				float2 tex = txA*(1-bc_b-bc_g) + txB*bc_b + txC*bc_g;
				if(nro_R>0)
					color_obj = tex2D( g_samDef, tex);
				else
					color_obj = tex2Dlod( g_samDef, float4(tex.x,tex.y,0,R/35));
				//float kd = dot(N,g_vLightDir);		// luz diffusa
				//color_actual = (k_la + (1-k_la)*kd)*color_obj;
				//color_actual = color_obj;
				//color_actual.g = 1;
			}
			
			float kd = saturate(dot(g_vLightDir,N));		// luz diffusa
			float ks = saturate(dot(reflect(g_vLightDir,N), normalize(Ip-LF)));
			ks = 0.7*pow(ks,5);		// luz esspecular
			color_actual = saturate((k_la + (1-k_la)*kd)*color_obj + ks);
			//color_actual = (k_la + kd)*color_obj;
			//color_actual = color_obj;
			
			// Calculo la direccion del rayo reflejado 
			D = reflect(D,N);
		}
		else
			D.x = 2;
		
		if(nro_R==0)
			Color.rgb = color_actual;
		else
		{
			//float alfa = pow(0.5,nro_R);
			float alfa = 0.25;
			Color.rgb = alfa*color_actual + (1-alfa)*tex2D( g_samColorBuf, Tex);
		}
		
		// out RayDir
		RayDir.xyz = D;
		RayDir.w = 0;
		// out Intersection Point, lo alejo un cierto epsilon, para
		// que en la proxima el rayo no haga interseccion con sigo mismo, pero si con otra
		// parte del mismo objeto (self reflexion) 
		oIp.xyz = LF+antD*(R-EPSILON);		// punto de interseccion
		oIp.w = 0;
	}
	
}

float F(float x,float y)
{
	return 5;
	/*
	y-=10;
	//return 0.1*(x*x - y*y)-15;
	//return sqrt(200 - x*x - y*y)-15;
	//return 3*(sin(0.5*x)+cos(0.5*y));
	//return 35*exp(-2*(0.008*(x*x+y*y)))*sin(0.008*(x*x-y*y));
	float R = 10;
	float r = 3;
	float d = R - sqrt(x*x + y*y);
	float disc = r*r-d*d;
	if(abs(disc)<0.1)
		return 0;
	else
	if(disc>0.1)
		return sqrt(disc);
	else
		return -1000;
	*/

}


void PS_RayTracing3( float4 Diffuse:COLOR0, float2 Tex : TEXCOORD0,
	out float4 Color : COLOR0 ,out float4 RayDir : COLOR1,out float4 oIp : COLOR2 )
{
	// Calculo la direccion del rayo u Obtengo la direccion del rayo
	float3 D = nro_R==0?
		normalize(g_vViewDir + g_vDx*(2*Tex.x-1) + g_vDy*(1-2*Tex.y)).rgb:
		tex2D( g_samRayDir, Tex);
	float3 antD = D;
	float near = 5;
	float far = 40;
	float dt = 0.25;
	int hit = 0;
	float3 pt = LF+D*near;
	int signo = 0;
	int cant = 0;
	float t;
	float color_actual;
	for(t=near;t<far && cant<200 && !hit;t+=dt)
	{
		pt = LF + D*t;
		// verifico si la funcion Existe
		float y = F(pt.x,pt.z);
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
	
	if(hit==1)
	{
		hit = 0;
		float t1 = t-dt;
		float t0 = t1-dt;
		for(int i=0;i<15 && !hit;++i)
		{
			t = (t0+t1)/2;
			pt = LF + D*t;
			float dy = F(pt.x,pt.z)- pt.y;
			if(abs(dy)<0.01)
				hit = true;
			else
			if(sign(dy)!=signo)
				t1 = t;
			else
				t0 = t;
		}		
	}
		
	if(hit)
	{
		// aproximo la normal
		float ds = 1;
		float3 ipx = float3(ds,F(pt.x+ds,pt.z)-F(pt.x,pt.z),0);
		float3 ipz = float3(0,F(pt.x,pt.z+ds)-F(pt.x,pt.z),ds);
		float3 N = -normalize(cross(ipx,ipz));
		float3 color_obj = tex2D( g_samDef, float2(pt.x,pt.z));
		//float3 color_obj = tex2Dlod( g_samDef, float4(pt.x,pt.y,0,t/20));

		float3 g_vLightDir = normalize(g_vLightPos-pt);
		float kd = saturate(dot(g_vLightDir,N));		// luz diffusa
		float ks = saturate(dot(reflect(g_vLightDir,N), g_vViewDir));
		ks = 0.75*pow(ks,5);		// luz especular
		color_actual = saturate((k_la + (1-k_la)*kd)*color_obj + ks);
		// Calculo la direccion del rayo reflejado 
		D = reflect(D,N);
	}
	else
	{
		color_actual = 0;
		D.x = 2;
	}
		
	Color.a = 1;
	if(nro_R==0)
		Color.rgb = color_actual;
	else
	{
		float alfa = 0.25;
		Color.rgb = alfa*color_actual + (1-alfa)*tex2D( g_samColorBuf, Tex);
	}
	
	
	// out RayDir
	RayDir.xyz = D;
	RayDir.w = 0;
	// out Intersection Point, lo alejo un cierto epsilon, para
	// que en la proxima el rayo no haga interseccion con sigo mismo, pero si con otra
	// parte del mismo objeto (self reflexion) 
	oIp.xyz = LF+antD*(t-EPSILON);		// punto de interseccion
	oIp.w = 0;
	
}

float HMap(float x,float y)
{
	float3 tx = tex2D( g_samDef, float2(x,y)*0.001);
	return 10;
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
	float t,ts;
	float color_actual = 0;
	for(t=near;t<far && cant<200 && !hit;t+=dt)
	{
		pt = LF + D*t;
		// verifico si la funcion Existe
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
	
	if(hit==1)
	{
		ts = t;
		hit = 0;
		float t1 = ts-dt;
		float t0 = t1-dt;
		for(int i=0;i<15 && !hit;++i)
		{
			ts = (t0+t1)*0.5;
			pt = LF + D*ts;
			float dy = HMap(pt.x,pt.z)- pt.y;
			if(abs(dy)<0.01)
				hit = 1;
			else
			if(sign(dy)!=signo)
				t1 = ts;
			else
				t0 = ts;
		}
	}
	
	if(hit==1)
	{
		// aproximo la normal
		float ds = 1;
		float3 ipx = float3(ds,HMap(pt.x+ds,pt.z)-HMap(pt.x,pt.z),0);
		float3 ipz = float3(0,HMap(pt.x,pt.z+ds)-HMap(pt.x,pt.z),ds);
		float3 N = -normalize(cross(ipx,ipz));
		float3 color_obj = tex2D( g_samDef, float2(pt.x,pt.z));

		float3 g_vLightDir = normalize(g_vLightPos-pt);
		float kd = saturate(dot(g_vLightDir,N));		// luz diffusa
		float ks = saturate(dot(reflect(g_vLightDir,N), g_vViewDir));
		ks = 0.75*pow(ks,5);		// luz especular
		color_actual = saturate((k_la + (1-k_la)*kd)*color_obj + ks);
		color_actual = 1;
	}
	else
		color_actual.r = 1;
		
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
        PixelShader = compile ps_3_0 PS_RayVoxel();
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






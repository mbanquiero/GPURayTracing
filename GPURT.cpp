
#include <d3d9.h>
#pragma warning( disable : 4996 ) // disable deprecated warning 
#include <strsafe.h>
#pragma warning( default : 4996 ) 


#include <D3dx9effect.h>

//-----------------------------------------------------------------------------
// Global variables
//-----------------------------------------------------------------------------
LPDIRECT3D9             g_pD3D       = NULL; // Used to create the D3DDevice
LPDIRECT3DDEVICE9       g_pd3dDevice = NULL; // Our rendering device
LPDIRECT3DVERTEXBUFFER9 g_pVB        = NULL; // Buffer to hold vertices
ID3DXEffect*            g_pEffect = NULL;       // D3DX effect interface
LPDIRECT3DVERTEXDECLARATION9 g_pVertDecl = NULL;
D3DPRESENT_PARAMETERS	d3dpp;
LPDIRECT3DTEXTURE9      g_pTexObjT = NULL;	
LPDIRECT3DTEXTURE9      g_pTexObj;       // texture para almacenar los objetos
LPDIRECT3DTEXTURE9      g_pTexObj2;
LPDIRECT3DTEXTURE9      g_pTexObj3;
LPDIRECT3DTEXTURE9      g_pTexObj4;
LPDIRECT3DTEXTURE9      g_pTexDef;       // Textura x defecto
LPDIRECT3DTEXTURE9      g_pTexDef2; 
LPDIRECT3DTEXTURE9      g_pTexDef3;
LPDIRECT3DTEXTURE9      g_pTexColorBuf = NULL;       // Color Buffer
LPDIRECT3DTEXTURE9      g_pTexColorBufOut = NULL;       // Color Buffer
LPDIRECT3DTEXTURE9      g_pTexRayDir = NULL;       // Direccion del rayo
LPDIRECT3DTEXTURE9      g_pTexRayDirOut = NULL;       // Direccion del rayo
LPDIRECT3DTEXTURE9      g_pTexIp = NULL;       
LPDIRECT3DTEXTURE9      g_pTexIpOut = NULL;
LPDIRECT3DTEXTURE9      g_pTexVoxel = NULL;				// Voxels
LPDIRECT3DTEXTURE9      g_pTexBitwise = NULL;

// Camara
D3DXVECTOR3 LookFrom(0,20,-22);
D3DXVECTOR3 LookAt(0,15,0);
//D3DXVECTOR3 LookFrom(0,5,-12);
//D3DXVECTOR3 LookAt(0,3,0);
D3DXVECTOR3 VUp(0,1,0);
float fov = D3DX_PI / 4.0f;
float ftime = 0;


#define MAP_SIZE			1024
#define OBJ_SIZE			10

struct CUSTOMVERTEX
{
    FLOAT x,y,z;
    float u,v;
};

#define D3DFVF_CUSTOMVERTEX (D3DFVF_XYZ|D3DFVF_TEX1)



D3DVERTEXELEMENT9 g_aVertDecl[] =
{
    { 0, 0,  D3DDECLTYPE_FLOAT3, D3DDECLMETHOD_DEFAULT, D3DDECLUSAGE_POSITION, 0 },
    { 0, 24, D3DDECLTYPE_FLOAT2, D3DDECLMETHOD_DEFAULT, D3DDECLUSAGE_TEXCOORD, 0 },
    D3DDECL_END()
};


//-----------------------------------------------------------------------------
// Name: InitD3D()
// Desc: Initializes Direct3D
//-----------------------------------------------------------------------------
HRESULT InitD3D( HWND hWnd )
{
    // Create the D3D object.
    if( NULL == ( g_pD3D = Direct3DCreate9( D3D_SDK_VERSION ) ) )
        return E_FAIL;

    // Set up the structure used to create the D3DDevice
    ZeroMemory( &d3dpp, sizeof(d3dpp) );
    d3dpp.Windowed = TRUE;
    d3dpp.SwapEffect = D3DSWAPEFFECT_DISCARD;
    d3dpp.BackBufferFormat = D3DFMT_UNKNOWN;
	d3dpp.BackBufferWidth = 0; 
	d3dpp.BackBufferHeight = 0;
	d3dpp.MultiSampleType = D3DMULTISAMPLE_NONE ;

    // Create the D3DDevice
    if( FAILED( g_pD3D->CreateDevice( D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWnd,
                                      D3DCREATE_HARDWARE_VERTEXPROCESSING,
                                      &d3dpp, &g_pd3dDevice ) ) )
    {
        return E_FAIL;
    }

    // Device state would normally be set here

    DWORD dwShaderFlags = D3DXFX_NOT_CLONEABLE;
    // If this fails, there should be debug output as to 
    // they the .fx file failed to compile
	ID3DXBuffer *pBuffer = NULL;
    if( FAILED(D3DXCreateEffectFromFile( g_pd3dDevice, "test.fxo", NULL, NULL, dwShaderFlags, 
                                        NULL, &g_pEffect, &pBuffer ) ))
	{
			char *saux = (char *)pBuffer->GetBufferPointer();
			return E_FAIL;
	}

	g_pd3dDevice->CreateVertexDeclaration( g_aVertDecl, &g_pVertDecl);

	D3DCAPS9 Caps;
	g_pd3dDevice->GetDeviceCaps(&Caps);
    return S_OK;
}




//-----------------------------------------------------------------------------
// Name: InitVB()
// Desc: Creates a vertex buffer and fills it with our vertices. The vertex
//       buffer is basically just a chuck of memory that holds vertices. After
//       creating it, we must Lock()/Unlock() it to fill it. For indices, D3D
//       also uses index buffers. The special thing about vertex and index
//       buffers is that they can be created in device memory, allowing some
//       cards to process them in hardware, resulting in a dramatic
//       performance gain.
//-----------------------------------------------------------------------------
HRESULT InitVB()
{
    CUSTOMVERTEX vertices[] =
    {
        { -1, 1, 1, 0,0, }, 
		{ 1,  1, 1, 1,0, },
		{ -1, -1, 1, 0,1, },
        { 1,-1, 1, 1,1, },
    };

    if( FAILED( g_pd3dDevice->CreateVertexBuffer( 4*sizeof(CUSTOMVERTEX),
                                                  0, D3DFVF_CUSTOMVERTEX,
                                                  D3DPOOL_DEFAULT, &g_pVB, NULL ) ) )
    {
        return E_FAIL;
    }

    VOID* pVertices;
    if( FAILED( g_pVB->Lock( 0, sizeof(vertices), (void**)&pVertices, 0 ) ) )
        return E_FAIL;
    memcpy( pVertices, vertices, sizeof(vertices) );
    g_pVB->Unlock();

	// Direccion del rayo
	g_pd3dDevice->CreateTexture( d3dpp.BackBufferWidth, d3dpp.BackBufferHeight,
                                     1, D3DUSAGE_RENDERTARGET,
                                     D3DFMT_A32B32G32R32F,
                                     D3DPOOL_DEFAULT,
                                     &g_pTexRayDir,NULL);
	g_pd3dDevice->CreateTexture( d3dpp.BackBufferWidth, d3dpp.BackBufferHeight,
                                     1, D3DUSAGE_RENDERTARGET,
                                     //    D3DFMT_X8R8G8B8,
                                     D3DFMT_A32B32G32R32F,
                                     D3DPOOL_DEFAULT,
                                     &g_pTexRayDirOut,NULL);

	// Intersection Point
	g_pd3dDevice->CreateTexture( d3dpp.BackBufferWidth, d3dpp.BackBufferHeight,
                                     1, D3DUSAGE_RENDERTARGET,
                                     D3DFMT_A32B32G32R32F,
                                     D3DPOOL_DEFAULT,
                                     &g_pTexIp,NULL);
	g_pd3dDevice->CreateTexture( d3dpp.BackBufferWidth, d3dpp.BackBufferHeight,
                                     1, D3DUSAGE_RENDERTARGET,
                                     D3DFMT_A32B32G32R32F,
                                     D3DPOOL_DEFAULT,
                                     &g_pTexIpOut,NULL);


	// Creo la textura de objetos
	g_pd3dDevice->CreateTexture( OBJ_SIZE,OBJ_SIZE,
                                     1, D3DUSAGE_DYNAMIC,
                                     D3DFMT_A32B32G32R32F,
                                     D3DPOOL_DEFAULT,
                                     &g_pTexObj,NULL);
	g_pEffect->SetTexture( "g_txObj", g_pTexObj);

	g_pd3dDevice->CreateTexture( OBJ_SIZE, OBJ_SIZE,
                                     1, D3DUSAGE_DYNAMIC,
                                     D3DFMT_A32B32G32R32F,
                                     D3DPOOL_DEFAULT,
                                     &g_pTexObj2,NULL);
	g_pEffect->SetTexture( "g_txObj2", g_pTexObj2);
	g_pd3dDevice->CreateTexture( OBJ_SIZE, OBJ_SIZE,
                                     1, D3DUSAGE_DYNAMIC,
                                     D3DFMT_A32B32G32R32F,
                                     D3DPOOL_DEFAULT,
                                     &g_pTexObj3,NULL);
	g_pEffect->SetTexture( "g_txObj3", g_pTexObj3);
	g_pd3dDevice->CreateTexture( OBJ_SIZE, OBJ_SIZE,
                                     1, D3DUSAGE_DYNAMIC,
                                     D3DFMT_A32B32G32R32F,
                                     D3DPOOL_DEFAULT,
                                     &g_pTexObj4,NULL);
	g_pEffect->SetTexture( "g_txObj4", g_pTexObj4);
	g_pd3dDevice->CreateTexture( OBJ_SIZE, OBJ_SIZE,
                                     1, D3DUSAGE_DYNAMIC,
                                     D3DFMT_X8R8G8B8,
                                     D3DPOOL_DEFAULT,
                                     &g_pTexObjT,NULL);
	g_pEffect->SetTexture( "g_txObjT", g_pTexObjT);


	// inicializo la textura
    D3DLOCKED_RECT lr,lr2,lr3,lr4,lrT;
    g_pTexObj->LockRect( 0, &lr, NULL, 0);
    g_pTexObj2->LockRect( 0, &lr2, NULL, 0);
    g_pTexObj3->LockRect( 0, &lr3, NULL, 0);
    g_pTexObj4->LockRect( 0, &lr4, NULL, 0);
    g_pTexObjT->LockRect( 0, &lrT, NULL, 0);
	BYTE *bytes = (BYTE *)lr.pBits;
	BYTE *bytes2 = (BYTE *)lr2.pBits;
	BYTE *bytes3 = (BYTE *)lr3.pBits;
	BYTE *bytes4 = (BYTE *)lr4.pBits;
	BYTE *bytesT = (BYTE *)lrT.pBits;
	for(int j=0;j<OBJ_SIZE;++j)
	{
		int t = 0;
		int s = 0;
		for(int i=0;i<OBJ_SIZE;++i)
		{
			FLOAT *texel = (FLOAT *)(bytes+t);
			// formato del texel (4 bytes por canal) 
			// | R |  G |  B  |  A |		= 128 bits
			
			texel[0] = i-5;		// pos X
			texel[1] = j-5;		// Pos y 
			texel[2] = 0;		// Pos Z
			texel[3] = 0.5;		// Radio

			texel = (FLOAT *)(bytes2+t);
			texel[0] = texel[1] = texel[2] = texel[3] = 0;
			texel = (FLOAT *)(bytes3+t);
			texel[0] = texel[1] = texel[2] = texel[3] = 0;
			t+=16;

			BYTE *texelT = (BYTE *)(bytesT+s);
			texelT[0] = texelT[1] = texelT[2] = texelT[3] = 0;
			s+=4;

		}
		bytes+=lr.Pitch;
		bytes2+=lr2.Pitch;
		bytes3+=lr3.Pitch;
		bytesT+=lrT.Pitch;
	}
	

	if(0)
	{
		FLOAT *texel = (FLOAT *)lr.pBits;
		FLOAT *texel2 = (FLOAT *)lr2.pBits;
		FLOAT *texel3 = (FLOAT *)lr3.pBits;
		BYTE *texelT = (BYTE *)lrT.pBits;

		// esferas
		texelT[0] = 0;
		texel[0] = 4;		// pos X
		texel[1] = -2;		// Pos y 
		texel[2] = 0;		// Pos Z
		texel[3] = 1;		// Radio

		texelT[4] = 0;
		texel[4] = 4;		// pos X
		texel[5] = -3;		// Pos y 
		texel[6] = -3;		// Pos Z
		texel[7] = 2;		// Radio

		// Triangulos
		texelT[8] = 1;
		texel[8] = 0;		// pos X
		texel[9] = -5;		// Pos y 
		texel[10] = 5;		// Pos Z

		texel2[8] = 10;		// pos X
		texel2[9] = -5;		// Pos y 
		texel2[10] = 5;		// Pos Z

		texel3[8] = 0;		// pos X
		texel3[9] = 5;		// Pos y 
		texel3[10] = 5;		// Pos Z

		// triangulo2
		texelT[12] = 1;
		texel[12] = 0;		// pos X
		texel[13] = 5;		// Pos y 
		texel[14] = 5;		// Pos Z

		texel2[12] = 10;		// pos X
		texel2[13] = -5;		// Pos y 
		texel2[14] = 5;		// Pos Z

		texel3[12] = 10;		// pos X
		texel3[13] = 5;		// Pos y 
		texel3[14] = 5;		// Pos Z

		// Triangulos
		texelT[16] = 1;
		texel[16] = 0;		// pos X
		texel[17] = -5;		// Pos y 
		texel[18] = -20;	// Pos Z

		texel3[16] = 10;		// pos X
		texel3[17] = -5;		// Pos y 
		texel3[18] = -20;		// Pos Z

		texel2[16] = 0;		// pos X
		texel2[17] = 5;		// Pos y 
		texel2[18] = -20;		// Pos Z

		// triangulo2
		texelT[20] = 1;
		texel[20] = 0;		// pos X
		texel[21] = 5;		// Pos y 
		texel[22] = -20;		// Pos Z

		texel2[20] = 10;		// pos X
		texel2[21] = 5;		// Pos y 
		texel2[22] = -20;		// Pos Z

		texel3[20] = 10;		// pos X
		texel3[21] = -5;		// Pos y 
		texel3[22] = -20;		// Pos Z


		// Piso
		texelT[24] = 1;
		texel[24] = 0;		// pos X
		texel[25] = -5;		// Pos y 
		texel[26] = -10;	// Pos Z

		texel3[26] = 0;		// pos X
		texel3[25] = -5;		// Pos y 
		texel3[26] = 5;		// Pos Z

		texel2[24] = 10;		// pos X
		texel2[25] = -5;		// Pos y 
		texel2[26] = -10;		// Pos Z
		// triangulo2
		texelT[28] = 1;
		texel[28] = 0;		// pos X
		texel[29] = -5;		// Pos y 
		texel[30] = 5;		// Pos Z

		texel3[28] = 10;		// pos X
		texel3[29] = -5;		// Pos y 
		texel3[30] = 5;		// Pos Z

		texel2[28] = 10;		// pos X
		texel2[29] = -5;		// Pos y 
		texel2[30] = -10;		// Pos Z

	}

	if(1)
	{
		FLOAT *texel = (FLOAT *)lr.pBits;
		FLOAT *texel2 = (FLOAT *)lr2.pBits;
		FLOAT *texel3 = (FLOAT *)lr3.pBits;
		FLOAT *texel4 = (FLOAT *)lr4.pBits;
		BYTE *texelT = (BYTE *)lrT.pBits;

		// esferas
		int t = 0;
		texelT[t] = 0;
		texel[t] = -5;		// pos X
		texel[t+1] = 0;		// Pos y 
		texel[t+2] = 0;		// Pos Z
		texel[t+3] = 2;		// Radio
		t+=4;
		
		texelT[t] = 0;
		texel[t] = 0;		// pos X
		texel[t+1] = 0;		// Pos y 
		texel[t+2] = 0;		// Pos Z
		texel[t+3] = 2;		// Radio
		t+=4;

		texelT[t] = 0;
		texel[t] = 5;		// pos X
		texel[t+1] = 0;		// Pos y 
		texel[t+2] = 0;		// Pos Z
		texel[t+3] = 2;		// Radio
		t+=4;


		// Piso
		float k = 50;
		texelT[t] = 1;
		texel[t] = -200;		// pos X
		texel[t+1] = -2;		// Pos y 
		texel[t+2] = -200;		// Pos Z
		texel[t+3] = 0;			// texture U
		texel4[t] = 0;			// texture V

		texel3[t] = -200;		// pos X
		texel3[t+1] = -2;		// Pos y 
		texel3[t+2] = 200;		// Pos Z
		texel3[t+3] = 0;			// texture U
		texel4[t+2] = k;			// texture V

		texel2[t] = 200;		// pos X
		texel2[t+1] = -2;		// Pos y 
		texel2[t+2] = -200;		// Pos Z
		texel2[t+3] = k;			// texture U
		texel4[t+1] = 0;			// texture V

		t+=4;
		// triangulo2
		texelT[t] = 1;
		texel[t] = -200;		// pos X
		texel[t+1] = -2;		// Pos y 
		texel[t+2] = 200;		// Pos Z
		texel[t+3] = 0;			// texture U
		texel4[t] = k;			// texture V

		texel3[t] = 200;		// pos X
		texel3[t+1] = -2;		// Pos y 
		texel3[t+2] = 200;		// Pos Z
		texel3[t+3] = k;			// texture U
		texel4[t+2] = k;			// texture V

		texel2[t] = 200;		// pos X
		texel2[t+1] = -2;		// Pos y 
		texel2[t+2] = -200;		// Pos Z
		texel2[t+3] = k;			// texture U
		texel4[t+1] = 0;			// texture V

	}

	if(0)
	{
		// geometria constructiva
		FLOAT *texel = (FLOAT *)lr.pBits;
		FLOAT *texel2 = (FLOAT *)lr2.pBits;
		FLOAT *texel3 = (FLOAT *)lr3.pBits;
		FLOAT *texel4 = (FLOAT *)lr4.pBits;
		BYTE *texelT = (BYTE *)lrT.pBits;

		// esferas
		int t = 0;
		texelT[t] = 0;
		texel[t] =  0;		// pos X
		texel[t+1] = 0;		// Pos y 
		texel[t+2] = 0;		// Pos Z
		texel[t+3] = 5;		// Radio

		texel2[t] = 0;		// pos X
		texel2[t+1] = 0;	// Pos y 
		texel2[t+2] = -4;	// Pos Z
		texel2[t+3] = 3;	// Radio

		texel3[t] = 3;		// pos X
		texel3[t+1] = 5;	// Pos y 
		texel3[t+2] = 0;	// Pos Z
		texel3[t+3] = 9;	// Radio

		t+=4;
		
		texelT[t] = 2;
		texel[t] = 0;		// pos X
		texel[t+1] = 0;		// Pos y 
		texel[t+2] = -4;		// Pos Z
		texel[t+3] = 3;		// Radio

		texel2[t] = 0;		// pos X
		texel2[t+1] = 0;	// Pos y 
		texel2[t+2] = 0;	// Pos Z
		texel2[t+3] = 5;	// Radio

		texel3[t] = 3;		// pos X
		texel3[t+1] = 5;	// Pos y 
		texel3[t+2] = 0;	// Pos Z
		texel3[t+3] = 9;	// Radio


		t+=4;


		texelT[t] = 2;
		texel[t] = 3;		// pos X
		texel[t+1] = 5;	// Pos y 
		texel[t+2] = 0;	// Pos Z
		texel[t+3] = 9;	// Radio


		texel2[t] = 0;		// pos X
		texel2[t+1] = 0;	// Pos y 
		texel2[t+2] = 0;	// Pos Z
		texel2[t+3] = 5;	// Radio

		texel3[t] = 0;		// pos X
		texel3[t+1] = 0;		// Pos y 
		texel3[t+2] = -4;		// Pos Z
		texel3[t+3] = 3;		// Radio


		t+=4;


	}
	
    g_pTexObj->UnlockRect( 0 );
    g_pTexObj2->UnlockRect( 0 );
    g_pTexObj3->UnlockRect( 0 );
    g_pTexObj4->UnlockRect( 0 );
    g_pTexObjT->UnlockRect( 0 );


	D3DXCreateTextureFromFile( g_pd3dDevice, "bricks_clay_02_512x512.JPG",&g_pTexDef3);
	//D3DXCreateTextureFromFile( g_pd3dDevice, "grilla2.bmp",&g_pTexDef3);
	D3DXCreateTextureFromFile( g_pd3dDevice, "cobblestone_quad_01.JPG",&g_pTexDef2);
	D3DXCreateTextureFromFile( g_pd3dDevice, "grilla.bmp",&g_pTexDef);
	D3DXCreateTextureFromFile( g_pd3dDevice, "voxels.bmp",&g_pTexVoxel);


    g_pd3dDevice->CreateTexture( d3dpp.BackBufferWidth, d3dpp.BackBufferHeight,
                                         1, D3DUSAGE_RENDERTARGET,
										D3DFMT_A32B32G32R32F,
                                         D3DPOOL_DEFAULT,
                                         &g_pTexColorBuf,NULL);
    g_pd3dDevice->CreateTexture( d3dpp.BackBufferWidth, d3dpp.BackBufferHeight,
                                         1, D3DUSAGE_RENDERTARGET,
										D3DFMT_A32B32G32R32F,
                                         D3DPOOL_DEFAULT,
                                         &g_pTexColorBufOut,NULL);


	g_pEffect->SetTexture( "g_txRayDir", g_pTexRayDir);
	g_pEffect->SetTexture( "g_txColorBuf", g_pTexColorBuf);
	g_pEffect->SetTexture( "g_txIp", g_pTexIp);



	// Bitwise texture
	g_pd3dDevice->CreateTexture( 256, 256,1, D3DUSAGE_DYNAMIC,
					D3DFMT_X8R8G8B8,D3DPOOL_DEFAULT,&g_pTexBitwise,NULL);
	g_pTexBitwise->LockRect( 0, &lr, NULL, 0);
	bytes = (BYTE *)lr.pBits;
	int h = 0;
	for(int i=0;i<256;++i)
	{
		int t = 0;
		for(int j=0;j<256;++j)
		{
			BYTE *texel = (BYTE *)(bytes+t);

			// Tex[i][j] = i & j
			// formato del texel (1 bytes por canal) 
			// | B |  G |  R  |  A |		= 32 bits
			// 
			// 
			if(j%4==0 && i%4==0)
				++h;
			if(h>24)
				h = 0;
			texel[0] = texel[1] = texel[2] = 0;		
			texel[3] = 1;

			if(h<8)
				texel[0] = pow(2.0,h);
			else
			if(h<16)
				texel[1] = pow(2.0,h-8);
			else
			if(h<24)
				texel[2] = pow(2.0,h-16);


			texel[0] = i & j;		
			texel[1] = i & j;		
			texel[2] = i & j;		
			texel[3] = i & j;		


			t+=4;
		}
		bytes+=lr.Pitch;
	}
	g_pTexBitwise->UnlockRect( 0 );
	g_pEffect->SetTexture( "g_txBitwise", g_pTexBitwise);

	//D3DXSaveTextureToFile("test.bmp",D3DXIFF_BMP,g_pTexBitwise,NULL);


	return S_OK;
}




//-----------------------------------------------------------------------------
// Name: Cleanup()
// Desc: Releases all previously initialized objects
//-----------------------------------------------------------------------------
VOID Cleanup()
{


	if( g_pVB != NULL )        
        g_pVB->Release();

    if( g_pd3dDevice != NULL ) 
        g_pd3dDevice->Release();

    if( g_pD3D != NULL )       
        g_pD3D->Release();

    if(g_pVertDecl != NULL)
		g_pVertDecl->Release();

	if(g_pTexObj != NULL)
		g_pTexObj->Release();
	if(g_pTexObj2 != NULL)
		g_pTexObj2->Release();
	if(g_pTexObj3 != NULL)
		g_pTexObj3->Release();
	if(g_pTexObj4 != NULL)
		g_pTexObj4->Release();
	if(g_pTexObjT != NULL)
		g_pTexObjT->Release();

	if(g_pTexRayDir != NULL)
		g_pTexRayDir->Release();
	if(g_pTexRayDirOut != NULL)
		g_pTexRayDirOut->Release();

	if(g_pTexIp != NULL)
		g_pTexIp->Release();
	if(g_pTexIpOut != NULL)
		g_pTexIpOut->Release();

	if(g_pTexDef != NULL)
		g_pTexDef->Release();
	if(g_pTexDef2 != NULL)
		g_pTexDef2->Release();
	if(g_pTexDef3 != NULL)
		g_pTexDef3->Release();

	if(g_pTexColorBuf != NULL)
		g_pTexColorBuf->Release();
	if(g_pTexColorBufOut != NULL)
		g_pTexColorBufOut->Release();

	if(g_pTexVoxel!= NULL)
		g_pTexVoxel->Release();

	if(g_pTexBitwise!= NULL)
		g_pTexBitwise->Release();


}




//-----------------------------------------------------------------------------
// Name: Render()
// Desc: Draws the scene
//-----------------------------------------------------------------------------
VOID Render()
{
    // Begin the scene
    if( SUCCEEDED( g_pd3dDevice->BeginScene() ) )
    {
		g_pEffect->SetFloat("time", ftime);

		D3DXVECTOR3 N = LookAt-LookFrom;
		D3DXVec3Normalize(&N,&N);
		D3DXVECTOR3 V,U;
		D3DXVec3Cross(&V,&N,&VUp);
		D3DXVec3Normalize(&V,&V);
		D3DXVec3Cross(&U,&V,&N);
		float W = d3dpp.BackBufferWidth;
		float H = d3dpp.BackBufferHeight;
		float k = 2*tan(fov/2);
		D3DXVECTOR3 Dy = U*(k*H/W);
		D3DXVECTOR3 Dx = V*k;
		// direccion de cada rayo
		//TVector3d D = N + Dy*y + Dx*x;

		g_pd3dDevice->SetRenderState( D3DRS_CULLMODE, D3DCULL_NONE );
		g_pd3dDevice->SetStreamSource( 0, g_pVB, 0, sizeof(CUSTOMVERTEX) );
		g_pd3dDevice->SetFVF( D3DFVF_CUSTOMVERTEX );
		g_pd3dDevice->Clear( 0, NULL, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0,0,0), 1.0f, 0 );

		g_pEffect->SetVector( "LF",&D3DXVECTOR4(LookFrom,0));
		g_pEffect->SetVector( "g_vViewDir",&D3DXVECTOR4(N,0));
		g_pEffect->SetVector( "g_vDx",&D3DXVECTOR4(Dx,0));
		g_pEffect->SetVector( "g_vDy",&D3DXVECTOR4(Dy,0));

		// Textura x defecto
		g_pEffect->SetTexture( "g_txDef", g_pTexDef);
		g_pEffect->SetTexture( "g_txDef2", g_pTexDef2);
		g_pEffect->SetTexture( "g_txDef3", g_pTexDef3);

		// voxels 
		g_pEffect->SetTexture( "g_txVoxel", g_pTexVoxel);

		if(1)
		{
			// prueba directa
			g_pEffect->SetTechnique( "RayTracing");
			g_pEffect->SetInt("nro_R",0);
			g_pd3dDevice->Clear( 0, NULL, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0,0,0), 1.0f, 0 );
			UINT cPass;
			g_pEffect->Begin( &cPass, 0);
			g_pEffect->BeginPass( 0 );
			g_pd3dDevice->DrawPrimitive(D3DPT_TRIANGLESTRIP, 0, 2);
			g_pEffect->EndPass();
			g_pEffect->End();
		}
		else
		{
			// pipelined
			LPDIRECT3DSURFACE9 pOldRT = NULL;
			g_pd3dDevice->GetRenderTarget( 0, &pOldRT );
			LPDIRECT3DSURFACE9 pSurf;

			// Genero las direcciones de los rayos
			g_pEffect->SetTechnique( "GenerateRays");
			g_pTexRayDir->GetSurfaceLevel( 0, &pSurf );
			g_pd3dDevice->SetRenderTarget( 0, pSurf );
			UINT cPass;
			g_pEffect->Begin( &cPass, 0);
			g_pEffect->BeginPass( 0 );
			g_pd3dDevice->DrawPrimitive(D3DPT_TRIANGLESTRIP, 0, 2);
			g_pEffect->EndPass();
			g_pEffect->End();
			pSurf->Release();
			//D3DXSaveTextureToFile("test.bmp",D3DXIFF_BMP,g_pTexRayDir,NULL);


			for(int P=0;P<2;++P)
			{
				// Genero la salida sobre la textura que representa el color buffer
				g_pEffect->SetTechnique( "RayTracing");
				g_pEffect->SetInt("nro_R",P);
				LPDIRECT3DSURFACE9 pSurf2;
				g_pTexColorBufOut->GetSurfaceLevel( 0, &pSurf2 );
				g_pd3dDevice->SetRenderTarget( 0, pSurf2 );
				g_pTexRayDirOut->GetSurfaceLevel( 0, &pSurf );
				g_pd3dDevice->SetRenderTarget( 1, pSurf );
				LPDIRECT3DSURFACE9 pSurf3;
				g_pTexIpOut->GetSurfaceLevel( 0, &pSurf3 );
				g_pd3dDevice->SetRenderTarget( 2, pSurf3 );

				g_pd3dDevice->Clear( 0, NULL, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0,0,0), 1.0f, 0 );

				g_pEffect->Begin( &cPass, 0);
				g_pEffect->BeginPass( 0 );
				g_pd3dDevice->DrawPrimitive(D3DPT_TRIANGLESTRIP, 0, 2);
				g_pEffect->EndPass();
				g_pEffect->End();
				g_pd3dDevice->SetRenderTarget( 1, NULL);
				g_pd3dDevice->SetRenderTarget( 2, NULL);
				pSurf3->Release();
				pSurf2->Release();
				pSurf->Release();

				//D3DXSaveTextureToFile("test.bmp",D3DXIFF_BMP,g_pTexRayDirOut,NULL);
				//D3DXSaveTextureToFile("test2.bmp",D3DXIFF_BMP,g_pTexColorBufOut,NULL);
				//D3DXSaveTextureToFile("test3.bmp",D3DXIFF_BMP,g_pTexIpOut,NULL);


				// Swap de texturas de entrada/salida
				LPDIRECT3DTEXTURE9 aux =g_pTexColorBuf;
				g_pTexColorBuf = g_pTexColorBufOut;
				g_pTexColorBufOut = aux;

				aux =g_pTexRayDir;
				g_pTexRayDir = g_pTexRayDirOut;
				g_pTexRayDirOut = aux;

				aux =g_pTexIp;
				g_pTexIp = g_pTexIpOut;
				g_pTexIpOut = aux;

				// actualizo el cambio en el effecto
				g_pEffect->SetTexture( "g_txRayDir", g_pTexRayDir);
				g_pEffect->SetTexture( "g_txColorBuf", g_pTexColorBuf);
				g_pEffect->SetTexture( "g_txIp", g_pTexIp);
				
				// siguiente recursion de rayos

			}
				
			// Restauro el render Target
			g_pd3dDevice->SetRenderTarget( 0, pOldRT );
			// dibujo pp dicho
			g_pd3dDevice->Clear( 0, NULL, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0,0,0), 1.0f, 0 );
			g_pEffect->SetTechnique( "Draw");
			// color buffer
			g_pEffect->Begin( &cPass, 0);
			g_pEffect->BeginPass( 0 );
			g_pd3dDevice->DrawPrimitive(D3DPT_TRIANGLESTRIP, 0, 2);
			g_pEffect->EndPass();
			g_pEffect->End();
		}


		g_pd3dDevice->EndScene();
	}

    // Present the backbuffer contents to the display
    g_pd3dDevice->Present( NULL, NULL, NULL, NULL );
}




//-----------------------------------------------------------------------------
// Name: MsgProc()
// Desc: The window's message handler
//-----------------------------------------------------------------------------
LRESULT WINAPI MsgProc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
    switch( msg )
    {
        case WM_DESTROY:
            Cleanup();
            PostQuitMessage( 0 );
            return 0;
    }

    return DefWindowProc( hWnd, msg, wParam, lParam );
}




//-----------------------------------------------------------------------------
// Name: WinMain()
// Desc: The application's entry point
//-----------------------------------------------------------------------------
INT WINAPI WinMain( HINSTANCE hInst, HINSTANCE, LPSTR, INT )
{
    // Register the window class
    WNDCLASSEX wc = { sizeof(WNDCLASSEX), CS_CLASSDC, MsgProc, 0L, 0L,
                      GetModuleHandle(NULL), NULL, NULL, NULL, NULL,
                      "GPU Voxel", NULL };
    RegisterClassEx( &wc );

	float an = 0;
	float da = D3DX_PI / 16.0f;
	float dist = LookFrom.z;

    // Create the application's window
    HWND hWnd = CreateWindow( "GPU Voxel","GPU Voxel",
                              WS_OVERLAPPEDWINDOW, 0, 0, 800, 600,
                              NULL, NULL, wc.hInstance, NULL );

    // Initialize Direct3D
    if( SUCCEEDED( InitD3D( hWnd ) ) )
    {
        // Create the vertex buffer
        if( SUCCEEDED( InitVB() ) )
        {
            // Show the window
            ShowWindow( hWnd, SW_SHOWDEFAULT );
            UpdateWindow( hWnd );
			LARGE_INTEGER F,T0,T1;   // address of current frequency
			QueryPerformanceFrequency(&F);
			QueryPerformanceCounter(&T0);

            // Enter the message loop
            MSG msg;
            ZeroMemory( &msg, sizeof(msg) );
            while( msg.message!=WM_QUIT )
            {

				QueryPerformanceCounter(&T1);
				double elapsed_time = (double)(T1.LowPart - T0.LowPart) / (double)F.LowPart;
				ftime += elapsed_time;
				T0 = T1;

                if( PeekMessage( &msg, NULL, 0U, 0U, PM_REMOVE ) )
                {
                    TranslateMessage( &msg );
                    DispatchMessage( &msg );

					// proceso el mensaje
					switch(msg.message)
					{
						case WM_KEYDOWN:
							switch((int) msg.wParam)	    // virtual-key code 
							{
								case VK_LEFT:
									an-=da;
									break;
								case VK_RIGHT:
									an+=da;
									break;
								case VK_UP:
									LookFrom.y++;
									break;
								case VK_DOWN:
									LookFrom.y--;
									break;
								case 'Z':
									dist++;
									break;
								case 'W':
									dist--;
									break;
							}
							break;

					}
					LookFrom.x = dist*sin(an);
					LookFrom.z = dist*cos(an);

                }
                else
                    Render();
            }
        }
    }

    UnregisterClass( "GPU RayTracing", wc.hInstance );
    return 0;
}

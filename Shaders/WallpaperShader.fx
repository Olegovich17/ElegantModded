//--------------------------------------------------------------------------------------
// Vertex shader variables
//--------------------------------------------------------------------------------------
uniform float4x4 g_mWorld;

//--------------------------------------------------------------------------------------
// Pixel shader variables
//--------------------------------------------------------------------------------------
#define			TAU						6.28318530718
sampler2D		TextureSampler		:	register(s0);
const float2	g_fResolution		=	float2( 1280.0f, 720.0f );
uniform float	g_fXuiAlpha			=	1.0f;
const float		g_fBrightness		=	1.8f;
const int		g_nEffectValueMax	=   5;
uniform float	g_fDisplacement;
uniform float	g_fApplicationTime;

// Pixel shader defaults
//
// R  30/255 = 0.117647059
// G 230/255 = 0.901960784
// B  90/255 = 0.352941176
// S  35/ 20 = 1.75
// E       3 = 3
//
//--------------------------------------------------------------------------------------
uniform float4	g_fColorFactor		=	float4( 0.117647059f, 0.901960784f, 0.352941176f, 1.0f );
uniform float	g_fTimeScale		=	1.75f;
uniform int		g_nEffectValue		=	3;

//--------------------------------------------------------------------------------------
// Vertex shader structs
//--------------------------------------------------------------------------------------
struct VERTEX_IN {
	float4 ObjPos 	: POSITION;
	float2 Tex		: TEXCOORD0;
};

//--------------------------------------------------------------------------------------
// Pixel shader structs
//--------------------------------------------------------------------------------------
struct VERTEX_TO_PIXEL {
	float4 ProjPos	: POSITION;
	float2 Tex		: TEXCOORD0;
	float3 PosL 	: TEXCOORD1;
	float3 PosW		: TEXCOORD2;
};

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VERTEX_TO_PIXEL ShadeVertex ( VERTEX_IN In )
{
	VERTEX_TO_PIXEL Out;
	Out.ProjPos = mul( g_mWorld, In.ObjPos );
	Out.Tex = In.Tex;
	Out.PosL = In.ObjPos;
	Out.PosW = Out.ProjPos;
	return Out;
}
 
//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 ShadePixel( VERTEX_TO_PIXEL In ) : COLOR
{
	float fSpeed = 0.125f * g_fTimeScale;								// Convert the user specified time factor into a scale suitable for this shader
	int   nIter  = clamp(g_nEffectValue + 2, 2, g_nEffectValueMax + 2);		// Convert the user specified effect value into a suitable *clamped* range for this shader
    
	// Define variables used in creating effect
	float2	q		= (In.PosL.xy / g_fResolution.xy);
    float2	p		= fmod(q * TAU, TAU) - 250.0;
    float2	i		= float2(p);
    float	c		= 1.2;
    float	inten	= 0.008;
    
	// Loop once for each iteration specified (based on effect value)
    for ( int n = 0; n < nIter; n++ )  {
        float t = g_fApplicationTime * fSpeed * (1.0 - (2.5 / float(n + 1)));
        i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(float2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
    }
    
	// Calculate the final effect value
    c /= float( nIter  );
    c = 1.17 - pow( c, g_fBrightness );  
	float n = pow( abs( c ), 32.0 );
    float3 rgb = float3( n, n, n );
    
	// Blend effect color with color form TextureSampler
	float4 baseColor = tex2D( TextureSampler, In.Tex );
    
	// Apply our user specified color factor
	float4 finalColor = float4( rgb * g_fColorFactor, 0.35 ) * baseColor + baseColor;

	// Return final pixel color
	return float4( finalColor.rgb, finalColor.a * g_fXuiAlpha );
}


//--------------------------------------------------------------------------------------
// Technique - Normal - Background
//--------------------------------------------------------------------------------------
technique RenderWallpaper
{
    pass Pass0
    {
        VertexShader = compile vs_2_0 ShadeVertex();
        PixelShader  = compile ps_2_0 ShadePixel();
    }
}
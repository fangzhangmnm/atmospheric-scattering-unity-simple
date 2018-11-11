Shader "Hidden/AtmS"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		
		//R1("R1",float)=6360000
		//R2("R2",float)=6420000
		//Beta_R("Beta_R",color)=(0.0000058,0.0000135,0.0000331,1)
		//H_R("H_R",float)=8000
		//Beta_M("Beta_M",color)=(0.00002,0.00002,0.00002,1)
		//G_M("G_M",float)=0.76
		//H_M("H_M",float)=1200
		
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 worldDirection:TEXCOORD1;
				float4 vertex : SV_POSITION;
			};
			float4x4 clipToWorld;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				float4 clip=float4(o.vertex.xy,0,1);
				o.worldDirection=mul(clipToWorld,clip)-_WorldSpaceCameraPos;
				return o;
			}
			
			sampler2D_float _CameraDepthTexture;
			float4 _CameraDepthTexture_ST;
			sampler2D _MainTex;
			float R1,R2;
			float3 Beta_R;
			float H_R;
			float3 Beta_M;
			float H_M,G_M,CG_M;
			float3 lightDir;
			float3 lightColor;
			float3 groundColor;
			float scale;

			struct GeomInfo{
				float l,h1,h2;
			};
			float3 attenuation(float3 Beta,float H,GeomInfo v){
				//if(v.h1<0)v.h1=0;
				//if(v.h2<0)v.h2=0;
				if(abs(v.h1-v.h2)>0.001*H)
					//return Beta*v.l*exp(-hm2H)*sinh(dh2H)/dh2H;
					return Beta*v.l*H/(v.h2-v.h1)*(exp(-v.h1/H)-exp(-v.h2/H));
				else
					return Beta*v.l*exp(-(v.h1+v.h2)/2/H);
			}
			GeomInfo getGeom(float R1,float R2,float camy,float wy){
				if(camy<0)camy=0;
				float R1y=R1+camy;
				float R1ywy=R1y*wy;
				GeomInfo rtval;
				if(R1y<R2){
					rtval.l=sqrt(R1ywy*R1ywy+R2*R2-R1y*R1y)-R1ywy;
					rtval.h1=camy;
					rtval.h2=R2-R1;
				}else{
					rtval.l=2*sqrt(R1ywy*R1ywy+R2*R2-R1y*R1y);
					rtval.h1=rtval.h2=R2-R1;
					if(isnan(rtval.l)|| wy>0)
						rtval.l=0;
				}
				return rtval;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				float depth0=SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv.xy);
				float depth=LinearEyeDepth(depth0)*scale;
				float3 worldspace=i.worldDirection*depth+_WorldSpaceCameraPos;
				
				float mu=-dot(lightDir,normalize(i.worldDirection.xyz));
				float mu2=-normalize(i.worldDirection.xyz).y;
				float vy=i.worldDirection.y/length(i.worldDirection);
				float ly=-lightDir.y/length(lightDir);
				float camy=_WorldSpaceCameraPos.y*scale;
				if(camy<0)camy=0;
				GeomInfo v=getGeom(R1,R2,camy,vy);
				GeomInfo l=getGeom(R1,R2,camy,ly);
				if(v.l>depth && depth0>0){
					v.l=depth;
					v.h2=worldspace.y;
				}


				float4 rtval = tex2D(_MainTex, i.uv);
				if(depth0==0)rtval.xyz=0;
				float P_R=(1+mu*mu)*0.059683;
				float P_M=CG_M*(1+mu*mu)*pow(1+G_M*(G_M-2*mu),-1.5);
				float P_R2=(1+mu2*mu2)*0.059683;
				float P_M2=CG_M*(1+mu2*mu2)*pow(1+G_M*(G_M-2*mu2),-1.5);
				int n=3;
				for(int i=n-1;i>=0;--i){
					GeomInfo seg;
					seg.l=v.l/n;
					seg.h1=v.h1+(v.h2-v.h1)/n*i;
					seg.h2=v.h1+(v.h2-v.h1)/n*(i+1);
					float hm=(seg.h1+seg.h2)/2;
					GeomInfo lp=getGeom(R1,R2,hm,ly);
					rtval.xyz*=exp(-(attenuation(Beta_R,H_R,seg)+attenuation(Beta_M,H_M,seg)));
					rtval.xyz+=lightColor*seg.l*(P_R*Beta_R*exp(-hm/H_R)+P_M*Beta_M*exp(-hm/H_M))
					*exp(-(attenuation(Beta_R,H_R,lp)+attenuation(Beta_M,H_M,lp)));
					rtval.xyz+=groundColor*seg.l*(P_R2*Beta_R*exp(-hm/H_R)+P_M2*Beta_M*exp(-hm/H_M));
					
				}
				return rtval;
			}
			ENDCG
		}
	}
}

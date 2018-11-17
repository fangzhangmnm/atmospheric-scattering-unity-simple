using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
[ImageEffectAllowedInSceneView]
public class AtmS : MonoBehaviour {
	public Light sun;
	public Color sunColor=new Color(1,1,1,1);
	public float sunIntensity=1;
	public Color groundColor=new Color(1,1,1,1);
	public float groundIntensity=1;
	public float scale=10;
	public float R1=6360000,R2=6420000;
	public Vector4 Beta_R=new Vector4(5.8f,13.6f,33.1f,1e6f)*1e-6f;
	public float H_R=8000;
	public Vector4 Beta_M=new Vector4(2,2,2,1e5f)*1e-5f;
	public float H_M=1200,G_M=0.76f;
	Material material;
	void Awake(){
		material=new Material(Shader.Find("Hidden/AtmS"));
	}
	void Start(){
	}
	void OnRenderImage(RenderTexture source,RenderTexture destination){
		Camera camera=Camera.current;
		//https://gamedev.stackexchange.com/questions/131978/shader-reconstructing-position-from-depth-in-vr-through-projection-matrix
		var p = GL.GetGPUProjectionMatrix(camera.projectionMatrix, !camera.forceIntoRenderTexture || camera.stereoEnabled);// Unity flips its 'Y' vector depending on if its in VR, Editor view or game view etc... (facepalm)
		p[2, 3] = p[3, 2] = 0.0f;
		p[3, 3] = 1.0f;
		var clipToWorld = Matrix4x4.Inverse(p * camera.worldToCameraMatrix) * Matrix4x4.TRS(new Vector3(0, 0, -p[2,2]), Quaternion.identity, Vector3.one);
		material.SetMatrix("clipToWorld", clipToWorld);
		material.SetFloat("R1",R1);
		material.SetFloat("R2",R2);
		material.SetFloat("H_R",H_R);
		material.SetFloat("H_M",H_M);
		material.SetFloat("G_M",G_M);
		material.SetFloat("CG_M",0.119366f*(1-G_M*G_M)/(2+G_M*G_M));
		material.SetVector("Beta_R",Beta_R*Beta_R.w);
		material.SetVector("Beta_M",Beta_M*Beta_M.w);
		material.SetFloat("scale",scale);
		if(sun){
			material.SetVector("lightDir",sun.transform.forward.normalized);
		}
		material.SetVector("lightColor",sunColor*sunIntensity);
		material.SetVector("groundColor",groundColor*groundIntensity);
		Graphics.Blit(source,destination,material);
	}
}

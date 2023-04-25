using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CollisionCamera : MonoBehaviour
{
    [SerializeField] ModelGrass modelGrassScript;
    float grassHeight = 0;
    public Shader replacementShader;

    Camera cam;

    private void OnEnable()
    {
        cam = GetComponent<Camera>();
        if (replacementShader != null)
        {
            cam.SetReplacementShader(replacementShader, "");
        }
    }

    private void Start()
    {
        grassHeight = calculateHrassHeight(modelGrassScript.grassMesh);
    }

    private void Update()
    {

        Vector3 position = new Vector3(transform.position.x, transform.position.y, transform.position.z);
        Vector2 nearFarPlane = new Vector2(cam.nearClipPlane, cam.farClipPlane);



        Shader.SetGlobalFloat("_CollisionShader_GrassHeight", grassHeight);
        Shader.SetGlobalVector("_CollisionShader_TexturePos", position);
        Shader.SetGlobalFloat("_TextureWidth", cam.orthographicSize * 2);
        Shader.SetGlobalFloat("_CollisionShader_DepthTex", cam.orthographicSize * 2);
        Shader.SetGlobalVector("_CollisionShader_NearFarPlane", nearFarPlane);
        
    }

    private void OnDisable()
    {
        cam.ResetReplacementShader();
    }

    float calculateHrassHeight(Mesh grassMesh)
    {
        GameObject temp = new GameObject();
        temp.name = "cositas";
        temp.AddComponent<MeshRenderer>();
        temp.AddComponent<MeshFilter>();
        temp.GetComponent<MeshFilter>().mesh = grassMesh;
        temp.AddComponent<BoxCollider>();

        Vector3 size = temp.GetComponent<BoxCollider>().bounds.size;
        float grassHeight = 0;
        if (size.x >= size.y && size.x >= size.z)
            grassHeight = size.x;
        if (size.y >= size.x && size.y >= size.z)
            grassHeight = size.y;
        if (size.z >= size.y && size.z >= size.x)
            grassHeight = size.z;

        DestroyImmediate(temp);

        return grassHeight;
    }
}

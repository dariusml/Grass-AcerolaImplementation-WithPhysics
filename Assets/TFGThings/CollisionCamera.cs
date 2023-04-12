using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CollisionCamera : MonoBehaviour
{
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

    private void Update()
    {
        Vector2 position = new Vector2(transform.position.x, transform.position.z);
        Shader.SetGlobalVector("_TexturePos", position);
        Shader.SetGlobalFloat("_TextureWidth", cam.orthographicSize * 2);
    }

    private void OnDisable()
    {
        cam.ResetReplacementShader();
    }
}

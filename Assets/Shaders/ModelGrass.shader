Shader "Unlit/ModelGrass" {
    Properties {
        _Albedo1 ("Albedo 1", Color) = (1, 1, 1)
        _Albedo2 ("Albedo 2", Color) = (1, 1, 1)
        _AOColor ("Ambient Occlusion", Color) = (1, 1, 1)
        _TipColor ("Tip Color", Color) = (1, 1, 1)
        _Scale ("Scale", Range(0.0, 2.0)) = 0.0
        _Droop ("Droop", Range(0.0, 10.0)) = 0.0
        _FogColor ("Fog Color", Color) = (1, 1, 1)
        _FogDensity ("Fog Density", Range(0.0, 1.0)) = 0.0
        _FogOffset ("Fog Offset", Range(0.0, 10.0)) = 0.0


        //New properties for collision
        _CollisionDepthTex ("TextureCollision", 2D) = "white" {}
        //_TexturePos("TexturePos", Vector) = (0,0,0,0)
        //_TextureWidth("TextureWidth", float) = 8
    }

    SubShader {
        Cull Off
        Zwrite On

        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma target 4.5

            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"
            #include "../Resources/Random.cginc"

            struct VertexData {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float noiseVal : TEXCOORD2;
                float3 chunkNum : TEXCOORD3;

                //DARIO
                float4 rootPos : TEXCOORD4;
            };

            struct GrassData {
                float4 position;
                float2 uv;
                float displacement;
            };

            sampler2D _WindTex;
            float4 _Albedo1, _Albedo2, _AOColor, _TipColor, _FogColor;
            StructuredBuffer<GrassData> positionBuffer;
            float _Scale, _Droop, _FogDensity, _FogOffset;

            int _ChunkNum;

            ////////////////////////
            //COLLISION PARAMETERS//
            ////////////////////////
            sampler2D _CollisionDepthTex;
            float4 _CollisionDepthTex_ST;


            uniform float3 _CollisionShader_TexturePos;
            uniform float2 _CollisionShader_NearFarPlane;
            uniform float _TextureWidth;
            uniform float _CollisionShader_GrassHeight;
            uniform sampler2D _CollisionShader_DepthTex;



            float4 RotateAroundYInDegrees (float4 vertex, float degrees) {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float4(mul(m, vertex.xz), vertex.yw).xzyw;
            }
            
            float4 RotateAroundXInDegrees (float4 vertex, float degrees) {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float4(mul(m, vertex.yz), vertex.xw).zxyw;
            }

            float yWorldPosition(float normalizedDistance)
            {
                float cameraDepth = _CollisionShader_NearFarPlane.y - _CollisionShader_NearFarPlane.x;
                float distanceToCamera = cameraDepth * (1-normalizedDistance) + _CollisionShader_NearFarPlane.x;

                float yPos = distanceToCamera + _CollisionShader_TexturePos.y;
                return yPos;
            }

            //float4 value that represents the plane equation in the form (a, b, c, d), where (a, b, c) is the normal vector of the plane and d is the distance from the origin to the plane.
            float4 PlaneFromPointAndNormal(float3 pointOfPlane, float3 normal)
            {
                float d = dot(-normal, pointOfPlane);
                return float4(normal, d);
            }
            float4 PlaneFromDirectionsAndPoint(float3 dir1, float3 dir2, float3 pointOfPlane)
            {
                float3 normal = normalize(cross(dir1, dir2));
                float d = -dot(normal, pointOfPlane);
                return float4(normal, d);
            }

            v2f vert (VertexData v, uint instanceID : SV_INSTANCEID) {
                v2f o;
                float4 grassPosition = positionBuffer[instanceID].position;

                float idHash = randValue(abs(grassPosition.x * 10000 + grassPosition.y * 100 + grassPosition.z * 0.05f + 2));
                idHash = randValue(idHash * 100000);


                float4 animationDirection = float4(0.0f, 0.0f, 1.0f, 0.0f);
                animationDirection = normalize(RotateAroundYInDegrees(animationDirection, idHash * 180.0f));  


                //LOCAL POSITION//

                //Lo gira pork el modelado esta mal
                float4 localPosition = RotateAroundXInDegrees(v.vertex, 90.0f);
                localPosition = RotateAroundYInDegrees(localPosition, idHash * 180.0f);//Giro para añadir variedad
                //Height displacement
                localPosition.y += _Scale * v.uv.y * v.uv.y * v.uv.y;
                //Parece que cambia la X dependiendo de la altura de la hierba, a mas altura mas lo cambia
                localPosition.xz += _Droop * lerp(0.5f, 1.0f, idHash) * (v.uv.y * v.uv.y * _Scale) * animationDirection;


                float4 worldUV = float4(positionBuffer[instanceID].uv, 0, 0);
                

                //DARIO
                o.rootPos = grassPosition;
                //DARIO


                float swayVariance = lerp(0.8, 1.0, idHash);
                float movement = v.uv.y * v.uv.y * (tex2Dlod(_WindTex, worldUV).r);
                movement *= swayVariance;
                
                localPosition.xz += movement;
                

                ///////////////////////////////////
                ///////                   /////////
                ///////   EXPERIMENTOS    /////////
                ///////                   /////////


                float2 grassPos = grassPosition.xz;

                float2 relativeToCamaraPos = grassPos - _CollisionShader_TexturePos.xz;

                float2 normalizedGrassCoord = relativeToCamaraPos/_TextureWidth  + float2(0.5,0.5);

                float4 uvToPick = float4(normalizedGrassCoord.x, 1 - normalizedGrassCoord.y,0,0);

                float4 currenPixelColor = tex2Dlod(_CollisionDepthTex,uvToPick);


                float3 worldNormalVector = normalize( currenPixelColor.xyz * 2 - float3(1,1,1) );
                float Ypos = yWorldPosition(currenPixelColor.a);

                //IS even a tiny part INSIDE??
                float grassInside = 1 - step(grassPosition.y + _CollisionShader_GrassHeight, Ypos);





                float4 insideLocalPos = 0;



                ////////////////////////////////////////////////////////////
                ////////   GRASS COLLISIONED VERTEX TRANSFORM    ///////////
                ////////////////////////////////////////////////////////////

                //
                //Plane of collision point orthogonal to normal direction
                //
                float3 planePoint = float3(grassPosition.x,Ypos,grassPosition.z);

                float4 collisionOrthogonalPlane = PlaneFromPointAndNormal(planePoint,worldNormalVector);
                //
                //plane up(0,1,0) and normal vector
                //
                float4 grassDeformationPlane = PlaneFromDirectionsAndPoint(float3(0,1,0), worldNormalVector, grassPosition.xyz)

                


                // normalize the resulting vector if needed
                //ortho = normalize(ortho);



                localPosition = lerp(localPosition, insideLocalPos, grassInside);




                ///////                   /////////
                ///////   EXPERIMENTOS    /////////
                ///////                   /////////
                ///////////////////////////////////


                float4 worldPosition = float4(grassPosition.xyz + localPosition, 1.0f);

                worldPosition.y -= positionBuffer[instanceID].displacement;
                worldPosition.y *= 1.0f + positionBuffer[instanceID].position.w * lerp(0.8f, 1.0f, idHash);
                worldPosition.y += positionBuffer[instanceID].displacement;




                o.vertex = UnityObjectToClipPos(worldPosition);
                o.uv = v.uv;
                o.noiseVal = tex2Dlod(_WindTex, worldUV).r;
                o.worldPos = worldPosition;
                o.chunkNum = float3(randValue(_ChunkNum * 20 + 1024), randValue(randValue(_ChunkNum) * 10 + 2048), randValue(_ChunkNum * 4 + 4096));



                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float4 col = lerp(_Albedo1, _Albedo2, i.uv.y);
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float ndotl = DotClamped(lightDir, normalize(float3(0, 1, 0)));

                float4 ao = lerp(_AOColor, 1.0f, i.uv.y);
                float4 tip = lerp(0.0f, _TipColor, i.uv.y * i.uv.y * (1.0f + _Scale));
                //return fixed4(i.chunkNum, 1.0f);
                //return i.noiseVal;

                float4 grassColor = (col + tip) * ndotl * ao;

                /* Fog */
                float viewDistance = length(_WorldSpaceCameraPos - i.worldPos);
                float fogFactor = (_FogDensity / sqrt(log(2))) * (max(0.0f, viewDistance - _FogOffset));
                fogFactor = exp2(-fogFactor * fogFactor);



                //return lerp(_FogColor, grassColor, fogFactor);


                //
                //EXPERIMENTOS
                //


                //Consigo el color que le corresponde a la hierba dependiendo de la posicion de la hoja

                float2 grassPos = i.rootPos.xz;

                float2 relativeToCamaraPos = grassPos - _CollisionShader_TexturePos.xz;

                float2 normalizedGrassCoord = relativeToCamaraPos/_TextureWidth  + float2(0.5,0.5);

                float2 uvToPick = float2(normalizedGrassCoord.x, 1 - normalizedGrassCoord.y);

                float4 currenPixelColor = tex2D(_CollisionDepthTex,uvToPick);

                fixed4 color1 = currenPixelColor;
                fixed4 color2 = fixed4(uvToPick.xy,0,1);

                //if(_CollisionShader_GrassHeight >  i.rootPos.y)

                //color1 = fixed4(color1.a,color1.a,color1.a,color1.a);


                float Ypos = yWorldPosition(currenPixelColor.a);
                float inside = step(i.rootPos.y + _CollisionShader_GrassHeight, Ypos);
                color1 = fixed4(inside,inside,inside,inside);

                return color1;
            }







            ENDCG
        }
    }
}

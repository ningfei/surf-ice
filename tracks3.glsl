//pref
Ambient|float|0.0|0|1
Diffuse|float|0.0|1|2
Specular|float|0.0|0.25|1
SpecularRough|float|0.01|0.05|1
Edge|float|0|0.05|1.0
//vert
#version 330
#define M_PI 3.1415926535897932384626433832795
layout(location = 0) in vec3 Vert;
layout(location = 3) in vec4 Norm;
layout(location = 6) in vec4 Clr;
uniform mat4 ModelViewProjectionMatrix;
uniform mat4 ModelViewMatrix;
uniform mat4 ProjectionMatrix;
uniform float Radius;
uniform mat3 NormalMatrix;
uniform vec3 LightPos = vec3(0.0, 20.0, 30.0); //LR, -DU+, -FN+
out vec4 vClr;
out vec4 vP;
out vec3 vN;
out float TextCordCylinder;
out vec2 TextCordEnd;
out float fType;
out vec3 vLightPos;
out mat3 Rot;
out float RotInversion;

out vec3 SimN;


//http://math.stackexchange.com/questions/180418/calculate-rotation-matrix-to-align-vector-a-to-vector-b-in-3d
//http://math.stackexchange.com/questions/293116/rotating-one-3d-vector-to-another
//https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
mat3 AlignVectors(vec3 FromVector,vec3 ToVector, inout float Inversion){
	vec3 v = cross(FromVector,ToVector);
	float E = M_PI/2.0;
	float s = length(v);
	float c = dot(FromVector,ToVector);
	float ang = acos(c);

	if((M_PI-ang)<E){
		Inversion=-1.0;
	}
	 
	mat3 vX;
	vX[0] = vec3(0,v[2],-v[1]);
	vX[1] = vec3(-v[2],0,v[0]);
	vX[2] = vec3(v[1],-v[0],0);
	
	mat3 final = mat3(1.0)+vX+vX*vX*(1-c)/s*s*s*s;

	return final;
}


float angle(vec3 a,vec3 b){
	float c = dot(a,b);
	return acos(c);
}

void main() {
	float rScale = 0.001; //0.001
	float vType = Norm.a;
	vec3 VectorPoints = normalize(NormalMatrix*Norm.xyz);
	vec4 VertexPosition = ModelViewMatrix*vec4(Vert, 1.0);
	vec3 vecCameraPoint = vec3(0,0,1);//normalize(vec3(0.0,0.0,1000.0)-VertexPosition.xyz);
	vec4 VectorBillboard = normalize(vec4(cross(VectorPoints, vecCameraPoint),0.0));
	float kind = mod(gl_VertexID,2);
	
	float inversion = 1.0;
	
	
	
	
	if(vType==0.0){//Part of the Track Cylinders
		VectorBillboard = VectorBillboard*Radius*rScale;
		
		Rot=AlignVectors(vec3(0.0,-1.0,0.0),VectorPoints,inversion);
		
		
		if(kind==0.0){
			VertexPosition = VertexPosition-VectorBillboard;
			TextCordCylinder = 0.0;
			SimN=normalize(-VectorBillboard.xyz);
		}else{
			VertexPosition = VertexPosition+VectorBillboard;
			TextCordCylinder = 1.0;
			SimN=normalize(VectorBillboard.xyz);
		}

	}else if(vType==1.0){//It is end of track
		vec4 VectorEndBillboard = normalize(vec4(cross(VectorBillboard.xyz,VectorPoints.xyz),0.0))*Radius*rScale;
		
		Rot=AlignVectors(vec3(0.0,1.0,0.0),VectorBillboard.xyz,inversion);
		SimN=normalize(VectorPoints.xyz);
		
		VectorBillboard = VectorBillboard*Radius*rScale;
		if(kind==0.0){
			VertexPosition = VertexPosition-VectorBillboard+VectorEndBillboard;
			TextCordEnd = vec2(1.0,0.0);
		}else{
			VertexPosition = VertexPosition+VectorBillboard+VectorEndBillboard;
			TextCordEnd = vec2(1.0,1.0);
		}
	}else if(vType==-2.0){
		vec4 VectorEndBillboard = normalize(vec4(cross(VectorBillboard.xyz,VectorPoints.xyz),0.0))*Radius*rScale;
		
		Rot=AlignVectors(vec3(0.0,1.0,0.0),VectorBillboard.xyz,inversion);
		SimN=normalize(VectorPoints.xyz);
		
		VectorBillboard = VectorBillboard*Radius*rScale;
		if(kind==0.0){
			VertexPosition = VertexPosition-VectorBillboard-VectorEndBillboard;
			TextCordEnd = vec2(0.0,0.0);
		}else{
			VertexPosition = VertexPosition+VectorBillboard-VectorEndBillboard;
			TextCordEnd = vec2(0.0,1.0);
		}
	}else{
		vClr=vec4(0.0,0.0,0.0,1.0);
	}
	
	RotInversion = inversion;
	fType = vType;
	vClr = Clr;
	vP = ProjectionMatrix*VertexPosition;
	gl_Position = vP;
    vN = normalize((NormalMatrix * Norm.xyz));
	vLightPos=LightPos;
	
	
}

//frag
#version 330
in vec4 vClr;
in vec3 vN;
in vec4 vP;
in float TextCordCylinder;
in float fType;
in vec2 TextCordEnd;
in vec3 vLightPos;
in mat3 Rot;
in vec3 SimN;
in float RotInversion;

uniform sampler1D normalmaptexture;
uniform sampler2D normalmaptexturesphere;
uniform float Ambient = 0.2;
uniform float Diffuse = 0.8;
uniform float Specular = 0.5;
uniform float Shininess = 60.0;
uniform float Edge = 0.5;
uniform float SpecularRough = 0.05;

out vec4 color;



void main() {
	vec4 N;
	
	vec3 NN;
	
	if(fType==0.0){
		N = texture(normalmaptexture  , TextCordCylinder);
		NN =  Rot*(2.0*N.xyz-1.0);
	}else{
		N = texture(normalmaptexturesphere  , TextCordEnd);
		if(N.a==0.0)discard;
		NN =  Rot*(2.0*N.xyz-1.0);
	}
	
	vec3 SupX = Rot*vec3(0.0,0.0,N.z);
	vec3 SupY = RotInversion*Rot*vec3(0.0,0.0,N.z);
			
	NN.x = SupX.x+SimN.x;
	NN.y = max(0.0,SupY.y) + SimN.y;
	NN.z = NN.z;
	
	vec3 difClr = vClr.rgb;
	//vec3 difClr = vec3(1.0, 1.0, 1.0);

	vec3 ambClr = vClr.rgb;
	//vec3 L = normalize(vLightPos);
	vec3 L = normalize(vLightPos);
	//L.rgb = L.rbg;
	//L.r = L.r;
	//L.gb = L.bg;

	//vec3 L = normalize(vec3(0.0, 0.2, 0.5));
	vec3 n = NN;
	float NormalSpec = pow(max(0.0,dot(vN,L)),Shininess);
	//float BillboardSpec = pow(dot(N.xyz,L),Shininess)*Specular;
	//float BillboardSpec = pow(max(0.0,dot(N.xyz,L)), Shininess) * Specular;
	float dif = max(0.0,dot(n,L)) * Diffuse;
	//vec3 h = normalize(vec3(0.0, 0.35, 0.5)); //half vector between light and viewer
	float s = pow(max(0.0,dot(n,L)), 10.0) * Specular;
	color = vec4(s + difClr*dif + Ambient*ambClr , 1.0);
	//color = vec4(difClr*dif + Ambient*ambClr, 1.0);
	//color = vec4(difClr*dx , 1.0);
	//color = vec4(NN,1.0);

	//color = vec4(NormalSpec*BillboardSpec*specClr + difClr*dif + Ambient*ambClr , 1.0);
}

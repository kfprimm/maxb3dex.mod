
Strict

Import MaxB3D.Drivers
Import MaxB3DEx.Lightmapper

GLGraphics3D 800,600
SetAmbientLight 50, 50, 50

Local light:TLight = CreateLight()
SetEntityRotation(light, 45, 30, 0)
''SetLightRange light,3

Local camera:TCamera = CreateCamera()
SetEntityPosition camera, 17, 18, 18
SetEntityColor camera,0,0,255

Local cube1:TMesh = CreateCube()
FlipMesh cube1
PositionMesh cube1, 0, 1.0, 0
SetEntityScale cube1, 20, 5, 20
SetEntityPickMode cube1, PICKMODE_POLYGON
SetEntityName cube1, "cube1"

Local cube2:TMesh = CreateCylinder()
PositionMesh cube2, 0, 1, 0
SetEntityScale cube2, 2, 2, 2
SetEntityPickMode cube2, PICKMODE_POLYGON
SetEntityName cube2, "cube2"
'SetEntityAlpha cube2,.5
SetEntityColor cube2,255,0,0

PointEntity camera, cube1

Local lightmapper:TLightmapper = New TLightmapper
lightmapper.SetAmbient 40, 40, 40
lightmapper.AddLight -8, 3, -8, 219, 219, 255, 0, True, 3
lightmapper.AddLight  8, 3,  3, 255, 255, 219, 0, True, 3

lightmapper.AddObscurer cube1
lightmapper.AddObscurer cube2

Local oldtime = MilliSecs()

While Not KeyHit(KEY_ESCAPE)
	Local Time = MilliSecs()
	Local DeltaTime# = Float(Time - OldTime) / 1000   ' in seconds
	OldTime% = Time
	
	' Camera movement
	Local CamSpd# = 10 * DeltaTime
	MoveEntity(camera, Float(KeyDown(KEY_RIGHT) - KeyDown(KEY_LEFT)) * CamSpd, 0, Float(KeyDown(KEY_UP) - KeyDown(KEY_DOWN)) * CamSpd)
	
	If MouseDown(2)
		Local TurnSpeed# = 0.8
		TurnEntity(camera, Float(MouseYSpeed())  * TurnSpeed#, 0, 0, False)
		TurnEntity(camera, 0, -Float(MouseXSpeed()) * TurnSpeed#, 0, True)
	Else
		MouseXSpeed()
		MouseYSpeed()
	EndIf
	
	Local info:TPick, ent:TEntity
	
	If MouseHit(1)
		info = WorldPick(camera, [Float(MouseX()), Float(MouseY())])
		If info ent:TEntity = info.Entity
		If ent
			Local pixmap:TPixmap = lightmapper.Run(ent, 0.2, 2)
			SavePixmapJPeg pixmap, GetEntityName(ent)+"_lm.jpg"
			SetEntityTexture ent,LoadTexture(pixmap)
			'SetEntityPickMode(cube1, 0)
			Rem
			BeginLightMap(40, 40, 40)
			
			CreateLMLight( -8, 3, -8, 219, 219, 255, 0, True, 3)
			CreateLMLight(  8, 3,  3, 255, 255, 219, 0, True, 3)
			
			'(mesh, lumelsize# = 0.5, maxmapsize = 1024, blurradius = 1, TotalInfo$ = "")
			tex = LightMapMesh(ent, 0.25, 1024, 1, "Lightmapping " + EntityName(ent))
			
			'tex = LightMapMesh(ent, 0.25, 1024, 1, "Lightmapping " + EntityName(ent))
			
			If tex
			'	SaveLightMap(ent, tex, EntityName(ent) + "_lm.bmp", EntityName(ent) + ".luv")
			'	ApplyLightMap(ent, tex)
			EndIf
			
			EndLightMap()
			End Rem
			'SetEntityPickMode(cube1, 2)
		
		EndIf
	EndIf
	
	If KeyHit(KEY_F2) '  F2 key
		info = WorldPick(camera, [Float(MouseX()), Float(MouseY())])
		If info ent = info.Entity
		If ent
		'	LoadLightMap(ent, GetEntityName(ent) + "_lm.bmp", GetEntityName(ent) + ".luv")
		EndIf
	EndIf
	
	UpdateWorld()
	
	RenderWorld()
	DoMax2D
	
	info = WorldPick(camera, [Float(MouseX()), Float(MouseY())])
	If info DrawText GetEntityName(info.Entity),0,0
	
	Flip False
Wend


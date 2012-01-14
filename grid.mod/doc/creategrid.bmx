
Strict

Import MaxB3D.Drivers

Import MaxB3DEx.Grid
Import MaxB3DEx.GLGrid
Import MaxB3DEx.D3D9Grid

Graphics 800,600

Local camera:TCamera=CreateCamera()
SetEntityPosition camera,0,0,-20

Local light:TLight=CreateLight()
SetEntityRotation light,90,0,0

Local grid:TGrid=CreateGrid(10,10)
SetEntityFX grid,FX_FULLBRIGHT
SetEntityColor grid,255,0,0

While Not KeyDown( KEY_ESCAPE ) And Not AppTerminate()
	TurnEntity grid,.5,0,0
	RenderWorld
	Flip
Wend
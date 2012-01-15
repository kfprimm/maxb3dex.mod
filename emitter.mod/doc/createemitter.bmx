
Strict

Import MaxB3D.Drivers

Import MaxB3DEx.Emitter
Import MaxB3DEx.GLEmitter
Import MaxB3DEx.D3D9Emitter

Graphics 800,600
SeedRnd MilliSecs()

Local light:TLight = CreateLight()

Local pivot:TPivot = CreatePivot()

Local camera:TCamera = CreateCamera(pivot)
SetEntityPosition camera,0,7,-10

Local brush:TBrush = CreateBrush("particle1.png")
SetBrushBlend brush, BLEND_ADD

Local cone:TMesh = CreateCone()

Local flame:TEmitter = CreateEmitter(cone)
SetEntityPosition flame,0,1,0
SetEntityBrush flame,brush

SetEmitterRate flame, 1
SetEmitterLife flame, 40, 60
SetEmitterGradient flame,254,0,0,254,254,0
SetEmitterVelocity flame,-.01,0.1,-.01,.01,.1,.01

Local smoke:TEmitter = CreateEmitter(flame)
SetEntityPosition smoke,0,2,0
SetEntityBrush smoke,brush

SetEmitterRate smoke, 15
SetEmitterLife smoke, 200, 500
SetEmitterGradient smoke,230,230,230,100,100,100
SetEmitterVelocity smoke,-.02,.05,-.02,.02,.05,.02
SetEmitterScaling smoke,4,5

PointEntity camera, flame

While Not KeyDown(KEY_ESCAPE) And Not AppTerminate()
	TurnEntity pivot,0,1,0
	If Not KeyDown(KEY_SPACE) UpdateWorld
	Local info:TRenderInfo = RenderWorld()
	DoMax2D
	DrawText "FPS: "+info.FPS,0,0
	DrawText "Particles: "+(GetEmitterCount(flame)+GetEmitterCount(smoke)),0,15
	Flip
Wend
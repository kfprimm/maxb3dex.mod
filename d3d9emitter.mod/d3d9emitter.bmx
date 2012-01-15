
Strict

Rem
	bbdoc: Provides a D3D9 renderer for TEmitter
End Rem
Module MaxB3DEx.D3D9Emitter
ModuleInfo "Author: Kevin Primm"
ModuleInfo "License: MIT"

Import MaxB3DEx.Emitter
Import MaxB3D.D3D9Driver

?Win32

Type TD3D9EmitterRenderer Extends TCustomRenderer	
	Method Render(entity:TEntity, driver:TMaxB3DDriver)
		Local emitter:TEmitter = TEmitter(entity), d3ddev:IDirect3DDevice9 = TD3D9MaxB3DDriver(driver)._d3ddev

		d3ddev.SetVertexDeclaration Null
		d3ddev.SetFVF D3DFVF_XYZ|D3DFVF_PSIZE|D3DFVF_DIFFUSE
		
		d3ddev.SetRenderState D3DRS_POINTSPRITEENABLE, True   
		d3ddev.SetRenderState D3DRS_POINTSCALEENABLE, True  
		
		Local size# = 2.0, size_min# = 1.0, a# = 0.0, b# = 0.0, c# = 2
		d3ddev.SetRenderState D3DRS_POINTSIZE, Int Ptr(Varptr size)[0]
		d3ddev.SetRenderState D3DRS_POINTSIZE_MIN, Int Ptr(Varptr size_min)[0]
		d3ddev.SetRenderState D3DRS_POINTSCALE_A, Int Ptr(Varptr a)[0]
		d3ddev.SetRenderState D3DRS_POINTSCALE_B, Int Ptr(Varptr b)[0]
		d3ddev.SetRenderState D3DRS_POINTSCALE_C, Int Ptr(Varptr c)[0]
		
		d3ddev.DrawPrimitiveUP D3DPT_POINTLIST,emitter._particles.length/TEmitter.COUNT,emitter._particles,TEmitter.COUNT*4

		d3ddev.SetRenderState D3DRS_POINTSPRITEENABLE, False
		d3ddev.SetRenderState D3DRS_POINTSCALEENABLE, False
	End Method
End Type
TCustomEntity.Register TEmitter.Name(), "d3d9", New TD3D9EmitterRenderer

?




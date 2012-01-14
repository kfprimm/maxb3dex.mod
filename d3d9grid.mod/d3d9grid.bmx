
Strict

Rem
	bbdoc: Provides a D3D9 renderer for TGrid
End Rem
Module MaxB3DEx.D3D9Grid
ModuleInfo "Author: Kevin Primm"
ModuleInfo "License: MIT"

Import MaxB3DEx.Grid
Import MaxB3D.D3D9Driver

?Win32

Type TD3D9GridRenderer Extends TCustomRenderer
	Method Render(entity:TEntity, driver:TMaxB3DDriver)
		Local grid:TGrid = TGrid(entity), d3ddev:IDirect3DDevice9 = TD3D9MaxB3DDriver(driver)._d3ddev

		d3ddev.SetVertexDeclaration Null
		d3ddev.SetFVF D3DFVF_XYZ
		
		Local line#[6]
		For Local x=0 To grid._rows	
			line[0] = x;line[1] = 0;line[2] = 0;
			line[3] = x;line[4] = grid._rows;line[5] = 0
			d3ddev.DrawPrimitiveUP D3DPT_LINELIST,2,line,12
		Next
		For Local y=0 To grid._columns
			line[0] = 0;line[1] = y;line[2] = 0;
			line[3] = grid._columns;line[4] = y;line[5] = 0
			d3ddev.DrawPrimitiveUP D3DPT_LINELIST,2,line,12
		Next
	End Method
End Type
TCustomEntity.Register TGrid.Name(), "d3d9", New TD3D9GridRenderer

?
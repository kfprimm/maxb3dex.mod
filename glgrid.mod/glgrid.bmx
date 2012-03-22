
Strict

Rem
	bbdoc: Provides a GL renderer for TGrid
End Rem
Module MaxB3DEx.GLGrid
ModuleInfo "Author: Kevin Primm"
ModuleInfo "License: MIT"

Import MaxB3DEx.Grid
Import MaxB3D.GLDriver

Function glDrawGrid(rows#,columns#,size#)
	glBegin GL_LINES		
	glNormal3f 0,0,1	
	For Local x=0 To rows
		glVertex2f x*size,0
		glVertex2f x*size,rows*size
	Next
	For Local y=0 To columns
		glVertex2f 0,y*size
		glVertex2f columns*size,y*size
	Next
	glEnd
End Function

Type TGLGridRenderer Extends TCustomRenderer
	Method Render(entity:TEntity, driver:TMaxB3DDriver)
		Local grid:TGrid = TGrid(entity)
		glDrawGrid grid._columns, grid._rows,1.0
	End Method
End Type
TCustomEntity.Register TGrid.Name(), "gl", New TGLGridRenderer





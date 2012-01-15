
Strict

Rem
	bbdoc: Custom grid entity
End Rem
Module MaxB3DEx.Grid
ModuleInfo "Author: Kevin Primm"
ModuleInfo "License: MIT"

Import MaxB3D.GLDriver
Import MaxB3D.D3D9Driver

Type TGrid Extends TCustomEntity
	Field _columns, _rows
	
	Method GetSize(columns Var, rows Var)
		columns = _columns
		rows = _rows
	End Method	
	Method SetSize(columns, rows)
		_columns = columns
		_rows = rows
	End Method
	
	Method GetCullRadius#()
		Local sx#,sy#,sz#
		GetScale sx,sy,sz,True
		Local size# = Max(_columns,_rows)*Max(Max(sx,sy),sz)
		Return Sqr(size*size*3)
	End Method
		
	Function Name$()
		Return "grid"
	End Function
End Type

Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function CreateGrid:TGrid(columns = 2, rows = 2, parent:TEntity = Null)
	Local grid:TGrid = TGrid(CurrentWorld().AddCustomEntity(New TGrid, parent))
	grid.SetSize(columns, rows)
	Return grid
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function GetGridSize(grid:TGrid, columns Var, rows Var)
	Return grid.GetSize(columns, rows)
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function SetGridSize(grid:TGrid, columns, rows)
	Return grid.SetSize(columns, rows)
End Function
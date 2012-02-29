
Strict

Module MaxB3DEx.Lightmapper
ModuleInfo "Author: Kevin Primm"
ModuleInfo "License: MIT"

Import MaxB3D.Core
Import Prime.PixmapPacker
Import BRL.JpgLoader

Private
Function BlurPixmap:TPixmap(pixmap:TPixmap, radius# = 1)
	Local out:TPixmap = CopyPixmap(pixmap)		
	Local w = PixmapWidth(pixmap), h = PixmapHeight(pixmap)

	For Local y = 0 To H-1
		For Local x = 0 To W-1
			Local ix1 = Max(x - radius, 0)
			Local iy1 = Max(y - radius, 0)
			Local ix2 = Min(x + radius, w-1)
			Local iy2 = Min(y + radius, h-1)
			
			Local r, g, b, num			

			For Local y2 = iy1 To iy2
				For Local x2 = ix1 To ix2
					Local argb = ReadPixel(pixmap,x2, y2)&$FFFFFF
					Local ar = (argb Shr 16 & %11111111)
					Local ag = (argb Shr 8 & %11111111)
					Local ab = (argb&%11111111)
					
					r = r + ar
					g = g + ag
					b = b + ab
					
					num = num + 1
				Next	
			Next
			
			r = r / num
			g = g / num
			b = b / num	

			out.WritePixel x,y,((255&$ff) Shl 24)|((Min(255, r)&$ff) Shl 16)|((Min(255, g)&$ff) Shl 8)|(Min(255, b)&$ff)
		Next
	Next
	Return out
End Function

Type TLMLight
	Field position:TVector
	Field r#,g#,b#
	Field range#, casts, intensity#
End Type

Type TLMSurface
	Field faces:TLMFace[]
	Field lumelsize#, blur#
	
	Method AddFace:TLMFace(nx#,ny#,nz#,x0#,y0#,z0#,x1#,y1#,z1#,x2#,y2#,z2#)
		Local face:TLMFace = New TLMFace
		face.Build nx,ny,nz,x0,y0,z0,x1,y1,z1,x2,y2,z2,lumelsize,blur
		faces :+ [face]
		Return face
	End Method
	
	Method Light(ambientr, ambientg, ambientb, lights:TList, obscurers:TList, entity:TEntity)
		For Local i = 0 Until faces.length
			faces[i].Light i,ambientr,ambientg,ambientb,lights,obscurers,entity,lumelsize,blur
		Next
	End Method
End Type

Type TLMFace
	Field u0#,v0#,u1#,v1#,u2#,v2#
	Field plane:TPlane
	
	Field lumels:TVector[,]
	Field width,height,pixmap:TPixmap
	
	Method CalculateUV:TBoundingBox(u0#,v0#,u1#,v1#,u2#,v2#,dt#)	
		Local box:TBoundingBox = New TBoundingBox
		box.Add Vec2(u0,v0)
		box.Add Vec2(u1,v1)
		box.Add Vec2(u2,v2)
		
		box.mx.x :+ dt;box.mx.y :+ dt
		box.mn.x :- dt;box.mn.y :- dt
				
		Local du#,dv#,dw#
		box.GetSize du,dv,dw

		u0 = (u0-box.mn.x)/du
		v0 = (v0-box.mn.y)/dv
		u1 = (u1-box.mn.x)/du
		v1 = (v1-box.mn.y)/dv
		u2 = (u2-box.mn.x)/du
		v2 = (v2-box.mn.y)/dv
		
		Return box
	End Method
	
	Method Build(nx#,ny#,nz#,x0#,y0#,z0#,x1#,y1#,z1#,x2#,y2#,z2#,lumelsize#,blur#)
		plane = New TPlane.FromPoint(Vec3(nx,ny,nz).Normalize(), Vec3(x0,y0,z0)) 
		Local box:TBoundingBox, uv:TVector, vec0:TVector, vec1:TVector, dt# = lumelsize*(blur+5.0)
		
		Select plane.MajorAxis()
		Case AXIS_X
			box = CalculateUV(y0,z0,y1,z1,y2,z2,dt)
			uv   = Vec3(-(plane.y * box.mn.x + plane.z * box.mn.y + plane.w)/plane.x, box.mn.x, box.mn.y)
			vec0 = Vec3(-(plane.y * box.mx.x + plane.z * box.mn.y + plane.w)/plane.x, box.mx.x, box.mn.y)
			vec1 = Vec3(-(plane.y * box.mn.x + plane.z * box.mx.y + plane.w)/plane.x, box.mn.x, box.mx.y) 
		Case AXIS_Y
			box = CalculateUV(x0,z0,x1,z1,x2,z2,dt)
			uv   = Vec3(box.mn.x, -(plane.x * box.mn.x + plane.z * box.mn.y + plane.w)/plane.y, box.mn.y)
			vec0 = Vec3(box.mx.x, -(plane.x * box.mx.x + plane.z * box.mn.y + plane.w)/plane.y, box.mn.y)
			vec1 = Vec3(box.mn.x, -(plane.x * box.mn.x + plane.z * box.mx.y + plane.w)/plane.y, box.mx.y) 						
		Case AXIS_Z
			box = CalculateUV(x0,y0,x1,y1,x2,y2,dt)
			uv   = Vec3(box.mn.x, box.mn.y, -(plane.x * box.mn.x + plane.y * box.mn.y + plane.w)/plane.z)
			vec0 = Vec3(box.mx.x, box.mn.y, -(plane.x * box.mx.x + plane.y * box.mn.y + plane.w)/plane.z)
			vec1 = Vec3(box.mn.x, box.mx.y, -(plane.x * box.mn.x + plane.y * box.mx.y + plane.w)/plane.z) 						
		End Select
		
		Local edge0:TVector = Vec3(vec0.x-uv.x,vec0.y-uv.y,vec0.z-uv.z)
		Local edge1:TVector = Vec3(vec1.x-uv.x,vec1.y-uv.y,vec1.z-uv.z)
		
		Local du#,dv#,dw#
		box.GetSize du,dv,dw
			
		width = Max(du / lumelsize, 2)
		height = Max(dv / lumelsize, 2)
		
		lumels = New TVector[width,height]
		For Local x = 0 Until width 
			For Local y = 0 Until height
				Local newedge0:TVector = edge0.Scale(x/Float(width)), newedge1:TVector = edge1.Scale(y/Float(height))
				lumels[x,y] = Vec3(uv.x+newedge1.x+newedge0.x, uv.y+newedge1.y+newedge0.y, uv.z+newedge1.z+newedge0.z)
			Next
		Next
	End Method
	
	Method Light(index, ambientr, ambientg, ambientb, lights:TList, obscurers:TList, entity:TEntity, lumelsize#, blur#)
		pixmap = CreatePixmap(width,height,PF_RGB888)
		For Local x = 0 Until width 
			For Local y = 0 Until height
				Local r,g,b
				For Local light:TLMLight = EachIn lights
					If light.position.Dot(plane)<=EPSILON Continue
					Local vec:TVector = light.position.Sub(lumels[x,y])
					Local distance# = vec.Length()
					vec.Normalize()
					Local angle# = plane.To3().Dot(vec)
					If distance < light.range
						Local ok = True, enumr# = 1.0, enumg# = 1.0, enumb# = 1.0
						Local intensity# = (light.intensity * angle)/distance

						If light.casts
							For Local obscurer:TEntity = EachIn obscurers
								If obscurer.Pick(PICKMODE_POLYGON,light.position.x,light.position.y,light.position.z,lumels[x,y].x,lumels[x,y].y,lumels[x,y].z,0)
									Local er,eb,eg
									Local ea# =	1.0-entity.GetAlpha()
									entity.GetColor er,eb,eg
									enumr :* (er * ea) / 255.0
									enumg :* (eg * ea) / 255.0
									enumb :* (eb * ea) / 255.0
								EndIf
							Next
						
							Local selfpick:TRawPick = entity.Pick(PICKMODE_POLYGON,light.position.x,light.position.y,light.position.z,lumels[x,y].x,lumels[x,y].y,lumels[x,y].z,0)
							If selfpick If selfpick.triangle <> index ok = False
						EndIf
						
						If ok And intensity > 0.0
							r :+ ((light.r / 255.0) * enumr) * 255.0 * intensity
							g :+ ((light.g / 255.0) * enumg) * 255.0 * intensity
							b :+ ((light.b / 255.0) * enumb) * 255.0 * intensity
						EndIf								
					EndIf								
				Next	
				pixmap.WritePixel x,y,((255&$ff) Shl 24)|((Min(255, r + ambientr)&$ff) Shl 16)|((Min(255, g + ambientg)&$ff) Shl 8)|(Min(255, b + ambientb)&$ff)
			Next
		Next
		
		If blur > 0 pixmap = BlurPixmap(pixmap, blur)
		Return True
	End Method
	
End Type

Public

Type TLightmapper
	Field lights:TList = New TList
	Field entities:TList = New TList
	Field surfacefaces:TMap = New TMap
	Field ambientr, ambientg, ambientb
	
	Method AddLight(x#,y#,z#,red = 255,green = 255,blue = 255,range# = 0, casts = True, intensity# = 10.0)
		Local light:TLMLight = New TLMLight
		light.position = Vec3(x,y,z)
		light.r = red;light.g = green;light.b = blue
		If range = 0 range = 9999999
		light.range = range
		light.casts = casts
		light.intensity = intensity
		lights.AddLast light
	End Method
	
	Method SetAmbient(red, green, blue)
		ambientr = red
		ambientg = green
		ambientb = blue
	End Method
	
	Method AddObscurer(entity:TEntity)
		entities.AddLast(entity)
	End Method
	
	Method BuildSurface:TLMSurface(surface:TSurface, matrix:TMatrix, lumelsize# = 0.5, blur# = 1)
		surface.Unweld
		surface.UpdateNormals False
		
		Local lmsurface:TLMSurface = New TLMSurface
		lmsurface.lumelsize = lumelsize
		lmsurface.blur = blur
		
		Local t,v
		surface.GetCounts v,t
		
		For Local i = 0 Until t
			Local vi0,vi1,vi2,nx#,ny#,nz#
			Local x0#,y0#,z0#,x1#,y1#,z1#,x2#,y2#,z2#
			Local u0#,v0#,u1#,v1#,u2#,v2#
			surface.GetTriangle i,vi0,vi1,vi2
			
			surface.GetTriangleNormal i,nx,ny,nz
			surface.GetCoords vi0,x0,y0,z0
			surface.GetCoords vi1,x1,y1,z1
			surface.GetCoords vi2,x2,y2,z2
			
			matrix.TransformVec3 x0,y0,z0
			matrix.TransformVec3 x1,y1,z1
			matrix.TransformVec3 x2,y2,z2
			
			lmsurface.AddFace nx,ny,nz,x0,y0,z0,x1,y1,z1,x2,y2,z2
		Next
		Return lmsurface
	End Method
	
	Method Run:TPixmap(entity:TEntity, lumelsize# = 0.5, blur# = 1, coordset = 0)
		Local mesh:TMesh = TMesh(entity)
		mesh.SetFX mesh.GetFX()|FX_FULLBRIGHT

		Local packer:TPixmapPacker = New TPixmapPacker, pixmaps:TPixmap[]		
		For Local surface:TSurface = EachIn mesh
			Local lmsurface:TLMSurface = TLMSurface(surfacefaces.ValueForKey(surface))
			If lmsurface = Null
				lmsurface = BuildSurface(surface, entity.GetMatrix(), lumelsize, blur)
				surfacefaces.Insert surface, lmsurface
			EndIf
			
			lmsurface.Light(ambientr, ambientg, ambientb, lights, entities, entity)
			For Local face:TLMFace = EachIn lmsurface.faces
				pixmaps :+ [face.pixmap]
				packer.Add face.pixmap
			Next
		Next
		
		Local pixmap:TPixmap = packer.Run(PACKER_POW2|PACKER_SQR, 256), offset = 0
		For Local surface:TSurface = EachIn mesh
			Local lmsurface:TLMSurface = TLMSurface(surfacefaces.ValueForKey(surface))
			For Local t = 0 Until lmsurface.faces.length
				Local u0# = lmsurface.faces[t].u0, v0# = lmsurface.faces[t].v0
				Local u1# = lmsurface.faces[t].u1, v1# = lmsurface.faces[t].v1
				Local u2# = lmsurface.faces[t].u2, v2# = lmsurface.faces[t].v2
				OffsetUVs packer,offset+t,pixmap,u0,v0,u1,v1,u2,v2
				
				Local i0,i1,i2
				surface.GetTriangle t,i0,i1,i2
				
				surface.SetTexCoords i0,1.0-u0,v0,coordset
				surface.SetTexCoords i1,1.0-u1,v1,coordset
				surface.SetTexCoords i2,1.0-u2,v2,coordset
			Next
			offset :+ lmsurface.faces.length
		Next
		Return pixmap
	End Method
	
	Function OffsetUVs(packer:TPixmapPacker, index, pixmap:TPixmap, u0# Var,v0# Var,u1# Var,v1# Var,u2# Var,v2# Var)
		Local pwidth# = PixmapWidth(pixmap), pheight# = PixmapHeight(pixmap)
		
		Local x,y,width,height			
		If packer.Get(index,x,y,width,height)	
			Local tu0# = u0,tu1# = u1,tu2# = u2
			u0 = 1.0 - v0;v0 = tu0
			u1 = 1.0 - v1;v1 = tu1
			u2 = 1.0 - v2;v2 = tu2
		EndIf
		u0 = (x + u0*width)/pwidth;v0 = (y + v0*height)/pheight
		u1 = (x + u1*width)/pwidth;v1 = (y + v1*height)/pheight
		u2 = (x + u2*width)/pwidth;v2 = (y + v2*height)/pheight
	End Function
End Type

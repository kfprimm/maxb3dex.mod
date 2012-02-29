
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

Public

Type TLMLight
	Field position:TVector
	Field r#,g#,b#
	Field range#, casts, intensity#
End Type

Type TLightmapper
	Field lights:TList = New TList
	Field entities:TList = New TList
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
	
	Method Run:TPixmap(mesh:TMesh, lumelsize# = 0.5, blur# = 1, coordset = 0)
		Local packer:TPixmapPacker = New TPixmapPacker, pixmaps:TPixmap[]
		mesh.SetFX mesh.GetFX()|FX_FULLBRIGHT
		For Local surface:TSurface = EachIn mesh
			surface.Unweld
			surface.UpdateNormals False
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
				
				mesh.TransformPoint x0,y0,z0
				mesh.TransformPoint x1,y1,z1
				mesh.TransformPoint x2,y2,z2
				
				Local dt# = lumelsize*(blur+5.0)	
				Local p:TPlane = New TPlane.FromPoint(Vec3(nx,ny,nz).Normalize(), Vec3(x0,y0,z0)), box:TBoundingBox
				Local vec0:TVector, vec1:TVector, uv:TVector
				Select p.MajorAxis()
				Case AXIS_X
					CalculateUV surface,i,y0,z0,y1,z1,y2,z2,coordset,dt,box
					uv   = Vec3(-(p.y * box.mn.x + p.z * box.mn.y + p.w)/p.x, box.mn.x, box.mn.y)
					vec0 = Vec3(-(p.y * box.mx.x + p.z * box.mn.y + p.w)/p.x, box.mx.x, box.mn.y)
					vec1 = Vec3(-(p.y * box.mn.x + p.z * box.mx.y + p.w)/p.x, box.mn.x, box.mx.y) 
				Case AXIS_Y
					CalculateUV surface,i,x0,z0,x1,z1,x2,z2,coordset,dt,box
					uv   = Vec3(box.mn.x, -(p.x * box.mn.x + p.z * box.mn.y + p.w)/p.y, box.mn.y)
					vec0 = Vec3(box.mx.x, -(p.x * box.mx.x + p.z * box.mn.y + p.w)/p.y, box.mn.y)
					vec1 = Vec3(box.mn.x, -(p.x * box.mn.x + p.z * box.mx.y + p.w)/p.y, box.mx.y) 						
				Case AXIS_Z
					CalculateUV surface,i,x0,y0,x1,y1,x2,y2,coordset,dt,box
					uv   = Vec3(box.mn.x, box.mn.y, -(p.x * box.mn.x + p.y * box.mn.y + p.w)/p.z)
					vec0 = Vec3(box.mx.x, box.mn.y, -(p.x * box.mx.x + p.y * box.mn.y + p.w)/p.z)
					vec1 = Vec3(box.mn.x, box.mx.y, -(p.x * box.mn.x + p.y * box.mx.y + p.w)/p.z) 						
				End Select		
				
				Local edge0:TVector = Vec3(vec0.x-uv.x,vec0.y-uv.y,vec0.z-uv.z)
				Local edge1:TVector = Vec3(vec1.x-uv.x,vec1.y-uv.y,vec1.z-uv.z)
				
				Local du#,dv#,dw#
				box.GetSize du,dv,dw
				
				Local width = Max(du / lumelsize, 2)
				Local height = Max(dv / lumelsize, 2)

				Local pixmap:TPixmap = CreatePixmap(width,height,PF_RGB888)
				For Local x = 0 Until width 
					For Local y = 0 Until height
						Local newedge0:TVector = edge0.Scale(x/Float(width)), newedge1:TVector = edge1.Scale(y/Float(height))
						Local lumel:TVector = Vec3(uv.x+newedge1.x+newedge0.x, uv.y+newedge1.y+newedge0.y, uv.z+newedge1.z+newedge0.z)
						Local r,g,b
						For Local light:TLMLight = EachIn lights
							If light.position.Dot(p)<=EPSILON Continue
							Local vec:TVector = light.position.Sub(lumel)
							Local distance# = vec.Length()
							vec.Normalize()
							Local angle# = p.To3().Dot(vec)
							If distance < light.range
								Local ok = True
								For Local entity:TEntity = EachIn entities
									If entity.Pick(PICKMODE_POLYGON,light.position.x,light.position.y,light.position.z,lumel.x,lumel.y,lumel.z,0) ok = False;Exit
								Next
								
								Local selfpick:TRawPick = mesh.Pick(PICKMODE_POLYGON,light.position.x,light.position.y,light.position.z,lumel.x,lumel.y,lumel.z,0)
								If selfpick If selfpick.triangle <> i ok = False
								
								If ok
									Local intensity# = (light.intensity * angle)/distance
									r :+ light.r * intensity
									g :+ light.g * intensity
									b :+ light.b * intensity
								EndIf								
							EndIf								
						Next	
						pixmap.WritePixel x,y,((255&$ff) Shl 24)|((Min(255, r + ambientr)&$ff) Shl 16)|((Min(255, g + ambientg)&$ff) Shl 8)|(Min(255, b + ambientb)&$ff)
					Next
				Next
				
				If blur > 0 pixmap = BlurPixmap(pixmap, blur)
				pixmaps :+ [pixmap]
				packer.Add pixmap
			Next
		Next
		
		Local pixmap:TPixmap = packer.Run(PACKER_POW2|PACKER_SQR, 256)
		Local pwidth# = PixmapWidth(pixmap), pheight# = PixmapHeight(pixmap)
		Local toffset = 0
		For Local surface:TSurface = EachIn mesh
			Local tcnt,vcnt
			Local x,y,width,height,flipped
			surface.GetCounts vcnt,tcnt
			For Local t = 0 Until tcnt
				Local indices[] = [0,0,0]
				surface.GetTriangle t,indices[0],indices[1],indices[2]
				
				flipped = packer.Get(toffset + t,x,y,width,height)
				
				For Local i = EachIn indices
					Local u#,v#
					surface.GetTexCoords i,u,v,coordset
					If flipped
						Local oldu# = u
						u = 1.0-v
						v = oldu
					EndIf
					u = (x + u*width)/pwidth ''(x + (u*width))/pwidth
					v = (y + v*height)/pheight ''(y + (v*height))/pheight
					surface.SetTexCoords i,1.0-u,v,coordset
				Next
			Next
			toffset :+ tcnt
		Next
		Return pixmap
	End Method
	
	Function Clamp#(f#)
		If f < EPSILON Return 0.0
		If Abs(1.0 - f) < EPSILON Return 1.0
		Return f
	End Function
	
	Method CalculateUV(surface:TSurface,index,u0#,v0#,u1#,v1#,u2#,v2#,coordset,dt#,box:TBoundingBox Var)	
		box = New TBoundingBox
		box.Add Vec2(u0,v0)
		box.Add Vec2(u1,v1)
		box.Add Vec2(u2,v2)
		
		box.mx.x :+ dt
		box.mx.y :+ dt
		box.mn.x :- dt
		box.mn.y :- dt
				
		Local du#,dv#,dw#
		box.GetSize du,dv,dw

		Local vi0,vi1,vi2
		surface.GetTriangle index,vi0,vi1,vi2
		
		surface.SetTexCoords vi0,(u0-box.mn.x)/du,(v0-box.mn.y)/dv,coordset
		surface.SetTexCoords vi1,(u1-box.mn.x)/du,(v1-box.mn.y)/dv,coordset
		surface.SetTexCoords vi2,(u2-box.mn.x)/du,(v2-box.mn.y)/dv,coordset		
	End Method
End Type

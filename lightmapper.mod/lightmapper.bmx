
Strict

Module MaxB3DEx.Lightmapper
ModuleInfo "Author: Kevin Primm"
ModuleInfo "License: MIT"

Import MaxB3D.Core
Import BRL.JPGLoader

Type TLMLight
	Field position:TVector
	Field r#,g#,b#
	Field range#, casts, intensity#
End Type

Type TLightmapper
	Field lights:TList = New TList
	Field entities:TList = New TList
	
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
	
	Method AddEntity(entity:TEntity)
		entities.AddLast(entity)
	End Method
	
	Method Run(width, height)
		Local mcnt, scnt
		For Local mesh:TMesh = EachIn entities
			mcnt :+ 1
			For Local surface:TSurface = EachIn mesh
				scnt :+ 1
				surface.Unweld
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
					
					Local p:TPlane = New TPlane.FromPoint(Vec3(nx,ny,nz).Normalize(), Vec3(x0,y0,z0)), box:TBoundingBox
					Local vec0:TVector, vec1:TVector, uv:TVector
					Select p.MajorAxis()
					Case AXIS_X
						CalculateUV surface,i,y0,z0,y1,z1,y2,z2,box
						uv   = Vec3(-(p.y * box.mn.x + p.z * box.mn.y + p.w)/p.x, box.mn.x, box.mn.y)
						vec0 = Vec3(-(p.y * box.mx.x + p.z * box.mn.y + p.w)/p.x, box.mx.x, box.mn.y)
						vec1 = Vec3(-(p.y * box.mn.x + p.z * box.mx.y + p.w)/p.x, box.mn.x, box.mx.y) 
					Case AXIS_Y
						CalculateUV surface,i,x0,z0,x1,z1,x2,z2,box
						uv   = Vec3(box.mn.x, -(p.x * box.mn.x + p.z * box.mn.y + p.w)/p.y, box.mn.y)
						vec0 = Vec3(box.mx.x, -(p.x * box.mx.x + p.z * box.mn.y + p.w)/p.y, box.mn.y)
						vec1 = Vec3(box.mn.x, -(p.x * box.mn.x + p.z * box.mx.y + p.w)/p.y, box.mx.y) 						
					Case AXIS_Z
						CalculateUV surface,i,x0,y0,x1,y1,x2,y2,box
						uv   = Vec3(box.mn.x, box.mn.y, -(p.x * box.mn.x + p.y * box.mn.y + p.w)/p.z)
						vec0 = Vec3(box.mx.x, box.mn.y, -(p.x * box.mx.x + p.y * box.mn.y + p.w)/p.z)
						vec1 = Vec3(box.mn.x, box.mx.y, -(p.x * box.mn.x + p.y * box.mx.y + p.w)/p.z) 						
					End Select		
					
					Local edge0:TVector = Vec3(vec0.x-uv.x,vec0.y-uv.y,vec0.z-uv.z)
					Local edge1:TVector = Vec3(vec1.x-uv.x,vec1.y-uv.y,vec1.z-uv.z)
					
					Local lumels:Byte[width,height,3]
					For Local x = 0 Until width 
						For Local y = 0 Until height
							Local ut# = x/Float(width), vt# = y/Float(height)
							Local newedge0:TVector = edge0.Scale(ut), newedge1:TVector = edge1.Scale(vt)
							Local lumel:TVector = Vec3(uv.x+newedge1.x+newedge0.x, uv.y+newedge1.y+newedge0.y, uv.z+newedge1.z+newedge0.z)
							Local r,g,b
							For Local light:TLMLight = EachIn lights
								If light.position.Dot(p)<=EPSILON Continue
								Local vec:TVector = light.position.Sub(lumel)
								Local distance# = vec.Length()
								vec.Normalize()
								Local angle# = p.To3().Dot(vec)
								If distance < light.range
									Local intensity# = (light.intensity * angle)/distance
									r :+ light.r * intensity
									g :+ light.g * intensity
									b :+ light.b * intensity
								EndIf								
							Next
							lumels[x,y,0] = Min(255, r)
							lumels[x,y,1] = Min(255, g)
							lumels[x,y,2] = Min(255, b)
						Next
					Next
					
					SavePixmapJPeg CreateStaticPixmap(lumels,width,height,0,PF_RGB888), mcnt+"_"+scnt+"_"+i+".jpg"
				Next
			Next
		Next
	End Method
	
	Method CalculateUV(surface:TSurface,index,u0#,v0#,u1#,v1#,u2#,v2#,box:TBoundingBox Var)	
		Local vi0,vi1,vi2
		surface.GetTriangle index,vi0,vi1,vi2
		
		box = New TBoundingBox
		box.Add Vec2(u0,v0)
		box.Add Vec2(u1,v1)
		box.Add Vec2(u2,v2)
		
		Local du#,dv#,dw#
		box.GetSize du,dv,dw
		
		surface.SetTexCoords vi0,(u0-box.mn.x)/du,(v0-box.mn.y)/dv,1
		surface.SetTexCoords vi1,(u1-box.mn.x)/du,(v1-box.mn.y)/dv,1
		surface.SetTexCoords vi2,(u2-box.mn.x)/du,(v2-box.mn.y)/dv,1		
	End Method
End Type

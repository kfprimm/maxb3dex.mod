
Strict

Module MaxB3DEx.LensFlares
ModuleInfo "Author: Kevin Primm"
ModuleInfo "License: MIT"
ModuleInfo "Credit: Adapted from code archive entry by David Barlia."
ModuleInfo "Credit: http://blitzbasic.com/codearcs/codearcs.php?code=1107"

Import MaxB3D.Core

Type TFlarePart
	Field distance#, size#
	Field colorinfluence#, alpha#
	Field frame
End Type

Type TLensFlare
	Field image:TImage
	Field parts:TFlarePart[]
	
	Function Create:TLensFlare(image:TImage)
		Local flare:TLensFlare = New TLensFlare
		flare.image = image
		MidHandleImage flare.image
		Return flare
	End Function
	
	Method AddPart(distance#, size#, colorinfluence#, alpha#, frame)
		Local part:TFlarePart = New TFlarePart
		part.distance = distance
		part.size = size
		part.colorinfluence = colorinfluence
		part.alpha = alpha
		part.frame = frame
		parts :+ [part]
	End Method
	
	Method Render(camera:TCamera, source:Object)
		Local sourcex#, sourcey#, x#,y#
		camera.Project source,sourcex,sourcey
		x = sourcex/GraphicsWidth()
		y = sourcey/GraphicsHeight()
		
		'SeeSource = camerapick(cam_entity,SourceX,SourceY)
		If camera.HasView(source) And (x>0 And x<=1) And (y>0 And y<=1)
			Local red = 255, green = 255, blue = 255 'GetFlareColor(cam_entity, source, SourceX, SourceY)			
			Local scale# = 640.0/800.0
			
			Local oldblend = GetBlend()
			SetBlend LIGHTBLEND
			
			Local aspect# = GraphicsWidth()/Float(GraphicsHeight())
			For Local part:TFlarePart = EachIn parts
				Local flare_x# = sourcex - (((x-0.5)*2.0)*part.distance)
				Local flare_y# = sourcey - (((y-0.5)*2.0)*(part.distance/aspect))

				Local r = (part.colorinfluence * red   + 255.0*(1.0-part.colorinfluence))
				Local g = (part.colorinfluence * green + 255.0*(1.0-part.colorinfluence))
				Local b = (part.colorinfluence * blue  + 255.0*(1.0-part.colorinfluence))

				Local size# = part.size * scale * (x + y + (Cos(part.distance*0.45)/2.0) + 0.5)
				Local alpha# = part.alpha
				If Min(x,y)<0.1 alpha = part.alpha * Min(x,y)/0.2								
				
				SetColor r,g,b
				SetScale size/ImageWidth(image), size/ImageHeight(image)
				SetAlpha alpha

				DrawImage image,flare_x,flare_y,part.frame
			Next
			
			SetBlend oldblend
		End If
	End Method
End Type

Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function CreateLensFlare:TLensFlare(image:TImage)
	Return TLensFlare.Create(image)
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function RenderLensFlare(flare:TLensFlare, camera:TCamera, source:Object)
	Return flare.Render(camera, source)
End Function


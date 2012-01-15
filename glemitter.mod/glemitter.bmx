
Strict

Rem
	bbdoc: Provides a GL renderer for TEmitter
End Rem
Module MaxB3DEx.GLEmitter
ModuleInfo "Author: Kevin Primm"
ModuleInfo "License: MIT"

Import MaxB3DEx.Emitter
Import MaxB3D.GLDriver

Type TGLEmitterRenderer Extends TCustomRenderer
	Method Render(entity:TEntity, driver:TMaxB3DDriver)
		Local emitter:TEmitter = TEmitter(entity)

		glEnable( GL_POINT_SPRITE_ARB )
 		glPointParameterfvARB GL_POINT_DISTANCE_ATTENUATION_ARB, [0.0, 0.0, 1.0]
  	'glPointSize( 2.0 )
		'glPointParameterfARB( GL_POINT_SIZE_MIN_ARB, 2.0 )
		'glPointParameterfARB( GL_POINT_SIZE_MAX_ARB, 100.0 )
		
		For Local i=0 To 7
			glActiveTextureARB GL_TEXTURE0+i
			Local texture:TTexture=emitter._brush._texture[i]
			If texture=Null Or texture._blend=BLEND_NONE Continue
			glTexEnvf GL_POINT_SPRITE_ARB, GL_COORD_REPLACE_ARB, GL_TRUE
		Next
		
		glBegin GL_POINTS
		For Local i = 0 To emitter._life.length-1
			glColor4bv Byte Ptr(Varptr emitter._particles[i*TEmitter.COUNT+4])
			glVertex3f 0,0,0
		Next
		glEnd
		
	End Method
End Type
TCustomEntity.Register TEmitter.Name(), "gl", New TGLEmitterRenderer






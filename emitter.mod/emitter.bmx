
Strict

Module MaxB3DEx.Emitter
ModuleInfo "Author: Kevin Primm"
ModuleInfo "License: MIT"

Import MaxB3D.Core

Private
Function ARGB(alpha,red,green,blue)
	Return ((alpha&$ff) Shl 24)|((red&$ff) Shl 16)|((green&$ff) Shl 8)|(blue&$ff)
End Function

Public

Type TEmitter Extends TCustomEntity
	Const COUNT = 5 ' x,y,z,size,color
	Field _rate#, _time#
	Field _min_life#, _max_life#
	Field _min_vx#, _min_vy#, _min_vz#, _max_vx#, _max_vy#, _max_vz#
	Field _min_s#, _max_s#
	Field _startred, _startgreen, _startblue, _endred, _endgreen, _endblue
	Field _particles#[], _xyz#[], _life#[], _length#[]
	Field _resize

	Method Init:TEmitter(config:TWorldConfig,parent:TEntity)
		Super.Init(config, parent)
		SetFX 0
		SetScaling 2
		AddHook config.UpdateHook, UpdateHook, Self
		Return Self
	End Method
	
	Method CopyData:TEntity(entity:TEntity)
		Local emitter:TEmitter = TEmitter(entity)
		
		Local min_life#,max_life#
		Local min_vx#, min_vy#, min_vz#, max_vx#, max_vy#, max_vz#
		Local min_s#, max_s#
		Local startred, startgreen, startblue
		Local endred, endgreen, endblue

		emitter.GetLife min_life,max_life
		emitter.GetVelocity min_vx,min_vy,min_vz,max_vx,max_vy,max_vz
		emitter.GetScaling min_s,max_s
		emitter.GetGradient startred,startgreen,startblue,endred,endgreen,endblue

		SetRate emitter.GetRate()
		SetLife min_life,max_life
		SetVelocity min_vx,min_vy,min_vz,max_vx,max_vy,max_vz
		SetScaling min_s,max_s
		SetGradient startred,startgreen,startblue,endred,endgreen,endblue

		Return Super.CopyData(entity)
	End Method
	
	Method GetCount()
		Return _life.length
	End Method

	Method GetRate#()
		Return _rate
	End Method
	Method SetRate(rate#)
		_rate = rate
		_resize = True
	End Method
	
	Method GetLife(min_life# Var, max_life# Var)
		min_life = _min_life
		max_life = _max_life
	End Method
	Method SetLife(min_life#, max_life# = 0.0)
		_min_life = min_life
		_max_life = max_life
		_resize = True
	End Method
	
	Method GetGradient(sr Var,sg Var,sb Var,er Var,eg Var,eb Var)
		sr = _startred
		sg = _startgreen
		sb = _startblue
		er = _endred
		eg = _endgreen
		eb = _endblue
	End Method
	Method SetGradient(sr,sg,sb,er,eg,eb)
		_startred = sr
		_startgreen = sg
		_startblue = sb
		_endred = er
		_endgreen = eg
		_endblue = eb
	End Method
	
	Method GetVelocity(minx# Var,miny# Var,minz# Var,maxx# Var,maxy# Var,maxz# Var)
		minx = _min_vx
		miny = _min_vy
		minz = _min_vz
		maxx = _max_vx
		maxy = _max_vy
		maxz = _max_vz
	End Method
	Method SetVelocity(minx#,miny#,minz#,maxx#,maxy#,maxz#)
		_min_vx = minx
		_min_vy = miny
		_min_vz = minz
		_max_vx = maxx
		_max_vy = maxy
		_max_vz = maxz
	End Method
	
	Method GetScaling(min_s# Var, max_s# Var)
		min_s = _min_s
		max_s = _max_s
	End Method
	Method SetScaling(min_s#, max_s# = 0.0)
		_min_s = min_s
		_max_s = max_s
	End Method
	
	Method Update(speed#)
		If _resize
			Local size = Max(_max_life, _min_life)/_rate
			_particles = _particles[..size*COUNT]
			_life = _life[..size]
			_length = _length[..size]
			_xyz = _xyz[..size*3]
			_resize = False
		EndIf
		
		_time :+ speed
		Local dead = -1
		For Local i = 0 To _life.length - 1
			If _life[i] <= 0
				dead = i
				Continue
			EndIf
			_life[i] :- speed
			
			If _life[i] > 0
				Local t# = _life[i]/_length[i]
				_particles[i*COUNT+0] :+ _xyz[i*3+0]
				_particles[i*COUNT+1] :+ _xyz[i*3+1]
				_particles[i*COUNT+2] :+ _xyz[i*3+2]
				Int Ptr(Varptr _particles[i*COUNT+4])[0] = ARGB(255*t, _startred + (_endred - _startred)*t, _startgreen + (_endgreen - _startgreen)*t, _startblue + (_endblue - _startblue)*t)
			Else
				_particles[i*COUNT+3] = 0.0
				Int Ptr(Varptr _particles[i*COUNT+4])[0] = 0
			EndIf
		Next		
		
		If _time > _rate
			Assert dead<>-1, "Dead should not equal -1!"
			_length[dead] = Rnd(_min_life, Max(_max_life, _min_life))
			_life[dead] = _length[dead]
			_particles[dead*COUNT+0] = 0.0
			_particles[dead*COUNT+1] = 0.0
			_particles[dead*COUNT+2] = 0.0
			_particles[dead*COUNT+3] = Rnd(_min_s, Max(_max_s, _min_s))
			Int Ptr(Varptr _particles[dead*COUNT+4])[0] = 0
			
			_xyz[(dead*3)+0] = Rnd(_min_vx, Max(_max_vx, _min_vx))
			_xyz[(dead*3)+1] = Rnd(_min_vy, Max(_max_vy, _min_vy))
			_xyz[(dead*3)+2] = Rnd(_min_vz, Max(_max_vz, _min_vz))
			
			_time = 0
		EndIf
	End Method
		
	Function UpdateHook:Object(id,data:Object,context:Object)
		TEmitter(context).Update(TWorldConfig(data).UpdateSpeed)
		Return data
	End Function
	
	Method SetFX(fx)
		Return Super.SetFX(fx|FX_VERTEXCOLOR)
	End Method
	
	Method SetBrush(brush:TBrush)
		Super.SetBrush brush
		_brush._fx :| FX_VERTEXCOLOR
	End Method
	
	Method GetCullRadius#()
		Local life# = Max(_max_life, _min_life), dist# = Max(Abs(Max(Max(_max_vx, _max_vy), _max_vz)), Abs(Max(Max(_min_vx, _min_vy),_min_vz)))
		Return life*Sqr(dist*dist*3)
	End Method
	
	Function Name$()
		Return "emitter"
	End Function
End Type

Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function CreateEmitter:TEmitter(parent:TEntity = Null)
	Return TEmitter(CurrentWorld().AddCustomEntity(New TEmitter, parent))
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function GetEmitterCount(emitter:TEmitter)
	Return emitter.GetCount()
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function GetEmitterRate#(emitter:TEmitter)
	Return emitter.GetRate()
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function SetEmitterRate(emitter:TEmitter, rate#)
	Return emitter.SetRate(rate)
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function GetEmitterLife(emitter:TEmitter, min_life# Var, max_life# Var)
	Return emitter.GetLife(min_life, max_life)
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function SetEmitterLife(emitter:TEmitter, min_life#, max_life# = 0.0)
	Return emitter.SetLife(min_life, max_life)
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function GetEmitterGradient(emitter:TEmitter, sr Var, sg Var, sb Var, er Var, eg Var, eb Var)
	Return emitter.GetGradient(sr,sg,sb,er,eg,eb)
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function SetEmitterGradient(emitter:TEmitter, sr, sg, sb, er, eg, eb)
	Return emitter.SetGradient(sr, sg, sb, er, eg, eb)
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function GetEmitterVelocity(emitter:TEmitter, minx# Var,miny# Var,minz# Var,maxx# Var,maxy# Var,maxz# Var)
	Return emitter.GetVelocity(minx,miny,minz,maxx,maxy,maxz)
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function SetEmitterVelocity(emitter:TEmitter, minx#, miny#, minz#, maxx# = 0.0, maxy# = 0.0, maxz# = 0.0)
	Return emitter.SetVelocity(minx,miny,minz,maxx,maxy,maxz)
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function GetEmitterScaling(emitter:TEmitter, min_life# Var, max_life# Var)
	Return emitter.GetScaling(min_life, max_life)
End Function
Rem
	bbdoc: Needs documentation. #TODO
End Rem
Function SetEmitterScaling(emitter:TEmitter, min_s#, max_s# = 0.0)
	Return emitter.SetScaling(min_s, max_s)
End Function

Strict

Rem
	bbdoc: Misc utility functions for MaxB3D
End Rem
Module MaxB3DEx.Helper
ModuleInfo "Author: Kevin Primm"
ModuleInfo "License: MIT"

Import MaxB3D.Core

Function FlyCam(camera:TCamera)
	Global _lastx,_lasty
	Local pitch#,yaw#,roll#
	Local halfx=GraphicsWidth()/2,halfy=GraphicsHeight()/2
	camera.GetRotation pitch,yaw,roll
	
	camera.Move KeyDown(KEY_D)-KeyDown(KEY_A),0,KeyDown(KEY_W)-KeyDown(KEY_S)
	camera.SetRotation pitch-(halfy-MouseY()),yaw+(halfx-MouseX()),0
	MoveMouse halfx,halfy
End Function

// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var GetPath = new ApiHook();
/*
int GetPath(
  HDC     hdc,
  LPPOINT apt,
  LPBYTE  aj,
  int     cpt
);
*/
GetPath.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var hdc = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var apt = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var aj  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var cpt	= Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();

	Emu.SetReg(REG_EAX, 1); 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
GetPath.install('gdi32.dll', 'GetPath');

/*
###################################################################################################
###################################################################################################
*/



var SelectObject = new ApiHook();
/*
HGDIOBJ SelectObject(
  HDC     hdc,
  HGDIOBJ h
);
*/
SelectObject.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var hdc = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var h 	= Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();

	Emu.SetReg(REG_EAX, 0); 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
SelectObject.install('gdi32.dll', 'SelectObject');

/*
###################################################################################################
###################################################################################################
*/


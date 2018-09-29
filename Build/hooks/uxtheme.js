// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var IsThemeActive = new ApiHook();
IsThemeActive.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	print('0x',ret.toString(16),' IsThemeActive');

	Emu.SetReg(REG_EAX, 1); 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
IsThemeActive.install('uxtheme.dll', 'IsThemeActive');

/*
###################################################################################################
###################################################################################################
*/

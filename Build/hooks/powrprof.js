// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var GetActivePwrScheme = new ApiHook();
/*
BOOLEAN GetActivePwrScheme(
  PUINT puiID
);
*/
GetActivePwrScheme.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret
	var puiID = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	Emu.WriteDword(puiID,0);// taken from x64dbg :P

	Emu.SetReg(REG_EAX, 1); 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
GetActivePwrScheme.install('powrprof.dll', 'GetActivePwrScheme');

/*
###################################################################################################
###################################################################################################
*/

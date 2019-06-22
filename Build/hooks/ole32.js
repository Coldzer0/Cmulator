// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var OleInitialize = new ApiHook();
/*
HRESULT OleInitialize(
  IN LPVOID pvReserved
);
*/
OleInitialize.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var pvReserved = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();

	log('OleInitialize(0x{0})'.format(
		pvReserved.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
OleInitialize.install('uxtheme.dll', 'OleInitialize');

/*
###################################################################################################
###################################################################################################
*/
// 


var CoFileTimeNow = new ApiHook();
/*
HRESULT CoFileTimeNow(
  FILETIME *lpFileTime
);
*/
CoFileTimeNow.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var lpFileTime = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();

	var data = [0x90, 0x69, 0x45, 0xA5, 0xA3, 0xC4, 0xD4, 0x01];
	Emu.WriteMem(lpFileTime,data);

	log('CoFileTimeNow(0x{0})'.format(
		lpFileTime.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
CoFileTimeNow.install('ole32.dll', 'CoFileTimeNow');

/*
###################################################################################################
###################################################################################################
*/



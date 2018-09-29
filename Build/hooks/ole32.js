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


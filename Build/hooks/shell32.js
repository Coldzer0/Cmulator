// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var CommandLineToArgvW = new ApiHook();
/*
LPWSTR * CommandLineToArgvW(
  LPCWSTR lpCmdLine,
  int     *pNumArgs
);
*/
CommandLineToArgvW.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var lpCmdLine       = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var pNumArgs		   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();

	Emu.WriteDword(lpCmdLine-4,lpCmdLine);
	Emu.WriteDword(lpCmdLine-8,lpCmdLine);
	Emu.WriteWord(pNumArgs,2);

	console.log("CommandLineToArgvW(0x{0}, 0x{1})".format(
		lpCmdLine.toString(16),
		pNumArgs.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, lpCmdLine-8); // A pointer to an array of LPWSTR values, similar to argv.
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

CommandLineToArgvW.install('shell32.dll', 'CommandLineToArgvW');

/*
###################################################################################################
###################################################################################################
*/


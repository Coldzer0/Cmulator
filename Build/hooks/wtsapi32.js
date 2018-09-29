// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var WTSSendMessage = new ApiHook();
/*
BOOL WTSSendMessage(
  IN HANDLE hServer,
  IN DWORD  SessionId,
  LPSTR     pTitle,
  IN DWORD  TitleLength,
  LPSTR     pMessage,
  IN DWORD  MessageLength,
  IN DWORD  Style,
  IN DWORD  Timeout,
  DWORD     *pResponse,
  IN BOOL   bWait
);
*/
WTSSendMessage.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var hServer       = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var SessionId	  = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var pTitle  	  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var TitleLength	  = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var pMessage 	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 
	var MessageLength = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 1)) : Emu.pop(); 
	var Style  	  	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 2)) : Emu.pop(); 
	var Timeout 	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 3)) : Emu.pop(); 
	var pResponse 	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 4)) : Emu.pop();
	var bWait 	  	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 5)) : Emu.pop(); 


	var title = API.IsWapi ? Emu.ReadStringW(pTitle)   : Emu.ReadStringA(pTitle);
	var msg   = API.IsWapi ? Emu.ReadStringW(pMessage) : Emu.ReadStringA(pMessage);

	warn("WTSSendMessage{0}('{1}','{2}')".format(
		API.IsWapi ? 'W' : 'A',
		title,
		msg
	))

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true;
};

WTSSendMessage.install('wtsapi32.dll','WTSSendMessageA');
WTSSendMessage.install('wtsapi32.dll','WTSSendMessageW');

/*
###################################################################################################
###################################################################################################
*/






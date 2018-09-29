// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var MessageBox = new ApiHook();

MessageBox.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..
	
	var hdl     = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var text	= Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var Caption = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var type	= Emu.isx64 ? Emu.ReadReg(REG_R9D) : Emu.pop();

	log("MessageBox{0}({1}, '{2}', '{3}', {4})".format(
		API.IsWapi ? 'W' : 'A',
		hdl,
		API.IsWapi ? Emu.ReadStringW(text) : Emu.ReadStringA(text),
		API.IsWapi ? Emu.ReadStringW(Caption) : Emu.ReadStringA(Caption),
		type
	));

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it / false if you want Emu to handle it and set PC to (pop ret) .
};

MessageBox.install('user32.dll', 'MessageBoxA');
MessageBox.install('user32.dll', 'MessageBoxW');

/*
###################################################################################################
###################################################################################################
*/

var GetProcessWindowStation = new ApiHook();
/*
HWINSTA GetProcessWindowStation();
*/
GetProcessWindowStation.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	warn('GetProcessWindowStation');

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0x1020);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

GetProcessWindowStation.install('user32.dll', 'GetProcessWindowStation');

/*
###################################################################################################
###################################################################################################
*/

var GetUserObjectInformation = new ApiHook();
/*
BOOL GetUserObjectInformation(
  HANDLE  hObj,
  int     nIndex,
  PVOID   pvInfo,
  DWORD   nLength,
  LPDWORD lpnLengthNeeded
);
*/
GetUserObjectInformation.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var hObj       		= Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var nIndex		    = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var pvInfo  		= Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var nLength	   		= Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 byte Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var lpnLengthNeeded = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 

/*
typedef struct tagUSEROBJECTFLAGS {
  BOOL  fInherit;
  BOOL  fReserved;
  DWORD dwFlags;
} USEROBJECTFLAGS, *PUSEROBJECTFLAGS;
*/


	if (nIndex == 1) {
		Emu.WriteDword(pvInfo+8,1);
		Emu.WriteDword(lpnLengthNeeded,nLength);
	} else{
		Emu.WriteDword(pvInfo,0x30405060);
	}

	warn("GetUserObjectInformation{0}(0x{1}, {2}, 0x{3}, {4}, 0x{5})".format(
		API.IsWapi ? 'W' : 'A',
		hObj.toString(16),
		nIndex,
		pvInfo.toString(16),
		nLength,
		lpnLengthNeeded.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

GetUserObjectInformation.install('user32.dll', 'GetUserObjectInformationA');
GetUserObjectInformation.install('user32.dll', 'GetUserObjectInformationW');

/*
###################################################################################################
###################################################################################################
*/
var GetKeyboardType = new ApiHook();

GetKeyboardType.OnCallBack = function (Emu, API, ret) {

	Emu.pop();// return address .

	var something = Emu.pop();
	log('GetKeyboardType(',something,')');

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0x02110110);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetKeyboardType.install('user32.dll', 'GetKeyboardType'); // 0x4B3 by Ordinal for testing

/*
###################################################################################################
###################################################################################################
*/

var SystemParametersInfo = new ApiHook();
/*
BOOL SystemParametersInfo(
  UINT  uiAction,
  UINT  uiParam,
  PVOID pvParam,
  UINT  fWinIni
);
*/
SystemParametersInfo.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var uiAction = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var uiParam	 = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var pvParam  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var fWinIni	 = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();

	// if (pvParam !== 0) {
	// 	Emu.WriteDword(pvParam,0x40100000);
	// }

	warn("SystemParametersInfo{0}(0x{1}, 0x{2}, 0x{3}, 0x{4})".format(
		API.IsWapi ? 'W' : 'A',
		uiAction.toString(16),
		uiParam.toString(16),
		pvParam.toString(16),
		fWinIni.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

SystemParametersInfo.install('user32.dll', 'SystemParametersInfoA');
SystemParametersInfo.install('user32.dll', 'SystemParametersInfoW');

/*
###################################################################################################
###################################################################################################
*/

var MapVirtualKey = new ApiHook();
/*
UINT MapVirtualKey(
  UINT uCode,
  UINT uMapType
);
*/
MapVirtualKey.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var uCode 	 = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var uMapType = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();

	log("{0}(0x{1}, 0x{2})".format(
		API.name,
		uCode.toString(16),
		uMapType.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, uCode);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

MapVirtualKey.install('user32.dll', 'MapVirtualKeyA');
MapVirtualKey.install('user32.dll', 'MapVirtualKeyW');

/*
###################################################################################################
###################################################################################################
*/


var RegisterWindowMessage = new ApiHook();
/*
UINT RegisterWindowMessage(
  LPCWSTR lpString
);
*/
var RW_INDEX = 0xC000;

RegisterWindowMessage.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var lpString = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	log("{0}('{1}') = 0x{2}".format(
		API.name,
		API.IsWapi ? Emu.ReadStringW(lpString) : Emu.ReadStringA(lpString),
		RW_INDEX.toString(16)
	));

/*
If the message is successfully registered, 
the return value is a message identifier in the range 0xC000 through 0xFFFF
*/
	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, RW_INDEX);
	RW_INDEX += 1;

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

RegisterWindowMessage.install('user32.dll', 'RegisterWindowMessageA');
RegisterWindowMessage.install('user32.dll', 'RegisterWindowMessageW');

/*
###################################################################################################
###################################################################################################
*/

// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var MultiByteToWideChar = new ApiHook();
/*
int MultiByteToWideChar(
  UINT                              CodePage,
  DWORD                             dwFlags,
  _In_NLS_string_(cbMultiByte)LPCCH lpMultiByteStr,
  int                               cbMultiByte,
  LPWSTR                            lpWideCharStr,
  int                               cchWideChar
);
*/
MultiByteToWideChar.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var CodePage       = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwFlags		   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var lpMultiByteStr = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var cbMultiByte	   = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var lpWideCharStr  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 
	var cchWideChar	   = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 8) : Emu.pop(); 

	if (lpWideCharStr !== 0){

		var byte;
		var i ;

		// mem copy :V .
		for (i = 0; i < cbMultiByte; i++) {
			byte = Emu.ReadByte(lpMultiByteStr + i);
			Emu.WriteByte(lpWideCharStr + i , byte);
		}
	}

	// console.log("MultiByteToWideChar({0}, {1}, 0x{2}, {3}, {4}, {5})".format(
	// 	CodePage,
	// 	dwFlags,
	// 	lpMultiByteStr.toString(16),
	// 	cbMultiByte,
	// 	lpWideCharStr.toString(16),
	// 	cchWideChar
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, cbMultiByte); // just for now :P .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

MultiByteToWideChar.install('kernel32.dll', 'MultiByteToWideChar');
MultiByteToWideChar.install('api-ms-win-core-string-l1-1-0.dll', 'MultiByteToWideChar');

/*
###################################################################################################
###################################################################################################
*/

var WideCharToMultiByte = new ApiHook();
/*
int WideCharToMultiByte(
  UINT                               CodePage,
  DWORD                              dwFlags,
  _In_NLS_string_(cchWideChar)LPCWCH lpWideCharStr,
  int                                cchWideChar,
  LPSTR                              lpMultiByteStr,
  int                                cbMultiByte,
  LPCCH                              lpDefaultChar,
  LPBOOL                             lpUsedDefaultChar
);
*/
WideCharToMultiByte.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var CodePage       = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwFlags		   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var lpWideCharStr  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var cchWideChar	   = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var lpMultiByteStr 	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 
	var cbMultiByte	   	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 8) : Emu.pop(); 
	var lpDefaultChar  	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 16) : Emu.pop(); 
	var lpUsedDefaultChar = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 24) : Emu.pop(); 


	if (lpMultiByteStr !== 0 && cchWideChar !== 0){

		var byte;
		var i ;

		// mem copy :V .
		for (i = 0; i < cchWideChar; i++) {
			byte = Emu.ReadWord(lpWideCharStr + i );
			Emu.WriteByte(lpMultiByteStr + i , byte);
		}
	}

	// console.log("WideCharToMultiByte({0}, {1}, 0x{2}, {3}, 0x{4}, {5}, {6}, {7})".format(
	// 	CodePage,
	// 	dwFlags,
	// 	lpWideCharStr.toString(16),
	// 	cchWideChar,
	// 	lpMultiByteStr.toString(16),
	// 	cbMultiByte,
	// 	lpDefaultChar,
	// 	lpUsedDefaultChar
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, cchWideChar); // just for now :P .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

WideCharToMultiByte.install('kernel32.dll', 'WideCharToMultiByte');
WideCharToMultiByte.install('api-ms-win-core-string-l1-1-0.dll', 'WideCharToMultiByte');

/*
###################################################################################################
###################################################################################################
*/

var LCMapString = new ApiHook();
/*
int LCMapStringA(
  LCID   Locale,
  DWORD  dwMapFlags,
  LPCSTR lpSrcStr,
  int    cchSrc,
  LPSTR  lpDestStr,
  int    cchDest
);
*/
LCMapString.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var Locale     = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwMapFlags = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var lpSrcStr   = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var cchSrc	   = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	var lpDestStr  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 
	var cchDest	   = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 8) : Emu.pop(); 


	if (lpDestStr !== 0){

		var byte;
		var i ;

		// mem copy :V .
		for (i = 0; i < cchSrc; i++) {
			byte = Emu.ReadByte(lpSrcStr + i);
			Emu.WriteByte(lpDestStr + i , byte);
		}
	}

	// console.log("LCMapString{0}({1}, {2}, 0x{3}, {4}, 0x{5}, {6})".format(
	// 	API.IsWapi ? 'W' : 'A',
	// 	Locale,
	// 	dwMapFlags,
	// 	lpSrcStr.toString(16),
	// 	cchSrc,
	// 	lpDestStr.toString(16),
	// 	cchDest
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, cchSrc); // just for now :P .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

LCMapString.install('kernel32.dll', 'LCMapStringA');
LCMapString.install('kernel32.dll', 'LCMapStringW');

LCMapString.install('api-ms-win-core-localization-l1-1-0.dll', 'LCMapStringW');


/*
###################################################################################################
###################################################################################################
*/

var LCMapStringEx = new ApiHook();
/*
int LCMapStringEx(
  LPCWSTR          lpLocaleName,
  DWORD            dwMapFlags,
  LPCWSTR          lpSrcStr,
  int              cchSrc,
  LPWSTR           lpDestStr,
  int              cchDest,
  LPNLSVERSIONINFO lpVersionInformation,
  LPVOID           lpReserved,
  LPARAM           sortHandle
);
*/
LCMapStringEx.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var Locale     = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwMapFlags = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var lpSrcStr   = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var cchSrc	   = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	var lpDestStr  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 
	var cchDest	   = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 8) : Emu.pop(); 

	var lpVersionInformation = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 8) : Emu.pop(); 
	var lpReserved	   		 = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 16) : Emu.pop(); 
	var sortHandle	   		 = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 24) : Emu.pop(); 


	if (lpDestStr !== 0){

		var byte;
		var i ;

		// mem copy :V .
		for (i = 0; i < cchSrc; i++) {
			byte = Emu.ReadByte(lpSrcStr + i);
			Emu.WriteByte(lpDestStr + i , byte);
		}
	}

	// console.log("LCMapStringEx({0}, {1}, 0x{2}, {3}, 0x{4}, {5})".format(
	// 	Locale,
	// 	dwMapFlags,
	// 	lpSrcStr.toString(16),
	// 	cchSrc,
	// 	lpDestStr.toString(16),
	// 	cchDest
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, cchSrc); // just for now :P .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

LCMapStringEx.install('kernel32.dll', 'LCMapStringEx');

/*
###################################################################################################
###################################################################################################
*/

var GetStringTypeW = new ApiHook();
GetStringTypeW.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};

GetStringTypeW.install('kernel32.dll', 'GetStringTypeW');
GetStringTypeW.install('api-ms-win-core-string-l1-1-0.dll', 'GetStringTypeW');

/*
###################################################################################################
###################################################################################################
*/


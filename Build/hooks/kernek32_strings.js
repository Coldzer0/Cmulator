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
		Emu.WriteStringA(lpMultiByteStr,Emu.ReadStringW(lpWideCharStr));
	}

	log("WideCharToMultiByte({0}, {1}, 0x{2}, {3}, 0x{4}, {5}, {6}, {7})".format(
		CodePage,
		dwFlags,
		lpWideCharStr.toString(16),
		cchWideChar,
		lpMultiByteStr.toString(16),
		cbMultiByte,
		lpDefaultChar,
		lpUsedDefaultChar
	));

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

var lstrlen = new ApiHook();
/*
int lstrlen(
  LPCWSTR lpString
);
*/
lstrlen.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // return addr

	var Buf = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	var data = API.IsWapi ? Emu.ReadWord(Buf) : Emu.ReadByte(Buf);
	var len = 0;

	while (data != 0) {
		len +=1
		data = API.IsWapi ? Emu.ReadWord(Buf+len) : Emu.ReadByte(Buf+len);
	}

	log("{0}(0x{1} = '{2}') = {3} ".format(
		API.name,
		Buf.toString(16),
		Emu.IsWapi ? Emu.ReadStringW(Buf) : Emu.ReadStringA(Buf),
		len
	));


    Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, len);
    Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
lstrlen.install('kernel32.dll', 'lstrlen');
lstrlen.install('kernelbase.dll', 'lstrlenW');
lstrlen.install('kernelbase.dll', 'lstrlenA');
lstrlen.install('api-ms-win-core-misc-l1-1-0.dll', 'lstrlenW');
lstrlen.install('api-ms-win-core-misc-l1-1-0.dll', 'lstrlenA');
lstrlen.install('kernel32.dll', 'lstrlenW');
lstrlen.install('kernel32.dll', 'lstrlenA');

/*
###################################################################################################
###################################################################################################
*/


// var lstrcmpW = new ApiHook();
/*
int lstrcmpW(
  LPCWSTR lpString1,
  LPCWSTR lpString2
);
*/
/*
lstrcmpW.OnCallBack = function (Emu, API, ret) {

	// lstrcmpW.args[0] = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + 4);
	// lstrcmpW.args[1] = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + 8);

	var lpString1 = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpString2 = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	Emu.HexDump(lpString1, len*2);
	Emu.HexDump(lpString2, len*2);

	// so just let the library handle it :D 
	return true;
};
*/
/*
lstrcmpW.OnExit = function(Emu,API){

	var len = Emu.ReadReg(REG_EAX);
	var lpString1 = lstrcmpW.args[0];
	var lpString2 = lstrcmpW.args[0];

	warn("OnExit : lstrcmpW(0x{0},0x{1}) = {2} ".format(
		lpString1.toString(16),
		lpString2.toString(16),
		Emu.ReadReg(REG_EAX)
	));

	Emu.HexDump(lpString1, len*2);
	Emu.HexDump(lpString2, len*2);
}

lstrcmpW.install('kernelbase.dll', 'lstrcmpW');
*/

var lstrcmp = new ApiHook();
lstrcmp.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var Ptr1 = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var Ptr2 = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	var lpString1 = API.IsWapi ? Emu.ReadStringW(Ptr1) : Emu.ReadStringA(Ptr1);
	var lpString2 = API.IsWapi ? Emu.ReadStringW(Ptr2) : Emu.ReadStringA(Ptr2);

	 
	warn("{0}(0x{1} = '{2}', 0x{3} = '{4}')".format(
		API.name,
		Ptr1.toString(16),
		lpString1,
		Ptr2.toString(16),
		lpString2
	));

	if (Ptr1 !== 0) {
		if (lpString1.length !== 0) {
			Emu.HexDump(Ptr1, API.IsWapi ? lpString1.length * 2 : lpString1.length);
		}
	}
	if (Ptr2 !== 0) {
		if (lpString2.length !== 0) {
			Emu.HexDump(Ptr2, API.IsWapi ? lpString2.length * 2 : lpString2.length);
		}
	}
	var value = 0;

	if (lpString1 !== lpString2) {
		value = lpString1.length - lpString2.length;
		if (value == 0) {
			value = 1;
		}
	}

	warn('lstrcmp = ',value)

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, value);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	// Emu.Stop();

	return true;
};
lstrcmp.install('kernel32.dll', 'lstrcmpW');
lstrcmp.install('kernel32.dll', 'lstrcmpA');
lstrcmp.install('kernel32.dll', 'lstrcmp');

/*
###################################################################################################
*/

// var CompareStringW = new ApiHook();
// CompareStringW.OnCallBack = function (Emu, API, ret) {
// 	// let the lib handle it
// 	return true;
// };
// CompareStringW.install('kernelbase.dll', 'CompareStringW');

// var InternalLcidToName = new ApiHook();
// InternalLcidToName.OnCallBack = function (Emu, API, ret) {
// 	// let the lib handle it
// 	return true;
// };
// InternalLcidToName.install('kernelbase.dll', 'InternalLcidToName');

// var CompareStringEx = new ApiHook();
// CompareStringEx.OnCallBack = function (Emu, API, ret) {
// 	// let the lib handle it
// 	return true;
// };
// CompareStringEx.install('kernelbase.dll', 'CompareStringEx');

/*
###################################################################################################
###################################################################################################
*/

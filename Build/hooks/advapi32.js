// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var RegCreateKey = new ApiHook();
/*
	LSTATUS RegCreateKeyA(
	  HKEY   hKey,
	  LPCSTR lpSubKey,
	  PHKEY  phkResult
	);
*/
RegCreateKey.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..
	

	var hKey ;
	var lpSubKey;
	var phkResult ;

	if (Emu.isx64) {

		hKey      = Emu.ReadReg(REG_RCX);
		lpSubKey  = API.IsWapi ? Emu.ReadStringW(Emu.ReadReg(REG_RDX)) : Emu.ReadStringA(Emu.ReadReg(REG_RDX));
		phkResult = Emu.ReadReg(REG_R8);

	}else{

		hKey 	  = Emu.pop();
		lpSubKey  = API.IsWapi ? Emu.ReadStringW(Emu.pop()) : Emu.ReadStringA(Emu.pop());
		phkResult = Emu.pop()

	}

	var Keys = {
	  0x80000000: 'HKEY_CLASSES_ROOT',
	  0x80000001: 'HKEY_CURRENT_USER',
	  0x80000002: 'HKEY_LOCAL_MACHINE',
	  0x80000003: 'HKEY_USERS',
	  0x80000004: 'HKEY_PERFORMANCE_DATA',
	  0x80000005: 'HKEY_CURRENT_CONFIG',
	  0x80000006: 'HKEY_DYN_DATA'
	}

	log("0x{0} : {1}({2}, '{3}', 0x{4}) = {5}".format(
		ret.toString(16),
		API.name,
		Keys[hKey],
		lpSubKey,
		phkResult.toString(16),
		0x90 // static for now :D
	));

	Emu.WriteByte(phkResult,0x90); // i like nop :P .

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0); // Form MS Docs .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

RegCreateKey.install('advapi32.dll', 'RegCreateKeyA');
RegCreateKey.install('advapi32.dll', 'RegCreateKeyW');

/*
###################################################################################################
###################################################################################################
*/

var RegSetValue = new ApiHook();
/*
	LSTATUS RegSetValueA(
	  HKEY   hKey,
	  LPCSTR lpSubKey,
	  DWORD  dwType,
	  LPCSTR lpData,
	  DWORD  cbData
	);
*/
RegSetValue.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..
	

	var hKey ;
	var lpSubKey;
	var phkResult ;

	if (Emu.isx64) {

		hKey      = Emu.ReadReg(REG_RCX);
		lpSubKey  = API.IsWapi ? Emu.ReadStringW(Emu.ReadReg(REG_RDX)) : Emu.ReadStringA(Emu.ReadReg(REG_RDX));
		phkResult = Emu.ReadReg(REG_R8);

	}else{

		hKey 	  = Emu.pop();
		lpSubKey  = API.IsWapi ? Emu.ReadStringW(Emu.pop()) : Emu.ReadStringA(Emu.pop());
		phkResult = Emu.pop()

	}

	var Keys = {
	  0x80000000: 'HKEY_CLASSES_ROOT',
	  0x80000001: 'HKEY_CURRENT_USER',
	  0x80000002: 'HKEY_LOCAL_MACHINE',
	  0x80000003: 'HKEY_USERS',
	  0x80000004: 'HKEY_PERFORMANCE_DATA',
	  0x80000005: 'HKEY_CURRENT_CONFIG',
	  0x80000006: 'HKEY_DYN_DATA',
	  0x80000050: 'HKEY_PERFORMANCE_TEXT',
	  0x80000060: 'HKEY_PERFORMANCE_NLSTEXT'
	}

	warn("0x{0} : {1}({2}, '{3}', 0x{4})".format(
		ret.toString(16),
		API.name,
		Keys[hKey],
		lpSubKey,
		phkResult.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

RegSetValue.install('advapi32.dll', 'RegSetValueA');
RegSetValue.install('advapi32.dll', 'RegSetValueW');

/*
###################################################################################################
###################################################################################################
*/

var RegSetValueEx = new ApiHook();
/*
	LSTATUS RegSetValueExA(
	  HKEY       hKey,
	  LPCSTR     lpValueName,
	  DWORD      Reserved,
	  DWORD      dwType,
	  CONST BYTE *lpData,
	  DWORD      cbData
	);
*/
RegSetValueEx.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..
	

	var hKey ;
	var lpValueName;
	var Reserved;
	var dwType;
	var lpData;
	var cbData;

	if (Emu.isx64) {

		hKey        = Emu.ReadReg(REG_RCX);
		lpValueName = API.IsWapi ? Emu.ReadStringW(Emu.ReadReg(REG_RDX)) : Emu.ReadStringA(Emu.ReadReg(REG_RDX));
		Reserved    = Emu.ReadReg(REG_R8D);
		dwType		= Emu.ReadReg(REG_R9D);

		var shadow  = Emu.ReadReg(REG_RSP) + 32; // not we are at the 5th param .
		lpData		= API.IsWapi ? Emu.ReadStringW(shadow) : Emu.ReadStringA(shadow);
		// cbData		= TODO: add Emu.ReadQWord(shadow+8);


	}else{

		hKey 	  	= Emu.pop();
		lpValueName = API.IsWapi ? Emu.ReadStringW(Emu.pop()) : Emu.ReadStringA(Emu.pop());
		Reserved 	= Emu.pop();
		dwType		= Emu.pop();
		lpData		= Emu.pop();
		cbData		= Emu.pop();

	}

	var Keys = {
	  0x80000000: 'HKEY_CLASSES_ROOT',
	  0x80000001: 'HKEY_CURRENT_USER',
	  0x80000002: 'HKEY_LOCAL_MACHINE',
	  0x80000003: 'HKEY_USERS',
	  0x80000004: 'HKEY_PERFORMANCE_DATA',
	  0x80000005: 'HKEY_CURRENT_CONFIG',
	  0x80000006: 'HKEY_DYN_DATA',
	  0x80000050: 'HKEY_PERFORMANCE_TEXT',
	  0x80000060: 'HKEY_PERFORMANCE_NLSTEXT'
	}
	var Types = {	
	  0:  'REG_NONE',// No value type
	  1:  'REG_SZ',// Unicode or ANSI nul terminated string
	  2:  'REG_EXPAND_SZ', // Unicode or ANSI nul terminated string
	  3:  'REG_BINARY',// Free form binary
	  4:  'REG_DWORD_LITTLE_ENDIAN',// 32-bit number
	  5:  'REG_DWORD_BIG_ENDIAN',// 32-bit number
	  6:  'REG_LINK',// Symbolic Link (unicode)
	  7:  'REG_MULTI_SZ',// Multiple Unicode strings
	  8:  'REG_RESOURCE_LIST',// Resource list in the resource map
	  9:  'REG_FULL_RESOURCE_DESCRIPTOR',// Resource list in the hardware description
	  10: 'REG_RESOURCE_REQUIREMENTS_LIST',
	  11: 'REG_QWORD'// 64-bit number
	}

	var handle = Keys[hKey] !== undefined ? Keys[hKey] : hKey;
	var type = Types[dwType];

	var data = null;
	if (dwType == 1 || dwType == 2 || dwType == 6 ){
		data = "'" + (API.IsWapi ? Emu.ReadStringW(lpData) : Emu.ReadStringA(lpData)) + "'";
	}
	// Binary ..
	if (dwType == 3){ 
		Emu.HexDump(lpData,cbData); // dump hex :D ..
		// TODO: add dump to file ;)
	}

	warn("0x{0} : {1}({2}, '{3}', {4}, {5}, {6}, {7})".format(
		ret.toString(16),
		API.name,
		handle,
		lpValueName,
		Reserved.toString(16),
		type,
		data,
		Emu.isx64 ? 0 : cbData
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

RegSetValueEx.install('advapi32.dll', 'RegSetValueExA');
RegSetValueEx.install('advapi32.dll', 'RegSetValueExW');


/*
###################################################################################################
###################################################################################################
*/

var RegCloseKey = new ApiHook();
/*
	LSTATUS RegCloseKey(
	  HKEY hKey
	);
*/
RegCloseKey.OnCallBack = function (Emu, API,ret) {
	Emu.pop();

	print('0x{0} : RegCloseKey()'.format(
		ret.toString(16),
		Emu.pop()
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	
	return true; 
};
RegCloseKey.install('advapi32.dll', 'RegCloseKey');

/*
###################################################################################################
###################################################################################################
*/

var RegOpenKey = new ApiHook();
/*
LSTATUS RegOpenKey(
  HKEY   hKey,
  LPCSTR lpSubKey,
  PHKEY  phkResult
);
*/

var blacklist = [
	'Wine',
	'VBOX',
	'VBOX__'
];

RegOpenKey.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var hKey       = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpSubKey   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var phkResult  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();

	var value = API.IsWapi ? Emu.ReadStringW(lpSubKey) : Emu.ReadStringA(lpSubKey);

	var AntiCheck = blacklist.inList(value,true);

	var handle = AntiCheck ? 0 : 0xF1; // 0 if antiVM else give a fake handle :V 

	if (phkResult !== 0) {
		Emu.WriteDword(phkResult,handle); // fake handle :D 
	}

	warn("0x{0} : {1}({2}, '{3}', 0x{4}) = {5} ".format(
		ret.toString(16),
		API.name,
		hKey.toString(16),
		value,
		phkResult.toString(16),
		!AntiCheck
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, AntiCheck ? 1 : 0); // ERROR_SUCCESS = 0 .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

RegOpenKey.install('advapi32.dll', 'RegOpenKeyA');
RegOpenKey.install('advapi32.dll', 'RegOpenKeyW');

/*
###################################################################################################
###################################################################################################
*/
var RegOpenKeyEx = new ApiHook();
/*
LSTATUS RegOpenKeyEx(
  HKEY   hKey,
  LPCSTR lpSubKey,
  DWORD  ulOptions,
  REGSAM samDesired,
  PHKEY  phkResult
);
*/
RegOpenKeyEx.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var hKey       = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpSubKey   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var ulOptions  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var samDesired = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var phkResult  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 

	if (phkResult !== 0) {
		Emu.WriteDword(phkResult,0xF0); // fake handle :D 
	}

	warn("0x{0} : {1}({2}, '{3}', {4}, {5}, 0x{6})".format(
		ret.toString(16),
		API.name,
		hKey,
		API.IsWapi ? Emu.ReadStringW(lpSubKey) : Emu.ReadStringA(lpSubKey),
		ulOptions,
		samDesired,
		phkResult.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0); // ERROR_SUCCESS .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

RegOpenKeyEx.install('advapi32.dll', 'RegOpenKeyExA');
RegOpenKeyEx.install('advapi32.dll', 'RegOpenKeyExW');


/*
###################################################################################################
###################################################################################################
*/


var RegQueryValueEx = new ApiHook();
/*
LSTATUS RegQueryValueEx(
  HKEY                              hKey,
  LPCSTR                            lpValueName,
  LPDWORD                           lpReserved,
  LPDWORD                           lpType,
  __out_data_source(REGISTRY)LPBYTE lpData,
  LPDWORD                           lpcbData
);
*/
RegQueryValueEx.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var hKey        = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpValueName = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var lpReserved  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var lpType	    = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var lpData   = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 
	var lpcbData = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 8) : Emu.pop(); 

	// TODO: make array of reg data or what ever :D
	if (lpData !== 0 && lpcbData !== 0) {

		if (lpType = 0) {
			Emu.WriteDword(lpcbData,4); 
			Emu.WriteByte(lpData,0x30);
		} 
	}

	warn("0x{0} : {1}(0x{2}, '{3}', 0x{4}, 0x{5}, 0x{6}, 0x{7})".format(
		ret.toString(16),
		API.name,
		hKey.toString(16),
		API.IsWapi ? Emu.ReadStringW(lpValueName) : Emu.ReadStringA(lpValueName),
		lpReserved.toString(16),
		lpType.toString(16),
		lpData.toString(16),
		lpcbData.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0); // ERROR_SUCCESS .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

RegQueryValueEx.install('advapi32.dll', 'RegQueryValueExA');
RegQueryValueEx.install('advapi32.dll', 'RegQueryValueExW');


/*
###################################################################################################
###################################################################################################
*/


var EventRegister = new ApiHook();
/*
ULONG EVNTAPI EventRegister(
  LPCGUID         ProviderId,
  PENABLECALLBACK EnableCallback,
  PVOID           CallbackContext,
  PREGHANDLE      RegHandle
);
*/
EventRegister.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var ProviderId      = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var EnableCallback  = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var CallbackContext = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var RegHandle	    = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();

	log("0x{0} : EventRegister(0x{1}, 0x{2}, 0x{3}, 0x{4})".format(
		ret.toString(16),
		ProviderId.toString(16),
		EnableCallback.toString(16),
		CallbackContext.toString(16),
		RegHandle.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0); // Returns ERROR_SUCCESS if successful.
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

EventRegister.install('advapi32.dll', 'EventRegister');

/*
###################################################################################################
###################################################################################################
*/


var GetSecurityDescriptorControl = new ApiHook();
/*
BOOL GetSecurityDescriptorControl(
  PSECURITY_DESCRIPTOR         pSecurityDescriptor,
  PSECURITY_DESCRIPTOR_CONTROL pControl,
  LPDWORD                      lpdwRevision
);
*/
GetSecurityDescriptorControl.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var pSecurityDescriptor = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var pControl  			= Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var lpdwRevision 		= Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();

	log("GetSecurityDescriptorControl(0x{0}, 0x{1}, 0x{2})".format(
		pSecurityDescriptor.toString(16),
		pControl.toString(16),
		lpdwRevision.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1); // Returns nonzero if successful.
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

GetSecurityDescriptorControl.install('advapi32.dll', 'GetSecurityDescriptorControl');

/*
###################################################################################################
###################################################################################################
*/


var IsTokenRestricted = new ApiHook();
/*
BOOL IsTokenRestricted(
  HANDLE TokenHandle
);
*/
IsTokenRestricted.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var TokenHandle = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	log("IsTokenRestricted(0x{0})".format(
		TokenHandle.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

IsTokenRestricted.install('advapi32.dll', 'IsTokenRestricted');

/*
###################################################################################################
###################################################################################################
*/

// advapi32.dll.CryptAcquireContextA

var AdvGen = new ApiHook();
AdvGen.OnCallBack = function (Emu, API, ret) {

	return true; // we handled the Stack and other things :D .
};
AdvGen.OnExit = function(Emu,API){

	warn("CryptAcquireContextA() = 0x", Emu.isx64 ? Emu.ReadReg(REG_RAX) : Emu.ReadReg(REG_EAX))
}

AdvGen.install('advapi32.dll', 'CryptAcquireContextA');
AdvGen.install('cryptsp.dll' , 'CryptAcquireContextA');


/*
###################################################################################################
###################################################################################################
*/




// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var WinHttpOpen = new ApiHook();
/*
WINHTTPAPI HINTERNET WinHttpOpen(
  LPCWSTR pszAgentW,
  DWORD   dwAccessType,
  LPCWSTR pszProxyW,
  LPCWSTR pszProxyBypassW,
  DWORD   dwFlags
);
*/
WinHttpOpen.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var pszAgentW       = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwAccessType	= Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var pszProxyW 		= Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var pszProxyBypassW	= Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var dwFlags  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 

	print("WinHttpOpen('{0}', {1}, '{2}', '{3}', {4} )".format(
		Emu.ReadStringW(pszAgentW),
		dwAccessType,
		Emu.ReadStringW(pszProxyW),
		Emu.ReadStringW(pszProxyBypassW),
		dwFlags
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 100);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
WinHttpOpen.install('winhttp.dll', 'WinHttpOpen');


/*
###################################################################################################
###################################################################################################
*/

var WinHttpGetProxyForUrl = new ApiHook();
/*
BOOLAPI WinHttpGetProxyForUrl(
  IN HINTERNET                 hSession,
  IN LPCWSTR                   lpcwszUrl,
  IN WINHTTP_AUTOPROXY_OPTIONS *pAutoProxyOptions,
  OUT WINHTTP_PROXY_INFO       *pProxyInfo
);
*/
WinHttpGetProxyForUrl.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var hSession       	  = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpcwszUrl		  = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var pAutoProxyOptions = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var pProxyInfo		  = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();

	print("WinHttpGetProxyForUrl({0}, '{1}', 0x{2}, 0x{3})".format(
		hSession,
		Emu.ReadStringW(lpcwszUrl),
		pAutoProxyOptions.toString(16),
		pProxyInfo
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
WinHttpGetProxyForUrl.install('winhttp.dll', 'WinHttpGetProxyForUrl');


/*
###################################################################################################
###################################################################################################
*/

var WinHttpGetIEProxyConfigForCurrentUser = new ApiHook();
/*
BOOLAPI WinHttpGetIEProxyConfigForCurrentUser(
  IN OUT WINHTTP_CURRENT_USER_IE_PROXY_CONFIG *pProxyConfig
);
*/
WinHttpGetIEProxyConfigForCurrentUser.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var pProxyConfig = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	print("WinHttpGetIEProxyConfigForCurrentUser(0x{0})".format(
		pProxyConfig.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
WinHttpGetIEProxyConfigForCurrentUser.install('winhttp.dll', 'WinHttpGetIEProxyConfigForCurrentUser');


/*
###################################################################################################
###################################################################################################
*/











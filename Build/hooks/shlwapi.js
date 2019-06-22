// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var PathStripPath = new ApiHook();
/*
void PathStripPath(
  LPSTR pszPath
);
*/
PathStripPath.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // return addr

	var pszPath = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var path = Emu.IsWapi ? Emu.ReadStringW(pszPath) : Emu.ReadStringA(pszPath);
	var filename = path.split(/[\\\/]/).pop(); // path.substring(path.lastIndexOf('\\')+1);


	if (filename !== '') {
		var len = Emu.IsWapi ? Emu.WriteStringW(pszPath,filename) : Emu.WriteStringA(pszPath,filename);
		Emu.WriteByte(pszPath+len,0);
	}


	log("{0}(0x{1} = '{2}') = '{3}' ".format(
		API.name,
		pszPath.toString(16),
		path,
		filename
	));

    Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};

PathStripPath.install('shlwapi.dll', 'PathStripPathA');
PathStripPath.install('shlwapi.dll', 'PathStripPathW');

/*
###################################################################################################
###################################################################################################
*/


var PathFindFileName = new ApiHook();

PathFindFileName.OnCallBack = function (Emu, API, ret) {

	// The Lib can handle it :D
	return true; // we handled the Stack and other things :D .
};

PathFindFileName.install('shlwapi.dll', 'PathFindFileNameA');
PathFindFileName.install('shlwapi.dll', 'PathFindFileNameW');

/*
###################################################################################################
###################################################################################################
*/
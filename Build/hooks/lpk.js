// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var LpkDllInitialize = new ApiHook();
LpkDllInitialize.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
LpkDllInitialize.install('lpk.dll', 'LpkDllInitialize');

/*
###################################################################################################
###################################################################################################
*/
var LpkPresent = new ApiHook();
LpkPresent.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
LpkPresent.install('usp10.dll', 'LpkPresent');

/*
###################################################################################################
###################################################################################################
*/


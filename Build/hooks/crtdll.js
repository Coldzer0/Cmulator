// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';


var strcat = new ApiHook();

strcat.OnCallBack = function (Emu, API, ret) {

	// i think implementing this in JS is a bit hard so
	// just let the library handle it :D 
	info('[!] just let the library handle it :D');
	return true;
};
strcat.install('crtdll.dll', 'strcat');


/*
###################################################################################################
###################################################################################################
*/


var __GetMainArgs = new ApiHook();

__GetMainArgs.OnCallBack = function (Emu, API, ret) {

	// i think implementing this in JS is a bit hard so
	// just let the library handle it :D 
	info('[!] just let the library handle it :D');
	return true;
};
__GetMainArgs.install('crtdll.dll', '__GetMainArgs');
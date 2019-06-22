'use strict';

var KernelBaseGetGlobalData = new ApiHook();
KernelBaseGetGlobalData.OnCallBack = function (Emu, API, ret) {

	// let the lib handle it 
	return true;
};

KernelBaseGetGlobalData.install('kernelbase.dll', 'KernelBaseGetGlobalData');

/*
###################################################################################################
###################################################################################################
*/

var KBGetThreadLocale = new ApiHook();
KBGetThreadLocale.OnCallBack = function (Emu, API, ret) {
	// let the lib handle it 
	return true;
};

KBGetThreadLocale.install('kernelbase.dll', 'GetThreadLocale');

/*
###################################################################################################
###################################################################################################
*/

var InterlockedCompareExchange = new ApiHook();
InterlockedCompareExchange.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};

InterlockedCompareExchange.install('kernelbase.dll', 'InterlockedCompareExchange');
/*
###################################################################################################
###################################################################################################
*/
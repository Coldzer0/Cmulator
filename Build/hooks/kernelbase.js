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


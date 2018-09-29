// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

var IsDBCSLeadByte = new ApiHook();
IsDBCSLeadByte.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
IsDBCSLeadByte.install('kernel32.dll', 'IsDBCSLeadByte');
IsDBCSLeadByte.install('kernelbase.dll', 'IsDBCSLeadByte');

/*
###################################################################################################
###################################################################################################
*/


var SetUnhandledExceptionFilter = new ApiHook();
/*
LPTOP_LEVEL_EXCEPTION_FILTER WINAPI SetUnhandledExceptionFilter(
  _In_ LPTOP_LEVEL_EXCEPTION_FILTER lpTopLevelExceptionFilter
);
*/
SetUnhandledExceptionFilter.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // PC

    var ExceptionFilter = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

    var SEH = Emu.isx64 ? Emu.ReadQword(Emu.TEB) : Emu.ReadDword(Emu.TEB);

    if (SEH !== -1) {
    	Emu.isx64 ? Emu.WriteQword(SEH+8,ExceptionFilter) : Emu.WriteDword(SEH+4,ExceptionFilter);
    }

    info('0x{0} : SetUnhandledExceptionFilter(Handler = 0x{1})'.format(
    	ret.toString(16),
    	ExceptionFilter.toString(16)
    ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
SetUnhandledExceptionFilter.install('kernel32.dll', 'SetUnhandledExceptionFilter');

/*
###################################################################################################
###################################################################################################
*/






var GetNativeSystemInfo = new ApiHook();
/*
void WINAPI GetNativeSystemInfo(
  _Out_ LPSYSTEM_INFO lpSystemInfo
);
*/
GetNativeSystemInfo.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // PC

    var lpSystemInfo = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	var SYSTEM_INFO = [0x09, 0x00, 0x00, 0x00, // dwOemId
					   0x00, 0x10, 0x00, 0x00, // dwPageSize
					   0x00, 0x00, 0x01, 0x00, // lpMinimumApplicationAddress
					   0xFF, 0xFF, 0xFE, 0xFF, // lpMaximumApplicationAddress
					   0x03, 0x00, 0x00, 0x00, // dwActiveProcessorMask
					   0x02, 0x00, 0x00, 0x00, // dwNumberOfProcessors
					   0xD8, 0x21, 0x00, 0x00, // dwProcessorType
					   0x00, 0x00, 0x01, 0x00, // dwAllocationGranularity
					   0x06, 0x00, 			   // wProcessorLevel
					   0x01, 0x46]			   // wProcessorRevision

	Emu.WriteMem(lpSystemInfo,SYSTEM_INFO);
    
    log('GetNativeSystemInfo(0x{0})'.format(
    	lpSystemInfo.toString(16)
    ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0x50001);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
GetNativeSystemInfo.install('kernel32.dll', 'GetNativeSystemInfo');

/*
###################################################################################################
###################################################################################################
*/


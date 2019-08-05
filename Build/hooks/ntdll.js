'use strict';

var LdrGetProcedureAddress = new ApiHook();
/*
NTSTATUS LdrGetProcedureAddress(
	HMODULE ModuleHandle, 
	PANSI_STRING FunctionName, 
	WORD Oridinal, 
	PVOID *FunctionAddress
);
*/
LdrGetProcedureAddress.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var ModuleHandle  	= Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var FunctionName 	= Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var Oridinal 		= Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var FunctionAddress	= Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();

	var len  = Emu.ReadWord(FunctionName);
	var name = Emu.ReadStringA(Emu.ReadDword(FunctionName+4),len);
	
	var Addr = Emu.GetProcAddr(ModuleHandle, name);
	Emu.WriteDword(FunctionAddress,Addr);


	// warn('Func = ', name);
	// info('Addr = ', Addr.toString(16));


	info("LdrGetProcedureAddress(0x{0}, '{1}', 0x{2}, 0x{3}) = 0x{4}".format(
		ModuleHandle.toString(16),
		name,
		Oridinal.toString(16),
		FunctionAddress.toString(16),
		Addr.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0); // just for now :P .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

LdrGetProcedureAddress.install('ntdll.dll', 'LdrGetProcedureAddress');


/*
###################################################################################################
###################################################################################################
*/

var memset_ = new ApiHook();
memset_.OnCallBack = function (Emu, API, ret) {
	// just let the library handle it :D 
	return true;
};
memset_.install('ntdll.dll' , 'memset');
memset_.install('msvcrt.dll', 'memset');

/*
###################################################################################################
###################################################################################################
*/

var NtQuerySystemInformation = new ApiHook();
/*
__kernel_entry NTSTATUS NtQuerySystemInformation(
  IN SYSTEM_INFORMATION_CLASS SystemInformationClass,
  OUT PVOID                   SystemInformation,
  IN ULONG                    SystemInformationLength,
  OUT PULONG ReturnLength     OPTIONAL
);
*/
NtQuerySystemInformation.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var SystemInformationClass  = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var SystemInformation 		= Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var SystemInformationLength = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var OPTIONAL	   			= Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();

	console.log("NtQuerySystemInformation(0x{0}, 0x{1}, 0x{2}, 0x{3})".format(
		SystemInformationClass.toString(16),
		SystemInformation.toString(16),
		SystemInformationLength.toString(16),
		OPTIONAL.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0); // just for now :P .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

NtQuerySystemInformation.install('ntdll.dll', 'NtQuerySystemInformation');
/*
###################################################################################################
###################################################################################################
*/

var RtlInitializeHandleTable = new ApiHook();
/*
NTSYSAPI VOID NTAPI RtlInitializeHandleTable(	
	_In_ ULONG 	TableSize,
	_In_ ULONG 	HandleSize,
	_In_ PRTL_HANDLE_TABLE 	HandleTable 
);
*/
RtlInitializeHandleTable.OnCallBack = function (Emu, API, ret) {

	// let the lib handle it 
	return true; // we handled the Stack and other things :D .
};

RtlInitializeHandleTable.install('ntdll.dll', 'RtlInitializeHandleTable');

/*
###################################################################################################
###################################################################################################
*/

var RtlDeleteCriticalSection = new ApiHook();
/*
RtlDeleteCriticalSection
*/
RtlDeleteCriticalSection.OnCallBack = function (Emu, API, ret) {

	// let the lib handle it 
	return true; // we handled the Stack and other things :D .
};

RtlDeleteCriticalSection.install('ntdll.dll', 'RtlDeleteCriticalSection');

/*
###################################################################################################
###################################################################################################
*/

var RtlInitializeCriticalSection = new ApiHook();
/*
 NTSTATUS RtlInitializeCriticalSection
 (
  RTL_CRITICAL_SECTION* crit
 )
*/
RtlInitializeCriticalSection.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var crit  = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	console.log("RtlInitializeCriticalSection(0x{0})".format(
		crit.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0); // just for now :P .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

RtlInitializeCriticalSection.install('ntdll.dll', 'RtlInitializeCriticalSection');
/*
###################################################################################################
###################################################################################################
*/


var RtlGetNtVersionNumbers = new ApiHook();
/*
 void RtlGetNtVersionNumbers
 (
  LPDWORD major,
  LPDWORD minor,
  LPDWORD build
 )
*/
RtlGetNtVersionNumbers.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var major = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var minor = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var build = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();

	if (major !== 0)
	  Emu.WriteDword(major,6);
	if (minor !== 0)
	  Emu.WriteDword(minor,1);
	if (build !== 0)
	  Emu.WriteDword(build,7601);

	warn("RtlGetNtVersionNumbers");

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

RtlGetNtVersionNumbers.install('ntdll.dll', 'RtlGetNtVersionNumbers');
/*
###################################################################################################
###################################################################################################
*/

var DeleteCriticalSection = new ApiHook();
/*
void DeleteCriticalSection(
  LPCRITICAL_SECTION lpCriticalSection
);
*/
DeleteCriticalSection.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var lpCriticalSection = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	log("DeleteCriticalSection(0x{0})".format(
		lpCriticalSection.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};
DeleteCriticalSection.install('kernelbase.dll', 'DeleteCriticalSection');
DeleteCriticalSection.install('kernel32.dll', 'DeleteCriticalSection');

/*
###################################################################################################
###################################################################################################
*/


var InitializeSRWLock = new ApiHook();
InitializeSRWLock.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};

InitializeSRWLock.install('ntdll.dll', 'InitializeSRWLock');
InitializeSRWLock.install('kernel32.dll', 'InitializeSRWLock');

/*
###################################################################################################
###################################################################################################
*/


/*
###################################################################################################
###################################################################################################
*/

var RtlInitUnicodeString = new ApiHook();
RtlInitUnicodeString.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};

RtlInitUnicodeString.install('ntdll.dll', 'RtlInitUnicodeString');
/*
###################################################################################################
###################################################################################################
*/

var _aulldvrm = new ApiHook();
_aulldvrm.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};

_aulldvrm.install('ntdll.dll', '_aulldvrm');
/*
###################################################################################################
###################################################################################################
*/



var RtlInitializeNtUserPfn = new ApiHook();
RtlInitializeNtUserPfn.OnCallBack = function (Emu, API, ret) {
	Emu.pop();

	if (Emu.isx64 !== true) {
		Emu.pop();
		Emu.pop();
		Emu.pop();
	}

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	// just let the library handle it :D 
	return true;
};

RtlInitializeNtUserPfn.install('ntdll.dll', 'RtlInitializeNtUserPfn');
RtlInitializeNtUserPfn.install('ntdll.dll', 'RtlRetrieveNtUserPfn');
/*
###################################################################################################
###################################################################################################
*/

var _snwprintf = new ApiHook();
_snwprintf.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	warn(API.name)
	return true;
};

_snwprintf.install('ntdll.dll', '_snwprintf');
_snwprintf.install('ntdll.dll', 'RtlAnsiCharToUnicodeChar');
_snwprintf.install('ntdll.dll', 'RtlMultiByteToUnicodeN');

/*
###################################################################################################
###################################################################################################
*/
/*
WCHAR RtlAnsiCharToUnicodeChar(
  _Inout_ PUCHAR *SourceCharacter
);
*/

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

/*
###################################################################################################
###################################################################################################
*/

var strcmp = new ApiHook();
/*
int strcmp(
  LPCWSTR lpString1,
  LPCWSTR lpString2
);
*/

strcmp.OnCallBack = function (Emu, API, ret) {

	strcmp.args[0] = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + 4);
	strcmp.args[1] = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + 8);
	// so just let the library handle it :D 
	return true;
};
strcmp.OnExit = function(Emu,API){

	var lpString1 = strcmp.args[0];
	var lpString2 = strcmp.args[1];

	warn("strcmp(0x{0} = '{1}' , 0x{2} = '{3}') = {4} ".format(
		lpString1.toString(16),
		Emu.ReadStringA(lpString1),
		lpString2.toString(16),
		Emu.ReadStringA(lpString2),
		Emu.ReadReg(REG_EAX).toString(16)
	));
}

strcmp.install('ntdll.dll', 'strcmp');

/*
###################################################################################################
###################################################################################################
*/


var ntdll_Gen = new ApiHook();
ntdll_Gen.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
ntdll_Gen.install('ntdll.dll', 'strcpy_s');
ntdll_Gen.install('ntdll.dll', 'strcat_s');

ntdll_Gen.install('ntdll.dll', 'RtlInitializeCriticalSectionAndSpinCount');
ntdll_Gen.install('ntdll.dll', 'RtlInitializeCriticalSectionEx');

ntdll_Gen.install('ntdll.dll', 'RtlImageNtHeader');

ntdll_Gen.install('ntdll.dll', 'RtlImageNtHeaderEx');

ntdll_Gen.install('ntdll.dll', 'RtlInitializeSRWLock');
ntdll_Gen.install('ntdll.dll', 'RtlRunOnceInitialize');
ntdll_Gen.install('ntdll.dll', 'RtlInitializeConditionVariable');


ntdll_Gen.install('ntdll.dll', 'RtlSetThreadPoolStartFunc');
ntdll_Gen.install('ntdll.dll', 'LdrSetDllManifestProber');

ntdll_Gen.install('ntdll.dll', 'RtlSetUnhandledExceptionFilter');

ntdll_Gen.install('ntdll.dll', 'RtlCreateTagHeap');

ntdll_Gen.install('ntdll.dll', 'InterlockedPushListSList');

ntdll_Gen.install('ntdll.dll', 'RtlGetNtGlobalFlags');











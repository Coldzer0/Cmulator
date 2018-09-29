// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';


// var CreateThread = new ApiHook();
// /*
// HANDLE CreateThread(
//   LPSECURITY_ATTRIBUTES   lpThreadAttributes,
//   SIZE_T                  dwStackSize,
//   LPTHREAD_START_ROUTINE  lpStartAddress,
//   __drv_aliasesMem LPVOID lpParameter,
//   DWORD                   dwCreationFlags,
//   LPDWORD                 lpThreadId
// );
// */
// CreateThread.OnCallBack = function (Emu, API, ret) {

// 	Emu.pop(); // return address

// 	Emu.pop(); // lpThreadAttributes




// 	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
// 	return true; // true if you handle it false if you want Emu to handle it and set PC .
// };
// CreateThread.install('kernel32.dll', 'CreateThread');
/*
###################################################################################################
###################################################################################################
*/

var CloseHandle = new ApiHook();
/*
CloseHandle
BOOL WINAPI CloseHandle(
  _In_ HANDLE hObject
);
*/
CloseHandle.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var hObject = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	info('CloseHandle(0x',hObject.toString(16),')');

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

CloseHandle.install('kernel32.dll', 'CloseHandle');

/*
###################################################################################################
###################################################################################################
*/

var TlsSlots = new Array(64); // Global Var :V ..
for (var i = TlsSlots.length - 1; i >= 0; i--) {
	TlsSlots[i] = 0;
}

var TlsIndex = 8;

var TlsAlloc = new ApiHook();

TlsAlloc.OnCallBack = function (Emu, API, ret) {
	Emu.pop();

	// print('TlsAlloc = index : ',TlsIndex);

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, TlsIndex);

	TlsIndex += 1;

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

TlsAlloc.install('kernel32.dll', 'TlsAlloc');

/*
###################################################################################################
###################################################################################################
*/


var TlsGetValue = new ApiHook();
TlsGetValue.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var index = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	var value;
	if (index <= 64){
		value = TlsSlots[index];
	}else{
		value = -1;
	}

	// print('TlsGetValue(',index,') = ',value.toString(16));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, value);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

TlsGetValue.install('kernel32.dll', 'TlsGetValue');

/*
###################################################################################################
###################################################################################################
*/


var TlsSetValue = new ApiHook();
TlsSetValue.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var index = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var value = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	if (index <= 64){
		TlsSlots[index] = value;
		Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	}else{
		value = -1;
		Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	}

	// print('TlsSetValue({0}, {1})'.format(index,value.toString(16)));

	
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

TlsSetValue.install('kernel32.dll', 'TlsSetValue');

/*
###################################################################################################
###################################################################################################
*/


var FlsSlots = new Array(128); // Global Var :V ..
for (var i = FlsSlots.length - 1; i >= 0; i--) {
	FlsSlots[i] = 0;
}
FlsSlots[1] = (0x40000000 + 0x60000);

var FlsIndex = 1;

var FlsAlloc = new ApiHook();
/*
DWORD WINAPI FlsAlloc(
  _In_ PFLS_CALLBACK_FUNCTION lpCallback
);
*/
FlsAlloc.OnCallBack = function (Emu, API, ret) {
	Emu.pop();

	var lpCallback = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	// print('FlsAlloc(0x{0}) = {1} '.format(
	// 	lpCallback.toString(16),
	// 	FlsIndex
	// ));


	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, FlsIndex);

	FlsIndex += 1;

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

FlsAlloc.install('kernel32.dll', 'FlsAlloc');
FlsAlloc.install('api-ms-win-core-fibers-l1-1-0.dll', 'FlsAlloc');

/*
###################################################################################################
###################################################################################################
*/

var FlsFree = new ApiHook();
/*
BOOL WINAPI FlsFree(
  _In_ DWORD dwFlsIndex
);
*/
FlsFree.OnCallBack = function (Emu, API, ret) {
	Emu.pop();

	var dwFlsIndex = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	// print('FlsFree(0x{0}) = {1} '.format(
	// 	lpCallback.toString(16),
	// 	FlsIndex
	// ));

	FlsSlots[FlsFree] = 0;

	// TODO: add ident for index.

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, dwFlsIndex);

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

FlsFree.install('kernel32.dll', 'FlsFree');
FlsFree.install('api-ms-win-core-fibers-l1-1-0.dll', 'FlsFree');

/*
###################################################################################################
###################################################################################################
*/

var FlsSetValue = new ApiHook();
/*
BOOL WINAPI FlsSetValue(
  _In_     DWORD dwFlsIndex,
  _In_opt_ PVOID lpFlsData
);
*/
FlsSetValue.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var index = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var value = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	var val = -1;
	if (index <= 128){
		FlsSlots[index] = value;
		val = 1;
	}

	// print('FlsSetValue(0x{0}, 0x{1})'.format(
	// 	index.toString(16),
	// 	value.toString(16)
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, val);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

FlsSetValue.install('kernel32.dll', 'FlsSetValue');
FlsSetValue.install('api-ms-win-core-fibers-l1-1-0.dll', 'FlsSetValue');

/*
###################################################################################################
###################################################################################################
*/

var FlsGetValue = new ApiHook();
/*
PVOID WINAPI FlsGetValue(
  _In_ DWORD dwFlsIndex
);
*/
FlsGetValue.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var index = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	var value = -1;


	if (index <= 128){
		value = FlsSlots[index]
	}

	// print('FlsGetValue(0x{0}) = 0x{1}'.format(index.toString(16),value.toString(16)));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, value);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

FlsGetValue.install('kernel32.dll', 'FlsGetValue');
FlsGetValue.install('api-ms-win-core-fibers-l1-1-0.dll', 'FlsGetValue');

/*
###################################################################################################
###################################################################################################
*/
var lastError = 0;

var GetLastError = new ApiHook();
GetLastError.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret
	
	// print('GetLastError : ',lastError);
	
	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);	
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

GetLastError.install('kernel32.dll', 'GetLastError');
GetLastError.install('api-ms-win-core-errorhandling-l1-1-0.dll', 'GetLastError');
/*
###################################################################################################
###################################################################################################
*/


var SetLastError = new ApiHook();
SetLastError.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	lastError = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	// print('SetLastError : ',lastError);

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

SetLastError.install('kernel32.dll', 'SetLastError');
SetLastError.install('api-ms-win-core-errorhandling-l1-1-0.dll', 'SetLastError');

/*
###################################################################################################
###################################################################################################
*/

var EnterCriticalSection = new ApiHook();
/*
void EnterCriticalSection(
  LPCRITICAL_SECTION lpCriticalSection
);
*/
EnterCriticalSection.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var lpCriticalSection = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	// print('EnterCriticalSection(0x',lpCriticalSection.toString(16),')');

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

EnterCriticalSection.install('kernel32.dll', 'EnterCriticalSection');
EnterCriticalSection.install('api-ms-win-core-synch-l1-1-0.dll', 'EnterCriticalSection');

/*
###################################################################################################
###################################################################################################
*/

var InterlockedIncrement = new ApiHook();
/*
unsigned InterlockedIncrement(
  _Interlocked_operand_ unsigned *Addend
);
*/
InterlockedIncrement.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var Addend = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	var val = (Emu.isx64 ? Emu.ReadQword(Addend) : Emu.ReadDword(Addend)) + 1;
	Emu.isx64 ? Emu.WriteQword(Addend,val) : Emu.WriteDword(Addend,val);

	// print('InterlockedIncrement(0x{0}) = {1}'.format(
	// 	Addend.toString(16),
	// 	val
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, val);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

InterlockedIncrement.install('kernel32.dll', 'InterlockedIncrement');
InterlockedIncrement.install('api-ms-win-core-interlocked-l1-1-0.dll', 'InterlockedIncrement');


/*
###################################################################################################
###################################################################################################
*/

var InterlockedDecrement = new ApiHook();
/*
unsigned InterlockedDecrement(
  _Interlocked_operand_ unsigned *Addend
);
*/
InterlockedDecrement.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var Addend = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	var val = (Emu.isx64 ? Emu.ReadQword(Addend) : Emu.ReadDword(Addend)) - 1;

	Emu.isx64 ? Emu.WriteQword(Addend,val) : Emu.WriteDword(Addend,val);

	// print('InterlockedDecrement(0x{0}) = {1}'.format(
	// 	Addend.toString(16),
	// 	val
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, val);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

InterlockedDecrement.install('kernel32.dll', 'InterlockedDecrement');
InterlockedDecrement.install('api-ms-win-core-interlocked-l1-1-0.dll', 'InterlockedDecrement');


/*
###################################################################################################
###################################################################################################
*/

var LeaveCriticalSection = new ApiHook();
/*
void LeaveCriticalSection(
  LPCRITICAL_SECTION lpCriticalSection
);
*/
LeaveCriticalSection.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var lpCriticalSection = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	// print('LeaveCriticalSection(0x',lpCriticalSection.toString(16),')');

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

LeaveCriticalSection.install('kernel32.dll', 'LeaveCriticalSection');


/*
###################################################################################################
###################################################################################################
*/


var GetCurrentThreadId = new ApiHook();
/*
DWORD GetCurrentThreadId();
*/
GetCurrentThreadId.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	print('GetCurrentThreadId = ', 1001);

	Emu.SetReg(REG_EAX, 1001); // DWORD for both x32 & x64 .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
GetCurrentThreadId.install('kernel32.dll', 'GetCurrentThreadId');
GetCurrentThreadId.install('api-ms-win-core-processthreads-l1-1-0.dll', 'GetCurrentThreadId');

/*
###################################################################################################
###################################################################################################
*/

var GetCurrentProcess = new ApiHook();
/*
DWORD GetCurrentProcess();
*/
GetCurrentProcess.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	print('GetCurrentProcess = ', 9090);

	Emu.SetReg(REG_EAX, 9090); // DWORD for both x32 & x64 .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

GetCurrentProcess.install('kernel32.dll', 'GetCurrentProcess');
// GetCurrentProcessId.install('api-ms-win-core-processthreads-l1-1-0.dll', 'GetCurrentProcessId');
/*
###################################################################################################
###################################################################################################
*/

var GetCurrentProcessId = new ApiHook();
/*
DWORD GetCurrentProcessId();
*/
GetCurrentProcessId.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	print('GetCurrentProcessId = ', 1002);

	Emu.SetReg(REG_EAX, 1002); // DWORD for both x32 & x64 .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

GetCurrentProcessId.install('kernel32.dll', 'GetCurrentProcessId');
GetCurrentProcessId.install('api-ms-win-core-processthreads-l1-1-0.dll', 'GetCurrentProcessId');
/*
###################################################################################################
###################################################################################################
*/

var IsWow64Process = new ApiHook();
/*
BOOL IsWow64Process(
  HANDLE hProcess,
  PBOOL  Wow64Process
);
*/
IsWow64Process.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var hProcess 	 = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var Wow64Process = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	warn('IsWow64Process(0x{0},0x{1})'.format(
		hProcess.toString(16),
		Wow64Process.toString(16)
	));

	Emu.WriteDword(Wow64Process,1); // change it as you like :D 

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

IsWow64Process.install('kernel32.dll', 'IsWow64Process');

/*
###################################################################################################
###################################################################################################
*/

var CheckRemoteDebuggerPresent = new ApiHook();
/*
BOOL WINAPI CheckRemoteDebuggerPresent(
  _In_    HANDLE hProcess,
  _Inout_ PBOOL  pbDebuggerPresent
);
*/
CheckRemoteDebuggerPresent.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var hProcess 	 	  = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var pbDebuggerPresent = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	warn('CheckRemoteDebuggerPresent(0x{0},0x{1})'.format(
		hProcess.toString(16),
		pbDebuggerPresent.toString(16)
	));

	Emu.WriteDword(pbDebuggerPresent,0); // change it as you like :D 

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

CheckRemoteDebuggerPresent.install('kernel32.dll', 'CheckRemoteDebuggerPresent');

/*
###################################################################################################
###################################################################################################
*/

// win7 x64 - GetThreadLocale = 1033
var GetThreadLocale = new ApiHook();
GetThreadLocale.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	// it reads it from TEB .
/*
	// GetThreadLocale
	75E026BF | 64:A1 18000000 | mov eax,dword ptr fs:[18]     | 
	75E026C5 | 8B80 C4000000  | mov eax,dword ptr ds:[eax+C4] |
	75E026CB | C3             | ret                           |
*/
	return true;
};
GetThreadLocale.install('kernel32.dll', 'GetThreadLocale');

/*
###################################################################################################
###################################################################################################
*/


var DuplicateHandle = new ApiHook();
/*
BOOL WINAPI DuplicateHandle(
  _In_  HANDLE   hSourceProcessHandle,
  _In_  HANDLE   hSourceHandle,
  _In_  HANDLE   hTargetProcessHandle,
  _Out_ LPHANDLE lpTargetHandle,
  _In_  DWORD    dwDesiredAccess,
  _In_  BOOL     bInheritHandle,
  _In_  DWORD    dwOptions
);
*/
DuplicateHandle.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var hSourceProcessHandle = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var hSourceHandle	  	 = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var hTargetProcessHandle = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var lpTargetHandle	  	 = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var dwDesiredAccess 	 = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 
	var bInheritHandle 		 = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 1)) : Emu.pop(); 
	var dwOptions  	  	  	 = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 2)) : Emu.pop(); 


	var result = 0;
	if (lpTargetHandle !== 0) {
		if (hSourceProcessHandle !== 9090){
			Emu.isx64 ? Emu.WriteQword(lpTargetHandle,8080) : Emu.WriteDword(lpTargetHandle,8080);
		}
		result = 1;
	}

	warn("DuplicateHandle(0x{0}, 0x{1}, 0x{2}, Out 0x{3} = 8080, 0x{4}, 0x{5}, 0x{6})".format(
		hSourceProcessHandle.toString(16),
		hSourceHandle.toString(16),
		hTargetProcessHandle.toString(16),
		lpTargetHandle.toString(16),
		dwDesiredAccess.toString(16),
		bInheritHandle.toString(16),
		dwOptions.toString(16)
	))

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, result);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true;
};

DuplicateHandle.install('kernel32.dll','DuplicateHandle');


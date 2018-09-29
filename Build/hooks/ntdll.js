'use strict';


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
DeleteCriticalSection.install('api-ms-win-core-synch-l1-1-0.dll', 'DeleteCriticalSection');

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
InitializeSRWLock.install('api-ms-win-core-synch-l1-1-0.dll', 'InitializeSRWLock');

/*
###################################################################################################
###################################################################################################
*/


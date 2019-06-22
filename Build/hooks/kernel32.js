'use strict';



var RegKrnInitialize = new ApiHook();
RegKrnInitialize.OnCallBack = function (Emu, API,ret) {

	Emu.pop()// ret

	var Base 	= Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var Reason  = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var revered = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();

	print("RegKrnInitialize(0x{0},0x{1},0x{2})".format(
		Base.toString(16),
		Reason.toString(16),
		revered.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
RegKrnInitialize.install('kernel32.dll', 'RegKrnInitialize');

/*
###################################################################################################
###################################################################################################
*/
var ExitProcess = new ApiHook();
ExitProcess.OnCallBack = function (Emu, API,ret) {

	Emu.pop();

	var ExitCode = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	error("{0}(0x{1})".format(
		API.name,
		ExitCode.toString(16)
	));

	Emu.Stop();

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

ExitProcess.install('kernel32.dll', 'FatalExit');
ExitProcess.install('kernel32.dll', 'ExitProcess');
ExitProcess.install('ntdll.dll', 'RtlExitUserThread');
ExitProcess.install('ntdll.dll', 'RtlExitUserProcess');
ExitProcess.install('ucrtbase.dll', 'exit');
ExitProcess.install('ucrtbase.dll', '_Exit');

/*
###################################################################################################
###################################################################################################
*/

var IsDebuggerPresent = new ApiHook();
IsDebuggerPresent.OnCallBack = function (Emu, API,ret) {

	Emu.pop(); // ret

	var value = 0; // set result to 0 :D

	warn('IsDebuggerPresent = ' + value);

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, value);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

IsDebuggerPresent.install('kernel32.dll', 'IsDebuggerPresent');

// TODO: remove after implementing apisetschema Forwarder .
IsDebuggerPresent.install('api-ms-win-core-debug-l1-1-0.dll', 'IsDebuggerPresent');

/*
###################################################################################################
###################################################################################################
*/

var OpenProcess = new ApiHook();
OpenProcess.OnCallBack = function (Emu, API,ret) {

	print('OpenProcess : TODO or implement it your self :P ');

	return false; // true if you handle it false if you want Emu to handle it and set PC .
};
OpenProcess.install('kernel32.dll', 'OpenProcess');

/*
###################################################################################################
###################################################################################################
*/

var GetModuleHandleW = new ApiHook();
GetModuleHandleW.OnCallBack = function (Emu, API,ret) {

	Emu.pop(); // ret PC .. 

	var mPtr;
	var handle;
	var text;

	if (Emu.isx64){

		mPtr = Emu.ReadReg(REG_RCX);

		if (mPtr !== 0){
			text = API.IsWapi ? Emu.ReadStringW(mPtr) : Emu.ReadStringA(mPtr);
			handle = Emu.GetModuleHandle(text); // return module handle (Base Address).
		}else{
			handle = Emu.ImageBase;
		}

	} else {

		mPtr = Emu.pop(); // module str Pointer ..
		if (mPtr !== 0) {

			text = API.IsWapi ? Emu.ReadStringW(mPtr) : Emu.ReadStringA(mPtr);
			handle = Emu.GetModuleHandle(text);

		}else{
			handle = Emu.ImageBase;
		}
	}

	if (text == undefined){
		text = '#0'
	}

	var log = "GetModuleHandle('{0}') = {1} ".format(
			text, 
			handle.toString(16).toUpperCase()
		);

	console.log(log);

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, handle);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;// true if you handle it false if you want Emu to handle it and set PC .
};

GetModuleHandleW.install('kernel32.dll', 'GetModuleHandleW');
GetModuleHandleW.install('kernel32.dll', 'GetModuleHandleA');

GetModuleHandleW.install('api-ms-win-core-libraryloader-l1-1-0.dll', 'GetModuleHandleW');
// api-ms-win-core-libraryloader-l1-1-0.dll.GetModuleHandleW


/*
###################################################################################################
###################################################################################################
*/

var LdrGetDllHandle = new ApiHook();
/*
LdrGetDllHandle(
  IN PWORD                pwPath OPTIONAL,
  IN PVOID                Unused OPTIONAL,
  IN PUNICODE_STRING      ModuleFileName,
  OUT PHANDLE             pHModule 
);
*/
LdrGetDllHandle.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var pwPath    	   = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var Unused 		   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var ModuleFileName = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var pHModule	   = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();

	var modulename = Emu.ReadStringW(Emu.ReadDword(ModuleFileName+4));

	log("LdrGetDllHandle('{0}',{1},'{2}',{3})".format(
		Emu.ReadStringA(pwPath),
		Unused.toString(16),
		modulename,
		pHModule.toString(16)
	));

	var handle = Emu.GetModuleHandle(modulename);
	if (handle == 0) handle = Emu.ImageBase;

	Emu.WriteDword(pHModule,handle); 

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
LdrGetDllHandle.install('ntdll.dll', 'LdrGetDllHandle');


/*
###################################################################################################
###################################################################################################
*/

var GetProcAddress = new ApiHook();
/* FFARPROC WINAPI GetProcAddress(  HMODULE hModule,  LPCSTR lpProcName);*/
GetProcAddress.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pc 

	var hModule;
	var pName;
	var FnName;
	
	if (Emu.isx64) {
		hModule = Emu.ReadReg(REG_RCX);
		pName = Emu.ReadReg(REG_RDX);
	}else{
		hModule = Emu.pop();
		pName = Emu.pop();
	}

	FnName = Emu.ReadStringA(pName);

	// GetProcAddr will get Base of lib if loaded by the PE .
	var addr = Emu.GetProcAddr(hModule, FnName);

	warn("GetProcAddress(0x{0},'{1}') = 0x{2}".format(
		hModule.toString(16).toUpperCase(), 
		FnName,
		addr.toString(16).toUpperCase()
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, addr);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetProcAddress.install('kernel32.dll', 'GetProcAddress');
GetProcAddress.install('kernelbase.dll', 'GetProcAddress');

/*
###################################################################################################
###################################################################################################
*/
var LoadLibrary = new ApiHook();
/*
HMODULE WINAPI LoadLibrary(
  _In_ LPCTSTR lpFileName
);

HMODULE LoadLibraryExW(
  LPCWSTR lpLibFileName,
  HANDLE  hFile,
  DWORD   dwFlags
);
*/
LoadLibrary.OnCallBack = function (Emu, API,ret) {

	Emu.pop(); // ret PC .. 

	var lpFileName = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var Libname = API.IsWapi ? Emu.ReadStringW(lpFileName) : Emu.ReadStringA(lpFileName);
	var handle  = Emu.LoadLibrary(Libname);

	if (API.IsEx) {
		
		var hFile   = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
		var dwFlags = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();

		log("{0}('{1}', 0x{2}, 0x{3}) = 0x{4}".format(
			API.name,
			Libname, 
			hFile.toString(16),
			dwFlags.toString(16),
			handle.toString(16)
		));

	} else {

		print("{0}('{1}') = 0x{2}".format(
			API.name,
			Libname, 
			handle.toString(16)
		));	
	}

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, handle);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;// true if you handle it false if you want Emu to handle it and set PC .
};

LoadLibrary.install('kernel32.dll', 'LoadLibraryA'); // Ordinal = 829 in Current dll i use.
LoadLibrary.install('kernel32.dll', 'LoadLibraryW');

LoadLibrary.install('kernel32.dll', 'LoadLibraryExA');
LoadLibrary.install('kernel32.dll', 'LoadLibraryExW');

/*
###################################################################################################
###################################################################################################
*/


var FreeLibrary = new ApiHook();
/*
	BOOL WINAPI FreeLibrary(
	  _In_ HMODULE hModule
	);
*/
FreeLibrary.OnCallBack = function (Emu, API,ret) {

	Emu.pop(); // ret PC .. 

	var hModule = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	
	print("FreeLibrary(0x{0})".format(
		hModule.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;// true if you handle it false if you want Emu to handle it and set PC .
};

FreeLibrary.install('kernel32.dll', 'FreeLibrary');
/*
###################################################################################################
###################################################################################################
*/
var WinExec = new ApiHook();
/* UINT WINAPI WinExec( LPCSTR lpCmdLine, UINT uCmdShow);  */
WinExec.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // PC

    var cmd  = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
    var show = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	warn("WinExec('{0}', {1})".format(
		Emu.ReadStringA(cmd),
		show
	));

    Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 32); // return 32 << from MS docs. 
    Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
WinExec.install('kernel32.dll', 'WinExec');

/*
###################################################################################################
###################################################################################################
*/

var GetTempPathA = new ApiHook();
/*
DWORD WINAPI GetTempPath(
	__in   DWORD nBufferLength,
	__out  LPTSTR lpBuffer
);
*/
GetTempPathA.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // PC - EIP ..
	
	if (Emu.isx64) {
		print('TODO: x64 for GetTempPath');
		return false;
	} else {
		
		var BufLen   = Emu.pop(); // nBufferLength
		var lpBuffer = Emu.pop(); // lpBuffer 

		var tmp = "C:\\Windows\\Temp\\";
		var len = Emu.WriteStringA(lpBuffer,tmp); // lpCmdLine .

		if (len > 0){
			var msg = "GetTempPathA({0}, {1}) = {2} - '{3}'".format(
				BufLen,
				lpBuffer.toString(16),
				len,
				tmp
			);
			console.log(msg);
		}

	}

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, len); // return 32 << from MS docs.
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetTempPathA.install('kernel32.dll', 'GetTempPathA');

/*
###################################################################################################
###################################################################################################
*/

var GetWindowsDirectory = new ApiHook();
/*
UINT WINAPI GetWindowsDirectory(
  _Out_ LPTSTR lpBuffer,
  _In_  UINT   uSize
);
*/
GetWindowsDirectory.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // return addr ..		
		
	var lpBuffer = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var uSize    = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	var tmp = "C:\\Windows";
	var len = API.IsWapi ? Emu.WriteStringW(lpBuffer,tmp) : Emu.WriteStringA(lpBuffer,tmp); // lpCmdLine .

	if (len > 0){
		var msg = "GetWindowsDirectory{0}({1}, {2}) = {3} - '{4}'".format(
			API.IsWapi ? 'W' : 'A',
			lpBuffer.toString(16),
			uSize,
			len,
			tmp
		);
		console.log(msg);
	}

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, len); // return len << from MS docs.
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetWindowsDirectory.install('kernel32.dll', 'GetWindowsDirectoryA');
GetWindowsDirectory.install('kernel32.dll', 'GetWindowsDirectoryW');


/*
###################################################################################################
###################################################################################################
*/

// 0028E9F4   0028EA18  L"C:\\Windows\\system32"
var GetSystemDirectory = new ApiHook();
/*
UINT WINAPI GetSystemDirectory(
  _Out_ LPTSTR lpBuffer,
  _In_  UINT   uSize
);
*/
GetSystemDirectory.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // return addr ..
		
	var lpBuffer = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var uSize    = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	var tmp = "C:\\Windows\\system32";
	var len = API.IsWapi ? Emu.WriteStringW(lpBuffer,tmp) : Emu.WriteStringA(lpBuffer,tmp); // lpCmdLine .

	if (len > 0){
		var msg = "GetSystemDirectory{0}({1}, {2}) = {3} - '{4}'".format(
			API.IsWapi ? 'W' : 'A',
			lpBuffer.toString(16),
			uSize,
			len,
			tmp
		);
		console.log(msg);
	}

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, len); // return len << from MS docs.
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetSystemDirectory.install('kernel32.dll', 'GetSystemDirectoryA');
GetSystemDirectory.install('kernel32.dll', 'GetSystemDirectoryW');

/*
###################################################################################################
###################################################################################################
*/

var GetCurrentDirectory = new ApiHook();
/*
DWORD GetCurrentDirectory(
  DWORD  nBufferLength,
  LPTSTR lpBuffer
);
*/
GetCurrentDirectory.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // return addr ..
		
	var nBufferLength = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpBuffer      = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	var len = 0;
	var tmp = "C:\\pla";
	
	if (nBufferLength > 0){	
		len = API.IsWapi ? Emu.WriteStringW(lpBuffer,tmp) : Emu.WriteStringA(lpBuffer,tmp);
	}

	log("{0}({1}, {2}) = '{3}'".format(
			API.name,
			nBufferLength,
			lpBuffer.toString(16),
			(len > 0) ? tmp : ''
		));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, len); // return len << from MS docs.
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetCurrentDirectory.install('kernel32.dll', 'GetCurrentDirectoryA');
GetCurrentDirectory.install('kernel32.dll', 'GetCurrentDirectoryW');

/*
###################################################################################################
###################################################################################################
*/

var GetFullPathName = new ApiHook();
/*
DWORD GetFullPathName(
  LPCSTR lpFileName,
  DWORD  nBufferLength,
  LPSTR  lpBuffer,
  LPSTR  *lpFilePart
);
*/
GetFullPathName.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // return addr ..
		
	var lpFileName 	   = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var nBufferLength  = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var lpBuffer	   = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var lpFilePart	   = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();

	var len = 0;

	if (lpFileName !== 0){

		var FileName = API.IsWapi ? Emu.ReadStringW(lpFileName) : Emu.ReadStringA(lpFileName);

		len = API.IsWapi ? Emu.WriteStringW(lpBuffer,FileName) : Emu.WriteStringA(lpBuffer,FileName);

		API.IsWapi ? Emu.WriteWord(lpBuffer + (len * 2),0) : Emu.WriteByte(lpBuffer+len,0);
	}

	log("{0}('{1}', {2}, 0x{3}, 0x{4})".format(
		API.name,
		FileName,
		nBufferLength,
		lpBuffer.toString(16),
		lpFilePart.toString(16)
	));

	// Emu.HexDump(lpFileName,32);

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, len); // return len << from MS docs.
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetFullPathName.install('kernel32.dll', 'GetFullPathNameA');
GetFullPathName.install('kernel32.dll', 'GetFullPathNameW');

/*
###################################################################################################
###################################################################################################
*/

/*
###################################################################################################
###################################################################################################
*/

var lstrcat = new ApiHook();
/*
LPTSTR WINAPI lstrcat(
  _Inout_ LPTSTR lpString1,
  _In_    LPTSTR lpString2
);
*/
lstrcat.OnCallBack = function (Emu, API, ret) {
	
	// Emu.pop(); // return addr ..
	
	// if (Emu.isx64) {
	// 	return false;
	// } else {
		
	// 	var lpString1 = Emu.pop(); // lpString1 
	// 	var lpString2 = Emu.pop(); // lpString2

	// 	var lpString1_s = API.IsWapi ? Emu.ReadStringW(lpString1) : Emu.ReadStringA(lpString1);
	// 	var lpString2_s = API.IsWapi ? Emu.ReadStringW(lpString2) : Emu.ReadStringA(lpString2);

	// 	var StrPtr = lpString1 + (API.IsWapi ? (lpString1_s.length * 2) : lpString1_s.length); // set the next pos to write

	// 	var len = API.IsWapi ? Emu.WriteStringW(StrPtr,lpString2_s) : Emu.WriteStringA(StrPtr,lpString2_s);

	// 	var msg = "lstrcat{0}('{1}', '{2}') = {3}".format(
	// 		API.IsWapi ? 'W' : 'A',
	// 		lpString1_s,
	// 		lpString2_s,
	// 		(lpString1_s + lpString2_s)
	// 	);
	// 	console.log(msg);
	// }

	// Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, len); // return len << from MS docs.
	// Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // let lib handle it :D
};
lstrcat.install('kernel32.dll', 'lstrcatA');
lstrcat.install('kernel32.dll', 'lstrcatW');
lstrcat.install('kernel32.dll', 'lstrcat');

/*
###################################################################################################
###################################################################################################
*/

var GetVersion = new ApiHook();
/* DWORD WINAPI GetVersion(void); */
GetVersion.OnCallBack = function (Emu, API, ret) {

	Emu.pop();	

  /*
	+------------------------------------------------------------------------------+
	|                    |   PlatformID    |   Major version   |   Minor version   |
	+------------------------------------------------------------------------------+
	| Windows 95         |  Win32Windows   |         4         |          0        |
	| Windows 98         |  Win32Windows   |         4         |         10        |
	| Windows Me         |  Win32Windows   |         4         |         90        |
	| Windows NT 4.0     |  Win32NT        |         4         |          0        |
	| Windows 2000       |  Win32NT        |         5         |          0        |
	| Windows XP         |  Win32NT        |         5         |          1        |
	| Windows 2003       |  Win32NT        |         5         |          2        |
	| Windows Vista      |  Win32NT        |         6         |          0        |
	| Windows 2008       |  Win32NT        |         6         |          0        |
	| Windows 7          |  Win32NT        |         6         |          1        |
	| Windows 2008 R2    |  Win32NT        |         6         |          1        |
	| Windows 8          |  Win32NT        |         6         |          2        |
	| Windows 8.1        |  Win32NT        |         6         |          3        |
	+------------------------------------------------------------------------------+
	| Windows 10         |  Win32NT        |        10         |          0        |
	+------------------------------------------------------------------------------+
     Win32Windows = 1; | Win32NT = 2;
  */

	var platformId = 2;
	var majorVersion = 6;
	var minorVersion = 3;
	var Version = (platformId << 16) | (minorVersion << 8) | majorVersion;

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, Version);


	console.log('GetVersion : ', Emu.ReadReg(Emu.isx64 ? REG_RAX : REG_EAX).toString(16) );
	
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetVersion.install('kernel32.dll', 'GetVersion');

/*
###################################################################################################
###################################################################################################
*/
var GetVersionExW = new ApiHook();
/* 
BOOL WINAPI GetVersionEx(
  _Inout_ LPOSVERSIONINFO lpVersionInfo
);
*/
GetVersionExW.OnCallBack = function (Emu, API, ret) {

	Emu.pop();	
/*
typedef struct _OSVERSIONINFOEXA {
  DWORD dwOSVersionInfoSize;
  DWORD dwMajorVersion;
  DWORD dwMinorVersion;
  DWORD dwBuildNumber;
  DWORD dwPlatformId;
  CHAR  szCSDVersion[128];
  WORD  wServicePackMajor;
  WORD  wServicePackMinor;
  WORD  wSuiteMask;
  BYTE  wProductType;
  BYTE  wReserved;
} OSVERSIONINFOEXA, *POSVERSIONINFOEXA, *LPOSVERSIONINFOEXA;
*/
	var lpVersionInfo = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	if ( lpVersionInfo > 0x10000 ){
		Emu.WriteDword(lpVersionInfo,156);    // dwOSVersionInfoSize

		Emu.WriteDword(lpVersionInfo+4, 6);    // dwMajorVersion
		Emu.WriteDword(lpVersionInfo+8, 1);    // dwMinorVersion
		Emu.WriteDword(lpVersionInfo+12,7601); // dwBuildNumber
		Emu.WriteDword(lpVersionInfo+16,2);    // dwPlatformId

		API.IsWapi ? Emu.WriteStringW(lpVersionInfo+20,'Service Pack 1') : Emu.WriteStringA(lpVersionInfo+20,'Service Pack 1');
	}

	info(API.name,'(0x{0})'.format(
		lpVersionInfo.toString(16)
	));

	// Emu.HexDump(lpVersionInfo,120);

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetVersionExW.install('kernel32.dll', 'GetVersionEx');
GetVersionExW.install('kernel32.dll', 'GetVersionExA');
GetVersionExW.install('kernel32.dll', 'GetVersionExW');
GetVersionExW.install('api-ms-win-core-sysinfo-l1-1-0.dll', 'GetVersionExW');

/*
###################################################################################################
###################################################################################################
*/

var Sleep = new ApiHook();

Sleep.OnCallBack = function (Emu, API, ret) {


	// Emu.Stop();
	// console.log('Sleep stop for testing ');
	// return false;

	Emu.pop();// return address .

	var dwMilliseconds = Emu.pop();
	warn('Sleep(',dwMilliseconds,')');

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
Sleep.install('kernel32.dll', 'Sleep'); // 0x4B3 by Ordinal for testing

/*
###################################################################################################
###################################################################################################
*/

var SetThreadLocale = new ApiHook();
/*
BOOL SetThreadLocale(
  LCID Locale
);
*/
SetThreadLocale.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // return address

	var locale = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	console.log('SetThreadLocale(',locale,')');

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
SetThreadLocale.install('kernel32.dll', 'SetThreadLocale');

/*
###################################################################################################
###################################################################################################
*/

var GetSystemInfo = new ApiHook();
/*
void WINAPI GetSystemInfo(
  _Out_ LPSYSTEM_INFO lpSystemInfo
);
*/
GetSystemInfo.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // return address

	var lpSystemInfo = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	error('GetSystemInfo(lpSystemInfo = 0x', lpSystemInfo.toString(16) ,') - TODO Set data to lpSystemInfo ');

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetSystemInfo.install('kernel32.dll', 'GetSystemInfo');

/*
###################################################################################################
###################################################################################################
*/

var pla = 0x40000000; // TODO: make it dynamic .


var LocalAlloc = new ApiHook();
/*
DECLSPEC_ALLOCATOR HLOCAL LocalAlloc(
  UINT   uFlags,
  SIZE_T uBytes
);
*/
LocalAlloc.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // return address

	var uFlags = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var uBytes = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	console.log('LocalAlloc({0}, {1}) = 0x{2}'.format(uFlags,uBytes,(pla).toString(16)));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, pla );
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);


	pla += uBytes;

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
LocalAlloc.install('kernel32.dll', 'LocalAlloc');

LocalAlloc.install('api-ms-win-core-misc-l1-1-0.dll', 'LocalAlloc');

/*
###################################################################################################
###################################################################################################
*/

var LocalFree = new ApiHook();
/*
HLOCAL LocalFree(
  _Frees_ptr_opt_ HLOCAL hMem
);
*/
LocalFree.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // return address

	var hMem = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	log('LocalFree(0x{0})'.format(
		hMem.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0 );
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
LocalFree.install('kernel32.dll', 'LocalFree');
LocalFree.install('api-ms-win-core-misc-l1-1-0.dll', 'LocalFree');

/*
###################################################################################################
###################################################################################################
*/

var HeapCreate = new ApiHook();
/*
HANDLE HeapCreate(
  DWORD  flOptions,
  SIZE_T dwInitialSize,
  SIZE_T dwMaximumSize
);
*/
HeapCreate.OnCallBack = function (Emu, API, ret) {
	Emu.pop();


	var flOptions     = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwInitialSize = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var dwMaximumSize = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();

	print('HeapCreate({0}, {1}, {2}) = 0x{3}'.format(
		flOptions,
		dwInitialSize,
		dwMaximumSize,
		pla.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, pla+0x10);
	pla += dwInitialSize + 0x10;

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

HeapCreate.install('kernel32.dll', 'HeapCreate');
HeapCreate.install('api-ms-win-core-heap-l1-1-0.dll', 'HeapCreate');

/*
###################################################################################################
###################################################################################################
*/

var HeapFree = new ApiHook();
/*
BOOL HeapFree(
  HANDLE  hHeap,
  DWORD   dwFlags,
  LPVOID  lpMem
);
*/
HeapFree.OnCallBack = function (Emu, API, ret) {
	Emu.pop();


	var hHeap   = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwFlags = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var lpMem   = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();

	// print('HeapFree(0x{0}, {1}, 0x{2}) = always true'.format(
	// 	hHeap.toString(16),
	// 	dwFlags,
	// 	lpMem.toString(16)
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

HeapFree.install('kernel32.dll', 'HeapFree');

/*
###################################################################################################
###################################################################################################
*/

var HeapSetInformation = new ApiHook();
/*
BOOL HeapSetInformation(
  HANDLE                 HeapHandle,
  HEAP_INFORMATION_CLASS HeapInformationClass,
  PVOID                  HeapInformation,
  SIZE_T                 HeapInformationLength
);
*/
HeapSetInformation.OnCallBack = function (Emu, API, ret) {
	Emu.pop();


	var HeapHandle     		  = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var HeapInformationClass  = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var HeapInformation  	  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var HeapInformationLength = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();

	print('HeapSetInformation(0x{0}, 0x{1}, 0x{2}, 0x{3})'.format(
		HeapHandle.toString(16),
		HeapInformationClass.toString(16),
		HeapInformation.toString(16),
		HeapInformationLength.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

HeapSetInformation.install('kernel32.dll', 'HeapSetInformation');
/*
###################################################################################################
###################################################################################################
*/

var HeapAlloc = new ApiHook();
/*
DECLSPEC_ALLOCATOR LPVOID HeapAlloc(
  HANDLE hHeap,
  DWORD  dwFlags,
  SIZE_T dwBytes
);
*/
HeapAlloc.OnCallBack = function (Emu, API, ret) {
	Emu.pop();


	var hHeap   = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwFlags = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var dwBytes = Emu.isx64 ? Emu.ReadReg(REG_R8D) : Emu.pop();

	// print('HeapAlloc(0x{0}, {1}, {2}) = 0x{3} '.format(
	// 	hHeap.toString(16),
	// 	dwFlags,
	// 	dwBytes,
	// 	(pla + 0x100).toString(16)
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, pla+0x10);
	pla += dwBytes + 0x10;

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

HeapAlloc.install('kernel32.dll', 'HeapAlloc');
HeapAlloc.install('api-ms-win-core-heap-l1-1-0.dll', 'HeapAlloc');

/*
###################################################################################################
###################################################################################################
*/

var VirtualAlloc = new ApiHook();
/*
DECLSPEC_ALLOCATOR LPVOID VirtualAlloc(
  Pointer Addr
  SIZE_T  Size,
  DWORD   dwFlags,
  DWORD   dwAccess
);
*/
var first_alloc = true;


var AllocAddr = 0x40000000;
var lastSize = 0;

VirtualAlloc.OnCallBack = function (Emu, API, ret) {
	Emu.pop();


	var Addr     = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var Size     = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var dwFlags  = Emu.isx64 ? Emu.ReadReg(REG_R8D) : Emu.pop();
	var dwAccess = Emu.isx64 ? Emu.ReadReg(REG_R9D) : Emu.pop();


	if (first_alloc) {
		first_alloc = false;
	}else {
		AllocAddr += lastSize;
	}
	
	print('VirtualAlloc(0x{0}, {1}, {2}, {3}) = 0x{4} '.format(
		Addr.toString(16),
		Size,
		dwFlags,
		dwAccess,
		AllocAddr.toString(16)
	));


	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, AllocAddr);

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	lastSize += Size;

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

VirtualAlloc.install('kernel32.dll', 'VirtualAlloc');

/*
###################################################################################################
###################################################################################################
*/


var NtAllocateVirtualMemory = new ApiHook();
/*
__kernel_entry NTSYSCALLAPI NTSTATUS NtAllocateVirtualMemory(
  HANDLE    ProcessHandle,
  PVOID     *BaseAddress,
  ULONG_PTR ZeroBits,
  PSIZE_T   RegionSize,
  ULONG     AllocationType,
  ULONG     Protect
);
*/

NtAllocateVirtualMemory.OnCallBack = function (Emu, API, ret) {
	

	Emu.pop();


	var ProcessHandle = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var BaseAddress   = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var ZeroBits  	  = Emu.isx64 ? Emu.ReadReg(REG_R8D) : Emu.pop();
	var RegionSize 	  = Emu.isx64 ? Emu.ReadReg(REG_R9D) : Emu.pop();

	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var AllocationType  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) 	  : Emu.pop(); 
	var Protect	   		= Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 8) : Emu.pop(); 
	

	var Pointer = Emu.ReadDword(BaseAddress);
	var Size 	= Emu.ReadDword(RegionSize);

	if (Pointer == 0) {

		if (first_alloc) {
			first_alloc = false;
		}else {
			AllocAddr += lastSize;
		}

		Emu.WriteDword(BaseAddress,AllocAddr);
	}
	
	info('NtAllocateVirtualMemory(0x{0}, 0x{1}, 0x{2}, 0x{3}, 0x{4}, 0x{5}) = 0x{6} '.format(
		ProcessHandle.toString(16),
		Pointer.toString(16),
		ZeroBits.toString(16),
		Size.toString(16),
		AllocationType.toString(16),
		Protect.toString(16),
		AllocAddr.toString(16)
	));


	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);// Error Sucsses 

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	lastSize += Size;

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

NtAllocateVirtualMemory.install('ntdll.dll', 'NtAllocateVirtualMemory');

/*
###################################################################################################
###################################################################################################
*/

var RtlAllocateHeap = new ApiHook();
/*
NTSYSAPI PVOID RtlAllocateHeap(
  PVOID  HeapHandle,
  ULONG  Flags,
  SIZE_T Size
);
*/
RtlAllocateHeap.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop();


	var HeapHandle = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var Flags      = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var Size  	   = Emu.isx64 ? Emu.ReadReg(REG_R8D) : Emu.pop();

	if (first_alloc) {
		first_alloc = false;
	}else {
		AllocAddr += lastSize;
	}

	print('RtlAllocateHeap(0x{0}, 0x{1}, 0x{2} = 0x{3} '.format(
		HeapHandle.toString(16),
		Flags.toString(16),
		Size.toString(16),
		AllocAddr.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, AllocAddr);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	lastSize += Size;

	return true;
};

RtlAllocateHeap.install('ntdll.dll', 'RtlAllocateHeap');
/*
###################################################################################################
###################################################################################################
*/



var NtProtectVirtualMemory = new ApiHook();
/*
NTSYSAPI 
NTSTATUS
NTAPI
NtProtectVirtualMemory(
  IN HANDLE               ProcessHandle,
  IN OUT PVOID            *BaseAddress,
  IN OUT PULONG           NumberOfBytesToProtect,
  IN ULONG                NewAccessProtection,
  OUT PULONG              OldAccessProtection 
 );
*/

NtProtectVirtualMemory.OnCallBack = function (Emu, API, ret) {
	

	Emu.pop();


	var ProcessHandle = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var BaseAddress   = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var NumberOfBytes = Emu.isx64 ? Emu.ReadReg(REG_R8D) : Emu.pop();
	var NewAccess 	  = Emu.isx64 ? Emu.ReadReg(REG_R9D) : Emu.pop();

	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var OldAccess 	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) 	  : Emu.pop(); 
	

	var Pointer = Emu.ReadDword(BaseAddress);
	
	print('NtProtectVirtualMemory(0x{0}, 0x{1}, 0x{2}, 0x{3}, 0x{4}) '.format(
		ProcessHandle.toString(16),
		Pointer.toString(16),
		NumberOfBytes.toString(16),
		NewAccess.toString(16),
		OldAccess.toString(16)
	));


	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);// Error Sucsses 

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

NtProtectVirtualMemory.install('ntdll.dll', 'NtProtectVirtualMemory');

/*
###################################################################################################
###################################################################################################
*/
var VirtualFree = new ApiHook();
/*
BOOL WINAPI VirtualFree(
  _In_ LPVOID lpAddress,
  _In_ SIZE_T dwSize,
  _In_ DWORD  dwFreeType
);
*/
VirtualFree.OnCallBack = function (Emu, API, ret) {
	Emu.pop();


	var lpAddress  = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwSize     = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var dwFreeType = Emu.isx64 ? Emu.ReadReg(REG_R8D) : Emu.pop();

	print('VirtualFree(0x{0}, {1}, {2}) = 0x{4} '.format(
		lpAddress.toString(16),
		dwSize,
		dwFreeType
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, dwSize); // :D 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

VirtualFree.install('kernel32.dll', 'VirtualFree');

/*
###################################################################################################
###################################################################################################
*/

var HeapDestroy = new ApiHook();
/*
BOOL HeapDestroy(
  HANDLE hHeap
);
*/
HeapDestroy.OnCallBack = function (Emu, API, ret) {
	Emu.pop();


	var hHeap   = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	print('HeapDestroy(0x{0}, {1}, {2}) = 0x{3} '.format(
		hHeap.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

HeapDestroy.install('kernel32.dll', 'HeapDestroy');
HeapDestroy.install('api-ms-win-core-heap-l1-1-0.dll', 'HeapDestroy');

/*
###################################################################################################
###################################################################################################
*/

var HeapSize = new ApiHook();
/*
SIZE_T HeapSize(
  HANDLE  hHeap,
  DWORD   dwFlags,
  LPCVOID lpMem
);
*/
HeapSize.OnCallBack = function (Emu, API, ret) {
	Emu.pop();


	var hHeap   = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwFlags = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var lpMem   = Emu.isx64 ? Emu.ReadReg(REG_R8D) : Emu.pop();

	// print('HeapSize(0x{0}, {1}, 0x{2})'.format(
	// 	hHeap.toString(16),
	// 	dwFlags,
	// 	lpMem.toString(16)
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1000); // TODO: implement Mem Manager . 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

HeapSize.install('kernel32.dll', 'HeapSize');
HeapSize.install('api-ms-win-core-heap-l1-1-0.dll', 'HeapSize');

/*
###################################################################################################
###################################################################################################
*/


var GetProcessHeap = new ApiHook();
/*
HANDLE GetProcessHeap();
*/
GetProcessHeap.OnCallBack = function (Emu, API, ret) {
	Emu.pop();

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, pla); // TODO: implement Mem Manager . 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

GetProcessHeap.install('kernel32.dll', 'GetProcessHeap');

/*
###################################################################################################
###################################################################################################
*/

var VirtualProtect = new ApiHook();
/*
BOOL WINAPI VirtualProtect(
  _In_  LPVOID lpAddress,
  _In_  SIZE_T dwSize,
  _In_  DWORD  flNewProtect,
  _Out_ PDWORD lpflOldProtect
);
*/
VirtualProtect.OnCallBack = function (Emu, API, ret) {
	
	//TODO: implemenet in Native side - memory manager.

	Emu.pop();

	var lpAddress      = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwSize         = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var flNewProtect   = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var lpflOldProtect = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();

	print('VirtualProtect(0x{0}, {1}, {2}, {3})'.format(
		lpAddress.toString(16),
		dwSize,
		flNewProtect,
		lpflOldProtect
	)); 

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};

VirtualProtect.install('kernel32.dll', 'VirtualProtect');



/*
###################################################################################################
###################################################################################################
*/

var GetConsoleOutputCP = new ApiHook();
/*
Identifier	.NET Name		Additional information
1252		windows-1252	ANSI Latin 1; Western European (Windows)
*/
GetConsoleOutputCP.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	print('GetConsoleOutputCP : ',1252);
	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1252);	

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

GetConsoleOutputCP.install('kernel32.dll', 'GetConsoleOutputCP');
/*
###################################################################################################
###################################################################################################
*/

var GetACP = new ApiHook();
/*
UINT GetACP();

Identifier	.NET Name		Additional information
1252		windows-1252	ANSI Latin 1; Western European (Windows)
*/
GetACP.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	print('GetACP : ',1252);
	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1252);	

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

GetACP.install('kernel32.dll', 'GetACP');
GetACP.install('api-ms-win-core-localization-l1-1-0.dll', 'GetACP');

/*
###################################################################################################
###################################################################################################
*/

var GetCPInfo = new ApiHook();
/*
BOOL GetCPInfo(
  UINT     CodePage,
  LPCPINFO lpCPInfo
);
*/
GetCPInfo.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var CodePage = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpCPInfo = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	// print('GetCPInfo({0}, {1})'.format(
	// 	CodePage,
	// 	lpCPInfo.toString(16)
	// ));


	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);	
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

GetCPInfo.install('kernel32.dll', 'GetCPInfo');
GetCPInfo.install('api-ms-win-core-localization-l1-1-0.dll', 'GetCPInfo');

/*
###################################################################################################
###################################################################################################
*/


var IsValidCodePage = new ApiHook();
/*
BOOL IsValidCodePage(
  UINT CodePage
);
more info check :
https://docs.microsoft.com/en-us/windows/desktop/Intl/code-page-identifiers
*/
IsValidCodePage.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var CodePage    = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();
	print('IsValidCodePage(',CodePage,')');

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);	
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

IsValidCodePage.install('kernel32.dll', 'IsValidCodePage');
/*
###################################################################################################
###################################################################################################
*/

var GetModuleFileName = new ApiHook();
/*
DWORD WINAPI GetModuleFileName(
  _In_opt_ HMODULE hModule,
  _Out_    LPTSTR  lpFilename,
  _In_     DWORD   nSize
);
*/
GetModuleFileName.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret
	
	var hModule    = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpFilename = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var nSize	   = Emu.isx64 ? Emu.ReadReg(REG_R8D) : Emu.pop();

	var mName = Emu.GetModuleName(hModule);
	var Path = 'C:\\pla\\' + mName;

	var len = API.IsWapi ? Emu.WriteStringW(lpFilename,Path) : Emu.WriteStringA(lpFilename,Path);

	// null byte - mybe needed maybe not :D - i put it anyway :V 
	API.IsWapi ? Emu.WriteWord(lpFilename + (len * 2),0) : Emu.WriteByte(lpFilename+len,0);

	print("GetModuleFileName{0}(0x{1}, 0x{2}, 0x{3}) = '{4}'".format(
		API.IsWapi ? 'W' : 'A',
		hModule.toString(16),
		lpFilename.toString(16),
		nSize.toString(16),
		Path
	));

	// MS Docs : the return value is the length of the string
	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, len);	
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

GetModuleFileName.install('kernel32.dll', 'GetModuleFileNameA');
GetModuleFileName.install('kernel32.dll', 'GetModuleFileNameW');
GetModuleFileName.install('api-ms-win-core-libraryloader-l1-1-0.dll', 'GetModuleFileNameA');
GetModuleFileName.install('api-ms-win-core-libraryloader-l1-1-0.dll', 'GetModuleFileNameW');


/*
###################################################################################################
###################################################################################################
*/

var EncodePointer = new ApiHook();
/*
PVOID EncodePointer(
  _In_ PVOID Ptr
);
*/
EncodePointer.OnCallBack = function (Emu, API,ret) {
	
	Emu.pop(); // ret

	var Ptr = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	var cookie = Ptr ^ 0xC0DE;

	print('EncodePointer(0x{0}) = 0x{1} '.format(
		Ptr.toString(16),
		cookie.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, cookie);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
EncodePointer.install('kernel32.dll', 'EncodePointer');
EncodePointer.install('msvcr90.dll', '_encode_pointer');
EncodePointer.install('api-ms-win-core-util-l1-1-0.dll', 'EncodePointer');

EncodePointer.install('ntdll.dll', 'RtlEncodePointer');
/*
###################################################################################################
###################################################################################################
*/


var DecodePointer = new ApiHook();
/*
PVOID DecodePointer(
   PVOID Ptr
);
*/
DecodePointer.OnCallBack = function (Emu, API,ret) {
	
	Emu.pop(); // ret

	var Ptr = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	var cookie = Ptr ^ 0xC0DE;

	print('DecodePointer(0x{0}) = 0x{1} '.format(
		Ptr.toString(16),
		cookie.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, cookie);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
DecodePointer.install('kernel32.dll', 'DecodePointer');
DecodePointer.install('api-ms-win-core-util-l1-1-0.dll', 'DecodePointer');

DecodePointer.install('msvcr90.dll', '_decode_pointer');


/*
###################################################################################################
###################################################################################################
*/


var InitializeCriticalSectionAndSpinCount = new ApiHook();
/*
BOOL InitializeCriticalSectionAndSpinCount(
  LPCRITICAL_SECTION lpCriticalSection,
  DWORD              dwSpinCount
);
*/
InitializeCriticalSectionAndSpinCount.OnCallBack = function (Emu, API,ret) {
	
	Emu.pop(); // ret

	var lpCriticalSection = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwSpinCount		  = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();


	// print('InitializeCriticalSectionAndSpinCount(0x{0}, {1}) = 1 '.format(
	// 	lpCriticalSection.toString(16),
	// 	dwSpinCount
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1); // This function always succeeds and returns a nonzero value. from MS Docs :V .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
InitializeCriticalSectionAndSpinCount.install('kernel32.dll', 'InitializeCriticalSectionAndSpinCount');

InitializeCriticalSectionAndSpinCount.install('api-ms-win-core-synch-l1-1-0.dll', 'InitializeCriticalSectionAndSpinCount');

/*
###################################################################################################
###################################################################################################
*/

var InitializeCriticalSectionEx = new ApiHook();
/*
BOOL InitializeCriticalSectionEx(
  LPCRITICAL_SECTION lpCriticalSection,
  DWORD              dwSpinCount,
  DWORD              Flags
);
*/
InitializeCriticalSectionEx.OnCallBack = function (Emu, API,ret) {
	
	Emu.pop(); // ret

	var lpCriticalSection = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwSpinCount		  = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var Flags 			  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();

	// print('InitializeCriticalSectionEx(0x{0}, {1}, {2}) = 1 '.format(
	// 	lpCriticalSection.toString(16),
	// 	dwSpinCount,
	// 	Flags
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1); // from MS Docs :V .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
InitializeCriticalSectionEx.install('kernel32.dll', 'InitializeCriticalSectionEx');
InitializeCriticalSectionEx.install('api-ms-win-core-synch-l1-1-0.dll', 'InitializeCriticalSectionEx');

/*
###################################################################################################
###################################################################################################
*/
var InitializeCriticalSection = new ApiHook();
/*
_Maybe_raises_SEH_exception_ VOID InitializeCriticalSection(
  LPCRITICAL_SECTION lpCriticalSection
);
*/
InitializeCriticalSection.OnCallBack = function (Emu, API,ret) {
	
	// Emu.pop(); // ret

	// var lpCriticalSection = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	// print('InitializeCriticalSection(0x{0})'.format(
	// 	lpCriticalSection.toString(16)
	// ));

	// Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
InitializeCriticalSection.install('kernel32.dll', 'InitializeCriticalSection');

InitializeCriticalSection.install('api-ms-win-core-synch-l1-1-0.dll', 'InitializeCriticalSection');

/*
###################################################################################################
###################################################################################################
*/

var GetStartupInfo = new ApiHook();
/*
void GetStartupInfo(
  LPSTARTUPINFOA lpStartupInfo
);
*/
GetStartupInfo.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

/*
_STARTUPINFOW   struc ; (sizeof=0x44, align=0x4, copyof_14)
00000000 cb              dd ?
00000004 lpReserved      dd ?                    ; offset
00000008 lpDesktop       dd ?                    ; offset
0000000C lpTitle         dd ?                    ; offset
00000010 dwX             dd ?
00000014 dwY             dd ?
00000018 dwXSize         dd ?
0000001C dwYSize         dd ?
00000020 dwXCountChars   dd ?
00000024 dwYCountChars   dd ?
00000028 dwFillAttribute dd ?
0000002C dwFlags         dd ?
00000030 wShowWindow     dw ?
00000032 cbReserved2     dw ?                
00000034 lpReserved2     dd ?                 
00000038 hStdInput       dd ?
*/

	var lpStartupInfo = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	
	print('GetStartupInfo(0x',lpStartupInfo.toString(16),')'); // TODO: implement struct write .

	Emu.WriteDword(lpStartupInfo+0x30,0); // wShowWindow & cbReserved2
	Emu.WriteDword(lpStartupInfo+0x34,0); // lpReserved2

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetStartupInfo.install('kernel32.dll', 'GetStartupInfoA');
GetStartupInfo.install('kernel32.dll', 'GetStartupInfoW');

GetStartupInfo.install('api-ms-win-core-processthreads-l1-1-0.dll', 'GetStartupInfoW');


/*
###################################################################################################
###################################################################################################
*/


var GetSystemTimeAsFileTime = new ApiHook();
/*
void WINAPI GetSystemTimeAsFileTime(
  _Out_ LPFILETIME lpSystemTimeAsFileTime
);
*/
GetSystemTimeAsFileTime.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var lpSysTime = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	print('GetSystemTimeAsFileTime(0x',lpSysTime.toString(16),')'); // TODO: implement struct write .

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // true if you handle it false if you want Emu to handle it and set PC .
};
GetSystemTimeAsFileTime.install('kernel32.dll', 'GetSystemTimeAsFileTime');
GetSystemTimeAsFileTime.install('api-ms-win-core-sysinfo-l1-1-0.dll', 'GetSystemTimeAsFileTime');


/*
###################################################################################################
###################################################################################################
*/

var GetTickCount = new ApiHook();
/*
DWORD WINAPI GetTickCount(void);
*/
var first = true;

GetTickCount.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var tick = Date.now();
	if (first == true){
		
		first = false;

	}else{
		tick += 600; // For Anti Debug & Emulation tricks .
		
		first = true;
	}

	print('GetTickCount = ' , tick); // TODO: implement struct write .

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, tick);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
GetTickCount.install('kernel32.dll', 'GetTickCount');
GetTickCount.install('api-ms-win-core-sysinfo-l1-1-0.dll', 'GetTickCount');


/*
###################################################################################################
###################################################################################################
*/

var QueryPerformanceCounter = new ApiHook();
/*
BOOL WINAPI QueryPerformanceCounter(
  _Out_ LARGE_INTEGER *lpPerformanceCount
);
*/
QueryPerformanceCounter.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	// var tick = Date.now();

	var lpPerformanceCount = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	print('QueryPerformanceCounter(0x{0})'.format(lpPerformanceCount.toString(16))); // TODO: implement WriteDword .

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
QueryPerformanceCounter.install('kernel32.dll', 'QueryPerformanceCounter');
QueryPerformanceCounter.install('api-ms-win-core-profile-l1-1-0.dll', 'QueryPerformanceCounter');

/*
###################################################################################################
###################################################################################################
*/

var GetCommandLine = new ApiHook();
/*
LPTSTR WINAPI GetCommandLine(void);
*/
GetCommandLine.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var cmd = API.IsWapi ? (0x40000000 + 0x30000) : (0x40000000 + 0x31000); // TODO implement memory mng .

	var mName = Emu.GetModuleName(0); // Current module .
	var Path = '"C:\\pla\\' + mName + '"'; // :D 

	API.IsWapi ? Emu.WriteStringW(cmd,Path) : Emu.WriteStringA(cmd,Path);

	print("{0}() = 0x{1} = '{2}'".format(
		API.name,
		cmd.toString(16),
		Path
	));

	// MS Docs : the return value is the length of the string
	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, cmd);	
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

GetCommandLine.install('kernel32.dll', 'GetCommandLineA');
GetCommandLine.install('kernel32.dll', 'GetCommandLineW');

GetCommandLine.install('api-ms-win-core-processenvironment-l1-1-0.dll', 'GetCommandLineA');
GetCommandLine.install('api-ms-win-core-processenvironment-l1-1-0.dll', 'GetCommandLineW');

/*
###################################################################################################
###################################################################################################
*/

var GetEnvironmentStrings = new ApiHook();
/*
LPTCH WINAPI GetEnvironmentStrings(void);
*/
GetEnvironmentStrings.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret


	var cmd = API.IsWapi ? (0x40000000 + 0x40000) : (0x40000000 + 0x41000); // pla + 0x60000.


	var env1 = '=::=::\\'; // :D 
	API.IsWapi ? Emu.WriteStringW(cmd,env1) : Emu.WriteStringA(cmd,env1);

	// if a
	var env2 = 'USERNAME=Me'; // :D 
	API.IsWapi ? Emu.WriteStringW((cmd + (env1.length * 2) + 1) ,env2) : Emu.WriteStringA(cmd + (env1.length + 1) ,env2);


	print("GetEnvironmentStrings{0}() = 0x{1}".format(
		API.IsWapi ? 'W' : 'A',
		cmd.toString(16)
	));

	// MS Docs : the return value is the length of the string
	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, cmd);	
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it false if you want Emu to handle it and set PC .
};

GetEnvironmentStrings.install('kernel32.dll', 'GetEnvironmentStringsA');
GetEnvironmentStrings.install('kernel32.dll', 'GetEnvironmentStringsW');

GetEnvironmentStrings.install('api-ms-win-core-processenvironment-l1-1-0.dll', 'GetEnvironmentStringsA');
GetEnvironmentStrings.install('api-ms-win-core-processenvironment-l1-1-0.dll', 'GetEnvironmentStringsW');

/*
###################################################################################################
###################################################################################################
*/

var FreeEnvironmentStrings = new ApiHook();
/*
BOOL WINAPI FreeEnvironmentStrings(
  _In_ LPTCH lpszEnvironmentBlock
);
*/
FreeEnvironmentStrings.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var lpszEnvironmentBlock = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	print('FreeEnvironmentStrings{0}(0x{1})'.format(
		API.IsWapi ? 'W' : 'A',
		lpszEnvironmentBlock.toString(16)		
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

FreeEnvironmentStrings.install('kernel32.dll', 'FreeEnvironmentStringsA');
FreeEnvironmentStrings.install('kernel32.dll', 'FreeEnvironmentStringsW');

FreeEnvironmentStrings.install('api-ms-win-core-processenvironment-l1-1-0.dll', 'FreeEnvironmentStringsA');
FreeEnvironmentStrings.install('api-ms-win-core-processenvironment-l1-1-0.dll', 'FreeEnvironmentStringsW');

/*
###################################################################################################
###################################################################################################
*/

/*
check
https://docs.microsoft.com/en-us/windows/desktop/api/processthreadsapi/nf-processthreadsapi-isprocessorfeaturepresent
for more info :D
*/
var IsProcessorFeaturePresent = new ApiHook();
/*
BOOL IsProcessorFeaturePresent(
  DWORD ProcessorFeature
);
*/
IsProcessorFeaturePresent.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var ProcessorFeature = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();

	print('IsProcessorFeaturePresent({0})'.format(
		ProcessorFeature		
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

IsProcessorFeaturePresent.install('kernel32.dll', 'IsProcessorFeaturePresent');

/*
###################################################################################################
###################################################################################################
*/

var MutexList = [];

var CreateMutex = new ApiHook();
/*
HANDLE CreateMutex(
  LPSECURITY_ATTRIBUTES lpMutexAttributes,
  BOOL                  bInitialOwner,
  LPCSTR                lpName
);
*/
CreateMutex.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var lpMutexAttributes = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();
	var bInitialOwner	  = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
	var lpName 			  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();


	var MutexName = API.IsWapi ? Emu.ReadStringW(lpName) : Emu.ReadStringA(lpName);

	Emu.HexDump(lpName,16);


	var initOwner = bInitialOwner == 1 ? 'True' : 'False';

	print("CreateMutex(0x{0},{1},'{2}')".format(
		lpMutexAttributes.toString(16),
		initOwner,
		MutexName
	));

	MutexList.push(MutexName);

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0xE02C);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

CreateMutex.install('kernel32.dll', 'CreateMutexA');
CreateMutex.install('kernel32.dll', 'CreateMutexW');

/*
###################################################################################################
###################################################################################################
*/

var GetFileAttributes = new ApiHook();
/*
DWORD GetFileAttributesA(
  LPCSTR lpFileName
);
*/
GetFileAttributes.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var lpFileName = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();

	var Filename = API.IsWapi ? Emu.ReadStringW(lpFileName) : Emu.ReadStringA(lpFileName);

	print("GetFileAttributes{0}('{1}')".format(
		API.IsWapi ? 'W' : 'A',
		Filename
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0); // TODO :V check if file exists in our virtual Emu .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
GetFileAttributes.install('kernel32.dll', 'GetFileAttributesA');
GetFileAttributes.install('kernel32.dll', 'GetFileAttributesW');

/*
###################################################################################################
###################################################################################################
*/

var GetSystemTime = new ApiHook();
/*			
void WINAPI GetSystemTime(
  _Out_ LPSYSTEMTIME lpSystemTime
);
void WINAPI GetLocalTime(
  _Out_ LPSYSTEMTIME lpSystemTime
);
*/
GetSystemTime.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var lpSystemTime = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();

	var SysTime = [0xE3,0x07,  // wYear
				   0x06,0x00,  // wMonth
				   0x05,0x00,  // wDayOfWeek
				   0x0B,0x00,  // wDay
				   0x0C,0x00,  // wHour
				   0x30,0x00,  // wMinute
				   0x15,0x00,  // wSecond
				   0x73,0x02]; // wMilliseconds

    Emu.WriteMem(lpSystemTime,SysTime);

	print("GetSystemTime(0x{0})".format(
		lpSystemTime
	));

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
GetSystemTime.install('kernel32.dll', 'GetSystemTime');
GetSystemTime.install('kernel32.dll', 'GetLocalTime');
GetSystemTime.install('api-ms-win-core-sysinfo-l1-1-0.dll', 'GetLocalTime');

/*
###################################################################################################
###################################################################################################
*/

var SetFileAttributes = new ApiHook();
/*
BOOL SetFileAttributes(
  LPCSTR lpFileName,
  DWORD  dwFileAttributes
);
*/
SetFileAttributes.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // ret

	var lpFileName = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();
	var dwFileAttributes	  = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	var Filename = API.IsWapi ? Emu.ReadStringW(lpFileName) : Emu.ReadStringA(lpFileName);

	print("SetFileAttributes{0}('{1}',0x{2})".format(
		API.IsWapi ? 'W' : 'A',
		Filename,
		dwFileAttributes.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
SetFileAttributes.install('kernel32.dll', 'SetFileAttributesA');
SetFileAttributes.install('kernel32.dll', 'SetFileAttributesW');

/*
###################################################################################################
###################################################################################################
*/

var InterlockedCompareExchange = new ApiHook();
InterlockedCompareExchange.OnCallBack = function (Emu, API,ret) {

	warn('InterlockedCompareExchange');

	return true; // let lib handle it
};
InterlockedCompareExchange.install('kernel32.dll', 'InterlockedCompareExchange');
InterlockedCompareExchange.install('api-ms-win-core-interlocked-l1-1-0.dll', 'InterlockedCompareExchange');

/*
###################################################################################################
###################################################################################################
*/

var InterlockedExchange = new ApiHook();
InterlockedExchange.OnCallBack = function (Emu, API,ret) {

	warn('InterlockedExchange');

	return true; // let lib handle it
};
InterlockedExchange.install('kernel32.dll', 'InterlockedExchange');
InterlockedExchange.install('api-ms-win-core-interlocked-l1-1-0.dll', 'InterlockedExchange');

/*
###################################################################################################
###################################################################################################
*/

var DisableThreadLibraryCalls = new ApiHook();
/*
BOOL WINAPI DisableThreadLibraryCalls(
  _In_ HMODULE hModule
);
*/
DisableThreadLibraryCalls.OnCallBack = function (Emu, API,ret) {

	Emu.pop(); // ret

	var hModule = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();
	log('DisableThreadLibraryCalls({0})'.format(
		hModule.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
DisableThreadLibraryCalls.install('kernel32.dll', 'DisableThreadLibraryCalls');
DisableThreadLibraryCalls.install('api-ms-win-core-libraryloader-l1-1-0.dll', 'DisableThreadLibraryCalls');

/*
###################################################################################################
###################################################################################################
*/

var GetStdHandle = new ApiHook();
/*
HANDLE WINAPI GetStdHandle(
  _In_ DWORD nStdHandle
);
*/
GetStdHandle.OnCallBack = function (Emu, API,ret) {

	Emu.pop(); // ret

	var nStdHandle = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();

	log('GetStdHandle({0})'.format(
		nStdHandle.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
GetStdHandle.install('kernel32.dll', 'GetStdHandle');
GetStdHandle.install('api-ms-win-core-processenvironment-l1-1-0.dll', 'GetStdHandle');

/*
###################################################################################################
###################################################################################################
*/


var SetHandleCount = new ApiHook();
/*
UINT SetHandleCount(
	UINT uNumber 
); 
*/
SetHandleCount.OnCallBack = function (Emu, API,ret) {

	Emu.pop(); // ret

	var uNumber = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();

	log('SetHandleCount(0x{0})'.format(
		uNumber.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, uNumber);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
SetHandleCount.install('kernel32.dll', 'SetHandleCount');
SetHandleCount.install('api-ms-win-core-misc-l1-1-0.dll', 'SetHandleCount');

/*
###################################################################################################
###################################################################################################
*/

var GetFileType = new ApiHook();
/*
DWORD GetFileType(
  HANDLE hFile
);
*/
GetFileType.OnCallBack = function (Emu, API,ret) {

	Emu.pop(); // ret

	var nStdHandle = Emu.isx64 ? Emu.ReadReg(REG_ECX) : Emu.pop();
	
	log('GetFileType({0})'.format(
		nStdHandle.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};
GetFileType.install('kernel32.dll', 'GetFileType');
GetFileType.install('api-ms-win-core-file-l1-1-0.dll', 'GetFileType');

/*
###################################################################################################
###################################################################################################
*/

var lstrcpyn = new ApiHook();
lstrcpyn.OnCallBack = function (Emu, API, ret) {

	// read variables direct without pop so the lib can handle it :D 
	// and so we can print stuff :V
	var Dest  = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 0) );
	var Src   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 1) );
	var count = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 2) );

	warn("lstrcpyn{0}(Dest = 0x{1}, Src = '{2}', count = {3})".format(
		API.IsWapi ? 'W' : 'A',
		Dest,
		API.IsWapi ? Emu.ReadStringW(Src) : Emu.ReadStringA(Src),
		count
	));
	// we don't pop any values so
	// just let the library handle it :D 
	return true;
};
lstrcpyn.install('kernel32.dll', 'lstrcpynA');
lstrcpyn.install('kernel32.dll', 'lstrcpynW');

/*
###################################################################################################
###################################################################################################
*/

var GetConsoleMode = new ApiHook();
/*
BOOL WINAPI GetConsoleMode(
  _In_  HANDLE  hConsoleHandle,
  _Out_ LPDWORD lpMode
);
*/
GetConsoleMode.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var hConsoleHandle = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpMode 		   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();

	// log("GetConsoleMode(0x{0},{1})".format(
	// 	hConsoleHandle.toString(16),
	// 	lpMode.toString(16)
	// ));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
GetConsoleMode.install('kernel32.dll', 'GetConsoleMode');

/*
###################################################################################################
###################################################################################################
*/

var FreeConsole = new ApiHook();
/*
BOOL WINAPI FreeConsole(void);
*/
FreeConsole.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	log('FreeConsole()');

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
FreeConsole.install('kernel32.dll', 'FreeConsole');

/*
###################################################################################################
###################################################################################################
*/

var GetSystemWow64DirectoryA = new ApiHook();
/*
UINT GetSystemWow64DirectoryA(
  LPSTR lpBuffer,
  UINT  uSize
);
*/
GetSystemWow64DirectoryA.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var lpBuffer = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var uSize 	 = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();

	var path = 'C:\\Windows\\SysWOW64';

	API.IsWapi ? Emu.WriteStringW(lpBuffer,path) : Emu.WriteStringA(lpBuffer,path);

	log("GetSystemWow64DirectoryA(0x{0},0x{1}) = '{2}'".format(
		lpBuffer.toString(16),
		uSize.toString(16),
		path
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, path.length);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
GetSystemWow64DirectoryA.install('kernel32.dll', 'GetSystemWow64DirectoryA');

/*
###################################################################################################
###################################################################################################
*/

var Wow64DisableWow64FsRedirection = new ApiHook();
/*
BOOL WINAPI Wow64DisableWow64FsRedirection(
  _Out_ PVOID *OldValue
);
*/
Wow64DisableWow64FsRedirection.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop();

	var OldValue = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	log("Wow64DisableWow64FsRedirection(0x{0})".format(
		OldValue.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
Wow64DisableWow64FsRedirection.install('kernel32.dll', 'Wow64DisableWow64FsRedirection');

/*
###################################################################################################
###################################################################################################
*/

var InitializeSListHead = new ApiHook();
/*
void InitializeSListHead(
  PSLIST_HEADER ListHead
);
*/
InitializeSListHead.OnCallBack = function (Emu, API, ret) {

	Emu.pop();
	
	var ListHead = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	log("InitializeSListHead(0x{0})".format(
		ListHead.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
InitializeSListHead.install('kernel32.dll', 'InitializeSListHead');

/*
###################################################################################################
###################################################################################################
*/


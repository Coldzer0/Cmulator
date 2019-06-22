'use strict';

var WriteFile = new ApiHook();
/*
BOOL WriteFile(
  HANDLE       hFile,
  LPCVOID      lpBuffer,
  DWORD        nNumberOfBytesToWrite,
  LPDWORD      lpNumberOfBytesWritten,
  LPOVERLAPPED lpOverlapped
);
*/
WriteFile.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var hFile    			   = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpBuffer 			   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var nNumberOfBytesToWrite  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var lpNumberOfBytesWritten = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	var lpOverlapped = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 


	Emu.WriteDword(lpNumberOfBytesWritten,nNumberOfBytesToWrite);

	log("WriteFile('{0}')".format(
		Emu.ReadStringA(lpBuffer,nNumberOfBytesToWrite)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
WriteFile.install('kernel32.dll', 'WriteFile');

/*
###################################################################################################
###################################################################################################
*/

var CreateFile = new ApiHook();
/*
HANDLE CreateFile(
  LPCSTR                lpFileName,
  DWORD                 dwDesiredAccess,
  DWORD                 dwShareMode,
  LPSECURITY_ATTRIBUTES lpSecurityAttributes,
  DWORD                 dwCreationDisposition,
  DWORD                 dwFlagsAndAttributes,
  HANDLE                hTemplateFile
);
*/
CreateFile.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var lpFileName       	 = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwDesiredAccess  	 = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var dwShareMode  		 = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var lpSecurityAttributes = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var dwCreationDisposition = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 
	var dwFlagsAndAttributes  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 8)  : Emu.pop(); 
	var hTemplateFile 		  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 16) : Emu.pop(); 


	warn("{0}('{1}', 0x{2}, 0x{3}, 0x{4}, 0x{5}, 0x{6}, 0x{7})".format(
		API.name,
		API.IsWapi ? Emu.ReadStringW(lpFileName) : Emu.ReadStringA(lpFileName),
		dwDesiredAccess.toString(16),
		dwShareMode.toString(16),
		lpSecurityAttributes.toString(16),
		dwCreationDisposition.toString(16),
		dwFlagsAndAttributes.toString(16),
		hTemplateFile.toString(16)
	));


	// TODO: make list of handles with file names so we can track it .

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, Math.random() * 100); // random handle :D
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
CreateFile.install('kernel32.dll', 'CreateFileA');
CreateFile.install('kernel32.dll', 'CreateFileW');

/*
###################################################################################################
###################################################################################################
*/


var GetBinaryTypeW = new ApiHook();
/*
BOOL GetBinaryTypeW(
  LPCWSTR lpApplicationName,
  LPDWORD lpBinaryType
);
*/
GetBinaryTypeW.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var lpApplicationName  = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpBinaryType 		= Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	Emu.WriteDword(lpBinaryType,0) // SCS_32BIT_BINARY = 0 || A 32-bit Windows-based application

	var FilePath = API.IsWapi ? Emu.ReadStringW(lpApplicationName) : Emu.ReadStringA(lpApplicationName);
	console.log("{0}('{1}', 0x{2})".format(
		API.name,
		FilePath,
		lpBinaryType.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};

GetBinaryTypeW.install('kernel32.dll', 'GetBinaryTypeA');
GetBinaryTypeW.install('kernel32.dll', 'GetBinaryTypeW');

/*
###################################################################################################
###################################################################################################
*/

var CopyFile = new ApiHook();
/*
BOOL CopyFile(
  LPCSTR lpExistingFileName,
  LPCSTR lpNewFileName,
  BOOL   bFailIfExists
);
*/
CopyFile.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var lpExistingFileName = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpNewFileName 	   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var bFailIfExists  	   = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();

	warn("{0}('{1}','{2}',{3})".format(
		API.name,
		API.IsWapi ? Emu.ReadStringW(lpExistingFileName) : Emu.ReadStringA(lpExistingFileName),
		API.IsWapi ? Emu.ReadStringW(lpNewFileName) : Emu.ReadStringA(lpNewFileName),
		bFailIfExists
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
CopyFile.install('kernel32.dll', 'CopyFileA');
CopyFile.install('kernel32.dll', 'CopyFileW');

/*
###################################################################################################
###################################################################################################
*/

var DeleteFile = new ApiHook();
/*
BOOL DeleteFileA(
  LPCSTR lpFileName
);
*/
DeleteFile.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var lpFileName = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	warn("{0}('{1}')".format(
		API.name,
		API.IsWapi ? Emu.ReadStringW(lpFileName) : Emu.ReadStringA(lpFileName)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
DeleteFile.install('kernel32.dll', 'DeleteFileA');
DeleteFile.install('kernel32.dll', 'DeleteFileW');

/*
###################################################################################################
###################################################################################################
*/
var _lcreat = new ApiHook();
/*
HFILE _lcreat(
  LPCSTR lpPathName,
  int    iAttribute
);
*/
_lcreat.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var lpPathName = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var iAttribute = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();

	info("_lcreat('{0}',{1}) = {2}".format(
		Emu.ReadStringA(lpPathName),
		iAttribute,
		1337
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1337); // file handle :D
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
_lcreat.install('kernel32.dll', '_lcreat');
/*
###################################################################################################
###################################################################################################
*/

var _hwrite = new ApiHook();
/*
long _hwrite(
HFILE hFile, 
// handle to file 
LPCSTR lpBuffer, 
// pointer to buffer for data to be written 
long lBytes 
// number of bytes to write 
); 
*/
_hwrite.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var hFile 	 = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpBuffer = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var lBytes   = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();

	warn("_hwrite({0},0x{1},{2})".format(
		hFile,
		lpBuffer.toString(16),
		lBytes
	));
	Emu.HexDump(lpBuffer,lBytes);

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, lBytes);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
_hwrite.install('kernel32.dll', '_hwrite');
/*
###################################################################################################
###################################################################################################
*/

var _lclose = new ApiHook();
/*
HFILE _lclose(
  HFILE hFile
);
*/
_lclose.OnCallBack = function (Emu, API, ret) {

	Emu.pop();

	var hFile = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	log("_lclose({0})".format(
		hFile
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, hFile);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
_lclose.install('kernel32.dll', '_lclose');
/*
###################################################################################################
###################################################################################################
*/
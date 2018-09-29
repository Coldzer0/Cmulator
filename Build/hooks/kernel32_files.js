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




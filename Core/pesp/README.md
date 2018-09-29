# Pascal Executable Parser

A collection of classes and functions to parse executable files for the Pascal
language, namely for Free Pascal and Delphi. Everything is implemented in Pascal, 
there are no external dependencies.

These are my findings trying to parse these files. Not everything is implemented yet
(e.g. Resource parsing), and I may be wrong here and there. If you have 
improvements let me know.

## License

BSD

## Supported files

- 16 Bit DOS EXE aka MZ
- 16 Bit Windows EXE aka NE
- 32 Bit PE
- 64 Bit PE
- 32 Bit ELF
- 64 Bit ELF

## Compatibility

OS
: Windows, Linux

Compiler
: Delphi, Free Pascal (Generics required)

## Usage

    // Register files we need
    TPseFile.RegisterFile(TPsePeFile);
    TPseFile.RegisterFile(TPseElfFile);
    TPseFile.RegisterFile(TPseNeFile);
    // If its not one of the above load it as raw file
    TPseFile.RegisterFile(TPseRawFile);

    // filename contains the name of the executable
    PseFile := TPseFile.GetInstance(filename, false);
    try
      WriteLn(PseFile.GetFriendlyName);
      WriteLn(Format('Entry point 0x%x', [PseFile.GetEntryPoint]));

      WriteLn(Format('%d Sections', [PseFile.Sections.Count]));
      for i := 0 to PseFile.Sections.Count - 1 do begin
        sec := PseFile.Sections[i];
        WriteLn(Format('%s: Address 0x%x, Size %d', [sec.Name, sec.Address, sec.Size]));
      end;

      WriteLn(Format('%d Imports', [PseFile.ImportTable.Count]));
      for i := 0 to PseFile.ImportTable.Count - 1 do begin
        imp := PseFile.ImportTable[i];
        WriteLn(Format('%s:', [imp.DllName]));
        for j := 0 to imp.Count - 1 do begin
          api := imp[j];
          WriteLn(Format('  %s: Hint %d, Address: 0x%x', [api.Name, api.Hint, api.Address]));
        end;
      end;

      WriteLn(Format('%d Exports', [PseFile.ExportTable.Count]));
      for i := 0 to PseFile.ExportTable.Count - 1 do begin
        expo := PseFile.ExportTable[i];
        WriteLn(Format('  %s: Orinal %d, Address: 0x%x', [expo.Name, expo.Ordinal, expo.Address]));
      end;
      
      if PseFile is TPsePeFile then begin
        // PE specific code...
      end else if PseFile is TPseElfFile then begin
        // ELF specific code...
      end;
      
    finally
      PseFile.Free;
    end;
    
For details see `pse.dpr`.

## Screenshot

    pse.exe test\pe\inttest.exe
    PE32
    Entry point 0x401010
    3 Sections
    .text: Address 0x1000, Size 10763
    .rdata: Address 0x4000, Size 1884
    .data: Address 0x5000, Size 4508
    1 Imports
    KERNEL32.dll:
      RtlUnwind: Hint 0, Address: 0x59B8
      HeapCreate: Hint 0, Address: 0x59C4
      HeapDestroy: Hint 0, Address: 0x59D2
      HeapAlloc: Hint 0, Address: 0x59E0
      HeapReAlloc: Hint 0, Address: 0x59EC
      HeapFree: Hint 0, Address: 0x59FA
      HeapSize: Hint 0, Address: 0x5A06
      HeapValidate: Hint 0, Address: 0x5A12
      GetSystemTimeAsFileTime: Hint 0, Address: 0x5A22
      GetStartupInfoA: Hint 0, Address: 0x5A3C
      GetFileType: Hint 0, Address: 0x5A4E
      GetStdHandle: Hint 0, Address: 0x5A5C
      GetCurrentProcess: Hint 0, Address: 0x5A6C
      DuplicateHandle: Hint 0, Address: 0x5A80
      SetHandleCount: Hint 0, Address: 0x5A92
      GetCommandLineA: Hint 0, Address: 0x5AA4
      GetModuleFileNameA: Hint 0, Address: 0x5AB6
      GetEnvironmentStrings: Hint 0, Address: 0x5ACC
      FreeEnvironmentStringsA: Hint 0, Address: 0x5AE4
      OutputDebugStringA: Hint 0, Address: 0x5AFE
      UnhandledExceptionFilter: Hint 0, Address: 0x5B14
      ExitProcess: Hint 0, Address: 0x5B30
      SetConsoleCtrlHandler: Hint 0, Address: 0x5B3E
      VirtualAlloc: Hint 0, Address: 0x5B56
      VirtualQuery: Hint 0, Address: 0x5B66
      GetConsoleMode: Hint 0, Address: 0x5B76
      GetConsoleOutputCP: Hint 0, Address: 0x5B88
      WriteFile: Hint 0, Address: 0x5B9E
      GetLastError: Hint 0, Address: 0x5BAA
      CloseHandle: Hint 0, Address: 0x5BBA
      SetFilePointer: Hint 0, Address: 0x5BC8
      SetStdHandle: Hint 0, Address: 0x5BDA
      MultiByteToWideChar: Hint 0, Address: 0x5BEA
      WideCharToMultiByte: Hint 0, Address: 0x5C00
      DeleteFileA: Hint 0, Address: 0x5C16
    0 Exports

## References

- TIS Committee. *Tool Interface Standard (TIS) Executable and Linking
    Format (ELF) Specification*. TIS Committee, 1995.
- Micosoft. *Microsoft Portable Executable and Common Object File Format
    Specification*. Microsoft, February 2013.
- Micosoft. *Executeable-file Header Format*. Microsoft, February 1999.
    <ftp://ftp.microsoft.com/MISC1/DEVELOPR/WIN_DK/KB/Q65/1/22.TXT>
- <http://wiki.osdev.org/NE>
- <http://www.fileformat.info/format/exe/corion-ne.htm>

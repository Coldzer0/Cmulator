unit struct;

{$PACKRECORDS C}
interface


{
    This file is part of the Free Pascal run time library.
    This unit contains the record definition for the Win32 API
    Copyright (c) 1999-2000 by Florian KLaempfl,
    member of the Free Pascal development team.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{
  Structures.h

  Declarations for all the Windows32 API Structures

  Copyright (C) 1996 Free Software Foundation, Inc.

  Author:  Scott Christley <scottc@net-community.com>
  Date: 1996

  This file is part of the Windows32 API Library.

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Library General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Library General Public License for more details.

  If you are interested in a warranty or support for this source code,
  contact Scott Christley <scottc@net-community.com> for more information.

  You should have received a copy of the GNU Library General Public
  License along with this library; see the file COPYING.LIB.
  If not, write to the Free Software Foundation,
  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
}


Const
  IMAGE_SIZEOF_SHORT_NAME = 8;

  type

    { WARNING
      the variable argument list
      is not implemented for FPC
      va_list is just a dummy record
      MvdV: Nevertheless it should be a pointer type, not a record}

     va_list = pchar;
     UCHAR = byte;
     WCHAR = WideChar;


     UINT   = cardinal;
     ULONG  = cardinal;
     USHORT = word;
     {$ifdef UNICODE}
          LPTCH  = Pwidechar;
          LPTSTR = Pwidechar;
     {$else}
          LPTCH  = Pchar;
          LPTSTR = Pchar;
     {$endif}
     {$ifdef UNICODE}
          LPCTSTR = Pwidechar;
     {$else}
          LPCTSTR = Pchar;
     {$endif}

     LPSTR = Pchar;
     LPPSTR = ^LPSTR;

     SHORT = smallint;
     WINT  = longint;
     LONG  = longint;
     LONG64= int64;
     ULONG64 = qword;     // imagehlp header.
     ULONG32 = cardinal;
     DWORD = cardinal;

     LPVOID  = pointer;
     LPCVOID = pointer;
     PVOID = pointer;

     HANDLE = System.THandle;
     HINST = HANDLE;
     HMENU = HANDLE;
     HWND = HANDLE;
     LONGLONG  = int64;
     ULONGLONG  = qword;
     PULONGLONG = ^ULONGLONG; //
     UINT_PTR = PtrUInt;
     PUINT_PTR = ^UINT_PTR;
     FARPROC = pointer;

  { PE executable header.   }
  { Magic number, 0x5a4d  }
  { Bytes on last page of file, 0x90  }
  { Pages in file, 0x3  }
  { Relocations, 0x0  }
  { Size of header in paragraphs, 0x4  }
  { Minimum extra paragraphs needed, 0x0  }
  { Maximum extra paragraphs needed, 0xFFFF  }
  { Initial (relative) SS value, 0x0  }
  { Initial SP value, 0xb8  }
  { Checksum, 0x0  }
  { Initial IP value, 0x0  }
  { Initial (relative) CS value, 0x0  }
  { File address of relocation table, 0x40  }
  { Overlay number, 0x0  }
  { Reserved words, all 0x0  }
  { OEM identifier (for e_oeminfo), 0x0  }
  { OEM information; e_oemid specific, 0x0  }
  { Reserved words, all 0x0  }
  { File address of new exe header, 0x80  }
  { We leave out the next two fields, since they aren't in the header file }
  { DWORD dos_message[16];   text which always follows dos header  }
  { DWORD nt_signature;      required NT signature, 0x4550  }

     IMAGE_DOS_HEADER = record
          e_magic : WORD;
          e_cblp : WORD;
          e_cp : WORD;
          e_crlc : WORD;
          e_cparhdr : WORD;
          e_minalloc : WORD;
          e_maxalloc : WORD;
          e_ss : WORD;
          e_sp : WORD;
          e_csum : WORD;
          e_ip : WORD;
          e_cs : WORD;
          e_lfarlc : WORD;
          e_ovno : WORD;
          e_res : array[0..3] of WORD;
          e_oemid : WORD;
          e_oeminfo : WORD;
          e_res2 : array[0..9] of WORD;
          case boolean of
             true : (e_lfanew : LONG);
             false: (_lfanew : LONG); // delphi naming
       end;
     PIMAGE_DOS_HEADER = ^IMAGE_DOS_HEADER;
     TIMAGE_DOS_HEADER = IMAGE_DOS_HEADER;
     TIMAGEDOSHEADER = IMAGE_DOS_HEADER;
     PIMAGEDOSHEADER = ^IMAGE_DOS_HEADER;

     MMRESULT = Longint;

type
  PWaveFormatEx = ^TWaveFormatEx;
  TWaveFormatEx = packed record
    wFormatTag: Word;       { format type }
    nChannels: Word;        { number of channels (i.e. mono, stereo, etc.) }
    nSamplesPerSec: DWORD;  { sample rate }
    nAvgBytesPerSec: DWORD; { for buffer estimation }
    nBlockAlign: Word;      { block size of data }
    wBitsPerSample: Word;   { number of bits per sample of mono data }
    cbSize: Word;           { the count in bytes of the size of }
  end;

  // TrackMouseEvent. NT or higher only.
  TTrackMouseEvent = Record
    cbSize : DWORD;
    dwFlags : DWORD;
    hwndTrack : HWND;
    dwHoverTime : DWORD;
  end;
  PTrackMouseEvent = ^TTrackMouseEvent;


// File header format.
//

  PIMAGE_FILE_HEADER = ^IMAGE_FILE_HEADER;
  _IMAGE_FILE_HEADER = record
    Machine: WORD;
    NumberOfSections: WORD;
    TimeDateStamp: DWORD;
    PointerToSymbolTable: DWORD;
    NumberOfSymbols: DWORD;
    SizeOfOptionalHeader: WORD;
    Characteristics: WORD;
  end;
  IMAGE_FILE_HEADER = _IMAGE_FILE_HEADER;
  TImageFileHeader = IMAGE_FILE_HEADER;
  PImageFileHeader = PIMAGE_FILE_HEADER;


//
// Debug Format
//

  PIMAGE_DEBUG_DIRECTORY = ^IMAGE_DEBUG_DIRECTORY;
  _IMAGE_DEBUG_DIRECTORY = record
    Characteristics: DWORD;
    TimeDateStamp: DWORD;
    MajorVersion: Word;
    MinorVersion: Word;
    Type_: DWORD;
    SizeOfData: DWORD;
    AddressOfRawData: DWORD;
    PointerToRawData: DWORD;
  end;
  IMAGE_DEBUG_DIRECTORY = _IMAGE_DEBUG_DIRECTORY;
  TImageDebugDirectory = IMAGE_DEBUG_DIRECTORY;
  PImageDebugDirectory = PIMAGE_DEBUG_DIRECTORY;

//
// Optional header format.
//


  PIMAGE_DATA_DIRECTORY = ^IMAGE_DATA_DIRECTORY;
  _IMAGE_DATA_DIRECTORY = record
    VirtualAddress: DWORD;
    Size: DWORD;
  end;
  IMAGE_DATA_DIRECTORY = _IMAGE_DATA_DIRECTORY;
  TIMAGE_DATA_DIRECTORY = _IMAGE_DATA_DIRECTORY;
  TImageDataDirectory = IMAGE_DATA_DIRECTORY;
  PImageDataDirectory = PIMAGE_DATA_DIRECTORY;

const
  IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16;

type
  PIMAGE_OPTIONAL_HEADER32 = ^IMAGE_OPTIONAL_HEADER32;
  _IMAGE_OPTIONAL_HEADER = record
    //
    // Standard fields.
    //
    Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    SizeOfCode: DWORD;
    SizeOfInitializedData: DWORD;
    SizeOfUninitializedData: DWORD;
    AddressOfEntryPoint: DWORD;
    BaseOfCode: DWORD;
    BaseOfData: DWORD;
    //
    // NT additional fields.
    //
    ImageBase: DWORD;
    SectionAlignment: DWORD;
    FileAlignment: DWORD;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: DWORD;
    SizeOfImage: DWORD;
    SizeOfHeaders: DWORD;
    CheckSum: DWORD;
    Subsystem: Word;
    DllCharacteristics: Word;
    SizeOfStackReserve: DWORD;
    SizeOfStackCommit: DWORD;
    SizeOfHeapReserve: DWORD;
    SizeOfHeapCommit: DWORD;
    LoaderFlags: DWORD;
    NumberOfRvaAndSizes: DWORD;
    DataDirectory: array [0..IMAGE_NUMBEROF_DIRECTORY_ENTRIES - 1] of IMAGE_DATA_DIRECTORY;
  end;
  IMAGE_OPTIONAL_HEADER32 = _IMAGE_OPTIONAL_HEADER;
  TImageOptionalHeader32 = IMAGE_OPTIONAL_HEADER32;
  PImageOptionalHeader32 = PIMAGE_OPTIONAL_HEADER32;

  PIMAGE_ROM_OPTIONAL_HEADER = ^IMAGE_ROM_OPTIONAL_HEADER;
  _IMAGE_ROM_OPTIONAL_HEADER = record
    Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    SizeOfCode: DWORD;
    SizeOfInitializedData: DWORD;
    SizeOfUninitializedData: DWORD;
    AddressOfEntryPoint: DWORD;
    BaseOfCode: DWORD;
    BaseOfData: DWORD;
    BaseOfBss: DWORD;
    GprMask: DWORD;
    CprMask: array [0..3] of DWORD;
    GpValue: DWORD;
  end;
  IMAGE_ROM_OPTIONAL_HEADER = _IMAGE_ROM_OPTIONAL_HEADER;
  TIMAGE_ROM_OPTIONAL_HEADER = _IMAGE_ROM_OPTIONAL_HEADER;
  TImageRomOptionalHeader = IMAGE_ROM_OPTIONAL_HEADER;
  PImageRomOptionalHeader = PIMAGE_ROM_OPTIONAL_HEADER;

  PIMAGE_OPTIONAL_HEADER64 = ^IMAGE_OPTIONAL_HEADER64;
  _IMAGE_OPTIONAL_HEADER64 = record
    Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    SizeOfCode: DWORD;
    SizeOfInitializedData: DWORD;
    SizeOfUninitializedData: DWORD;
    AddressOfEntryPoint: DWORD;
    BaseOfCode: DWORD;
    ImageBase: Int64;
    SectionAlignment: DWORD;
    FileAlignment: DWORD;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: DWORD;
    SizeOfImage: DWORD;
    SizeOfHeaders: DWORD;
    CheckSum: DWORD;
    Subsystem: Word;
    DllCharacteristics: Word;
    SizeOfStackReserve: Int64;
    SizeOfStackCommit: Int64;
    SizeOfHeapReserve: Int64;
    SizeOfHeapCommit: Int64;
    LoaderFlags: DWORD;
    NumberOfRvaAndSizes: DWORD;
    DataDirectory: array [0..IMAGE_NUMBEROF_DIRECTORY_ENTRIES - 1] of IMAGE_DATA_DIRECTORY;
  end;
  IMAGE_OPTIONAL_HEADER64 = _IMAGE_OPTIONAL_HEADER64;
  TImageOptionalHeader64 = IMAGE_OPTIONAL_HEADER64;
  PImageOptionalHeader64 = PIMAGE_OPTIONAL_HEADER64;

const
  IMAGE_SIZEOF_ROM_OPTIONAL_HEADER  = 56;
  IMAGE_SIZEOF_STD_OPTIONAL_HEADER  = 28;
  IMAGE_SIZEOF_NT_OPTIONAL32_HEADER = 224;
  IMAGE_SIZEOF_NT_OPTIONAL64_HEADER = 240;

  IMAGE_NT_OPTIONAL_HDR32_MAGIC = $10b;
  IMAGE_NT_OPTIONAL_HDR64_MAGIC = $20b;
  IMAGE_ROM_OPTIONAL_HDR_MAGIC  = $107;

type
{$ifdef _WIN64}
  IMAGE_OPTIONAL_HEADER = IMAGE_OPTIONAL_HEADER64;
  PIMAGE_OPTIONAL_HEADER = PIMAGE_OPTIONAL_HEADER64;
{$else}
  IMAGE_OPTIONAL_HEADER = IMAGE_OPTIONAL_HEADER32;
  PIMAGE_OPTIONAL_HEADER = PIMAGE_OPTIONAL_HEADER32;
{$endif}
  TImageOptionalHeader = IMAGE_OPTIONAL_HEADER;
  PImageOptionalHeader = PIMAGE_OPTIONAL_HEADER;

const
  IMAGE_SIZEOF_NT_OPTIONAL_HEADER = IMAGE_SIZEOF_NT_OPTIONAL32_HEADER;
  IMAGE_NT_OPTIONAL_HDR_MAGIC     = IMAGE_NT_OPTIONAL_HDR32_MAGIC;

type
  PIMAGE_NT_HEADERS64 = ^IMAGE_NT_HEADERS64;
  _IMAGE_NT_HEADERS64 = record
    Signature: DWORD;
    FileHeader: IMAGE_FILE_HEADER;
    OptionalHeader: IMAGE_OPTIONAL_HEADER64;
  end;
  IMAGE_NT_HEADERS64 = _IMAGE_NT_HEADERS64;
  TImageNtHeaders64 = IMAGE_NT_HEADERS64;
  PImageNtHeaders64 = PIMAGE_NT_HEADERS64;

  PIMAGE_NT_HEADERS32 = ^IMAGE_NT_HEADERS32;
  _IMAGE_NT_HEADERS = record
    Signature: DWORD;
    FileHeader: IMAGE_FILE_HEADER;
    OptionalHeader: IMAGE_OPTIONAL_HEADER32;
  end;
  IMAGE_NT_HEADERS32 = _IMAGE_NT_HEADERS;
  TImageNtHeaders32 = IMAGE_NT_HEADERS32;
  PImageNtHeaders32 = PIMAGE_NT_HEADERS32;

  PIMAGE_ROM_HEADERS = ^IMAGE_ROM_HEADERS;
  _IMAGE_ROM_HEADERS = record
    FileHeader: IMAGE_FILE_HEADER;
    OptionalHeader: IMAGE_ROM_OPTIONAL_HEADER;
  end;
  IMAGE_ROM_HEADERS = _IMAGE_ROM_HEADERS;
  TImageRomHeaders = IMAGE_ROM_HEADERS;
  PImageRomHeaders = PIMAGE_ROM_HEADERS;

{$ifdef _WIN64}
  IMAGE_NT_HEADERS = IMAGE_NT_HEADERS64;
  PIMAGE_NT_HEADERS = PIMAGE_NT_HEADERS64;
{$else}
  IMAGE_NT_HEADERS = IMAGE_NT_HEADERS32;
  PIMAGE_NT_HEADERS = PIMAGE_NT_HEADERS32;
{$endif}

  TImageNtHeaders = IMAGE_NT_HEADERS;
  PImageNtHeaders = PIMAGE_NT_HEADERS;

  _GET_FILEEX_INFO_LEVELS = (GetFileExInfoStandard, GetFileExMaxInfoLevel);
  GET_FILEEX_INFO_LEVELS = _GET_FILEEX_INFO_LEVELS;
  TGetFileExInfoLevels = GET_FILEEX_INFO_LEVELS;
  TGet_FileEx_Info_Levels = GET_FILEEX_INFO_LEVELS;

  tagBSTRBLOB = record
                  cbsize : ULONG;
		  pdata  : pbyte;
                  end;
  BSTRBLOB=TagBSTRBlob;
  TBSTRBLOB=BSTRBLOB;
  PBSTRBLOB=^BSTRBLOB;

  tagCLIPDATA = record
                  cbsize : ULONG;
		  ulClipFmt : long;
		  pclipdata : pbyte;
                  end;
  CLIPDATA=TagCLIPDATA;
  TCLIPDATA=CLIPDATA;
  PCLIPDATA=^CLIPDATA;

   TImage_Section_SubHeader= record
            case longint of
               0 : ( PhysicalAddress : DWORD );
               1 : ( VirtualSize : DWORD );
            end;

   _IMAGE_SECTION_HEADER = record
        Name : array[0..(IMAGE_SIZEOF_SHORT_NAME)-1] of BYTE;
        Misc : TImage_Section_SubHeader;
        VirtualAddress : DWORD;
        SizeOfRawData : DWORD;
        PointerToRawData : DWORD;
        PointerToRelocations : DWORD;
        PointerToLinenumbers : DWORD;
        NumberOfRelocations : WORD;
        NumberOfLinenumbers : WORD;
        Characteristics : DWORD;
     end;
   IMAGE_SECTION_HEADER = _IMAGE_SECTION_HEADER;
   TIMAGE_SECTION_HEADER = _IMAGE_SECTION_HEADER;
   PIMAGE_SECTION_HEADER = ^_IMAGE_SECTION_HEADER;
   PPIMAGE_SECTION_HEADER = ^PIMAGE_SECTION_HEADER;
   IMAGESECTIONHEADER = _IMAGE_SECTION_HEADER;
   TIMAGESECTIONHEADER = _IMAGE_SECTION_HEADER;
   PIMAGESECTIONHEADER = ^_IMAGE_SECTION_HEADER;


   _IMAGE_FUNCTION_ENTRY = record
      StartingAddress,
      EndingAddress,
      EndOfPrologue     : DWord;
      end;
   IMAGE_FUNCTION_ENTRY = _IMAGE_FUNCTION_ENTRY;
   TIMAGE_FUNCTION_ENTRY= IMAGE_FUNCTION_ENTRY;
   PIMAGE_FUNCTION_ENTRY= ^IMAGE_FUNCTION_ENTRY;
   LPIMAGE_FUNCTION_ENTRY= PIMAGE_FUNCTION_ENTRY;


   _IMAGE_FUNCTION_ENTRY64 = record
       StartingAddress,
       EndingAddress :   ULONGLONG   ;
       case boolean of
         false : (EndOfPrologue : ULONGLONG);
         true  : (UnwindInfoAddress : ULONGLONG);
       end;
   IMAGE_FUNCTION_ENTRY64  =  _IMAGE_FUNCTION_ENTRY64;
   TIMAGE_FUNCTION_ENTRY64 =  _IMAGE_FUNCTION_ENTRY64;
   PIMAGE_FUNCTION_ENTRY64 =  ^_IMAGE_FUNCTION_ENTRY64;
   LPIMAGE_FUNCTION_ENTRY64=  ^_IMAGE_FUNCTION_ENTRY64;

   _IMAGE_COFF_SYMBOLS_HEADER  = record
      NumberOfSymbols,
      LvaToFirstSymbol,
      NumberOfLinenumbers,
      LvaToFirstLinenumber,
      RvaToFirstByteOfCode,
      RvaToLastByteOfCode,
      RvaToFirstByteOfData,
      RvaToLastByteOfData    : DWORD;
    end;
   TIMAGE_COFF_SYMBOLS_HEADER = _IMAGE_COFF_SYMBOLS_HEADER;
   IMAGE_COFF_SYMBOLS_HEADER  = _IMAGE_COFF_SYMBOLS_HEADER;
   PIMAGE_COFF_SYMBOLS_HEADER = ^IMAGE_COFF_SYMBOLS_HEADER;
   LPIMAGE_COFF_SYMBOLS_HEADER= PIMAGE_COFF_SYMBOLS_HEADER;


   _FPO_DATA = record
    ulOffStart: DWORD;             // offset 1st byte of function code
    cbProcSize: DWORD;             // # bytes in function
    cdwLocals : DWORD;             // # bytes in locals/4
    bitvalues : word;              //
{
    WORD        cdwParams;              // # bytes in params/4
    WORD        cbProlog : 8;           // # bytes in prolog
    WORD        cbRegs   : 3;           // # regs saved
    WORD        fHasSEH  : 1;           // TRUE if SEH in func
    WORD        fUseBP   : 1;           // TRUE if EBP has been allocated
    WORD        reserved : 1;           // reserved for future use
    WORD        cbFrame  : 2;           // frame type
}
    end;
   FPO_DATA   = _FPO_DATA;
   TFPO_DATA  = _FPO_DATA;
   PFPO_DATA  = ^_FPO_DATA;
   LPFPO_DATA = PFPO_DATA;


     IMAGE_LOAD_CONFIG_DIRECTORY32 = record
          Size : DWORD;
          TimeDateStamp : DWORD;
          MajorVersion : WORD;
          MinorVersion : WORD;
          GlobalFlagsClear : DWORD;
          GlobalFlagsSet : DWORD;
          CriticalSectionDefaultTimeout : DWORD;
          DeCommitFreeBlockThreshold : DWORD;
          DeCommitTotalFreeThreshold : DWORD;
          LockPrefixTable : DWORD;
          MaximumAllocationSize : DWORD;
          VirtualMemoryThreshold : DWORD;
          ProcessHeapFlags : DWORD;
          ProcessAffinityMask : DWORD;
          CSDVersion : WORD;
          Reserved1 : WORD;
          EditList : DWORD;
          SecurityCookie : DWORD;
          SEHandlerTable : DWORD;
          SEHandlerCount : DWORD;
       end;
     PIMAGE_LOAD_CONFIG_DIRECTORY32 = ^IMAGE_LOAD_CONFIG_DIRECTORY32;
     TIMAGE_LOAD_CONFIG_DIRECTORY32 = IMAGE_LOAD_CONFIG_DIRECTORY32;
     IMAGE_LOAD_CONFIG_DIRECTORY64 = record
          Size : DWORD;
          TimeDateStamp : DWORD;
          MajorVersion : WORD;
          MinorVersion : WORD;
          GlobalFlagsClear : DWORD;
          GlobalFlagsSet : DWORD;
          CriticalSectionDefaultTimeout : DWORD;
          DeCommitFreeBlockThreshold : ULONGLONG;
          DeCommitTotalFreeThreshold : ULONGLONG;
          LockPrefixTable : ULONGLONG;
          MaximumAllocationSize : ULONGLONG;
          VirtualMemoryThreshold : ULONGLONG;
          ProcessAffinityMask : ULONGLONG;
          ProcessHeapFlags : DWORD;
          CSDVersion : WORD;
          Reserved1 : WORD;
          EditList : ULONGLONG;
          SecurityCookie : ULONGLONG;
          SEHandlerTable : ULONGLONG;
          SEHandlerCount : ULONGLONG;
       end;
     PIMAGE_LOAD_CONFIG_DIRECTORY64 = ^IMAGE_LOAD_CONFIG_DIRECTORY64;
     TIMAGE_LOAD_CONFIG_DIRECTORY64 = IMAGE_LOAD_CONFIG_DIRECTORY64;
{$ifdef _WIN64}
     IMAGE_LOAD_CONFIG_DIRECTORY = IMAGE_LOAD_CONFIG_DIRECTORY64;
     TIMAGE_LOAD_CONFIG_DIRECTORY = TIMAGE_LOAD_CONFIG_DIRECTORY64;
     PIMAGE_LOAD_CONFIG_DIRECTORY = PIMAGE_LOAD_CONFIG_DIRECTORY64;
{$else}
     IMAGE_LOAD_CONFIG_DIRECTORY = IMAGE_LOAD_CONFIG_DIRECTORY32;
     TIMAGE_LOAD_CONFIG_DIRECTORY = TIMAGE_LOAD_CONFIG_DIRECTORY32;
     PIMAGE_LOAD_CONFIG_DIRECTORY = PIMAGE_LOAD_CONFIG_DIRECTORY32;
{$endif}

{$push}
{$packrecords 4}

    PIMAGE_EXPORT_DIRECTORY = ^TIMAGE_EXPORT_DIRECTORY;
    IMAGE_EXPORT_DIRECTORY = record
        Characteristics : DWORD;
        TimeDateStamp   : DWORD;
        MajorVersion    : WORD;
        MinorVersion    : WORD;
        Name 	        : DWORD;
        Base 		    : DWORD;
        NumberOfFunctions : DWORD;
        NumberOfNames   : DWORD;
        AddressOfFunctions : DWORD;     { RVA from base of image }
        AddressOfNames  : DWORD;        { RVA from base of image }
        AddressOfNameOrdinals : DWORD;  { RVA from base of image }
      end;
    TIMAGE_EXPORT_DIRECTORY = IMAGE_EXPORT_DIRECTORY;
    _IMAGE_EXPORT_DIRECTORY = IMAGE_EXPORT_DIRECTORY;
    LPIMAGE_EXPORT_DIRECTORY= PIMAGE_EXPORT_DIRECTORY;

  P_IMAGE_IMPORT_BY_NAME = ^_IMAGE_IMPORT_BY_NAME;
  _IMAGE_IMPORT_BY_NAME =  record
      Hint : WORD;
      Name : array[0..0] of AnsiCHAR;
    end;
  IMAGE_IMPORT_BY_NAME = _IMAGE_IMPORT_BY_NAME;
  PIMAGE_IMPORT_BY_NAME = ^IMAGE_IMPORT_BY_NAME;
  LPIMAGE_IMPORT_BY_NAME = P_IMAGE_IMPORT_BY_NAME;
  PPIMAGE_IMPORT_BY_NAME = ^PIMAGE_IMPORT_BY_NAME;

  {$push}{$packrecords 8}              // Use align 8 for the 64-bit IAT.}
  P_IMAGE_THUNK_DATA64 = ^_IMAGE_THUNK_DATA64;
  _IMAGE_THUNK_DATA64 =  record
      u1 :  record
          case longint of
            0 : ( ForwarderString : ULONGLONG );    { PBYTE  }
            1 : ( _Function : ULONGLONG );          { PDWORD }
            2 : ( Ordinal : ULONGLONG );
            3 : ( AddressOfData : ULONGLONG );      { PIMAGE_IMPORT_BY_NAME }
          end;
    end;
  IMAGE_THUNK_DATA64 = _IMAGE_THUNK_DATA64;
  PIMAGE_THUNK_DATA64 = ^IMAGE_THUNK_DATA64;

  PPIMAGE_THUNK_DATA64 = ^PIMAGE_THUNK_DATA64;
  LPIMAGE_THUNK_DATA64 = PIMAGE_THUNK_DATA64;
  {$pop}                        // Back to 4 byte packing}

  P_IMAGE_THUNK_DATA32 = ^_IMAGE_THUNK_DATA32;
  _IMAGE_THUNK_DATA32 =  record
      u1 :  record
          case longint of
            0 : ( ForwarderString : DWORD );          { PBYTE  }
            1 : ( _Function : DWORD );                { PDWORD }
            2 : ( Ordinal : DWORD );
            3 : ( AddressOfData : DWORD );            { PIMAGE_IMPORT_BY_NAME }
          end;
    end;
  IMAGE_THUNK_DATA32 = _IMAGE_THUNK_DATA32;
  PIMAGE_THUNK_DATA32 = ^IMAGE_THUNK_DATA32;

  PPIMAGE_THUNK_DATA32 = ^PIMAGE_THUNK_DATA32;
  LPIMAGE_THUNK_DATA32 = PIMAGE_THUNK_DATA32;

  { }
  { Thread Local Storage }
  { }

  PIMAGE_TLS_CALLBACK = procedure (DllHandle:PVOID; Reason:DWORD; Reserved:PVOID);stdcall; {NTAPI}

  P_IMAGE_TLS_DIRECTORY64 = ^_IMAGE_TLS_DIRECTORY64;
  _IMAGE_TLS_DIRECTORY64 =  record
      StartAddressOfRawData : ULONGLONG;
      EndAddressOfRawData : ULONGLONG;
      AddressOfIndex : ULONGLONG;               { PDWORD }
      AddressOfCallBacks : ULONGLONG;           { PIMAGE_TLS_CALLBACK *; }
      SizeOfZeroFill : DWORD;
          case longint of
            0 : ( Characteristics : DWORD );
            1 : ( CharacteristicsFields:  bitpacked record
                                  Reserved0 : 0..$FFFFF; // 5 nibbles=20 bits
                                  Alignment : 0..$F;      // 4 bits
                                  Reserved1 : 0..$FF;     // 8 bits
              end );
    end;
  IMAGE_TLS_DIRECTORY64 = _IMAGE_TLS_DIRECTORY64;
  PIMAGE_TLS_DIRECTORY64 = ^IMAGE_TLS_DIRECTORY64;

  PPIMAGE_TLS_DIRECTORY64 = ^PIMAGE_TLS_DIRECTORY64;
  LPIMAGE_TLS_DIRECTORY64 = PIMAGE_TLS_DIRECTORY64;
  P_IMAGE_TLS_DIRECTORY32 = ^_IMAGE_TLS_DIRECTORY32;
  _IMAGE_TLS_DIRECTORY32 =  record
      StartAddressOfRawData : DWORD;
      EndAddressOfRawData : DWORD;
      AddressOfIndex : DWORD;                      { PDWORD }
      AddressOfCallBacks : DWORD;                  { PIMAGE_TLS_CALLBACK * }
      SizeOfZeroFill : DWORD;
          case longint of
            0 : ( Characteristics : DWORD );
            1 : ( CharacteristicsFields : bitpacked  record
                                 Reserved0 : 0..$FFFFF; // 5 nibbles=20 bits
                                 Alignment : 0..$F;      // 4 bits
                                 Reserved1 : 0..$FF;     // 8 bits
              end );

    end;
  IMAGE_TLS_DIRECTORY32 = _IMAGE_TLS_DIRECTORY32;
  PIMAGE_TLS_DIRECTORY32 = ^IMAGE_TLS_DIRECTORY32;



  PPIMAGE_TLS_DIRECTORY32 = ^PIMAGE_TLS_DIRECTORY32;
  LPIMAGE_TLS_DIRECTORY32 = PIMAGE_TLS_DIRECTORY32;

  {$ifdef WIN64}

  PIMAGE_THUNK_DATA = PIMAGE_THUNK_DATA64;
  IMAGE_THUNK_DATA = IMAGE_THUNK_DATA64;

  PPIMAGE_THUNK_DATA = ^PIMAGE_THUNK_DATA64;
  LPIMAGE_THUNK_DATA = PIMAGE_THUNK_DATA64;

  PIMAGE_TLS_DIRECTORY = ^IMAGE_TLS_DIRECTORY;
  IMAGE_TLS_DIRECTORY = IMAGE_TLS_DIRECTORY64;

  PPIMAGE_TLS_DIRECTORY = ^PIMAGE_TLS_DIRECTORY;
  LPIMAGE_TLS_DIRECTORY = PIMAGE_TLS_DIRECTORY64;
  {$else}

  PIMAGE_THUNK_DATA = PIMAGE_THUNK_DATA32;
  IMAGE_THUNK_DATA = IMAGE_THUNK_DATA32;

  PPIMAGE_THUNK_DATA = ^PIMAGE_THUNK_DATA;
  LPIMAGE_THUNK_DATA = PIMAGE_THUNK_DATA32;
  PIMAGE_TLS_DIRECTORY = ^IMAGE_TLS_DIRECTORY;
  IMAGE_TLS_DIRECTORY = IMAGE_TLS_DIRECTORY32;

  PPIMAGE_TLS_DIRECTORY = ^PIMAGE_TLS_DIRECTORY;
  LPIMAGE_TLS_DIRECTORY = PIMAGE_TLS_DIRECTORY32;
  {$endif}

  P_IMAGE_IMPORT_DESCRIPTOR = ^_IMAGE_IMPORT_DESCRIPTOR;
  _IMAGE_IMPORT_DESCRIPTOR =  record
          case longint of
            0 : ( Characteristics : DWORD );     { 0 for terminating null import descriptor }
            1 : ( OriginalFirstThunk : DWORD;    { RVA to original unbound IAT (PIMAGE_THUNK_DATA) }
                  TimeDateStamp : DWORD;         { 0 if not bound, }
                                                 // -1 if bound, and real date\time stamp
                                                 //     in IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT (new BIND)
                                                 // O.W. date/time stamp of DLL bound to (Old BIND)
                  ForwarderChain : DWORD;        // -1 if no forwarders
                  Name : DWORD;
                  FirstThunk : DWORD;            // RVA to IAT (if bound this IAT has actual addresses)
                );
    end;
  IMAGE_IMPORT_DESCRIPTOR = _IMAGE_IMPORT_DESCRIPTOR;
  PIMAGE_IMPORT_DESCRIPTOR = ^IMAGE_IMPORT_DESCRIPTOR   {UNALIGNED  }     ;


  PPIMAGE_IMPORT_DESCRIPTOR = ^PIMAGE_IMPORT_DESCRIPTOR;
  LPIMAGE_IMPORT_DESCRIPTOR = PIMAGE_IMPORT_DESCRIPTOR;
  { }
  { New format import descriptors pointed to by DataDirectory[ IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT ] }
  { }


  P_IMAGE_BOUND_IMPORT_DESCRIPTOR = ^_IMAGE_BOUND_IMPORT_DESCRIPTOR;
  _IMAGE_BOUND_IMPORT_DESCRIPTOR =  record
      TimeDateStamp : DWORD;
      OffsetModuleName : WORD;
      NumberOfModuleForwarderRefs : WORD;
      { Array of zero or more IMAGE_BOUND_FORWARDER_REF follows }
    end;

  IMAGE_BOUND_IMPORT_DESCRIPTOR = _IMAGE_BOUND_IMPORT_DESCRIPTOR;
  PIMAGE_BOUND_IMPORT_DESCRIPTOR = ^IMAGE_BOUND_IMPORT_DESCRIPTOR;
  LPIMAGE_BOUND_IMPORT_DESCRIPTOR = P_IMAGE_BOUND_IMPORT_DESCRIPTOR;
  PPIMAGE_BOUND_IMPORT_DESCRIPTOR = ^PIMAGE_BOUND_IMPORT_DESCRIPTOR;

  P_IMAGE_BOUND_FORWARDER_REF = ^_IMAGE_BOUND_FORWARDER_REF;
  _IMAGE_BOUND_FORWARDER_REF =  record
      TimeDateStamp : DWORD;
      OffsetModuleName : WORD;
      Reserved : WORD;
    end;
  IMAGE_BOUND_FORWARDER_REF = _IMAGE_BOUND_FORWARDER_REF;
  PIMAGE_BOUND_FORWARDER_REF = ^IMAGE_BOUND_FORWARDER_REF;
  LPIMAGE_BOUND_FORWARDER_REF = P_IMAGE_BOUND_FORWARDER_REF;
  PPIMAGE_BOUND_FORWARDER_REF = ^PIMAGE_BOUND_FORWARDER_REF;
  { Delay load version 2 }

  _IMAGE_DELAYLOAD_DESCRIPTOR = record
        case longint of
        0: (AllAttributes :Dword;
            DllNameRVA,                       // RVA to the name of the target library (NULL-terminate ASCII string)
            ModuleHandleRVA,                  // RVA to the HMODULE caching location (PHMODULE)
            ImportAddressTableRVA,            // RVA to the start of the IAT (PIMAGE_THUNK_DATA)
            ImportNameTableRVA,               // RVA to the start of the name table (PIMAGE_THUNK_DATA::AddressOfData)
            BoundImportAddressTableRVA,       // RVA to an optional bound IAT
            UnloadInformationTableRVA,        // RVA to an optional unload info table
            TimeDateStamp            : DWORD; // 0 if not bound,
                                            // Otherwise, date/time of the target DLL
         );
        1: (Attributes:bitpacked record
             rvabased:0..1;  {1 bits}                 // Delay load version 2
             ReservedAttributes: 0..$7FFFFFF; {31 bits}
             end;)
     end;

  IMAGE_DELAYLOAD_DESCRIPTOR= _IMAGE_DELAYLOAD_DESCRIPTOR;
  PIMAGE_DELAYLOAD_DESCRIPTOR= ^_IMAGE_DELAYLOAD_DESCRIPTOR;
  PCIMAGE_DELAYLOAD_DESCRIPTOR= PIMAGE_DELAYLOAD_DESCRIPTOR;
{$pop}


implementation
end.


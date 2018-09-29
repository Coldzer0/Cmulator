{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PsePe;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils;

const
  IMAGE_SUBSYSTEM_UNKNOWN                 = 0;  { Unknown subsystem. }
  IMAGE_SUBSYSTEM_NATIVE                  = 1;  { Image doesn't require a subsystem. }
  IMAGE_SUBSYSTEM_WINDOWS_GUI             = 2;  { Image runs in the Windows GUI subsystem. }
  IMAGE_SUBSYSTEM_WINDOWS_CUI             = 3;  { Image runs in the Windows character subsystem. }
  IMAGE_SUBSYSTEM_OS2_CUI                 = 5;  { image runs in the OS/2 character subsystem. }
  IMAGE_SUBSYSTEM_POSIX_CUI               = 7;  { image run  in the Posix character subsystem. }
  IMAGE_SUBSYSTEM_RESERVED8               = 8;  { image run  in the 8 subsystem. }
  IMAGE_SUBSYSTEM_WINDOWS_CE_GUI          = 9;
  IMAGE_SUBSYSTEM_EFI_APPLICATION         = 10;
  IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER = 11;
  IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER      = 12;
  IMAGE_SUBSYSTEM_EFI_ROM                 = 13;
  IMAGE_SUBSYSTEM_XBOX                    = 15;

  IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA       = $0020;
  IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE          = $0040;
  IMAGE_DLLCHARACTERISTICS_FORCE_INTEGRITY       = $0080;
  IMAGE_DLLCHARACTERISTICS_NX_COMPAT             = $0100;
  IMAGE_DLLCHARACTERISTICS_NO_ISOLATION          = $0200;
  IMAGE_DLLCHARACTERISTICS_NO_SEH                = $0400;
  IMAGE_DLLCHARACTERISTICS_NO_BIND               = $0800;
  IMAGE_DLLCHARACTERISTICS_APPCONTAINER          = $1000;
  IMAGE_DLLCHARACTERISTICS_WDM_DRIVER            = $2000;
  IMAGE_DLLCHARACTERISTICS_GUARD_CF              = $4000;
  IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE = $8000;

  IMAGE_LIBRARY_PROCESS_INIT                     = $1;    { Reserved. }
  IMAGE_LIBRARY_PROCESS_TERM                     = $2;    { Reserved. }
  IMAGE_LIBRARY_THREAD_INIT                      = $4;    { Reserved. }
  IMAGE_LIBRARY_THREAD_TERM                      = $8;    { Reserved. }

  IMAGE_DIRECTORY_ENTRY_EXPORT             = 0;  { Export Directory }
  IMAGE_DIRECTORY_ENTRY_IMPORT             = 1;  { Import Directory }
  IMAGE_DIRECTORY_ENTRY_RESOURCE           = 2;  { Resource Directory }
  IMAGE_DIRECTORY_ENTRY_EXCEPTION          = 3;  { Exception Directory }
  IMAGE_DIRECTORY_ENTRY_SECURITY           = 4;  { Security Directory }
  IMAGE_DIRECTORY_ENTRY_BASERELOC          = 5;  { Base Relocation Table }
  IMAGE_DIRECTORY_ENTRY_DEBUG              = 6;  { Debug Directory }
  IMAGE_DIRECTORY_ENTRY_COPYRIGHT          = 7;  { Description String }
  IMAGE_DIRECTORY_ENTRY_GLOBALPTR          = 8;  { Machine Value (MIPS GP) }
  IMAGE_DIRECTORY_ENTRY_TLS                = 9;  { TLS Directory }
  IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG       = 10;  { Load Configuration Directory }
  IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT      = 11;  { Bound Import Directory in headers }
  IMAGE_DIRECTORY_ENTRY_IAT               = 12;  { Import Address Table }
  IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT      = 13;  { Delay Load Import Descriptors }
  IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR    = 14;  { COM Runtime descriptor }

  IMAGE_FILE_RELOCS_STRIPPED               = $0001;  { Relocation info stripped from file. }
  IMAGE_FILE_EXECUTABLE_IMAGE              = $0002;  { File is executable  (i.e. no unresolved externel references). }
  IMAGE_FILE_LINE_NUMS_STRIPPED            = $0004;  { Line nunbers stripped from file. }
  IMAGE_FILE_LOCAL_SYMS_STRIPPED           = $0008;  { Local symbols stripped from file. }
  IMAGE_FILE_AGGRESIVE_WS_TRIM             = $0010;  { Agressively trim working set }
  IMAGE_FILE_LARGE_ADDRESS_AWARE           = $0020;  { App can handle >2gb addresses }
  IMAGE_FILE_BYTES_REVERSED_LO             = $0080;  { Bytes of machine word are reversed. }
  IMAGE_FILE_32BIT_MACHINE                 = $0100;  { 32 bit word machine. }
  IMAGE_FILE_DEBUG_STRIPPED                = $0200;  { Debugging info stripped from file in .DBG file }
  IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP       = $0400;  { If Image is on removable media, copy and run from the swap file. }
  IMAGE_FILE_NET_RUN_FROM_SWAP             = $0800;  { If Image is on Net, copy and run from the swap file. }
  IMAGE_FILE_SYSTEM                        = $1000;  { System File. }
  IMAGE_FILE_DLL                           = $2000;  { File is a DLL. }
  IMAGE_FILE_UP_SYSTEM_ONLY                = $4000;  { File should only be run on a UP machine }
  IMAGE_FILE_BYTES_REVERSED_HI             = $8000;  { Bytes of machine word are reversed. }

  IMAGE_FILE_MACHINE_UNKNOWN               = 0;
  IMAGE_FILE_MACHINE_I386                  = $14c;   { Intel 386. }
  IMAGE_FILE_MACHINE_R3000                 = $162;   { MIPS little-endian, 0x160 big-endian }
  IMAGE_FILE_MACHINE_R4000                 = $166;   { MIPS little-endian }
  IMAGE_FILE_MACHINE_R10000                = $168;   { MIPS little-endian }
  IMAGE_FILE_MACHINE_ALPHA                 = $184;   { Alpha_AXP }
  IMAGE_FILE_MACHINE_POWERPC               = $1F0;   { IBM PowerPC Little-Endian }
  IMAGE_FILE_MACHINE_IA64                  = $0200;  { Intel 64 }
  IMAGE_FILE_MACHINE_ALPHA64               = $0284;  { Alpha_64 }
  IMAGE_FILE_MACHINE_AMD64                 = $8664;  { AMD64 (K8) }

  IMAGE_SCN_TYPE_NO_PAD                    = $00000008;  { Reserved. }
  IMAGE_SCN_CNT_CODE                       = $00000020;  { Section contains code. }
  IMAGE_SCN_CNT_INITIALIZED_DATA           = $00000040;  { Section contains initialized data. }
  IMAGE_SCN_CNT_UNINITIALIZED_DATA         = $00000080;  { Section contains uninitialized data. }

  IMAGE_SCN_LNK_OTHER                      = $00000100;  { Reserved. }
  IMAGE_SCN_LNK_INFO                       = $00000200;  { Section contains comments or some other type of information. }
  IMAGE_SCN_LNK_REMOVE                     = $00000800;  { Section contents will not become part of image. }
  IMAGE_SCN_LNK_COMDAT                     = $00001000;  { Section contents comdat. }

  IMAGE_SCN_MEM_FARDATA                    = $00008000;
  IMAGE_SCN_MEM_PURGEABLE                  = $00020000;
  IMAGE_SCN_MEM_16BIT                      = $00020000;
  IMAGE_SCN_MEM_LOCKED                     = $00040000;
  IMAGE_SCN_MEM_PRELOAD                    = $00080000;

  IMAGE_SCN_ALIGN_1BYTES                   = $00100000;
  IMAGE_SCN_ALIGN_2BYTES                   = $00200000;
  IMAGE_SCN_ALIGN_4BYTES                   = $00300000;
  IMAGE_SCN_ALIGN_8BYTES                   = $00400000;
  IMAGE_SCN_ALIGN_16BYTES                  = $00500000;  { Default alignment if no others are specified. }
  IMAGE_SCN_ALIGN_32BYTES                  = $00600000;
  IMAGE_SCN_ALIGN_64BYTES                  = $00700000;

  IMAGE_SCN_LNK_NRELOC_OVFL                = $01000000;  { Section contains extended relocations. }
  IMAGE_SCN_MEM_DISCARDABLE                = $02000000;  { Section can be discarded. }
  IMAGE_SCN_MEM_NOT_CACHED                 = $04000000;  { Section is not cachable. }
  IMAGE_SCN_MEM_NOT_PAGED                  = $08000000;  { Section is not pageable. }
  IMAGE_SCN_MEM_SHARED                     = $10000000;  { Section is shareable. }
  IMAGE_SCN_MEM_EXECUTE                    = $20000000;  { Section is executable. }
  IMAGE_SCN_MEM_READ                       = $40000000;  { Section is readable. }
  IMAGE_SCN_MEM_WRITE                      = Cardinal($80000000);  { Section is writeable. }

type
  PImageFileHeader = ^TImageFileHeader;
  _IMAGE_FILE_HEADER = packed record
    Machine: Word;
    NumberOfSections: Word;
    TimeDateStamp: Cardinal;
    PointerToSymbolTable: Cardinal;
    NumberOfSymbols: Cardinal;
    SizeOfOptionalHeader: Word;
    Characteristics: Word;
  end;
  TImageFileHeader = _IMAGE_FILE_HEADER;
  IMAGE_FILE_HEADER = _IMAGE_FILE_HEADER;

  PImageExportDirectory = ^TImageExportDirectory;
  _IMAGE_EXPORT_DIRECTORY = packed record
    Characteristics: Cardinal;
    TimeDateStamp: Cardinal;
    MajorVersion: Word;
    MinorVersion: Word;
    Name: Cardinal;
    Base: Cardinal;
    NumberOfFunctions: Cardinal;
    NumberOfNames: Cardinal;
    AddressOfFunctions: Cardinal;
    AddressOfNames: Cardinal;
    AddressOfNameOrdinals: Cardinal;
  end;
  TImageExportDirectory = _IMAGE_EXPORT_DIRECTORY;
  IMAGE_EXPORT_DIRECTORY = _IMAGE_EXPORT_DIRECTORY;

type
  PImageDataDirectory = ^TImageDataDirectory;
  _IMAGE_DATA_DIRECTORY = record
    VirtualAddress: Cardinal;
    Size: Cardinal;
  end;
  {$EXTERNALSYM _IMAGE_DATA_DIRECTORY}
  TImageDataDirectory = _IMAGE_DATA_DIRECTORY;
  IMAGE_DATA_DIRECTORY = _IMAGE_DATA_DIRECTORY;

const
  IMAGE_NUMBEROF_DIRECTORY_ENTRIES        = 16;

type
  PImageOptionalHeader32 = ^TImageOptionalHeader32;
  _IMAGE_OPTIONAL_HEADER32 = packed record
    { Standard fields. }
    Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    SizeOfCode: Cardinal;
    SizeOfInitializedData: Cardinal;
    SizeOfUninitializedData: Cardinal;
    AddressOfEntryPoint: Cardinal;
    BaseOfCode: Cardinal;
    BaseOfData: Cardinal;
    { NT additional fields. }
    ImageBase: Cardinal;
    SectionAlignment: Cardinal;
    FileAlignment: Cardinal;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: Cardinal;
    SizeOfImage: Cardinal;
    SizeOfHeaders: Cardinal;
    CheckSum: Cardinal;
    Subsystem: Word;
    DllCharacteristics: Word;
    SizeOfStackReserve: Cardinal;
    SizeOfStackCommit: Cardinal;
    SizeOfHeapReserve: Cardinal;
    SizeOfHeapCommit: Cardinal;
    LoaderFlags: Cardinal;
    NumberOfRvaAndSizes: Cardinal;
    DataDirectory: packed array[0..IMAGE_NUMBEROF_DIRECTORY_ENTRIES-1] of TImageDataDirectory;
  end;
  TImageOptionalHeader32 = _IMAGE_OPTIONAL_HEADER32;
  IMAGE_OPTIONAL_HEADER32 = _IMAGE_OPTIONAL_HEADER32;

  PImageRomOptionalHeader = ^TImageRomOptionalHeader;
  _IMAGE_ROM_OPTIONAL_HEADER = packed record
    Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    SizeOfCode: Cardinal;
    SizeOfInitializedData: Cardinal;
    SizeOfUninitializedData: Cardinal;
    AddressOfEntryPoint: Cardinal;
    BaseOfCode: Cardinal;
    BaseOfData: Cardinal;
    BaseOfBss: Cardinal;
    GprMask: Cardinal;
    CprMask: packed array[0..3] of Cardinal;
    GpValue: Cardinal;
  end;
  TImageRomOptionalHeader = _IMAGE_ROM_OPTIONAL_HEADER;
  IMAGE_ROM_OPTIONAL_HEADER = _IMAGE_ROM_OPTIONAL_HEADER;

  PImageOptionalHeader64 = ^TImageOptionalHeader64;
  _IMAGE_OPTIONAL_HEADER64 = packed record
    { Standard fields. }
    Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    SizeOfCode: Cardinal;
    SizeOfInitializedData: Cardinal;
    SizeOfUninitializedData: Cardinal;
    AddressOfEntryPoint: Cardinal;
    BaseOfCode: Cardinal;
    { NT additional fields. }
    ImageBase: UInt64;
    SectionAlignment: Cardinal;
    FileAlignment: Cardinal;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: Cardinal;
    SizeOfImage: Cardinal;
    SizeOfHeaders: Cardinal;
    CheckSum: Cardinal;
    Subsystem: Word;
    DllCharacteristics: Word;
    SizeOfStackReserve: UInt64;
    SizeOfStackCommit: UInt64;
    SizeOfHeapReserve: UInt64;
    SizeOfHeapCommit: UInt64;
    LoaderFlags: Cardinal;
    NumberOfRvaAndSizes: Cardinal;
    DataDirectory: packed array[0..IMAGE_NUMBEROF_DIRECTORY_ENTRIES-1] of TImageDataDirectory;
  end;
  TImageOptionalHeader64 = _IMAGE_OPTIONAL_HEADER64;
  IMAGE_OPTIONAL_HEADER64 = _IMAGE_OPTIONAL_HEADER64;

  PImageDebugDirectory = ^TImageDebugDirectory;
  _IMAGE_DEBUG_DIRECTORY = packed record
    Characteristics: Cardinal;
    TimeDateStamp: Cardinal;
    MajorVersion: Word;
    MinorVersion: Word;
    _Type: Cardinal;
    SizeOfData: Cardinal;
    AddressOfRawData: Cardinal;
    PointerToRawData: Cardinal;
  end;
  TImageDebugDirectory = _IMAGE_DEBUG_DIRECTORY;
  IMAGE_DEBUG_DIRECTORY = _IMAGE_DEBUG_DIRECTORY;

const
  IMAGE_SIZEOF_SHORT_NAME                  = 8;

type
  TISHMisc = record
    case Integer of
      0: (PhysicalAddress: Cardinal);
      1: (VirtualSize: Cardinal);
  end;

  PPImageSectionHeader = ^PImageSectionHeader;
  PImageSectionHeader = ^TImageSectionHeader;
  _IMAGE_SECTION_HEADER = packed record
    Name: packed array[0..IMAGE_SIZEOF_SHORT_NAME-1] of Byte;
    Misc: TISHMisc;
    VirtualAddress: Cardinal;
    SizeOfRawData: Cardinal;
    PointerToRawData: Cardinal;
    PointerToRelocations: Cardinal;
    PointerToLinenumbers: Cardinal;
    NumberOfRelocations: Word;
    NumberOfLinenumbers: Word;
    Characteristics: Cardinal;
  end;
  TImageSectionHeader = _IMAGE_SECTION_HEADER;
  IMAGE_SECTION_HEADER = _IMAGE_SECTION_HEADER;

  _IMAGE_THUNK_DATA64 = record
    case Byte of
      0: (ForwarderString: UInt64); // PBYTE
      1: (_Function: UInt64);       // PDWORD Function -> _Function
      2: (Ordinal: UInt64);
      3: (AddressOfData: UInt64);   // PIMAGE_IMPORT_BY_NAME
  end;
  IMAGE_THUNK_DATA64 = _IMAGE_THUNK_DATA64;
  TImageThunkData64 = _IMAGE_THUNK_DATA64;
  PIMAGE_THUNK_DATA64 = ^_IMAGE_THUNK_DATA64;
  PImageThunkData64 = ^_IMAGE_THUNK_DATA64;

  // #include "poppack.h"                        // Back to 4 byte packing

  _IMAGE_THUNK_DATA32 = record
    case Byte of
      0: (ForwarderString: Cardinal); // PBYTE
      1: (_Function: Cardinal);       // PDWORD Function -> _Function
      2: (Ordinal: Cardinal);
      3: (AddressOfData: Cardinal);   // PIMAGE_IMPORT_BY_NAME
  end;
  IMAGE_THUNK_DATA32 = _IMAGE_THUNK_DATA32;
  TImageThunkData32 = _IMAGE_THUNK_DATA32;
  PIMAGE_THUNK_DATA32 = ^_IMAGE_THUNK_DATA32;
  PImageThunkData32 = ^_IMAGE_THUNK_DATA32;

const
  IMAGE_ORDINAL_FLAG64 = UInt64($8000000000000000);
  IMAGE_ORDINAL_FLAG32 = LongWord($80000000);

type
  _IMAGE_IMPORT_DESCRIPTOR = record
    case Byte of
      0: (Characteristics: Cardinal);        // 0 for terminating null import descriptor
      1: (
        OriginalFirstThunk: Cardinal;        // RVA to original unbound IAT (PIMAGE_THUNK_DATA)
        TimeDateStamp: Cardinal;             // 0 if not bound,
                                             // -1 if bound, and real date\time stamp
                                             //     in IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT (new BIND)
                                             // O.W. date/time stamp of DLL bound to (Old BIND)

        ForwarderChain: Cardinal;            // -1 if no forwarders
        Name: Cardinal;
        FirstThunk: Cardinal                 // RVA to IAT (if bound this IAT has actual addresses)
      );
  end;
  IMAGE_IMPORT_DESCRIPTOR = _IMAGE_IMPORT_DESCRIPTOR;
  TImageImportDescriptor = _IMAGE_IMPORT_DESCRIPTOR;
  PIMAGE_IMPORT_DESCRIPTOR = ^_IMAGE_IMPORT_DESCRIPTOR;
  PImageImportDescriptor = ^_IMAGE_IMPORT_DESCRIPTOR;

const
  IMAGE_DEBUG_TYPE_UNKNOWN          = 0;
  IMAGE_DEBUG_TYPE_COFF             = 1;
  IMAGE_DEBUG_TYPE_CODEVIEW         = 2;
  IMAGE_DEBUG_TYPE_FPO              = 3;
  IMAGE_DEBUG_TYPE_MISC             = 4;
  IMAGE_DEBUG_TYPE_EXCEPTION        = 5;
  IMAGE_DEBUG_TYPE_FIXUP            = 6;
  IMAGE_DEBUG_TYPE_OMAP_TO_SRC      = 7;
  IMAGE_DEBUG_TYPE_OMAP_FROM_SRC    = 8;

type
  PImageDebugMisc = ^TImageDebugMisc;
  _IMAGE_DEBUG_MISC = record
    DataType: Cardinal;             // type of misc data, see defines
    Length: Cardinal;               // total length of record, rounded to four
                                    // byte multiple.
    Unicode: ByteBool;              // TRUE if data is unicode string
    Reserved: array[0..2] of Byte;
    Data: array[0..0] of Byte;      // Actual data
  end;
  TImageDebugMisc = _IMAGE_DEBUG_MISC;
  IMAGE_DEBUG_MISC = _IMAGE_DEBUG_MISC;

  PImageCOFFSymbolsHeader = ^TImageCOFFSymbolsHeader;
  _IMAGE_COFF_SYMBOLS_HEADER = record
    NumberOfSymbols: Cardinal;
    LvaToFirstSymbol: Cardinal;
    NumberOfLinenumbers: Cardinal;
    LvaToFirstLinenumber: Cardinal;
    RvaToFirstByteOfCode: Cardinal;
    RvaToLastByteOfCode: Cardinal;
    RvaToFirstByteOfData: Cardinal;
    RvaToLastByteOfData: Cardinal;
  end;
  TImageCOFFSymbolsHeader = _IMAGE_COFF_SYMBOLS_HEADER;
  IMAGE_COFF_SYMBOLS_HEADER = _IMAGE_COFF_SYMBOLS_HEADER;

  FarProc = Pointer;
  RVA = Cardinal;

  TImgDelayDescr = record
    grAttrs: Cardinal;         // attributes
    rvaDLLName: RVA;           // RVA to dll name
    rvaHMod: RVA;              // RVA of module handle
    rvaIAT: RVA;               // RVA of the IAT
    rvaINT: RVA;               // RVA of the INT
    rvBoundIAT: RVA;           // RVA of the optional bound IAT
    rvaUnloadIAT: RVA;         // RVA of optional copy of original IAT
    dwTimeStamp: Cardinal;     // 0 if not bound,
                               // O.W. date/time stamp of DLL bound to (Old BIND)
  end;
  PImgDelayDescr = ^TImgDelayDescr;

  // Delay Load Attributes
  DLAttr = (
    dlattrRva = $1             // RVAs are used instead of pointers
                               // Having this set indicates a VC7.0
                               // and above delay load descriptor.
  );

  // Delay load import hook notifications
  DLIMportHookNotification = (
    dliStartProcessing,
    dliNoteStartProcessing = dliStartProcessing,
    dliNotePreLoadLibrary,
    dliNotePreGetProcAddress,
    dliFailLoadLib,
    dliFailGetProc,
    dliNoteEndProcessing
  );

  _DelayLoadProc = record
    fImportByName: LongBool;
    case Byte of
      0: (szProcName: PChar);
      1: (dwOrdinal: Cardinal);
  end;
  TDelayLoadProc = _DelayLoadProc;

  _DelayLoadInfo = record
    cd: Cardinal;              // size of structure
    pidd: PImgDelayDescr;      // raw form of data (everything is there)
    ppfn: FarProc;             // points to address of function to load
    szDll: PChar;              // name of dll
    dlp: TDelayLoadProc;       // name or ordinal of procedure
    hmodCur: HMODULE;          // the hInstance of the library we have loaded
    pfnCur: FarProc;           // the actual function that will be called
    dwLastError: Cardinal;     // error received (if an error notification)
  end;
  TDelayLoadInfo = _DelayLoadInfo;
  PDelayLoadInfo = ^TDelayLoadInfo;

function GetImageDirectoryName(const ADir: Integer): string;
function GetCharacteristicsString(const Characteristics: Word): string;
function GetMachineString(const Machine: Word): string;
function GetSubsystemString(const Subsystem: Word): string;
function GetSecCharacteristicsString(const Characteristics: Cardinal): string;
function GetDllCharacteristicsString(const Characteristics: Cardinal): string;

implementation

function GetDllCharacteristicsString(const Characteristics: Cardinal): string;
begin
  Result := '';
  if (Characteristics and IMAGE_LIBRARY_PROCESS_INIT) = IMAGE_LIBRARY_PROCESS_INIT then
    Result := Result + 'IMAGE_LIBRARY_PROCESS_INIT | ';
  if (Characteristics and IMAGE_LIBRARY_PROCESS_TERM) = IMAGE_LIBRARY_PROCESS_TERM then
    Result := Result + 'IMAGE_LIBRARY_PROCESS_TERM | ';
  if (Characteristics and IMAGE_LIBRARY_THREAD_INIT) = IMAGE_LIBRARY_THREAD_INIT then
    Result := Result + 'IMAGE_LIBRARY_THREAD_INIT | ';
  if (Characteristics and IMAGE_LIBRARY_PROCESS_INIT) = IMAGE_LIBRARY_PROCESS_INIT then
    Result := Result + 'IMAGE_LIBRARY_PROCESS_INIT | ';
  if (Characteristics and IMAGE_LIBRARY_THREAD_TERM) = IMAGE_LIBRARY_THREAD_TERM then
    Result := Result + 'IMAGE_LIBRARY_THREAD_TERM | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA) = IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_HIGH_ENTROPY_VA | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE) = IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_FORCE_INTEGRITY) = IMAGE_DLLCHARACTERISTICS_FORCE_INTEGRITY then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_FORCE_INTEGRITY | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_NX_COMPAT) = IMAGE_DLLCHARACTERISTICS_NX_COMPAT then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_NX_COMPAT | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_NO_ISOLATION) = IMAGE_DLLCHARACTERISTICS_NO_ISOLATION then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_NO_ISOLATION | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_NO_SEH) = IMAGE_DLLCHARACTERISTICS_NO_SEH then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_NO_SEH | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_NO_BIND) = IMAGE_DLLCHARACTERISTICS_NO_BIND then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_NO_BIND | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_APPCONTAINER) = IMAGE_DLLCHARACTERISTICS_APPCONTAINER then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_APPCONTAINER | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_WDM_DRIVER) = IMAGE_DLLCHARACTERISTICS_WDM_DRIVER then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_WDM_DRIVER | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_GUARD_CF) = IMAGE_DLLCHARACTERISTICS_GUARD_CF then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_GUARD_CF | ';
  if (Characteristics and IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE) = IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE then
    Result := Result + 'IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE | ';

  if Result <> '' then
    Delete(Result, Length(Result) - 2, MaxInt);
end;

function GetImageDirectoryName(const ADir: Integer): string;
begin
  case ADir of
    IMAGE_DIRECTORY_ENTRY_EXPORT:
      Result := 'IMAGE_DIRECTORY_ENTRY_EXPORT';
    IMAGE_DIRECTORY_ENTRY_IMPORT:
      Result := 'IMAGE_DIRECTORY_ENTRY_IMPORT';
    IMAGE_DIRECTORY_ENTRY_RESOURCE:
      Result := 'IMAGE_DIRECTORY_ENTRY_RESOURCE';
    IMAGE_DIRECTORY_ENTRY_EXCEPTION:
      Result := 'IMAGE_DIRECTORY_ENTRY_EXCEPTION';
    IMAGE_DIRECTORY_ENTRY_SECURITY:
      Result := 'IMAGE_DIRECTORY_ENTRY_SECURITY';
    IMAGE_DIRECTORY_ENTRY_BASERELOC:
      Result := 'IMAGE_DIRECTORY_ENTRY_BASERELOC';
    IMAGE_DIRECTORY_ENTRY_DEBUG:
      Result := 'IMAGE_DIRECTORY_ENTRY_DEBUG';
    IMAGE_DIRECTORY_ENTRY_COPYRIGHT:
      Result := 'IMAGE_DIRECTORY_ENTRY_COPYRIGHT';
    IMAGE_DIRECTORY_ENTRY_GLOBALPTR:
      Result := 'IMAGE_DIRECTORY_ENTRY_GLOBALPTR';
    IMAGE_DIRECTORY_ENTRY_TLS:
      Result := 'IMAGE_DIRECTORY_ENTRY_TLS';
    IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG:
      Result := 'IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG';
    IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT:
      Result := 'IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT';
    IMAGE_DIRECTORY_ENTRY_IAT:
      Result := 'IMAGE_DIRECTORY_ENTRY_IAT';
    IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT:
      Result := 'IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT';
    IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR:
      Result := 'IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR';
  else
    Result := Format('Unknown %d', [ADir]);
  end;
end;

function GetCharacteristicsString(const Characteristics: Word): string;
begin
  Result := '';
  if (Characteristics and IMAGE_FILE_RELOCS_STRIPPED) = IMAGE_FILE_RELOCS_STRIPPED then
    Result := Result + 'IMAGE_FILE_RELOCS_STRIPPED | ';
  if (Characteristics and IMAGE_FILE_EXECUTABLE_IMAGE) = IMAGE_FILE_EXECUTABLE_IMAGE then
    Result := Result + 'IMAGE_FILE_EXECUTABLE_IMAGE | ';
  if (Characteristics and IMAGE_FILE_LINE_NUMS_STRIPPED) = IMAGE_FILE_LINE_NUMS_STRIPPED then
    Result := Result + 'IMAGE_FILE_LINE_NUMS_STRIPPED | ';
  if (Characteristics and IMAGE_FILE_LOCAL_SYMS_STRIPPED) = IMAGE_FILE_LOCAL_SYMS_STRIPPED then
    Result := Result + 'IMAGE_FILE_LOCAL_SYMS_STRIPPED | ';
  if (Characteristics and IMAGE_FILE_LARGE_ADDRESS_AWARE) = IMAGE_FILE_LARGE_ADDRESS_AWARE then
    Result := Result + 'IMAGE_FILE_LARGE_ADDRESS_AWARE | ';
  if (Characteristics and IMAGE_FILE_BYTES_REVERSED_LO) = IMAGE_FILE_BYTES_REVERSED_LO then
    Result := Result + 'IMAGE_FILE_BYTES_REVERSED_LO | ';
  if (Characteristics and IMAGE_FILE_32BIT_MACHINE) = IMAGE_FILE_32BIT_MACHINE then
    Result := Result + 'IMAGE_FILE_32BIT_MACHINE | ';
  if (Characteristics and IMAGE_FILE_DEBUG_STRIPPED) = IMAGE_FILE_DEBUG_STRIPPED then
    Result := Result + 'IMAGE_FILE_DEBUG_STRIPPED | ';
  if (Characteristics and IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP) = IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP then
    Result := Result + 'IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP | ';
  if (Characteristics and IMAGE_FILE_NET_RUN_FROM_SWAP) = IMAGE_FILE_NET_RUN_FROM_SWAP then
    Result := Result + 'IMAGE_FILE_NET_RUN_FROM_SWAP | ';
  if (Characteristics and IMAGE_FILE_SYSTEM) = IMAGE_FILE_SYSTEM then
    Result := Result + 'IMAGE_FILE_SYSTEM | ';
  if (Characteristics and IMAGE_FILE_DLL) = IMAGE_FILE_DLL then
    Result := Result + 'IMAGE_FILE_DLL | ';
  if (Characteristics and IMAGE_FILE_UP_SYSTEM_ONLY) = IMAGE_FILE_UP_SYSTEM_ONLY then
    Result := Result + 'IMAGE_FILE_UP_SYSTEM_ONLY | ';
  if (Characteristics and IMAGE_FILE_BYTES_REVERSED_HI) = IMAGE_FILE_BYTES_REVERSED_HI then
    Result := Result + 'IMAGE_FILE_BYTES_REVERSED_HI | ';

  if Result <> '' then
    Delete(Result, Length(Result) - 2, MaxInt);
end;

function GetMachineString(const Machine: Word): string;
begin
  case Machine of
    IMAGE_FILE_MACHINE_UNKNOWN:
      Result := 'IMAGE_FILE_MACHINE_UNKNOWN';
    IMAGE_FILE_MACHINE_I386:
      Result := 'IMAGE_FILE_MACHINE_I386';
    IMAGE_FILE_MACHINE_R3000:
      Result := 'IMAGE_FILE_MACHINE_R3000';
    IMAGE_FILE_MACHINE_R4000:
      Result := 'IMAGE_FILE_MACHINE_R4000';
    IMAGE_FILE_MACHINE_R10000:
      Result := 'IMAGE_FILE_MACHINE_R10000';
    IMAGE_FILE_MACHINE_ALPHA:
      Result := 'IMAGE_FILE_MACHINE_ALPHA';
    IMAGE_FILE_MACHINE_POWERPC:
      Result := 'IMAGE_FILE_MACHINE_POWERPC';
    IMAGE_FILE_MACHINE_IA64:
      Result := 'IMAGE_FILE_MACHINE_IA64';
    IMAGE_FILE_MACHINE_ALPHA64:
      Result := 'IMAGE_FILE_MACHINE_ALPHA64';
    IMAGE_FILE_MACHINE_AMD64:
      Result := 'IMAGE_FILE_MACHINE_AMD64';
    else
      Result := Format('Unknown %d', [Machine]);
  end;
end;

function GetSubsystemString(const Subsystem: Word): string;
begin
  case Subsystem of
    IMAGE_SUBSYSTEM_UNKNOWN:
      Result := 'IMAGE_SUBSYSTEM_UNKNOWN';
    IMAGE_SUBSYSTEM_NATIVE:
      Result := 'IMAGE_SUBSYSTEM_NATIVE';
    IMAGE_SUBSYSTEM_WINDOWS_GUI:
      Result := 'IMAGE_SUBSYSTEM_WINDOWS_GUI';
    IMAGE_SUBSYSTEM_WINDOWS_CUI:
      Result := 'IMAGE_SUBSYSTEM_WINDOWS_CUI';
    IMAGE_SUBSYSTEM_OS2_CUI:
      Result := 'IMAGE_SUBSYSTEM_OS2_CUI';
    IMAGE_SUBSYSTEM_POSIX_CUI:
      Result := 'IMAGE_SUBSYSTEM_POSIX_CUI';
    IMAGE_SUBSYSTEM_RESERVED8:
      Result := 'IMAGE_SUBSYSTEM_RESERVED8';
    IMAGE_SUBSYSTEM_WINDOWS_CE_GUI:
      Result := 'IMAGE_SUBSYSTEM_WINDOWS_CE_GUI';
    IMAGE_SUBSYSTEM_EFI_APPLICATION:
      Result := 'IMAGE_SUBSYSTEM_EFI_APPLICATION';
    IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER:
      Result := 'IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER';
    IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER:
      Result := 'IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER';
    IMAGE_SUBSYSTEM_EFI_ROM:
      Result := 'IMAGE_SUBSYSTEM_EFI_ROM';
    IMAGE_SUBSYSTEM_XBOX:
      Result := 'IMAGE_SUBSYSTEM_XBOX';
  else
    Result := Format('Unknown %d', [Subsystem]);
  end;
end;

function GetSecCharacteristicsString(const Characteristics: Cardinal): string;
begin
  Result := '';
  if (Characteristics and IMAGE_SCN_TYPE_NO_PAD) = IMAGE_SCN_TYPE_NO_PAD then
    Result := Result + 'IMAGE_SCN_TYPE_NO_PAD | ';
  if (Characteristics and IMAGE_SCN_CNT_CODE) = IMAGE_SCN_CNT_CODE then
    Result := Result + 'IMAGE_SCN_CNT_CODE | ';
  if (Characteristics and IMAGE_SCN_CNT_INITIALIZED_DATA) = IMAGE_SCN_CNT_INITIALIZED_DATA then
    Result := Result + 'IMAGE_SCN_CNT_INITIALIZED_DATA | ';
  if (Characteristics and IMAGE_SCN_CNT_UNINITIALIZED_DATA) = IMAGE_SCN_CNT_UNINITIALIZED_DATA then
    Result := Result + 'IMAGE_SCN_CNT_UNINITIALIZED_DATA | ';
  if (Characteristics and IMAGE_SCN_LNK_OTHER) = IMAGE_SCN_LNK_OTHER then
    Result := Result + 'IMAGE_SCN_LNK_OTHER | ';
  if (Characteristics and IMAGE_SCN_LNK_INFO) = IMAGE_SCN_LNK_INFO then
    Result := Result + 'IMAGE_SCN_LNK_INFO | ';
  if (Characteristics and IMAGE_SCN_LNK_REMOVE) = IMAGE_SCN_LNK_REMOVE then
    Result := Result + 'IMAGE_SCN_LNK_REMOVE | ';
  if (Characteristics and IMAGE_SCN_LNK_COMDAT) = IMAGE_SCN_LNK_COMDAT then
    Result := Result + 'IMAGE_SCN_LNK_COMDAT | ';
  if (Characteristics and IMAGE_SCN_MEM_PURGEABLE) = IMAGE_SCN_MEM_PURGEABLE then
    Result := Result + 'IMAGE_SCN_MEM_PURGEABLE  | ';
  if (Characteristics and IMAGE_SCN_MEM_16BIT) = IMAGE_SCN_MEM_16BIT then
    Result := Result + 'IMAGE_SCN_MEM_16BIT | ';
  if (Characteristics and IMAGE_SCN_MEM_LOCKED) = IMAGE_SCN_MEM_LOCKED then
    Result := Result + 'IMAGE_SCN_MEM_LOCKED | ';
  if (Characteristics and IMAGE_SCN_MEM_PRELOAD) = IMAGE_SCN_MEM_PRELOAD then
    Result := Result + 'IMAGE_SCN_MEM_PRELOAD | ';
  if (Characteristics and IMAGE_SCN_ALIGN_1BYTES) = IMAGE_SCN_ALIGN_1BYTES then
    Result := Result + 'IMAGE_SCN_ALIGN_1BYTES | ';
  if (Characteristics and IMAGE_SCN_ALIGN_2BYTES) = IMAGE_SCN_ALIGN_2BYTES then
    Result := Result + 'IMAGE_SCN_ALIGN_2BYTES | ';
  if (Characteristics and IMAGE_SCN_ALIGN_4BYTES) = IMAGE_SCN_ALIGN_4BYTES then
    Result := Result + 'IMAGE_SCN_ALIGN_4BYTES | ';
  if (Characteristics and IMAGE_SCN_ALIGN_8BYTES) = IMAGE_SCN_ALIGN_8BYTES then
    Result := Result + 'IMAGE_SCN_ALIGN_8BYTES | ';
  if (Characteristics and IMAGE_SCN_ALIGN_16BYTES) = IMAGE_SCN_ALIGN_16BYTES then
    Result := Result + 'IMAGE_SCN_ALIGN_16BYTES | ';
  if (Characteristics and IMAGE_SCN_ALIGN_32BYTES) = IMAGE_SCN_ALIGN_32BYTES then
    Result := Result + 'IMAGE_SCN_ALIGN_32BYTES | ';
  if (Characteristics and IMAGE_SCN_ALIGN_64BYTES) = IMAGE_SCN_ALIGN_64BYTES then
    Result := Result + 'IMAGE_SCN_ALIGN_64BYTES | ';
  if (Characteristics and IMAGE_SCN_LNK_NRELOC_OVFL) = IMAGE_SCN_LNK_NRELOC_OVFL then
    Result := Result + 'IMAGE_SCN_LNK_NRELOC_OVFL | ';
  if (Characteristics and IMAGE_SCN_MEM_DISCARDABLE) = IMAGE_SCN_MEM_DISCARDABLE then
    Result := Result + 'IMAGE_SCN_MEM_DISCARDABLE | ';
  if (Characteristics and IMAGE_SCN_MEM_NOT_CACHED) = IMAGE_SCN_MEM_NOT_CACHED then
    Result := Result + 'IMAGE_SCN_MEM_NOT_CACHED | ';
  if (Characteristics and IMAGE_SCN_MEM_NOT_PAGED) = IMAGE_SCN_MEM_NOT_PAGED then
    Result := Result + 'IMAGE_SCN_MEM_NOT_PAGED | ';
  if (Characteristics and IMAGE_SCN_MEM_SHARED) = IMAGE_SCN_MEM_SHARED then
    Result := Result + 'IMAGE_SCN_MEM_SHARED | ';
  if (Characteristics and IMAGE_SCN_MEM_EXECUTE) = IMAGE_SCN_MEM_EXECUTE then
    Result := Result + 'IMAGE_SCN_MEM_EXECUTE | ';
  if (Characteristics and IMAGE_SCN_MEM_READ) = IMAGE_SCN_MEM_READ then
    Result := Result + 'IMAGE_SCN_MEM_READ | ';
  if (Characteristics and IMAGE_SCN_MEM_WRITE) = IMAGE_SCN_MEM_WRITE then
    Result := Result + 'IMAGE_SCN_MEM_WRITE | ';

  if Result <> '' then
    Delete(Result, Length(Result) - 2, MaxInt);
end;

end.

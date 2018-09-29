unit TEP_PEB;

{$mode delphi}
{$PackRecords C}

interface

uses
  Classes, SysUtils;

type
  ULONG = Cardinal;
  LONG = Longint;
  UCHAR = byte;

type
  T4Bits=0..15;
  T2Bits=0..3;
  T1Bit=0..1;

  TSpareCrossTebBits = bitpacked record
    bit_0  : T1Bit;
    bit_1  : T1Bit;
    bit_2  : T1Bit;
    bit_3  : T1Bit;
    bit_4  : T1Bit;
    bit_5  : T1Bit;
    bit_6  : T1Bit;
    bit_7  : T1Bit;
    bit_8  : T1Bit;
    bit_9  : T1Bit;
    bit_10 : T1Bit;
    bit_11 : T1Bit;
    bit_12 : T1Bit;
    bit_13 : T1Bit;
    bit_14 : T1Bit;
    bit_15 : T1Bit;
  end;


const
  EXCEPTION_ACCESS_VIOLATION = $C0000005;
  EXCEPTION_BREAKPOINT = $80000003;
  EXCEPTION_DATATYPE_MISALIGNMENT = $80000002;
  EXCEPTION_SINGLE_STEP = $80000004;
  EXCEPTION_ARRAY_BOUNDS_EXCEEDED = $c000008c;
  EXCEPTION_FLT_DENORMAL_OPERAND = $c000008d;
  EXCEPTION_FLT_DIVIDE_BY_ZERO = $c000008e;
  EXCEPTION_FLT_INEXACT_RESULT = $c000008f;
  EXCEPTION_FLT_INVALID_OPERATION = $c0000090;
  EXCEPTION_FLT_OVERFLOW = $c0000091;
  EXCEPTION_FLT_STACK_CHECK = $c0000092;
  EXCEPTION_FLT_UNDERFLOW = $c0000093;
  EXCEPTION_INT_DIVIDE_BY_ZERO = $c0000094;
  EXCEPTION_INT_OVERFLOW = $c0000095;
  EXCEPTION_INVALID_HANDLE = $c0000008;
  EXCEPTION_PRIV_INSTRUCTION = $c0000096;
  EXCEPTION_NONCONTINUABLE_EXCEPTION = $c0000025;
  EXCEPTION_NONCONTINUABLE = $1;
  EXCEPTION_STACK_OVERFLOW = $c00000fd;
  EXCEPTION_INVALID_DISPOSITION = $c0000026;
  EXCEPTION_IN_PAGE_ERROR = $c0000006;
  EXCEPTION_ILLEGAL_INSTRUCTION = $c000001d;
  EXCEPTION_POSSIBLE_DEADLOCK = $c0000194;

  EXCEPTION_MAXIMUM_PARAMETERS = 15;

type

  EXCEPTION_RECORD_32 = record
    ExceptionCode : DWORD;
    ExceptionFlags : DWORD;
    ExceptionRecord : DWORD; // Pointer to EXCEPTION_RECORD_32 .
    ExceptionAddress : DWORD;
    NumberParameters : DWORD;
    ExceptionInformation : array[0..(EXCEPTION_MAXIMUM_PARAMETERS)-1] of DWORD;
  end;

  FLOATING_SAVE_AREA_32 = record
    ControlWord : DWORD;
    StatusWord : DWORD;
    TagWord : DWORD;
    ErrorOffset : DWORD;
    ErrorSelector : DWORD;
    DataOffset : DWORD;
    DataSelector : DWORD;
    RegisterArea : array[0..79] of BYTE;
    Cr0NpxState : DWORD;
  end;

  CONTEXT_32 = record
    ContextFlags : DWORD;
    Dr0 : DWORD;
    Dr1 : DWORD;
    Dr2 : DWORD;
    Dr3 : DWORD;
    Dr6 : DWORD;
    Dr7 : DWORD;
    FloatSave : FLOATING_SAVE_AREA_32;
    SegGs : DWORD;
    SegFs : DWORD;
    SegEs : DWORD;
    SegDs : DWORD;
    Edi : DWORD;
    Esi : DWORD;
    Ebx : DWORD;
    Edx : DWORD;
    Ecx : DWORD;
    Eax : DWORD;
    Ebp : DWORD;
    Eip : DWORD;
    SegCs : DWORD;
    EFlags : DWORD;
    Esp : DWORD;
    SegSs : DWORD;
  end;


  LARGE_INTEGER = record
    case Integer of
    0: (
        LowPart: DWORD;
        HighPart: LONG
      );
    1: (QuadPart: UInt64);
  end;

  ULARGE_INTEGER = record
    case Integer of
      0: (
          LowPart: DWORD;
          HighPart: DWORD
        );
      1: ( QuadPart: UInt64);
  end;

  CLIENT_ID_32 = record
    UniqueProcess: DWORD;
    UniqueThread: DWORD;
  end;

  CLIENT_ID_64 = record
    UniqueProcess: QWORD;
    UniqueThread: QWORD;
  end;

  LIST_ENTRY_32 = record
    Flink : DWORD; // Pointer to LIST_ENTRY_32.
    Blink : DWORD; // Pointer to LIST_ENTRY_32.
  end;

  LIST_ENTRY_64 = record
    Flink : QWORD; // Pointer to LIST_ENTRY_64.
    Blink : QWORD; // Pointer to LIST_ENTRY_64.
  end;

  ACTIVATION_CONTEXT_STACK_32 = record // not packed!
    ActiveFrame: DWORD; // Pointer to RTL_ACTIVATION_CONTEXT_STACK_FRAME_32.
    FrameListCache : LIST_ENTRY_32;
    Flags : ULONG;
    NextCookieSequenceNumber : ULONG;
    StackId : ULONG;
  end;

  ACTIVATION_CONTEXT_STACK_64 = record // not packed!
    ActiveFrame: QWORD; // Pointer to RTL_ACTIVATION_CONTEXT_STACK_FRAME_64.
    FrameListCache : LIST_ENTRY_64;
    Flags : ULONG;
    NextCookieSequenceNumber : ULONG;
    StackId : ULONG;
  end;

  RTL_ACTIVATION_CONTEXT_STACK_FRAME_32 = record // not packed!
    Previous: DWORD; // Pointer to RTL_ACTIVATION_CONTEXT_STACK_FRAME_32.
    ActivationContext: DWORD; // Pointer to ACTIVATION_CONTEXT_STACK_32.
    Flags: ULONG;
  end;

  RTL_ACTIVATION_CONTEXT_STACK_FRAME_64 = record // not packed!
    Previous: QWORD; // Pointer to RTL_ACTIVATION_CONTEXT_STACK_FRAME_64.
    ActivationContext: QWORD; // Pointer to ACTIVATION_CONTEXT_STACK_64.
    Flags: ULONG;
  end;

  GDI_TEB_BATCH_32 = record // not packed!
    Offset: ULONG;
    HDC: DWORD;
    Buffer: array[0..309] of ULONG;
  end;

  GDI_TEB_BATCH_64 = record // not packed!
    Offset: ULONG;
    HDC: QWORD;
    Buffer: array[0..309] of ULONG;
  end;

  UNICODE_STRING_32 = record
    Length: WORD;
    MaximumLength: WORD;
    Buffer: DWORD; // Pointer to String .
  end;

  UNICODE_STRING_64 = record
    Length: WORD;
    MaximumLength: WORD;
    Buffer: QWORD; // Pointer to String .
  end;

  TEB_ACTIVE_FRAME_CONTEXT_32 = record // not packed!
    Flags: ULONG;
    FrameName: DWORD; // Pointer to PChar .
  end;

  TEB_ACTIVE_FRAME_CONTEXT_64 = record // not packed!
    Flags: ULONG;
    FrameName: QWORD; // Pointer to PChar .
  end;

  TEB_ACTIVE_FRAME_32 = record // not packed!
    Flags: ULONG;
    Previous: DWORD; // Pointer to TEB_ACTIVE_FRAME_32.
    Context: DWORD;// Pointer to TEB_ACTIVE_FRAME_CONTEXT_32
  end;

  TEB_ACTIVE_FRAME_64 = record // not packed!
    Flags: ULONG;
    Previous: QWORD; // Pointer to TEB_ACTIVE_FRAME_64.
    Context: QWORD;// Pointer to TEB_ACTIVE_FRAME_CONTEXT_64.
  end;

  PROCESSOR_NUMBER = record
    Group    : WORD;
    Number   : Byte;
    Reserved : Byte;
  end;

  EXCEPTION_REGISTRATION_RECORD_32 = record
    pNext: DWORD; // Pointer to Next SEH Handler .
    pfnHandler: DWORD; // Handler Address .
  end;

  EXCEPTION_REGISTRATION_RECORD_64 = record
    pNext: QWORD; // Pointer to Next SEH Handler .
    pfnHandler: Int64; // Handler Address .
  end;

  PEB_LDR_DATA_32 = record // not packed!
    Length: ULONG;
    Initialized: BOOLEAN;
    SsHandle: DWORD; // Pointer .
    InLoadOrderModuleList: LIST_ENTRY_32;
    InMemoryOrderModuleList: LIST_ENTRY_32;
    InInitializationOrderModuleList: LIST_ENTRY_32;
    EntryInProgress: DWORD;
    ShutdownInProgress : Boolean;
    ShutdownThreadId : DWORD; // Pointer .
  end;

  PEB_LDR_DATA_64 = record // not packed!
    Length: ULONG;
    Initialized: BOOLEAN;
    SsHandle: QWORD; // Pointer .
    InLoadOrderModuleList: LIST_ENTRY_64;
    InMemoryOrderModuleList: LIST_ENTRY_64;
    InInitializationOrderModuleList: LIST_ENTRY_64;
    EntryInProgress: QWORD;
    ShutdownInProgress : Boolean;
    ShutdownThreadId : QWORD; // Pointer .
  end;

  LDR_DATA_TABLE_ENTRY_32 = record // not packed!
    InLoadOrderLinks: LIST_ENTRY_32;
    InMemoryOrderLinks: LIST_ENTRY_32;
    InInitializationOrderLinks: LIST_ENTRY_32;
    DllBase: DWORD;
    EntryPoint: DWORD;
    SizeOfImage: ULONG;
    FullDllName: UNICODE_STRING_32;
    BaseDllName: UNICODE_STRING_32;
    Flags: ULONG;
    LoadCount: WORD;
    TlsIndex: WORD;
    HashLinks: LIST_ENTRY_32;
    TimeDateStamp: ULONG;
    EntryPointActivationContext: DWORD; // ACTIVATION_CONTEXT
    PatchInformation: DWORD;
  end;

  LDR_DATA_TABLE_ENTRY_64 = record // not packed!
    InLoadOrderLinks: LIST_ENTRY_64;
    InMemoryOrderLinks: LIST_ENTRY_64;
    InInitializationOrderLinks: LIST_ENTRY_64;
    DllBase: QWORD;
    EntryPoint: QWORD;
    SizeOfImage: ULONG;
    FullDllName: UNICODE_STRING_64;
    BaseDllName: UNICODE_STRING_64;
    Flags: ULONG;
    LoadCount: WORD;
    TlsIndex: WORD;
    HashLinks: LIST_ENTRY_64;
    TimeDateStamp: ULONG;
    EntryPointActivationContext: QWORD; // ACTIVATION_CONTEXT
    PatchInformation: QWORD;
  end;

  NT_TIB32 = record
    ExceptionList: DWORD; // Pointer to EXCEPTION_REGISTRATION_RECORD_32 .
    StackBase: DWORD;
    StackLimit: DWORD;
    SubSystemTib: DWORD;
    Union: record
      case Integer of
        0: (FiberData: DWORD);
        1: (Version: DWORD);
    end;
    ArbitraryUserPointer: DWORD;
    Self: DWORD;
  end;

  NT_TIB64 = record
    ExceptionList: int64; // Pointer to EXCEPTION_REGISTRATION_RECORD_64 .
    StackBase: QWORD;
    StackLimit: QWORD;
    SubSystemTib: QWORD;
    Union: record
    case Integer of
      0: (FiberData: QWORD);
      1: (Version: DWORD);
    end;
    ArbitraryUserPointer: QWORD;
    Self: QWORD;
  end;

  TTIB_32 = record
    NtTib: NT_TIB32;
    EnvironmentPointer: DWORD; // Pointer
    ClientId: CLIENT_ID_32;
    ActiveRpcHandle: DWORD; // Pointer .
    ThreadLocalStoragePointer: DWORD;
    Peb: DWORD; // Pointer to PEB . TODO: Add PEB Structure .
    LastErrorValue: ULONG;
    CountOfOwnedCriticalSections: ULONG;
    CsrClientThread: DWORD; // Pointer .
    Win32ThreadInfo: DWORD; // Pointer .
    User32Reserved: array[0..25] of ULONG;
    UserReserved: array[0..4] of ULONG;
    WOW32Reserved: DWORD; // Pointer .
    CurrentLocale: ULONG;
    FpSoftwareStatusRegister: ULONG;
    SystemReserved1: array[0..53] of DWORD;
    ExceptionCode: LONG;
    ActivationContextStack: DWORD; // Pointer to ACTIVATION_CONTEXT_STACK_32 .

    // Win 10 .
    InstrumentationCallbackSp : DWORD; // Pointer .
    InstrumentationCallbackPreviousPc : DWORD; // Pointer .
    InstrumentationCallbackPreviousSp : DWORD; // Pointer .
    InstrumentationCallbackDisabled : Byte;
    SpareBytes : array[0..22] of byte;
    TxFsContext : ULONG;

    GdiTebBatch: GDI_TEB_BATCH_32;
    RealClientId: CLIENT_ID_32;
    GdiCachedProcessHandle: DWORD;// Pointer.

    GdiClientPID: ULONG;
    GdiClientTID: ULONG;
    GdiThreadLocalInfo: DWORD; // Pointer .
    Win32ClientInfo: array[0..61] of DWORD;
    glDispatchTable: array[0..232] of DWORD;
    glReserved1: array[0..28] of DWORD;
    glReserved2: DWORD;
    glSectionInfo: DWORD;
    glSection: DWORD;
    glTable: DWORD;
    glCurrentRC: DWORD;
    glContext: DWORD;
    LastStatusValue: ULONG; // 4 byte for both .

    StaticUnicodeString: UNICODE_STRING_32;
    StaticUnicodeBuffer: array[0..260] of WCHAR; // WCHAR = 2bytes .
    Padding: WORD;
    DeallocationStack: DWORD; // Pointer .
    TlsSlots: array[0..63] of DWORD;
    TlsLinks: LIST_ENTRY_32;
    Vdm: DWORD; // Pointer .
    ReservedForNtRpc: DWORD; // Pointer .
    DbgSsReserved: array[0..1] of DWORD;
    HardErrorMode: ULONG;

    Instrumentation: array[0..8] of DWORD;
    ActivityId : TGuid;
    SubProcessTag : DWORD; // Pointer .
    PerflibData : DWORD; // Pointer .
    EtwTraceData : DWORD; // Pointer .

    WinSockData: DWORD; // Pointer .
    GdiBatchCount: ULONG;

    IdealProcessor : packed record  // Both x32 - x64 .
      case Integer of
        0: (
            ReservedPad0 : byte;
            ReservedPad1 : byte;
            ReservedPad2 : byte;
            IdealProcessor: BOOLEAN;
        );
        1: (IdealProcessorValue : ULONG;);
        2: (CurrentIdealProcessor : PROCESSOR_NUMBER);
    end;

    GuaranteedStackBytes : ULONG;

    ReservedForPerf: DWORD; // Pointer .
    ReservedForOle: DWORD;  // Pointer .
    WaitingOnLoaderLock: ULONG;

    SavedPriorityState : DWORD; // Pointer .
    ReservedForCodeCoverage : DWORD; // Pointer .
    ThreadPoolData : DWORD; // Pointer .

    TlsExpansionSlots: DWORD;// Pointer to Pointer - read 2 time .
    MuiGeneration : ULONG;

    IsImpersonating: ULONG;
    NlsCache: DWORD; // Pointer .
    pShimData: DWORD;// Pointer .


    HeapAffinity : packed record
      case integer of
        0:(
           HeapVirtualAffinity_0 : WORD; // x32 & x64 .
           LowFragHeapDataSlot_1 : WORD; // x32 & x64 .
        );
        1:(
           HeapVirtualAffinity: ULONG; // till win 7  - x32 & x64..
        );
    end;

    CurrentTransactionHandle: DWORD; // Pointer .
    ActiveFrame: DWORD;// Pointer to TEB_ACTIVE_FRAME_32.
    FlsData: DWORD;

    PreferredLanguages : DWORD; // Pointer .
    UserPrefLanguages : DWORD;  // Pointer .
    MergedPrefLanguages : DWORD; // Pointer .
    MuiImpersonation : ULONG;

    TCrossTebFlags : bitpacked record  // both x32 - x64 .
      case boolean of
        false : (
               SpareCrossTebBits : TSpareCrossTebBits;
        );
        true : (CrossTebFlags : WORD) ;
    end;


    TSameTebFlags : bitpacked record  // both x32 - x64 .
      case boolean of
        false : (
            SafeThunkCall ,
            InDebugPrint  ,
            HasFiberData  ,
            SkipThreadAttach,
            WerInShipAssertCode,
            RanProcessInit,
            ClonedThread,
            SuppressDebugMsg,
            DisableUserStackWalk,
            RtlExceptionAttached,
            InitialThread,
            SessionAware,
            LoadOwner,
            LoaderWorker
            : T1Bit;
            SpareSameTebBits : T2Bits;
        );
        true : (SameTebFlags : WORD) ;
    end;

    TxnScopeEnterCallback : DWORD; // Pointer .
    TxnScopeExitCallback  : DWORD; // Pointer .
    TxnScopeContext : DWORD; // Pointer .

    LockCount : ULONG;   // both x32 - x64 .
    SpareUlong0 : ULONG; // both x32 - x64 .

    ResourceRetValue : DWORD; // Pointer .
    ReservedForWdf : DWORD; // Pointer .
  end;

  TTIB_64 = record
    NtTib: NT_TIB64;
    EnvironmentPointer: QWORD; // Pointer
    ClientId: CLIENT_ID_64;
    ActiveRpcHandle: QWORD; // Pointer .
    ThreadLocalStoragePointer: QWORD;
    Peb: QWORD; // Pointer to PEB64 . TODO: Add PEB64 Structure .
    LastErrorValue: ULONG;
    CountOfOwnedCriticalSections: ULONG;
    CsrClientThread: QWORD; // Pointer .
    Win32ThreadInfo: QWORD; // Pointer .
    User32Reserved: array[0..25] of ULONG;
    UserReserved: array[0..4] of ULONG;
    WOW32Reserved: QWORD; // Pointer .
    CurrentLocale: ULONG;
    FpSoftwareStatusRegister: ULONG;
    SystemReserved1: array[0..53] of QWORD;
    ExceptionCode: LONG;

    Padding0 : array[0..3] of byte;

    ActivationContextStack: QWORD; // Pointer to ACTIVATION_CONTEXT_STACK_32 .

    // Win 10 .
    InstrumentationCallbackSp : QWORD; // Pointer .
    InstrumentationCallbackPreviousPc : QWORD; // Pointer .
    InstrumentationCallbackPreviousSp : QWORD; // Pointer .
    TxFsContext : ULONG;
    InstrumentationCallbackDisabled : Byte;
    Padding1 : array[0..2] of byte;

    GdiTebBatch: GDI_TEB_BATCH_64;
    RealClientId: CLIENT_ID_64;
    GdiCachedProcessHandle: QWORD;// Pointer.

    GdiClientPID: ULONG;
    GdiClientTID: ULONG;
    GdiThreadLocalInfo: QWORD; // Pointer .
    Win32ClientInfo: array[0..61] of QWORD;
    glDispatchTable: array[0..232] of QWORD;
    glReserved1: array[0..28] of QWORD;
    glReserved2: QWORD;
    glSectionInfo: QWORD;
    glSection: QWORD;
    glTable: QWORD;
    glCurrentRC: QWORD;
    glContext: QWORD;
    LastStatusValue: ULONG; // 4 byte for both .
    Padding2 : array[0..3] of byte;

    StaticUnicodeString: UNICODE_STRING_64;
    StaticUnicodeBuffer: array[0..260] of WCHAR; // WCHAR = 2bytes .
    Padding3 : array[0..5] of byte;

    DeallocationStack: QWORD; // Pointer .
    TlsSlots: array[0..63] of QWORD;
    TlsLinks: LIST_ENTRY_64;
    Vdm: QWORD; // Pointer .
    ReservedForNtRpc: QWORD; // Pointer .
    DbgSsReserved: array[0..1] of QWORD;
    HardErrorMode: ULONG;

    Padding4 : array[0..3] of byte;

    Instrumentation: array[0..10] of QWORD;
    ActivityId : TGuid;
    SubProcessTag : QWORD; // Pointer .
    PerflibData : QWORD; // Pointer .
    EtwTraceData : QWORD; // Pointer .

    WinSockData: QWORD; // Pointer .
    GdiBatchCount: ULONG;

    IdealProcessor : packed record  // Both x32 - x64 .
      case Integer of
        0: (
            ReservedPad0 : byte;
            ReservedPad1 : byte;
            ReservedPad2 : byte;
            IdealProcessor: BOOLEAN;
        );
        1: (IdealProcessorValue : ULONG;);
        2: (CurrentIdealProcessor : PROCESSOR_NUMBER);
    end;

    GuaranteedStackBytes : ULONG;

    Padding5 : array[0..3] of byte;

    ReservedForPerf: QWORD; // Pointer .
    ReservedForOle: QWORD;  // Pointer .
    WaitingOnLoaderLock: ULONG;

    Padding6 : array[0..3] of byte;

    SavedPriorityState : QWORD; // Pointer .
    ReservedForCodeCoverage : QWORD; // Pointer .
    ThreadPoolData : QWORD; // Pointer .

    TlsExpansionSlots: QWORD;// Pointer to Pointer - read 2 time .

    DeallocationBStore : QWORD; // Pointer .
    BStoreLimit : QWORD; // Pointer .

    MuiGeneration : ULONG;
    IsImpersonating: ULONG;

    NlsCache: QWORD; // Pointer .
    pShimData: QWORD;// Pointer .

    HeapAffinity : packed record
      case integer of
        0:(
           HeapVirtualAffinity_0 : WORD; // x32 & x64 .
           LowFragHeapDataSlot_1 : WORD; // x32 & x64 .
        );
        1:(
           HeapVirtualAffinity: ULONG; // till win 7  - x32 & x64..
        );
    end;

    Padding7 : array[0..3] of byte;

    CurrentTransactionHandle: QWORD; // Pointer .
    ActiveFrame: QWORD;// Pointer to TEB_ACTIVE_FRAME_64.
    FlsData: QWORD;

    PreferredLanguages : QWORD; // Pointer .
    UserPrefLanguages : QWORD;  // Pointer .
    MergedPrefLanguages : QWORD; // Pointer .
    MuiImpersonation : ULONG;


    TCrossTebFlags : bitpacked record  // both x32 - x64 .
      case boolean of
        false : (
               SpareCrossTebBits : TSpareCrossTebBits;
        );
        true : (CrossTebFlags : WORD) ;
    end;


    TSameTebFlags : bitpacked record  // both x32 - x64 .
      case boolean of
        false : (
            SafeThunkCall,
            InDebugPrint,
            HasFiberData,
            SkipThreadAttach,
            WerInShipAssertCode,
            RanProcessInit,
            ClonedThread,
            SuppressDebugMsg,
            DisableUserStackWalk,
            RtlExceptionAttached,
            InitialThread,
            SessionAware,
            LoadOwner,
            LoaderWorker
            : T1Bit;
            SpareSameTebBits : T2Bits;
        );
        true : (SameTebFlags : WORD) ;
    end;

    TxnScopeEnterCallback : QWORD; // Pointer .
    TxnScopeExitCallback  : QWORD; // Pointer .
    TxnScopeContext : QWORD; // Pointer .

    LockCount : ULONG;   // both x32 - x64 .
    WowTebOffset : ULONG; // both x32 - x64 .

    ResourceRetValue : QWORD; // Pointer .
    ReservedForWdf : QWORD; // Pointer .
    ReservedForCrt : QWORD;
    EffectiveContainerId : TGuid;
  end;

  TPEB_32 = record
    InheritedAddressSpace: BOOLEAN;
    ReadImageFileExecOptions: BOOLEAN;
    BeingDebugged: BOOLEAN;

    BitFields : bitpacked record  // both x32 - x64 .
      case boolean of
        false : (
            ImageUsesLargePages ,
            IsProtectedProcess  ,
            IsImageDynamicallyRelocated  ,
            SkipPatchingUser32Forwarders,
            IsPackagedProcess,
            IsAppContainer,
            IsProtectedProcessLight,
            SpareBit : T1Bit;
        );
        true : (SpareBool : Boolean);
    end;

    Mutant: DWORD; // Pointer .
    ImageBaseAddress: DWORD;
    Ldr: DWORD;// Pointer PEB_LDR_DATA
    ProcessParameters: DWORD;// TODO : PRTL_USER_PROCESS_PARAMETERS ;
    SubSystemData: DWORD; // Pointer
    ProcessHeap: DWORD; // Pointer
    FastPebLock: DWORD; // Pointer - TODO : PRTL_CRITICAL_SECTION ;


    AtlThunkSListPtr : DWORD; // Pointer .
    IFEOKey : DWORD; // Pointer .

    CrossProcessFlags : bitpacked record  // Both x32 - x64 .
      case Integer of
        0: (
          ProcessInJob,
          ProcessInitializing,
          ProcessUsingVEH,
          ProcessUsingVCH,
          ProcessUsingFTH : T1Bit;
          ReservedBits0 :  0..$7FFFFFF; // 27 bits .
        );
        1: (CrossProcessFlag : ULONG)
    end;

    KernelCallbackTable: DWORD; // Pointer to Pointer - List of callback functions
    SystemReserved: array[0..0] of ULONG;
    AtlThunkSListPtr32 : ULONG;
    ApiSetMap: DWORD; // Pointer .
    TlsExpansionCounter: ULONG;
    TlsBitmap: DWORD; // Pointer - ntdll!TlsBitMap of type PRTL_BITMAP .
    TlsBitmapBits: array[0..1] of ULONG; // 64 bits

    ReadOnlySharedMemoryBase: DWORD; // Pointer .
    HotpatchInformation: DWORD; // Pointer .

    ReadOnlyStaticServerData: DWORD; // Pointer - PTEXT_INFO .
    AnsiCodePageData: DWORD; // Pointer .
    OemCodePageData: DWORD; // Pointer .
    UnicodeCaseTableData: DWORD; // Pointer .
    NumberOfProcessors: ULONG;
    NtGlobalFlag: ULONG;
    Unknown01: ULONG; // Padding or something
    CriticalSectionTimeout: LARGE_INTEGER;
    HeapSegmentReserve: ULONG;
    HeapSegmentCommit: ULONG;
    HeapDeCommitTotalFreeThreshold: ULONG;
    HeapDeCommitFreeBlockThreshold: ULONG;
    NumberOfHeaps: ULONG;
    MaximumNumberOfHeaps: ULONG;
    ProcessHeaps: DWORD; // Pointer to Pointers.
    GdiSharedHandleTable: DWORD; // Pointer to Pointers.
    ProcessStarterHelper: DWORD; // Pointer .
    GdiDCAttributeList: ULONG;

    LoaderLock: DWORD; // Pointer to RTL_CRITICAL_SECTION .

    OSMajorVersion: ULONG;
    OSMinorVersion: ULONG;
    OSBuildNumber: word;
    OSCSDVersion: word;
    OSPlatformId: ULONG;
    ImageSubsystem: ULONG;
    ImageSubsystemMajorVersion: ULONG;
    ImageSubsystemMinorVersion: ULONG;

    ActiveProcessAffinityMask : DWORD;

    GdiHandleBuffer: array[0..33] of ULONG;
    PostProcessInitRoutine: DWORD; // Pointer .
    TlsExpansionBitmap: DWORD; // Pointer .
    TlsExpansionBitmapBits: array[0..31] of ULONG;
    SessionId: ULONG;

    AppCompatFlags: ULARGE_INTEGER;
    AppCompatFlagsUser: ULARGE_INTEGER;
    pShimData: DWORD; // Pointer .
    AppCompatInfo: DWORD; // Pointer .
    CSDVersion: UNICODE_STRING_32;

    ActivationContextData: DWORD; // Pointer to ACTIVATION_CONTEXT_DATA
    ProcessAssemblyStorageMap: DWORD; // Pointer to PASSEMBLY_STORAGE_MAP
    SystemDefaultActivationContextData: DWORD; // Pointer to ACTIVATION_CONTEXT_DATA
    SystemAssemblyStorageMap: DWORD; // Pointer to ASSEMBLY_STORAGE_MAP

    MinimumStackCommit: DWORD;

    FlsCallback: DWORD; // Pointer to Pointer .
    FlsListHead: LIST_ENTRY_32;
    FlsBitmap: DWORD; // Pointer .
    FlsBitmapBits: array[0..3] of ULONG;
    FlsHighIndex: ULONG;
    WerRegistrationData : DWORD; // Pointer .
    WerShipAssertPtr : DWORD; // Pointer .
    pContextData : DWORD; // Pointer .
    pImageHeaderHash : DWORD; // Pointer .

    TracingFlags : bitpacked record  // Both x32 - x64 .
      case boolean of
        False: (
          HeapTracingEnabled : T1Bit;
          CritSecTracingEnabled : T1Bit;
          LibLoaderTracingEnabled : T1Bit;
          SpareTracingBits :  0..$1FFFFFFF; // 29 bits .
        );
        True: (TracingFlag : ULONG)
    end;

    Unknown02: ULONG; // Padding or something
    CsrServerReadOnlySharedMemoryBase : QWORD;
    TppWorkerpListLock : DWORD;
    TppWorkerpList : LIST_ENTRY_32;
    WaitOnAddressHashTable : array [0..127] of DWORD; // Pointers .
  end;

  TPEB_64 = record
    InheritedAddressSpace: BOOLEAN;
    ReadImageFileExecOptions: BOOLEAN;
    BeingDebugged: BOOLEAN;

    BitFields : bitpacked record  // both x32 - x64 .
      case boolean of
        false : (
            ImageUsesLargePages ,
            IsProtectedProcess  ,
            IsImageDynamicallyRelocated  ,
            SkipPatchingUser32Forwarders,
            IsPackagedProcess,
            IsAppContainer,
            IsProtectedProcessLight,
            SpareBit : T1Bit;
        );
        true : (SpareBool : Boolean);
    end;
    Padding0 : ULONG;
    Mutant: QWORD; // Pointer .
    ImageBaseAddress: QWORD;
    Ldr: Int64;// Pointer PEB_LDR_DATA << TODO add it .
    ProcessParameters: Int64;// TODO : PRTL_USER_PROCESS_PARAMETERS ;
    SubSystemData: QWORD; // Pointer
    ProcessHeap: QWORD; // Pointer
    FastPebLock: QWORD; // Pointer - TODO : PRTL_CRITICAL_SECTION ;

    AtlThunkSListPtr : QWORD; // Pointer
    IFEOKey : QWORD; // Pointer

    CrossProcessFlags : bitpacked record  // Both x32 - x64 .
      case Integer of
        0: (
          ProcessInJob,
          ProcessInitializing,
          ProcessUsingVEH,
          ProcessUsingVCH,
          ProcessUsingFTH : T1Bit;
          ReservedBits0 :  0..$7FFFFFF; // 27 bits .
        );
        1: (CrossProcessFlag : ULONG)
    end;
    Padding1 : ULONG;

    KernelCallbackTable: QWORD; // Pointer to Pointer - List of callback functions
    SystemReserved: array[0..0] of ULONG;
    AtlThunkSListPtr32 : ULONG;
    ApiSetMap : QWORD;
    TlsExpansionCounter: ULONG;
    Padding2 : ULONG;
    TlsBitmap: QWORD; // Pointer - ntdll!TlsBitMap of type PRTL_BITMAP .
    TlsBitmapBits: array[0..1] of ULONG; // 64 bits
    ReadOnlySharedMemoryBase: QWORD; // Pointer .

    HotpatchInformation : QWORD; // Pointer .
    ReadOnlyStaticServerData: QWORD; // Pointer - PTEXT_INFO .
    AnsiCodePageData: QWORD; // Pointer .
    OemCodePageData: QWORD; // Pointer .
    UnicodeCaseTableData: QWORD; // Pointer .
    NumberOfProcessors: ULONG;
    NtGlobalFlag: ULONG;
    CriticalSectionTimeout: LARGE_INTEGER;
    HeapSegmentReserve: QWORD;
    HeapSegmentCommit: QWORD;
    HeapDeCommitTotalFreeThreshold: QWORD;
    HeapDeCommitFreeBlockThreshold: QWORD;
    NumberOfHeaps: ULONG;
    MaximumNumberOfHeaps: ULONG;
    ProcessHeaps: QWORD; // Pointer to Pointers.
    GdiSharedHandleTable: QWORD; // Pointer to Pointers.
    ProcessStarterHelper: QWORD; // Pointer .
    GdiDCAttributeList: ULONG;
    Padding3 : ULONG;

    LoaderLock: QWORD; // Pointer to PCRITICAL_SECTION .
    OSMajorVersion : ULONG;
    OSMinorVersion : ULONG;
    OSBuildNumber  : word;
    OSCSDVersion   : word;
    OSPlatformId   : ULONG;
    ImageSubsystem : ULONG;
    ImageSubsystemMajorVersion: ULONG;
    ImageSubsystemMinorVersion: ULONG;
    Padding4 : ULONG;

    ActiveProcessAffinityMask : QWORD;
    GdiHandleBuffer: array[0..59] of ULONG; // x64: unsigned long[60] .
    PostProcessInitRoutine: QWORD; // Pointer .
    TlsExpansionBitmap: QWORD; // Pointer .
    TlsExpansionBitmapBits: array[0..31] of ULONG;
    SessionId: ULONG;
    Padding5 : ULONG;

    AppCompatFlags: ULARGE_INTEGER;
    AppCompatFlagsUser: ULARGE_INTEGER;
    pShimData: QWORD; // Pointer .
    AppCompatInfo: QWORD; // Pointer .
    CSDVersion: UNICODE_STRING_64;
    ActivationContextData: QWORD; // Pointer to ACTIVATION_CONTEXT_DATA
    ProcessAssemblyStorageMap: QWORD; // Pointer to PASSEMBLY_STORAGE_MAP
    SystemDefaultActivationContextData: QWORD; // Pointer to ACTIVATION_CONTEXT_DATA
    SystemAssemblyStorageMap: QWORD; // Pointer to ASSEMBLY_STORAGE_MAP
    MinimumStackCommit: QWORD;
    FlsCallback: QWORD; // Pointer to Pointer .
    FlsListHead: LIST_ENTRY_64;
    FlsBitmap: QWORD; // Pointer .
    FlsBitmapBits: array[0..3] of ULONG;
    FlsHighIndex: ULONG;
    WerRegistrationData : QWORD; // Pointer .
    WerShipAssertPtr : QWORD; // Pointer .
    pContextData : QWORD; // pUnused .
    pImageHeaderHash : QWORD; // Pointer .

    TracingFlags : bitpacked record  // Both x32 - x64 .
      case Integer of
        0: (
          HeapTracingEnabled : T1Bit;
          CritSecTracingEnabled : T1Bit;
          LibLoaderTracingEnabled : T1Bit;
          SpareTracingBits :  0..$1FFFFFFF; // 29 bits .
        );
        1: (TracingFlag : ULONG)
    end;
    Padding6: ULONG;
    CsrServerReadOnlySharedMemoryBase : QWORD;
    TppWorkerpListLock : QWORD;
    TppWorkerpList : LIST_ENTRY_64;
    WaitOnAddressHashTable : array [0..127] of QWORD; // Pointers .
  end;

implementation

end.


{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseNe;

interface

type
  // OS/2 .EXE header
  PImageOs2Header = ^TImageOs2Header;
  _IMAGE_OS2_HEADER = record
    ne_magic: Word;         // Magic number
    ne_ver: Byte;           // Version number
    ne_rev: Byte;           // Revision number
    ne_enttab: Word;        // Offset of Entry Table
    ne_cbenttab: Word;      // Number of bytes in Entry Table
    ne_crc: LongInt;        // Checksum of whole file
    ne_flags: Word;         // Flag word
    ne_autodata: Word;      // Automatic data segment number
    ne_heap: Word;          // Initial heap allocation
    ne_stack: Word;         // Initial stack allocation
    ne_csip: LongInt;       // Initial CS:IP setting
    ne_sssp: LongInt;       // Initial SS:SP setting
    ne_cseg: Word;          // Count of file segments
    ne_cmod: Word;          // Entries in Module Reference Table
    ne_cbnrestab: Word;     // Size of non-resident name table
    ne_segtab: Word;        // Offset of Segment Table
    ne_rsrctab: Word;       // Offset of Resource Table
    ne_restab: Word;        // Offset of resident name table
    ne_modtab: Word;        // Offset of Module Reference Table
    ne_imptab: Word;        // Offset of Imported Names Table
    ne_nrestab: LongInt;    // Offset of Non-resident Names Table
    ne_cmovent: Word;       // Count of movable entries
    ne_align: Word;         // Segment alignment shift count
    ne_cres: Word;          // Count of resource segments
    ne_exetyp: Byte;        // Target Operating system
    ne_flagsothers: Byte;   // Other .EXE flags
    ne_pretthunks: Word;    // offset to return thunks
    ne_psegrefbytes: Word;  // offset to segment ref. bytes
    ne_swaparea: Word;      // Minimum code swap area size
    ne_expver: array[0..1] of Byte; //Expected windows version (minor first)
  end;
  TImageOs2Header = _IMAGE_OS2_HEADER;
  IMAGE_OS2_HEADER = _IMAGE_OS2_HEADER;

const
  NOAUTODATA     = $0000;
  SINGLEDATA     = $0001;
  MULTIPLEDATA   = $0002;
  ERRORS         = $2000;
  LIBRARY_MODULE = $8000;

  EXETYPE_UNKNOWN = $0;
  EXETYPE_OS2     = $1;
  EXETYPE_WINDOWS = $2;
  EXETYPE_DOS40   = $3;
  EXETYPE_WIN386  = $4;
  EXETYPE_BOSS    = $5;

  SEGMENTGLAG_TYPE_MASK = $0007;
  SEGMENTGLAG_CODE      = $0000;
  SEGMENTGLAG_DATA      = $0001;
  SEGMENTGLAG_MOVEABLE  = $0010;
  SEGMENTGLAG_PRELOAD   = $0040;
  SEGMENTGLAG_RELOCINFO = $0100;
  SEGMENTGLAG_DISCARD   = $F000;

  RESTABLEFLAG_MOVEABLE = $0010;
  RESTABLEFLAG_PURE     = $0020;
  RESTABLEFLAG_PRELOAD  = $0040;

type
  _EXE_SEGMENTHEADER = record
    Offset: Word;
    Size: Word;
    Flags: Word;
    MinAllocSize: Word;
  end;
  TExeSegmentHeader = _EXE_SEGMENTHEADER;

const
  RELOCTYPE_SOURCE_MASK = $0f;
  RELOCTYPE_LOBYTE      = $00;
  RELOCTYPE_SEGMENT     = $02;
  RELOCTYPE_FAR_ADDR    = $03;
  RELOCTYPE_OFFSET      = $05;

  RELOCFLAG_TARGET_MASK   = $03;
  RELOCFLAG_INTERNALREF   = $00;
  RELOCFLAG_IMPORTORDINAL = $01;
  RELOCFLAG_IMPORTNAME    = $02;
  RELOCFLAG_OSFIXUP       = $03;
  RELOCFLAG_ADDITIVE      = $04;

type
  _RELOC_TABLE = record
    // RELOCTYPE_*
    RelocType: Byte;
    // RELOCFLAG_*
    RelocFlag: Byte;
    Offset: Word;
    InternalRef: record
      SegNum: Byte;
      _: Byte;
      Offset: Word;
    end;
    ImportName: record
      Module: Word;
      Name: Word;
    end;
    ImportOrdinal: record
      Module: Word;
      Oridnal: Word;
    end;
  end;
  TRelocTable = _RELOC_TABLE;

  _RESIDENT_NAME_TABLE_ENTRY = record
    Size: Byte;
    Name: Byte;
    Ordinal: Word;
  end;
  TResidentNameTableEntry = _RESIDENT_NAME_TABLE_ENTRY;

  _IMPORTED_NAME_TABLE_ENTRY = record
    Size: Byte;
    Name: Byte;
  end;
  TImportedNameTableEntry = _IMPORTED_NAME_TABLE_ENTRY;

  _RESOURCE_BLOCK = record
    TypeId: Word;
    Count: Word;
    Reserved: Cardinal;
  end;
  TResourceBlock = _RESOURCE_BLOCK;
  _RESOURCE_TABLE = record
    FileOffset: Word;
    Length: Word;
    Flag: Word;
    ResourceId: Word;
    Reserved: Cardinal;
  end;
  TResouceTable = _RESOURCE_TABLE;

  _RESOURCE_TABLE_ENTRY = record
    AlignShift: Word;
    Block: TResourceBlock;
    SizeOfTypeName: Byte;
    Text: Byte;
  end;
  TResourceTableEntry = _RESOURCE_TABLE_ENTRY;

const
  IMAGE_OS2_SIGNATURE    = ((Ord('E') shl 8) + Ord('N'));
  IMAGE_OS2_SIGNATURE_LE = ((Ord('E') shl 8) + Ord('L'));

implementation

end.

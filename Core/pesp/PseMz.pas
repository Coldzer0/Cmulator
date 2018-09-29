{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseMz;

interface

type
  // MZ Header
  TExeHeader = packed record
    Signature: Word;            // This is the "magic number" of an EXE file. The
                                // first byte of the file is 0x4d and the second is 0x5a.

    BytesInLastBlock: Word;     // The number of bytes in the last block of the program
                                // that are actually used. If this value is zero, that
                                // means the entire last block is used (i.e. the effective value is 512).

    BlocksInFile: Word;         // Number of blocks in the file that are part of the EXE file.
                                // If [02-03] is non-zero, only that much of the last block is used.

    NumRelocs: Word;            // Number of relocation entries stored after the header. May be zero.

    HeaderParagraphs: Word;     // Number of paragraphs in the header. The program's data begins
                                // just after the header, and this field can be used to calculate
                                // the appropriate file offset. The header includes the relocation
                                // entries. Note that some OSs and/or programs may fail if the header is not a multiple of 512 bytes.

    MinExtraParagraphs: Word;   // Number of paragraphs of additional memory that the program will need.
                                // This is the equivalent of the BSS size in a Unix program.
                                // The program can't be loaded if there isn't at least this much memory available to it.

    MaxExtraParagraphs: Word;   // Maximum number of paragraphs of additional memory.
                                // Normally, the OS reserves all the remaining conventional memory
                                // for your program, but you can limit it with this field.

    ss: Word;                   // Relative value of the stack segment. This value is added to the segment
                                // the program was loaded at, and the result is used to initialize the SS register.

    sp: Word;                   // Initial value of the SP register.

    Checksum: Word;             // Word checksum. If set properly, the 16-bit sum of all
                                // words in the file should be zero. Usually, this isn't filled in.

    ip: Word;                   // Initial value of the IP register.

    cs: Word;                   // Initial value of the CS register, relative to the segment the program was loaded at.

    RelocTableOffset: Word;     // Offset of the first relocation item in the file.
    OverlayNumber: Word;        // Overlay number. Normally zero, meaning that it's the main program.
  end;

  TExeReloc = record
    Offset: Word;
    Segment: Word;
  end;

  // DOS Header
  PImageDosHeader = ^TImageDosHeader;
  _IMAGE_DOS_HEADER = record           { DOS .EXE header                  }
    e_magic: Word;                     { Magic number                     }
    e_cblp: Word;                      { Bytes on last page of file       }
    e_cp: Word;                        { Pages in file                    }
    e_crlc: Word;                      { Relocations                      }
    e_cparhdr: Word;                   { Size of header in paragraphs     }
    e_minalloc: Word;                  { Minimum extra paragraphs needed  }
    e_maxalloc: Word;                  { Maximum extra paragraphs needed  }
    e_ss: Word;                        { Initial (relative) SS value      }
    e_sp: Word;                        { Initial SP value                 }
    e_csum: Word;                      { Checksum                         }
    e_ip: Word;                        { Initial IP value                 }
    e_cs: Word;                        { Initial (relative) CS value      }
    e_lfarlc: Word;                    { File address of relocation table }
    e_ovno: Word;                      { Overlay number                   }
    e_res: array [0..3] of Word;       { Reserved words                   }
    e_oemid: Word;                     { OEM identifier (for e_oeminfo)   }
    e_oeminfo: Word;                   { OEM information; e_oemid specific}
    e_res2: array [0..9] of Word;      { Reserved words                   }
    _lfanew: LongInt;                  { File address of new exe header   }
  end;
  TImageDosHeader = _IMAGE_DOS_HEADER;
  IMAGE_DOS_HEADER = _IMAGE_DOS_HEADER;

const
  DOS_HEADER_MZ = ((Ord('Z') shl 8) + Ord('M'));

implementation

end.

{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseElf;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils;

const
  // e_ident[] Identification Indexes
  EI_MAG0    = 0; // File identification
  EI_MAG1    = 1; // File identification
  EI_MAG2    = 2; // File identification
  EI_MAG3    = 3; // File identification
  EI_CLASS   = 4; // File class
  EI_DATA    = 5; // Data encoding
  EI_VERSION = 6; // File version
  EI_PAD     = 7; // Start of padding bytes
  EI_NIDENT = 16; // SizeOf(e_ident)

  // e_type
  ET_NONE       = 0;  //No file type
  ET_REL        = 1;  //Relocatable file
  ET_EXEC       = 2;  //Executable file
  ET_DYN        = 3;  //Shared object file
  ET_CORE       = 4;  //Core file
  ET_LOPROC = $ff00;  //Processor-specific
  ET_HIPROC = $ffff;  //Processor-specific

  // e_machine
  EM_NONE    = $00; // No machine
  EM_M32     = $01; // AT&T WE 32100
  EM_SPARC   = $02; // SPARC
  EM_386     = $03; // x86
  EM_68K     = $04; // Motorola 68000
  EM_88K     = $05; // Motorola 88000
  EM_860     = $07; // Intel 80860
  EM_MIPS    = $08; // MIPS RS3000
  EM_PPC     = $14; // PowerPC
  EM_ARM     = $28; // ARM
  EM_SUPERH  = $2A; // SuperH
  EM_IA64    = $32; // IA-64
  EM_X86_64  = $3E; // x86-64
  EM_AARCH64 = $7B; // AArch64 (ARM-64)

  // EI_CLASS
  ELFCLASSNONE = 0; // Invalid class
  ELFCLASS32   = 1; // 32-bit objects
  ELFCLASS64   = 2; // 64-bit objects

  // EI_DATA
  ELFDATANONE = 0; // Invalid data encoding
  ELFDATA2LSB = 1; // Little Endian
  ELFDATA2MSB = 2; // Big Endian

  // Special Section Indexes
  SHN_UNDEF     = 0;
  SHN_LORESERVE = $ff00;
  SHN_LOPROC    = $ff00;
  SHN_HIPROC    = $ff1f;
  SHN_ABS       = $fff1;
  SHN_COMMON    = $fff2;
  SHN_HIRESERVE = $ffff;

  // sh_type
  SHT_NULL      = 0;
  SHT_PROGBITS  = 1;
  SHT_SYMTAB    = 2;
  SHT_STRTAB    = 3;
  SHT_RELA      = 4;
  SHT_HASH      = 5;
  SHT_DYNAMIC   = 6;
  SHT_NOTE      = 7;
  SHT_NOBITS    = 8;
  SHT_REL       = 9;
  SHT_SHLIB     = 10;
  SHT_DYNSYM    = 11;
  SHT_NUM       = 12;
  SHT_LOPROC    = $70000000;
  SHT_HIPROC    = $7fffffff;
  SHT_LOUSER    = $80000000;
  SHT_HIUSER    = $ffffffff;

  // sh_flags
  SHF_WRITE     = $1;          // The section contains data that should be writable during process execution.
  SHF_ALLOC     = $2;          // The section occupies memory during process execution. Some control sections do
                               // not reside in the memory image of an object file; this attribute is off for those sections.
  SHF_EXECINSTR = $4;          // The section contains executable machine instructions.
  SHF_MASKPROC  = $f0000000;   // All bits included in this mask are reserved for processor-specific semantics.

type
  Elf32_Addr = Cardinal;
  Elf32_Half = Word;
  Elf32_Off = Cardinal;
  Elf32_Sword = Integer;
  Elf32_Word = Cardinal;
  Elf32_Section = Word;

  Elf64_Addr = UInt64;
  Elf64_Off = UInt64;
  Elf64_Word = Cardinal;
  Elf64_Xword = UInt64;
  Elf64_Section = Word;

  // 32 Bit file header
  Elf32_Ehdr = record
    e_ident: array[0..EI_NIDENT-1] of Byte;
    e_type: Elf32_Half;
    e_machine: Elf32_Half;
    e_version: Elf32_Word;
    e_entry: Elf32_Addr;
    e_phoff: Elf32_Off;
    e_shoff: Elf32_Off;
    e_flags: Elf32_Word;
    e_ehsize: Elf32_Half;
    e_phentsize: Elf32_Half;
    e_phnum: Elf32_Half;
    e_shentsize: Elf32_Half;
    e_shnum: Elf32_Half;
    e_shstrndx: Elf32_Half;
  end;
  TElf32Header = Elf32_Ehdr;

  // 64 Bit file header
  Elf64_Ehdr = record
    e_ident: array[0..EI_NIDENT-1] of Byte;
    e_type: Elf32_Half;                               // This member identifies the object file type.
    e_machine: Elf32_Half;                            // This member’s value specifies the required architecture for an individual file.
    e_version: Elf32_Word;
    e_entry: Elf64_Addr;                              // This member gives the virtual address to which the system first transfers control, thus
                                                      // starting the process. If the file has no associated entry point, this member holds zero.
    e_phoff: Elf64_Off;                               // This member holds the program header table’s file offset in bytes. If the file has no
                                                      // program header table, this member holds zero.
    e_shoff: Elf64_Off;
    e_flags: Elf32_Word;
    e_ehsize: Elf32_Half;
    e_phentsize: Elf32_Half;
    e_phnum: Elf32_Half;
    e_shentsize: Elf32_Half;
    e_shnum: Elf32_Half;
    e_shstrndx: Elf32_Half;
  end;
  TElf64Header = Elf64_Ehdr;

  TElf32SectionHeader = record
    sh_name: Elf32_Word;               // This member specifies the name of the section. Its value is an index into the section
                                       // header string table section [see ‘‘String Table’’ below], giving the location of a null-
                                       // terminated string.
    sh_type: Elf32_Word;
    sh_flags: Elf32_Word;
    sh_addr: Elf32_Addr;
    sh_offset: Elf32_Off;
    sh_size: Elf32_Word;
    sh_link: Elf32_Word;
    sh_info: Elf32_Word;
    sh_addralign: Elf32_Word;
    sh_entsize: Elf32_Half;
  end;
  PElf32SectionHeader = ^TElf32SectionHeader;

  TElf64SectionHeader = record
    sh_name: Elf32_Word;
    sh_type: Elf32_Word;
    sh_flags: Elf64_Xword;
    sh_addr: Elf64_Addr;
    sh_offset: Elf64_Off;
    sh_size: Elf64_Xword;
    sh_link: Elf32_Word;
    sh_info: Elf32_Word;
    sh_addralign: Elf64_Xword;
    sh_entsize: Elf64_Xword;
  end;
  PElf64SectionHeader = ^TElf64SectionHeader;

  Elf32_Phdr  = record
    p_type: Elf32_Word;
    p_offset: Elf32_Off;
    p_vaddr: Elf32_Addr;
    p_paddr: Elf32_Addr;
    p_filesz: Elf32_Word;
    p_memsz: Elf32_Word;
    p_flags: Elf32_Word;
    p_align: Elf32_Word;
  end;
  TElf32ProgramHeader = Elf32_Phdr;
  Elf64_Phdr  = record
    p_type: Elf64_Word;
    p_flags: Elf64_Word;
    p_offset: Elf64_Off;
    p_vaddr: Elf64_Addr;
    p_paddr: Elf64_Addr;
    p_filesz: Elf64_Xword;
    p_memsz: Elf64_Xword;
    p_align: Elf64_Xword;
  end;
  TElf64ProgramHeader = Elf64_Phdr;

const
  // p_type
  PT_NULL    = 0;
  PT_LOAD    = 1;
  PT_DYNAMIC = 2;
  PT_INTERP  = 3;
  PT_NOTE    = 4;
  PT_SHLIB   = 5;
  PT_PHDR    = 6;
  PT_LOPROC  = $70000000;
  PT_HIPROC  = $7fffffff;

type
  TElf32_Sym = record
    st_name: Elf32_Word;           // An index into the object file's symbol string table,
                                   // which holds the character representations of the symbol names.
                                   // If the value is nonzero, it represents a string table index
                                   // that gives the symbol name. Otherwise, the symbol table entry has no name.
    st_value: Elf32_Addr;          // The value of the associated symbol. Depending on the context,
                                   // this can be an absolute value, an address, and so forth.
    st_size: Elf32_Word;           // Many symbols have associated sizes. For example, a data object's size is
                                   // the number of bytes contained in the object. This member holds 0 if the
                                   // symbol has no size or an unknown size.
    st_info: Byte;
    st_other: Byte;
    st_shndx: Elf32_Section;       // Every symbol table entry is defined in relation to some section.
                                   // This member holds the relevant section header table index
  end;

  TElf64_Sym = record
    st_name: Elf64_Word;
    st_info: Byte;
    st_other: Byte;
    st_shndx: Elf64_Section;
    st_value: Elf64_Addr;
    st_size: Elf64_Xword;
  end;

function GetSecCharacteristicsString(const Characteristics: Cardinal): string;
function GetTypeString(const e_type: Elf32_Half): string;
function GetMachineString(const e_machine: Elf32_Half): string;
function GetIdentString(const e_ident: array of Byte): string;
function GetIdentHexString(const e_ident: array of Byte): string;
function GetElfTypeString(const sh_type: Elf32_Word): string;

implementation

function GetElfTypeString(const sh_type: Elf32_Word): string;
begin
  case sh_type of
    SHT_NULL: Result := 'SHT_NULL';
    SHT_PROGBITS: Result := 'SHT_PROGBITS';
    SHT_SYMTAB: Result := 'SHT_SYMTAB';
    SHT_STRTAB: Result := 'SHT_STRTAB';
    SHT_RELA: Result := 'SHT_RELA';
    SHT_HASH: Result := 'SHT_HASH';
    SHT_DYNAMIC: Result := 'SHT_DYNAMIC';
    SHT_NOTE: Result := 'SHT_NOTE';
    SHT_NOBITS: Result := 'SHT_NOBITS';
    SHT_REL: Result := 'SHT_REL';
    SHT_SHLIB: Result := 'SHT_SHLIB';
    SHT_DYNSYM: Result := 'SHT_DYNSYM';
    SHT_NUM: Result := 'SHT_NUM';
    SHT_LOPROC: Result := 'SHT_LOPROC';
    SHT_HIPROC: Result := 'SHT_HIPROC';
    SHT_LOUSER: Result := 'SHT_LOUSER';
    SHT_HIUSER: Result := 'SHT_HIUSER';
  else
    Result := 'Unknown';
  end;
end;

function GetIdentHexString(const e_ident: array of Byte): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to EI_NIDENT - 1 do begin
    if e_ident[i] <> 0 then
      Result := Result + IntToHex(Integer(e_ident[i]), 2);
  end;
end;

function GetIdentString(const e_ident: array of Byte): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to EI_NIDENT - 1 do begin
    if e_ident[i] <> 0 then
      Result := Result + Char(e_ident[i])
    else
      Break;
  end;
end;

function GetSecCharacteristicsString(const Characteristics: Cardinal): string;
begin
  Result := '';
  if Characteristics <> 0 then begin
    if (Characteristics and SHF_WRITE) = SHF_WRITE then
      Result := Result + 'SHF_WRITE | ';
    if (Characteristics and SHF_ALLOC) = SHF_ALLOC then
      Result := Result + 'SHF_ALLOC | ';
    if (Characteristics and SHF_EXECINSTR) = SHF_EXECINSTR then
      Result := Result + 'SHF_EXECINSTR | ';
    if (Characteristics and SHF_MASKPROC) = SHF_MASKPROC then
      Result := Result + 'SHF_MASKPROC | ';

    if Result <> '' then
      Delete(Result, Length(Result) - 2, MaxInt);
  end else
    Result := '0';
end;

function GetTypeString(const e_type: Elf32_Half): string;
begin
  case e_type of
    ET_NONE:
      Result := 'ET_NONE';
    ET_REL:
      Result := 'ET_REL';
    ET_EXEC:
      Result := 'ET_EXEC';
    ET_DYN:
      Result := 'ET_DYN';
    ET_CORE:
      Result := 'ET_CORE';
    ET_LOPROC:
      Result := 'ET_LOPROC';
    ET_HIPROC:
      Result := 'ET_HIPROC';
  else
    Result := Format('Unknown %d', [e_type]);
  end;
end;

function GetMachineString(const e_machine: Elf32_Half): string;
begin
  case e_machine of
    ET_NONE:
      Result := 'ET_NONE';
    EM_M32:
      Result := 'EM_M32';
    EM_SPARC:
      Result := 'EM_SPARC';
    EM_386:
      Result := 'EM_386';
    EM_68K:
      Result := 'EM_68K';
    EM_88K:
      Result := 'EM_88K';
    EM_860:
      Result := 'EM_860';
    EM_MIPS:
      Result := 'EM_MIPS';
    EM_PPC:
      Result := 'EM_PPC';
    EM_ARM:
      Result := 'EM_ARM';
    EM_SUPERH:
      Result := 'EM_SUPERH';
    EM_IA64:
      Result := 'EM_IA64';
    EM_X86_64:
      Result := 'EM_X86_64';
    EM_AARCH64:
      Result := 'EM_AARCH64';
  else
    Result := Format('Unknown %d', [e_machine]);
  end;
end;

end.

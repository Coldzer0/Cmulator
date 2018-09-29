{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseElfFile;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseFile, PseElf, PseSection, PseCmn;

type
  {
    ELF files, used on UNIXOIDE.

    References
      TIS Committee. Tool Interface Standard (TIS) Executable and Linking
        Format (ELF) Specification. TIS Committee, 1995.
  }
  TPseElfFile = class(TPseFile)
  private
    FFileHeader32: TElf32Header;
    FFileHeader64: TElf64Header;
    FProgramHeader32: array of TElf32ProgramHeader;
    FProgramHeader64: array of TElf64ProgramHeader;
    FSizeOfImage: Cardinal;
    function GetMachine: Elf32_Half;
    procedure ReadExports;
    procedure ReadImports;
    procedure ReadSections;
    procedure ReadProgramHeaders;
    function ReadSectionString(const Index: integer): string;
    procedure UpdateSectionNames;
  protected
  public
    constructor Create; override;
    destructor Destroy; override;
    function LoadFromStream(Stream: TStream): boolean; override;
    procedure SaveSectionToStream(const ASection: integer; Stream: TStream); override;
    function GetArch: TPseArch; override;
    function GetMode: TPseMode; override;
    function GetFirstAddr: UInt64; override;
    function GetEntryPoint: UInt64; override;

    function GetImageBase: UInt64;
    function GetSizeOfImage: Cardinal;

    function GetFriendlyName: string; override;

    property FileHeader32: TElf32Header read FFileHeader32;
    property FileHeader64: TElf64Header read FFileHeader64;
  end;

implementation

uses
  Math;

constructor TPseElfFile.Create;
begin
  inherited;
end;

destructor TPseElfFile.Destroy;
begin
  inherited;
end;

function TPseElfFile.LoadFromStream(Stream: TStream): boolean;
begin
  Result := inherited;
  if Result then begin
    FStream.Position := 0;
    FStream.Read(FFileHeader32, SizeOf(TElf32Header));

    // Check for ELF format
    if FFileHeader32.e_ident[EI_MAG0] <> $7f then
      Exit(false);
    if FFileHeader32.e_ident[EI_MAG1] <> Ord('E') then
      Exit(false);
    if FFileHeader32.e_ident[EI_MAG2] <> Ord('L') then
      Exit(false);
    if FFileHeader32.e_ident[EI_MAG3] <> Ord('F') then
      Exit(false);

    // 32 or 64 Bit
    if FFileHeader32.e_ident[EI_CLASS] = ELFCLASS64 then
      FBitness := pseb64
    else
      FBitness := pseb32;
    if Is64 then begin
      // Read 64 bit header, differs in size
      FStream.Position := 0;
      FStream.Read(FFileHeader64, SizeOf(TElf64Header));
    end;

    ReadProgramHeaders;
    ReadSections;
    ReadImports;
    ReadExports;
  end;
end;

function TPseElfFile.GetFirstAddr: UInt64;
var
  i: integer;
  sec: TPseSection;
  ep: UInt64;
begin
  // In contrast to PE files, ELF files do not define an image base, so
  // find the section with the entry point and return its target address
  ep := GetEntryPoint;
  for i := 0 to FSections.Count - 1 do begin
    sec := FSections[i];
    if (saCode in sec.Attribs) or ((saExecuteable in sec.Attribs)) then begin
      // Section must be executeable
      if (ep >= sec.Address) and (ep <= (sec.Address + sec.Size)) then begin
        // Entrypoint is inside the section
        Result := sec.Address;
        Exit;
      end;
    end;
  end;
  Result := 0;
end;

function TPseElfFile.GetEntryPoint: UInt64;
begin
  if IS64 then
    Result := FFileHeader64.e_entry
  else
    Result := FFileHeader32.e_entry;
end;

procedure TPseElfFile.UpdateSectionNames;
var
  i: integer;
  sec: TPseSection;
begin
  for i := 0 to FSections.Count - 1 do begin
    sec := FSections[i];
    sec.Name := ReadSectionString(sec.NameIndex);
  end;
end;

procedure TPseElfFile.ReadExports;
begin

end;

procedure TPseElfFile.ReadImports;
begin

end;

function TPseElfFile.ReadSectionString(const Index: integer): string;
var
  cur_pos: Int64;
  name: array[0..255] of AnsiChar;
  strtab: TPseSection;
begin
  Result := '(Unknown)';
  if Index = 0 then
    Exit;

  if IS64 then begin
    if FFileHeader64.e_shstrndx =  SHN_UNDEF then
      Exit;
    strtab := FSections[FFileHeader64.e_shstrndx];
    FStream.Seek(strtab.FileOffset + Index, soFromBeginning);
  end else begin
    if FFileHeader32.e_shstrndx =  SHN_UNDEF then
      Exit;
    strtab := FSections[FFileHeader32.e_shstrndx];
    FStream.Seek(strtab.FileOffset + Index, soFromBeginning);
  end;

  cur_pos := FStream.Position;
  FStream.Read(name, 256);
  FStream.Position := cur_pos;
  Result := string(StrPas(PAnsiChar(@name)));
end;

procedure TPseElfFile.ReadSections;
var
  n, i: integer;
  sec32: TElf32SectionHeader;
  sec64: TElf64SectionHeader;
  sec: TPseSection;
  attribs: TSectionAttribs;
begin
  FSections.Clear;
  FSizeOfImage := 0;

  if IS64 then begin
    FStream.Seek(FFileHeader64.e_shoff, soFromBeginning);
    n := FFileHeader64.e_shnum;

    for i := 0 to n - 1 do begin
      attribs := [];
      FStream.Read(sec64, SizeOf(TElf64SectionHeader));
      sec := FSections.New;
      sec.FileOffset := sec64.sh_offset;
      sec.NameIndex := sec64.sh_name;
      sec.Address := sec64.sh_addr;
      sec.Size := sec64.sh_size;
      sec.OrigAttribs := sec64.sh_flags;
      sec.ElfType := sec64.sh_type;
      if sec64.sh_type = SHT_PROGBITS then
        Include(attribs, saCode)
      else if sec64.sh_type = SHT_STRTAB then
        Include(attribs, saStringTable)
      else if sec64.sh_type = SHT_SYMTAB then
        Include(attribs, saSymbolTable)
      else if sec64.sh_type = SHT_NULL then
        // Don't show in sections tree
        Include(attribs, saNull);

      if (sec64.sh_flags and SHF_EXECINSTR) = SHF_EXECINSTR then
        Include(attribs, saExecuteable);
      if (sec64.sh_flags and SHF_ALLOC) = SHF_ALLOC then
        Include(attribs, saReadable);
      if (sec64.sh_flags and SHF_WRITE) = SHF_WRITE then
        Include(attribs, saWriteable);
      sec.Attribs := attribs;

      if sec64.sh_addr <> 0 then
        Inc(FSizeOfImage, sec64.sh_size);
    end;
  end else begin
    FStream.Seek(FFileHeader32.e_shoff, soFromBeginning);
    n := FFileHeader32.e_shnum;
    for i := 0 to n - 1 do begin
      attribs := [];
      FStream.Read(sec32, SizeOf(TElf32SectionHeader));
      sec := FSections.New;
      sec.FileOffset := sec32.sh_offset;
      sec.NameIndex := sec32.sh_name;
      sec.Address := sec32.sh_addr;
      sec.Size := sec32.sh_size;
      sec.OrigAttribs := sec32.sh_flags;
      sec.ElfType := sec32.sh_type;
      if sec32.sh_type = SHT_PROGBITS then
        Include(attribs, saCode)
      else if sec32.sh_type = SHT_STRTAB then
        Include(attribs, saStringTable)
      else if sec32.sh_type = SHT_SYMTAB then
        Include(attribs, saSymbolTable)
      else if sec32.sh_type = SHT_NULL then
        Include(attribs, saNull);

      if (sec32.sh_flags and SHF_EXECINSTR) = SHF_EXECINSTR then
        Include(attribs, saExecuteable);
      sec.Attribs := attribs;

      if sec32.sh_addr <> 0 then
        Inc(FSizeOfImage, sec32.sh_size);
    end;
  end;
  // Now update section names, string table secion should be loaded
  UpdateSectionNames;
end;

procedure TPseElfFile.ReadProgramHeaders;
var
  i, n: integer;
begin
  if IS64 then begin
    FStream.Seek(FFileHeader64.e_phoff, soFromBeginning);
    n := FFileHeader64.e_phnum;
    SetLength(FProgramHeader64, n);
    for i := 0 to n - 1 do begin
      FStream.Read(FProgramHeader64[i], FFileHeader64.e_phentsize);
    end;
  end else begin
    FStream.Seek(FFileHeader32.e_phoff, soFromBeginning);
    n := FFileHeader32.e_phnum;
    SetLength(FProgramHeader32, n);
    for i := 0 to n - 1 do begin
      FStream.Read(FProgramHeader32[i], FFileHeader32.e_phentsize);
    end;
  end;
end;

procedure TPseElfFile.SaveSectionToStream(const ASection: integer; Stream: TStream);
var
  sec: TPseSection;
  o, s: Int64;
begin
  sec := FSections[ASection];
  o := sec.FileOffset;
  FStream.Seek(o, soFromBeginning);
  s := Min(Int64(sec.Size), Int64(FStream.Size - o));
  Stream.CopyFrom(FStream, s);
end;

function TPseElfFile.GetImageBase: UInt64;
var
  i: integer;
begin
  Result := $FFFFFFFFFFFFFF;
  if Is64 then begin
    for i := Low(FProgramHeader64) to High(FProgramHeader64) do begin
      if (FProgramHeader64[i].p_type = PT_LOAD) and (Result > FProgramHeader64[i].p_vaddr) then
        Result := FProgramHeader64[i].p_vaddr;
    end;
  end else begin
    for i := Low(FProgramHeader32) to High(FProgramHeader32) do begin
      if  (FProgramHeader32[i].p_type = PT_LOAD) and (Result > FProgramHeader32[i].p_vaddr) then
        Result := FProgramHeader32[i].p_vaddr;
    end;
  end;
end;

function TPseElfFile.GetSizeOfImage: Cardinal;
begin
  Result := FSizeOfImage;
end;

function TPseElfFile.GetMachine: Elf32_Half;
begin
  if IS64 then
    Result := FFileHeader64.e_machine
  else
    Result := FFileHeader32.e_machine;
end;

function TPseElfFile.GetArch: TPseArch;
begin
  case GetMachine of
    EM_386,
    EM_X86_64:
      begin
        Result := pseaX86;
      end;
    EM_MIPS:
      begin
        Result := pseaMIPS;
      end;
    EM_PPC:
      begin
        Result := pseaPPC;
      end;
    EM_ARM:
      begin
        Result := pseaARM;
      end;
    EM_AARCH64:
      begin
        Result := pseaARM64;
      end;
    else
      Result := pseaUnknown;
  end;
end;

function TPseElfFile.GetMode: TPseMode;
begin
  Result := [];
  case GetMachine of
    EM_ARM, EM_AARCH64:
      Include(Result, psemARM);
    EM_386:
      Include(Result, psem32);
    EM_X86_64:
      Include(Result, psem64);
    EM_PPC:
      begin
        if Is64 then
          Include(Result, psem64);
      end;
  end;
  if IS64 then begin
    if FFileHeader64.e_ident[EI_DATA] = ELFDATA2LSB then
      Include(Result, psemLittleEndian)
    else
      Include(Result, psemBigEndian);
  end else begin
    if FFileHeader32.e_ident[EI_DATA] = ELFDATA2LSB then
      Include(Result, psemLittleEndian)
    else
      Include(Result, psemBigEndian);
  end;
end;

function TPseElfFile.GetFriendlyName: string;
begin
  Result := 'ELF';
  if Is64 then
    Result := Result + '64'
  else
    Result := Result + '32';
end;

initialization

end.

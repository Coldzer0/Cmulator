{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseNeFile;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseFile, PseSection, PseImportTable, PseCmn, PseMz, PseNe,
  PseResource;

type
  {
    Windows NE files.

    16 Bit Windows EXE file.

    References

    Micosoft. Executeable-file Header Format. Microsoft, February 1999.
    <ftp://ftp.microsoft.com/MISC1/DEVELOPR/WIN_DK/KB/Q65/1/22.TXT>

    <http://www.nondot.org/sabre/os/files/Executables/EXE-3.1.txt>

    <http://wiki.osdev.org/NE>

    <http://www.fileformat.info/format/exe/corion-ne.htm>
  }
  TPseNeFile = class(TPseFile)
  private
    FDosHeader: TImageDosHeader;
    FOs2Header: TImageOs2Header;
    procedure ReadSections;
    procedure ReadImports;
    procedure ReadExports;
    procedure ReadResources;
  protected
  public
    function LoadFromStream(Stream: TStream): boolean; override;
    procedure SaveSectionToStream(const ASection: integer; Stream: TStream); override;
    function GetFriendlyName: string; override;
    function GetArch: TPseArch; override;
    function GetMode: TPseMode; override;

    function GetEntryPoint: UInt64; override;
    function GetFirstAddr: UInt64; override;

    property DosHeader: TImageDosHeader read FDosHeader;
    property Os2Header: TImageOs2Header read FOs2Header;
  end;

function GetFlagsString(const AFlags: Word): string;
function GetExeTypeString(const AType: Byte): string;
function GetSecCharacteristicsString(const AFlags: Word): string;

implementation

uses
  Math;

function GetSecCharacteristicsString(const AFlags: Word): string;
begin
  Result := '';
  if (AFlags and SEGMENTGLAG_CODE) = SEGMENTGLAG_CODE then
    Result := Result + 'CODE | ';
  if (AFlags and SEGMENTGLAG_DATA) = SEGMENTGLAG_DATA then
    Result := Result + 'DATA | ';
  if (AFlags and SEGMENTGLAG_MOVEABLE) = SEGMENTGLAG_MOVEABLE then
    Result := Result + 'MOVEABLE | ';
  if (AFlags and SEGMENTGLAG_PRELOAD) = SEGMENTGLAG_PRELOAD then
    Result := Result + 'PRELOAD | ';
  if (AFlags and SEGMENTGLAG_RELOCINFO) = SEGMENTGLAG_RELOCINFO then
    Result := Result + 'RELOCINFO | ';
  if (AFlags and SEGMENTGLAG_DISCARD) = SEGMENTGLAG_DISCARD then
    Result := Result + 'DISCARD | ';

  if Result <> '' then
    Delete(Result, Length(Result) - 2, MaxInt);
end;

function GetFlagsString(const AFlags: Word): string;
begin
  Result := '';
  if (AFlags and NOAUTODATA) = NOAUTODATA then
    Result := Result + 'NOAUTODATA | ';
  if (AFlags and SINGLEDATA) = SINGLEDATA then
    Result := Result + 'SINGLEDATA | ';
  if (AFlags and MULTIPLEDATA) = MULTIPLEDATA then
    Result := Result + 'MULTIPLEDATA | ';
  if (AFlags and ERRORS) = ERRORS then
    Result := Result + 'ERRORS | ';
  if (AFlags and LIBRARY_MODULE) = LIBRARY_MODULE then
    Result := Result + 'LIBRARY_MODULE | ';

  if Result <> '' then
    Delete(Result, Length(Result) - 2, MaxInt);
end;

function GetExeTypeString(const AType: Byte): string;
begin
  case AType of
    EXETYPE_UNKNOWN: Result := 'Unknown';
    EXETYPE_OS2: Result := 'OS/2';
    EXETYPE_WINDOWS: Result := 'Windows';
    EXETYPE_DOS40: Result := 'MS-DOS 4.0';
    EXETYPE_WIN386: Result := 'Windows 386';
    EXETYPE_BOSS: Result := 'BOSS';
  else
    Result := 'Unknown';
  end;
end;

function TPseNeFile.LoadFromStream(Stream: TStream): boolean;
begin
  Result := inherited;
  if Result then begin
    FStream.Position := 0;
    if (FStream.Read(FDosHeader, SizeOf(TImageDosHeader)) <> SizeOf(TImageDosHeader)) then
      Exit(false);
    if FDosHeader.e_magic <> DOS_HEADER_MZ then
      Exit(false);

    FStream.Seek(FDosHeader._lfanew, soFromBeginning);
    if FStream.Read(FOs2Header, SizeOf(FOs2Header)) <> SizeOf(FOs2Header) then
      Exit(false);
    if (FOs2Header.ne_magic <> IMAGE_OS2_SIGNATURE) then
      Exit(false);

    FBitness := pseb16;

    ReadSections;
    ReadResources;
    ReadExports;
    ReadImports;
    Result := true;
  end;
end;

procedure TPseNeFile.ReadResources;
var
  entry: TResourceBlock;
  res_table: TResouceTable;
  i: integer;
  offset: Integer;
  res: TPseResource;
  res_align: Word;
begin
  // RESOURCE TABLE
  offset := FOs2Header.ne_rsrctab + FDosHeader._lfanew;
  FStream.Seek(offset, soFromBeginning);
  FStream.Read(res_align, 2);

  while (true) do begin
    if (FStream.Read(entry, SizeOf(TResourceBlock)) <> SizeOf(TResourceBlock)) then
      Break;
    if entry.TypeId = 0 then
      Break;

    for i := 0 to entry.Count - 1 do begin
      FStream.Read(res_table, SizeOf(res_table));
      res := FResources.New;
      res.ResType := entry.TypeId;
      res.ResId := res_table.ResourceId;
      res.Offset := res_table.FileOffset shl res_align;
      res.Size := res_table.Length shl res_align;
    end;
  end;
end;

procedure TPseNeFile.ReadExports;
begin
   // RESIDENT-NAME TABLE
   FExports.Clear;
end;

procedure TPseNeFile.ReadImports;
var
  i: integer;
  offset: Word;
  offsets: TList;
  next_offset: Word;
  string_len: Byte;
  name: array[0..MAXBYTE-1] of AnsiChar;
  import_obj: TPseImport;
  imp_api: TPseApi;
begin
  FImports.Clear;
  FStream.Seek(FOs2Header.ne_modtab + FDosHeader._lfanew, soFromBeginning);
  offsets := TList.Create;
  try
    // Each entry contains an offset for the module-name string within the imported-
    // names table; each entry is 2 bytes long.
    for i := 0 to FOs2Header.ne_cmod - 1 do begin
      // Offset within Imported Names Table to referenced module name
      // string.
      FStream.Read(offset, SizeOf(Word));
      offsets.Add(Pointer(offset));
    end;

    for i := 0 to offsets.Count - 1 do begin
      // This table contains the names of modules and procedures that are imported
      // by the executable file. Each entry is composed of a 1-byte field that
      // contains the length of the string, followed by any number of characters.
      // The strings are not null-terminated and are case sensitive.
      FStream.Seek(FOs2Header.ne_imptab + FDosHeader._lfanew + Word(offsets[i]), soFromBeginning);
      FStream.Read(string_len, SizeOf(Byte));
      FillChar(name, MAXBYTE, 0);
      FStream.Read(name, string_len);
      import_obj := FImports.New;
      import_obj.DllName := string(StrPas(PAnsiChar(@name)));
      if i < offsets.Count - 1 then
        next_offset := FOs2Header.ne_imptab + FDosHeader._lfanew + Word(offsets[i+1])
      else
        next_offset := FOs2Header.ne_enttab + FDosHeader._lfanew;

      while FStream.Position < next_offset do begin
        FStream.Read(string_len, SizeOf(Byte));
        FillChar(name, MAXBYTE, 0);
        FStream.Read(name, string_len);
        imp_api := import_obj.New;
        imp_api.Name := string(StrPas(PAnsiChar(@name)));
      end;

    end;
  finally
    offsets.Free;
  end;
end;

procedure TPseNeFile.ReadSections;
var
  i: integer;
  seg_header: TExeSegmentHeader;
  sec: TPseSection;
  attribs: TSectionAttribs;
begin
  FSections.Clear;
  FStream.Seek(FOs2Header.ne_segtab + FDosHeader._lfanew, soFromBeginning);
  for i := 0 to FOs2Header.ne_autodata - 1 do begin
    if (FStream.Read(seg_header, SizeOf(TExeSegmentHeader)) <> SizeOf(TExeSegmentHeader)) then
      Break;
    attribs := [];
    sec := FSections.New;
    sec.Name := Format('Segment %d', [i+1]);
    sec.Address := seg_header.Offset;
    sec.FileOffset := seg_header.Offset;
    if seg_header.Size <> 0 then
      sec.Size := seg_header.Size
    else
      sec.Size := 64 * 1024;                                                    // Zero means 64K.
    sec.OrigAttribs := seg_header.Flags;

    if (seg_header.Flags and SEGMENTGLAG_CODE) = SEGMENTGLAG_CODE then begin
      Include(attribs, saCode);
      Include(attribs, saExecuteable);
    end;
    if (seg_header.Flags and SEGMENTGLAG_DATA) = SEGMENTGLAG_DATA then begin
      Include(attribs, saData);
      if (seg_header.Flags and SEGMENTGLAG_PRELOAD) = SEGMENTGLAG_PRELOAD then
        Include(attribs, saReadable);
    end;
    sec.Attribs := attribs;
  end;
end;

function TPseNeFile.GetEntryPoint: UInt64;
begin
  Result := FOs2Header.ne_csip mod 65536;
end;

function TPseNeFile.GetFirstAddr: UInt64;
begin
  Result := 0;
end;

procedure TPseNeFile.SaveSectionToStream(const ASection: integer; Stream: TStream);
var
  sec: TPseSection;
  o, s: Int64;
begin
  sec := FSections[ASection];
  o := sec.Address;
  FStream.Position := o;
  s := Min(Int64(sec.Size), Int64(FStream.Size - o));
  Stream.CopyFrom(FStream, s);
end;

function TPseNeFile.GetArch: TPseArch;
begin
  Result := pseaX86;
end;

function TPseNeFile.GetMode: TPseMode;
begin
  Result := [psem16];
end;

function TPseNeFile.GetFriendlyName: string;
begin
  Result := 'NE16';
end;

initialization

end.

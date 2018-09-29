{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseMzFile;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseFile, PseSection, PseCmn, PseMz;

type
  {
    DOS EXE files.

    References

    http://www.delorie.com/djgpp/doc/exe/
    http://www.delorie.com/djgpp/doc/rbinter/it/94/15.html
    http://wiki.osdev.org/MZ
    http://www.tavi.co.uk/phobos/exeformat.html
    http://www.fileformat.info/format/exe/corion-mz.htm
    http://blogs.msdn.com/b/oldnewthing/archive/2008/03/24/8332730.aspx
    http://stackoverflow.com/questions/3715618/how-does-dos-load-a-program-into-memory
  }
  TPseMzFile = class(TPseFile)
  private
    FExeHeader: TExeHeader;
    FRelocs: array of TExeReloc;
  protected
  public
    function LoadFromStream(Stream: TStream): boolean; override;
    procedure SaveSectionToStream(const ASection: integer; Stream: TStream); override;
    function GetFriendlyName: string; override;
    function GetArch: TPseArch; override;
    function GetMode: TPseMode; override;

    function GetEntryPoint: UInt64; override;
    function GetFirstAddr: UInt64; override;

    function GetSizeOfImage: Cardinal;
  end;

implementation

uses
  Math;

function TPseMzFile.LoadFromStream(Stream: TStream): boolean;
var
  i: integer;
  sec: TPseSection;
begin
  Result := inherited;
  if Result then begin
    FStream.Position := 0;
    if (FStream.Read(FExeHeader, SizeOf(TExeHeader)) <> SizeOf(TExeHeader)) then
      Exit(false);
    if FExeHeader.Signature <> DOS_HEADER_MZ then
      Exit(false);

    // After the header, there follow the relocation items, which are used to span
    // multpile segments.
    FStream.Seek(FExeHeader.RelocTableOffset, soFromBeginning);
    SetLength(FRelocs, FExeHeader.NumRelocs);
    for i := 0 to FExeHeader.NumRelocs - 1 do begin
      if (FStream.Read(FRelocs[i], SizeOf(TExeReloc)) <> SizeOf(TExeReloc)) then
        Exit(false);
    end;

    sec := FSections.New;
    sec.Name := ChangeFileExt(ExtractFileName(FFilename), '');
    sec.Address := FExeHeader.HeaderParagraphs * 16;
    sec.FileOffset := FExeHeader.HeaderParagraphs * 16;
    FStream.Seek(sec.FileOffset, soFromBeginning);
    sec.Size := GetSizeOfImage;
    sec.Attribs := [saCode, saExecuteable, saData, saReadable, saWriteable];

    FBitness := pseb16;
  end;
end;

function TPseMzFile.GetEntryPoint: UInt64;
begin
  // Initial value of IP so this is the entry point
  Result := FExeHeader.ip;
end;

function TPseMzFile.GetFirstAddr: UInt64;
begin
  Result := 0;
end;

function TPseMzFile.GetSizeOfImage: Cardinal;
var
  header_size: Cardinal;
begin
  header_size := FExeHeader.HeaderParagraphs * 16;
  Result := FExeHeader.BlocksInFile * 512 - header_size;
  if Result + header_size < 512 then
    Result := 512 - header_size;
end;

procedure TPseMzFile.SaveSectionToStream(const ASection: integer; Stream: TStream);
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

function TPseMzFile.GetArch: TPseArch;
begin
  Result := pseaX86;
end;

function TPseMzFile.GetMode: TPseMode;
begin
  Result := [psem16];
end;

function TPseMzFile.GetFriendlyName: string;
begin
  Result := 'MZ16';
end;

initialization

end.

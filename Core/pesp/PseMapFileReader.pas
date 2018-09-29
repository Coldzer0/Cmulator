{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseMapFileReader;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseDebugInfo;

type
  {
    http://www.codeproject.com/Articles/3472/Finding-crash-information-using-the-MAP-file
    https://code.google.com/p/map2dbg/source/browse/trunk/map2dbg/convert.cpp
  }

  TMapFileType = (mftUnknown, mftByName, mftByValue);
  TMangeling = (mUnknown, mNotMangled, mMangled);
  TPseMapFileReader = class
  private
    FFileName: string;
    FStream: TFileStream;
    FSkipped: boolean;
    FFileType: TMapFileType;
    FMangeling: TMangeling;
    function ReadLine(Stream: TStream; out Line: string): boolean;
    procedure SkipToPublics;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;

    function GetNext(out ADebugInfo: TDebugInfoItem): boolean;
  end;

implementation

function SplitString(const AIn, ADelim: string; var AOut: array of string): integer;
var
  CurLine, te: string;
  p2: integer;
begin
  Result := 0;
  if AIn <> '' then begin
    CurLine := AIn;
    repeat
      p2 := Pos(ADelim, CurLine);
      if p2 = 0 then
        p2 := Length(CurLine) + 1;
      te := System.Copy(CurLine, 1, p2 - 1);
      System.Delete(CurLine, 1, p2);
      AOut[Result] := te;
      Inc(Result);
      if Result > High(AOut) then
        Break;
    until CurLine = '';
  end;
end;

constructor TPseMapFileReader.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  FStream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyNone);
  FSkipped := false;
  FFileType := mftUnknown;
  FMangeling := mUnknown;
  SkipToPublics;
end;

destructor TPseMapFileReader.Destroy;
begin
  FStream.Free;
  inherited;
end;

function TPseMapFileReader.GetNext(out ADebugInfo: TDebugInfoItem): boolean;
var
  ln: string;
  p, p2: integer;
  sseg, sOffset, sName: string;
  iSeg: integer;
  iOffset: Int64;
begin
  Result := false;
  if not FSkipped then
    Exit;

  while ReadLine(FStream, ln) do begin
    ln := Trim(ln);
    if (ln <> '') and (Length(ln) > 15) then begin
      //example of some lines:
      // 0001:0000035C       System.CloseHandle
      // 0001:00000380  __acrtused
      // Segment:Offset     Name
      p := Pos(':', ln);
      if p <> 0 then begin
        sseg := Copy(ln, 1, p-1);
        iseg := StrToIntDef(sseg, -1);
        if iseg = -1 then
          Continue;

        p2 := Pos(' ', ln);
        if p2 = 0 then
          Continue;
        sOffset := Copy(ln, p+1, p2 - p - 1);
        iOffset := StrToInt64Def('$' + sOffset, -1);
        if iOffset = -1 then
          Continue;

        sName := Trim(Copy(ln, p2+1, MaxInt));
        // Success
        ADebugInfo.Segment := iseg;
        ADebugInfo.Offset := iOffset;
        ADebugInfo.Name := sName;
        Result := true;
        Break;
      end;
    end;

  end;
end;

procedure TPseMapFileReader.SkipToPublics;
var
  ln: string;
begin
  while ReadLine(FStream, ln) do begin
    ln := Trim(ln);
    if ln <> '' then begin
      if Pos('Address', ln) <> 0 then begin
        if Pos('Publics by Value', ln) <> 0 then begin
          FSkipped := true;
          FFileType := mftByValue;
          Break;
        end else if Pos('Publics by Name', ln) <> 0 then begin
          FSkipped := true;
          FFileType := mftByName;
          Break;
        end;
      end;
    end;
  end;
end;

function TPseMapFileReader.ReadLine(Stream: TStream; out Line: string): boolean;
var
  ch: AnsiChar;
  RawLine: string;
begin
  Result := False;
  RawLine := '';
  ch := #0;
  while (Stream.Read(ch, 1) = 1) and (ch <> #13) do begin
    Result := True;
    RawLine := RawLine + Char(ch);
  end;
  Line := RawLine;
  if ch = #13 then begin
    Result := True;
    if (Stream.Read(ch, 1) = 1) and (ch <> #10) then
      Stream.Seek(-1, soFromCurrent); // unread it if not LF character.
  end;
end;

end.

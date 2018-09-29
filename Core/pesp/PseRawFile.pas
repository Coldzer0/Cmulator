{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseRawFile;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseFile, PseSection, PseCmn;

type
  TPseRawFile = class(TPseFile)
  private
  protected
  public
    function LoadFromStream(Stream: TStream): boolean; override;
    procedure SaveSectionToStream(const ASection: integer; Stream: TStream); override;
    function GetEntryPoint: UInt64; override;
    function GetFirstAddr: UInt64; override;
    function GetArch: TPseArch; override;
    function GetMode: TPseMode; override;
    function GetFriendlyName: string; override;
  end;

implementation

function TPseRawFile.LoadFromStream(Stream: TStream): boolean;
var
  sec: TPseSection;
begin
  Result := inherited;
  FStream.Position := 0;
  sec := FSections.New;
  sec.Address := 0;
  sec.Size := FStream.Size;
  sec.FileOffset := 0;
  // Assume its code
  sec.Attribs := [saCode];
  if FFilename <> '' then
    sec.Name := ExtractFileName(FFilename)
  else
    sec.Name := '(No name)';
end;

function TPseRawFile.GetFirstAddr: UInt64;
begin
  Result := 0;
end;

procedure TPseRawFile.SaveSectionToStream(const ASection: integer; Stream: TStream);
var
  sec: TPseSection;
begin
  sec := FSections[ASection];
  FStream.Position := sec.Address;
  Stream.CopyFrom(FStream, sec.Size);
end;

function TPseRawFile.GetEntryPoint: UInt64;
begin
  Result := 0;
end;

function TPseRawFile.GetArch: TPseArch;
begin
  Result := pseaUnknown;
end;

function TPseRawFile.GetMode: TPseMode;
begin
  Result := [];
end;

function TPseRawFile.GetFriendlyName: string;
begin
  Result := 'Raw binary';
end;

initialization

end.

unit PseImgLoader;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, PseFile, PseVirtMem;

type
  TPseImgLoader = class
  protected
    FFile: TPseFile;
  public
    constructor Create(AFile: TPseFile); virtual;
    procedure Load(AMem: TPseVirtMem); virtual; abstract;

    class function GetInstance(AFile: TPseFile): TPseImgLoader;
    class function LoadFile(AFile: TPseFile; AMem: TPseVirtMem): boolean;
  end;

implementation

uses
  PsePeFile, PsePeLoader, PseElfLoader, PseElfFile;

class function TPseImgLoader.GetInstance(AFile: TPseFile): TPseImgLoader;
begin
  if AFile is TPsePeFile then
    Result := TPsePeLoader.Create(AFile)
  else if AFile is TPseElfFile then
    Result := TPseElfLoader.Create(AFile)
  else
    Result := nil;
end;

class function TPseImgLoader.LoadFile(AFile: TPseFile; AMem: TPseVirtMem): boolean;
var
  ldr: TPseImgLoader;
begin
  ldr := TPseImgLoader.GetInstance(AFile);
  if Assigned(ldr) then begin
    try
      ldr.Load(AMem);
      Result := true;
    finally
      ldr.Free;
    end;
  end else
    Result := false;
end;

constructor TPseImgLoader.Create(AFile: TPseFile);
begin
  inherited Create;
  FFile := AFile;
end;

end.

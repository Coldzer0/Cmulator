{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseFile;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseSection, PseExportTable, PseImportTable, PseDebugInfo,
  PseCmn, PseResource,
{$ifdef FPC}
  fgl
{$else}
  Generics.Collections
{$endif}
  ;


type
  TPseFileClass = class of TPseFile;
  {
    Base class
  }
  TPseFile = class(TPersistent)
  private
  protected
    FStream: TStream;
    FFilename: string;
    FSections: TPseSectionList;
    FExports: TPseExportTable;
    FImports: TPseImportTable;
    FResources: TPseResourceList;
    FDebugInfo: TPseDebugInfo;
    FBitness: TPseBitness;
    FReadDebugInfo: boolean;
    function GetHasDebugInfo: boolean;
    function GetIs64: boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function LoadFromFile(const AFilename: string): boolean; virtual;
    function LoadFromStream(Stream: TStream): boolean; virtual;
    function GetEntryPoint: UInt64; virtual; abstract;
    function GetArch: TPseArch; virtual; abstract;
    function GetMode: TPseMode; virtual; abstract;
    function GetFirstAddr: UInt64; virtual; abstract;
    function GetInitStackSize: UInt64; virtual;
    function GetMaxStackSize: UInt64; virtual;
    function GetInitHeapSize: UInt64; virtual;
    function GetMaxHeapSize: UInt64; virtual;
    procedure SaveSectionToStream(const ASection: integer; Stream: TStream); virtual; abstract;

    function GetFriendlyName: string; virtual;

    property Filename: string read FFilename;
    property Sections: TPseSectionList read FSections;
    property ExportTable: TPseExportTable read FExports;
    property ImportTable: TPseImportTable read FImports;
    property Resources: TPseResourceList read FResources;
    property Stream: TStream read FStream;
    property Is64: boolean read GetIs64;
    property Bitness: TPseBitness read FBitness default psebUnknown;
    property HasDebugInfo: boolean read GetHasDebugInfo;
    property DebugInfo: TPseDebugInfo read FDebugInfo;
    property ReadDebugInfo: boolean read FReadDebugInfo write FReadDebugInfo;

    class procedure RegisterFile(AClass: TPseFileClass; const AIndex: integer = -1);
    class function GetInstance(const AFilename: string; const AWidthDebugInfo: boolean): TPseFile; overload;
    class function GetInstance(Stream: TStream; const AWidthDebugInfo: boolean): TPseFile; overload;
  end;

implementation

uses
  PseRawFile;

type
{$ifdef FPC}
  TPseFilesList = TFPGList<TPseFileClass>;
{$else}
  TPseFilesList = TList<TPseFileClass>;
{$endif}

var
  gPseFiles: TPseFilesList = nil;

class procedure TPseFile.RegisterFile(AClass: TPseFileClass; const AIndex: integer = -1);
begin
  if gPseFiles = nil then
    gPseFiles := TPseFilesList.Create;
  if gPseFiles.IndexOf(AClass) = -1 then begin
    if AIndex = -1 then
      gPseFiles.Add(AClass)
    else
      gPseFiles.Insert(AIndex, AClass);
  end;
end;

class function TPseFile.GetInstance(const AFilename: string; const AWidthDebugInfo: boolean): TPseFile;
var
  i: integer;
  cls: TPseFileClass;
begin
  Result := nil;
  if gPseFiles <> nil then begin
    for i := 0 to gPseFiles.Count - 1 do begin
      cls := gPseFiles[i];
      Result := cls.Create;
      Result.ReadDebugInfo := AWidthDebugInfo;
      if Result.LoadFromFile(AFilename) then
        Exit;
      if Assigned(Result) then
        FreeAndNil(Result);
    end;
    Result := TPseRawFile.Create;
    if Result.LoadFromFile(AFilename) then
      Exit;

    if Assigned(Result) then
      FreeAndNil(Result);
  end;
end;

class function TPseFile.GetInstance(Stream: TStream; const AWidthDebugInfo: boolean): TPseFile;
var
  i: integer;
  cls: TPseFileClass;
begin
  Result := nil;
  if gPseFiles <> nil then begin
    for i := 0 to gPseFiles.Count - 1 do begin
      cls := gPseFiles[i];
      Result := cls.Create;
      Result.ReadDebugInfo := AWidthDebugInfo;
      if Result.LoadFromStream(Stream) then
        Exit;
      if Assigned(Result) then
        FreeAndNil(Result);
    end;
    Result := TPseRawFile.Create;
    if Result.LoadFromStream(Stream) then
      Exit;

    if Assigned(Result) then
      FreeAndNil(Result);
  end;
end;

constructor TPseFile.Create;
begin
  inherited;
  FStream := TMemoryStream.Create;
  FSections := TPseSectionList.Create(Self);
  FExports := TPseExportTable.Create;
  FImports := TPseImportTable.Create(Self);
  FResources := TPseResourceList.Create(Self);
  FDebugInfo := TPseDebugInfo.Create;
  FBitness := psebUnknown;
end;

destructor TPseFile.Destroy;
begin
  FDebugInfo.Free;
  FSections.Free;
  FExports.Free;
  FImports.Free;
  FResources.Free;
  FStream.Free;
  inherited;
end;

function TPseFile.GetIs64: boolean;
begin
  Result := Fbitness = pseb64;
end;

function TPseFile.GetInitStackSize: UInt64;
begin
  Result := 4096;
end;

function TPseFile.GetMaxStackSize: UInt64;
begin
  Result := 1048576;
end;

function TPseFile.GetInitHeapSize: UInt64;
begin
  Result := 4096;
end;

function TPseFile.GetMaxHeapSize: UInt64;
begin
  Result := 1048576;
end;

function TPseFile.GetHasDebugInfo: boolean;
begin
  Result := not FDebugInfo.IsEmpty;
end;

function TPseFile.LoadFromFile(const AFilename: string): boolean;
var
  fs: TFileStream;
begin
  try
    fs := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyNone);
    try
      FFilename := AFilename;
      Result := LoadFromStream(fs);
    finally
      fs.Free;
    end;
  except
    Result := false;
  end;
end;

function TPseFile.LoadFromStream(Stream: TStream): boolean;
begin
  try
    TMemoryStream(FStream).Clear;
    Stream.Position := 0;
    FStream.CopyFrom(Stream, Stream.Size);
    Result := true;
  except
    Result := false;
  end;
end;

function TPseFile.GetFriendlyName: string;
begin
  Result := 'Unknown';
end;

initialization

finalization
	if Assigned(gPseFiles) then
	  gPseFiles.Free;

end.

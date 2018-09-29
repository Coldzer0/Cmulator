{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseImportTable;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes,
  {$ifdef FPC}
    fgl
  {$else}
    Generics.Collections
  {$endif}
  ;

type
  TPseImport = class;
  TPseImportTable = class;

  TPseApi = class
  private
    FName: string;
    FAddress: UInt64;
    FHint: Word;
    FOwner: TPseImport;
  public
    constructor Create(AOwner: TPseImport);
    function GetFullName: string;

    property Name: string read FName write FName;
    property Hint: Word read FHint write FHint;
    property Address: UInt64 read FAddress write FAddress;
  end;

  {$ifdef FPC}
    TApiList = TFPGList<TPseApi>;
    TImportList = TFPGList<TPseImport>;
  {$else}
    TApiList = TList<TPseApi>;
    TImportList = TList<TPseImport>;
  {$endif}

  TPseImport = class(TApiList)
  private
    FDllName: string;
    FIatRva : UInt64;
    FHandle: THandle;
    FDelayLoad: boolean;
    FOwner: TPseImportTable;
  public
    constructor Create(Owner: TPseImportTable);
    destructor Destroy; override;
    procedure Clear;
    function New: TPseApi;
    function Find(const AAddress: UInt64): TPseApi;
    property IatRva: UInt64 read FIatRva write FIatRva;
    property DllName: string read FDllName write FDllName;
    property DelayLoad: boolean read FDelayLoad write FDelayLoad;
  end;

  TPseImportTable = class(TImportList)
  private
    FOwner: TObject;
  public
    constructor Create(Owner: TObject);
    destructor Destroy; override;
    procedure Clear;
    function New: TPseImport;
    function FindApi(const AAddress: UInt64): TPseApi;
  end;

implementation

uses
  PseFile;

constructor TPseApi.Create(AOwner: TPseImport);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TPseApi.GetFullName: string;
begin
  if Assigned(FOwner) and (FOwner.DllName <> '') then
    Result := FOwner.DllName + '!';
  Result := Result + FName;
end;

constructor TPseImport.Create(Owner: TPseImportTable);
begin
  inherited Create;
  FOwner := Owner;
   FHandle := 0;
end;

destructor TPseImport.Destroy;
begin
  Clear;
  inherited;
end;

function TPseImport.New: TPseApi;
begin
  Result := TPseApi.Create(Self);
  Add(Result);
end;

procedure TPseImport.Clear;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  inherited;
end;

function TPseImport.Find(const AAddress: UInt64): TPseApi;
var
  i: integer;
begin
  for i := 0 to Count - 1 do begin
    Result := Items[i];
    if Result.Address = AAddress then
      Exit;
  end;
  Result := nil;
end;

constructor TPseImportTable.Create(Owner: TObject);
begin
  inherited Create;
  FOwner := Owner;
end;

destructor TPseImportTable.Destroy;
begin
  Clear;
  inherited;
end;

procedure TPseImportTable.Clear;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  inherited;
end;

function TPseImportTable.New: TPseImport;
begin
  Result := TPseImport.Create(Self);
  Add(Result);
end;

function TPseImportTable.FindApi(const AAddress: UInt64): TPseApi;
var
  i: integer;
begin
  for i := 0 to Count - 1 do begin
    Result := Items[i].Find(AAddress);
    if Result <> nil then
      Exit;
  end;
  Result := nil;
end;

end.

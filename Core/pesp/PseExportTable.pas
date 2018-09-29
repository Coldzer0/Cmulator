{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseExportTable;

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
  TPseExport = class
  private
    FName: string;
    FOrdinal: integer;
    FAddress: UInt64;
  public
    property Name: string read FName write FName;
    property Ordinal: integer read FOrdinal write FOrdinal;
    property Address: UInt64 read FAddress write FAddress;
  end;

type
{$ifdef FPC}
  TExportList = TFPGList<TPseExport>;
{$else}
  TExportList = TList<TPseExport>;
{$endif}

  TPseExportTable = class(TExportList)
  private
    FNumNames: integer;
    FNumFuncs: integer;
    FBase: UInt64;
    FName: string;
  public
    destructor Destroy; override;
    procedure Clear;
    function New: TPseExport;

    property NumNames: integer read FNumNames write FNumNames;
    property NumFuncs: integer read FNumFuncs write FNumFuncs;
    property Base: UInt64 read FBase write FBase;
    property Name: string read FName write FName;
  end;

implementation

destructor TPseExportTable.Destroy;
begin
  Clear;
  inherited;
end;

procedure TPseExportTable.Clear;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  inherited;
end;

function TPseExportTable.New: TPseExport;
begin
  Result := TPseExport.Create;
  Add(Result);
end;

end.

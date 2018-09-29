{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseResource;

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
  TPseResource = class;

  TPseResourceList = class({$ifdef FPC}TFPGList{$else}TList{$endif}<TPseResource>)
  private
    FOwner: TObject;
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;
    procedure Clear;
    function New: TPseResource;
    function GetById(const AId: Integer): TPseResource;
  end;

  TPseResource = class
  private
    FOwner: TPseResourceList;
    FResId: Integer;
    FResType: Integer;
    // File offset
    FOffset: Cardinal;
    FSize: Cardinal;
  public
    constructor Create(AOwner: TPseResourceList);

    function GetWinType: Word;
    function GetWinTypeString: string;
    procedure SaveToStream(Stream: TStream);

    property ResId: Integer read FResId write FResId;
    property ResType: integer read FResType write FResType;
    property Offset: Cardinal read FOffset write FOffset;
    property Size: Cardinal read FSize write FSize;
  end;

const
  // Predefined Windows Resource Types
  WIN_RT_NONE         = 0;
  WIN_RT_CURSOR       = 1;
  WIN_RT_BITMAP       = 2;
  WIN_RT_ICON         = 3;
  WIN_RT_MEMU         = 4;
  WIN_RT_DIALOG       = 5;
  WIN_RT_STRING       = 6;
  WIN_RT_FONTDIR      = 7;
  WIN_RT_FONT         = 8;
  WIN_RT_ACCELERATOR  = 9;
  WIN_RT_RCDATA       = 10;
  WIN_RT_MESSAGETABLE = 11;
  WIN_RT_GROUP_CURSOR = WIN_RT_CURSOR + 11;
  WIN_RT_GROUP_ICON   = WIN_RT_ICON + 11;
  WIN_RT_VERSION      = 16;
  WIN_RT_DLGINCLUDE   = 17;
  WIN_RT_PLUGPLAY     = 19;
  WIN_RT_VXD          = 20;
  WIN_RT_ANICURSOR    = 21;
  WIN_RT_ANIICON      = 22;
  WIN_RT_HTML         = 23;
  WIN_RT_MANIFEST     = 24;

  WIN_TYPE_STRING: array[WIN_RT_NONE..WIN_RT_MANIFEST] of string = ('No type',
    'RT_CURSOR', 'RT_BITMAP', 'RT_ICON', 'RT_MENU', 'RT_DIALOG', 'RT_STRING',
    'RT_FONTDIR', 'RT_FONT', 'RT_ACCELERATOR', 'RT_RCDATA', 'RT_MESSAGETABLE', 'RT_GROUP_CURSOR', '(13 ?)', 'RT_GROUP_ICON', '(15 ?)',
    'RT_VERSION', 'RT_DLGINCLUDE', '(18 ?)', 'RT_PLUGPLAY', 'RT_VXD', 'RT_ANICURSOR',
    'RT_ANIICON', 'RT_HTML', 'RT_MANIFEST'
  );

implementation

uses
  PseFile, Math;

type
  TPseFileAccess = class(TPseFile);

{ TPseResource }

constructor TPseResource.Create(AOwner: TPseResourceList);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TPseResource.GetWinType: Word;
begin
  Result := FResType and $FFF;
end;

function TPseResource.GetWinTypeString: string;
var
  wt: Word;
begin
  wt := GetWinType;
  if (wt <= WIN_RT_MANIFEST) then
    Result := WIN_TYPE_STRING[wt]
  else
    Result := 'Custom';
end;

procedure TPseResource.SaveToStream(Stream: TStream);
var
  s: TStream;
  o, sz: Int64;
begin
  s := TPseFileAccess(FOwner.FOwner).FStream;
  o := FOffset;
  sz := Min(Int64(FSize), Int64(s.Size - o));
  s.Seek(o, soFromBeginning);
  Stream.CopyFrom(s, sz);
end;

{ TPseResourceList }

procedure TPseResourceList.Clear;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  inherited;
end;

constructor TPseResourceList.Create(AOwner: TObject);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TPseResourceList.Destroy;
begin
  Clear;
  inherited;
end;

function TPseResourceList.GetById(const AId: Integer): TPseResource;
var
  i: integer;
begin
  for i := 0 to Count - 1 do begin
    if Items[i].FResId = AId then begin
      Result := Items[i];
      Exit;
    end;
  end;
  Result := nil;
end;

function TPseResourceList.New: TPseResource;
begin
  Result := TPseResource.Create(Self);
  Add(Result);
end;

end.

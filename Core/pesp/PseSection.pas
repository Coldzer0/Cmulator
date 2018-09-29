{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseSection;

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
  TPseSection = class;

  TPseSectionList = class({$ifdef FPC}TFPGList{$else}TList{$endif}<TPseSection>)
  private
    FOwner: TObject;
  public
    constructor Create(AOwner: TObject);
    destructor Destroy; override;
    procedure Clear;
    function New: TPseSection;
  end;

  TSectionAttrib = (saCode, saExecuteable, saReadable, saWriteable, saData, saInitializedData,
    saStringTable, saSymbolTable, saNull);
  TSectionAttribs = set of TSectionAttrib;
  TPseSection = class
  private
    FOwner: TPseSectionList;
    FAddress: UInt64;
    FPointerToRawData: UInt64;
    FSize: UInt64;
    FName: string;
    FOrigAttribs: Cardinal;
    FAttribs: TSectionAttribs;
    FIndex: integer;
    FFileOffset: Int64;
    FNameIndex: Cardinal;
    FElfType: Cardinal;
  public
    constructor Create(AOwner: TPseSectionList);
    procedure SaveToFile(const AFilename: string);
    procedure SaveToStream(Stream: TStream);

    property Address: UInt64 read FAddress write FAddress;
    property PointerToRawData: UInt64 read FPointerToRawData write FPointerToRawData;
    property Size: UInt64 read FSize write FSize;
    property Name: string read FName write FName;
    // Original Flags, Characteristics in ELF, PE file
    property OrigAttribs: Cardinal read FOrigAttribs write FOrigAttribs;
    property Attribs: TSectionAttribs read FAttribs write FAttribs;
    property FileOffset: Int64 read FFileOffset write FFileOffset;
    property NameIndex: Cardinal read FNameIndex write FNameIndex;
    property ElfType: Cardinal read FElfType write FElfType;
    property Index: integer read FIndex;
  end;

implementation

uses
  PseFile;

procedure TPseSectionList.Clear;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  inherited;
end;

constructor TPseSectionList.Create(AOwner: TObject);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TPseSectionList.Destroy;
begin
  Clear;
  inherited;
end;

function TPseSectionList.New: TPseSection;
begin
  Result := TPseSection.Create(Self);
  Result.FIndex := Add(Result);
end;

constructor TPseSection.Create(AOwner: TPseSectionList);
begin
  inherited Create;
  FOwner := AOwner;
  FFileOffset := -1;
end;

procedure TPseSection.SaveToFile(const AFilename: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(AFilename, fmCreate);
  try
    SaveToStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TPseSection.SaveToStream(Stream: TStream);
begin
  if (FOwner.FOwner is TPseFile) then begin
    (FOwner.FOwner as TPseFile).SaveSectionToStream(FIndex, Stream);
  end;
end;

end.

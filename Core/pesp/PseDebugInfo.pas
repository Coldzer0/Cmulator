{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseDebugInfo;

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
  TDebugInfoItem = record
    Segment: Word;
    Offset: UInt64;
    FileName: string;
    LineNum: UInt64;
    Name: string;
  end;
  PDebugInfoItem = ^TDebugInfoItem;

  TDebugInfoDict = {$ifdef FPC}TFPGMap{$else}TDictionary{$endif}<UInt64, TDebugInfoItem>;
  TSegments =  {$ifdef FPC}TFPGMap{$else}TDictionary{$endif}<Word, TDebugInfoDict>;

  TPseDebugInfo = class
  private
    FSegments: TSegments;
    function GetSegmentDict(const ASeg: Word): TDebugInfoDict;
    function GetIsEmpty: boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(ADi: TDebugInfoItem);

    property IsEmpty: Boolean read GetIsEmpty;
    property SegmentDi[const ASeg: Word]: TDebugInfoDict read GetSegmentDict;
  end;

implementation

constructor TPseDebugInfo.Create;
begin
  inherited Create;
  FSegments := TSegments.Create;
end;

destructor TPseDebugInfo.Destroy;
begin
  FSegments.Clear;
  FSegments.Free;
  inherited;
end;

function TPseDebugInfo.GetSegmentDict(const ASeg: Word): TDebugInfoDict;
{$ifdef FPC}
var
  index: integer;
{$endif}
begin
{$ifdef FPC}
  if (FSegments.Find(ASeg, index)) then begin
    Result := FSegments.Data[index];
    Exit;
  end;
{$else}
  if FSegments.ContainsKey(ASeg) then begin
    if FSegments.TryGetValue(ASeg, Result) then
      Exit;
  end;
{$endif}
  Result := TDebugInfoDict.Create;
  FSegments.Add(ASeg, Result);
end;

function TPseDebugInfo.GetIsEmpty: boolean;
begin
  Result := FSegments.Count = 0;
end;

procedure TPseDebugInfo.Add(ADi: TDebugInfoItem);
var
  dict: TDebugInfoDict;
{$ifdef FPC}
  index: integer;
{$endif}
begin
  dict := GetSegmentDict(ADi.Segment);
{$ifdef FPC}
  if (not FSegments.Find(ADi.Offset, index)) then begin
    dict.Add(ADi.Offset, ADi);
  end;
{$else}
  if not dict.ContainsKey(ADi.Offset) then
    dict.Add(ADi.Offset, ADi);
{$endif}
end;

end.

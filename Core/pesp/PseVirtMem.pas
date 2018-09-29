unit PseVirtMem;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  SysUtils, Classes;

type
  TPseMemFlag = (pmfExecute, pmfRead, pmfWrite);
  TPseMemFlags = set of TPseMemFlag;

  TPseVirtMem = class;

  TPseMemSegment = class
  private
    FOwner: TPseVirtMem;
    FBase, FSize: UInt64;
    FFlags: TPseMemFlags;
    FStartEA, FEndEA: UInt64;
    FName: string;
  public
    constructor Create(AOwner: TPseVirtMem; const AName: string; const ABase, ASize: UInt64;
      AFlags: TPseMemFlags); virtual;
    destructor Destroy; override;

    function Read(const AAddr: UInt64; var Buffer; Count: Longint): Longint; dynamic;
    function Write(const AAddr: UInt64; const Buffer; Count: Longint): Longint; dynamic;

    procedure SaveToStream(Stream: TStream);

    property Name: string read FName;
    property Base: UInt64 read FBase;
    property Size: UInt64 read FSize;
    property Flags: TPseMemFlags read FFlags write FFlags;
  end;

  TPseVirtMem = class
  private
    FSegments: TList;
    FMemBase: UInt64;
    FBuffer: TMemoryStream;
    FInitSize: UInt64;
    FMaxSize: UInt64;
    FSorted: boolean;
    function GetSegment(const AAddr: UInt64): TPseMemSegment;
    function GetSegmentByIndex(const Index: integer): TPseMemSegment;
    function GetCount: integer;
    function GetSize: Int64;
    function GetStream: TStream;
    procedure Sort;
  public
    constructor Create(const AMemBase: UInt64; const AInitSize, AMaxSize: UInt64);
    destructor Destroy; override;
    function CreateSegment(const AName: string; const ABase, ASize: UInt64;
      const AFlags: TPseMemFlags): TPseMemSegment;
    procedure Clear;

    function Read(const AAddr: UInt64; var Buffer; Count: Longint): Longint;
    function Write(const AAddr: UInt64; const Buffer; Count: Longint): Longint;

    { Get Segment by Address }
    property Segments[const AAddr: UInt64]: TPseMemSegment read GetSegment;
    { Get segment by index }
    property Items[const Index: integer]: TPseMemSegment read GetSegmentByIndex; default;
    property Count: integer read GetCount;
    property Size: Int64 read GetSize;
    property MemBase: UInt64 read FMemBase;
    property Stream: TStream read GetStream;
  end;

implementation

uses
  Math;

{ TPseMemSegment }

constructor TPseMemSegment.Create(AOwner: TPseVirtMem; const AName: string; const ABase, ASize: UInt64;
  AFlags: TPseMemFlags);
begin
  inherited Create;
  FOwner := AOwner;
  FName := AName;
  FBase := ABase;
  FSize := ASize;
  FFlags := AFlags;
  FStartEA := ABase;
  FEndEA := ABase + ASize;
end;

destructor TPseMemSegment.Destroy;
begin
  inherited;
end;

procedure TPseMemSegment.SaveToStream(Stream: TStream);
var
  o, s: Int64;
begin
  o := FBase;
  FOwner.Stream.Seek(o, soFromBeginning);
  s := Min(Int64(FSize), Int64(FOwner.Stream.Size - o));
  Stream.CopyFrom(FOwner.Stream, s);
end;

function TPseMemSegment.Read(const AAddr: UInt64; var Buffer; Count: Longint): Longint;
var
  index: integer;
begin
  if not (pmfRead in FFlags) then
    raise Exception.Create('Segment is not readable');
  if AAddr < FBase then
    raise Exception.CreateFmt('Access violation read at 0x%.16x', [AAddr]);
  if AAddr + Count > FBase + FSize then
    raise Exception.CreateFmt('Access violation read at 0x%.16x', [AAddr]);
  index := AAddr - (FOwner.FMemBase);
  if (index < 0) then
    raise Exception.CreateFmt('Access violation read at 0x%.16x', [AAddr]);
  FOwner.FBuffer.Position := index;
  Result := FOwner.FBuffer.Read(Buffer, Count);
end;

function TPseMemSegment.Write(const AAddr: UInt64; const Buffer; Count: Longint): Longint;
var
  pos: integer;
begin
  if not (pmfWrite in FFlags) then
    raise Exception.Create('Segment is not writeable');
  pos := AAddr + (FBase - FOwner.FMemBase);
  if (pos < 0) or (Count > FSize) then
    raise Exception.CreateFmt('Access violation write at 0x%.16x', [AAddr]);
  FOwner.FBuffer.Position := pos;
  Result := FOwner.FBuffer.Write(Buffer, Count);
end;

{ TPseVirtMem }

constructor TPseVirtMem.Create(const AMemBase: UInt64; const AInitSize, AMaxSize: UInt64);
begin
  inherited Create;
  FSegments := Classes.TList.Create;
  FMemBase := AMemBase;
  FInitSize := AInitSize;
  FMaxSize := AMaxSize;
  FBuffer := TMemoryStream.Create;
  FBuffer.SetSize(FInitSize);
  FSorted := false;
end;

destructor TPseVirtMem.Destroy;
begin
  Clear;
  FSegments.Free;
  FBuffer.Free;
  inherited;
end;

procedure TPseVirtMem.Clear;
var
  i: integer;
  seg: TPseMemSegment;
begin
  for i := 0 to FSegments.Count - 1 do begin
    seg := TPseMemSegment(FSegments[i]);
    seg.Free;
  end;
  FSegments.Clear;
end;

function TPseVirtMem.GetSegment(const AAddr: UInt64): TPseMemSegment;
var
  i: integer;
  seg: TPseMemSegment;
begin
  for i := 0 to FSegments.Count - 1 do begin
    seg := TPseMemSegment(FSegments[i]);
    if (seg.FStartEA >= AAddr) and (seg.FEndEA < AAddr) then begin
      Result := seg;
      Exit;
    end;
  end;
  Result := nil;
end;

function TPseVirtMem.CreateSegment(const AName: string; const ABase, ASize: UInt64;
  const AFlags: TPseMemFlags): TPseMemSegment;
begin
  if GetSegment(ABase) <> nil then begin
    raise Exception.CreateFmt('Segment at 0x%.16x already mapped', [ABase]);
  end;
  Result := TPseMemSegment.Create(Self, AName, FMemBase + ABase, ASize, AFlags);
  FSegments.Add(Result);
  FSorted := false;
end;

function TPseVirtMem.Read(const AAddr: UInt64; var Buffer; Count: Longint): Longint;
var
  seg: TPseMemSegment;
begin
  seg := GetSegment(AAddr);
  if seg = nil then
    raise Exception.CreateFmt('No segment at 0x%.16x', [AAddr]);
  Result := seg.Read(AAddr, Buffer, Count);
end;

function TPseVirtMem.Write(const AAddr: UInt64; const Buffer; Count: Longint): Longint;
var
  seg: TPseMemSegment;
begin
  seg := GetSegment(AAddr);
  if seg = nil then
    raise Exception.CreateFmt('No segment at 0x%.16x', [AAddr]);
  Result := seg.Write(AAddr, Buffer, Count);
end;

function TPseVirtMem.GetCount: integer;
begin
  Result := FSegments.Count;
end;

function TPseVirtMem.GetSegmentByIndex(const Index: integer): TPseMemSegment;
begin
  if not FSorted then
    Sort;
  if (Index >= 0) and (Index < Count) then
    Result := TPseMemSegment(FSegments[Index])
  else
    Result := nil;
end;

{ Sort segments by address }
function Segments_SortProc(i1, i2: Pointer): Integer;
begin
  if TPseMemSegment(i1).Base > TPseMemSegment(i2).Base then
    Result := 1
  else if TPseMemSegment(i1).Base < TPseMemSegment(i2).Base then
    Result := -1
  else
    Result := 0;
end;

procedure TPseVirtMem.Sort;
begin
  FSegments.Sort(Segments_SortProc);
  FSorted := true;
end;

function TPseVirtMem.GetSize: Int64;
begin
  Result := FBuffer.Size;
end;

function TPseVirtMem.GetStream: TStream;
begin
  Result := FBuffer;
end;

end.

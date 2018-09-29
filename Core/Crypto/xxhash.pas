{****************************************************
  This file is FreePascal & Delphi port of xxHash
  from origignal port by Vojtěch Čihák which was
  FPC compatible only.

  by Jose Sebastian Battig

  Original copyright:
  Copyright (C) 2014 Vojtěch Čihák, Czech Republic

  http://sourceforge.net/projects/xxhashfpc/files/

  This library is free software. See the files
  COPYING.modifiedLGPL.txt and COPYING.LGPL.txt,
  included in this distribution,
  for details about the license.
****************************************************}

unit xxHash;
{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

interface

{$IFNDEF FPC}
type
  PQWord = ^QWord;
  QWord = UInt64;
{$IFDEF VER180}
  NativeInt = Integer;
  NativeUInt = Cardinal;
{$ENDIF}
{$ENDIF}

const
  cPrime32x1: LongWord = 2654435761;
	cPrime32x2: LongWord = 2246822519;
	cPrime32x3: LongWord = 3266489917;
	cPrime32x4: LongWord = 668265263;
	cPrime32x5: LongWord = 374761393;

  cPrime64x1: QWord = 11400714785074694791;
  cPrime64x2: QWord = 14029467366897019727;
  cPrime64x3: QWord = 1609587929392839161;
  cPrime64x4: QWord = 9650029242287828579;
  cPrime64x5: QWord = 2870177450012600261;

type
  { TxxHash32 }
  TxxHash32 = class
  private
    FBuffer: Pointer;
    FMemSize: Cardinal;
    FSeed: LongWord;
    FTotalLength: QWord;
    FV1, FV2, FV3, FV4: LongWord;
  public
    constructor Create(ASeed: LongWord = 0);
    destructor Destroy; override;
    function Digest: LongWord;
    procedure Reset;
    function Update(ABuffer: Pointer; ALength: Cardinal): Boolean;
    property Seed: LongWord read FSeed write FSeed;
  end;

  { TxxHash64 }
  TxxHash64 = class
  private
    FBuffer: Pointer;
    FMemSize: Cardinal;
    FSeed: QWord;
    FTotalLength: QWord;
    FV1, FV2, FV3, FV4: QWord;
  public
    constructor Create(ASeed: QWord = 0);
    destructor Destroy; override;
    function Digest: QWord;
    procedure Reset;
    function Update(ABuffer: Pointer; ALength: LongWord): Boolean;
    property Seed: QWord read FSeed write FSeed;
  end;

  function xxHash32Calc(ABuffer: Pointer; ALength: LongInt; ASeed: LongWord = 0): LongWord; overload;
  function xxHash32Calc(const ABuffer: array of Byte; ASeed: LongWord = 0): LongWord; overload;
  function xxHash32Calc(const AString: string; ASeed: LongWord = 0): LongWord; overload;

  function xxHash64Calc(ABuffer: Pointer; ALength: Cardinal; ASeed: QWord = 0):
      QWord; overload;
  function xxHash64Calc(const ABuffer: array of Byte; ASeed: QWord = 0): QWord; overload;
  function xxHash64Calc(const AString: string; ASeed: QWord = 0): QWord; overload;

implementation

{$IFNDEF FPC}
{$IFOPT Q+}{$DEFINE OVERFLOWCHECKSON}{$ENDIF}
{$Q-}
function RoLWord(Value: Word; N: Integer): Word; inline;
begin
  Result:= ((Value shl N) and $ffff) or (Value shr (16-N));
end;

function RoRWord(Value: Word; N: Integer): Word; inline;
begin
  Result:= (Value shr N) or ((Value shl (16-N)) and $ffff);
end;

function RolDWord(Value: Cardinal; N: Integer): Cardinal; inline;
begin
  Result:= (Value shl N) or (Value shr (32-N));
end;

function RoRDWord(Value: Cardinal; N: Integer): Cardinal; inline;
begin
  Result:= (Value shr N) or (Value shl (32-N));
end;

(* The following two functions will blow up if inlined in Delphi 2007 *)
function RoLQWord(Value: Int64; N: Integer): Int64; {$IFNDEF VER180} inline; {$ENDIF}
begin
  Result:= (Value shl N) or (Value shr (64-N));
end;

function RoRQWord(Value: Int64; N: Integer): Int64; {$IFNDEF VER180} inline; {$ENDIF}
begin
  Result:= (Value shr N) or (Value shl (64-N));
end;
{$IFDEF OVERFLOWCHECKSON}{$Q+}{$ENDIF}
{$ENDIF}

function xxHash32Calc(ABuffer: Pointer; ALength: LongInt; ASeed: LongWord = 0): LongWord;
var v1, v2, v3, v4: LongWord;
    pLimit, pEnd: Pointer;
begin
  pEnd := {%H-}Pointer({%H-}NativeInt(ABuffer) + ALength);
  if ALength >= 16 then
    begin
      pLimit := {%H-}Pointer({%H-}NativeInt(pEnd) - 16);
      v1 := ASeed + cPrime32x1 + cPrime32x2;
      v2 := ASeed + cPrime32x2;
      v3 := ASeed;
      v4 := ASeed - cPrime32x1;

      repeat
        v1 := cPrime32x1 * RolDWord(v1 + cPrime32x2 * PLongWord(ABuffer)^, 13);
        v2 := cPrime32x1 * RolDWord(v2 + cPrime32x2 * {%H-}PLongWord({%H-}NativeUInt(ABuffer)+4)^, 13);
        v3 := cPrime32x1 * RolDWord(v3 + cPrime32x2 * {%H-}PLongWord({%H-}NativeUInt(ABuffer)+8)^, 13);
        v4 := cPrime32x1 * RolDWord(v4 + cPrime32x2 * {%H-}PLongWord({%H-}NativeUInt(ABuffer)+12)^, 13);
        inc({%H-}NativeUInt(ABuffer), 16);
      until not ({%H-}NativeUInt(ABuffer) <= {%H-}NativeUInt(pLimit));

      Result := RolDWord(v1, 1) + RolDWord(v2, 7) + RolDWord(v3, 12) + RolDWord(v4, 18);
    end else
    Result := ASeed + cPrime32x5;

  inc(Result, ALength);

  while {%H-}NativeUInt(ABuffer) <= ({%H-}NativeUInt(pEnd) - 4) do
    begin
      Result := Result + PLongWord(ABuffer)^ * cPrime32x3;
      Result := RolDWord(Result, 17) * cPrime32x4;
      inc({%H-}NativeUInt(ABuffer), 4);
    end;

  while {%H-}NativeUInt(ABuffer) < {%H-}NativeUInt(pEnd) do
    begin
      Result := Result + PByte(ABuffer)^ * cPrime32x5;
      Result := RolDWord(Result, 11) * cPrime32x1;
      inc({%H-}NativeUInt(ABuffer));
    end;

  Result := Result xor (Result shr 15);
  Result := Result * cPrime32x2;
  Result := Result xor (Result shr 13);
  Result := Result * cPrime32x3;
  Result := Result xor (Result shr 16);
end;

function xxHash32Calc(const ABuffer: array of Byte; ASeed: LongWord): LongWord;
begin
  Result := xxHash32Calc(@ABuffer[0], length(ABuffer), ASeed);
end;

function xxHash32Calc(const AString: string; ASeed: LongWord): LongWord;
begin
  Result := xxHash32Calc({$IFNDEF FPC}TEncoding.UTF8.GetBytes{$ELSE} PChar {$ENDIF}(AString), length(AString), ASeed);
end;

function xxHash64Calc(ABuffer: Pointer; ALength: Cardinal; ASeed: QWord = 0):
    QWord;
var v1, v2, v3, v4: QWord;
    pLimit, pEnd: Pointer;
begin
  pEnd := {%H-}Pointer({%H-}NativeUInt(ABuffer) + ALength);

  if ALength >= 32 then
    begin
      v1 := ASeed + cPrime64x1 + cPrime64x2;
      v2 := ASeed + cPrime64x2;
      v3 := ASeed;
      v4 := ASeed - cPrime64x1;

      pLimit := {%H-}Pointer({%H-}NativeUInt(pEnd) - 32);
      repeat
        v1 := cPrime64x1 * RolQWord(v1 + cPrime64x2 * PQWord(ABuffer)^, 31);
        v2 := cPrime64x1 * RolQWord(v2 + cPrime64x2 * {%H-}PQWord({%H-}NativeUInt(ABuffer)+8)^, 31);
        v3 := cPrime64x1 * RolQWord(v3 + cPrime64x2 * {%H-}PQWord({%H-}NativeUInt(ABuffer)+16)^, 31);
        v4 := cPrime64x1 * RolQWord(v4 + cPrime64x2 * {%H-}PQWord({%H-}NativeUInt(ABuffer)+24)^, 31);
        inc({%H-}NativeUInt(ABuffer), 32);
      until not ({%H-}NativeUInt(ABuffer) <= {%H-}NativeUInt(pLimit));

      Result := RolQWord(v1, 1) + RolQWord(v2, 7) + RolQWord(v3, 12) + RolQWord(v4, 18);

      v1 := RolQWord(v1 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v1) * cPrime64x1 + cPrime64x4;

      v2 := RolQWord(v2 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v2) * cPrime64x1 + cPrime64x4;

      v3 := RolQWord(v3 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v3) * cPrime64x1 + cPrime64x4;

      v4 := RolQWord(v4 * cPrime64x2, 31) * cPrime64x1;
      Result := (Result xor v4) * cPrime64x1 + cPrime64x4;
    end else
    Result := ASeed + cPrime64x5;

  inc(Result, ALength);

  while {%H-}NativeUInt(ABuffer) <= ({%H-}NativeUInt(pEnd) - 8) do
    begin
      Result := Result xor (cPrime64x1 * RolQWord(cPrime64x2 * PQWord(ABuffer)^, 31));
    	Result := RolQWord(Result, 27) * cPrime64x1 + cPrime64x4;
    	inc({%H-}NativeUInt(ABuffer), 8);
    end;

  if {%H-}NativeUInt(ABuffer) <= ({%H-}NativeUInt(pEnd) - 4) then
    begin
    	Result := (Result xor PLongWord(ABuffer)^) * cPrime64x1;
      Result := RolQWord(Result, 23) * cPrime64x2 + cPrime64x3;
      inc({%H-}NativeUInt(ABuffer), 4);
    end;

  while {%H-}NativeUInt(ABuffer) < {%H-}NativeUInt(pEnd) do
    begin
      Result := Result xor (PByte(ABuffer)^ * cPrime64x5);
      Result := RolQWord(Result, 11) * cPrime64x1;
      inc({%H-}NativeUInt(ABuffer));
    end;

  Result := Result xor (Result shr 33);
  Result := Result * cPrime64x2;
  Result := Result xor (Result shr 29);
  Result := Result * cPrime64x3;
  Result := Result xor (Result shr 32);
end;

function xxHash64Calc(const ABuffer: array of Byte; ASeed: QWord): QWord;
begin
  Result := xxHash64Calc(@ABuffer[0], length(ABuffer), ASeed);
end;

function xxHash64Calc(const AString: string; ASeed: QWord): QWord;
begin
  Result := xxHash64Calc({$IFNDEF FPC}TEncoding.UTF8.GetBytes{$ELSE} PChar {$ENDIF}(AString), length(AString), ASeed);
end;

{ TxxHash32 }

constructor TxxHash32.Create(ASeed: LongWord);
begin
  FSeed := ASeed;
  Reset;
  GetMem(FBuffer, 16);
end;

destructor TxxHash32.Destroy;
begin
  Freemem(FBuffer, 16);
  inherited Destroy;
end;

function TxxHash32.Digest: LongWord;
var pBuffer, pEnd: Pointer;
begin
  if FTotalLength >= 16
    then Result := RolDWord(FV1, 1) + RolDWord(FV2, 7) + RolDWord(FV3, 12) + RolDWord(FV4, 18)
    else Result := Seed + cPrime32x5;
  inc(Result, FTotalLength);

  pBuffer := FBuffer;
  pEnd := {%H-}Pointer({%H-}NativeUInt(pBuffer) + FMemSize);
  while {%H-}NativeUInt(pBuffer) <= ({%H-}NativeUInt(pEnd) - 4) do
    begin
      Result := Result + PLongWord(pBuffer)^ * cPrime32x3;
      Result := RolDWord(Result, 17) * cPrime32x4;
      inc({%H-}NativeUInt(pBuffer), 4);
    end;

  while {%H-}NativeUInt(pBuffer) < {%H-}NativeUInt(pEnd) do
    begin
      Result := Result + PByte(pBuffer)^ * cPrime32x5;
      Result := RolDWord(Result, 11) * cPrime32x1;
      inc({%H-}NativeUInt(pBuffer));
    end;

  Result := Result xor (Result shr 15);
  Result := Result * cPrime32x2;
  Result := Result xor (Result shr 13);
  Result := Result * cPrime32x3;
  Result := Result xor (Result shr 16);
end;

procedure TxxHash32.Reset;
begin
  FV1 := Seed + cPrime32x1 + cPrime32x2;
  FV2 := Seed + cPrime32x2;
  FV3 := Seed + 0;
  FV4 := Seed - cPrime32x1;
  FTotalLength := 0;
  FMemSize := 0;
end;

function TxxHash32.Update(ABuffer: Pointer; ALength: Cardinal): Boolean;
var v1, v2, v3, v4: LongWord;
    pHelp, pEnd, pLimit: Pointer;
begin
  FTotalLength := FTotalLength + ALength;

  if (FMemSize + ALength) < 16 then  { not enough data, store them to the next Update }
    begin
      pHelp := {%H-}Pointer({%H-}NativeUInt(FBuffer) + FMemSize);
      Move(ABuffer^, pHelp^, ALength);
      FMemSize := FMemSize + ALength;
      Result := True;
      Exit;  { Exit! }
    end;

  pEnd := {%H-}Pointer({%H-}NativeUInt(ABuffer) + ALength);

  if FMemSize > 0 then  { some data left from the previous Update }
    begin
      pHelp := {%H-}Pointer({%H-}NativeUInt(FBuffer) + FMemSize);
      Move(ABuffer^, pHelp^, 16 - FMemSize);

      FV1 := cPrime32x1 * RolDWord(FV1 + cPrime32x2 * PLongWord(FBuffer)^, 13);
      FV2 := cPrime32x1 * RolDWord(FV2 + cPrime32x2 * {%H-}PLongWord({%H-}NativeUInt(FBuffer) + 4)^, 13);
      FV3 := cPrime32x1 * RolDWord(FV3 + cPrime32x2 * {%H-}PLongWord({%H-}NativeUInt(FBuffer) + 8)^, 13);
      FV4 := cPrime32x1 * RolDWord(FV4 + cPrime32x2 * {%H-}PLongWord({%H-}NativeUInt(FBuffer) + 12)^, 13);

      ABuffer := {%H-}Pointer({%H-}NativeUInt(ABuffer) + (16 - FMemSize));
      FMemSize := 0;
    end;

  if {%H-}NativeUInt(ABuffer) <= ({%H-}NativeUInt(pEnd) - 16) then
    begin
      v1 := FV1;
      v2 := FV2;
      v3 := FV3;
      v4 := FV4;

      pLimit := {%H-}Pointer({%H-}NativeUInt(pEnd) - 16);
      repeat
        v1 := cPrime32x1 * RolDWord(v1 + cPrime32x2 * PLongWord(ABuffer)^, 13);
        v2 := cPrime32x1 * RolDWord(v2 + cPrime32x2 * {%H-}PLongWord({%H-}NativeUInt(ABuffer)+4)^, 13);
        v3 := cPrime32x1 * RolDWord(v3 + cPrime32x2 * {%H-}PLongWord({%H-}NativeUInt(ABuffer)+8)^, 13);
        v4 := cPrime32x1 * RolDWord(v4 + cPrime32x2 * {%H-}PLongWord({%H-}NativeUInt(ABuffer)+12)^, 13);
        inc({%H-}NativeUInt(ABuffer), 16);
      until not ({%H-}NativeUInt(ABuffer) <= {%H-}NativeUInt(pLimit));

      FV1 := v1;
      FV2 := v2;
      FV3 := v3;
      FV4 := v4;
    end;

  if {%H-}NativeUInt(ABuffer) < {%H-}NativeUInt(pEnd) then  { store remaining data to the next Update or to Digest }
    begin
      pHelp := FBuffer;
      Move(ABuffer^, pHelp^, {%H-}NativeUInt(pEnd) - {%H-}NativeUInt(ABuffer));
      FMemSize := {%H-}NativeUInt(pEnd) - {%H-}NativeUInt(ABuffer);
    end;

  Result := True;
end;

{ TxxHash64 }

constructor TxxHash64.Create(ASeed: QWord);
begin
  FSeed := ASeed;
  Reset;
  GetMem(FBuffer, 32);
end;

destructor TxxHash64.Destroy;
begin
  Freemem(FBuffer, 32);
  inherited Destroy;
end;

function TxxHash64.Digest: QWord;
var v1, v2, v3, v4: QWord;
    pBuffer, pEnd: Pointer;
begin
  if FTotalLength >= 32 then
    begin
      v1 := FV1;
      v2 := FV2;
      v3 := FV3;
      v4 := FV4;

      Result := RolQWord(v1, 1) + RolQWord(v2, 7) + RolQWord(v3, 12) + RolQWord(v4, 18);

      v1 := RolQWord(v1 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v1) * cPrime64x1 + cPrime64x4;

      v2 := RolQWord(v2 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v2) * cPrime64x1 + cPrime64x4;

      v3 := RolQWord(v3 * cPrime64x2, 31) * cPrime64x1;
    	Result := (Result xor v3) * cPrime64x1 + cPrime64x4;

      v4 := RolQWord(v4 * cPrime64x2, 31) * cPrime64x1;
      Result := (Result xor v4) * cPrime64x1 + cPrime64x4;
    end else
    Result := Seed + cPrime64x5;

  Result := Result + FTotalLength;

  pBuffer := FBuffer;
  pEnd := {%H-}Pointer({%H-}NativeUInt(pBuffer) + FMemSize);
  while {%H-}NativeUInt(pBuffer) <= ({%H-}NativeUInt(pEnd) - 8) do
    begin
      Result := Result xor (cPrime64x1 * RolQWord(cPrime64x2 * PQWord(pBuffer)^, 31));
    	Result := RolQWord(Result, 27) * cPrime64x1 + cPrime64x4;
    	inc({%H-}NativeUInt(pBuffer), 8);
    end;

  if {%H-}NativeUInt(pBuffer) <= ({%H-}NativeUInt(pEnd) - 4) then
    begin
      Result := (Result xor PLongWord(pBuffer)^) * cPrime64x1;
      Result := RolQWord(Result, 23) * cPrime64x2 + cPrime64x3;
      inc({%H-}NativeUInt(pBuffer), 4);
    end;

  while {%H-}NativeUInt(pBuffer) < {%H-}NativeUInt(pEnd) do
    begin
      Result := (Result xor PByte(pBuffer)^) * cPrime64x5;
      Result := RolQWord(Result, 11) * cPrime64x1;
      inc({%H-}NativeUInt(pBuffer));
    end;

  Result := Result xor (Result shr 33);
  Result := Result * cPrime64x2;
  Result := Result xor (Result shr 29);
  Result := Result * cPrime64x3;
  Result := Result xor (Result shr 32);
end;

procedure TxxHash64.Reset;
begin
  FV1 := Seed + cPrime64x1 + cPrime64x2;
  FV2 := Seed + cPrime64x2;
  FV3 := Seed + 0;
  FV4 := Seed - cPrime64x1;
  FTotalLength := 0;
  FMemSize := 0;
end;

function TxxHash64.Update(ABuffer: Pointer; ALength: LongWord): Boolean;
var v1, v2, v3, v4: QWord;
    pHelp, pEnd, pLimit: Pointer;
begin
  FTotalLength := FTotalLength + ALength;
  if (FMemSize + ALength) < 32 then  { not enough data, store them to the next Update }
    begin
      pHelp := {%H-}Pointer({%H-}NativeUInt(FBuffer) + FMemSize);
      Move(ABuffer^, pHelp^, ALength);
      FMemSize := FMemSize + ALength;
      Result := True;
      Exit;  { Exit! }
    end;

  pEnd := {%H-}Pointer({%H-}NativeUInt(ABuffer) + ALength);

  if FMemSize > 0 then  { some data left from the previous Update }
    begin
      pHelp := {%H-}Pointer({%H-}NativeUInt(FBuffer) + FMemSize);
      Move(FBuffer^, pHelp^, 32 - FMemSize);

      FV1 := cPrime64x1 * RolQWord(FV1 + cPrime64x2 * PQWord(FBuffer)^, 31);
      FV2 := cPrime64x1 * RolQWord(FV2 + cPrime64x2 * {%H-}PQWord({%H-}NativeUInt(FBuffer)+8)^, 31);
      FV3 := cPrime64x1 * RolQWord(FV3 + cPrime64x2 * {%H-}PQWord({%H-}NativeUInt(FBuffer)+16)^, 31);
      FV4 := cPrime64x1 * RolQWord(FV4 + cPrime64x2 * {%H-}PQWord({%H-}NativeUInt(FBuffer)+24)^, 31);

      ABuffer := {%H-}Pointer({%H-}NativeUInt(ABuffer) + (32 - FMemSize));
      FMemSize := 0;
    end;

  if {%H-}NativeUInt(ABuffer) <= ({%H-}NativeUInt(pEnd) - 32) then
    begin
      v1 := FV1;
      v2 := FV2;
      v3 := FV3;
      v4 := FV4;

      pLimit := {%H-}Pointer({%H-}NativeUInt(pEnd) - 32);
      repeat
        v1 := cPrime64x1 * RolQWord(v1 + cPrime64x2 * PQWord(ABuffer)^, 31);
        v2 := cPrime64x1 * RolQWord(v2 + cPrime64x2 * {%H-}PQWord({%H-}NativeUInt(ABuffer)+8)^, 31);
        v3 := cPrime64x1 * RolQWord(v3 + cPrime64x2 * {%H-}PQWord({%H-}NativeUInt(ABuffer)+16)^, 31);
        v4 := cPrime64x1 * RolQWord(v4 + cPrime64x2 * {%H-}PQWord({%H-}NativeUInt(ABuffer)+24)^, 31);
        inc({%H-}NativeUInt(ABuffer), 32);
      until not ({%H-}NativeUInt(ABuffer) <= {%H-}NativeUInt(pLimit));

      FV1 := v1;
      FV2 := v2;
      FV3 := v3;
      FV4 := v4;
    end;

  if {%H-}NativeUInt(ABuffer) < {%H-}NativeUInt(pEnd) then  { store remaining data to the next Update or to Digest }
    begin
      pHelp := FBuffer;
      Move(ABuffer^, pHelp^, {%H-}NativeUInt(pEnd) - {%H-}NativeUInt(ABuffer));
      FMemSize := {%H-}NativeUInt(pEnd) - {%H-}NativeUInt(ABuffer);
    end;

  Result := True;
end;

end.


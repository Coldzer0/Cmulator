{
  Pascal language binding for the Capstone engine <http://www.capstone-engine.org/>

  Copyright (C) 2014, Stefan Ascher
}

unit Capstone;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$SMARTLINK ON}
{$PackRecords C}

interface

uses
  SysUtils, Classes, CapstoneApi, CapstoneCmn;

type
  TCsInsn = record
    id: Cardinal;
    address: Int64;
    size: Word;
    bytes: array[0..15] of Byte;
    mnemonic: string;
    op_str: string;
  end;

  TCsSyntax = (cssIntel, cssAtt);

  TCapstone = class(TPersistent)
  private
    FHandle: csh;
    FArch: TCsArch;
    FMode: TCsMode;
    FCode: Pointer;
    FSize: NativeUInt;
    FInsn: Pcs_insn;
    FDetails: boolean;
    FSyntax: TCsSyntax;
  public
    constructor Create;
    destructor Destroy; override;
    function Open(ACode: Pointer; ASize: NativeUInt): cs_err;
    procedure Close;
    function GetNext(var AAddr: UInt64; out AInsn: TCsInsn): boolean;
    function GetDetail(out AInsn: cs_insn; out ADetail: cs_detail): boolean;
  published
    property Arch: TCsArch read FArch write FArch default csaUnknown;
    property Mode: TCsMode read FMode write FMode default [];
    property Details: boolean read FDetails write FDetails;
    property Syntax: TCsSyntax read FSyntax write FSyntax default cssIntel;
  end;

implementation

{ TCapstone }

constructor TCapstone.Create;
begin
  inherited;
  FArch := csaUnknown;
  FMode := [];
  FSyntax := cssIntel;
  FHandle := 0;
  FInsn := nil;
end;

destructor TCapstone.Destroy;
begin
  Close;
  inherited;
end;

function TCapstone.Open(ACode: Pointer; ASize: NativeUInt): cs_err;
var
  h: csh;
  dMode: integer;
begin
  if FArch = csaUnknown then
    raise Exception.Create('Unknown Architecture');
  h := 0;
  dMode := 0;
  if csmLittleEndian in FMode then
    dMode := dMode or CS_MODE_LITTLE_ENDIAN;
  if csmARM in FMode then
    dMode := dMode or CS_MODE_ARM;
  if csm16 in FMode then
    dMode := dMode or CS_MODE_16;
  if csm32 in FMode then
    dMode := dMode or CS_MODE_32;
  if csm64 in FMode then
    dMode := dMode or CS_MODE_64;
  if csmThumb in FMode then
    dMode := dMode or CS_MODE_THUMB;
  if csmMClass in FMode then
    dMode := dMode or CS_MODE_MCLASS;
  if csmV8 in FMode then
    dMode := dMode or CS_MODE_V8;
  if csmMicro in FMode then
    dMode := dMode or CS_MODE_MICRO;
  if csmMips3 in FMode then
    dMode := dMode or CS_MODE_MIPS3;
  if csmMips3R6 in FMode then
    dMode := dMode or CS_MODE_MIPS32R6;
  if csmMipsGP64 in FMode then
    dMode := dMode or CS_MODE_MIPSGP64;
  if csmV9 in FMode then
    dMode := dMode or CS_MODE_V9;
  if csmBigEndian in FMode then
    dMode := dMode or CS_MODE_BIG_ENDIAN;

  Result := cs_open(Ord(FArch), dMode, @h);
  if Result = CS_ERR_OK then begin
    FHandle := h;
    cs_option(FHandle, CS_OPT_SKIPDATA, Ord(CS_OPT_ON));
    if FDetails then
	    cs_option(FHandle, CS_OPT_DETAIL, Ord(CS_OPT_ON));
    if FSyntax = cssAtt then
	    cs_option(FHandle, CS_OPT_SYNTAX, Ord(CS_OPT_SYNTAX_ATT));
  end;

  FCode := ACode;
  FSize := ASize;
end;

procedure TCapstone.Close;
begin
  if FInsn <> nil then begin
    cs_free(FInsn, 1);
    FInsn := nil;
  end;
  if FHandle <> 0 then begin
    cs_close(FHandle);
    FHandle := 0;
  end;
end;

function TCapstone.GetDetail(out AInsn: cs_insn; out ADetail: cs_detail): boolean;
begin
  if (FInsn <> nil) then begin
   	Move(FInsn^, AInsn, SizeOf(cs_insn));
  	if (FInsn^.detail <> nil) then
	  	Move(FInsn^.detail^, ADetail, SizeOf(cs_detail));
		Result := true;
  end else
  	Result := false;
end;

function Read_BSTRING(Address : Int64; LengthText : Integer): ShortString stdcall;
var
  i : Integer;
begin
  Result := '';
  try
    for i := 0 to LengthText do
    begin
      if Byte(PQWord(Address+i)^) = $00 then Break;
      Result := Result + Chr(Byte(PQWord(Address+i)^));
    end;
  except
    on E: EAccessViolation do Exit;
  end;
end;

function TCapstone.GetNext(var AAddr: UInt64; out AInsn: TCsInsn): boolean;
begin
  if FHandle = 0 then
    Exit(false);

  if (FInsn = nil) then
    FInsn := cs_malloc(FHandle);

  AInsn.id := 0;
  AInsn.address := 0;
  AInsn.size := 0;
  FillChar(AInsn.bytes, 16, 0);
  AInsn.mnemonic := '';
  AInsn.op_str := '';

  Result := cs_disasm_iter(FHandle, FCode, FSize, AAddr, FInsn);
  if Result then
  begin
    AInsn.id := FInsn^.id;
    AInsn.address := FInsn^.address;
    AInsn.size := FInsn^.size;
    Move(FInsn^.bytes, AInsn.bytes, 16);
    AInsn.mnemonic := string(FInsn^.mnemonic);
    AInsn.op_str := string(FInsn^.op_str);
  end;
end;

end.

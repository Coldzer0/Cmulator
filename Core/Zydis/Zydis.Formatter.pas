{***************************************************************************************************

  Zydis Top Level API

  Original Author : Florian Bernd

 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.

***************************************************************************************************}

unit Zydis.Formatter;

interface

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  {$IFNDEF FPC}System.SysUtils{$ELSE}SysUtils{$ENDIF}, Zydis, Zydis.Exception;

type
  TZydisFormatter = class(TObject)
  strict private
    class var Callbacks: array[TZydisFormatterHookType] of Pointer;
  strict private
    FContext: Zydis.TZydisFormatter;
    FHexPrefix: AnsiString;
    FHexSuffix: AnsiString;
  strict private
    procedure SetProperty(&Property: TZydisFormatterProperty; Value: ZydisUPointer); inline;
    procedure SetUppercase(Value: ZydisBool); inline;
    procedure SetForceMemorySegments(Value: ZydisBool); inline;
    procedure SetForceMemorySize(Value: ZydisBool); inline;
    procedure SetAddressFormat(Value: TZydisAddressFormat); inline;
    procedure SetDisplacementFormat(Value: TZydisDisplacementFormat); inline;
    procedure SetImmediateFormat(Value: TZydisImmediateFormat); inline;
    procedure SetHexUppercase(Value: ZydisBool); inline;
    procedure SetHexPrefix(const Value: AnsiString); inline;
    procedure SetHexSuffix(const Value: AnsiString); inline;
    procedure SetHexPaddingAddress(const Value: ZydisU8); inline;
    procedure SetHexPaddingDisplacement(const Value: ZydisU8); inline;
    procedure SetHexPaddingImmediate(const Value: ZydisU8); inline;
  strict private
    class function InternalPreInstruction(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPostInstruction(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPreOperand(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPostOperand(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalFormatInstruction(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalFormatOperandReg(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalFormatOperandMem(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalFormatOperandPtr(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalFormatOperandImm(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPrintMnemonic(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPrintRegister(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; Reg: TZydisRegister;
      UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPrintAddress(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; Address: ZydisU64;
      UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPrintDisp(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPrintImm(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPrintMemSize(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPrintPrefixes(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      UserData: TZydisFormatter): TZydisStatus; static; cdecl;
    class function InternalPrintDecorator(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; Decorator: TZydisDecoratorType;
      UserData: TZydisFormatter): TZydisStatus; static; cdecl;
  strict protected
    function DoPreInstruction(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction): TZydisStatus; virtual;
    function DoPostInstruction(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction): TZydisStatus; virtual;
    function DoPreOperand(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand): TZydisStatus; virtual;
    function DoPostOperand(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand): TZydisStatus; virtual;
    function DoFormatInstruction(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction): TZydisStatus; virtual;
    function DoFormatOperandReg(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand): TZydisStatus; virtual;
    function DoFormatOperandMem(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand): TZydisStatus; virtual;
    function DoFormatOperandPtr(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand): TZydisStatus; virtual;
    function DoFormatOperandImm(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand): TZydisStatus; virtual;
    function DoPrintMnemonic(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction): TZydisStatus; virtual;
    function DoPrintRegister(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; Reg: TZydisRegister): TZydisStatus; virtual;
    function DoPrintAddress(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; Address: ZydisU64): TZydisStatus; virtual;
    function DoPrintDisp(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand): TZydisStatus; virtual;
    function DoPrintImm(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand): TZydisStatus; virtual;
    function DoPrintMemSize(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand): TZydisStatus; virtual;
    function DoPrintPrefixes(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction): TZydisStatus; virtual;
    function DoPrintDecorator(const Formatter: Zydis.TZydisFormatter;
      var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
      const Operand: TZydisDecodedOperand; Decorator: TZydisDecoratorType): TZydisStatus; virtual;
  public
    function FormatInstruction(const Instruction: TZydisDecodedInstruction): String;
    function FormatOperand(const Instruction: TZydisDecodedInstruction; Index: ZydisU8): String;
  public
    constructor Create(Style: TZydisFormatterStyle);
  public
    //class constructor Create;
  public
    property Uppercase: ZydisBool write SetUppercase;
    property ForceMemorySegments: ZydisBool write SetForceMemorySegments;
    property ForceMemorySize: ZydisBool write SetForceMemorySize;
    property AddressFormat: TZydisAddressFormat write SetAddressFormat;
    property DisplacementFormat: TZydisDisplacementFormat write SetDisplacementFormat;
    property ImmediateFormat: TZydisImmediateFormat write SetImmediateFormat;
    property HexUppercase: ZydisBool write SetHexUppercase;
    property HexPrefix: AnsiString write SetHexPrefix;
    property HexSuffix: AnsiString write SetHexSuffix;
    property HexPaddingAddress: ZydisU8 write SetHexPaddingAddress;
    property HexPaddingDisplacement: ZydisU8 write SetHexPaddingDisplacement;
    property HexPaddingImmediate: ZydisU8 write SetHexPaddingImmediate;
  end;

implementation

{ TZydisFormatter }

constructor TZydisFormatter.Create(Style: TZydisFormatterStyle);
var
  Status: TZydisStatus;
  HookType: TZydisFormatterHookType;
begin
  inherited Create;
  Status := ZydisFormatterInit(FContext, Style);
  if (not ZydisSuccess(Status)) then TZydisException.RaiseException(Status);
  for HookType := Low(TZydisFormatterHookType) to High(TZydisFormatterHookType) do
  begin
    Status := ZydisFormatterSetHook(FContext, HookType, Callbacks[HookType]);
    if (not ZydisSuccess(Status)) then TZydisException.RaiseException(Status);
  end;
end;

//class constructor TZydisFormatter.Create;
//begin
  //Callbacks[ZYDIS_FORMATTER_HOOK_PRE_INSTRUCTION   ] := @InternalPreInstruction;
  //Callbacks[ZYDIS_FORMATTER_HOOK_POST_INSTRUCTION  ] := @InternalPostInstruction;
  //Callbacks[ZYDIS_FORMATTER_HOOK_PRE_OPERAND       ] := @InternalPreOperand;
  //Callbacks[ZYDIS_FORMATTER_HOOK_POST_OPERAND      ] := @InternalPostOperand;
  //Callbacks[ZYDIS_FORMATTER_HOOK_FORMAT_INSTRUCTION] := @InternalFormatInstruction;
  //Callbacks[ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_REG] := @InternalFormatOperandReg;
  //Callbacks[ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_MEM] := @InternalFormatOperandMem;
  //Callbacks[ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_PTR] := @InternalFormatOperandPtr;
  //Callbacks[ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_IMM] := @InternalFormatOperandImm;
  //Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_MNEMONIC    ] := @InternalPrintMnemonic;
  //Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_REGISTER    ] := @InternalPrintRegister;
  //Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_ADDRESS     ] := @InternalPrintAddress;
  //Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_DISP        ] := @InternalPrintDisp;
  //Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_IMM         ] := @InternalPrintImm;
  //Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_MEMSIZE     ] := @InternalPrintMemSize;
  //Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_PREFIXES    ] := @InternalPrintPrefixes;
  //Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_DECORATOR   ] := @InternalPrintDecorator;
//end;

function TZydisFormatter.DoFormatInstruction(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction): TZydisStatus;
begin
  Result := TZydisFormatterFunc(Callbacks[ZYDIS_FORMATTER_HOOK_FORMAT_INSTRUCTION])(
    @Formatter, Str, Instruction, Self);
end;

function TZydisFormatter.DoFormatOperandImm(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand): TZydisStatus;
begin
  Result := TZydisFormatterOperandFunc(Callbacks[ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_IMM])(
    @Formatter, Str, Instruction, Operand, Self);
end;

function TZydisFormatter.DoFormatOperandMem(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand): TZydisStatus;
begin
  Result := TZydisFormatterOperandFunc(Callbacks[ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_MEM])(
    @Formatter, Str, Instruction, Operand, Self);
end;

function TZydisFormatter.DoFormatOperandPtr(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand): TZydisStatus;
begin
  Result := TZydisFormatterOperandFunc(Callbacks[ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_PTR])(
    @Formatter, Str, Instruction, Operand, Self);
end;

function TZydisFormatter.DoFormatOperandReg(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand): TZydisStatus;
begin
  Result := TZydisFormatterOperandFunc(Callbacks[ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_REG])(
    @Formatter, Str, Instruction, Operand, Self);
end;

function TZydisFormatter.DoPostInstruction(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction): TZydisStatus;
begin
  if (not Assigned(Callbacks[ZYDIS_FORMATTER_HOOK_POST_INSTRUCTION])) then
  begin
    Exit(ZYDIS_STATUS_SUCCESS);
  end;
  Result := TZydisFormatterFunc(Callbacks[ZYDIS_FORMATTER_HOOK_POST_INSTRUCTION])(
    @Formatter, Str, Instruction, Self);
end;

function TZydisFormatter.DoPostOperand(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand): TZydisStatus;
begin
  if (not Assigned(Callbacks[ZYDIS_FORMATTER_HOOK_POST_OPERAND])) then
  begin
    Exit(ZYDIS_STATUS_SUCCESS);
  end;
  Result := TZydisFormatterOperandFunc(Callbacks[ZYDIS_FORMATTER_HOOK_POST_OPERAND])(
    @Formatter, Str, Instruction, Operand, Self);
end;

function TZydisFormatter.DoPreInstruction(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction): TZydisStatus;
begin
  if (not Assigned(Callbacks[ZYDIS_FORMATTER_HOOK_PRE_INSTRUCTION])) then
  begin
    Exit(ZYDIS_STATUS_SUCCESS);
  end;
  Result := TZydisFormatterFunc(Callbacks[ZYDIS_FORMATTER_HOOK_PRE_INSTRUCTION])(
    @Formatter, Str, Instruction, Self);
end;

function TZydisFormatter.DoPreOperand(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
  const Instruction: TZydisDecodedInstruction; const Operand: TZydisDecodedOperand): TZydisStatus;
begin
  if (not Assigned(Callbacks[ZYDIS_FORMATTER_HOOK_PRE_OPERAND])) then
  begin
    Exit(ZYDIS_STATUS_SUCCESS);
  end;
  Result := TZydisFormatterOperandFunc(Callbacks[ZYDIS_FORMATTER_HOOK_PRE_OPERAND])(
    @Formatter, Str, Instruction, Operand, Self);
end;

function TZydisFormatter.DoPrintAddress(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; Address: ZydisU64): TZydisStatus;
begin
  Result := TZydisFormatterAddressFunc(Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_ADDRESS])(
    @Formatter, Str, Instruction, Operand, Address, Self);
end;

function TZydisFormatter.DoPrintDecorator(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; Decorator: TZydisDecoratorType): TZydisStatus;
begin
  Result := TZydisFormatterDecoratorFunc(Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_DECORATOR])(
    @Formatter, Str, Instruction, Operand, Decorator, Self);
end;

function TZydisFormatter.DoPrintDisp(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
  const Instruction: TZydisDecodedInstruction; const Operand: TZydisDecodedOperand): TZydisStatus;
begin
  Result := TZydisFormatterOperandFunc(Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_DISP])(
    @Formatter, Str, Instruction, Operand, Self);
end;

function TZydisFormatter.DoPrintImm(const Formatter: Zydis.TZydisFormatter; var Str: TZydisString;
  const Instruction: TZydisDecodedInstruction; const Operand: TZydisDecodedOperand): TZydisStatus;
begin
  Result := TZydisFormatterOperandFunc(Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_IMM])(
    @Formatter, Str, Instruction, Operand, Self);
end;

function TZydisFormatter.DoPrintMemSize(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand): TZydisStatus;
begin
  Result := TZydisFormatterOperandFunc(Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_MEMSIZE])(
    @Formatter, Str, Instruction, Operand, Self);
end;

function TZydisFormatter.DoPrintMnemonic(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction): TZydisStatus;
begin
  Result := TZydisFormatterFunc(Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_MNEMONIC])(
    @Formatter, Str, Instruction, Self);
end;

function TZydisFormatter.DoPrintPrefixes(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction): TZydisStatus;
begin
  Result := TZydisFormatterFunc(Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_PREFIXES])(
    @Formatter, Str, Instruction, Self);
end;

function TZydisFormatter.DoPrintRegister(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; Reg: TZydisRegister): TZydisStatus;
begin
  Result := TZydisFormatterRegisterFunc(Callbacks[ZYDIS_FORMATTER_HOOK_PRINT_REGISTER])(
    @Formatter, Str, Instruction, Operand, Reg, Self);
end;

function TZydisFormatter.FormatInstruction(const Instruction: TZydisDecodedInstruction): String;
const
  STACK_BUFFER_LEN = 256;
var
  Status: TZydisStatus;
  Buffer: array of AnsiChar;
  BufferLen: ZydisUSize;
  StackBuf: array[0..STACK_BUFFER_LEN - 1] of AnsiChar;
  Data: Pointer;
begin
  BufferLen := STACK_BUFFER_LEN;
  Status := ZydisFormatterFormatInstructionEx(@FContext, @Instruction, @StackBuf[0],
    STACK_BUFFER_LEN, Self);
  Data := @StackBuf[0];
  while (Status = ZYDIS_STATUS_INSUFFICIENT_BUFFER_SIZE) do
  begin
    BufferLen := BufferLen * 2;
    SetLength(Buffer, BufferLen);
    Status := ZydisFormatterFormatInstructionEx(@FContext, @Instruction, @Buffer[0],
      BufferLen, Self);
    Data := @Buffer[0];
  end;
  if (not ZydisSuccess(Status)) then TZydisException.RaiseException(Status);
  Result := String(PAnsiChar(Data));
end;

function TZydisFormatter.FormatOperand(const Instruction: TZydisDecodedInstruction;
  Index: ZydisU8): String;
const
  STACK_BUFFER_LEN = 64;
var
  Status: TZydisStatus;
  Buffer: array of AnsiChar;
  BufferLen: ZydisUSize;
  StackBuf: array[0..STACK_BUFFER_LEN - 1] of AnsiChar;
  Data: Pointer;
begin
  BufferLen := STACK_BUFFER_LEN;
  Status := ZydisFormatterFormatOperandEx(@FContext, @Instruction, Index, @StackBuf[0],
    STACK_BUFFER_LEN, Self);
  Data := @StackBuf[0];
  while (Status = ZYDIS_STATUS_INSUFFICIENT_BUFFER_SIZE) do
  begin
    BufferLen := BufferLen * 2;
    SetLength(Buffer, BufferLen);
    Status := ZydisFormatterFormatOperandEx(@FContext, @Instruction, Index, @Buffer[0],
      BufferLen, Self);
    Data := @Buffer[0];
  end;
  if (not ZydisSuccess(Status)) then TZydisException.RaiseException(Status);
  Result := String(PAnsiChar(Data));
end;

class function TZydisFormatter.InternalFormatInstruction(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoFormatInstruction(Formatter, Str, Instruction);
end;

class function TZydisFormatter.InternalFormatOperandImm(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoFormatOperandImm(Formatter, Str, Instruction, Operand);
end;

class function TZydisFormatter.InternalFormatOperandMem(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoFormatOperandMem(Formatter, Str, Instruction, Operand);
end;

class function TZydisFormatter.InternalFormatOperandPtr(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoFormatOperandPtr(Formatter, Str, Instruction, Operand);
end;

class function TZydisFormatter.InternalFormatOperandReg(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoFormatOperandReg(Formatter, Str, Instruction, Operand);
end;

class function TZydisFormatter.InternalPostInstruction(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPostInstruction(Formatter, Str, Instruction);
end;

class function TZydisFormatter.InternalPostOperand(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPostOperand(Formatter, Str, Instruction, Operand);
end;

class function TZydisFormatter.InternalPreInstruction(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPreInstruction(Formatter, Str, Instruction);
end;

class function TZydisFormatter.InternalPreOperand(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPreOperand(Formatter, Str, Instruction, Operand);
end;

class function TZydisFormatter.InternalPrintAddress(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; Address: ZydisU64; UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPrintAddress(Formatter, Str, Instruction, Operand, Address);
end;

class function TZydisFormatter.InternalPrintDecorator(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; Decorator: TZydisDecoratorType;
  UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPrintDecorator(Formatter, Str, Instruction, Operand, Decorator);
end;

class function TZydisFormatter.InternalPrintDisp(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPrintDisp(Formatter, Str, Instruction, Operand);
end;

class function TZydisFormatter.InternalPrintImm(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPrintImm(Formatter, Str, Instruction, Operand);
end;

class function TZydisFormatter.InternalPrintMemSize(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPrintMemSize(Formatter, Str, Instruction, Operand);
end;

class function TZydisFormatter.InternalPrintMnemonic(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPrintMnemonic(Formatter, Str, Instruction);
end;

class function TZydisFormatter.InternalPrintPrefixes(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPrintPrefixes(Formatter, Str, Instruction);
end;

class function TZydisFormatter.InternalPrintRegister(const Formatter: Zydis.TZydisFormatter;
  var Str: TZydisString; const Instruction: TZydisDecodedInstruction;
  const Operand: TZydisDecodedOperand; Reg: TZydisRegister;
  UserData: TZydisFormatter): TZydisStatus;
begin
  Result := UserData.DoPrintRegister(Formatter, Str, Instruction, Operand, Reg);
end;

procedure TZydisFormatter.SetAddressFormat(Value: TZydisAddressFormat);
begin
  SetProperty(ZYDIS_FORMATTER_PROP_ADDR_FORMAT, ZydisUPointer(Value));
end;

procedure TZydisFormatter.SetDisplacementFormat(Value: TZydisDisplacementFormat);
begin
  SetProperty(ZYDIS_FORMATTER_PROP_DISP_FORMAT, ZydisUPointer(Value));
end;

procedure TZydisFormatter.SetForceMemorySegments(Value: ZydisBool);
begin
  SetProperty(ZYDIS_FORMATTER_PROP_FORCE_MEMSEG, ZydisUPointer(Value));
end;

procedure TZydisFormatter.SetForceMemorySize(Value: ZydisBool);
begin
  SetProperty(ZYDIS_FORMATTER_PROP_FORCE_MEMSIZE, ZydisUPointer(Value));
end;

procedure TZydisFormatter.SetHexPaddingAddress(const Value: ZydisU8);
begin
  SetProperty(ZYDIS_FORMATTER_PROP_HEX_PADDING_ADDR, ZydisUPointer(Value));
end;

procedure TZydisFormatter.SetHexPaddingDisplacement(const Value: ZydisU8);
begin
  SetProperty(ZYDIS_FORMATTER_PROP_HEX_PADDING_DISP, ZydisUPointer(Value));
end;

procedure TZydisFormatter.SetHexPaddingImmediate(const Value: ZydisU8);
begin
  SetProperty(ZYDIS_FORMATTER_PROP_HEX_PADDING_IMM, ZydisUPointer(Value));
end;

procedure TZydisFormatter.SetHexPrefix(const Value: AnsiString);
begin
  FHexPrefix := Value;
  SetProperty(ZYDIS_FORMATTER_PROP_HEX_PREFIX, ZydisUPointer(@FHexPrefix[1]));
end;

procedure TZydisFormatter.SetHexSuffix(const Value: AnsiString);
begin
  FHexSuffix := Value;
  SetProperty(ZYDIS_FORMATTER_PROP_HEX_SUFFIX, ZydisUPointer(@FHexSuffix[1]));
end;

procedure TZydisFormatter.SetHexUppercase(Value: ZydisBool);
begin
  SetProperty(ZYDIS_FORMATTER_PROP_HEX_UPPERCASE, ZydisUPointer(Value));
end;

procedure TZydisFormatter.SetImmediateFormat(Value: TZydisImmediateFormat);
begin
  SetProperty(ZYDIS_FORMATTER_PROP_IMM_FORMAT, ZydisUPointer(Value));
end;

procedure TZydisFormatter.SetProperty(&Property: TZydisFormatterProperty; Value: ZydisUPointer);
var
  Status: TZydisStatus;
begin
  Status := ZydisFormatterSetProperty(FContext, &Property, Value);
  if (not ZydisSuccess(Status)) then TZydisException.RaiseException(Status);
end;

procedure TZydisFormatter.SetUppercase(Value: ZydisBool);
begin
  SetProperty(ZYDIS_FORMATTER_PROP_UPPERCASE, ZydisUPointer(Value));
end;

end.

{***************************************************************************************************

  Zydis Top Level API

  Original Author : Florian Bernd .

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

unit Zydis.Decoder;

interface

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  {$IFNDEF FPC}System.SysUtils{$ELSE}SysUtils{$ENDIF}, Zydis, Zydis.Exception;

type
  TZydisDecoder = class sealed(TObject)
  strict private
    FContext: Zydis.TZydisDecoder;
  public
    procedure EnableMode(Mode: TZydisDecoderMode; Enabled: Boolean); inline;
    procedure DecodeBuffer(const Buffer: Pointer; Length: ZydisUSize; InstructionPointer: ZydisU64;
      var Instruction: TZydisDecodedInstruction); inline;
  public
    constructor Create(MachineMode: TZydisMachineMode; AddressWidth: TZydisAddressWidth);
  end;

implementation

{ TZydisDecoder }

constructor TZydisDecoder.Create(MachineMode: TZydisMachineMode; AddressWidth: TZydisAddressWidth);
var
  Status: TZydisStatus;
begin
  inherited Create;
  Status := ZydisDecoderInit(FContext, MachineMode, AddressWidth);
  if (not ZydisSuccess(Status)) then TZydisException.RaiseException(Status);
end;

procedure TZydisDecoder.DecodeBuffer(const Buffer: Pointer; Length: ZydisUSize;
  InstructionPointer: ZydisU64; var Instruction: TZydisDecodedInstruction);
var
  Status: TZydisStatus;
begin
  Status := ZydisDecoderDecodeBuffer(@FContext, Buffer, Length, InstructionPointer, Instruction);
  if (not ZydisSuccess(Status)) then TZydisException.RaiseException(Status);
end;

procedure TZydisDecoder.EnableMode(Mode: TZydisDecoderMode; Enabled: Boolean);
var
  Status: TZydisStatus;
begin
  Status := ZydisDecoderEnableMode(FContext, Mode, Enabled);
  if (not ZydisSuccess(Status)) then TZydisException.RaiseException(Status);
end;

end.

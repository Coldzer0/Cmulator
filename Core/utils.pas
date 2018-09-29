unit Utils;

{$mode delphi}
interface

uses
  Classes, SysUtils,strutils,FileUtil,
  Unicorn_dyn, UnicornConst, X86Const,
  {$i besenunits.inc},
  Capstone, CapstoneCmn, CapstoneApi;

type
  TArray = Array of byte;

procedure HexDump(mem : PByte; len : integer; VirtualAddr : UInt64 = 0; COLS : byte = 16);
procedure DumpStack(Addr : UInt64; Size : Cardinal);

function reg_read_x32(uc : uc_engine; reg : integer): UInt32;
function reg_read_x64(uc : uc_engine; reg : integer): UInt64;

function reg_write_x64(uc : uc_engine; reg: integer; value : UInt64): boolean;
function reg_write_x32(uc : uc_engine; reg: integer; value : UInt32): boolean;
function DisAsm(code : Pointer; Addr : UInt64; Size : UInt32) : TCsInsn;


// Emulator JS Wrappers .
function GetModulehandle(Module : String) : UInt64;
function GetProcAddr(Handle : UInt64; FnName : String): UInt64;
function push(value : UInt64): Boolean;
function pop(): UInt64;

function ReadStringA( Addr : UInt64; len : UInt32 = 0): AnsiString;
function ReadStringW( Addr : UInt64; len : UInt32 = 0): AnsiString;

function WriteStringA( Addr : UInt64; Str : AnsiString): UInt32;
function WriteStringW( Addr : UInt64; Str : AnsiString): UInt32;

function WriteMem(Addr   : UInt64; value : Pointer; len : UInt32) : boolean;
function WriteByte(Addr  : UInt64; value : byte) : boolean;
function WriteWord(Addr  : UInt64; value : word) : boolean;
function WriteDword(Addr : UInt64; value : dword) : boolean;
function WriteQword(Addr : UInt64; value : qword) : boolean;

function ReadMem(Addr   : UInt64; len : UInt32) : TArray;
function ReadByte(Addr  : UInt64) : Byte;
function ReadWord(Addr  : UInt64) : Word;
function ReadDword(Addr : UInt64) : Int32;
function ReadQword(Addr : UInt64) : Int64;

function isprint(const AC: AnsiChar): boolean;

const
  UC_PAGE_SIZE = $1000;

implementation
   uses
     Globals,math,FnHook;

function isprint(const AC: AnsiChar): boolean;
begin
  Result := (AC >= ' ') and (AC <= '~') and (Ord(AC) <> $7F);
end;

function IsStringPrintable( Str : String): Boolean;
var
  i : Integer;
begin
  for i := 1 to Length(Str) do
  begin
    if not isprint(Str[i]) then
    begin
      Result := False;
      Break;
    end;
    Result := True;
  end;
end;

// this code will read UTF8 string from given Address :D ..
function ReadStringW(Addr : UInt64; len : UInt32 = 0) : AnsiString;
var
  ch : WORD;
  count : UInt32;
const
  MAX_LEN = 1256;
begin
  Result := '';
  ch := 0; count := 0;
  if len = 0 then len := MAX_LEN; // Set Max len if not set :V ..
  repeat
   Emulator.err := uc_mem_read_(Emulator.uc,Addr,@ch,2);
   Result += BESENUTF32CharToUTF8(ch);
   inc(count);
   inc(Addr,2);
  until (ch = 0) or (count >= len);
  Result := Trim(Result);
end;

// this code will read ASCII string from given Address :D ..
function ReadStringA( Addr : UInt64; len : UInt32 = 0): AnsiString;
var
  ch : byte;
  count : UInt32;
const
  MAX_LEN = 1256;
begin
  Result := '';
  ch := 0; count := 0;
  if len = 0 then len := MAX_LEN; // Set Max len if not set :V ..
  repeat
   Emulator.err := uc_mem_read_(Emulator.uc,Addr,@ch,1);
   Result += Chr(ch);
   inc(count);
   inc(Addr);
  until (ch = 0) or (count >= len);
  Result := Trim(Result);
end;

function WriteStringA( Addr : UInt64; Str : AnsiString): UInt32;
var
  ch : byte;
  i,len : integer;
begin
  Result := 0;
  len := length(Str);
  ch := 0;
  for i := 1 to len do
  begin
    ch := Ord(Str[i]);
    Emulator.err := uc_mem_write_(Emulator.uc,Addr,@ch,1);

    // if Error then return with written len .
    if Emulator.err <> UC_ERR_OK then break;

    inc(Result);
    inc(Addr);
  end;
  // write null byte may overide another string starting byte ! .
  //ch := 0;
  //Emulator.err := uc_mem_write_(Emulator.uc,Addr+1,@ch,1);
end;

function WriteStringW( Addr : UInt64; Str : AnsiString): UInt32;
var
  ch : Word;
  i,len : integer;
begin
  Result := 0;
  len := length(Str);
  ch := 0;
  for i := 1 to len do
  begin
    ch := word(Str[i]);
    Emulator.err := uc_mem_write_(Emulator.uc,Addr,@ch,2);

    // if Error then return with written len .
    if Emulator.err <> UC_ERR_OK then break;

    inc(Result);
    inc(Addr,2);
  end;
  // write null byte may overide another string starting byte ! .
  //ch := 0;
  //Emulator.err := uc_mem_write_(Emulator.uc,Addr+2,@ch,2);
end;

function WriteMem(Addr : UInt64; value : Pointer; len : UInt32) : boolean;
begin
  Emulator.err := uc_mem_write_(Emulator.uc,Addr,value,len);
  Result := Emulator.err = UC_ERR_OK;
end;

function WriteByte(Addr : UInt64; value : byte) : boolean;
begin
  Emulator.err := uc_mem_write_(Emulator.uc,Addr,@value,1);
  Result := Emulator.err = UC_ERR_OK;
end;

function WriteWord(Addr : UInt64; value : word) : boolean;
begin
  Emulator.err := uc_mem_write_(Emulator.uc,Addr,@value,2);
  Result := Emulator.err = UC_ERR_OK;
end;

function WriteDword(Addr : UInt64; value : dword) : boolean;
begin
  Emulator.err := uc_mem_write_(Emulator.uc,Addr,@value,4);
  Result := Emulator.err = UC_ERR_OK;
end;

function WriteQword(Addr : UInt64; value : qword) : boolean;
begin
  Emulator.err := uc_mem_write_(Emulator.uc,Addr,@value,8);
  Result := Emulator.err = UC_ERR_OK;
end;

function ReadMem(Addr : UInt64; len : UInt32) : TArray;
begin
  SetLength(Result,len);
  Emulator.err := uc_mem_read_(Emulator.uc,Addr,@Result,len);
end;

function ReadByte(Addr : UInt64) : Byte;
begin
  Result := 0;
  Emulator.err := uc_mem_read_(Emulator.uc,Addr,@Result,1);
end;

function ReadWord(Addr : UInt64) : Word;
begin
  Result := 0;
  Emulator.err := uc_mem_read_(Emulator.uc,Addr,@Result,2);
end;

function ReadDword(Addr : UInt64) : Int32;
begin
  Result := 0;
  Emulator.err := uc_mem_read_(Emulator.uc,Addr,@Result,4);
end;

function ReadQword(Addr : UInt64) : Int64;
begin
  Result := 0;
  Emulator.err := uc_mem_read_(Emulator.uc,Addr,@Result,8);
end;


function push(value : UInt64): Boolean;
var
  Stack : UInt64;
begin
  Result := False; Stack := 0;
  Emulator.err := uc_reg_read(Emulator.uc,ifthen(Emulator.PE_x64,UC_X86_REG_RSP,UC_X86_REG_ESP),@Stack);
  if Emulator.err = UC_ERR_OK then
  begin
    Stack -= Emulator.img.ImageWordSize;// sub StackPointer,{4 or 8} .
    Emulator.err := uc_reg_write(Emulator.uc,ifthen(Emulator.PE_x64,UC_X86_REG_RSP,UC_X86_REG_ESP),@Stack);
    if Emulator.err = UC_ERR_OK then
    begin
      Emulator.err := uc_mem_write_(Emulator.uc,Stack,@value,Emulator.Img.ImageWordSize);
      Result := True;
    end;
  end;
end;
// this code will read Stack Pointer then Read it's Value then .
// add 4 or 8 (ImageWordSize) Depend on File if x32 or x64 .
// then write it to Stack Pointer .
function pop(): UInt64;
var
  Stack : UInt64;
begin
  Stack := 0; Result := 0;
  Emulator.err := uc_reg_read(Emulator.uc,ifthen(Emulator.PE_x64,UC_X86_REG_RSP,UC_X86_REG_ESP),@Stack);
  Emulator.err := uc_mem_read_(Emulator.uc,Stack,@Result,Emulator.Img.ImageWordSize);
  if Emulator.err = UC_ERR_OK then
  begin
    Stack += Emulator.img.ImageWordSize;
    Emulator.err := uc_reg_write(Emulator.uc,ifthen(Emulator.PE_x64,UC_X86_REG_RSP,UC_X86_REG_ESP),@Stack);
  end;
end;

function GetModulehandle(Module : String) : UInt64;
var
  Lib : TNewDll;
begin
  Result := 0;
  if LowerCase(Module) = LowerCase(ExtractFileName(Emulator.Img.FileName)) then
     Exit(Emulator.Img.ImageBase);

  Module := Trim(ExtractFileNameWithoutExt(LowerCase(Module)) + '.dll');
  if Emulator.Libs.TryGetValue(Module,Lib) then
     Result := Lib.BaseAddress;
end;

function GetProcAddr(Handle : UInt64; FnName : String): UInt64;
var
  Lib : TNewDll;
  API : TLibFunction;
begin
  for Lib in Emulator.Libs.Values do
  begin
    if lib.BaseAddress = Handle then
    begin
      if lib.FnByName.TryGetValue(FnName,API) then
      begin
        Result := API.VAddress;
        break;
      end;
    end;
  end;
end;

function DisAsm(code : Pointer; Addr : UInt64; Size : UInt32) : TCsInsn;
var
  disasm: TCapstone;
  insn: TCsInsn;
  err : cs_err;
begin
  Initialize(Result);
  FillByte(Result,SizeOf(Result),0);
  disasm := TCapstone.Create;
  try
    if Emulator.PE_x64 then
       disasm.Mode := [csm64]
    else
       disasm.Mode := [csm32];

    disasm.Arch := csaX86;
    err := disasm.Open(code,Size);
    if err = CS_ERR_OK then begin
      while disasm.GetNext(addr, insn) do begin
        Result := insn;
      end;
    end else begin
      WriteLn('[x] Error in cs_open : Err num ',err);
    end;
  finally
    disasm.Free;
  end;
end;

function reg_write_x32(uc : uc_engine; reg: integer; value : UInt32): boolean;
begin
  Result := uc_reg_write(uc,reg,@value) = UC_ERR_OK;
end;

function reg_write_x64(uc : uc_engine; reg: integer; value : UInt64): boolean;
begin
  Emulator.err := uc_reg_write(uc,reg,@value);
  Result := Emulator.err = UC_ERR_OK;
end;

function reg_read_x32(uc : uc_engine; reg : integer): UInt32;
begin
  Result := 0;
  uc_reg_read(uc,reg,@Result);
end;

function reg_read_x64(uc : uc_engine; reg : integer): UInt64;
begin
  Result := 0;
  Emulator.err := uc_reg_read(uc,reg,@Result);
end;

procedure DumpStack(Addr : UInt64; Size : Cardinal);
var
  Result : UInt64;
  i : Integer;
  ascii, unicode , Str : string;
const
  b32 = '%.8x : %.8x | %s';
  b64 = '%.16x : %.16x | %s';
begin
  Result := 0;
  if Addr = 0 then
     Emulator.err := uc_reg_read(Emulator.uc,ifthen(Emulator.PE_x64,UC_X86_REG_RSP,UC_X86_REG_ESP),@Addr);
  Writeln('============ Mem Dump ==============');
  for i := 0 to Size do
  begin
    Emulator.err := uc_mem_read_(Emulator.uc,Addr + (i * Emulator.Img.ImageWordSize),
                 @Result,Emulator.Img.ImageWordSize);


    Str := '';
    ascii := ReadStringA(Result);
    unicode := ReadStringW(Result);

    if IsStringPrintable(ascii) then
       Str := ascii;
    if IsStringPrintable(unicode) then
       Str := unicode;

    Writeln(Format(IfThen(Emulator.PE_x64,b64,b32),[Addr + ((i * Emulator.Img.ImageWordSize)),Result,Str]));
  end;
  Writeln('====================================');
  Writeln();
end;

procedure HexDump(mem : PByte; len : integer; VirtualAddr : UInt64 = 0; COLS : byte = 16);
var
  i , j , max : Integer;
  CH : Char;
begin
  if Emulator.RunOnDll then Exit;
  Writeln(#10'================================ Hex Dump ====================================');
  max := len + ifthen(Boolean(len mod COLS), (COLS - len mod COLS) , 0) - 1;
  for i := 0 to max do
  begin

    if ((i mod COLS) = 0) then
    begin
      if VirtualAddr <> 0 then
         Write(hexStr(UInt64(VirtualAddr+i),ifthen(Emulator.PE_x64,16,8)),' : ')
      else
         Write(hexStr(UInt64(mem+i),ifthen(Emulator.PE_x64,16,8)),' : ');
    end;

    CH := Chr(Byte((mem + i)^));

    if (i < len) then
       Write(IntToHex(Ord(CH),2),' ')
    else
       Write('   ');

    if (i mod COLS) = (COLS - 1) then
    begin
      Write(' | ');
      for j := i - (COLS - 1) to i do
      begin
        CH := Chr(Byte((mem + j)^));
        if j >= len then
           Write(' ')
        else
           if isprint(CH) then
             Write(CH)
           else
             Write('.');
      end;
      Writeln();
    end;
  end;
  Writeln('=============================================================================='#10);
end;

end.


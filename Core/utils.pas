unit Utils;

{$mode delphi}
interface

uses
  {$IfDef MSWINDOWS}windows,{$EndIf}
  Classes, SysUtils,strutils,RegExpr,
  Unicorn_dyn, UnicornConst, X86Const,
  Zydis,
  Zydis.Decoder,
  xxHash;

type
  TArray = Array of byte;

procedure HexDump(mem : PByte; len : integer; VirtualAddr : UInt64 = 0; COLS : byte = 16);
procedure DumpStack(Addr : UInt64; Size : Cardinal);

function reg_read_x32(uc : uc_engine; reg : integer): UInt32;
function reg_read_x64(uc : uc_engine; reg : integer): UInt64;

function reg_write_x64(uc : uc_engine; reg: integer; value : UInt64): boolean;
function reg_write_x32(uc : uc_engine; reg: integer; value : UInt32): boolean;
function DisAsm(code : Pointer; Addr : UInt64; Size : UInt32) : TZydisDecodedInstruction;


// Emulator JS Wrappers .
function CmuGetModulehandle(Module : String) : UInt64;
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

function ExtractFileNameWithoutExt(const AFilename: string): string;

function GetFullPath(name : string) : UnicodeString;
function GetDllFromApiSet(name : string): UnicodeString;
function SplitReg(Str : string) : string;

procedure TextColor(Color : Byte);
procedure NormVideo;

const
  UC_PAGE_SIZE  = $1000;
  EM_IMAGE_BASE = $400000;

// Console Colors
  LightRed     = 1;
  LightMagenta = 2;
  Yellow       = 3;
  LightCyan    = 4;
  Magenta      = 5;
  LightBlue    = 6;

implementation
   uses
     Globals,math,FnHook,Emu;


function ExtractFileNameWithoutExt(const AFilename: string): string;
var
 p: Integer;
begin
 Result:=AFilename;
 p:=length(Result);
 while (p>0) do begin
   case Result[p] of
     PathDelim: exit;
     {$ifdef windows}
     '/': if ('/' in AllowDirectorySeparators) then exit;
     {$endif}
     '.': exit(copy(Result,1, p-1));
   end;
   dec(p);
 end;
end;

// Taken from Besen Engine.
function UTF32CharToUTF8(u4c:LongWord):AnsiString;
begin
if u4c<=$7f then begin
 result:=ansichar(byte(u4c));
end else if u4c<=$7ff then begin
 result:=ansichar(byte($c0 or ((u4c shr 6) and $1f)))+ansichar(byte($80 or (u4c and $3f)));
end else if u4c<=$ffff then begin
 result:=ansichar(byte($e0 or ((u4c shr 12) and $0f)))+ansichar(byte($80 or ((u4c shr 6) and $3f)))+ansichar(byte($80 or (u4c and $3f)));
end else if u4c<=$1fffff then begin
 result:=ansichar(byte($f0 or ((u4c shr 18) and $07)))+ansichar(byte($80 or ((u4c shr 12) and $3f)))+ansichar(byte($80 or ((u4c shr 6) and $3f)))+ansichar(byte($80 or (u4c and $3f)));
{$ifndef strictutf8}
end else if u4c<=$3ffffff then begin
 result:=ansichar(byte($f8 or ((u4c shr 24) and $03)))+ansichar(byte($80 or ((u4c shr 18) and $3f)))+ansichar(byte($80 or ((u4c shr 12) and $3f)))+ansichar(byte($80 or ((u4c shr 6) and $3f)))+ansichar(byte($80 or (u4c and $3f)));
end else if u4c<=$7fffffff then begin
 result:=ansichar(byte($fc or ((u4c shr 30) and $01)))+ansichar(byte($80 or ((u4c shr 24) and $3f)))+ansichar(byte($80 or ((u4c shr 18) and $3f)))+ansichar(byte($80 or ((u4c shr 12) and $3f)))+ansichar(byte($80 or ((u4c shr 6) and $3f)))+ansichar(byte($80 or (u4c and $3f)));
{$endif}
end else begin
 u4c:=$fffd;
 result:=ansichar(byte($e0 or ((u4c shr 12) and $0f)))+ansichar(byte($80 or ((u4c shr 6) and $3f)))+ansichar(byte($80 or (u4c and $3f)));
end;
end;

function isprint(const AC: AnsiChar): boolean;
begin
  Result := (AC >= ' ') and (AC <= '~') and (Ord(AC) <> $7F);
end;

function IsStringPrintable( Str : String): Boolean;
var
  i : Integer;
begin
  Result := False;
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

function GetFullPath(name : string) : UnicodeString;
begin
  if Emulator.isx64 then
     Result := IncludeTrailingPathDelimiter(win64) + UnicodeString(LowerCase(Trim(name)))
  else
     Result := IncludeTrailingPathDelimiter(win32) + UnicodeString(LowerCase(Trim(name)));
end;

function SplitReg(Str : string) : string;
var
  re : TRegExpr;
begin
  Result := Str;
  re := TRegExpr.Create('^.*-l\d');
  if re.Exec(Str) then
  begin
    //Writeln('name : ',Str);
    //Writeln('[0]  : ',re.Match[0].Remove(Length(re.Match[0])-3,3),#10);
    Result := re.Match[0].Remove(Length(re.Match[0])-3,3);
  end;
  re.Free;
end;

function GetDllFromApiSet(name : string): UnicodeString;
var
  API : TApiRed;
  Dll : string;
  Path : UnicodeString;
begin
  Result := UnicodeString(name);

  Dll := ExtractFileNameWithoutExt(ExtractFileName(name));
  if not Emulator.ApiSetSchema.ContainsKey(Dll) then
     Dll := ExtractFileNameWithoutExt(ExtractFileName(SplitReg(name)));

  if Emulator.ApiSetSchema.ContainsKey(Dll) then
  begin
    Emulator.ApiSetSchema.TryGetValue(Dll,API);
    if API.count = 2 then
    begin
      Path := GetFullPath(API.last);
      if FileExists(string(Path)) then
         Result := Path
      else
      begin
        Path := GetFullPath(API._alias);
        if FileExists(string(Path)) then
           Result := Path
        else
        begin
          Path := GetFullPath(API.first);
          if FileExists(string(Path)) then
             Result := Path
          else
          begin
            Writeln(Format('Library "%s" not found ! [5]',[Path]));
            halt;
          end;
        end;
      end;
    end
    else
    begin
      Path := GetFullPath(API.first);
      if FileExists(string(Path)) then
         Result := Path
      else
      begin
        Writeln(Format('Library "%s" not found ! [4]',[Path]));
        halt;
      end;
    end;
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
   Result += UTF32CharToUTF8(ch);
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
  Initialize(Result);
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
  Emulator.err := uc_reg_read(Emulator.uc,ifthen(Emulator.isx64,UC_X86_REG_RSP,UC_X86_REG_ESP),@Stack);
  if Emulator.err = UC_ERR_OK then
  begin
    Stack -= Emulator.img.ImageWordSize;// sub StackPointer,{4 or 8} .
    Emulator.err := uc_reg_write(Emulator.uc,ifthen(Emulator.isx64,UC_X86_REG_RSP,UC_X86_REG_ESP),@Stack);
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
  Emulator.err := uc_reg_read(Emulator.uc,ifthen(Emulator.isx64,UC_X86_REG_RSP,UC_X86_REG_ESP),@Stack);
  Emulator.err := uc_mem_read_(Emulator.uc,Stack,@Result,Emulator.Img.ImageWordSize);
  if Emulator.err = UC_ERR_OK then
  begin
    Stack += Emulator.img.ImageWordSize;
    Emulator.err := uc_reg_write(Emulator.uc,ifthen(Emulator.isx64,UC_X86_REG_RSP,UC_X86_REG_ESP),@Stack);
  end;
end;

function CmuGetModulehandle(Module : String) : UInt64;
var
  Lib : TNewDll;
begin
  Result := 0;
  if LowerCase(Module) = LowerCase(ExtractFileName(Emulator.Img.FileName)) then
     Exit(Emulator.Img.ImageBase);

  Module := Trim(ExtractFileNameWithoutExt(LowerCase(ExtractFileName(Module))) + '.dll');
  if Emulator.Libs.TryGetValue(Module,Lib) then
     Result := Lib.BaseAddress;
end;

function GetProcAddr(Handle : UInt64; FnName : String): UInt64;
var
  Lib : TNewDll;
  API : TLibFunction;
  hash : Int64;
begin
  Result := 0;
  for Lib in Emulator.Libs.Values do
  begin
    if lib.BaseAddress = Handle then
    begin
      hash := xxHash64Calc(LowerCase(ExtractFileNameWithoutExt(ExtractFileName(lib.Dllname))) + '.' + FnName);

      //lib.FnByOrdinal;

      if lib.FnByName.TryGetValue(Hash,API) then
      begin
        Result := API.VAddress;
        break;
      end;
    end;
  end;
end;

function DisAsm(code : Pointer; Addr : UInt64; Size : UInt32) : TZydisDecodedInstruction;
var
  Decoder: Zydis.Decoder.TZydisDecoder;
begin
  Initialize(Result);
  try
    // TODO: update Zydis on windows, then remove comments.
    //if (ZydisGetVersion <> ZYDIS_VERSION) then
    //begin
    //  raise Exception.Create('Invalid Zydis version');
    //end;

    if Emulator.isx64 then
      Decoder := Zydis.Decoder.TZydisDecoder.Create(ZYDIS_MACHINE_MODE_LONG_64,ZYDIS_ADDRESS_WIDTH_64)
    else
      Decoder := Zydis.Decoder.TZydisDecoder.Create(ZYDIS_MACHINE_MODE_LONG_COMPAT_32,ZYDIS_ADDRESS_WIDTH_32);

    try
      Decoder.DecodeBuffer(code, Size, Addr,Result);
    finally
      Decoder.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
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
     Emulator.err := uc_reg_read(Emulator.uc,ifthen(Emulator.isx64,UC_X86_REG_RSP,UC_X86_REG_ESP),@Addr);
  Writeln('============ Mem Dump ==============');
  for i := 0 to Pred(Size) do
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

    Writeln(Format(IfThen(Emulator.isx64,b64,b32),[Addr + ((i * Emulator.Img.ImageWordSize)),Result,Str]));
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
  Writeln('           0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F');
  max := len + ifthen(Boolean(len mod COLS), (COLS - len mod COLS) , 0) - 1;
  for i := 0 to max do
  begin

    if ((i mod COLS) = 0) then
    begin
      if VirtualAddr <> 0 then
         Write(hexStr(UInt64(VirtualAddr+i),ifthen(Emulator.isx64,16,8)),' : ')
      else
         Write(hexStr(UInt64(mem+i),ifthen(Emulator.isx64,16,8)),' : ');
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

{$IfDef MSWINDOWS}
var
  OriginalConsole : WORD = 15;
{$EndIf}
procedure TextColor(Color : Byte);
{$IfDef MSWINDOWS}
var
  Info : CONSOLE_SCREEN_BUFFER_INFO;
{$EndIf}
begin
  {$IfDef MSWINDOWS}
  GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE),@Info);
  OriginalConsole := Info.wAttributes;
  {$EndIf}
  case Color of
    LightRed :
      {$IfDef unix}
      Write(#27'[1;31m');
      {$Else}
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),12);
      {$EndIf}
    LightMagenta :
      {$IfDef unix}
      Write(#27'[1;35m');
      {$Else}
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),13);
      {$EndIf}
    Magenta :
      {$IfDef unix}
      Write(#27'[3;35m');
      {$Else}
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),5);
      {$EndIf}
    Yellow :
      {$IfDef unix}
      Write(#27'[1;33m');
      {$Else}
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),14);
      {$EndIf}
    LightCyan :
      {$IfDef unix}
      Write(#27'[1;36m');
      {$Else}
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),11);
      {$EndIf}
    LightBlue :
      {$IfDef unix}
      Write(#27'[1;34m');
      {$Else}
      SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),9);
      {$EndIf}
  end;
end;

procedure NormVideo;
begin
  {$IfDef unix}
  Write(#27'[0m');
  {$Else}
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),OriginalConsole);
  {$EndIf}
end;

end.

unit JSEmuObj;

{$mode delphi}
{$WARN 5024 off : Parameter "$1" not used}
interface

uses
  Classes, SysUtils,
  FnHook,Utils,
  Unicorn_dyn, UnicornConst,
  PE_Loader,
  quickjs;


  { Register Stuff }
  function ReadReg(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function SetReg(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;


  { String things :P }
  function ReadStringA(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function ReadStringW(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;

  function WriteStringA(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function WriteStringW(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;

  { Emulator Modules }
  function LoadLibrary(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function GetModuleName(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function GetModuleHandle(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function GetProcAddress(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;

  { Memory things :D }
  function WriteByte(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function WriteWord(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function WriteDword(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function WriteQword(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function WriteMem(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;

  function ReadByte(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function ReadWord(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function ReadDword(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function ReadQword(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function ReadMem(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;

  { Stack }
  function push(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function pop(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;

  { Control Flow }
  function Stop(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function LastError(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;

  { Misc }
  function HexDump(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
  function StackDump(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;

implementation
   uses
     Globals, Emu;

{ TEmuObj }

function ReadReg(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Value : Int64 = 0;
  REG : UInt32 = 0;
begin
  if argc <> 1 then
  begin
    JS_ThrowInternalError(ctx,'GetReg take 1 arg - Ex: GetReg(REG_RAX)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_ToUint32(ctx,@REG,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'GetReg take 1 arg - Ex: GetReg(REG_RAX) - And Should Be Number',[]);
    Exit(JS_EXCEPTION);
  end;
  Value := 0;
  Emulator.err := uc_reg_read(Emulator.uc,REG,@Value);
  Result := JS_NewInt64(ctx,Value);
end;

function SetReg(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  value : Int64 = 0;
  REG : UInt32 = 0;
begin

  if argc <> 2 then
    JS_ThrowInternalError(ctx,'SetReg take 2 arg - Ex: SetReg(REG_RAX,0x401000)',[]);

  if JS_IsNumber(argv[0]) then
    JS_ToUint32(ctx,@REG,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'SetReg arg 1 Error - Ex: SetReg(REG_RAX,0x401000) - Both Should Be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[1]) then
     JS_ToInt64(ctx,@value,argv[1])
  else
  begin
    JS_ThrowInternalError(ctx,'SetReg arg 2 Error - Ex: SetReg(REG_RAX,0x401000) - Both Should Be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  //if (REG in [UC_X86_REG_EIP,UC_X86_REG_RIP]) and (value < Emulator.Img.ImageBase + Emulator.img.SizeOfImage) then
  //begin
  //  Emulator.Entry := value;
  //  WriteLn('Entry Changed to : ', hexStr(Emulator.Entry,8));
  //end;

  Emulator.err := uc_reg_write(Emulator.uc,REG,@value);
  Result := JS_NewBool(ctx,Emulator.err = UC_ERR_OK);
end;

function ReadStringA(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
  len  : UInt32 = 0;
  procedure Error(ErrNum : Integer);
  begin
    JS_ThrowInternalError(
    ctx,
    '[%d] ReadStringA take 1 or 2 arg - Ex: ReadStringA(Addr) or ReadStringA(Addr,len)',
    [ErrNum]);
  end;
begin
  if argc < 1 then
  begin
    Error(0);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_ToInt64(ctx,@Addr,argv[0])
  else
  begin
    Error(1); Exit(JS_EXCEPTION);
  end;

  if argc = 2 then
  begin
    if JS_IsNumber(argv[1]) then
      JS_ToUint32(ctx,@len,argv[1])
    else
    begin
      Error(2); Exit(JS_EXCEPTION);
    end;
  end;
  // TODO: Check if the Unicode strings works.
  Result := JS_NewString(ctx,PChar(Utils.ReadStringA(Addr,len)));
end;

function ReadStringW(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
  len  : UInt32 = 0;
  procedure Error(ErrNum : Integer);
  begin
    JS_ThrowInternalError(ctx,'[%d] ReadStringW take 1 or 2 arg - Ex: ReadStringW(Addr) or ReadStringW(Addr,len)',[ErrNum]);
  end;
begin

  if argc < 1 then
  begin
    JS_ThrowInternalError(ctx,'[0] ReadStringW take 1 or 2 arg - Ex: ReadStringW(Addr) or ReadStringW(Addr,len)',[]);
    Exit(JS_EXCEPTION);
  end;


  if JS_IsNumber(argv[0]) then
    JS_ToInt64(ctx,@Addr,argv[0])
  else
  begin
    Error(1); Exit(JS_EXCEPTION);
  end;

  if argc >= 2 then
  begin
    if JS_IsNumber(argv[1]) then
      JS_ToUint32(ctx,@len,argv[1])
    else
    begin
      Error(2); Exit(JS_EXCEPTION);
    end;
  end;

  Result := JS_NewString(ctx,PChar(Utils.ReadStringW(Addr,len)));
end;

function WriteStringA(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Str : PChar;
  Addr : Int64 = 0;
begin
  if argc <> 2 then
  begin
    JS_ThrowInternalError(ctx,'WriteStringA take 2 - Ex: WriteStringA(Addr, "plaplapla")',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_ToInt64(ctx,@Addr,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteStringA "First" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsString(argv[1]) then
    Str := JS_ToCString(ctx,argv[1])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteStringA "Second" Arg must be String',[]);
    Exit(JS_EXCEPTION);
  end;

  Result := JS_NewInt32(ctx,Utils.WriteStringA(Addr,Str));
  JS_FreeCString(ctx,Str);
end;

function WriteStringW(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Str : PChar;
  Addr : Int64 = 0;
begin
  if argc <> 2 then
  begin
    JS_ThrowInternalError(ctx,'WriteStringW take 2 - Ex: WriteStringW(Addr, "Cmulator")',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_ToInt64(ctx,@Addr,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteStringA "First" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsString(argv[1]) then
    Str := JS_ToCString(ctx,argv[1])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteStringW "Second" Arg must be String',[]);
    Exit(JS_EXCEPTION);
  end;
  Result := JS_NewInt32(ctx,Utils.WriteStringW(Addr,Str));
  JS_FreeCString(ctx,Str);
end;

function LoadLibrary(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Libname, RedirectLib : PChar;
  Lib : TNewDll;
begin
  Result := JS_NewInt64(ctx,0); // Default value = 0 ..
  if argc = 1 then
  begin
    if JS_IsString(argv[0]) then
      Libname := JS_ToCString(ctx,argv[0])
    else
    begin
      JS_ThrowInternalError(ctx,'LoadLibrary Arg must be String ! - Ex: LoadLibrary(''kernel32.dll'')',[]);
      Exit(JS_EXCEPTION);
    end;

    // this was here for debugging :P .
    //if AnsiContainsStr(Libname,'ms-') then
       //Writeln('Resolve lib : ',Libname ,' --> to : ',RedirectLib);

    RedirectLib := PChar(Trim(ExtractFileNameWithoutExt(LowerCase(ExtractFileName(Libname))) + '.dll'));

    // TODO: Need more test.
    if Emulator.Libs.TryGetValue(RedirectLib,Lib) then
    begin
      Result := JS_NewInt64(ctx,Lib.BaseAddress);
    end
    else
    begin
      if PE_Loader.load_sys_dll(Emulator.uc,RedirectLib) then
        if Emulator.Libs.TryGetValue(RedirectLib,Lib) then
           Result := JS_NewInt64(ctx,Lib.BaseAddress);
    end;
    JS_FreeCString(ctx,Libname);
  end;
end;

function GetModuleName(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Handle : Int64 = 0;
  Lib : TNewDll;
begin
  Result := JS_NewInt64(ctx,0); // Default value = 0 ..
  if argc = 1 then
  begin
    if JS_IsNumber(argv[0]) then
      JS_Toint64(ctx,@Handle,argv[0])
    else
    begin
      JS_ThrowInternalError(ctx,'GetModuleName Arg must be Number !!!',[]);
      Exit(JS_EXCEPTION);
    end;

    if (Handle = 0) or (Handle = Emulator.Img.ImageBase) then
    begin
      Result := JS_NewString(ctx,PChar(ExtractFileName(Emulator.Img.FileName))); // Current PE ...
      exit;
    end;

    for Lib in Emulator.Libs.Values do
    begin
      if lib.BaseAddress = Handle then
      begin
           Result := JS_NewString(ctx,PChar(ExtractFileName(lib.Dllname)));
           break;
      end;
    end;
  end
  else
   Result := JS_NewString(ctx,PChar(ExtractFileName(Emulator.Img.FileName))); // Current PE ...
end;

function GetModuleHandle(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Libname : PChar;
begin
  Result := JS_NewInt64(ctx,0); // Default value = 0 ..
  if argc = 1 then
  begin
    if JS_IsString(argv[0]) then
      Libname := JS_ToCString(ctx,argv[0])
    else
    begin
      JS_ThrowInternalError(ctx,'GetModuleHandle Arg must be String !!!',[]);
      Exit(JS_EXCEPTION);
    end;
    Result := JS_NewInt64(ctx,Utils.CmuGetModulehandle(Libname));
  end
  else
   Result := JS_NewInt64(ctx,Emulator.Img.ImageBase); // Current PE ...
end;

function GetProcAddress(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Handle : Int64 = 0;
  FnName : PChar;
begin
  Result := JS_NewInt64(ctx,0); // Default value = 0 ..
  if argc <> 2 then
  begin
    JS_ThrowInternalError(ctx,'GetProcAddr takes 2 Args Ex: Emu.GetProcAddr(user32_handle,''MessageBoxA'')',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Handle,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'GetProcAddr First Arg must be Number !!!',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsString(argv[1]) then
    FnName := JS_ToCString(ctx,argv[1])
  else
  begin
    JS_ThrowInternalError(ctx,'GetProcAddr Second Arg must be String !!!',[]);
    Exit(JS_EXCEPTION);
  end;
  // TODO: Add Search by Ordinal ..
  Result := JS_NewInt64(ctx,GetProcAddr(Handle,FnName));
  JS_FreeCString(ctx,FnName);
end;

function WriteByte(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
  value : uint32 = 0;
begin
  if argc <> 2 then
  begin
    JS_ThrowInternalError(ctx,'WriteByte take 2 - Ex: WriteByte(Addr, 0x100)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteByte "First" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[1]) then
    JS_ToUint32(ctx,@value,argv[1])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteByte "Second" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  Result := JS_NewBool(ctx,Utils.WriteByte(Addr,byte(value)));
end;

function WriteWord(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
  value : Word = 0;
begin
  if argc <> 2 then
  begin
    JS_ThrowInternalError(ctx,'WriteWord take 2 - Ex: WriteWord(Addr, 0x100)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteWord "First" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[1]) then
    JS_Toint32(ctx,@value,argv[1])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteWord "Second" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  Result := JS_NewBool(ctx,Utils.WriteWord(Addr,value));
end;

function WriteDword(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
  value : Dword = 0;
begin
  if argc <> 2 then
  begin
    JS_ThrowInternalError(ctx,'WriteDword take 2 - Ex: WriteDWord(Addr, 0x100)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteDword "First" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[1]) then
    JS_Toint32(ctx,@value,argv[1])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteDword "Second" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  Result := JS_NewBool(ctx,Utils.WriteDword(Addr,value));
end;

function WriteQword(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
  value : Qword = 0;
begin
  if argc <> 2 then
  begin
    JS_ThrowInternalError(ctx,'WriteQword take 2 - Ex: WriteQword(Addr, 0x100)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteQword "First" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[1]) then
    JS_Toint64(ctx,@value,argv[1])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteQword "Second" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;

  Result := JS_NewBool(ctx,Utils.WriteQword(Addr,value));
end;

function WriteMem(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
  val : Byte = 0;
  Element,length : JSValue;
  i,len : Integer;
begin
  Result := JS_NewInt32(ctx,0);
  if argc <> 2 then
  begin
    JS_ThrowInternalError(ctx,'WriteMem take 2 - Ex: WriteMem(Addr, [0xC0,0xDE])',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'WriteMem "First" Arg must be Number',[]);
    Exit(JS_EXCEPTION);
  end;
  // TODO: Debug this :D .
  if JS_IsObject(argv[1]) then
  begin
    if JS_IsArray(ctx,argv[1]) > 0 then
    begin
      length := JS_GetPropertyStr(ctx,argv[1],'length');
      JS_ToInt32(ctx,@len,length);
      for i := 0 to Pred(len) do
      begin
        Element := JS_GetPropertyUint32(ctx,argv[1],i);
        if JS_IsNumber(Element) then
        begin
         JS_ToUint32(ctx,@val,Element);
         if Utils.WriteByte(Addr+i,val) then
           Result := JS_NewInt32(ctx,i)
         else
           Break;
        end;
      end;
    end
    else
      Exit(JS_EXCEPTION);
  end
  else
  begin
    JS_ThrowInternalError(ctx,'WriteMem "Second" Arg must be Array',[]);
    Exit(JS_EXCEPTION);
  end;
end;

function ReadByte(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
begin
  if argc <> 1 then
  begin
    JS_ThrowInternalError(ctx,'ReadByte take 1 arg - Ex: ReadByte(Addr : Number)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
      JS_ThrowInternalError(ctx,'ReadByte take 1 arg - Ex: ReadByte(Addr : Number) - And Should Be Number',[]);
      Exit(JS_EXCEPTION);
  end;
  Result := JS_NewInt32(ctx,Utils.ReadByte(Addr));
end;

function ReadWord(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
begin
  if argc <> 1 then
  begin
    JS_ThrowInternalError(ctx,'ReadWord take 1 arg - Ex: ReadWord(Addr : Number)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
      JS_ThrowInternalError(ctx,'ReadWord take 1 arg - Ex: ReadWord(Addr : Number) - And Should Be Number',[]);
      Exit(JS_EXCEPTION);
  end;
  Result := JS_NewInt32(ctx,Utils.ReadWord(Addr));
end;

function ReadDword(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
begin
  if argc <> 1 then
  begin
    JS_ThrowInternalError(ctx,'ReadDword take 1 arg - Ex: ReadDword(Addr : Number)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
      JS_ThrowInternalError(ctx,'ReadDword take 1 arg - Ex: ReadDword(Addr : Number) - And Should Be Number',[]);
      Exit(JS_EXCEPTION);
  end;
  Result := JS_NewInt32(ctx,Utils.ReadDword(Addr));
end;

function ReadQword(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
begin
  if argc <> 1 then
  begin
    JS_ThrowInternalError(ctx,'ReadQword take 1 arg - Ex: ReadQword(Addr : Number)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
      JS_ThrowInternalError(ctx,'ReadQword take 1 arg - Ex: ReadQword(Addr : Number) - And Should Be Number',[]);
      Exit(JS_EXCEPTION);
  end;
  Result := JS_NewInt64(ctx,Utils.ReadQword(Addr));
end;

function ReadMem(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
begin
  // TODO .
  JS_ThrowInternalError(ctx,'In my TODO list :D',[]);
  //JS_NewArrayBuffer(ctx,data,len,free_func_callback,moredata,is_shared);
  Result := JS_EXCEPTION;
end;

function push(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Value : Int64 = 0;
//=========================
 procedure RaiseError();
 begin
   JS_ThrowInternalError(ctx,'push take 1 arg - Ex: push(value : Number)',[]);
 end;
begin
  Result := JS_FALSE;
  if argc <> 1 then
  begin
     RaiseError(); Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Value,argv[0])
  else
  begin
      RaiseError(); Exit(JS_EXCEPTION);
  end;
  Result := JS_NewBool(ctx,utils.push(Value));
end;

function pop(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
begin
  Result := JS_NewInt64(ctx,utils.pop());
end;

function Stop(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
begin
  Emulator.Stop := true;
  Result := JS_TRUE;
end;

function LastError(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
begin
  Result := JS_NewString(ctx,uc_strerror(Emulator.err));
end;

function HexDump(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
  len  : UInt32 = 0;
  cols : byte = 0;
  tmp  : Pointer = nil;
begin
  if argc < 2 then
  begin
    JS_ThrowInternalError(ctx,'HexDump take at least two args - Ex: HexDump(Addr, len, nCols)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'HexDump "First" Arg must be Number - Ex: HexDump(Addr, len, nCols)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[1]) then
    JS_ToUint32(ctx,@len,argv[1])
  else
  begin
    JS_ThrowInternalError(ctx,'HexDump "Second" Arg must be Number - Ex: HexDump(Addr, len, nCols)',[]);
    Exit(JS_EXCEPTION);
  end;

  cols := 16; // the default .
  if argc = 3 then
  begin
   if JS_IsNumber(argv[2]) then
     JS_ToUint32(ctx,@cols,argv[2])
    else
    begin
      JS_ThrowInternalError(ctx,'HexDump "Third" Arg must be Number - Ex: HexDump(Addr, len, nCols)',[]);
      Exit(JS_EXCEPTION);
    end;
  end;

  if len > 0 then
  begin
    tmp := AllocMem(len);
    if tmp <> nil then
    begin
      Emulator.err := uc_mem_read_(Emulator.uc,addr,tmp,len);
      Utils.HexDump(tmp,len,addr,cols);
      Freemem(tmp,len);
    end;
  end
  else
  begin
    JS_ThrowInternalError(ctx,'Really 🧐  a len of "0" to Dump, Try Harder !',[]);
    Exit(JS_EXCEPTION);
  end;
  Result := JS_UNDEFINED;
end;

function StackDump(ctx : JSContext; this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Addr : Int64 = 0;
  len  : UInt32 = 0;
begin
  if argc < 2 then
  begin
    JS_ThrowInternalError(ctx,'StackDump takes two args - Ex: StackDump(Addr, len)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[0]) then
    JS_Toint64(ctx,@Addr,argv[0])
  else
  begin
    JS_ThrowInternalError(ctx,'StackDump "First" Arg must be Number - Ex: StackDump(Addr, len)',[]);
    Exit(JS_EXCEPTION);
  end;

  if JS_IsNumber(argv[1]) then
    JS_ToUint32(ctx,@len,argv[1])
  else
  begin
    JS_ThrowInternalError(ctx,'StackDump "Second" Arg must be Number - Ex: StackDump(Addr, len)',[]);
    Exit(JS_EXCEPTION);
  end;

  if len > 0 then
     Utils.DumpStack(addr,len)
  else
     Writeln('Really a len of "0" for StackDump !');

  Result := JS_UNDEFINED;
end;

end.


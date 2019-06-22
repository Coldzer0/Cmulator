unit JSEmuObj;

{$mode delphi}

interface

uses
  Classes, SysUtils,
  {$I besenunits.inc},
  FnHook,Emu,Utils,
  Unicorn_dyn, UnicornConst, X86Const,
  LazFileUtils,LazUTF8,PE_Loader;

type

{ TEmuObj }

TEmuObj = class
    { Register Stuff }
    procedure ReadReg(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure SetReg(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);


    { String things :P }
    procedure ReadStringA(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure ReadStringW(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);

    procedure WriteStringA(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure WriteStringW(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);

    { Emulator Modules }
    procedure LoadLibrary(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure GetModuleName(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure GetModuleHandle(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure GetProcAddress(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);

    { Memory things :D }
    procedure WriteByte(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure WriteWord(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure WriteDword(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure WriteQword(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure WriteMem(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);

    procedure ReadByte(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure ReadWord(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure ReadDword(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure ReadQword(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure ReadMem(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);

    { Stack }
    procedure push(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure pop(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);

    { Control Flow }
    procedure Stop(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure LastError(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);

    { Misc }
    procedure HexDump(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
    procedure StackDump(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);

end;

implementation
   uses
     Globals,math,JSPlugins_BEngine;

{ TEmuObj }

procedure TEmuObj.ReadReg(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Value : UInt64;
  REG : UInt32;
  JSValue : PBESENValue;
begin
  if CountArguments <> 1 then
    raise EBESENError.Create('GetReg take 1 arg - Ex: GetReg(REG_RAX)');

  JSValue := Arguments^[0];
  case JSValue^.ValueType of
    bvtNUMBER:
      begin
       REG := TBESEN(JS).ToInt(JSValue^)
      end;
  else
      raise EBESENError.Create('GetReg take 1 arg - Ex: GetReg(REG_RAX) - And Should Be Number');
      exit;
  end;
  Value := 0;
  Emulator.err := uc_reg_read(Emulator.uc,REG,@Value);
  ResultValue := BESENNumberValue(Value);
end;

procedure TEmuObj.SetReg(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  value : UInt64;
  REG : UInt32;
  JSvalue : PBESENValue;

  procedure Error();
  begin
    raise EBESENError.Create('SetReg take 2 arg - Ex: GetReg(REG_RAX,0x401000) - And Both Should Be Number');
  end;
begin
  if CountArguments <> 2 then
    raise EBESENError.Create('SetReg take 2 arg - Ex: SetReg(REG_RAX,0x401000)');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    REG := TBESEN(JS).ToInt(JSvalue^)
  else
    Error();

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtNUMBER then
    value := TBESEN(JS).ToInt(JSvalue^)
  else
    Error();

  Emulator.err := uc_reg_write(Emulator.uc,REG,@value);

  ResultValue := BESENBooleanValue(Emulator.err = UC_ERR_OK);
end;

procedure TEmuObj.ReadStringA(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  len  : UInt32;
  JSvalue : PBESENValue;
  procedure Error();
  begin
    raise EBESENError.Create('ReadStringA take 1 or 2 arg - Ex: ReadStringA(Addr) or ReadStringA(Addr,len)');
  end;
begin
  len := 0; Addr := 0;

  if CountArguments < 1 then
    raise EBESENError.Create('ReadStringA take 1 or 2 arg - Ex: ReadStringA(Addr) or ReadStringA(Addr,len)');


  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    Error();

  if CountArguments = 2 then
  begin
    JSvalue := Arguments^[1];
    if  JSvalue^.ValueType = bvtNUMBER then
      len := TBESEN(JS).ToInt(JSvalue^)
    else
      Error();
  end;

  ResultValue := BESENStringValue(BESENUTF8ToUTF16(Utils.ReadStringA(Addr,len)));
end;

procedure TEmuObj.ReadStringW(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  len  : UInt32;
  JSvalue : PBESENValue;
  procedure Error();
  begin
    raise EBESENError.Create('ReadStringW take 1 or 2 arg - Ex: ReadStringW(Addr) or ReadStringW(Addr,len)');
  end;
begin
  len := 0; Addr := 0;

  if CountArguments < 1 then
    raise EBESENError.Create('ReadStringW take 1 or 2 arg - Ex: ReadStringW(Addr) or ReadStringW(Addr,len)');


  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    Error();

  if CountArguments = 2 then
  begin
    JSvalue := Arguments^[1];
    if  JSvalue^.ValueType = bvtNUMBER then
      len := TBESEN(JS).ToInt(JSvalue^)
    else
      Error();
  end;

  ResultValue := BESENStringValue(BESENUTF8ToUTF16(Utils.ReadStringW(Addr,len)));
end;

procedure TEmuObj.WriteStringA(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Str : AnsiString;
  Addr : UInt64;
  JSvalue : PBESENValue;
begin
  if CountArguments <> 2 then
    raise EBESENError.Create('WriteStringA take 2 - Ex: WriteStringA(Addr, "plaplapla")');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('WriteStringA "First" Arg must be Number');

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtSTRING then
    Str := JSStringToStr(JSvalue^)
  else
    raise EBESENError.Create('WriteStringA "Second" Arg must be String');

  ResultValue := BESENNumberValue(Utils.WriteStringA(Addr,Str));
end;

procedure TEmuObj.WriteStringW(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Str : AnsiString;
  Addr : UInt64;
  JSvalue : PBESENValue;
begin
  if CountArguments <> 2 then
    raise EBESENError.Create('WriteStringW take 2 - Ex: WriteStringW(Addr, "plaplapla")');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('WriteStringA "First" Arg must be Number');

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtSTRING then
    Str := JSStringToStr(JSvalue^)
  else
    raise EBESENError.Create('WriteStringW "Second" Arg must be String');

  ResultValue := BESENNumberValue(Utils.WriteStringW(Addr,Str));
end;

procedure TEmuObj.LoadLibrary(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Libname : AnsiString;
  JSvalue : PBESENValue;
  Lib : TNewDll;
begin
  ResultValue := BESENNumberValue(0); // Default value = 0 ..
  if CountArguments = 1 then
  begin
    JSvalue := Arguments^[0];
    if  JSvalue^.ValueType = bvtSTRING then
      Libname := Trim(JSStringToStr(JSvalue^))
    else
      raise EBESENError.Create('LoadLibrary Arg must be String ! - Ex: LoadLibrary(''kernel32.dll'')');

    Libname := Trim(ExtractFileNameWithoutExt(LowerCase(ExtractFileName(Libname))) + '.dll');

    if Emulator.Libs.TryGetValue(Libname,Lib) then
    begin
      ResultValue := BESENNumberValue(Lib.BaseAddress);
    end
    else
    begin
      if PE_Loader.load_sys_dll(Emulator.uc,Libname) then
        if Emulator.Libs.TryGetValue(Libname,Lib) then
           ResultValue := BESENNumberValue(Lib.BaseAddress);
    end;
  end;
end;

procedure TEmuObj.GetModuleName(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Handle : UInt64;
  JSvalue : PBESENValue;
  Lib : TNewDll;
begin
  ResultValue := BESENNumberValue(0); // Default value = 0 ..
  if CountArguments = 1 then
  begin
    JSvalue := Arguments^[0];
    if  JSvalue^.ValueType = bvtNUMBER then
      Handle := TBESEN(JS).ToInt(JSvalue^)
    else
      raise EBESENError.Create('GetModuleName Arg must be Number !!!');

    if (Handle = 0) or (Handle = Emulator.Img.ImageBase) then
    begin
      ResultValue := BESENStringValue(BESENUTF8ToUTF16(ExtractFileName(Emulator.Img.FileName))); // Current PE ...
      exit;
    end;

    for Lib in Emulator.Libs.Values do
    begin
      if lib.BaseAddress = Handle then
      begin
           ResultValue := BESENStringValue(BESENUTF8ToUTF16(ExtractFileName(lib.Dllname)));
           break;
      end;
    end;
  end
  else
   ResultValue := BESENStringValue(BESENUTF8ToUTF16(ExtractFileName(Emulator.Img.FileName))); // Current PE ...
end;

procedure TEmuObj.GetModuleHandle(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Libname : AnsiString;
  JSvalue : PBESENValue;
begin
  ResultValue := BESENNumberValue(0); // Default value = 0 ..
  if CountArguments = 1 then
  begin
    JSvalue := Arguments^[0];
    if  JSvalue^.ValueType = bvtSTRING then
      Libname := Trim(JSStringToStr(JSvalue^))
    else
      raise EBESENError.Create('GetModuleHandle Arg must be String !!!');

    ResultValue := BESENNumberValue(Utils.GetModulehandle(Libname));
  end
  else
   ResultValue := BESENNumberValue(Emulator.Img.ImageBase); // Current PE ...
end;

procedure TEmuObj.GetProcAddress(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Handle : UInt64;
  FnName : AnsiString;
  JSvalue : PBESENValue;
begin
  ResultValue := BESENNumberValue(0); // Default value = 0 ..
  if CountArguments <> 2 then
    raise EBESENError.Create('GetProcAddr takes 2 Args Ex: Emu.GetProcAddr(handle,''MessageBoxA'')');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Handle := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('GetProcAddr First Arg must be Number !!!');

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtSTRING then
    FnName := Trim(JSStringToStr(JSvalue^))
  else
    raise EBESENError.Create('GetProcAddr Second Arg must be String !!!');

  // TODO: Add Search by Ordinal ..

  ResultValue := BESENNumberValue(GetProcAddr(Handle,FnName));
end;

procedure TEmuObj.WriteByte(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  value : byte;
  JSvalue : PBESENValue;
begin
  if CountArguments <> 2 then
    raise EBESENError.Create('WriteByte take 2 - Ex: WriteByte(Addr, 0x100)');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('WriteByte "First" Arg must be Number');

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtNUMBER then
    value := byte(TBESEN(JS).ToInt(JSvalue^))
  else
    raise EBESENError.Create('WriteByte "Second" Arg must be Number');

  ResultValue := BESENBooleanValue(Utils.WriteByte(Addr,value));
end;

procedure TEmuObj.WriteWord(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  value : Word;
  JSvalue : PBESENValue;
begin
  if CountArguments <> 2 then
    raise EBESENError.Create('WriteWord take 2 - Ex: WriteWord(Addr, 0x100)');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('WriteWord "First" Arg must be Number');

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtNUMBER then
    value := Word(TBESEN(JS).ToInt(JSvalue^))
  else
    raise EBESENError.Create('WriteWord "Second" Arg must be Number');

  ResultValue := BESENBooleanValue(Utils.WriteWord(Addr,value));
end;

procedure TEmuObj.WriteDword(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  value : Dword;
  JSvalue : PBESENValue;
begin
  if CountArguments <> 2 then
    raise EBESENError.Create('WriteDword take 2 - Ex: WriteDWord(Addr, 0x100)');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('WriteDword "First" Arg must be Number');

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtNUMBER then
    value := Dword(TBESEN(JS).ToInt(JSvalue^))
  else
    raise EBESENError.Create('WriteDword "Second" Arg must be Number');

  ResultValue := BESENBooleanValue(Utils.WriteDword(Addr,value));
end;

procedure TEmuObj.WriteQword(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  value : Qword;
  JSvalue : PBESENValue;
begin
  if CountArguments <> 2 then
    raise EBESENError.Create('WriteQword take 2 - Ex: WriteQword(Addr, 0x100)');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('WriteQword "First" Arg must be Number');

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtNUMBER then
    value := Qword(TBESEN(JS).ToInt(JSvalue^))
  else
    raise EBESENError.Create('WriteQword "Second" Arg must be Number');

  ResultValue := BESENBooleanValue(Utils.WriteQword(Addr,value));
end;

procedure TEmuObj.WriteMem(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  val : Byte;
  JSvalue : PBESENValue;
  Element : TBESENValue;
  i,len : Integer;
begin
  ResultValue := BESENBooleanValue(False);
  if CountArguments <> 2 then
    raise EBESENError.Create('WriteMem take 2 - Ex: WriteMem(Addr, [0xC0,0xDE])');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('WriteMem "First" Arg must be Number');

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtOBJECT then
  begin
    if TBESENObject(JSvalue.Obj) is TBESENObjectArray then
    begin
      Initialize(Element);
      len := TBESENObjectArray(JSvalue.Obj).Len;
      for i := 0 to Pred(len) do
      begin
        TBESENObjectArray(JSvalue.Obj).GetArrayIndex(i,Element);
         if Element.ValueType = bvtNUMBER then
         begin
           val := TBESEN(JS).ToInt(Element);
           if Utils.WriteByte(Addr+i,val) then
             ResultValue := BESENBooleanValue(True)
           else
             Break;
         end;
      end;
    end;
  end
  else
    raise EBESENError.Create('WriteMem "Second" Arg must be Array');
end;

procedure TEmuObj.ReadByte(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  JSValue : PBESENValue;
begin
  if CountArguments <> 1 then
    raise EBESENError.Create('ReadByte take 1 arg - Ex: ReadByte(Addr : Number)');

  JSValue := Arguments^[0];
  case JSValue^.ValueType of
    bvtNUMBER:
      begin
       Addr := TBESEN(JS).ToInt(JSValue^)
      end;
  else
      raise EBESENError.Create('ReadByte take 1 arg - Ex: ReadByte(Addr : Number) - And Should Be Number');
      exit;
  end;
  ResultValue := BESENNumberValue(Utils.ReadByte(Addr));
end;

procedure TEmuObj.ReadWord(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  JSValue : PBESENValue;
begin
  if CountArguments <> 1 then
    raise EBESENError.Create('ReadWord take 1 arg - Ex: ReadWord(Addr : Number)');

  JSValue := Arguments^[0];
  case JSValue^.ValueType of
    bvtNUMBER:
      begin
       Addr := TBESEN(JS).ToInt(JSValue^)
      end;
  else
      raise EBESENError.Create('ReadWord take 1 arg - Ex: ReadWord(Addr : Number) - And Should Be Number');
      exit;
  end;
  ResultValue := BESENNumberValue(Utils.ReadWord(Addr));
end;

procedure TEmuObj.ReadDword(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  JSValue : PBESENValue;
begin
  if CountArguments <> 1 then
    raise EBESENError.Create('ReadDword take 1 arg - Ex: ReadDword(Addr : Number)');

  JSValue := Arguments^[0];
  case JSValue^.ValueType of
    bvtNUMBER:
      begin
       Addr := TBESEN(JS).ToInt(JSValue^)
      end;
  else
      raise EBESENError.Create('ReadDword take 1 arg - Ex: ReadDword(Addr : Number) - And Should Be Number');
      exit;
  end;
  ResultValue := BESENNumberValue(Utils.ReadDword(Addr));
end;

procedure TEmuObj.ReadQword(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  JSValue : PBESENValue;
begin
  if CountArguments <> 1 then
    raise EBESENError.Create('ReadQword take 1 arg - Ex: ReadQword(Addr : Number)');

  JSValue := Arguments^[0];
  case JSValue^.ValueType of
    bvtNUMBER:
      begin
       Addr := TBESEN(JS).ToInt(JSValue^)
      end;
  else
      raise EBESENError.Create('ReadQword take 1 arg - Ex: ReadQword(Addr : Number) - And Should Be Number');
      exit;
  end;
  ResultValue := BESENNumberValue(Utils.ReadQword(Addr));
end;

procedure TEmuObj.ReadMem(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
begin
  // TODO .
end;

procedure TEmuObj.push(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Value : UInt64;
  JSValue : PBESENValue;
//=========================
 procedure RaiseError();
 begin
   raise EBESENError.Create('push take 1 arg - Ex: push(value : Number)');
 end;
begin
  ResultValue := BESENBooleanValue(False);
  if CountArguments <> 1 then
     RaiseError();

  JSValue := Arguments^[0];
  case JSValue^.ValueType of
    bvtNUMBER:
      begin
       Value := TBESEN(JS).ToInt(JSValue^)
      end;
  else
      RaiseError();
      exit;
  end;
  ResultValue := BESENBooleanValue(utils.push(Value));
end;

procedure TEmuObj.pop(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
begin
  ResultValue := BESENNumberValue(utils.pop());
end;

procedure TEmuObj.Stop(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
begin
  Emulator.Stop := true;
end;

procedure TEmuObj.LastError(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Error : AnsiString;
begin
  Error := uc_strerror(Emulator.err);
  ResultValue := BESENStringValue(BESENUTF8ToUTF16(Error));
end;

procedure TEmuObj.HexDump(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  len  : UInt32;
  cols : byte;
  tmp  : Pointer;
  JSvalue : PBESENValue;
begin
  if CountArguments < 2 then
    raise EBESENError.Create('HexDump take at least two args - Ex: HexDump(Addr, len, nCols)');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('HexDump "First" Arg must be Number - Ex: HexDump(Addr, len, nCols)');

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtNUMBER then
    len := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('HexDump "Second" Arg must be Number - Ex: HexDump(Addr, len, nCols)');

  cols := 16; // the default .
  if CountArguments = 3 then
  begin
    JSvalue := Arguments^[2];
    if  JSvalue^.ValueType = bvtNUMBER then
      cols := TBESEN(JS).ToInt(JSvalue^)
    else
      raise EBESENError.Create('HexDump "Third" Arg must be Number - Ex: HexDump(Addr, len, nCols)');
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
    raise EBESENError.Create('Dump! - 0 Really! :D');

  ResultValue.ValueType := bvtUNDEFINED;
end;

procedure TEmuObj.StackDump(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  Addr : UInt64;
  len  : UInt32;
  JSvalue : PBESENValue;
begin
  if CountArguments < 2 then
    raise EBESENError.Create('StackDump takes two args - Ex: StackDump(Addr, len)');

  JSvalue := Arguments^[0];
  if  JSvalue^.ValueType = bvtNUMBER then
    Addr := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('StackDump "First" Arg must be Number - Ex: StackDump(Addr, len)');

  JSvalue := Arguments^[1];
  if  JSvalue^.ValueType = bvtNUMBER then
    len := TBESEN(JS).ToInt(JSvalue^)
  else
    raise EBESENError.Create('StackDump "Second" Arg must be Number - Ex: StackDump(Addr, len)');

  if len > 0 then
     Utils.DumpStack(addr,len)
  else
     Writeln('Len is 0 so not StackDump :D !');

  ResultValue.ValueType := bvtUNDEFINED;
end;

end.


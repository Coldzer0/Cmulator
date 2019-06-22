unit JSPlugins_BEngine;

{$mode delphi}

interface

uses
  Classes,
  SysUtils,
  {$I besenunits.inc},
  Crt,LazFileUtils,xxHash;

type
   TBESENInstance = class;

   { TNewHook }

   TNewHook = class(TBESENNativeObject)
   private
     FOnEnter  : TBESENObjectFunction;
     FOnExit   : TBESENObjectFunction;
     Fargs     : TBESENObjectArray;
   protected
     procedure ConstructObject(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer); override;
   public
     destructor Destroy; override;
   published
     procedure install(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
     property OnCallBack : TBESENObjectFunction read FOnEnter write FOnEnter;
     property OnExit : TBESENObjectFunction read FOnExit write FOnExit;
     property args : TBESENObjectArray read Fargs write Fargs;
   end;

   { TBESENInstance }

   TBESENInstance = class(TBESEN)
   private
     procedure NativeImportScripts(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var ResultValue:TBESENValue);
   public
     ShuttingDown: Boolean;
     constructor Create();
     destructor Destroy; override;
     procedure LoadScript(filename : AnsiString);
     procedure InitJSEmu();
   end;


   { TLogSystem }

   TLogSystem = class
   public
     // Prints text in command line
     procedure log(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var AResult:TBESENValue);
     procedure info(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var AResult:TBESENValue);
     procedure warn(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var AResult:TBESENValue);
     procedure error(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var AResult:TBESENValue);
   end;


function JSStringToStr(JSString : TBESENValue) : AnsiString;

implementation
   uses
     Globals,JSEmuObj,FnHook,Emu,PE_Loader;

var
 LogSystem : TLogSystem;
 JSCmulator : TEmuObj;

function JSStringToStr(JSString : TBESENValue) : AnsiString;
begin
  Result := BESENEncodeString(BESENUTF16ToUTF8(TBESEN(JS).ToStr(JSString)),UTF_8,BESENLocaleCharset);
end;

{ TScriptSystem }
procedure Print(const ThisArgument:TBESENValue;Arguments:PPBESENValues;CountArguments:integer;var AResult:TBESENValue; color : Integer);
var i:integer;
    v:PBESENValue;
    fOutput:widestring;
 procedure writeit(s:widestring);
 begin
  fOutput:=fOutput+s;
 end;
begin
 fOutput:='';
 AResult.ValueType:=bvtUNDEFINED;
 for i:=0 to CountArguments-1 do begin
  v:=Arguments^[i];
  case v^.ValueType of
   bvtUNDEFINED:begin
    writeit('undefined');
   end;
   bvtNULL:begin
    writeit('null');
   end;
   bvtBOOLEAN:begin
    if v^.Bool then begin
     writeit('true');
    end else begin
     writeit('false');
    end;
   end;
   bvtNUMBER:begin
    writeit(BESENFloatToStr(v^.Num));
   end;
   bvtSTRING:begin
    writeit(v^.Str);
   end;
   bvtOBJECT:begin
    writeit(TBESEN(JS).ToStr(v^));
   end;
   bvtREFERENCE:begin
    writeit('reference');
   end;
  end;
 end;

 if Emulator.RunOnDll then Exit;

 if color >= 0 then
   TextColor(color);
 writeln(BESENEncodeString(BESENUTF16ToUTF8(fOutput),UTF_8,BESENLocaleCharset));
 NormVideo;
end;

procedure TLogSystem.log(const ThisArgument:TBESENValue;
  Arguments:PPBESENValues;CountArguments:integer;
  var AResult:TBESENValue);
begin
  Print(ThisArgument,Arguments,CountArguments,AResult,-1);
end;

procedure TLogSystem.info(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var AResult : TBESENValue);
begin
  Print(ThisArgument,Arguments,CountArguments,AResult,LightCyan);
end;

procedure TLogSystem.warn(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var AResult : TBESENValue);
begin
  Print(ThisArgument,Arguments,CountArguments,AResult,Yellow);
end;

procedure TLogSystem.error(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var AResult : TBESENValue);
begin
  Print(ThisArgument,Arguments,CountArguments,AResult,LightRed);
end;

{ TBESENInstance }

procedure TBESENInstance.NativeImportScripts(const ThisArgument: TBESENValue;
  Arguments: PPBESENValues; CountArguments: integer;
  var ResultValue: TBESENValue);
var
  i: Integer;
  filename : ansistring;
begin
  resultValue := BESENUndefinedValue;
  for i:=0 to CountArguments-1 do
  begin
    filename := IncludeTrailingPathDelimiter(ExtractFileDir(JSAPI)) + BESENUTF16ToUTF8(ToStr(Arguments^[i]^));

    if Verbose then
       Writeln('loading JS Hook Module : ',filename);

    if FileExists(filename) then
    begin
        try
           Execute(BESENGetFileContent(filename));
        except
           on e: EBESENError do
           begin
             WriteLn(Format('%s ( %s | Line %d ): %s', [e.Name, Filename, TBESEN(self).LineNumber, e.Message]));
             halt(-1);
           end;

           on e: exception do
           begin
             WriteLn(Format('%s ( %s | Line %d ): %s', ['Exception', Filename, TBESEN(self).LineNumber, e.Message]));
             halt(-1);
           end;
        end;
    end
    else
    begin
      Writeln(filename,' not found !');
      halt(0);
    end;
  end;
end;

constructor TBESENInstance.Create();
begin
  inherited Create(COMPAT_JS);
  ShuttingDown:=False;
  Self.InjectObject('console',{$ifndef BESENSingleStringType}BESENUTF16ToUTF8({$endif}BESENObjectConsoleSource{$ifndef BESENSingleStringType}){$endif});

  Self.RegisterNativeObject('ApiHook', TNewHook);

  LogSystem := TLogSystem.Create;
  JSCmulator := TEmuObj.Create;

  ObjectGlobal.RegisterNativeFunction('print', LogSystem.log, 1, []);
  ObjectGlobal.RegisterNativeFunction('log', LogSystem.log, 1, []);
  ObjectGlobal.RegisterNativeFunction('info', LogSystem.info, 1, []);
  ObjectGlobal.RegisterNativeFunction('warn', LogSystem.warn, 1, []);
  ObjectGlobal.RegisterNativeFunction('error', LogSystem.error, 1, []);

  ObjectGlobal.RegisterNativeFunction('importScripts',NativeImportScripts,0,[]);
end;

destructor TBESENInstance.Destroy;
begin
  ShuttingDown:=True;
  inherited Destroy;
end;

procedure TBESENInstance.LoadScript(filename : AnsiString);
begin
  if FileExists(filename) then
  begin
      Writeln('[+] Loading JS Main Script : ', JSAPI);
      try
         Execute(BESENGetFileContent(filename));
      except
         on e: EBESENError do
         begin
           WriteLn(Format('%s ( %s | Line %d ): %s', [e.Name, Filename, TBESEN(self).LineNumber, e.Message]));
           halt(12);
         end;
         on e: exception do
         begin
           WriteLn(Format('%s ( %s | Line %d ): %s', ['Exception', Filename, TBESEN(self).LineNumber, e.Message]));
           halt(13);
         end;
      end;
  end
  else
  begin
    Writeln('API.js not found !');
    halt(0);
  end;
  Writeln();
end;

procedure TBESENInstance.InitJSEmu();
begin

  JSEmu:=TBESENObject.Create(Self,TBESEN(Self).ObjectPrototype,false);
  TBESEN(Self).GarbageCollector.Add(JSEmu);

  JSEmu.OverwriteData('isx64',BESENBooleanValue(Emulator.isx64),[bopaCONFIGURABLE]);
  JSEmu.OverwriteData('ImageBase',BESENNumberValue(Emulator.img.ImageBase),[bopaCONFIGURABLE]);
  JSEmu.OverwriteData('TEB',BESENNumberValue(Emulator.TEB),[bopaCONFIGURABLE]);
  JSEmu.OverwriteData('PID',BESENNumberValue(Emulator.PID),[bopaCONFIGURABLE]);
  JSEmu.OverwriteData('Filename',BESENStringValue(BESENUTF8ToUTF16(ExtractFileName(Emulator.img.FileName))),[bopaCONFIGURABLE]);


  { Modules }
  JSEmu.RegisterNativeFunction('LoadLibrary',JSCmulator.LoadLibrary,1,[]);
  JSEmu.RegisterNativeFunction('GetModuleName',JSCmulator.GetModuleName,1,[]);
  JSEmu.RegisterNativeFunction('GetModuleHandle',JSCmulator.GetModuleHandle,1,[]);
  JSEmu.RegisterNativeFunction('GetProcAddr',JSCmulator.GetProcAddress,2,[]);

  { Registers }
  JSEmu.RegisterNativeFunction('ReadReg',JSCmulator.ReadReg,1,[]);
  JSEmu.RegisterNativeFunction('SetReg',JSCmulator.SetReg,2,[]);

  { Strings }
  JSEmu.RegisterNativeFunction('ReadStringA',JSCmulator.ReadStringA,2,[]);
  JSEmu.RegisterNativeFunction('ReadStringW',JSCmulator.ReadStringW,2,[]);
  JSEmu.RegisterNativeFunction('WriteStringA',JSCmulator.WriteStringA,2,[]);
  JSEmu.RegisterNativeFunction('WriteStringW',JSCmulator.WriteStringW,2,[]);

  { memory }
  JSEmu.RegisterNativeFunction('WriteByte' ,JSCmulator.WriteByte,2,[]);
  JSEmu.RegisterNativeFunction('WriteWord' ,JSCmulator.WriteWord,2,[]);
  JSEmu.RegisterNativeFunction('WriteDword',JSCmulator.WriteDword,2,[]);
  JSEmu.RegisterNativeFunction('WriteQword',JSCmulator.WriteQword,2,[]);
  JSEmu.RegisterNativeFunction('WriteMem'  ,JSCmulator.WriteMem,2,[]);

  JSEmu.RegisterNativeFunction('ReadByte',JSCmulator.ReadByte(),2,[]);
  JSEmu.RegisterNativeFunction('ReadWord',JSCmulator.ReadWord,2,[]);
  JSEmu.RegisterNativeFunction('ReadDword',JSCmulator.ReadDword,2,[]);
  JSEmu.RegisterNativeFunction('ReadQword',JSCmulator.ReadQword,2,[]);

  // TODO: Result = Array of bytes.
  JSEmu.RegisterNativeFunction('ReadMem'  ,JSCmulator.ReadMem,1,[]);


  { Stack }
  JSEmu.RegisterNativeFunction('push',JSCmulator.push,1,[]);
  JSEmu.RegisterNativeFunction('pop',JSCmulator.pop,0,[]);

  { Mics }
  JSEmu.RegisterNativeFunction('Stop',JSCmulator.Stop,0,[]);
  JSEmu.RegisterNativeFunction('LastError',JSCmulator.LastError,0,[]);

  { good stuff }
  JSEmu.RegisterNativeFunction('HexDump',JSCmulator.HexDump,3,[]);
  JSEmu.RegisterNativeFunction('StackDump',JSCmulator.StackDump,2,[]);



  // Register As Global Object
  TBESEN(Self).ObjectGlobal.OverwriteData('Emu',BESENObjectValue(JSEmu),[bopaCONFIGURABLE]);

  Self.GarbageCollector.Protect(TBESENObject(JSEmu));
end;


{ TNewHook }
procedure TNewHook.ConstructObject(const ThisArgument: TBESENValue;
  Arguments: PPBESENValues; CountArguments: integer);
begin
  FOnEnter := nil;
  FOnExit  := nil;
  args := TBESENObjectArray.Create(Self.Instance);
  inherited ConstructObject(ThisArgument,Arguments,CountArguments);
end;

destructor TNewHook.Destroy;
begin
  if Assigned(self.OnCallBack) then
     TBESEN(Instance).GarbageCollector.Unprotect(self.OnCallBack);
  inherited Destroy;
end;

procedure TNewHook.install(const ThisArgument : TBESENValue;
  Arguments : PPBESENValues; CountArguments : integer;
  var ResultValue : TBESENValue);
var
  API : TLibFunction;
  ExLib : TNewDll;
  Ordinal : UInt32;
  Address : UInt64;
  lib,name : AnsiString;
  value : PBESENValue;
  isOrdinal , isAddress : boolean;
begin
  lib := ''; name := '';

  ResultValue := BESENBooleanValue(False);

  if CountArguments <= 0  then
    raise EBESENError.Create('install expect args (libname,ApiName) or (libname,Ordinal) or (Address)');

  isAddress := False; isOrdinal := False;

  if CountArguments = 1 then
  begin
     isAddress := True;
     value := Arguments^[0];
     if value^.ValueType = bvtNUMBER then
     begin
       Address := TBESEN(Instance).ToInt(value^);
     end
     else
     begin
      raise EBESENError.Create('install as Address expect args (Address) to be Number');
      exit;
     end;
  end
  else
  if CountArguments = 2 then
  begin
    value := Arguments^[1];
    case value^.ValueType of
      bvtSTRING :
        begin
          lib  := JSStringToStr(Arguments^[0]^);
          name := Trim(JSStringToStr(value^));
        end;
      bvtNUMBER:
        begin
         isOrdinal := true;
         lib     := JSStringToStr(Arguments^[0]^);
         Ordinal := TBESEN(Instance).ToInt(value^)
        end;
    else
        raise EBESENError.Create('install expect args (libname, ApiName : string) or (libname : string; Ordinal : Number)');
        exit;
    end;
  end;

  if Assigned(self.OnCallBack) then
  begin
    TBESEN(Instance).GarbageCollector.Protect(self.OnCallBack);

    if isAddress then
    begin
      Emulator.Hooks.ByAddr.AddOrSetValue(Address,THookFunction.Create(
         '','',0,False,nil,Self));
    end
    else
    begin
     if lib.IsEmpty then exit; // just to make sure everything will work :D .

     lib := LowerCase(ExtractFileNameWithoutExt(ExtractFileName(lib)));

     if isOrdinal then
     begin
       Emulator.Hooks.ByOrdinal.AddOrSetValue(xxHash64Calc(lib + '.' + IntToStr(Ordinal)),THookFunction.Create(
                lib,name,Ordinal,isOrdinal,nil,Self));
     end
     else
     begin
      Emulator.Hooks.ByName.AddOrSetValue(xxHash64Calc(lib + '.' + name),THookFunction.Create(
         lib,name,Ordinal,isOrdinal,nil,Self
      ));
     end;
    end;

    ResultValue := BESENBooleanValue(True);
  end;
end;

end.


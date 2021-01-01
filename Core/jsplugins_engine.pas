unit JSPlugins_Engine;

//{$mode delphi}

interface

uses
  Classes,
  SysUtils,
  xxHash,
  quickjs;


var
  API_Class_id    : JSClassID = 0;
  API_Class_Proto : JSValue;
  JClass : JSClassDef = (class_name:'ApiHook';finalizer:nil;gc_mark:nil;call:nil;exotic:nil);

type
  FunctionListEntry  = array of JSCFunctionListEntry;
var
  tab : array of JSCFunctionListEntry;

procedure LoadScript(filename : PChar);

procedure Init_QJS;
procedure InitJSEmu;
procedure Uninit_JSEngine;

function eval_buf(ctx : JSContext; Buf : PChar; buf_len : Integer; filename : PChar; eval_flags : Integer): Integer;
function eval_file(ctx : JSContext; filename : PChar; eval_flags : Integer): Integer;

implementation
   uses
     Globals,JSEmuObj,FnHook,Emu,Utils;


function logme(ctx : JSContext; this_val : JSValueConst;
   argc : Integer; argv : PJSValueConstArr; magic : Integer): JSValue; cdecl;
var
 i : Integer;
 str : PChar;
begin
  if (Emulator.RunOnDll) and (magic <> 4) then
    Exit(JS_UNDEFINED);

 case magic of
   2:TextColor(LightCyan); // info.
   3:TextColor(Yellow);    // warn.
   4:TextColor(LightRed);  // error.
 end;

 for i := 0 to Pred(argc) do
 begin
    if i <> 0 then
      write(' ');
    str := JS_ToCString(ctx, argv[i]);
    if not Assigned(str) then
       exit(JS_EXCEPTION);
    Write(str);
    JS_FreeCString(ctx, str);
 end;
 Writeln();
 NormVideo;

 Result := JS_UNDEFINED;
end;

function eval_buf(ctx : JSContext; Buf : PChar; buf_len : Integer; filename : PChar; eval_flags : Integer): Integer; cdecl;
var
 val : JSValue;
begin
 val := JS_Eval(ctx, buf, buf_len, filename, eval_flags);
 if JS_IsException(val) then
 begin
   js_std_dump_error(ctx);
   Result := -1;
 end
 else
   Result := 0;

 JS_FreeValue(ctx, val);
end;

function eval_file(ctx : JSContext; filename : PChar; eval_flags : Integer): Integer; cdecl;
var
 buf_len : size_t;
 Buf : Pointer;
begin
 buf := js_load_file(ctx, @buf_len, filename);
 if not Assigned(buf) then
 begin
   js_std_dump_error(ctx);
   Writeln('Error While Loading : ',filename);
   exit(-1);
 end;
 Result := eval_buf(ctx, buf, buf_len, filename, eval_flags);
 js_free(ctx, buf);
end;

function NativeImportScripts(ctx : JSContext; {%H-}this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  i: Integer;
  filename : PChar;
begin
  Result := JS_UNDEFINED;
  for i:= 0 to Pred(argc) do
  begin
    filename := JS_ToCString(ctx,argv[i]);

     if Verbose then
       Writeln('loading JS Hook Module : ',filename);

    if FileExists(filename) then
    begin
      if eval_file(ctx,filename,JS_EVAL_TYPE_GLOBAL) < 0 then
         halt(-1);
    end
    else
    begin
      JS_ThrowReferenceError(ctx,'Could not load "%s"',[filename]);
      Result := JS_EXCEPTION;
    end;
    JS_FreeCString(ctx,filename);
  end;
end;

function install(ctx : JSContext; {%H-}this_val : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
var
  Ordinal : UInt32 = 0;
  Address : Int64 = 0;
  lib,name : PChar;
  isOrdinal , isAddress : boolean;
  OnCallBack, OnExit : JSValue;
begin
  lib := nil; name := nil;

  Result := JS_NewBool(ctx,False);

  if argc <= 0  then
  begin
    JS_ThrowInternalError(ctx,'install expect args (libname,ApiName) or (libname,Ordinal) or (Address)',[]);
    Exit(JS_EXCEPTION);
  end;

  isAddress := False; isOrdinal := False;

  if argc = 1 then
  begin
     isAddress := True;
    if JS_VALUE_GET_TAG(argv[0]) = JS_TAG_INT then
      JS_Toint64(ctx,@Address,argv[0])
     else
     begin
      JS_ThrowInternalError(ctx,'install as Address expect args (Address) to be Number',[]);
      Exit(JS_EXCEPTION);
     end;
  end
  else
  if argc = 2 then
  begin
    case JS_VALUE_GET_TAG(argv[1]) of
      JS_TAG_STRING :
        begin
          lib  := JS_ToCString(ctx,argv[0]);
          name := JS_ToCString(ctx,argv[1]);
        end;
      JS_TAG_INT:
        begin
         isOrdinal := true;
         lib     := JS_ToCString(ctx,argv[0]);
         JS_ToUint32(ctx,@Ordinal,argv[1]);
        end;
    else
        JS_ThrowInternalError(ctx,
        'install expect args (libname, ApiName : string) or (libname : string; Ordinal : Number)',[]);
        Exit(JS_EXCEPTION);
    end;
  end;

  OnCallBack := JS_GetPropertyStr(ctx,this_val,'OnCallBack');
  OnExit     := JS_GetPropertyStr(ctx,this_val,'OnExit');

  if JS_IsUndefined(OnCallBack) then
  begin
    JS_ThrowInternalError(ctx,'"OnCallBack must be set to install the hook"',[]);
    Exit(JS_EXCEPTION);
  end;
  if not JS_IsFunction(ctx,OnCallBack) then
  begin
    JS_ThrowInternalError(ctx,'"OnCallBack must be a function"',[]);
    Exit(JS_EXCEPTION);
  end;

  if not JS_IsUndefined(OnExit) then
  begin
    if not JS_IsFunction(ctx,OnCallBack) then
    begin
      JS_ThrowInternalError(ctx,'"OnExit must be a function"',[]);
      Exit(JS_EXCEPTION);
    end;
  end;

  if JS_IsObject(this_val) then
  begin

    if isAddress then
    begin
      Emulator.Hooks.ByAddr.AddOrSetValue(Address,THookFunction.Create(
         '','',0,False,nil,this_val,OnCallBack,OnExit));
    end
    else
    begin
     if lib = '' then exit; // just to make sure everything will work :D .

     lib := PChar(LowerCase(ExtractFileNameWithoutExt(ExtractFileName(lib))));

     if isOrdinal then
     begin
       Emulator.Hooks.ByOrdinal.AddOrSetValue(xxHash64Calc(lib + '.' + IntToStr(Ordinal)),THookFunction.Create(
                lib,name,Ordinal,isOrdinal,nil,this_val,OnCallBack,OnExit));
     end
     else
     begin
      Emulator.Hooks.ByName.AddOrSetValue(xxHash64Calc(lib + '.' + name),THookFunction.Create(
         lib,name,Ordinal,isOrdinal,nil,this_val,OnCallBack,OnExit
      ));
     end;
    end;

    Result := JS_NewBool(ctx,True);
  end;
end;

function CConstructor(ctx : JSContext; new_target : JSValueConst; argc : Integer; argv : PJSValueConstArr): JSValue; cdecl;
begin
  Result := JS_NewObjectProtoClass(ctx,API_Class_Proto,API_Class_id);
  // New Array for every new instance.
  JS_DefinePropertyValueStr(ctx,Result,'args',JS_NewArray(ctx),JS_PROP_CONFIGURABLE or JS_PROP_WRITABLE);
end;

procedure RegisterNativeClass(ctx : JSContext);
var
  obj,global : JSValue;
begin
  // Create New Class id.
  JS_NewClassID(@API_Class_id);
  // Create the Class Name and other stuff.
  JS_NewClass(JS_GetRuntime(ctx),API_Class_id,@JClass);

  // New Object act as Prototype for the Class.
  API_Class_Proto := JS_NewObject(ctx);

  JS_SetPropertyStr(ctx,API_Class_Proto,'install',JS_NewCFunction(ctx, @install, 'install', 2));

  // Set the Prototype to the Class.
  JS_SetClassProto(ctx, API_Class_id, API_Class_Proto);

  // Set the Class native constructor.
  obj := JS_NewCFunction2(ctx, @CConstructor, 'ApiHook', 1, JS_CFUNC_constructor, 0);

  // Add the Class to Global Object so we can use it.
  global := JS_GetGlobalObject(ctx);
  JS_SetPropertyStr(ctx,global,'ApiHook',obj);
  JS_FreeValue(ctx,global);
end;

procedure Init_QJS;
const
  std_hepler : PChar =
    'import * as std from ''std'';'#10+
    'import * as os from ''os'';'#10+
    'globalThis.std = std;'#10+
    'globalThis.os = os;'#10;
begin
  rt := JS_NewRuntime;
  if Assigned(rt) then
  begin
    ctx := JS_NewContext(rt);
    if Assigned(rt) then
    begin
      // ES6 Module loader.
      JS_SetModuleLoaderFunc(rt, nil, @js_module_loader, nil);

      js_std_add_helpers(ctx,argc,argv);
      js_init_module_std(ctx, 'std');
      js_init_module_os(ctx, 'os');

      // Register with global object directly .
      RegisterNativeClass(ctx);

      eval_buf(ctx, std_hepler, strlen(std_hepler), '<global_helper>', JS_EVAL_TYPE_MODULE);
      js_std_loop(ctx);
    end;
  end;
end;

procedure Uninit_JSEngine;
begin
  js_std_free_handlers(rt);
  JS_FreeContext(ctx);
  JS_FreeRuntime(rt);
end;

procedure LoadScript(filename : PChar);
begin
  if FileExists(filename) then
  begin
      Writeln('[+] Loading JS Main Script : ', JSAPI); Writeln();
      if eval_file(ctx,filename,JS_EVAL_TYPE_GLOBAL or JS_EVAL_TYPE_MODULE) < 0 then
      begin
        halt(99);
      end;
      js_std_loop(ctx); // I need to read the code of this func to make sure i will use it or not.
  end
  else
  begin
    Writeln('API.js not found !');
    halt(0);
  end;
  Writeln();
end;

procedure InitJSEmu();
var
  global, console : JSValue;
begin

  JSEmu := JS_NewObject(ctx);

  JS_DefinePropertyValueStr(ctx,JSEmu,'TEB',JS_NewInt64(ctx,Emulator.TEB),JS_PROP_CONFIGURABLE);
  JS_DefinePropertyValueStr(ctx,JSEmu,'PEB',JS_NewInt64(ctx,Emulator.PEB),JS_PROP_CONFIGURABLE);
  JS_DefinePropertyValueStr(ctx,JSEmu,'PID',JS_NewInt32(ctx,Emulator.PID),JS_PROP_CONFIGURABLE);
  JS_DefinePropertyValueStr(ctx,JSEmu,'isx64',JS_NewBool(ctx,Emulator.isx64),JS_PROP_CONFIGURABLE);
  JS_DefinePropertyValueStr(ctx,JSEmu,'ImageBase',JS_NewInt64(ctx,Emulator.img.ImageBase),JS_PROP_CONFIGURABLE);
  JS_DefinePropertyValueStr(ctx,JSEmu,'Filename',JS_NewString(ctx,PChar(ExtractFileName(Emulator.img.FileName))),JS_PROP_CONFIGURABLE);

  { Modules }
  tab := FunctionListEntry.create(
    JS_CFUNC_DEF('LoadLibrary',1,@JSEmuObj.LoadLibrary),
    JS_CFUNC_DEF('GetModuleName',1,@JSEmuObj.GetModuleName),
    JS_CFUNC_DEF('GetModuleHandle',1,@JSEmuObj.GetModuleHandle),
    JS_CFUNC_DEF('GetProcAddr',2,@JSEmuObj.GetProcAddress),

    { Registers }
    JS_CFUNC_DEF('ReadReg',1,@JSEmuObj.ReadReg),
    JS_CFUNC_DEF('SetReg',2,@JSEmuObj.SetReg),

    { Strings }
    JS_CFUNC_DEF('ReadStringA',2,@JSEmuObj.ReadStringA),
    JS_CFUNC_DEF('ReadStringW',2,@JSEmuObj.ReadStringW),
    JS_CFUNC_DEF('WriteStringA',2,@JSEmuObj.WriteStringA),
    JS_CFUNC_DEF('WriteStringW',2,@JSEmuObj.WriteStringW),

    { memory }
    JS_CFUNC_DEF('WriteByte' ,2,@JSEmuObj.WriteByte),
    JS_CFUNC_DEF('WriteWord' ,2,@JSEmuObj.WriteWord),
    JS_CFUNC_DEF('WriteDword',2,@JSEmuObj.WriteDword),
    JS_CFUNC_DEF('WriteQword',2,@JSEmuObj.WriteQword),
    JS_CFUNC_DEF('WriteMem'  ,2,@JSEmuObj.WriteMem),

    JS_CFUNC_DEF('ReadByte',1,@JSEmuObj.ReadByte),
    JS_CFUNC_DEF('ReadWord',1,@JSEmuObj.ReadWord),
    JS_CFUNC_DEF('ReadDword',1,@JSEmuObj.ReadDword),
    JS_CFUNC_DEF('ReadQword',1,@JSEmuObj.ReadQword),

    // TODO: Result = Array of bytes.
    JS_CFUNC_DEF('ReadMem',1,@JSEmuObj.ReadMem),


    { Stack }
    JS_CFUNC_DEF('push',1,@JSEmuObj.push),
    JS_CFUNC_DEF('pop',0,@JSEmuObj.pop),

    { Mics }
    JS_CFUNC_DEF('Stop',0,@JSEmuObj.Stop),
    JS_CFUNC_DEF('LastError',0,@JSEmuObj.LastError),

    { good stuff }
    JS_CFUNC_DEF('HexDump',3,@JSEmuObj.HexDump),
    JS_CFUNC_DEF('StackDump',2,@JSEmuObj.StackDump)
  );
  // Set list of Properties to the prototype Object.
  JS_SetPropertyFunctionList(ctx,JSEmu,@tab[0],Length(tab));

  // Register As Global Object
  global := JS_GetGlobalObject(ctx);
  JS_SetPropertyStr(ctx,global,'Emu',JSEmu);

  // override the console object with Ours.
  console := JS_NewObject(ctx);
  JS_SetPropertyStr(ctx, console, 'log',JS_NewCFunctionMagic(ctx, @logme, 'log', 1,JS_CFUNC_generic_magic, 1));
  JS_SetPropertyStr(ctx, global, 'console', console);

  // Define all log functions with magic number to handle coloring :D .
  JS_SetPropertyStr(ctx,global,'print',JS_NewCFunctionMagic(ctx, @logme, 'print', 1,JS_CFUNC_generic_magic, 0));
  JS_SetPropertyStr(ctx,global,'log',JS_NewCFunctionMagic(ctx, @logme, 'log', 1,JS_CFUNC_generic_magic, 1));
  JS_SetPropertyStr(ctx,global,'info',JS_NewCFunctionMagic(ctx, @logme, 'info', 1,JS_CFUNC_generic_magic, 2));
  JS_SetPropertyStr(ctx,global,'warn',JS_NewCFunctionMagic(ctx, @logme, 'warn', 1,JS_CFUNC_generic_magic, 3));
  JS_SetPropertyStr(ctx,global,'error',JS_NewCFunctionMagic(ctx, @logme, 'error', 1,JS_CFUNC_generic_magic, 4));

  JS_SetPropertyStr(ctx,global,'importScripts',JS_NewCFunction(ctx, @NativeImportScripts, 'importScripts', 1));
  JS_FreeValue(ctx, global);
end;

end.

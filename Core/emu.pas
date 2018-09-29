unit Emu;

{$IFDEF FPC}
    {$MODE Delphi}
    {$PackRecords C}
{$ENDIF}

interface

uses
  Classes, SysUtils,cmem,Crt,
  strutils,LazUTF8,math,
  Unicorn_dyn , UnicornConst, X86Const,
  Capstone,
  Segments,Utils,PE_loader,
  PE.Image,
  PE.Section,
  PE.ExportSym,
  FnHook,TEP_PEB,
  {$i besenunits.inc},
  Generics.Collections,EThreads;

type
  TLibs = TFastHashMap<String, TNewDll>;

  TOnExit = TFastHashMap<DWORD, THookFunction>;

  THookByName = TFastHashMap<String, THookFunction>;
  THookByOrdinal = TFastHashMap<DWORD, THookFunction>;

  THooks = record
    ByName : THookByName;
    ByOrdinal : THookByOrdinal;
  end;

{ TEmu }
  TEmu = class
  private
    CPU_MODE : uc_mode;
    FilePath, Shellcode : String;
    Is_x64, IsSC, Stop_Emu : Boolean;

    Ferr : uc_err;

    // Segments things :D .
    gdt : PSegmentDescriptor;
    gdt_address,
    TEB_Address,
    PEB_address,
    fs_address,
    gs_address : UInt64;
    gdtr : uc_x86_mmr;

    // x32 registers .
    r_eax,r_ecx,r_edx,r_ebx,r_esp,r_ebp,r_esi,r_edi,r_eip : DWORD;
    // x64 registers .
    r_rax,r_rcx,r_rdx,r_rbx,r_rsp,r_rbp,r_rsi,r_rdi,r_rip : UInt64;

    PE,SCode : TMemoryStream;
    MapedPE : Pointer;

    // Handle Dlls and it's Memory .
    FLibs : TLibs;
    FHooks : THookByName;

    OnExitList : TOnExit;
  public
    LastGoodPC : UInt64;
    Flags : TFlags;
    r_cs,r_ss,r_ds,r_es,r_fs,r_gs : DWORD;

    MemFix : TStack<UInt64>;

    RunOnDll, IsException : Boolean;
    SEH_Handler : Int64;

    DLL_BASE_LOAD,
    DLL_NEXT_LOAD : UInt64;

    stack_size : Cardinal;
    stack_base,stack_limit : UInt64;

    Img: TPEImage;
    uc : uc_engine;

    Hooks : THooks;

    property TEB : UInt64 read TEB_Address write TEB_Address;
    property Libs : TLibs read FLibs write FLibs;
    property PE_x64 : boolean read Is_x64;
    property isShellCode : Boolean read IsSC write IsSC;
    property Stop : boolean read Stop_Emu write Stop_Emu;
    property err : uc_err read Ferr write Ferr;

    procedure SetHooks();
    function MapPEtoUC() : Boolean;
    procedure Start();
    procedure ResetEFLAGS();
    function init_segments() : boolean;
    function GetGDT(index : Integer): Pointer;
    constructor Create(_FilePath : string; _Shellcode, SCx64 : Boolean); virtual;
    destructor Destroy(); override;
  end;

var
  Ident : Cardinal = 0;
  lastExceptionHandler : UInt64 = 0;

implementation
  uses
    Globals,NativeHooks;

function Handle_SEH(uc : uc_engine; ExceptionCode : DWORD): Boolean;
var
  ZwContinue , PC , Zer0 , Old_ESP , New_ESP : UInt64;
  SEH , SEH_Handler : Int64;
  i : UInt32;
  // TODO : x64 EXCEPTION_RECORD &  CONTEXT ...
  ExceptionRecord : EXCEPTION_RECORD_32;
  ContextRecord : CONTEXT_32;

  ExceptionRecord_Addr , ContextRecord_Addr : UInt64;
begin
  SEH := 0; PC := 0; ZwContinue := 0; Zer0 := 0; Old_ESP := 0; New_ESP := 0;

  Emulator.err := uc_reg_read(uc, ifthen(Emulator.PE_x64,UC_X86_REG_RSP,UC_X86_REG_ESP), @Old_ESP);

  Emulator.err := uc_reg_read(uc, ifthen(Emulator.Is_x64,UC_X86_REG_RIP,UC_X86_REG_EIP), @PC);
  ZwContinue := Utils.GetProcAddr(Utils.GetModulehandle('ntdll'),'ZwContinue');

  SEH := ReadDword(Emulator.TEB);
  if Emulator.err <> UC_ERR_OK then
    Exit(False);

  if (SEH = 0) or
     (SEH = $FFFFFFFFFFFFFFFF) then
     Exit(False);

  SEH_Handler := ReadDword(SEH+4);
  if Emulator.err <> UC_ERR_OK then
    Exit(False);

  if (SEH_Handler = 0) or
     (SEH_Handler = $FFFFFFFF) then
     Exit(False);


  Emulator.SEH_Handler := SEH_Handler;

  if SEH_Handler <> lastExceptionHandler then
     lastExceptionHandler := SEH_Handler
  else
  begin
    // TODO: walk the SEH Chain .
  end;

  if VerboseExcp then
  begin
    TextColor(Yellow);
    Writeln(Format('0x%x Exception caught SEH 0x%x - Handler 0x%x',[PC,SEH,SEH_Handler]));
    NormVideo;
  end;

  // Space for the "EXCEPTION_POINTERS" .
  for i := 0 to Pred(376) do
  begin
    Utils.push(0);
  end;

  Emulator.err := uc_reg_read(uc, ifthen(Emulator.Is_x64,UC_X86_REG_RSP,UC_X86_REG_ESP), @New_ESP);

  Initialize(ExceptionRecord);
  FillByte(ExceptionRecord,SizeOf(ExceptionRecord),0);
  ExceptionRecord.ExceptionCode := ExceptionCode;
  ExceptionRecord.ExceptionFlags := 0;
  ExceptionRecord.ExceptionRecord := 0;
  ExceptionRecord.ExceptionAddress := PC;
  ExceptionRecord.NumberParameters := 0; // TODO .

  Initialize(ContextRecord);
  FillByte(ContextRecord,SizeOf(ContextRecord),0);
  ContextRecord.ContextFlags := $1007F; // taken from Debuggers while testing :D //
  // TODO : Save FLOATING_SAVE_AREA ..
  ContextRecord.SegGs := Emulator.r_gs;
  ContextRecord.SegFs := Emulator.r_fs;
  ContextRecord.SegEs := Emulator.r_es;
  ContextRecord.SegDs := Emulator.r_ds;

  ContextRecord.Edi := reg_read_x32(uc,UC_X86_REG_EDI);
  ContextRecord.Esi := reg_read_x32(uc,UC_X86_REG_ESI);
  ContextRecord.Ebx := reg_read_x32(uc,UC_X86_REG_EBX);
  ContextRecord.Edx := reg_read_x32(uc,UC_X86_REG_EDX);
  ContextRecord.Ecx := reg_read_x32(uc,UC_X86_REG_ECX);
  ContextRecord.Eax := reg_read_x32(uc,UC_X86_REG_EAX);
  ContextRecord.Ebp := reg_read_x32(uc,UC_X86_REG_EBP);
  ContextRecord.Eip := DWORD(Emulator.LastGoodPC);
  ContextRecord.SegCs  := Emulator.r_cs;
  ContextRecord.EFlags := DWORD(reg_read_x64(uc,UC_X86_REG_EFLAGS));
  ContextRecord.Esp    := Old_ESP;
  ContextRecord.SegSs  := Emulator.r_ss;

  ExceptionRecord_Addr := New_ESP + 32;
  ContextRecord_Addr := ExceptionRecord_Addr + SizeOf(EXCEPTION_RECORD_32);

  Emulator.err := uc_mem_write_(uc,ExceptionRecord_Addr,@ExceptionRecord,SizeOf(ExceptionRecord));

  Emulator.err := uc_mem_write_(uc,ContextRecord_Addr,@ContextRecord,SizeOf(ContextRecord));

  Utils.push(ContextRecord_Addr); // ContextRecord ..
  Utils.push(Old_ESP);
  Utils.push(ExceptionRecord_Addr); // ExceptionRecord ..
  Utils.push(ZwContinue); // ZwContinue to set Context .

  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RAX,UC_X86_REG_EAX),@Zer0);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RBX,UC_X86_REG_EBX),@Zer0);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RSI,UC_X86_REG_ESI),@Zer0);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RDI,UC_X86_REG_EDI),@Zer0);

  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RCX,UC_X86_REG_ECX),@SEH_Handler);

  if ExceptionCode = EXCEPTION_ACCESS_VIOLATION then
     Emulator.err := uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RIP,UC_X86_REG_EIP),@Emulator.SEH_Handler)
  else
     Emulator.IsException := True;

  Result := True; // Check if everything is ok :D ...
end;

function HookMemInvalid(uc: uc_engine; _type: uc_mem_type; address: UInt64; size: Cardinal; value: Int64; user_data: Pointer): Boolean; cdecl;
begin
  if Emulator.Stop then exit;

  TextColor(LightRed);
  case _type of
    UC_MEM_WRITE_UNMAPPED:
      begin
        if not Emulator.RunOnDll then
        begin

          if VerboseExcp then
          begin
            TextColor(LightCyan);
            WriteLn(Format('>>> EXCEPTION_ACCESS_VIOLATION WRITE_UNMAPPED at 0x%x, data size = %u, data value = 0x%x', [address, size, value]));
            NormVideo;
          end;

          if Handle_SEH(uc,EXCEPTION_ACCESS_VIOLATION) then
          begin
            uc_mem_map(uc, address, $1000, UC_PROT_ALL);
            Emulator.MemFix.Push(address);
            Result := True;
          end;
        end;
      end;
    UC_MEM_READ_UNMAPPED:
      begin
        if not Emulator.RunOnDll then
        begin

          if VerboseExcp then
          begin
            TextColor(LightCyan);
            WriteLn(Format('EXCEPTION_ACCESS_VIOLATION READ_UNMAPPED : addr 0x%x, data size = %u, data value = 0x%x', [address, size, value]));
            NormVideo;
          end;

          if Handle_SEH(uc,EXCEPTION_ACCESS_VIOLATION) then
          begin
            uc_mem_map(uc, address, $1000, UC_PROT_ALL);
            Emulator.MemFix.Push(address);
            Result := True;
          end;
        end;
      end;
    UC_ERR_FETCH_UNMAPPED:
      begin
        if not Emulator.RunOnDll then
           WriteLn(Format('>>> UC_ERR_FETCH_UNMAPPED : addr 0x%x, data size = %u, data value = 0x%x', [address, size, value]));
      end;
    UC_ERR_EXCEPTION:
      begin
           if (address <> $DEADC0DE) and (not Emulator.RunOnDll) then
           WriteLn(Format('>>> UC_ERR_EXCEPTION : addr 0x%x, data size = %u, data value = 0x%x', [address, size, value]));
      end;
    else
      begin
        if not Emulator.RunOnDll then
        begin
          WriteLn(Format('>>> Errrrror : addr 0x%x, data size = %u, data value = 0x%x - Type %d ',
          [address, size, value, _type]));
        end;

        // return false to indicate we want to stop emulation
        Result := false;
      end;
  end;
  NormVideo;
end;

procedure HookMemX86(uc: uc_engine; _type: uc_mem_type; address: UInt64; size: Cardinal; value: Int64; user_data: Pointer); cdecl;
var
  val : UInt64;
begin
  //if not VerboseEx then Exit;
  if Emulator.Stop then exit;
  case _type of
    UC_MEM_READ:
      begin
        if (not Emulator.RunOnDll) then
          if (address < Emulator.gs_address+$3000) and (address > Emulator.PEB_address )
             or
             (address < Emulator.fs_address+$3000) and (address > Emulator.PEB_address )
           //or (address >= Emulator.Img.ImageBase) and (address <= Emulator.Img.ImageBase + $1000)
          then
          begin
            val := 0;
            uc_mem_read_(uc,address,@val,size);
            WriteLn(Format('>>> Memory is being READ at 0x%x, data size = %u, data value = 0x%x', [address, size, val]));
          end;
      end;
    UC_MEM_WRITE:
      begin
        if (not Emulator.RunOnDll) then
          if (address < Emulator.gs_address+$3000) and (address > Emulator.PEB_address) then
            WriteLn(Format('>>> Memory is being WRITE at 0x%x, data size = %u, data value = 0x%x', [address, size, value]));
      end;
  end;
end;

function CallJS(API : TLibFunction; Hook : THookFunction ;ret : UInt64) : boolean;
var
  a: array[0..2] of PBESENValue;
  JSEmuObj, JSAPIObj, return, AResult : TBESENValue;
  JSAPI : TBESENObject;
  isEx : Boolean;
begin
  Result := False;

  if Assigned(JS) and Assigned(Hook.JSHook) and Assigned(Hook.JSHook.OnCallBack) then
  begin
    //Writeln(#10'====================== CallBack to JS =========================='#10);

    JSAPI := TBESENObject.Create(JS,TBESEN(JS).ObjectPrototype,false);
    TBESEN(JS).GarbageCollector.Add(JSAPI);

    isEx := API.FuncName.EndsWith('Ex') or
            API.FuncName.EndsWith('ExA') or
            API.FuncName.EndsWith('ExW');

    JSAPI.OverwriteData('IsEx',BESENBooleanValue(isEx),[bopaCONFIGURABLE]);
    JSAPI.OverwriteData('IsWapi',BESENBooleanValue(API.FuncName.EndsWith('W')),[bopaCONFIGURABLE]);
    JSAPI.OverwriteData('IsFW',BESENBooleanValue(API.IsForwarder),[bopaCONFIGURABLE]);
    JSAPI.OverwriteData('LibName',BESENStringValue(BESENUTF8ToUTF16(API.LibName)),[bopaCONFIGURABLE]);
    JSAPI.OverwriteData('name',  BESENStringValue(BESENUTF8ToUTF16(API.FuncName)),[bopaCONFIGURABLE]);
    JSAPI.OverwriteData('FWName',BESENStringValue(BESENUTF8ToUTF16(API.FWName)),[bopaCONFIGURABLE]);
    JSAPI.OverwriteData('Address',BESENNumberValue(API.VAddress),[bopaCONFIGURABLE]);
    JSAPI.OverwriteData('Ordinal',BESENNumberValue(API.ordinal),[bopaCONFIGURABLE]);
    TBESEN(JS).GarbageCollector.Protect(TBESENObject(JSAPI));

    a[0]:=@JSEmuObj;
    a[1]:=@JSAPIObj;
    a[2]:=@return;

    JSEmuObj := BESENObjectValue(TBESENObject(JSEmu));
    JSAPIObj := BESENObjectValue(TBESENObject(JSAPI));
    return   := BESENNumberValue(ret);

    try
       AResult.ValueType := bvtBOOLEAN;
       Hook.JSHook.OnCallBack.Call(BESENObjectValue(Hook.JSHook.OnCallBack), @a, 3, AResult);
    except
       on e: EBESENError do
       begin
         WriteLn(Format('%s ( Line %d ): %s', [e.Name, TBESEN(JS).LineNumber, e.Message]));
         halt(-1);
       end;

       on e: exception do
       begin
         WriteLn(Format('%s ( Line %d ): %s', ['Exception', TBESEN(JS).LineNumber, e.Message]));
         halt(-1);
       end;
    end;
    if AResult.ValueType = bvtBOOLEAN then
    begin
      if VerboseEx and (not Emulator.RunOnDll) then
         Writeln('JS Return : ' ,BoolToStr(Boolean(AResult.Bool),'True','False'));

      Result := Boolean(AResult.Bool);
    end;
    TBESEN(JS).GarbageCollector.Unprotect(TBESENObject(JSAPI));
    FreeAndNil(JSAPI);

    //Writeln(#10'================================================================'#10);
  end;
end;

function CheckHook(uc : uc_engine ; PC : UInt64) : Boolean;
var
  lib  : TNewDll;
  API  : TLibFunction;
  Hook : THookFunction;
  APIHandled : Boolean;
  ret : UInt64;
begin
  ret := 0;
  Result := False; APIHandled := False;
  for lib in Emulator.Libs.Values do
  begin                                                                      // todo remove after implementing apischemia redirect .
    if (PC > lib.BaseAddress) and (PC < (lib.BaseAddress + lib.ImageSize)) or ( (PC >= $30000) and (PC < $EFFFF) ) then
    begin
      if lib.FnByAddr.TryGetValue(PC,API) then
      begin
        // this's here cuz in some cases we don't let the API go far to the ret :D .
        if not Emulator.RunOnDll then
           Ident -= 3;

        Emulator.err := uc_reg_read(uc,ifthen(Emulator.Is_x64,UC_X86_REG_RSP,UC_X86_REG_ESP),@ret);
        Emulator.err := uc_mem_read_(uc,ret,@ret,Emulator.Img.ImageWordSize);

        if API.IsOrdinal then
           Emulator.Hooks.ByOrdinal.TryGetValue(API.ordinal,Hook)
        else
        begin
          Emulator.Hooks.ByName.TryGetValue(API.FuncName, Hook);
          {
            This Check is for Ordinal Hook for normal API with Exported name
            like "LoadLibraryA" - ORDINAL = 829 .
            so the first Check by name will fail so we need to Check the
              Ordinal One :D .
          }
          if (Hook.FuncName.IsEmpty) and  (Hook.ordinal = 0) then
            Emulator.Hooks.ByOrdinal.TryGetValue(API.ordinal,Hook);
        end;

        API.Hits += 1; // how many times this API Called .API
        API.Return := ret; // the Return Address used for OnExit CallBack .
        if Assigned(Hook.JSHook) and Assigned(Hook.JSHook.OnExit) then
        begin
          Hook.API := API;
          Emulator.OnExitList.AddOrSetValue(ret,Hook);
        end;

        Result := True;

        if Verbose and (not Emulator.RunOnDll) then
        begin
          WriteLn(Format(#10'[+] Call to "%s.%s"',[API.LibName,IfThen(API.FuncName<>'',API.FuncName,'#'+hexStr(API.ordinal,3))]));
          Writeln(Format('[#] Will Return to : 0x%x',[ret]));
          if Api.IsForwarder then
          begin
            Writeln(Format('[!] "%s" is Forwarded to : "%s"',[IfThen(API.FuncName<>'',API.FuncName,'#'+hexStr(API.ordinal,3)),API.FWName]));
          end;
        end;

        if (Hook.JSHook <> nil) then
        begin
          APIHandled := CallJS(Api,Hook,ret);
          // TODO: Check for Native CallBack :D ..
        end
        else if (Hook.NativeCallBack <> nil) then
        begin
          APIHandled := TFnCallBack(Hook.NativeCallBack)(uc,PC,ret);
        end
        else
        begin
          if (API.FuncName <> 'ExitProcess') and (not Emulator.RunOnDll) then
          begin
            TextColor(Crt.LightRed);
            Writeln();
            WriteLn(Format('[x] UnHooked Call to %s.%-30s',[API.LibName,IfThen(API.FuncName<>'',API.FuncName,'#'+hexStr(API.ordinal,3))]));
            Writeln(Format('[#] Will Return to : 0x%x',[ret]));
            Writeln('!!! Stack Pointer May get Corrupted '#10);
            NormVideo;
          end;
        end;

        if (API.FuncName = 'ExitProcess') and (not APIHandled) then
        begin
          Emulator.Stop := True;
          break;
        end;
        if (not Emulator.Stop) then
        begin
          if not APIHandled then
          begin
            //====================== Fix Stack Pointer ================================//
            Utils.pop(); // but this may Corrupt the Stack
            //=========================================================================//
            Emulator.err := uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RIP,UC_X86_REG_EIP),@ret);
          end;
        end;
        break;
      end
      //else
      //begin
      //  if not Emulator.RunOnDll then
      //  begin
      //    TextColor(LightMagenta);
      //    Writeln(Format('Code Run Inside "%s" Hidden at 0x%x - From 0x%x',[lib.Dllname,PC,ret]));
      //    NormVideo;
      //  end;
      //end;
    end;
  end;
end;

procedure CheckOnExitCallBack(IsAPI : boolean; PC : UInt64);
var
  Args : array[0..2] of PBESENValue;
  JSAPI : TBESENObject;
  JSEmuObj, JSAPIObj, AResult : TBESENValue;
  Hook : THookFunction;
  isEx : Boolean;
begin
  // Check if it's no an API Call :D just to make sure .
  if (not IsAPI) then
  if Emulator.OnExitList.TryGetValue(PC,Hook) then
  if Assigned(Hook.JSHook) and Assigned(JS) then // Check if an API already Called .
  begin
    if Hook.API.Return = PC then
    begin
      if Assigned(Hook.JSHook.OnExit) then // check if we have OnExit Callback .
      begin
        JSAPI := TBESENObject.Create(JS,TBESEN(JS).ObjectPrototype,false);
        TBESEN(JS).GarbageCollector.Add(JSAPI);

        isEx := Hook.API.FuncName.EndsWith('Ex') or Hook.API.FuncName.EndsWith('ExA') or Hook.API.FuncName.EndsWith('ExW');
        JSAPI.OverwriteData('IsEx',BESENBooleanValue(isEx),[bopaCONFIGURABLE]);
        JSAPI.OverwriteData('IsWapi',BESENBooleanValue(Hook.API.FuncName.EndsWith('W')),[bopaCONFIGURABLE]);
        JSAPI.OverwriteData('IsFW',BESENBooleanValue(Hook.API.IsForwarder),[bopaCONFIGURABLE]);
        JSAPI.OverwriteData('LibName',BESENStringValue(BESENUTF8ToUTF16(Hook.API.LibName)),[bopaCONFIGURABLE]);
        JSAPI.OverwriteData('name',  BESENStringValue(BESENUTF8ToUTF16(Hook.API.FuncName)),[bopaCONFIGURABLE]);
        JSAPI.OverwriteData('FWName',BESENStringValue(BESENUTF8ToUTF16(Hook.API.FWName)),[bopaCONFIGURABLE]);
        JSAPI.OverwriteData('Address',BESENNumberValue(Hook.API.VAddress),[bopaCONFIGURABLE]);
        JSAPI.OverwriteData('Ordinal',BESENNumberValue(Hook.API.ordinal),[bopaCONFIGURABLE]);
        TBESEN(JS).GarbageCollector.Protect(TBESENObject(JSAPI));

        Args[0]:=@JSEmuObj;
        Args[1]:=@JSAPIObj;

        JSEmuObj := BESENObjectValue(TBESENObject(JSEmu));
        JSAPIObj := BESENObjectValue(TBESENObject(JSAPI));

        try
           AResult.ValueType := bvtBOOLEAN;
           Hook.JSHook.OnExit.Call(BESENObjectValue(Hook.JSHook.OnExit), @Args, 2, AResult);
        except
           on e: EBESENError do
           begin
             WriteLn(Format('%s ( Line %d ): %s', [e.Name, TBESEN(JS).LineNumber, e.Message]));
             halt(-1);
           end;

           on e: exception do
           begin
             WriteLn(Format('%s ( Line %d ): %s', ['Exception', TBESEN(JS).LineNumber, e.Message]));
             halt(-1);
           end;
        end;
        TBESEN(JS).GarbageCollector.Unprotect(TBESENObject(JSAPI));
        FreeAndNil(JSAPI);
      end;
    end;
  end;
end;

procedure HookCode(uc: uc_engine; address: UInt64; size: Cardinal; user_data: Pointer); cdecl;
var
  PC , tmp : UInt64;
  code : Array [0..49] of byte; // 50 is good for asm ins .
  IsAPI : boolean;
  ins : TCsInsn;
  cmd : string;
  FixAddr : UInt64;
begin
  PC := 0;  FixAddr := 0;
  IsAPI := False;

  if Emulator.MemFix.Count > 0 then
  begin
    for FixAddr in Emulator.MemFix do
    begin
      uc_mem_unmap(uc,FixAddr,$1000);
    end;
  end;

  if Emulator.IsException then
  begin
    Emulator.err := uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RIP,UC_X86_REG_EIP),@Emulator.SEH_Handler);
    Emulator.IsException := False;
    Exit;
  end;

  if Steps_limit <> 0 then
    if Steps >= Steps_limit then
       Emulator.Stop := True;

  if Emulator.Stop then
  begin
    Emulator.err := uc_emu_stop(uc);
    exit;
  end;
  // Get PC (EIP - RIP) and - ESP Value .
  Emulator.err := uc_reg_read(uc, ifthen(Emulator.Is_x64,UC_X86_REG_RIP,UC_X86_REG_EIP), @PC);
  Emulator.LastGoodPC := PC;

  // TODO: add Address Hook .

  // TODO: add InterActive Commands .


  //Emulator.Flags.FLAGS := reg_read_x64(uc,UC_X86_REG_EFLAGS);
  IsAPI := CheckHook(uc,PC);

  // Check if the API hash an OnExit CallBack .
  CheckOnExitCallBack(IsAPI,PC);

  if (ShowASM) and (not IsAPI) and (not Emulator.RunOnDll) then
  begin
    Initialize(code);
    FillByte(code,Length(code),0);
    Emulator.err := uc_mem_read_(uc,address,@code,15);
    ins := DisAsm(@code,address,size);

    Writeln(Format('0x%x %s %s %s', [Address,DupeString(' ',Ident), ins.mnemonic, ins.op_str]));

    if ins.mnemonic = 'call' then Ident += 3;
    if ins.mnemonic = 'ret' then Ident -= 3;
  end;

  // rdtsc
  if size = 2 then
  begin
    FillByte(code,Length(code),0);
    uc_mem_read_(uc,address,@code,2);
    if (code[0] = $F) and (code[1] = $31) then
    begin
      reg_write_x32(uc,UC_X86_REG_EAX,RandomRange(100000,101000));
      reg_write_x32(uc,UC_X86_REG_EDX,$0);
      PC += size;
      Emulator.err := uc_reg_write(uc, ifthen(Emulator.Is_x64,UC_X86_REG_RIP,UC_X86_REG_EIP), @PC);
    end;
  end;
  if (not Emulator.RunOnDll) and (Steps_limit <> 0) then
     Steps += 1;
end;

procedure hook_intr(uc: uc_engine; intno: UInt32; user_data: Pointer); cdecl;
var
  PC : UInt64;
begin
  if Emulator.Stop then
  begin
    Emulator.err := uc_emu_stop(uc);
    exit;
  end;
  if Emulator.RunOnDll then Exit;

  PC := 0;
  Emulator.err := uc_reg_read(uc, ifthen(Emulator.Is_x64,UC_X86_REG_RIP,UC_X86_REG_EIP), @PC);

  TextColor(LightMagenta);
  Writeln();
  Writeln(Format('Exception interrupt at : 0x%x',[PC]));
  NormVideo;

  case intno of
    $3,$2D :
    begin
      Handle_SEH(uc,EXCEPTION_BREAKPOINT);
    end;
  else
    Writeln('interrupt ',intno , ' not supported yet ...');
    Emulator.Stop := True;
  end;
end;

procedure HookSysCall(uc : uc_engine; UserData : Pointer);
var
  PC : UInt64;
begin
  PC := 0;
  Emulator.err := uc_reg_read(uc, ifthen(Emulator.Is_x64,UC_X86_REG_RIP,UC_X86_REG_EIP), @PC);
  TextColor(LightMagenta);
  Writeln(Format('Syscall at : 0x%x',[PC]));
  NormVideo;
end;

procedure HookSysEnter(uc : uc_engine; UserData : Pointer);
var
  PC,EAX : UInt64;
begin
  PC := 0; EAX := 0;
  Emulator.err := uc_reg_read(uc, ifthen(Emulator.Is_x64,UC_X86_REG_RIP,UC_X86_REG_EIP), @PC);
  Emulator.err := uc_reg_read(uc, ifthen(Emulator.Is_x64,UC_X86_REG_RAX,UC_X86_REG_EAX), @EAX);

  TextColor(LightMagenta);
  Writeln(Format('SysEnter at : 0x%x',[PC]));
  Writeln(Format('EAX : 0x%x',[EAX]));
  NormVideo;
end;

procedure TEmu.SetHooks();
var
  trace1, trace2, trace3, trace4, trace5, trace6 , trace7: uc_hook;
begin
  //uc_hook_add(uc, trace1, UC_HOOK_MEM_WRITE, @HookMemX86, nil, 1, 0,[]);
  //uc_hook_add(uc, trace2, UC_HOOK_MEM_READ, @HookMemX86, nil, 1, 0,[]);

  Emulator.err := uc_hook_add(uc, trace3,
  UC_HOOK_MEM_READ_UNMAPPED or
  UC_HOOK_MEM_WRITE_UNMAPPED or
  UC_HOOK_MEM_READ_PROT or
  UC_HOOK_MEM_WRITE_PROT or
  UC_HOOK_MEM_FETCH_PROT or
  UC_HOOK_MEM_FETCH_UNMAPPED,
  @HookMemInvalid, nil,1,0,[]);

  if Speed then
    Emulator.err := uc_hook_add(uc, trace4, UC_HOOK_BLOCK, @HookCode, nil, 1, 0,[])
  else
    Emulator.err := uc_hook_add(uc, trace4, UC_HOOK_CODE, @HookCode, nil, 1, 0,[]);

  Emulator.err := uc_hook_add(uc, trace5, UC_HOOK_INTR, @hook_intr, nil, 1, 0,[]);

  Emulator.err := uc_hook_add(uc, trace6, UC_HOOK_INSN, @HookSysCall, nil, 1, 0,[UC_X86_INS_SYSCALL]);

  Emulator.err := uc_hook_add(uc, trace7, UC_HOOK_INSN, @HookSysEnter, nil, 1, 0,[UC_X86_INS_SYSENTER]);

end;

function TEmu.MapPEtoUC() : Boolean;
begin
  Result := False;
  if uc_mem_map(uc,img.ImageBase,Align(img.SizeOfImage,UC_PAGE_SIZE),UC_PROT_ALL) = UC_ERR_OK then
  begin
    Writeln('[√] PE Mapped to Unicorn');
    if uc_mem_write_(uc,img.ImageBase,MapedPE,PE.Size) = UC_ERR_OK then
    begin
      Writeln('[√] PE Written to Unicorn');

      Writeln();
      Writeln('[---------------- PE Info --------------]');
      Writeln('[*] File Name        : ' , ExtractFileName(img.FileName));
      Writeln('[*] Image Base       : ', hexStr(img.ImageBase,16));
      Writeln('[*] Address Of Entry : ', hexStr(img.EntryPointRVA,16));
      Writeln('[*] Size Of Headers  : ', hexStr(img.OptionalHeader.SizeOfHeaders,16));
      Writeln('[*] Size Of Image    : ', hexStr(img.SizeOfImage,16));
      Writeln('[---------------------------------------]');
      Result := True;
    end;
    if isShellCode then
    begin
      if Assigned(SCode) then
      begin
        Writeln('[*] Writing Shellcode to memory ...');
        if uc_mem_write_(uc,img.ImageBase + Img.EntryPointRVA,SCode.Memory,SCode.Size) = UC_ERR_OK then
        begin
          Writeln('[√] Shellcode Written to Unicorn');
        end;
      end;
    end;
  end;
  Writeln();
end;

procedure TEmu.Start();
var
  Entry : UInt64 = 0;
  Start, _End : UInt64;
begin
  Entry := 0;
  SetHooks();
  Writeln('[√] Set Hooks');
  if MapPEtoUC then
  begin
    if load_sys_dll(uc,'ntdll.dll') then    // loaded by Default in Win so we load it first .
    if load_sys_dll(uc,'kernel32.dll') then // second :D but maybe i should put kernelbase.dll ..
    if load_sys_dll(uc,'kernelbase.dll') then
    begin
      // Hook PE Imports

      HookImports_Pse(uc,Img,FilePath);
      //HookImports(uc,Img);

      if not init_segments() then
      begin
        Writeln('Can''t init Segments , last Err : ',uc_strerror(err));
        halt(-1);
      end;

      {
          The Order here is Important - first we load all JS API Hooks
          Then init all dlls and TLS then call Entry Point .
      }
      InstallNativeHooks(); // 0

      js.InitJSEmu(); // 1 .
      js.LoadPlugin(AnsiString(JSAPI)); // 2 .


      Init_dlls(); // 3 .

      InitTLS(uc,Self.Img); // 4 .

      Writeln();
      TextColor(LightCyan);
      Writeln('[>] Run ',ExtractFileName(self.Img.FileName),#10);
      NormVideo;

      // initial stack Pointer .
      r_esp := ((Emulator.stack_base + Emulator.stack_size) - $100);
      r_esp := r_esp and $FFFFFF00; // align the stack .

      err := uc_reg_write(uc, UC_X86_REG_ESP, @r_esp); // ESP .
      err := uc_reg_write(uc, UC_X86_REG_EBP, @r_esp); // EBP .

      // Reseting the EFLAGS is important for some caese -
      // so { don't Delete it :D }
      ResetEFLAGS();


      Entry := img.ImageBase + img.EntryPointRVA;

      // to emulater the call edx :D .. needed in some cases - Don't Delete it .
      uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RDX,UC_X86_REG_EDX),@Entry);

      Start := GetTickCount64;
      if isShellCode then
      err := uc_emu_start(uc,Entry,
          img.ImageBase + img.EntryPointRVA + SCode.Size,0,0)
      else
      err := uc_emu_start(uc,Entry,
          img.ImageBase + img.SizeOfImage,0,0);

      _End := GetTickCount64;
    end;
  end;
  Writeln();

  if Steps_limit <> 0 then
     Write(Format('%d %s - ',[Steps, ifthen(Speed,'Branches','Steps')]));

  Writeln(Format('Executed in %d ms',[(_end - Start)]));

  Writeln();
  Writeln('Cmulator Stop >> last Error : ',uc_strerror(err));
end;

function TEmu.GetGDT(index : Integer): Pointer;
begin
  Result := {%H-}Pointer({%H-}QWord(gdt) + (index * SizeOf(TSegmentDescriptor)));
end;

procedure TEmu.ResetEFLAGS();
begin
  Flags.FLAGS := $202;
  reg_write_x64(uc,UC_X86_REG_EFLAGS,Flags.FLAGS);
end;

function TEmu.init_segments() : boolean;
var
  msr : uc_x86_msr;
  tmp : UInt64;
begin
  Result := false;

  stack_base := $200000;
  stack_size := $60000;
  stack_limit := stack_base - stack_size;
  r_esp := ((stack_base + stack_size) - $70); // initial stack Pointer .

  gs_address := 0;

  if Is_x64 then
  begin
     fs_address  := $7FFFFFC0000; // i think this one not set in x64 :D .
     gs_address  := $7FFFFFE0000; // TEB  ...
     TEB_Address := gs_address;
     PEB_address := gs_address - $10000; // PEB ...
  end
  else
  begin
     fs_address  := $7FFE0000;
     TEB_Address := fs_address;
     PEB_address := fs_address - $10000; // PEB ...
  end;

  if Is_x64 then
  begin
    // FS not accessable from usermode for x64 - i think :D..
    //msr.rid := FSMSR;
    //msr.value := fs_address;
    //uc_reg_write(uc,UC_X86_REG_MSR,@msr);

    // GS Point to TIB in x64 ..
    msr.rid := GSMSR;
    msr.value := gs_address;
    uc_reg_write(uc,UC_X86_REG_MSR,@msr);
  end;

  // Setup FLAFS :D ..
  ResetEFLAGS();


  r_cs := CreateSelector(14, S_GDT or S_PRIV_3); // $73;
  r_ds := CreateSelector(15, S_GDT or S_PRIV_3); // $7b;
  r_es := CreateSelector(15, S_GDT or S_PRIV_3); // $7b;
  r_gs := CreateSelector(15, S_GDT or S_PRIV_3); // $7b;
  r_fs := CreateSelector(16, S_GDT or S_PRIV_3); // $83;
  r_ss := CreateSelector(17, S_GDT or S_PRIV_0); // $88; //ring 0 .

  gdt_address := $C0000000;
  gdtr.base := gdt_address;
  gdtr.limit := 31 * sizeof(TSegmentDescriptor) - 1;

  gdt := CAlloc(31,SizeOf(TSegmentDescriptor));

  Init_Descriptor(GetGDT(14),0,$fffff000,true);      // code segment .
  Init_Descriptor(GetGDT(15),0,$fffff000,false);     // data segment .
  Init_Descriptor(GetGDT(16),fs_address,$fff,false); // one page data segment simulate fs
  Init_Descriptor(GetGDT(17),0,$fffff000,false);     // ring 0 data
  {%H-}PSegmentDescriptor(GetGDT(17))^.dpl := 0;     // set descriptor privilege level .

  // TODO: remove it after implementing Mem Manager.
  tmp := $40000000;
  err := uc_mem_map(uc, tmp, $30000000, UC_PROT_ALL);

  // Now map everything :D ..
  if err = UC_ERR_OK then
  err := uc_mem_map(uc, stack_base, stack_size, UC_PROT_READ or UC_PROT_WRITE);
  if err = UC_ERR_OK then
  begin
    err := uc_mem_map(uc, gdt_address, $10000, UC_PROT_WRITE or UC_PROT_READ);
    if err = UC_ERR_OK then
    begin
      err := uc_reg_write(uc, UC_X86_REG_GDTR, @gdtr);
      if err = UC_ERR_OK then
      begin
        err := uc_mem_write_(uc, gdt_address, gdt, 31 * SizeOf(TSegmentDescriptor));
        if err = UC_ERR_OK then
        begin
          err := uc_mem_map(uc, fs_address, $4000, UC_PROT_WRITE or UC_PROT_READ);
          if err = UC_ERR_OK then
          begin
            begin
              err := uc_reg_write(uc, UC_X86_REG_ESP, @r_esp);
              if err = UC_ERR_OK then
              begin
                err := uc_reg_write(uc, UC_X86_REG_SS, @r_ss);
                if err = UC_ERR_OK then
                begin
                  err := uc_reg_write(uc, UC_X86_REG_CS, @r_cs);
                  if err = UC_ERR_OK then
                  begin
                    err := uc_reg_write(uc, UC_X86_REG_DS, @r_ds);
                    if err = UC_ERR_OK then
                    begin
                      err := uc_reg_write(uc, UC_X86_REG_ES, @r_es);
                      if err = UC_ERR_OK then
                      begin
                        err := uc_reg_write(uc, UC_X86_REG_FS, @r_fs);
                        if err = UC_ERR_OK then
                        begin
                          err := uc_reg_write(uc,UC_X86_REG_GS, @r_gs);
                          if err = UC_ERR_OK then
                          begin
                            if Is_x64 then
                            begin
                              err := uc_mem_map(uc, gs_address, $4000, UC_PROT_WRITE or UC_PROT_READ);
                              if err = UC_ERR_OK then
                                Result := true;
                            end
                            else
                                Result := true;

                            err := uc_mem_map(uc, PEB_address, $10000, UC_PROT_WRITE or UC_PROT_READ);
                            if err = UC_ERR_OK then
                            begin
                              if Result then
                                 if InitTEB_PEB(uc,fs_address,gs_address,PEB_address,stack_base,stack_limit,Is_x64) then
                                    Writeln('[+] Segments & (TIB - PEB) Init Done .')
                                 else
                                    Result := False;
                            end
                            else
                              Result := False;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  Writeln();
end;

constructor TEmu.Create(_FilePath : string; _ShellCode, SCx64 : Boolean);
begin
  // Until Unicorn Engine fix it :D
  MemFix := TStack<UInt64>.Create;

  LastGoodPC := 0;
  SEH_Handler := 0;
  IsException := False;
  Shellcode := _FilePath;
  // the file is Shellcode .
  isShellCode := _ShellCode;

  FilePath := _FilePath;
  Self.Stop := False;

  PE := nil; SCode := nil;
  OnExitList := TOnExit.Create();

  Hooks.ByName := THookByName.Create();
  Hooks.ByOrdinal := THookByOrdinal.Create();


  if isShellCode then
  begin
    FilePath := './shellcode/' + IfThen(SCx64,'sc64.exe','sc32.exe'); // these are empty files with PE header.
  end;
  if FileExists(FilePath) then
  begin
    img := TPEImage.Create();
    if img.LoadFromFile(FilePath) then
    begin
      Is_x64 := img.Is64bit;
      CPU_MODE := ifthen(Is_x64,UC_MODE_64,UC_MODE_32);

      Write(Format('"%s"',[ExtractFileName(FilePath)]));
      Writeln(IfThen(Is_x64,' is : x64',' is : x32'));

      Writeln('Mapping the File ..'#10);
      PE := MapPE(img,FilePath);
      if PE = nil then // Check if Mapping Ok .
      begin
        PE.Free; // Free the Stream before Exit .
        Writeln('Error while Map the PE');
        halt(1);
      end;
      MapedPE := PE.Memory;
      if isShellCode then
      begin
        SCode := TMemoryStream.Create;
        SCode.LoadFromFile(Shellcode);
        SCode.Position := 0;
      end;

      // Libraries Stuff ....
      Libs := TLibs.Create();
      // Set Dll Base loading ...
      if Is_x64 then
      begin
        Self.DLL_BASE_LOAD := $0000000070000000;// $000007FEE0000000;
      end
      else
      begin
        Self.DLL_BASE_LOAD := $0000000070000000;
      end;
      Self.DLL_NEXT_LOAD := Self.DLL_BASE_LOAD;
    end
    else
    begin
      IsSC := true;
      Writeln('Error While Loading : "',FilePath,'" not a valid PE File');
      halt(-1);
    end;
  end
  else
  begin
    Writeln('file not found !');
    halt(-1);
  end;

  err := uc_open(UC_ARCH_X86,CPU_MODE,uc);

  if err = UC_ERR_OK then
  begin
    Writeln('[+] Unicorn Init done  .');
  end
  else
  begin
    Writeln('Error While loading Unicorn : ',uc_strerror(err));
    halt(-1);
  end;
end;

destructor TEmu.Destroy();
begin
  Self.Stop := True;// just to make sure :D

  if uc <> nil then
     uc_close(uc);

  if Assigned(OnExitList) then
     FreeAndNil(OnExitList);

  if Assigned(PE) then
  begin
    FreeAndNil(PE);
  end;
  if Assigned(SCode) then
  begin
    FreeAndNil(SCode);
  end;
  if Assigned(Self.FLibs) then
  begin
    Self.FLibs.Clear;
    FreeAndNil(FLibs);
  end;
  inherited Destroy;
end;

end.


unit EThreads; // i really don't remember why i name this unit to Start with E .

{$mode delphi}

interface

uses
  Classes, SysUtils, math,
  Unicorn_dyn, UnicornConst , X86Const ,
  TEP_PEB, Utils,
  Generics.Collections, Generics.Defaults;


function InitTEB_PEB( uc : uc_engine; FS,GS,PEB,stack_address  : UInt64; stack_limit : UInt32; X64 : boolean): Boolean;

implementation
 uses
   Globals,FnHook,Emu;

var
  EntryNextOffset : UInt64 = 0;

function SortByBaseAddr(constref Left, Right: TPair<string, TNewDll>): Integer;
begin
 Result := TCompare.UInt64(Left.Value.BaseAddress, Right.Value.BaseAddress);
end;

function GetModulesCount(TLibsArray : array of TPair<string, TNewDll>) : Integer;
var
  TLibItem : TPair<string, TNewDll>;
begin
  Result := 0;
  for TLibItem in TLibsArray do
  begin
    if not TLibItem.Value.Dllname.StartsWith('api-ms-win') then
    begin
      Inc(Result);
    end;
  end;
end;

function BuildPEB_Ldr_Entry32(uc : uc_engine;
          Offset,
          blink : UInt64;
          lib : TNewDll;
          Main_Path : string;
          IsEnd : Boolean) : LDR_DATA_TABLE_ENTRY_32;
var
  Entry32 : LDR_DATA_TABLE_ENTRY_32;
  pre_len,
  FPath_len, Path_len, name_len : Cardinal;
  _flink32 : DWORD;
  path : string;
begin
  path := Main_Path + lib.Dllname;

  Fpath_len := Length(path) * 2;
  Path_len := Length(Main_Path) * 2;
  name_len := Length(lib.Dllname) * 2;

  pre_len := SizeOf(LDR_DATA_TABLE_ENTRY_32) + FPath_len;
  _flink32 := EntryNextOffset + pre_len + 2;

  if IsEnd then
    _flink32 := Offset; // Start_of_list .

  Initialize(Entry32);
  FillByte(Entry32,SizeOf(Entry32),0);

  Entry32.InLoadOrderLinks.Flink := _flink32; // next entry
  Entry32.InLoadOrderLinks.Blink := DWORD(blink);

  Entry32.InMemoryOrderLinks.Flink := _flink32 + 8;
  Entry32.InMemoryOrderLinks.Blink := DWORD(blink) + 8;

  Entry32.InInitializationOrderLinks.Flink := _flink32 + 16;
  Entry32.InInitializationOrderLinks.Blink := DWORD(blink) + 16;


  Entry32.DllBase := DWORD(lib.BaseAddress);
  Entry32.EntryPoint := DWORD(lib.EntryPoint);
  Entry32.SizeOfImage := lib.ImageSize;

  Entry32.FullDllName.Length := FPath_len;
  Entry32.FullDllName.MaximumLength := FPath_len + 2;
  Entry32.FullDllName.Buffer := EntryNextOffset + SizeOf(Entry32);

  Entry32.BaseDllName.Length := name_len;
  Entry32.BaseDllName.MaximumLength := name_len + 2;
  Entry32.BaseDllName.Buffer := EntryNextOffset + SizeOf(Entry32) + Path_len; // start if name .

  Emulator.err := uc_mem_write_(uc,EntryNextOffset,@Entry32,SizeOf(Entry32));
  Utils.WriteStringW(EntryNextOffset + SizeOf(Entry32),path);

  //DumpStack(EntryNextOffset,14);

  Result := Entry32;
end;

function BuildPEB_Ldr_Entry64(uc : uc_engine;
          Offset,
          blink : UInt64;
          lib : TNewDll;
          Main_Path : string;
          IsEnd : Boolean) : LDR_DATA_TABLE_ENTRY_64;
var
  Entry : LDR_DATA_TABLE_ENTRY_64;
  pre_len,
  FPath_len, Path_len, name_len : Cardinal;
  _flink : QWORD;
  path : string;
  tmp : Pointer;
begin
  path := Main_Path + lib.Dllname;

  Fpath_len := Length(path) * 2;
  Path_len := Length(Main_Path) * 2;
  name_len := Length(lib.Dllname) * 2;

  pre_len := SizeOf(LDR_DATA_TABLE_ENTRY_64) + FPath_len;
  _flink := EntryNextOffset + pre_len + 2;

  if IsEnd then
   _flink := Offset; // Start_of_list .

  Initialize(Entry);
  FillByte(Entry,SizeOf(Entry),0);

  Entry.InLoadOrderLinks.Flink := _flink;
  Entry.InLoadOrderLinks.Blink := blink;

  Entry.InMemoryOrderLinks.Flink := _flink + 16;
  Entry.InMemoryOrderLinks.Blink := blink + 16;

  Entry.InInitializationOrderLinks.Flink := _flink + 32;
  Entry.InInitializationOrderLinks.Blink := blink + 32;


  Entry.DllBase := lib.BaseAddress;
  Entry.EntryPoint := lib.EntryPoint;
  Entry.SizeOfImage := lib.ImageSize;

  Entry.FullDllName.Length := FPath_len;
  Entry.FullDllName.MaximumLength := FPath_len + 2;
  Entry.FullDllName.Buffer := EntryNextOffset + SizeOf(Entry);

  Entry.BaseDllName.Length := name_len;
  Entry.BaseDllName.MaximumLength := name_len + 2;
  Entry.BaseDllName.Buffer := EntryNextOffset + SizeOf(Entry) + Path_len; // start if name .

  Emulator.err := uc_mem_write_(uc,EntryNextOffset,@Entry,SizeOf(Entry));
  Utils.WriteStringW(EntryNextOffset + SizeOf(Entry),path);

  //DumpStack(EntryNextOffset,14);

  Result := Entry;
end;

procedure BuildPEB_Ldr(uc : uc_engine; offset : UInt64; X64 : boolean);
var
  index, ModulesCount : Integer;
  is_end : Boolean;

  flink32 : DWORD;
  flink64 : QWORD;

  blink32 : DWORD;
  blink64 : QWORD;

  NewOffset : UInt64;

  start_of_list, end_of_list : UInt64;

  LDR_DATA32 : PEB_LDR_DATA_32;
  LDR_DATA64 : PEB_LDR_DATA_64;

  module32 : LDR_DATA_TABLE_ENTRY_32;
  module64 : LDR_DATA_TABLE_ENTRY_64;

  MainModule : TNewDll;

  TLibsArray : array of TPair<string, TNewDll>;
  TLibItem : TPair<string, TNewDll>;
const
  sys_path : string = 'C:\Windows\System32\';
begin

  index := 0; ModulesCount := 0;
  is_end := False;

  if X64 then
  begin
    flink64 := offset + SizeOf(PEB_LDR_DATA_64);
    blink64 := 0;
    start_of_list := offset + $18;
    end_of_list := 0;

    Initialize(LDR_DATA64);
    FillByte(LDR_DATA64,SizeOf(LDR_DATA64),0); // zero out the structure.

    LDR_DATA64.Length := $58;

    LDR_DATA64.InLoadOrderModuleList.Flink := flink64;
    LDR_DATA64.InMemoryOrderModuleList.Flink := flink64 + 16;
    LDR_DATA64.InInitializationOrderModuleList.Flink := flink64 + 32;

    // Add Self .
    blink64 := start_of_list;

    MainModule.EntryPoint := Emulator.Img.ImageBase + Emulator.Img.EntryPointRVA;
    MainModule.BaseAddress := Emulator.Img.ImageBase;
    MainModule.Dllname := ExtractFileName(Emulator.Img.FileName);
    MainModule.ImageSize := Emulator.Img.SizeOfImage;

    EntryNextOffset := flink64;
    module64 := BuildPEB_Ldr_Entry64(uc,flink64,blink64,MainModule,
                'C:\Users\PlaMan\',False);

    end_of_list := flink64;

    // New Offset for Next Module .
    NewOffset := SizeOf(module64) + module64.FullDllName.MaximumLength;
    blink64 := flink64;
    flink64 += NewOffset;
    EntryNextOffset := flink64;

    // sort the libs .
    TLibsArray := Emulator.Libs.ToArray;
    TArrayHelper<Tlibs.TDictionaryPair>.Sort(
      TLibsArray, TComparer<TLibs.TDictionaryPair>.Construct(SortByBaseAddr));

    ModulesCount := GetModulesCount(TLibsArray);
    for TLibItem in TLibsArray do
    begin
      if not TLibItem.Value.Dllname.StartsWith('api-ms-win') then
      begin
        if index+1 = ModulesCount then
        begin
          //Writeln('[+] >>>>> last : ',TLibItem.Value.Dllname);

          end_of_list := flink64;
          flink64 := start_of_list;
          is_end := True;
        end;
        //else
         //Writeln('[+] Module : ',TLibItem.Value.Dllname);

        module64 := BuildPEB_Ldr_Entry64(uc,
                                         flink64,
                                         blink64,
                                         TLibItem.Value,
                                         sys_path,
                                         is_end);
        blink64 := flink64;
        flink64 += SizeOf(module64) + module64.FullDllName.MaximumLength;
        EntryNextOffset := flink64;
        inc(index);
      end;
    end;
    LDR_DATA64.InLoadOrderModuleList.Blink := end_of_list;
    LDR_DATA64.InMemoryOrderModuleList.Blink := end_of_list + 16;
    LDR_DATA64.InInitializationOrderModuleList.Blink := end_of_list + 32;

    if uc_mem_write_(uc,offset,@LDR_DATA64,SizeOf(PEB_LDR_DATA_64)) <> UC_ERR_OK then
    begin
      Writeln('[x] Error While Writing Ldr_data to memory ');
      halt(-1);
    end;

    //Writeln('LDR_DATA64 :');
    //DumpStack(offset,14);

  end // x64 .
  else
  begin
    flink32 := DWORD(offset + SizeOf(PEB_LDR_DATA_32));
    blink32 := 0;
    start_of_list := offset + $C;
    end_of_list := 0;

    Initialize(LDR_DATA32);
    FillByte(LDR_DATA32,SizeOf(LDR_DATA32),0); // zero out the structure.

    LDR_DATA32.Length := $28;

    LDR_DATA32.InLoadOrderModuleList.Flink := flink32;
    LDR_DATA32.InMemoryOrderModuleList.Flink := flink32 + 8;
    LDR_DATA32.InInitializationOrderModuleList.Flink := flink32 + 16; // ntdll.dll .

    // Add Self .
    blink32 := start_of_list;

    MainModule.EntryPoint := Emulator.Img.ImageBase + Emulator.Img.EntryPointRVA;
    MainModule.BaseAddress := Emulator.Img.ImageBase;
    MainModule.Dllname := ExtractFileName(Emulator.Img.FileName);
    MainModule.ImageSize := Emulator.Img.SizeOfImage;

    EntryNextOffset := flink32;
    module32 := BuildPEB_Ldr_Entry32(uc,flink32,blink32,MainModule,
                'C:\Users\PlaMan\',False);

    end_of_list := flink32;

    // New Offset for Next Module .
    NewOffset := SizeOf(module32) + module32.FullDllName.MaximumLength;
    blink32 := flink32;
    flink32 += NewOffset;
    EntryNextOffset := flink32;

    // sort the libs .
    TLibsArray := Emulator.Libs.ToArray;
    TArrayHelper<Tlibs.TDictionaryPair>.Sort(
      TLibsArray, TComparer<TLibs.TDictionaryPair>.Construct(SortByBaseAddr));

    ModulesCount := GetModulesCount(TLibsArray);
    for TLibItem in TLibsArray do
    begin
      if not TLibItem.Value.Dllname.StartsWith('api-ms-win') then
      begin
        if index+1 = ModulesCount then
        begin
          //Writeln('[+] >>>>> last : ',TLibItem.Value.Dllname);

          end_of_list := flink32;
          flink32 := start_of_list;
          is_end := True;
        end;
        //else
          //Writeln('[+] Module : ',TLibItem.Value.Dllname);

        module32 := BuildPEB_Ldr_Entry32(uc,
                                         flink32,
                                         blink32,
                                         TLibItem.Value,
                                         sys_path,
                                         is_end);
        blink32 := flink32;
        flink32 += SizeOf(module32) + module32.FullDllName.MaximumLength;
        EntryNextOffset := flink32;
        inc(index);
      end;
    end;
    LDR_DATA32.InLoadOrderModuleList.Blink := end_of_list;
    LDR_DATA32.InMemoryOrderModuleList.Blink := end_of_list + 8;
    LDR_DATA32.InInitializationOrderModuleList.Blink := end_of_list + 16;

    if uc_mem_write_(uc,offset,@LDR_DATA32,SizeOf(PEB_LDR_DATA_32)) <> UC_ERR_OK then
    begin
      Writeln('[x] Error While Writing Ldr_data to memory ');
      halt(-1);
    end;

    //Writeln('LDR_DATA32 :');
    //DumpStack(offset,14);
  end;
end;

procedure BuildPEB(uc : uc_engine; PEB : UInt64; X64 : boolean);
var
  PEB32 : TPEB_32;
  PEB64 : TPEB_64;
begin
  if X64 then
  begin
    Initialize(PEB64);
    FillByte(PEB64,SizeOf(PEB64),0);

    PEB64.BeingDebugged := False;
    PEB64.ImageBaseAddress  := DWORD(Emulator.Img.ImageBase);
    PEB64.Ldr := PEB + SizeOf(TPEB_64);
    BuildPEB_Ldr(uc,PEB64.Ldr,X64);

    PEB64.OSMajorVersion := RandomRange(10,20);
    PEB64.OSMinorVersion := RandomRange(10,20);
    PEB64.OSBuildNumber  := RandomRange(1000,2000);
    PEB64.OSCSDVersion   := RandomRange(10,20);
    PEB64.OSPlatformId   := RandomRange(10,20);

    if uc_mem_write_(uc,PEB,@PEB64,SizeOf(PEB64)) <> UC_ERR_OK then
    begin
      Writeln('[x] Error While Writing PEB to memory ');
      halt(-1);
    end;
  end
  else
  begin
    Initialize(PEB32);
    FillByte(PEB32,SizeOf(PEB32),0);

    PEB32.BeingDebugged := False;
    PEB32.ImageBaseAddress  := DWORD(Emulator.Img.ImageBase);
    PEB32.Ldr := PEB + SizeOf(TPEB_32);
    BuildPEB_Ldr(uc,PEB32.Ldr,X64);

    PEB32.OSMajorVersion := RandomRange(10,20);
    PEB32.OSMinorVersion := RandomRange(10,20);
    PEB32.OSBuildNumber  := RandomRange(1000,2000);
    PEB32.OSCSDVersion   := RandomRange(10,20);
    PEB32.OSPlatformId   := RandomRange(10,20);

    if uc_mem_write_(uc,PEB,@PEB32,SizeOf(PEB32)) <> UC_ERR_OK then
    begin
      Writeln('[x] Error While Writing PEB to memory ');
      halt(-1);
    end;
  end;
end;

function InitTEB_PEB( uc : uc_engine; FS,GS,PEB,stack_address  : UInt64; stack_limit : UInt32; X64 : boolean): Boolean;
var
  TIB64 : TTIB_64;
  TIB32 : TTIB_32;
  err : uc_err;
  tmp,LS : UInt64;
begin
  Result := False;
  if X64 then
  begin
    Initialize(TIB64);
    FillByte(TIB64,SizeOf(TTIB_64),0);

    TIB64.NtTib.ExceptionList := $FFFFFFFFFFFFFFFF;
    TIB64.NtTib.StackBase := stack_address;
    TIB64.NtTib.StackLimit := stack_limit;
    TIB64.NtTib.SubSystemTib := 0;
    TIB64.NtTib.Union.FiberData := 0;
    TIB64.NtTib.Self := gs;
    TIB64.EnvironmentPointer := 0;
    TIB64.ClientId.UniqueProcess := RandomRange(1000,2000); // random Process ID .
    TIB64.ClientId.UniqueThread  := RandomRange(3000,4000); // random Thread ID .
    TIB64.ActiveRpcHandle := 0;
    TIB64.ThreadLocalStoragePointer := stack_address;
    TIB64.Peb := PEB;

    BuildPEB(uc,PEB,X64);

    err := uc_mem_write_(uc,GS,@TIB64,SizeOf(TTIB_64));

    // custom for an x64 PE File .. just to make it continue run ..
    // remove it later .
    tmp := stack_address;
    err := uc_mem_write_(uc,tmp,@tmp,8);
    err := uc_mem_write_(uc,GS+$58,@tmp,8); // testing ...
    tmp += $188;
    err := uc_mem_write_(uc,tmp,@stack_address,8); // testing ...

    Result := err = UC_ERR_OK;
  end
  else
  begin
    Initialize(TIB32);
    FillByte(TIB32,SizeOf(TIB32),0);

    TIB32.NtTib.ExceptionList := $FFFFFFFF;
    TIB32.NtTib.StackBase := stack_address;
    TIB32.NtTib.StackLimit := stack_limit;
    TIB32.NtTib.SubSystemTib := 0;
    TIB32.NtTib.Union.FiberData := 0;
    TIB32.NtTib.Self := fs;
    TIB32.EnvironmentPointer := 0;
    TIB32.ClientId.UniqueProcess := RandomRange(1000,2000); // random Process ID .
    TIB32.ClientId.UniqueThread  := RandomRange(3000,4000); // random Thread ID .
    TIB32.ActiveRpcHandle := 0;
    TIB32.ThreadLocalStoragePointer := stack_address;
    TIB32.Peb := PEB;

    BuildPEB(uc,PEB,X64);

    // for LocalThreadStorage .
    LS := stack_address;
    tmp := LS + 4;
    err := uc_mem_write_(uc,LS,@tmp,4);

    err := uc_mem_write_(uc,FS,@TIB32,SizeOf(TTIB_32));
    Result := err = UC_ERR_OK;
  end;
  if err <> UC_ERR_OK then
  begin
    Writeln('Error While Write TEB to Memory - last Error : ',uc_strerror(err));
  end;
end;

end.


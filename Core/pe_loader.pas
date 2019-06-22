unit PE_Loader;

{$mode delphi}

interface

uses
  Classes, SysUtils, strutils,
  LazFileUtils, LazUTF8, Crt,
  Unicorn_dyn, UnicornConst, X86Const,
  Generics.Collections,Generics.Defaults,
  Utils, FnHook,xxHash,EThreads,TEP_PEB,math,
  PE.Common, // using TRVA .
  PE.Image,
  PE.Section,
  PE.Imports.Lib,  // using TPEImportLibrary .
  PE.Imports.Func, // using TPEImportFunction .
  PE.Types.Directories,
  PE.Types.Relocations,
  PE.ExportSym,
//-------------------------------------------//
  PseFile,
  PsePeFile,
  PseImportTable;

function MapPE(Img: TPEImage; Path : string) : TMemoryStream;
procedure HookImports(uc : uc_engine; Img: TPEImage);
procedure HookImports_Pse(uc : uc_engine; Img : TPEImage; FilePath : string);
function load_sys_dll(uc : uc_engine; Dll : string) : boolean;
function MapToMemory(PE : TPEImage) : TMemoryStream;

procedure InitTLS(uc : uc_engine; img : TPEImage);

procedure Init_dlls();

implementation
  uses
    Globals,Emu;


procedure InitTLS(uc : uc_engine; img : TPEImage);
var
  r_esp : UInt64;
  CallBack : TRVA;
begin
  if img.TLS.CallbackRVAs.Count = 0 then Exit;

  Writeln();
  TextColor(LightBlue);
  Writeln(Format('[*] Init %d TLS Callbacks',[img.TLS.CallbackRVAs.Count]));
  NormVideo;

  for CallBack in img.TLS.CallbackRVAs do
  begin

    r_esp := ((Emulator.stack_base + Emulator.stack_size) - $100); // initial stack Pointer .
    uc_reg_write(uc, UC_X86_REG_ESP, @r_esp); //

    //void __stdcall TlsCallback(PVOID DllHandle, DWORD Reason, PVOID Reserved) .
    Utils.push(0);         // lpReserved
    Utils.push(1);         // fdwReason
    Utils.push(img.ImageBase);  // HINST  .
    Utils.push($DEADC0DE); // our custom return address so we can stop the execution .

    if VerboseEx then
    begin
      Writeln();
      TextColor(LightMagenta);
      Writeln(Format('Call TlsCallBack %s Entry : %x',
            [ExtractFileName(img.FileName),img.ImageBase + img.EntryPointRVA]));
      NormVideo;
    end;
    Emulator.ResetEFLAGS();
    uc_emu_start(uc,img.ImageBase + CallBack,0,0,0);
  end;
  TextColor(LightBlue);
  Writeln('[√] Init TLS Callbacks done');
  NormVideo;

end;

{ TODO: implement apisetschema Forwarder.}
procedure FixDllImports(uc : uc_engine; var Img: TPEImage; DllBase : UInt64);
var
  SysDll : TNewDll;
  HookFn : TLibFunction;
  Lib : TPEImportLibrary;
  Fn  : TPEImportFunction;
  Hash : UInt64;
  rva , FuncAddr : TRVA;
  err : uc_err;
  path : UnicodeString;
  Dll : string;
begin
  FuncAddr := 0;
  if VerboseEx then
  begin
    Writeln('[---------------------------------------]');
    Writeln('[            Fixing DLL Imports         ]');Writeln();
    Writeln('[*] File Name  : ',ExtractFileName(Img.FileName)); Writeln();
  end;
  // Scan libraries.
  for Lib in Img.Imports.Libs do
  begin
    Dll := ExtractFileNameWithoutExt(ExtractFileName(lib.Name)) + '.dll';

    if Emulator.isx64 then
       Path := IncludeTrailingPathDelimiter(win64) + UnicodeString(LowerCase(Trim(Dll)))
    else
       Path := IncludeTrailingPathDelimiter(win32) + UnicodeString(LowerCase(Trim(Dll)));

    if not FileExists(Path) then
    begin
      Writeln('"',Dll,'" not found ! [1]');
      Writeln();
      halt(-1);
    end;
    // If library not loaded then load it .
    if not Emulator.Libs.ContainsKey(LowerCase(Dll)) then
    begin
      if VerboseEx then
      begin
        Writeln();
        Writeln('[>] ',ExtractFileName(Img.FileName),' Import : ', Dll,#10);
      end;

      if not load_sys_dll(uc,LowerCase(Dll)) then
      begin
        Writeln('Error While Loading Lib : ',Dll);
        halt(-1);
      end;
    end;

    rva := DllBase + Lib.IatRva;
    if not Emulator.Libs.TryGetValue(LowerCase(Dll),SysDll) then
    begin
      Writeln('<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>');
      Writeln(Format('>>>> Error %s import table has %s , but not Loaded In Cmulator <<<<',[img.FileName,Dll]));
      Writeln('<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>');
      halt(-1);
    end;

    for Fn in Lib.Functions do
    begin
      if Fn.Name <> '' then
      begin
        Hash := xxHash64Calc(LowerCase(ExtractFileNameWithoutExt(ExtractFileName(Lib.Name))) + '.' + Fn.Name);
        if SysDll.FnByName.TryGetValue(Hash,HookFn) then
        begin
          FuncAddr := HookFn.VAddress;
        end;
      end
      else
      begin
        Hash := xxHash64Calc(LowerCase(ExtractFileNameWithoutExt(ExtractFileName(Lib.Name))) + '.' + IntToStr(Fn.Ordinal));
        if SysDll.FnByOrdinal.TryGetValue(Hash,HookFn) then
        begin
          FuncAddr := HookFn.VAddress;
        end;
      end;

      if VerboseExx then
      begin
        write('  '); // indent
        writeln(format('%s : Real rva: 0x%-8x - New : 0x%-8x',
         [IfThen(fn.Name <> '',fn.Name,('#'+IntToStr(Fn.Ordinal))),rva,FuncAddr]));
      end;

      err := uc_mem_write_(uc,rva,@FuncAddr,Img.ImageWordSize);
      if err <> UC_ERR_OK then
      begin
        Writeln('Func Name : ', Fn.Name);
        Writeln('Error While Write Fn RVA , err : ',uc_strerror(err));
        halt(-1);
      end;

      inc(rva, Img.ImageWordSize);
    end;
    inc(rva, Img.ImageWordSize); // null
  end;
  if VerboseEx then
     Writeln('[---------------------------------------]'#10);
end;

procedure InitDll(uc : uc_engine; lib : TNewDll);
var
  r_esp : UInt64;
begin
  if (lib.EntryPoint <> 0) and (not lib.Dllname.StartsWith('ntdll')) then
  begin

    r_esp := ((Emulator.stack_base + Emulator.stack_size) - $100); // initial stack Pointer .
    uc_reg_write(uc, UC_X86_REG_ESP, @r_esp); //
    //TDllEntryProc = function(hinstDLL: HINST; fdwReason: DWORD; lpReserved: Pointer): BOOL; stdcall;
    Utils.push(0);         // lpReserved
    Utils.push(1);         // fdwReason
    Utils.push(lib.BaseAddress);  // HINST
    Utils.push($DEADC0DE); // our custom return address so we can stop the execution .

    if VerboseExx then
    begin
      Writeln();
      TextColor(LightMagenta);
      Writeln(Format('Call %s Entry : %x',[lib.Dllname,lib.EntryPoint]));
      NormVideo;
    end;

    if not VerboseExx then // if not VerboseExx don't show stuff :D .
       Emulator.RunOnDll := True;

    Emulator.ResetEFLAGS();
    uc_emu_start(uc,lib.EntryPoint,lib.ImageSize,0,0);
    Emulator.RunOnDll := False;
  end;
end;


function GetModulesCount(TLibsArray : TLibs) : Integer;
var
  LibItem : TNewDll;
begin
  Result := 0;
  for LibItem in TLibsArray.Values do
  begin
    if not LibItem.Dllname.StartsWith('api-ms-win') then
    begin
      Inc(Result);
    end;
  end;
end;

procedure Init_dlls();
var
  lib : TNewDll;
begin

  TextColor(LightMagenta);
  Writeln(Format('Initiating %d Libraries ...',[GetModulesCount(Emulator.Libs)]));
  NormVideo;
  for lib in Emulator.Libs.Values do
  begin
    if not Lib.Dllname.StartsWith('api-ms-win') then
    InitDll(Emulator.uc,lib);
  end;
end;

function load_sys_dll(uc : uc_engine; Dll : string) : boolean;
var
  img: TPEImage;
  sym: TPEExportSym;
  Reloc: TReloc;
  VAddr, DLL_BASE, Delta, pDst , ptmp : UInt64;
  Path : UnicodeString;
  FLibrary : TMemoryStream;
  err : uc_err;
  ByAddr    : TFastHashMap<UInt64, TLibFunction>;
  ByOrdinal : TFastHashMap<UInt64, TLibFunction>;
  ByName    : TFastHashMap<UInt64, TLibFunction>;
  FName, LibName , FWName, FWLib,FWAPI : string;
  Hash : UInt64;
  IsOrdinal : Boolean;
  //ret : Pointer;
begin

  FLibrary := nil;
  FWLib := '';
  Result := false;
  Delta := 0;

  Dll := LowerCase(ExtractFileNameWithoutExt(ExtractFileName(Dll)) + '.dll');
  if Emulator.Libs.ContainsKey(Trim(Dll)) then
    Exit(True);

  if Emulator.isx64 then
     Path := IncludeTrailingPathDelimiter(win64) + UnicodeString(LowerCase(Trim(Dll)))
  else
     Path := IncludeTrailingPathDelimiter(win32) + UnicodeString(LowerCase(Trim(Dll)));


  if FileExists(Path) then
  begin
    //ret := AllocMem(UC_PAGE_SIZE);
    //FillByte(ret^,UC_PAGE_SIZE,$C3);

    LibName := Trim(Dll);

    img := TPEImage.Create;
    try
      // Read image and parse exports only.
      if not img.LoadFromFile(string(path)) then
      begin
        writeln('Failed to load Library : ', LibName);
        exit;
      end;
      if not img.IsDLL then
      begin
        Writeln(Format('%s is not a DLL ... :( !',[LibName]));
        exit;
      end;
      if VerboseEx then
      begin
        Writeln('[---------------------------------------]');
        Writeln('[        Mapping Library Exports        ]');
        writeln(format('[*] Lib Name    : %s',[LibName]));
        writeln(format('[*] Image Base  : %x',[img.ImageBase]));
        Writeln(Format('[*] Image Size  : %x',[img.SizeOfImage]));
        Writeln(Format('[*] Loaded at   : %x - End at %x',[Align(Emulator.DLL_NEXT_LOAD,UC_PAGE_SIZE*2),Emulator.DLL_NEXT_LOAD + img.SizeOfImage]));
        Writeln(Format('[*] BaseOfCode  : %x',[img.ImageBase + img.OptionalHeader.BaseOfCode]));
        Writeln(Format('[*] SizeOfCode  : %x',[img.OptionalHeader.SizeOfCode]));
        Writeln('[---------------------------------------]'#10);
      end;


      FLibrary := MapToMemory(img);
      if (FLibrary.Memory = nil) or (FLibrary.Size <= 0) then
      begin
        Writeln('Can''t Alloc Memory For : ',LibName);
        halt(-1);
      end;
      DLL_BASE := Align(Emulator.DLL_NEXT_LOAD,UC_PAGE_SIZE);

      err := uc_mem_map(uc,DLL_BASE,img.SizeOfImage,UC_PROT_ALL);
      if err <> UC_ERR_OK then
      begin
        FreeAndNil(FLibrary);
        Writeln('Lib : ',LibName);
        Writeln('Error While Map the new lib base , err : ',uc_strerror(err));
        halt(-1);
      end;
      err := uc_mem_write_(uc,DLL_BASE,FLibrary.Memory,img.SizeOfImage);
      if err <> UC_ERR_OK then
      begin
        FreeAndNil(FLibrary);
        Writeln('Lib : ',LibName);
        Writeln('Error While Write the new lib base , err : ',uc_strerror(err));
        halt(-1);
      end;
      FreeAndNil(FLibrary); // TODO: use uc_mem_map_ptr ... for multithreading .


      //================================================================//
      // Relocations //
      Delta := DLL_BASE - img.ImageBase;
      if Delta <> 0 then
      begin
        for Reloc in img.Relocs.Items do
        begin
          case Reloc.&Type of
            IMAGE_REL_BASED_ABSOLUTE:; // Skip ..
            IMAGE_REL_BASED_HIGHLOW,
            IMAGE_REL_BASED_DIR64:
            begin
              pDst := DLL_BASE + Reloc.RVA;
              ptmp := 0;
              err := uc_mem_read_(uc,pDst,@ptmp,img.ImageWordSize);
              ptmp += Delta;
              err := uc_mem_write_(uc,pDst,@ptmp,img.ImageWordSize);
            end;
          else
            raise Exception.CreateFmt('Unsupported relocation type: %d', [Reloc.&Type]);
          end;
        end;
      end;
      inc(Emulator.DLL_NEXT_LOAD, img.SizeOfImage);

      //================================================================//
      //HOOK_LIB := (HOOK_BASE + (HOOK_INDEX * UC_PAGE_SIZE));
      //HOOK_Fn := HOOK_LIB;
      //err := uc_mem_map(uc,HOOK_LIB,UC_PAGE_SIZE,UC_PROT_ALL);
      //if err <> UC_ERR_OK then
      //begin
      //  FreeAndNil(FLibrary);
      //  Writeln('Lib : ',LibName);
      //  Writeln('Error While Map the Hook Base for lib base , err : ',uc_strerror(err));
      //  halt(-1);
      //end;
      //err := uc_mem_write_(uc,HOOK_LIB,ret,UC_PAGE_SIZE);
      //if err <> UC_ERR_OK then
      //begin
      //  FreeAndNil(FLibrary);
      //  Writeln('Lib : ',LibName);
      //  Writeln('Error While Write the new Hook Base for lib , err : ',uc_strerror(err));
      //  halt(-1);
      //end;
    //================================================================//

      ByAddr    := TFastHashMap<UInt64, TLibFunction>.Create();
      ByOrdinal := TFastHashMap<UInt64, TLibFunction>.Create();
      ByName    := TFastHashMap<UInt64, TLibFunction>.Create();

      for sym in img.ExportSyms.Items do
      begin
        if (sym.IsValid) then
        begin

          VAddr := (DLL_BASE + sym.RVA);
          FName := sym.Name;

          IsOrdinal := FName.IsEmpty;
          // has ordinal but no name ..
          if FName.IsEmpty then
          begin
            FName := IntToStr(sym.Ordinal);
          end;

          // (ByAddr.ContainsKey(VAddr) cuz some function has same Addr like .
          {
           VA: $7DDF9909; RVA: $99909; ord: $171; name: "GetBinaryType";
           VA: $7DDF9909; RVA: $99909; ord: $172; name: "GetBinaryTypeA";
           ---------------------------------------------------------------------
           VA: $7DD60000; RVA: $0; ord: $2; name: "InterlockedPushListSList"; fwd: "NTDLL.RtlInterlockedPushListSList"
           this one is Forwarded .
          }

          FWName := '';
          if sym.Forwarder then
          begin
            // API is Forwarded ..
            FWName := sym.ForwarderName;
            sym.GetForwarderLibAndFuncName(FWLib,FWAPI);
            VAddr := Utils.GetProcAddr(GetModulehandle(FWLib),FWAPI);
          end;

          if not ByAddr.ContainsKey(VAddr) then
          ByAddr.Add(VAddr,TLibFunction.Create(LibName,sym.Name,VAddr,sym.Ordinal,nil,
                                          sym.Forwarder,IsOrdinal,FWName));

          Hash := xxHash64Calc(LowerCase(ExtractFileNameWithoutExt(ExtractFileName(LibName))) + '.' + IntToStr(sym.Ordinal));

          ByOrdinal.Add(Hash,TLibFunction.Create(LibName,sym.Name,VAddr,sym.Ordinal,nil,
                                          sym.Forwarder,IsOrdinal,FWName));

          Hash := xxHash64Calc(LowerCase(ExtractFileNameWithoutExt(ExtractFileName(LibName))) + '.' + Fname);

          ByName.Add(Hash,TLibFunction.Create(LibName,sym.Name,VAddr,sym.Ordinal,nil,
                                          sym.Forwarder,IsOrdinal,FWName));

          //if VerboseExx then
          //begin
          //  writeln(format('Export VA: $%x; RVA: $%x; ord: $%x; name: "%s"; fwd: "%s"',
          //  [VAddr, sym.RVA, sym.Ordinal, sym.Name, sym.ForwarderName]));
          //end;
        end;
      end;
      Emulator.Libs.Add(LibName,TNewDll.Create((DLL_BASE + img.EntryPointRVA),LibName,DLL_BASE,img.SizeOfImage,ByAddr,ByOrdinal,ByName));
    finally
      inc(Emulator.DLL_NEXT_LOAD, img.SizeOfImage);
      //inc(HOOK_INDEX);

      // TODO: implement apisetschema Forwarder .
      FixDllImports(uc,img,DLL_BASE);

      // ReBuild Ldr for every new module loaded .
      if Emulator.PEB > 0 then // Check if already set ..
         BuildPEB_Ldr(uc,Emulator.PEB + IfThen(Emulator.isx64,SizeOf(TPEB_64),SizeOf(TPEB_32)),Emulator.isx64);

      img.Free;
    end;
    //if ret <> nil then
    //   Freemem(ret,UC_PAGE_SIZE);
  end
  else
  begin
    Writeln(Format('Library "%s" not found ! [2]',[Dll])); Writeln();
    halt(-1);
  end;

  Result := true;
end;

procedure HookImports(uc : uc_engine; Img: TPEImage);
var
  SysDll : TNewDll;
  HookFn : TLibFunction;
  Lib : TPEImportLibrary;
  Fn  : TPEImportFunction;
  Hash : UInt64;
  rva , FuncAddr : TRVA;
  err : uc_err;
  path : UnicodeString;
  Dll : string;
begin
  FuncAddr := 0;

  Writeln('[---------------------------------------]');
  Writeln('[            Fixing PE Imports          ]'); Writeln();
  Writeln('[*] File Name  : ',ExtractFileName(Img.FileName)); Writeln();
  // Scan libraries.
  for Lib in Img.Imports.Libs do
  begin
    Dll := ExtractFileNameWithoutExt(ExtractFileName(lib.Name)) + '.dll';
    if Emulator.isx64 then
       Path := IncludeTrailingPathDelimiter(win64) + UnicodeString(LowerCase(Trim(Dll)))
    else
       Path := IncludeTrailingPathDelimiter(win32) + UnicodeString(LowerCase(Trim(Dll)));

    if not FileExists(Path) then
    begin
      Writeln('"',Dll,'" not found ! [3]');
      halt(-1);
    end;
    // If library not loaded then load it .
    if not Emulator.Libs.ContainsKey(LowerCase(Dll)) then
    begin
      if Verbose then
      begin
        Writeln();
        Writeln('[>] ',ExtractFileName(Img.FileName),' Import Loading : ', Dll);
      end;
      if not load_sys_dll(uc,LowerCase(Dll)) then
      begin
        Writeln('Error While Loading Lib : ',Dll);
        halt(-1);
      end;
    end;


    if not Emulator.Libs.TryGetValue(LowerCase(Dll),SysDll) then
    begin
      Writeln('<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>');
      Writeln(Format('>>>> Error %s import table has %s , but not Loaded In Cmulator <<<<',[img.FileName,Dll]));
      Writeln('<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>');
      halt(-1);
    end;

    rva := Img.ImageBase + Lib.IatRva;

    for Fn in Lib.Functions do
    begin
      if Fn.Name <> '' then
      begin
        Hash := xxHash64Calc(LowerCase(ExtractFileNameWithoutExt(ExtractFileName(Lib.Name))) + '.' + Fn.Name);
        if SysDll.FnByName.TryGetValue(Hash,HookFn) then
        begin
          FuncAddr := HookFn.VAddress;
        end;
      end
      else
      begin
        Hash := xxHash64Calc(LowerCase(ExtractFileNameWithoutExt(ExtractFileName(Lib.Name))) + '.' + IntToStr(Fn.Ordinal));
        if SysDll.FnByOrdinal.TryGetValue(Hash,HookFn) then
        begin
          FuncAddr := HookFn.VAddress;
        end;
      end;

      if Verbose then
      begin
        Writeln(Format('%s',[IfThen(fn.Name <> '',fn.Name,('#'+IntToStr(Fn.Ordinal)))]));
        write('  '); // indent
        writeln(format('Real func rva: 0x%-8x - New : 0x%-8x',[rva,FuncAddr]));
      end;

      err := uc_mem_write_(uc,rva,@FuncAddr,Img.ImageWordSize);
      if err <> UC_ERR_OK then
      begin
        Writeln('Func Name : ', Fn.Name);
        Writeln('Error While Write Fn RVA , err : ',uc_strerror(err));
        halt(-1);
      end;

      inc(rva, Img.ImageWordSize);
    end;
  end;
  Writeln('[---------------------------------------]'#10);
end;

function MapToMemory(PE : TPEImage) : TMemoryStream;
var
  tmp : TMemoryStream;
  Offset : UInt64;
  sec : TPESection;
begin
  Result := TMemoryStream.Create;
  tmp := TMemoryStream.Create;
  try
    Offset := PE.ImageBase;
    Result.Position := 0;
    tmp.Position := 0;
    if PE.SaveToStream(tmp) then
    begin
      tmp.Position := 0; // set it back to 0 .

      Result.WriteBuffer(tmp.Memory^,PE.OptionalHeader.SizeOfHeaders);
      Offset += PE.OptionalHeader.SizeOfHeaders;

      if VerboseEx then
      begin
        Writeln('[---------------------------------------]');
        Writeln('[             Start Mapping             ]');
        Writeln('[*] File Name        : ' , ExtractFileName(PE.FileName));
        Writeln('[*] File Size        : ', tmp.Size, ' Byte');
        Writeln('[*] Image Base       : ', hexStr(PE.ImageBase,16));
        Writeln('[*] Address Of Entry : ', hexStr(PE.EntryPointRVA,16));
        Writeln('[*] Size Of Headers  : ', hexStr(PE.OptionalHeader.SizeOfHeaders,16));
        Writeln('[*] Size Of Image    : ', hexStr(PE.SizeOfImage,16));
      end;

      for sec in PE.Sections do
      begin



        while (Offset < (sec.RVA + PE.ImageBase )) do
        begin
          Result.WriteByte(0);
          Offset += 1;
        end;

        sec.SaveDataToStream(Result);
        Offset += sec.RawSize;

        while (Offset < (sec.RVA + sec.VirtualSize + PE.ImageBase)) do
        begin
          Result.WriteByte(0);
          Offset += 1;
        end;
      end;

      while ((Offset - PE.ImageBase) < PE.SizeOfImage) do
      begin
        Result.WriteByte(0);
        Offset += 1;
      end;
      if VerboseEx then
      begin
         Writeln('[+] File mapping completed √');
         Writeln('[---------------------------------------]'#10);
      end;
    end;
  finally
    tmp.free
  end;
end;

function SectionAlignment( img : TPEImage; sec : TPESection ): UInt32;
var
  sec_align , file_align : UInt32;
begin
  sec_align := img.OptionalHeader.SectionAlignment;
  file_align := img.OptionalHeader.FileAlignment;

  if sec_align < $1000 then // page_size .
    sec_align := file_align;

  if (sec_align and sec.RVA mod sec_align) = 1 then
    Exit(sec_align * (sec.RVA div sec_align));

  Result := sec.RVA;
end;

function FileAlignment(img : TPEImage; sec : TPESection): UInt32;
begin
  if img.OptionalHeader.FileAlignment < $200 then
    Exit(sec.RawOffset);
  Result := (sec.RawOffset div $200) * $200;
end;

procedure HookImports_Pse(uc : uc_engine; Img : TPEImage; FilePath : string);
var
  SysDll : TNewDll;
  HookFn : TLibFunction;
  imp: TPseImport;
  api: TPseApi;
  FuncAddr,rva : TRVA;
  err : uc_err;
  path : UnicodeString;
  Dll : string;
  PseFile: TPseFile;
  Hash : UInt64;
  //index : integer;
begin
  TPseFile.RegisterFile(TPsePeFile);
  PseFile := TPseFile.GetInstance(FilePath, false);

  FuncAddr := 0;

  Writeln('[---------------------------------------]');
  Writeln('[            Fixing PE Imports          ]'); Writeln();
  Writeln('[*] File Name  : ',ExtractFileName(FilePath));
  Writeln('[*] Import ',PseFile.ImportTable.Count ,' Dlls'); Writeln();

  // Scan libraries.
  for imp in PseFile.ImportTable do
  begin
    Dll := ExtractFileNameWithoutExt(ExtractFileName(imp.DllName)) + '.dll';

    Writeln('[+] Fix IAT for : ',Dll);

    if Emulator.isx64 then
       Path := IncludeTrailingPathDelimiter(win64) + UnicodeString(LowerCase(Trim(Dll)))
    else
       Path := IncludeTrailingPathDelimiter(win32) + UnicodeString(LowerCase(Trim(Dll)));

    if not FileExists(Path) then
    begin
      Writeln('"',Dll,'" not found ! [4]');
      halt(-1);
    end;
    // If library not loaded then load it .
    if not Emulator.Libs.ContainsKey(LowerCase(Dll)) then
    begin
      if not load_sys_dll(uc,LowerCase(Dll)) then
      begin
        Writeln('Error While Loading Lib : ',Dll);
        halt(-1);
      end;
    end;

    if not Emulator.Libs.TryGetValue(LowerCase(Dll),SysDll) then
    begin
      Writeln('<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>');
      Writeln(Format('>>>> Error %s import table has %s , but not Loaded In Cmulator <<<<',[img.FileName,Dll]));
      Writeln('<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>');
      halt(-1);
    end;

    rva := imp.IatRva + Img.ImageBase;
    for api in imp do
    begin
      if api.Name <> '' then
      begin
        Hash := xxHash64Calc(LowerCase(ExtractFileNameWithoutExt(ExtractFileName(imp.DllName))) + '.' + api.Name);
        if SysDll.FnByName.TryGetValue(Hash,HookFn) then
        begin
          FuncAddr := HookFn.VAddress;
        end;
      end
      else
      begin
        Hash := xxHash64Calc(LowerCase(ExtractFileNameWithoutExt(ExtractFileName(imp.DllName))) + '.' + IntToStr(api.Hint));
        if SysDll.FnByOrdinal.TryGetValue(Hash,HookFn) then
        begin
          FuncAddr := HookFn.VAddress;
        end;
      end;

      if Verbose then
      begin
        Writeln(Format('    %s',[IfThen(api.Name <> '',api.Name,('#'+IntToStr(api.Hint)))]));
        write('      '); // indent
        writeln(format('Real rva: 0x%-8x - New : 0x%-8x',[rva - Img.ImageBase,FuncAddr]));
      end;

      err := uc_mem_write_(uc,rva,@FuncAddr,Img.ImageWordSize);
      if err <> UC_ERR_OK then
      begin
        Writeln('Func Name : ', api.Name);
        Writeln('Error While Write Fn RVA , err : ',uc_strerror(err));
        halt(-1);
      end;
      inc(rva, Img.ImageWordSize);
    end;
    Writeln();
  end;
  Writeln('[---------------------------------------]');
  Writeln();
  FreeAndNil(PseFile);
end;

function MapToPEMemory(var PE : TPEImage; Image : TMemoryStream; max_virtualAddr : UInt64 = $10000000) : TMemoryStream;
var
  i, Size : Integer;
  sec : TPESection;
  padding_len : Integer;
  virtualAddr_adj : DWORD;
begin
  Result := TMemoryStream.Create;

  Result.Position := 0;
  Image.Position := 0;
  Image.SaveToStream(Result);

  if Result.Size = Image.Size then
  begin
    Result.Position := Result.Size;

    if VerboseEx then
    begin
      Writeln('[---------------------------------------]');
      Writeln('[             Start Mapping             ]');
      Writeln('[*] File Name        : ' , ExtractFileName(PE.FileName));
      Writeln('[*] File Size        : ', Image.Size, ' Byte');
      Writeln('[*] Image Base       : ', hexStr(PE.ImageBase,16));
      Writeln('[*] Address Of Entry : ', hexStr(PE.EntryPointRVA,16));
      Writeln('[*] Size Of Headers  : ', hexStr(PE.OptionalHeader.SizeOfHeaders,16));
      Writeln('[*] Size Of Image    : ', hexStr(PE.SizeOfImage,16));
    end;

    Size := Result.Size; // init size ..

    for sec in PE.Sections do
    begin

      if (sec.VirtualSize = 0) and (sec.RawSize = 0) then
         Continue;

      if sec.RawSize > Image.Size then
         Continue;

      if FileAlignment(PE,sec) > Image.Size then
         Continue;

      virtualAddr_adj := SectionAlignment(PE,sec);

      if virtualAddr_adj >= max_virtualAddr then
      begin
        Continue;
      end;

      padding_len := virtualAddr_adj - Size;

      if padding_len > 0 then
      begin
        for i := 0 to Pred(padding_len) do
        begin
          Result.WriteByte(0);
        end;
      end
      else
      if padding_len < 0 then
      begin
        Result.Position := Result.Size + padding_len;
        if Result.Position < 0 then
           Writeln('this is plaaaa <><><><><><><><<><><>>>><<<>>>');
      end;
      Size += padding_len;

      Size += sec.RawSize;
      sec.SaveDataToStream(Result);
    end;
    //Result.SaveToFile('./samples/netwire_mapped.exe');
    //halt(0);

    if VerboseEx then
    begin
       Writeln('[+] File mapping completed √');
       Writeln('[---------------------------------------]'#10);
    end;
  end;
end;

function MapPE(Img: TPEImage; Path : String) : TMemoryStream;
var
  Image : TMemoryStream;
begin
  Result := nil;
  Image := TMemoryStream.Create;
  Image.LoadFromFile(path);
  //Result := MapToMemory(Img); // maybe will add it as second method :D .
  Result := MapToPEMemory(Img,Image);
  FreeAndNil(Image);
end;

initialization
  //HOOK_BASE := $30000;
  //HOOK_INDEX := 0;

end.


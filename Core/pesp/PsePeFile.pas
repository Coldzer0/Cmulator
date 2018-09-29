{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PsePeFile;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseFile, PseSection,
  PseExportTable, PseImportTable, PseCmn, PseMz, PsePe;

type
  {
    Windows PE files.

    References

    Micosoft. Microsoft Portable Executable and Common Object File Format
      Specification. Microsoft, February 2013.
  }
  TPsePeFile = class(TPseFile)
  private
    FDosHeader: TImageDosHeader;
    FSignature: Cardinal;
    FImageHeader: TImageFileHeader;
    FOptHeader32: TImageOptionalHeader32;
    FOptHeader64: TImageOptionalHeader64;
    function GetCodeSection(out AAddr, ASize: UInt64): boolean;
    procedure ReadSections;
    procedure ReadExports;
    procedure ReadImports;
    procedure ReadDelayImports;
    procedure ReadMapFile;
    procedure ReadDebugDirectory;
    function RVAToOffset(const RVA: UInt64): UInt64;
  protected
  public
    constructor Create; override;
    destructor Destroy; override;
    function LoadFromStream(Stream: TStream): boolean; override;
    procedure SaveSectionToStream(const ASection: integer; Stream: TStream); override;
    function GetEntryPoint: UInt64; override;
    function GetArch: TPseArch; override;
    function GetMode: TPseMode; override;
    function GetFirstAddr: UInt64; override;
    function GetInitStackSize: UInt64; override;
    function GetMaxStackSize: UInt64; override;
    function GetInitHeapSize: UInt64; override;
    function GetMaxHeapSize: UInt64; override;

    function GetImageBase: UInt64;
    function GetSizeOfImage: Cardinal;
    function GetNumberOfSections: Cardinal;

    function GetMachineString: string;
    function GetCharacteristicsString: string;
    function GetSubsystemString: string;

    function GetFriendlyName: string; override;

    property DosHeader: TImageDosHeader read FDosHeader;
    property Signature: Cardinal read FSignature;
    property ImageHeader: TImageFileHeader read FImageHeader;
    property OptHeader32: TImageOptionalHeader32 read FOptHeader32;
    property OptHeader64: TImageOptionalHeader64 read FOptHeader64;
  end;

implementation

uses
  Math, PseMapFileReader, PseDebugInfo;

const
  DOS_HEADER_MZ = ((Ord('Z') shl 8) + Ord('M'));
  IMG_HEADER_EP = ((Ord('E') shl 8) + Ord('P'));

constructor TPsePeFile.Create;
begin
  inherited;
end;

destructor TPsePeFile.Destroy;
begin
  inherited;
end;

procedure TPsePeFile.SaveSectionToStream(const ASection: integer; Stream: TStream);
var
  sec: TPseSection;
  o, s: Int64;
begin
  sec := FSections[ASection];
  o := RVAToOffset(sec.Address);
  FStream.Seek(o, soFromBeginning);
  s := Min(Int64(sec.Size), Int64(FStream.Size - o));
  Stream.CopyFrom(FStream, s);
end;

function TPsePeFile.LoadFromStream(Stream: TStream): boolean;
begin
  Result := inherited;
  if Result then begin
    FStream.Position := 0;
    if (FStream.Read(FDosHeader, SizeOf(TImageDosHeader)) <> SizeOf(TImageDosHeader)) then
      Exit(false);
    if FDosHeader.e_magic <> DOS_HEADER_MZ then
      Exit(false);

    FStream.Seek(FDosHeader._lfanew, soFromBeginning);
    FStream.Read(FSignature, SizeOf(Cardinal));
    if FSignature <> IMG_HEADER_EP then
      Exit(false);

    if (FStream.Read(FImageHeader, SizeOf(TImageFileHeader)) <> SizeOf(TImageFileHeader)) then
      Exit(false);

    case FImageHeader.Machine of
      IMAGE_FILE_MACHINE_I386:
        begin
          FBitness := pseb32;
          if (FStream.Read(FOptHeader32, SizeOf(TImageOptionalHeader32)) <> SizeOf(TImageOptionalHeader32)) then
            Exit(false);
        end;
      IMAGE_FILE_MACHINE_AMD64, IMAGE_FILE_MACHINE_IA64:
        begin
          FBitness := pseb64;
          if (FStream.Read(FOptHeader64, SizeOf(TImageOptionalHeader64)) <> SizeOf(TImageOptionalHeader64)) then
            Exit(false);
        end;
    end;
    ReadSections;
    ReadExports;
    ReadImports;
    ReadDelayImports;
    if FReadDebugInfo then begin
      ReadDebugDirectory;
      ReadMapFile;
    end;
  end;
end;

procedure TPsePeFile.ReadDebugDirectory;
var
  debug_rva, offset: UInt64;
  debug_dir: TImageDebugDirectory;
  ansi_name: array[0..260] of AnsiChar;
  wide_name: array[0..260] of WideChar;
  debug_misc: TImageDebugMisc;
  coff_header: TImageCOFFSymbolsHeader;
begin
  if Is64 then begin
    debug_rva := RVAToOffset(FOptHeader64.DataDirectory[IMAGE_DIRECTORY_ENTRY_DEBUG].VirtualAddress);
  end else begin
    debug_rva := RVAToOffset(FOptHeader32.DataDirectory[IMAGE_DIRECTORY_ENTRY_DEBUG].VirtualAddress);
  end;
  if debug_rva = 0 then
    Exit;

  FStream.Seek(debug_rva, soFromBeginning);
  if (FStream.Read(debug_dir, SizeOf(TImageDebugDirectory)) <> SizeOf(TImageDebugDirectory)) then
    Exit;

  case debug_dir._Type of
    IMAGE_DEBUG_TYPE_UNKNOWN:
      Exit;
    IMAGE_DEBUG_TYPE_COFF:
      begin
        // http://waleedassar.blogspot.co.at/search/label/IMAGE_DEBUG_TYPE_COFF
        offset := debug_dir.PointerToRawData;
        FStream.Seek(offset, soFromBeginning);
        FStream.Read(coff_header, SizeOf(TImageCOFFSymbolsHeader));
      end;
    IMAGE_DEBUG_TYPE_CODEVIEW:
      begin
      end;
    IMAGE_DEBUG_TYPE_FPO: ;
    IMAGE_DEBUG_TYPE_MISC:
      begin
        offset := debug_dir.PointerToRawData;
        FStream.Seek(offset, soFromBeginning);
        FStream.Read(debug_misc, SizeOf(TImageDebugMisc));
        FStream.Seek(offset + SizeOf(TImageDebugMisc) - 1, soFromBeginning);
        if debug_misc.Unicode then begin
          FStream.Read(wide_name, debug_misc.Length);
        end else begin
          FStream.Read(ansi_name, debug_misc.Length);
        end;
      end;
    IMAGE_DEBUG_TYPE_EXCEPTION: ;
  else
    Exit;
  end;

//  offset := debug_dir.PointerToRawData;
//  FStream.Seek(offset, soFromBeginning);
//  FStream.Read(arr, Min(256, debug_dir.SizeOfData));
end;

procedure TPsePeFile.ReadMapFile;
var
  fn: string;
  reader: TPseMapFileReader;
  dii: TDebugInfoItem;
begin
  if FFileName <> '' then begin
    fn := ChangeFileExt(FFileName, '.map');
    if FileExists(fn) then begin
      reader := TPseMapFileReader.Create(fn);
      try
        while reader.GetNext(dii) do begin
          FDebugInfo.Add(dii);
        end;
      finally
        reader.Free;
      end;
    end;
  end;
end;

procedure TPsePeFile.ReadSections;
var
  i: integer;
  sech: TImageSectionHeader;
  sec: TPseSection;
  secname: AnsiString;
  attribs: TSectionAttribs;
begin
  FSections.Clear;
  for i := 0 to FImageHeader.NumberOfSections - 1 do begin
    if (FStream.Read(sech, SizeOf(TImageSectionHeader)) <> SizeOf(TImageSectionHeader)) then
      Break;
    attribs := [];
    sec := FSections.New;
    sec.Address := sech.VirtualAddress;
    sec.PointerToRawData := sech.PointerToRawData;
    sec.Size := sech.Misc.VirtualSize;
    sec.OrigAttribs := sech.Characteristics;
    secname := StrPas(PAnsiChar(@sech.Name));
    sec.Name := {$ifdef FPC}UTF8Decode{$else}UTF8ToString{$endif}(secname);
    if (sech.Characteristics and IMAGE_SCN_CNT_CODE) = IMAGE_SCN_CNT_CODE then
      Include(attribs, saCode);
    if (sech.Characteristics and IMAGE_SCN_CNT_INITIALIZED_DATA) = IMAGE_SCN_CNT_INITIALIZED_DATA then
      Include(attribs, saInitializedData);
    if (sech.Characteristics and IMAGE_SCN_CNT_UNINITIALIZED_DATA) = IMAGE_SCN_CNT_UNINITIALIZED_DATA then
      Include(attribs, saData);
    if (sech.Characteristics and IMAGE_SCN_MEM_EXECUTE) = IMAGE_SCN_MEM_EXECUTE then
      Include(attribs, saExecuteable);
    if (sech.Characteristics and IMAGE_SCN_MEM_READ) = IMAGE_SCN_MEM_READ then
      Include(attribs, saReadable);
    if (sech.Characteristics and IMAGE_SCN_MEM_WRITE) = IMAGE_SCN_MEM_WRITE then
      Include(attribs, saWriteable);

    sec.Attribs := attribs;
  end;
  for i := 0 to FSections.Count - 1 do begin
    sec := FSections[i];
    sec.FileOffset := RVAToOffset(sec.Address);
  end;
end;

procedure TPsePeFile.ReadExports;
var
  export_rva, offset: UInt64;
  expo: TImageExportDirectory;
  i: integer;
  expor: TPseExport;
  name: array[0..255] of AnsiChar;
  names: array[0..MAXWORD-1] of Cardinal;
  ordinals: array[0..MAXWORD-1] of Word;
  funcs: array[0..MAXWORD-1] of Cardinal;
begin
  FExports.Clear;
  if Is64 then begin
    export_rva := RVAToOffset(FOptHeader64.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress);
  end else begin
    export_rva := RVAToOffset(FOptHeader32.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress);
  end;
  if export_rva = 0 then
    // File has no exports
    Exit;

  FStream.Seek(export_rva, soFromBeginning);
  if (FStream.Read(expo, SizeOf(TImageExportDirectory)) <> SizeOf(TImageExportDirectory)) then
    Exit;

  FExports.NumNames := expo.NumberOfNames;
  FExports.NumFuncs := expo.NumberOfFunctions;
  FExports.Base := expo.Base;

  offset := RVAToOffset(expo.Name);
  FStream.Seek(offset, soFromBeginning);
  FillChar(name, 256, 0);
  FStream.Read(name, 256);
  FExports.Name := string(StrPas(PAnsiChar(@name)));

  offset := RVAToOffset(expo.AddressOfFunctions);
  FStream.Seek(offset, soFromBeginning);
  FStream.Read(funcs, FExports.NumFuncs * SizeOf(Cardinal));

  offset := RVAToOffset(expo.AddressOfNames);
  FStream.Seek(offset, soFromBeginning);
  FStream.Read(names, FExports.NumNames * SizeOf(Cardinal));

  offset := RVAToOffset(expo.AddressOfNameOrdinals);
  FStream.Seek(offset, soFromBeginning);
  FStream.Read(ordinals, FExports.NumFuncs * SizeOf(Word));

  for i := 0 to FExports.NumFuncs - 1 do begin
    expor := FExports.New;
    if i < FExports.NumNames then begin
      FillChar(name, 256, 0);
      offset := RVAToOffset(names[i]);
      FStream.Seek(offset, soFromBeginning);
      FStream.Read(name, 256);
      expor.Name := string(StrPas(PAnsiChar(@name)));
      expor.Ordinal := ordinals[i];
    end else begin
      expor.Name := '(No name)';
      expor.Ordinal := i;
    end;
    expor.Address := funcs[expor.Ordinal];
    expor.Ordinal := expor.Ordinal + 1;
  end;
end;

procedure TPsePeFile.ReadDelayImports;
var
  impo_list: TList;

  procedure AddToImpo(impo: TImgDelayDescr);
  var
    pi: PImgDelayDescr;
  begin
    New(pi);
    Move(impo, pi^, SizeOf(TImgDelayDescr));
    impo_list.Add(pi);
  end;
var
  import_rva, offset: UInt64;
  did: TImgDelayDescr;
  pimpo: PImgDelayDescr;
  i: integer;
  name: array[0..255] of AnsiChar;
  import_obj: TPseImport;
  thunk64: TImageThunkData64;
  thunk32: TImageThunkData32;
  stream_pos: Int64;
  imp_api: TPseApi;
  name_hint: Word;
begin
  if Is64 then begin
    import_rva := RVAToOffset(FOptHeader64.DataDirectory[IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT].VirtualAddress);
  end else begin
    import_rva := RVAToOffset(FOptHeader32.DataDirectory[IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT].VirtualAddress);
  end;
  if (import_rva = 0) then
    Exit;

  impo_list := TList.Create;
  try
    FStream.Seek(import_rva, soFromBeginning);
    if (FStream.Read(did, SizeOf(TImgDelayDescr)) <> SizeOf(TImgDelayDescr)) then
      Exit;

    while (did.rvaDLLName <> 0) do begin
      AddToImpo(did);
      if (FStream.Read(did, SizeOf(TImgDelayDescr)) <> SizeOf(TImgDelayDescr)) then
        Break;
    end;

    for i := 0 to impo_list.Count - 1 do begin
      offset := RVAToOffset(PImgDelayDescr(impo_list[i])^.rvaDLLName);
      if offset = 0 then
        Continue;

      import_obj := FImports.New;
      import_obj.DelayLoad := true;
      FillChar(name, 256, 0);
      FStream.Seek(offset, soFromBeginning);
      FStream.Read(name, 256);
      import_obj.DllName := string(StrPas(PAnsiChar(@name)));

      offset := RVAToOffset(PImgDelayDescr(impo_list[i])^.rvaINT);
      FStream.Seek(offset, soFromBeginning);
      if Is64 then begin
        FStream.Read(thunk64, SizeOf(TImageThunkData64));
        while thunk64._Function <> 0 do begin
          imp_api := import_obj.New;
          stream_pos := FStream.Position;
          FStream.Seek(RVAToOffset(thunk64.AddressOfData), soFromBeginning);
          FStream.Read(name_hint, SizeOf(Word));
          imp_api.Hint := name_hint;
          if (thunk64.Ordinal and IMAGE_ORDINAL_FLAG64) = 0 then begin
            FillChar(name, 256, 0);
            FStream.Read(name, 256);
            imp_api.Name := string(StrPas(PAnsiChar(@name)));
          end;
          imp_api.Address := thunk64._Function;
          FStream.Position := stream_pos;
          FStream.Read(thunk64, SizeOf(TImageThunkData64));
        end;
      end else begin
        FStream.Read(thunk32, SizeOf(TImageThunkData32));
        while thunk32._Function <> 0 do begin
          imp_api := import_obj.New;
          stream_pos := FStream.Position;
          FStream.Seek(RVAToOffset(thunk32.AddressOfData), soFromBeginning);
          FStream.Read(name_hint, SizeOf(Word));
          imp_api.Hint := name_hint;
          if (thunk32.Ordinal and IMAGE_ORDINAL_FLAG32) = 0 then begin
            FillChar(name, 256, 0);
            FStream.Read(name, 256);
            imp_api.Name := string(StrPas(PAnsiChar(@name)));
          end;
          imp_api.Address := (thunk32._Function);

          FStream.Position := stream_pos;
          FStream.Read(thunk32, SizeOf(TImageThunkData32));
        end;

      end;
    end;
  finally
    for i := 0 to impo_list.Count - 1 do begin
      pimpo := PImgDelayDescr(impo_list[i]);
      Dispose(pimpo);
    end;
    impo_list.Free
  end;
end;

procedure TPsePeFile.ReadImports;
var
  impo_list: TList;

  procedure AddToImpo(impo: TImageImportDescriptor);
  var
    pi: PImageImportDescriptor;
  begin
    New(pi);
    Move(impo, pi^, SizeOf(TImageImportDescriptor));
    impo_list.Add(pi);
  end;

var
  import_rva, offset: UInt64;
  impo: TImageImportDescriptor;
  pimpo: PImageImportDescriptor;
  name_hint: Word;
  i: integer;
  name: array[0..255] of AnsiChar;
  import_obj: TPseImport;
  imp_api: TPseApi;
  api_names: Cardinal;
  thunk64: TImageThunkData64;
  thunk32: TImageThunkData32;
  stream_pos: Int64;
begin
  FImports.Clear;
  if Is64 then begin
    import_rva := RVAToOffset(FOptHeader64.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress);
  end else begin
    import_rva := RVAToOffset(FOptHeader32.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress);
  end;
  if (import_rva = 0) then
    // Hm, really no imports
    Exit;

  impo_list := TList.Create;
  try
    FStream.Seek(import_rva, soFromBeginning);
    if (FStream.Read(impo, SizeOf(TImageImportDescriptor)) <> SizeOf(TImageImportDescriptor)) then
      Exit;
    while ((impo.FirstThunk <> 0) and (impo.Name <> 0)) do begin
      AddToImpo(impo);
      if (FStream.Read(impo, SizeOf(TImageImportDescriptor)) <> SizeOf(TImageImportDescriptor)) then
        Break;
    end;

    for i := 0 to impo_list.Count - 1 do begin
      import_obj := FImports.New;
      offset := RVAToOffset(PImageImportDescriptor(impo_list[i])^.Name);
      FillChar(name, 256, 0);
      FStream.Seek(offset, soFromBeginning);
      FStream.Read(name, 256);
      import_obj.DllName := string(StrPas(PAnsiChar(@name)));
      import_obj.IatRva := PImageImportDescriptor(impo_list[i])^.FirstThunk;

      if PImageImportDescriptor(impo_list[i])^.OriginalFirstThunk <> 0 then
      begin
        api_names := PImageImportDescriptor(impo_list[i])^.OriginalFirstThunk;
      end
      else
      begin
        api_names := PImageImportDescriptor(impo_list[i])^.FirstThunk;
      end;

      if RVAToOffset(api_names) <> 0 then
        api_names := RVAToOffset(api_names);

      FStream.Seek(api_names, soFromBeginning);
      if Is64 then begin
        FStream.Read(thunk64, SizeOf(TImageThunkData64));
        while thunk64._Function <> 0 do begin
          imp_api := import_obj.New;
          stream_pos := FStream.Position;
          FStream.Seek(RVAToOffset(thunk64.AddressOfData), soFromBeginning);
          FStream.Read(name_hint, SizeOf(Word));
          imp_api.Hint := name_hint;
          if (thunk64.Ordinal and IMAGE_ORDINAL_FLAG64) = 0 then begin
            FillChar(name, 256, 0);
            FStream.Read(name, 256);
            imp_api.Name := string(StrPas(PAnsiChar(@name)));
          end;
          imp_api.Address := thunk64._Function;
          FStream.Position := stream_pos;
          FStream.Read(thunk64, SizeOf(TImageThunkData64));
        end;
      end else begin
        FStream.Read(thunk32, SizeOf(TImageThunkData32));
        while thunk32._Function <> 0 do begin
          imp_api := import_obj.New;
          stream_pos := FStream.Position;
          FStream.Seek(RVAToOffset(thunk32.AddressOfData), soFromBeginning);
          FStream.Read(name_hint, SizeOf(Word));
          imp_api.Hint := name_hint;
          if (thunk32.Ordinal and IMAGE_ORDINAL_FLAG32) = 0 then begin
            FillChar(name, 256, 0);
            FStream.Read(name, 256);
            imp_api.Name := string(StrPas(PAnsiChar(@name)));
          end;
          imp_api.Address := (thunk32._Function);

          FStream.Position := stream_pos;
          FStream.Read(thunk32, SizeOf(TImageThunkData32));
        end;
      end;
    end;
  finally
    for i := 0 to impo_list.Count - 1 do begin
      pimpo := PImageImportDescriptor(impo_list[i]);
      Dispose(pimpo);
    end;
    impo_list.Free;
  end;
end;

function TPsePeFile.RVAToOffset(const RVA: UInt64): UInt64;
var
  r: UInt64;
  i: integer;
begin
  r := RVA;
  if (r > GetSizeOfImage) then begin
    if (r > GetImageBase) then begin
      Dec(r, GetImageBase);
      if (r > GetSizeOfImage) then
        Exit(0);
    end else
      Exit(0);
  end;

  for i := 0 to FImageHeader.NumberOfSections - 1 do begin
    if (r >= FSections[i].Address) and (r < (FSections[i].Address + FSections[i].Size)) then
      Exit(r - FSections[i].Address + FSections[i].PointerToRawData);
  end;
  if r > 0 then
  begin
    Result := r;
  end
  else
    Result := 0;
end;

function TPsePeFile.GetCodeSection(out AAddr, ASize: UInt64): boolean;
var
  i: integer;
  sec: TPseSection;
begin
  for i := 0 to FSections.Count - 1 do begin
    sec := FSections[i];
    if (saCode in sec.Attribs) and (saExecuteable in sec.Attribs) then begin
      AAddr := sec.Address;
      ASize := sec.Size;
      Exit(true);
    end;
  end;
  Result := false;
end;

function TPsePeFile.GetInitStackSize: UInt64;
begin
  case FImageHeader.Machine of
    IMAGE_FILE_MACHINE_I386:
      begin
        Result := FOptHeader32.SizeOfStackCommit;
      end;
    IMAGE_FILE_MACHINE_AMD64, IMAGE_FILE_MACHINE_IA64:
      begin
        Result := FOptHeader64.SizeOfStackCommit;
      end;
    else
      Result := inherited;
  end;
end;

function TPsePeFile.GetMaxStackSize: UInt64;
begin
  case FImageHeader.Machine of
    IMAGE_FILE_MACHINE_I386:
      begin
        Result := FOptHeader32.SizeOfStackReserve;
      end;
    IMAGE_FILE_MACHINE_AMD64, IMAGE_FILE_MACHINE_IA64:
      begin
        Result := FOptHeader64.SizeOfStackReserve;
      end;
    else
      Result := inherited;
  end;
end;

function TPsePeFile.GetInitHeapSize: UInt64;
begin
  case FImageHeader.Machine of
    IMAGE_FILE_MACHINE_I386:
      begin
        Result := FOptHeader32.SizeOfHeapCommit;
      end;
    IMAGE_FILE_MACHINE_AMD64, IMAGE_FILE_MACHINE_IA64:
      begin
        Result := FOptHeader64.SizeOfHeapCommit;
      end;
    else
      Result := inherited;
  end;
end;

function TPsePeFile.GetMaxHeapSize: UInt64;
begin
  case FImageHeader.Machine of
    IMAGE_FILE_MACHINE_I386:
      begin
        Result := FOptHeader32.SizeOfHeapReserve;
      end;
    IMAGE_FILE_MACHINE_AMD64, IMAGE_FILE_MACHINE_IA64:
      begin
        Result := FOptHeader64.SizeOfHeapReserve;
      end;
    else
      Result := inherited;
  end;
end;

function TPsePeFile.GetFirstAddr: UInt64;
var
  addr, size: UInt64;
begin
  if GetCodeSection(addr, size) then begin
    Result := addr + GetImageBase;
  end else
    Result := 0;
end;

function TPsePeFile.GetImageBase: UInt64;
begin
  case FImageHeader.Machine of
    IMAGE_FILE_MACHINE_I386:
      begin
        Result := FOptHeader32.ImageBase;
      end;
    IMAGE_FILE_MACHINE_AMD64, IMAGE_FILE_MACHINE_IA64:
      begin
        Result := FOptHeader64.ImageBase;
      end;
    else
      Result := 0;
  end;
end;

function TPsePeFile.GetSizeOfImage: Cardinal;
begin
  case FImageHeader.Machine of
    IMAGE_FILE_MACHINE_I386:
      begin
        Result := FOptHeader32.SizeOfImage;
      end;
    IMAGE_FILE_MACHINE_AMD64, IMAGE_FILE_MACHINE_IA64:
      begin
        Result := FOptHeader64.SizeOfImage;
      end;
    else
      Result := 0;
  end;
end;

function TPsePeFile.GetNumberOfSections: Cardinal;
begin
  Result := FImageHeader.NumberOfSections;
end;

function TPsePeFile.GetEntryPoint: UInt64;
begin
  case FImageHeader.Machine of
    IMAGE_FILE_MACHINE_I386:
      begin
        Result := UInt64(FOptHeader32.AddressOfEntryPoint) + UInt64(FOptHeader32.ImageBase);
      end;
    IMAGE_FILE_MACHINE_AMD64, IMAGE_FILE_MACHINE_IA64:
      begin
        Result := FOptHeader64.AddressOfEntryPoint + FOptHeader64.ImageBase;
      end;
    else
      Result := 0;
  end;
end;

function TPsePeFile.GetArch: TPseArch;
begin
  case FImageHeader.Machine of
    IMAGE_FILE_MACHINE_I386,
    IMAGE_FILE_MACHINE_AMD64:
      begin
        Result := pseaX86;
      end;
    IMAGE_FILE_MACHINE_R3000,
    IMAGE_FILE_MACHINE_R4000,
    IMAGE_FILE_MACHINE_R10000:
      begin
        Result := pseaMIPS;
      end;
    IMAGE_FILE_MACHINE_POWERPC:
      begin
        Result := pseaPPC;
      end
    else
      Result := pseaUnknown;
  end;
end;

function TPsePeFile.GetMode: TPseMode;
begin
  case FImageHeader.Machine of
    IMAGE_FILE_MACHINE_I386:
      begin
        Result := [psem32];
      end;
    IMAGE_FILE_MACHINE_AMD64,
    IMAGE_FILE_MACHINE_IA64:
      begin
        Result := [psem64];
      end;
    else
      Result := [];
  end;
end;

function TPsePeFile.GetMachineString: string;
begin
  Result := PsePe.GetMachineString(FImageHeader.Machine);
end;

function TPsePeFile.GetCharacteristicsString: string;
begin
  Result := PsePe.GetCharacteristicsString(FImageHeader.Characteristics);
end;

function TPsePeFile.GetSubsystemString: string;
var
  ssys: Word;
begin
  if Is64 then
    ssys := FOptHeader64.Subsystem
  else
    ssys := FOptHeader32.Subsystem;
  Result := PsePe.GetSubsystemString(ssys);
end;

function TPsePeFile.GetFriendlyName: string;
begin
  Result := 'PE';
  if Is64 then
    Result := Result + '64'
  else
    Result := Result + '32';
end;

initialization

end.

program pse;

{$ifdef MSWINDOWS}
  {$APPTYPE CONSOLE}
{$endif}
{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  SysUtils,
  Classes,
  PseDebugInfo in 'PseDebugInfo.pas',
  PseElf in 'PseElf.pas',
  PseElfFile in 'PseElfFile.pas',
  PseExportTable in 'PseExportTable.pas',
  PseFile in 'PseFile.pas',
  PseImportTable in 'PseImportTable.pas',
  PseLibFile in 'PseLibFile.pas',
  PseMapFileReader in 'PseMapFileReader.pas',
  PseMzFile in 'PseMzFile.pas',
  PseNeFile in 'PseNeFile.pas',
  PseObjFile in 'PseObjFile.pas',
  PsePe in 'PsePe.pas',
  PsePeFile in 'PsePeFile.pas',
  PseRawFile in 'PseRawFile.pas',
  PseSection in 'PseSection.pas',
  PseCmn in 'PseCmn.pas',
  PseMz in 'PseMz.pas',
  PseImgLoader in 'PseImgLoader.pas',
  PsePeLoader in 'PsePeLoader.pas',
  PseVirtMem in 'PseVirtMem.pas',
  PseElfLoader in 'PseElfLoader.pas',
  PseNe in 'PseNe.pas',
  PseResource in 'PseResource.pas';

function isprint(const AC: AnsiChar): boolean;
begin
  Result := (AC >= ' ') and (AC <= '~') and (Ord(AC) <> $7F);
end;

var
  filename: string;
  PseFile: TPseFile;
  i, j, c, k: integer;
  sec: TPseSection;
  imp: TPseImport;
  api: TPseApi;
  expo: TPseExport;
  mem: TPseVirtMem;
  mem_base: UInt64;
  mem_initsize, mem_maxsize: UInt64;
  res: boolean;
  seg: TPseMemSegment;
  seg_flags: string;
  buff: array[0..15] of Byte;
  addr: UInt64;
  print_mem: boolean;
  res_item: TPseResource;
  res_stream: TMemoryStream;
begin
  // Register files we need
  TPseFile.RegisterFile(TPsePeFile);
  TPseFile.RegisterFile(TPseElfFile);
  TPseFile.RegisterFile(TPseNeFile);
  TPseFile.RegisterFile(TPseMzFile);
  // If its not one of the above load it as raw file
  TPseFile.RegisterFile(TPseRawFile);

  if ParamCount = 0 then begin
    WriteLn('pse <filename> [-mem]');
    Halt(1);
  end;
  filename := ParamStr(1);
  if not FileExists(filename) then begin
    WriteLn(Format('File %s not found', [filename]));
    Halt(1);
  end;
  print_mem := (ParamCount > 1) and (ParamStr(2) = '-mem');

  PseFile := TPseFile.GetInstance(filename, false);
  if not Assigned(PseFile) then begin
    WriteLn('Unsupported file');
    Halt(1);
  end;
  try
    WriteLn(PseFile.GetFriendlyName);
    WriteLn(Format('Architecture: %s', [ARCH_STRING[PseFile.GetArch]]));
    WriteLn(Format('Entry point 0x%x', [PseFile.GetEntryPoint]));

    WriteLn(Format('%d Sections', [PseFile.Sections.Count]));
    for i := 0 to PseFile.Sections.Count - 1 do begin
      sec := PseFile.Sections[i];
      WriteLn(Format('  %s: Address 0x%x, Size %d', [sec.Name, sec.Address, sec.Size]));
    end;

    WriteLn(Format('%d Imports', [PseFile.ImportTable.Count]));
    for i := 0 to PseFile.ImportTable.Count - 1 do begin
      imp := PseFile.ImportTable[i];
      Write(Format('  %s', [imp.DllName]));
      if imp.DelayLoad then
        Write(' (delay load)');
      WriteLn(':');
      for j := 0 to imp.Count - 1 do begin
        api := imp[j];
        WriteLn(Format('  %s: Hint %d, Address: 0x%x', [api.Name, api.Hint, api.Address]));
      end;
    end;

    WriteLn(Format('%d Exports', [PseFile.ExportTable.Count]));
    for i := 0 to PseFile.ExportTable.Count - 1 do begin
      expo := PseFile.ExportTable[i];
      WriteLn(Format('  %s: Ordinal %d, Address: 0x%x', [expo.Name, expo.Ordinal, expo.Address]));
    end;

    WriteLn(Format('%d Resources', [PseFile.Resources.Count]));
//    res_stream := TMemoryStream.Create;
    try
      for i := 0 to PseFile.Resources.Count - 1 do begin
        res_item := PseFile.Resources[i];
        WriteLn(Format('  ID: %d, Type: %d (%s), Offset: %u, Size: %u', [res_item.ResId,
          res_item.ResType, res_item.GetWinTypeString, res_item.Offset, res_item.Size]));
//        res_stream.Clear;
//        res_item.SaveToStream(res_stream);
//        res_stream.SaveToFile(Format('test/res_%s_%d.dat', [res_item.GetWinTypeString, res_item.ResId]));
      end;
    finally
//      res_stream.Free;
    end;

    mem_base := 0;
    mem_initsize := PseFile.GetInitHeapSize;
    mem_maxsize := PseFile.GetMaxHeapSize;
    if PseFile is TPsePeFile then begin
      mem_base := TPsePeFile(PseFile).GetImageBase;
    end else if PseFile is TPseElfFile then begin
      mem_base := TPseElfFile(PseFile).GetImageBase;
    end;

    // load .
    mem := TPseVirtMem.Create(mem_base, mem_initsize, mem_maxsize);
    try
      res := TPseImgLoader.LoadFile(PseFile, mem);
      if res then begin
        WriteLn(Format('Virtual memory (Base = 0x%x, Size = %u) has %d segments:', [mem.MemBase, mem.Size, mem.Count]));
        for i := 0 to mem.Count - 1 do begin
          seg := mem.Items[i];
          seg_flags := '';
          if (pmfExecute in seg.Flags) then
            seg_flags := seg_flags + ' Execute';
          if (pmfRead in seg.Flags) then
            seg_flags := seg_flags + ' Read';
          if (pmfWrite in seg.Flags) then
            seg_flags := seg_flags + ' Write';
          seg_flags := Trim(seg_flags);
          WriteLn(Format('  %s: Base = 0x%x, Size = %u, Flags = %s', [seg.Name, seg.Base, seg.Size, seg_flags]));
          // Print content of segment
          if print_mem then begin
            WriteLn('  Contents of segment:');
            j := 0;
            c := 0;
            repeat
              addr := seg.Base + (j * SizeOf(buff));
              try
              c := seg.Read(addr, buff, SizeOf(buff));
              except
                Break;
              end;
              Write(Format('    0x%.16x: ', [addr]));
              for k := Low(buff) to High(buff) do begin
                Write(Format('%.2x ', [buff[k]]));
              end;
              Write('  ');
              for k := Low(buff) to High(buff) do begin
                if isprint(AnsiChar(buff[k])) then
                  Write(Format('%s', [AnsiChar(buff[k])]))
                else
                  Write('.');
              end;
              Inc(j);
              WriteLn;
            until c <> SizeOf(buff);
          end;
        end;
      end else begin
        WriteLn('Error loading file into virtual memory');
      end;
    finally
      mem.Free;
    end;

  finally
    PseFile.Free;
  end;
end.


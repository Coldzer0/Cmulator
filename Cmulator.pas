program Cmulator;


{$MODE Delphi}
{$PackRecords C}
{$codepage UTF8}

uses
  {$IFDEF unix}
  cthreads,BaseUnix,
  {$ENDIF}
  {$IFDEF WINDOWS}
  windows,
  {$ENDIF}
  cmem,ctypes,math,Crt,dynlibs,
  SysUtils,Classes,
  {$I Core/besenunits.inc},
  Globals,
  Unicorn_dyn, UnicornConst, Emu,
  JSPlugins_BEngine,superobject,
  PE.Common, // using TRVA .
  PE.Image,
  PE.Section,
  PE.ExportSym,
  PE.Imports.Lib,  // using TPEImportLibrary .
  PE.Imports.Func, // using TPEImportFunction .
  PE.Types.Directories,
  //GUI,
  FileUtil,Utils,TEP_PEB;



procedure info();
var
  major, minor : Cardinal;
begin
  major := 0; minor := 0;
  Writeln (#10'Cmulator Malware Analyzer - By Coldzer0',#10);
  Writeln (      'Compiled on      : ',{$I %DATE%}, ' - ' ,{$I %TIME%});
  Writeln (      'Target CPU       : i386 & x86_x64');
  uc_version(major, minor);
  Writeln(format('Unicorn Engine   : v%d.%d ',[major,minor]));
  Writeln('Cmulator         : v0.1'#10);
end;

procedure Help();
begin
  info();
  Writeln('Usage Example : ' , ParamStr(0) , ' -file ./Mal.exe -q');
  Writeln('   -f        Path to PE or ShellCode file to Emulate .');
  Writeln('   -s        Number of Steps Limit if 0 then it''s Unlimited - (default = 2000000) , ');
  Writeln('             But it works different with Quick Mode - it will increment ,');
  Writeln('             On any bransh like call jmp jz ret etc.. , so use smaller value .');
  Writeln();
  Writeln('   -q        Quick Mode to make Execution Faster But no disasm,');
  Writeln('             [x] In Quick Mode AddressHooks will not work');
  Writeln();
  Writeln('   -asm      Show Assembly instructions .');
  Writeln('   -x64      By default Cmulator Detect the PE Mode But this one for x64 ShellCodes .');
  Writeln('   -sc       To Notify Cmulator that the File is ShellCode .');
  WriteLn('   -ex       show SEH Excptions Address and Handlers');
  Writeln();
  Writeln('   -v        Show Some Info When Calling an API and Some Other Stuff .');
  Writeln('   -vv       Like -v But with more info .');
  Writeln('   -vv       Like -vv But with much much more more info :D - use at your own risk :P .');
  Writeln();
  Writeln();
end;

procedure LoadConfig();
var
  conf : TStrings;
  JSON : ISuperObject;
  data : string;
begin
  conf := TStringList.Create;
  if FileExists('./config.json') then
  begin
    conf.LoadFromFile('./config.json');
    data := conf.Text;
    JSON := SO(UnicodeString(data));

    win32 := JSON.S['system.win32'];
    win64 := JSON.S['system.win64'];
    JSAPI := JSON.S['JS.main'];

    if not FileExists(JSAPI) then
    begin
      Writeln('JS Main Script not found - Check the config file !');
      halt;
    end;

    if not DirectoryExists(win32) then
    begin
      Writeln('win32 dlls Folder not found - Check the config file !');
      halt;
    end;
    if not DirectoryExists(win64) then
    begin
      Writeln('win64 dlls Folder not found - Check the config file !');
      halt;
    end;
  end
  else
  begin
    Writeln('Confing file not found !');
    halt;
  end;
end;

var
  FilePath : String;
  i : integer;
  IsShellcode : boolean = False;
  SCx64 : Boolean = False;
begin
  //test; exit;
  FilePath := '';
  LoadConfig();

  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}

  if Paramcount = 0 then
  begin
    Writeln();
    Help();
    halt(0);
  end;
  for i := 1 to Paramcount do
  begin
    if LowerCase(ParamStr(i)) = '-h' then
    begin
      Writeln();
      Help();
      halt(0);
    end;
    if LowerCase(ParamStr(i)) = '-ex' then
    begin
      VerboseExcp := True;
    end;
    if LowerCase(ParamStr(i)) = '-x64' then
    begin
      SCx64 := True;
    end;
    if LowerCase(ParamStr(i)) = '-sc' then
    begin
      IsShellcode := True;
    end;
    if LowerCase(ParamStr(i)) = '-f' then
    begin
      FilePath := ParamStr(i+1);
      if not FileExists(FilePath) then
      begin
        Writeln();
        Writeln(Format('[x] file "%s" not found',[FilePath]));
        Help();
        halt(0);
      end;
    end;
    if LowerCase(ParamStr(i)) = '-s' then
    begin
      if not TryStrToQWord(ParamStr(i+1),Steps_limit) then
      begin
        Writeln('[x] Please Enter Steps as number ! - Ex: -s 1000');
        halt(0);
      end;
    end;
    if LowerCase(ParamStr(i)) = '-v' then
    begin
      Verbose := True;
    end;
    if LowerCase(ParamStr(i)) = '-vv' then
    begin
      Verbose   := true;
      VerboseEx := Verbose;
    end;
    if LowerCase(ParamStr(i)) = '-vvv' then
    begin
      Verbose    := true;
      VerboseEx  := Verbose;
      VerboseExx := Verbose;
    end;
    if LowerCase(ParamStr(i)) = '-asm' then
    begin
      ShowASM := True;
    end;
    if LowerCase(ParamStr(i)) = '-q' then
    begin
      Speed := True;
    end;
  end;
  info();

  if Speed and ShowASM then
  begin
    TextColor(LightRed);
    Writeln('Can''t Use Quick Mode with ASM Mode');
    Writeln();
    NormVideo;
    halt(0);
  end;

  Randomize; // don't remove this :D - it's here for a reason :P .

  Emulator := TEmu.Create(FilePath,IsShellcode,SCx64);

  js := TBESENInstance.Create(); // ini JS Plugin system ..

  Emulator.Start;

  Writeln(#10#10);
  Writeln('Press Enter to Close ¯\_(ツ)_/¯');
  //ReadLn;
end.

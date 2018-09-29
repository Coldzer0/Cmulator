{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseLibFile;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseFile;

type
  {
    COFF archive format: .lib, MinGW .a files.
    May (static lib file) or may not (dynamic lib file) the contents of one or
    more COFF OBJ files.

    References
      Micosoft. Microsoft Portable Executable and Common Object File Format
        Specification. Microsoft, February 2013.
  }
  TLibFile = class(TPseFile)

  end;

implementation

initialization
//  TSadFile.RegisterFile(TLibFile, 2);

end.

{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseObjFile;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseFile;

type
  {
    COFF OBJ files.
  }
  TPseObjFile = class(TPseFile)

  end;

implementation

initialization
//  TSadFile.RegisterFile(TObjFile, 2);

end.

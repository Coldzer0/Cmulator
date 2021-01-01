unit Globals;

{$mode delphi}

interface

uses
  Classes, SysUtils, Emu, quickjs, Unicorn_dyn;


{
Given a version number MAJOR.MINOR.PATCH, increment the:

MAJOR version when you make incompatible API changes,
MINOR version when you add functionality in a backwards-compatible manner, and
PATCH version when you make backwards-compatible bug fixes.
}
const
  CM_VERSION = 'v0.3.0';

  microseconds : UInt64 = 1000000;

var
  VerboseExcp  : Boolean = False;
  Verbose      : Boolean = False;
  VerboseEx    : Boolean = False;
  VerboseExx   : Boolean = False;
  Speed        : Boolean = False;
  ShowASM      : Boolean = False;
  InterActive  : Boolean = False; // TODO .
//============================================================================//
  Steps_limit  : UInt64 = 4000000; // 0 = unlimited .
  Steps        : UInt64 = 0;

  Emulator   : TEmu;

  rt  : JSRuntime = nil;
  ctx : JSContext = nil;
  JSEmu : JSValue;

  //HOOK_BASE,HOOK_INDEX,HOOK_LIB,HOOK_Fn : UInt64;

  win32 : UnicodeString = '';
  win64 : UnicodeString = '';

  JSAPI : AnsiString = '';
  ApiSetSchemaPath : UnicodeString = '';

implementation

end.


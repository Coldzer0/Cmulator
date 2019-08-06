unit Globals;

{$mode delphi}

interface

uses
  Classes, SysUtils, Emu,JSPlugins_BEngine,
  {$I besenunits.inc},Unicorn_dyn;


{
Given a version number MAJOR.MINOR.PATCH, increment the:

MAJOR version when you make incompatible API changes,
MINOR version when you add functionality in a backwards-compatible manner, and
PATCH version when you make backwards-compatible bug fixes.
}
const
  CM_VERSION = 'v0.2.1';

var
  VerboseExcp  : Boolean = False;
  Verbose      : Boolean = False;
  VerboseEx    : Boolean = False;
  VerboseExx   : Boolean = False;
  Speed        : Boolean = False;
  ShowASM      : Boolean = False;
  InterActive  : Boolean = False; // TODO .
//============================================================================//
  Steps_limit  : UInt64 = 2000000; // 0 = unlimited .
  Steps        : UInt64 = 0;

  Emulator   : TEmu;

  JS : TBESENInstance;
  JSEmu : TBESENObject;

  //HOOK_BASE,HOOK_INDEX,HOOK_LIB,HOOK_Fn : UInt64;

  win32 : UnicodeString = '';
  win64 : UnicodeString = '';

  JSAPI : UnicodeString = '';
  ApiSetSchemaPath : UnicodeString = '';

implementation

end.


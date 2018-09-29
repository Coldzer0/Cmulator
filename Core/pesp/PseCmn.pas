{
  Pascal Executable Parser

  by sa, 2014,2015
}

unit PseCmn;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

const
  MAXBYTE = 255;
  MAXWORD = 65535;

type
  TPseBitness = (psebUnknown, pseb16, pseb32, pseb64);

  TPseArch = (
    pseaARM,
    pseaARM64,
    pseaMIPS,
    pseaX86,
    pseaPPC,
    pseaSPARC,
    pseaSysZ,
    pseaXCore,
    pseaUnknown
  );

  TPseMode = set of (
    psemLittleEndian,
    psemARM,
    psem16,
    psem32,
    psem64,
    psemThumb,
    psemMClass,
    psemV8,
    psemMicro,
    psemMips3,
    psemMips3R6,
    psemMipsGP64,
    psemV9,
    psemBigEndian
  );

const
  BITNESS_STRING: array[TPseBitness] of string = ('Unknown', '16', '32', '64');
  ARCH_STRING: array[TPseArch] of string = ('ARM', 'ARM64', 'MIPS', 'x86', 'PowerPC',
    'SPARC', 'SystemZ', 'XCore', 'Unknown');

implementation

end.

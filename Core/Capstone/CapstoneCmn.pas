unit CapstoneCmn;
{$SMARTLINK ON}
interface

type
  TCsArch = (
    csaARM,
    csaARM64,
    csaMIPS,
    csaX86,
    csaPPC,
    csaSPARC,
    csaSysZ,
    csaXCore,
    csaUnknown
  );

  TCsMode = set of (
    csmLittleEndian,
    csmARM,
    csm16,
    csm32,
    csm64,
    csmThumb,
    csmMClass,
    csmV8,
    csmMicro,
    csmMips3,
    csmMips3R6,
    csmMipsGP64,
    csmV9,
    csmBigEndian
  );

implementation

end.

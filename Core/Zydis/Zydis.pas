{***************************************************************************************************

  Zydis API

  Original Author : Florian Bernd

 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.

***************************************************************************************************}

unit Zydis;
{$WARN 3031 off : Values in enumeration types have to be ascending}
{$IFDEF FPC}
  {$MODE DELPHI}
  {$WARNINGS OFF}
  {$HINTS OFF}
{$ENDIF}
interface

{.$DEFINE ZYDIS_DYNAMIC_LINK}

{* ============================================================================================== *}
{* Constants                                                                                      *}
{* ============================================================================================== *}
const
  ZYDIS_VERSION                = $0002000000030000;

  ZYDIS_MAX_INSTRUCTION_LENGTH = 15;
  ZYDIS_MAX_OPERAND_COUNT      = 10;

{* ============================================================================================== *}
{* Enums and types                                                                                *}
{* ============================================================================================== *}
type
{* ---------------------------------------------------------------------------------------------- *}
{* Common types                                                                                   *}
{* ---------------------------------------------------------------------------------------------- *}

  ZydisU8       = UInt8;
  ZydisU16      = UInt16;
  ZydisU32      = UInt32;
  ZydisU64      = UInt64;
  ZydisI8       = Int8;
  ZydisI16      = Int16;
  ZydisI32      = Int32;
  ZydisI64      = Int64;
  ZydisUSize    = NativeUInt;
  ZydisISize    = NativeInt;
  ZydisUPointer = UIntPtr;
  ZydisIPointer = IntPtr;
  ZydisBool     = Boolean;

{* ---------------------------------------------------------------------------------------------- *}
{* Generated enums                                                                                *}
{* ---------------------------------------------------------------------------------------------- *}

  {$I 'Generated/Zydis.Enum.Register.inc'}
  {$I 'Generated/Zydis.Enum.Mnemonic.inc'}
  {$I 'Generated/Zydis.Enum.InstructionCategory.inc'}
  {$I 'Generated/Zydis.Enum.ISASet.inc'}
  {$I 'Generated/Zydis.Enum.ISAExt.inc'}

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisStatus                                                                                    *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z4}
  TZydisStatus = (
    ZYDIS_STATUS_SUCCESS                    = $00000000,
    ZYDIS_STATUS_INVALID_PARAMETER,
    ZYDIS_STATUS_INVALID_OPERATION,
    ZYDIS_STATUS_INSUFFICIENT_BUFFER_SIZE,
    ZYDIS_STATUS_NO_MORE_DATA,
    ZYDIS_STATUS_DECODING_ERROR,
    ZYDIS_STATUS_INSTRUCTION_TOO_LONG,
    ZYDIS_STATUS_BAD_REGISTER,
    ZYDIS_STATUS_ILLEGAL_LOCK,
    ZYDIS_STATUS_ILLEGAL_LEGACY_PREFIX,
    ZYDIS_STATUS_ILLEGAL_REX,
    ZYDIS_STATUS_INVALID_MAP,
    ZYDIS_STATUS_MALFORMED_EVEX,
    ZYDIS_STATUS_MALFORMED_MVEX,
    ZYDIS_STATUS_INVALID_MASK,
    ZYDIS_STATUS_SKIP_OPERAND,
    ZYDIS_STATUS_IMPOSSIBLE_INSTRUCTION,
    ZYDIS_STATUS_USER                       = $10000000
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisLetterCase                                                                                *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisLetterCase = (
    ZYDIS_LETTER_CASE_DEFAULT,
    ZYDIS_LETTER_CASE_LOWER,
    ZYDIS_LETTER_CASE_UPPER,

    ZYDIS_LETTER_CASE_MAX_VALUE = ZYDIS_LETTER_CASE_UPPER
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisString                                                                                    *}
{* ---------------------------------------------------------------------------------------------- *}

  PZydisStaticString = ^TZydisStaticString;
  TZydisStaticString = record
  public
    Buffer: PAnsiChar;
    Length: ZydisU8;
  end;

  PZydisString = ^TZydisString;
  TZydisString = record
  public
    Buffer: PAnsiChar;
    Length: ZydisUSize;
    Capacity: ZydisUSize;
  end;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisRegisterClass                                                                             *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisRegisterClass = (
    ZYDIS_REGCLASS_INVALID,
    ZYDIS_REGCLASS_GPR8,
    ZYDIS_REGCLASS_GPR16,
    ZYDIS_REGCLASS_GPR32,
    ZYDIS_REGCLASS_GPR64,
    ZYDIS_REGCLASS_X87,
    ZYDIS_REGCLASS_MMX,
    ZYDIS_REGCLASS_XMM,
    ZYDIS_REGCLASS_YMM,
    ZYDIS_REGCLASS_ZMM,
    ZYDIS_REGCLASS_FLAGS,
    ZYDIS_REGCLASS_IP,
    ZYDIS_REGCLASS_SEGMENT,
    ZYDIS_REGCLASS_TEST,
    ZYDIS_REGCLASS_CONTROL,
    ZYDIS_REGCLASS_DEBUG,
    ZYDIS_REGCLASS_MASK,
    ZYDIS_REGCLASS_BOUND,

    ZYDIS_REGCLASS_MAX_VALUE = ZYDIS_REGCLASS_BOUND
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisRegisterWidth                                                                             *}
{* ---------------------------------------------------------------------------------------------- *}

  TZydisRegisterWidth = ZydisU16;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisMachineMode                                                                               *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisMachineMode = (
    ZYDIS_MACHINE_MODE_INVALID,
    ZYDIS_MACHINE_MODE_LONG_64,
    ZYDIS_MACHINE_MODE_LONG_COMPAT_32,
    ZYDIS_MACHINE_MODE_LONG_COMPAT_16,
    ZYDIS_MACHINE_MODE_LEGACY_32,
    ZYDIS_MACHINE_MODE_LEGACY_16,
    ZYDIS_MACHINE_MODE_REAL_16,

    ZYDIS_MACHINE_MODE_MAX_VALUE = ZYDIS_MACHINE_MODE_REAL_16
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisAddressWidth                                                                              *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisAddressWidth = (
    ZYDIS_ADDRESS_WIDTH_INVALID =  0,
    ZYDIS_ADDRESS_WIDTH_16      = 16,
    ZYDIS_ADDRESS_WIDTH_32      = 32,
    ZYDIS_ADDRESS_WIDTH_64      = 64,

    ZYDIS_ADDRESS_WIDTH_MAX_VALUE = ZYDIS_ADDRESS_WIDTH_64
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisElementType                                                                               *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisElementType = (
    ZYDIS_ELEMENT_TYPE_INVALID,
    ZYDIS_ELEMENT_TYPE_STRUCT,
    ZYDIS_ELEMENT_TYPE_UINT,
    ZYDIS_ELEMENT_TYPE_INT,
    ZYDIS_ELEMENT_TYPE_FLOAT16,
    ZYDIS_ELEMENT_TYPE_FLOAT32,
    ZYDIS_ELEMENT_TYPE_FLOAT64,
    ZYDIS_ELEMENT_TYPE_FLOAT80,
    ZYDIS_ELEMENT_TYPE_LONGBCD,

    ZYDIS_ELEMENT_TYPE_MAX_VALUE = ZYDIS_ELEMENT_TYPE_LONGBCD
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisElementSize                                                                               *}
{* ---------------------------------------------------------------------------------------------- *}

  TZydisElementSize = ZydisU16;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisOperandType                                                                               *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisOperandType = (
    ZYDIS_OPERAND_TYPE_UNUSED,
    ZYDIS_OPERAND_TYPE_REGISTER,
    ZYDIS_OPERAND_TYPE_MEMORY,
    ZYDIS_OPERAND_TYPE_POINTER,
    ZYDIS_OPERAND_TYPE_IMMEDIATE,

    ZYDIS_OPERAND_TYPE_MAX_VALUE = ZYDIS_OPERAND_TYPE_IMMEDIATE
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisOperandEncoding                                                                           *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisOperandEncoding = (
    ZYDIS_OPERAND_ENCODING_NONE,
    ZYDIS_OPERAND_ENCODING_MODRM_REG,
    ZYDIS_OPERAND_ENCODING_MODRM_RM,
    ZYDIS_OPERAND_ENCODING_OPCODE,
    ZYDIS_OPERAND_ENCODING_NDSNDD,
    ZYDIS_OPERAND_ENCODING_IS4,
    ZYDIS_OPERAND_ENCODING_MASK,
    ZYDIS_OPERAND_ENCODING_DISP8,
    ZYDIS_OPERAND_ENCODING_DISP16,
    ZYDIS_OPERAND_ENCODING_DISP32,
    ZYDIS_OPERAND_ENCODING_DISP64,
    ZYDIS_OPERAND_ENCODING_DISP16_32_64,
    ZYDIS_OPERAND_ENCODING_DISP32_32_64,
    ZYDIS_OPERAND_ENCODING_DISP16_32_32,
    ZYDIS_OPERAND_ENCODING_UIMM8,
    ZYDIS_OPERAND_ENCODING_UIMM16,
    ZYDIS_OPERAND_ENCODING_UIMM32,
    ZYDIS_OPERAND_ENCODING_UIMM64,
    ZYDIS_OPERAND_ENCODING_UIMM16_32_64,
    ZYDIS_OPERAND_ENCODING_UIMM32_32_64,
    ZYDIS_OPERAND_ENCODING_UIMM16_32_32,
    ZYDIS_OPERAND_ENCODING_SIMM8,
    ZYDIS_OPERAND_ENCODING_SIMM16,
    ZYDIS_OPERAND_ENCODING_SIMM32,
    ZYDIS_OPERAND_ENCODING_SIMM64,
    ZYDIS_OPERAND_ENCODING_SIMM16_32_64,
    ZYDIS_OPERAND_ENCODING_SIMM32_32_64,
    ZYDIS_OPERAND_ENCODING_SIMM16_32_32,
    ZYDIS_OPERAND_ENCODING_JIMM8,
    ZYDIS_OPERAND_ENCODING_JIMM16,
    ZYDIS_OPERAND_ENCODING_JIMM32,
    ZYDIS_OPERAND_ENCODING_JIMM64,
    ZYDIS_OPERAND_ENCODING_JIMM16_32_64,
    ZYDIS_OPERAND_ENCODING_JIMM32_32_64,
    ZYDIS_OPERAND_ENCODING_JIMM16_32_32,

    ZYDIS_OPERAND_ENCODING_MAX_VALUE = ZYDIS_OPERAND_ENCODING_JIMM16_32_32
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisOperandVisibility                                                                         *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisOperandVisibility = (
    ZYDIS_OPERAND_VISIBILITY_INVALID,
    ZYDIS_OPERAND_VISIBILITY_EXPLICIT,
    ZYDIS_OPERAND_VISIBILITY_IMPLICIT,
    ZYDIS_OPERAND_VISIBILITY_HIDDEN,

    ZYDIS_OPERAND_VISIBILITY_MAX_VALUE = ZYDIS_OPERAND_VISIBILITY_HIDDEN
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisOperandAction                                                                             *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisOperandAction = (
    ZYDIS_OPERAND_ACTION_INVALID,
    ZYDIS_OPERAND_ACTION_READ,
    ZYDIS_OPERAND_ACTION_WRITE,
    ZYDIS_OPERAND_ACTION_READWRITE,
    ZYDIS_OPERAND_ACTION_CONDREAD,
    ZYDIS_OPERAND_ACTION_CONDWRITE,
    ZYDIS_OPERAND_ACTION_READ_CONDWRITE,
    ZYDIS_OPERAND_ACTION_CONDREAD_WRITE,

    ZYDIS_OPERAND_ACTION_MAX_VALUE = ZYDIS_OPERAND_ACTION_CONDREAD_WRITE
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisInstructionEncoding                                                                       *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisInstructionEncoding = (
    ZYDIS_INSTRUCTION_ENCODING_INVALID,
    ZYDIS_INSTRUCTION_ENCODING_DEFAULT,
    ZYDIS_INSTRUCTION_ENCODING_3DNOW,
    ZYDIS_INSTRUCTION_ENCODING_XOP,
    ZYDIS_INSTRUCTION_ENCODING_VEX,
    ZYDIS_INSTRUCTION_ENCODING_EVEX,
    ZYDIS_INSTRUCTION_ENCODING_MVEX,

    ZYDIS_INSTRUCTION_ENCODING_MAX_VALUE = ZYDIS_INSTRUCTION_ENCODING_MVEX
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisOpcodeMap                                                                                 *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisOpcodeMap = (
    ZYDIS_OPCODE_MAP_DEFAULT,
    ZYDIS_OPCODE_MAP_0F,
    ZYDIS_OPCODE_MAP_0F38,
    ZYDIS_OPCODE_MAP_0F3A,
    ZYDIS_OPCODE_MAP_0F0F,
    ZYDIS_OPCODE_MAP_XOP8,
    ZYDIS_OPCODE_MAP_XOP9,
    ZYDIS_OPCODE_MAP_XOPA,

    ZYDIS_OPCODE_MAP_MAX_VALUE = ZYDIS_OPCODE_MAP_XOP9
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisMemoryOperandType                                                                         *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisMemoryOperandType = (
    ZYDIS_MEMOP_TYPE_INVALID,
    ZYDIS_MEMOP_TYPE_MEM,
    ZYDIS_MEMOP_TYPE_AGEN,
    ZYDIS_MEMOP_TYPE_MIB,

    ZYDIS_MEMOP_TYPE_MAX_VALUE = ZYDIS_MEMOP_TYPE_MIB
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisDecodedOperand                                                                            *}
{* ---------------------------------------------------------------------------------------------- *}

  TZydisDecodedOperandReg = record
  public
    Value: TZydisRegister;
  end;

  TZydisDecodedOperandMemDisp = record
  public
    HasDisplacement: ZydisBool;
    Value: ZydisI64;
  end;

  TZydisDecodedOperandMem = record
  public
    &Type: TZydisMemoryOperandType;
    Segment: TZydisRegister;
    Base: TZydisRegister;
    Index: TZydisRegister;
    Scale: ZydisU8;
    Disp: TZydisDecodedOperandMemDisp;
  end;

  TZydisDecodedOperandPtr = record
  public
    Segment: ZydisU16;
    Offset: ZydisU32;
  end;

  TZydisDecodedOperandImmValue = record
  case Integer of
    0: ( U: ZydisU64 );
    1: ( S: ZydisI64 );
  end;

  TZydisDecodedOperandImm = record
  public
    IsSigned: ZydisBool;
    IsRelative: ZydisBool;
    Value: TZydisDecodedOperandImmValue;
  end;

  PZydisDecodedOperand = ^TZydisDecodedOperand;
  TZydisDecodedOperand = record
  public
    Id: ZydisU8;
    &Type: TZydisOperandType;
    Visibility: TZydisOperandVisibility;
    Action: TZydisOperandAction;
    Encoding: TZydisOperandEncoding;
    Size: ZydisU16;
    ElementType: TZydisElementType;
    ElementSize: TZydisElementSize;
    ElementCount: ZydisU16;
    Reg: TZydisDecodedOperandReg;
    Mem: TZydisDecodedOperandMem;
    Ptr: TZydisDecodedOperandPtr;
    Imm: TZydisDecodedOperandImm;
  end;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisInstructionAttribute                                                                      *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisInstructionAttribute = (
    ZYDIS_ATTRIB_HAS_MODRM                =  0,
    ZYDIS_ATTRIB_HAS_SIB                  =  1,
    ZYDIS_ATTRIB_HAS_REX                  =  2,
    ZYDIS_ATTRIB_HAS_XOP                  =  3,
    ZYDIS_ATTRIB_HAS_VEX                  =  4,
    ZYDIS_ATTRIB_HAS_EVEX                 =  5,
    ZYDIS_ATTRIB_HAS_MVEX                 =  6,
    ZYDIS_ATTRIB_IS_RELATIVE              =  7,
    ZYDIS_ATTRIB_IS_PRIVILEGED            =  8,
    ZYDIS_ATTRIB_ACCEPTS_LOCK             =  9,
    ZYDIS_ATTRIB_ACCEPTS_REP              = 10,
    ZYDIS_ATTRIB_ACCEPTS_REPE             = 11,
    ZYDIS_ATTRIB_ACCEPTS_REPZ             = 11,
    ZYDIS_ATTRIB_ACCEPTS_REPNE            = 12,
    ZYDIS_ATTRIB_ACCEPTS_REPNZ            = 12,
    ZYDIS_ATTRIB_ACCEPTS_BOUND            = 13,
    ZYDIS_ATTRIB_ACCEPTS_XACQUIRE         = 14,
    ZYDIS_ATTRIB_ACCEPTS_XRELEASE         = 15,
    ZYDIS_ATTRIB_ACCEPTS_HLE_WITHOUT_LOCK = 16,
    ZYDIS_ATTRIB_ACCEPTS_BRANCH_HINTS     = 17,
    ZYDIS_ATTRIB_ACCEPTS_SEGMENT          = 18,
    ZYDIS_ATTRIB_HAS_LOCK                 = 19,
    ZYDIS_ATTRIB_HAS_REP                  = 20,
    ZYDIS_ATTRIB_HAS_REPE                 = 21,
    ZYDIS_ATTRIB_HAS_REPZ                 = 21,
    ZYDIS_ATTRIB_HAS_REPNE                = 22,
    ZYDIS_ATTRIB_HAS_REPNZ                = 22,
    ZYDIS_ATTRIB_HAS_BOUND                = 23,
    ZYDIS_ATTRIB_HAS_XACQUIRE             = 24,
    ZYDIS_ATTRIB_HAS_XRELEASE             = 25,
    ZYDIS_ATTRIB_HAS_BRANCH_NOT_TAKEN     = 26,
    ZYDIS_ATTRIB_HAS_BRANCH_TAKEN         = 27,
    ZYDIS_ATTRIB_HAS_SEGMENT_CS           = 28,
    ZYDIS_ATTRIB_HAS_SEGMENT_SS           = 29,
    ZYDIS_ATTRIB_HAS_SEGMENT_DS           = 30,
    ZYDIS_ATTRIB_HAS_SEGMENT_ES           = 31,
    ZYDIS_ATTRIB_HAS_SEGMENT_FS           = 32,
    ZYDIS_ATTRIB_HAS_SEGMENT_GS           = 33,
    ZYDIS_ATTRIB_HAS_OPERANDSIZE          = 34,
    ZYDIS_ATTRIB_HAS_ADDRESSSIZE          = 35
  );
  TZydisInstructionAttributes = set of TZydisInstructionAttribute;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisCPUFlag                                                                                   *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisCPUFlag = (
    ZYDIS_CPUFLAG_CF,
    ZYDIS_CPUFLAG_PF,
    ZYDIS_CPUFLAG_AF,
    ZYDIS_CPUFLAG_ZF,
    ZYDIS_CPUFLAG_SF,
    ZYDIS_CPUFLAG_TF,
    ZYDIS_CPUFLAG_IF,
    ZYDIS_CPUFLAG_DF,
    ZYDIS_CPUFLAG_OF,
    ZYDIS_CPUFLAG_IOPL,
    ZYDIS_CPUFLAG_NT,
    ZYDIS_CPUFLAG_RF,
    ZYDIS_CPUFLAG_VM,
    ZYDIS_CPUFLAG_AC,
    ZYDIS_CPUFLAG_VIF,
    ZYDIS_CPUFLAG_VIP,
    ZYDIS_CPUFLAG_ID,
    ZYDIS_CPUFLAG_C0,
    ZYDIS_CPUFLAG_C1,
    ZYDIS_CPUFLAG_C2,
    ZYDIS_CPUFLAG_C3,

    ZYDIS_CPUFLAG_MAX_VALUE = ZYDIS_CPUFLAG_C3
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisCPUFlagMask                                                                               *}
{* ---------------------------------------------------------------------------------------------- *}

  TZydisCPUFlagMask = set of TZydisCPUFlag;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisCPUFlagAction                                                                             *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisCPUFlagAction = (
    ZYDIS_CPUFLAG_ACTION_NONE,
    ZYDIS_CPUFLAG_ACTION_TESTED,
    ZYDIS_CPUFLAG_ACTION_MODIFIED,
    ZYDIS_CPUFLAG_ACTION_SET_0,
    ZYDIS_CPUFLAG_ACTION_SET_1,
    ZYDIS_CPUFLAG_ACTION_UNDEFINED,

    ZYDIS_CPUFLAG_ACTION_MAX_VALUE = ZYDIS_CPUFLAG_ACTION_UNDEFINED
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisExceptionClass                                                                            *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisExceptionClass = (
    ZYDIS_EXCEPTION_CLASS_NONE,
    ZYDIS_EXCEPTION_CLASS_SSE1,
    ZYDIS_EXCEPTION_CLASS_SSE2,
    ZYDIS_EXCEPTION_CLASS_SSE3,
    ZYDIS_EXCEPTION_CLASS_SSE4,
    ZYDIS_EXCEPTION_CLASS_SSE5,
    ZYDIS_EXCEPTION_CLASS_SSE7,
    ZYDIS_EXCEPTION_CLASS_AVX1,
    ZYDIS_EXCEPTION_CLASS_AVX2,
    ZYDIS_EXCEPTION_CLASS_AVX3,
    ZYDIS_EXCEPTION_CLASS_AVX4,
    ZYDIS_EXCEPTION_CLASS_AVX5,
    ZYDIS_EXCEPTION_CLASS_AVX6,
    ZYDIS_EXCEPTION_CLASS_AVX7,
    ZYDIS_EXCEPTION_CLASS_AVX8,
    ZYDIS_EXCEPTION_CLASS_AVX11,
    ZYDIS_EXCEPTION_CLASS_AVX12,
    ZYDIS_EXCEPTION_CLASS_E1,
    ZYDIS_EXCEPTION_CLASS_E1NF,
    ZYDIS_EXCEPTION_CLASS_E2,
    ZYDIS_EXCEPTION_CLASS_E2NF,
    ZYDIS_EXCEPTION_CLASS_E3,
    ZYDIS_EXCEPTION_CLASS_E3NF,
    ZYDIS_EXCEPTION_CLASS_E4,
    ZYDIS_EXCEPTION_CLASS_E4NF,
    ZYDIS_EXCEPTION_CLASS_E5,
    ZYDIS_EXCEPTION_CLASS_E5NF,
    ZYDIS_EXCEPTION_CLASS_E6,
    ZYDIS_EXCEPTION_CLASS_E6NF,
    ZYDIS_EXCEPTION_CLASS_E7NM,
    ZYDIS_EXCEPTION_CLASS_E7NM128,
    ZYDIS_EXCEPTION_CLASS_E9NF,
    ZYDIS_EXCEPTION_CLASS_E10,
    ZYDIS_EXCEPTION_CLASS_E10NF,
    ZYDIS_EXCEPTION_CLASS_E11,
    ZYDIS_EXCEPTION_CLASS_E11NF,
    ZYDIS_EXCEPTION_CLASS_E12,
    ZYDIS_EXCEPTION_CLASS_E12NP,
    ZYDIS_EXCEPTION_CLASS_K20,
    ZYDIS_EXCEPTION_CLASS_K21,

    ZYDIS_EXCEPTION_CLASS_MAX_VALUE = ZYDIS_EXCEPTION_CLASS_K21
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisVectorLength                                                                              *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z2}
  TZydisVectorLength = (
    ZYDIS_VECTOR_LENGTH_INVALID =   0,
    ZYDIS_VECTOR_LENGTH_128     = 128,
    ZYDIS_VECTOR_LENGTH_256     = 256,
    ZYDIS_VECTOR_LENGTH_512     = 512,

    ZYDIS_VECTOR_LENGTH_MAX_VALUE = ZYDIS_VECTOR_LENGTH_512
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisMaskMode                                                                                  *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisMaskMode = (
    ZYDIS_MASK_MODE_INVALID,
    ZYDIS_MASK_MODE_MERGE,
    ZYDIS_MASK_MODE_ZERO,

    ZYDIS_MASK_MODE_MAX_VALUE = ZYDIS_MASK_MODE_ZERO
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisBroadcastMode                                                                             *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisBroadcastMode = (
    ZYDIS_BROADCAST_MODE_INVALID,
    ZYDIS_BROADCAST_MODE_1_TO_2,
    ZYDIS_BROADCAST_MODE_1_TO_4,
    ZYDIS_BROADCAST_MODE_1_TO_8,
    ZYDIS_BROADCAST_MODE_1_TO_16,
    ZYDIS_BROADCAST_MODE_1_TO_32,
    ZYDIS_BROADCAST_MODE_1_TO_64,
    ZYDIS_BROADCAST_MODE_2_TO_4,
    ZYDIS_BROADCAST_MODE_2_TO_8,
    ZYDIS_BROADCAST_MODE_2_TO_16,
    ZYDIS_BROADCAST_MODE_4_TO_8,
    ZYDIS_BROADCAST_MODE_4_TO_16,
    ZYDIS_BROADCAST_MODE_8_TO_16,

    ZYDIS_BROADCAST_MODE_MAX_VALUE = ZYDIS_BROADCAST_MODE_8_TO_16
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisRoundingMode                                                                              *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisRoundingMode = (
    ZYDIS_ROUNDING_MODE_INVALID,
    ZYDIS_ROUNDING_MODE_RN,
    ZYDIS_ROUNDING_MODE_RD,
    ZYDIS_ROUNDING_MODE_RU,
    ZYDIS_ROUNDING_MODE_RZ,

    ZYDIS_ROUNDING_MODE_MAX_VALUE = ZYDIS_ROUNDING_MODE_RZ
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisSwizzleMode                                                                               *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisSwizzleMode = (
    ZYDIS_SWIZZLE_MODE_INVALID,
    ZYDIS_SWIZZLE_MODE_DCBA,
    ZYDIS_SWIZZLE_MODE_CDAB,
    ZYDIS_SWIZZLE_MODE_BADC,
    ZYDIS_SWIZZLE_MODE_DACB,
    ZYDIS_SWIZZLE_MODE_AAAA,
    ZYDIS_SWIZZLE_MODE_BBBB,
    ZYDIS_SWIZZLE_MODE_CCCC,
    ZYDIS_SWIZZLE_MODE_DDDD,

    ZYDIS_SWIZZLE_MODE_MAX_VALUE = ZYDIS_SWIZZLE_MODE_DDDD
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisConversionMode                                                                            *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisConversionMode = (
    ZYDIS_CONVERSION_MODE_INVALID,
    ZYDIS_CONVERSION_MODE_FLOAT16,
    ZYDIS_CONVERSION_MODE_SINT8,
    ZYDIS_CONVERSION_MODE_UINT8,
    ZYDIS_CONVERSION_MODE_SINT16,
    ZYDIS_CONVERSION_MODE_UINT16,

    ZYDIS_CONVERSION_MODE_MAX_VALUE = ZYDIS_CONVERSION_MODE_UINT16
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisDecodedInstruction                                                                        *}
{* ---------------------------------------------------------------------------------------------- *}

  TZydisDecodedInstructionAccessedFlags = record
  public
    Action: TZydisCPUFlagAction;
  end;

  TZydisDecodedInstructionAVXMask = record
  public
    Mode: TZydisMaskMode;
    Reg: TZydisRegister;
    IsControlMask: ZydisBool;
  end;

  TZydisDecodedInstructionAVXBroadcast = record
  public
    IsStatic: Boolean;
    Mode: TZydisBroadcastMode;
  end;

  TZydisDecodedInstructionAVXRounding = record
  public
    Mode: TZydisRoundingMode;
  end;

  TZydisDecodedInstructionAVXSwizzle = record
  public
    Mode: TZydisSwizzleMode;
  end;

  TZydisDecodedInstructionAVXConversion = record
  public
    Mode: TZydisConversionMode;
  end;

  TZydisDecodedInstructionAVX = record
  public
    VectorLength: TZydisVectorLength;
    Mask: TZydisDecodedInstructionAVXMask;
    Broadcast: TZydisDecodedInstructionAVXBroadcast;
    Rounding: TZydisDecodedInstructionAVXRounding;
    Swizzle: TZydisDecodedInstructionAVXSwizzle;
    Conversion: TZydisDecodedInstructionAVXConversion;
    HasSAE: ZydisBool;
    HasEvictionHint: ZydisBool;
  end;

  TZydisDecodedInstructionMeta = record
  public
    Category: TZydisInstructionCategory;
    ISASet: TZydisISASet;
    ISAExt: TZydisISAExt;
    ExceptionClass: TZydisExceptionClass;
  end;

  TZydisDecodedInstructionRawPrefixes = record
  public
    Data: array[0..ZYDIS_MAX_INSTRUCTION_LENGTH - 2] of ZydisU8;
    Count: ZydisU8;
    HasF0: ZydisU8;
    HasF3: ZydisU8;
    HasF2: ZydisU8;
    Has2E: ZydisU8;
    Has36: ZydisU8;
    Has3E: ZydisU8;
    Has26: ZydisU8;
    Has64: ZydisU8;
    Has65: ZydisU8;
    Has66: ZydisU8;
    Has67: ZydisU8;
  end;

  TZydisDecodedInstructionRawREX = record
  public
    IsDecoded: ZydisBool;
    Data: array[0..0] of ZydisU8;
    W: ZydisU8;
    R: ZydisU8;
    X: ZydisU8;
    B: ZydisU8;
  end;

  TZydisDecodedInstructionRawXOP = record
  public
    IsDecoded: ZydisBool;
    Data: array[0..2] of ZydisU8;
    R: ZydisU8;
    X: ZydisU8;
    B: ZydisU8;
    m_mmmm: ZydisU8;
    W: ZydisU8;
    vvvv: ZydisU8;
    L: ZydisU8;
    pp: ZydisU8;
  end;

  TZydisDecodedInstructionRawVEX = record
  public
    IsDecoded: ZydisBool;
    Data: array[0..2] of ZydisU8;
    R: ZydisU8;
    X: ZydisU8;
    B: ZydisU8;
    m_mmmm: ZydisU8;
    W: ZydisU8;
    vvvv: ZydisU8;
    L: ZydisU8;
    pp: ZydisU8;
  end;

  TZydisDecodedInstructionRawEVEX = record
  public
    IsDecoded: ZydisBool;
    Data: array[0..3] of ZydisU8;
    R: ZydisU8;
    X: ZydisU8;
    B: ZydisU8;
    R2: ZydisU8;
    mm: ZydisU8;
    W: ZydisU8;
    vvvv: ZydisU8;
    pp: ZydisU8;
    z: ZydisU8;
    L2: ZydisU8;
    L: ZydisU8;
    b_: ZydisU8;
    V2: ZydisU8;
    aaa: ZydisU8;
  end;

  TZydisDecodedInstructionRawMVEX = record
  public
    IsDecoded: ZydisBool;
    Data: array[0..3] of ZydisU8;
    R: ZydisU8;
    X: ZydisU8;
    B: ZydisU8;
    R2: ZydisU8;
    mmmm: ZydisU8;
    W: ZydisU8;
    vvvv: ZydisU8;
    pp: ZydisU8;
    E: ZydisU8;
    SSS: ZydisU8;
    V2: ZydisU8;
    kkk: ZydisU8;
  end;

  TZydisDecodedInstructionRawModRM = record
  public
    IsDecoded: ZydisBool;
    Data: array[0..0] of ZydisU8;
    &Mod: ZydisU8;
    Reg: ZydisU8;
    Rm: ZydisU8;
  end;

  TZydisDecodedInstructionRawSIB = record
  public
    IsDecoded: ZydisBool;
    Data: array[0..0] of ZydisU8;
    Scale: ZydisU8;
    Index: ZydisU8;
    Base: ZydisU8;
  end;

  TZydisDecodedInstructionRawDisp = record
  public
    Value: ZydisU64;
    Size: ZydisU8;
    Offset: ZydisU8;
  end;

  TZydisDecodedInstructionRawImmValue = record
  case Integer of
    0: ( U: ZydisU64 );
    1: ( S: ZydisI64 );
  end;

  TZydisDecodedInstructionRawImm = record
  public
    IsSigned: ZydisBool;
    IsRelative: ZydisBool;
    Value: TZydisDecodedInstructionRawImmValue;
    Size: ZydisU8;
    Offset: ZydisU8;
  end;

  TZydisDecodedInstructionRaw = record
  public
    Prefixes: TZydisDecodedInstructionRawPrefixes;
    REX: TZydisDecodedInstructionRawREX;
    XOP: TZydisDecodedInstructionRawXOP;
    VEX: TZydisDecodedInstructionRawVEX;
    EVEX: TZydisDecodedInstructionRawEVEX;
    MVEX: TZydisDecodedInstructionRawMVEX;
    ModRM: TZydisDecodedInstructionRawModRM;
    SIB: TZydisDecodedInstructionRawSIB;
    Disp: TZydisDecodedInstructionRawDisp;
    Imm: array[0..1] of TZydisDecodedInstructionRawImm;
  end;

  PZydisDecodedInstruction = ^TZydisDecodedInstruction;
  TZydisDecodedInstruction = record
  public
    MachineMode: TZydisMachineMode;
    Mnemonic: TZydisMnemonic;
    Length: ZydisU8;
    Data: array[0..ZYDIS_MAX_INSTRUCTION_LENGTH - 1] of ZydisU8;
    Encoding: TZydisInstructionEncoding;
    OpcodeMap: TZydisOpcodeMap;
    Opcode: ZydisU8;
    OperandSize: ZydisU8;
    StackWidth: ZydisU8;
    AddressWidth: ZydisU8;
    OperandCount: ZydisU8;
    Operands: array[0..ZYDIS_MAX_OPERAND_COUNT - 1] of TZydisDecodedOperand;
    Attributes: TZydisInstructionAttributes;
    InstructionAddress: ZydisU64;
    AccessedFlags: array[TZydisCPUFlag] of TZydisCPUFlagAction;
    AVX: TZydisDecodedInstructionAVX;
    Meta: TZydisDecodedInstructionMeta;
    Raw: TZydisDecodedInstructionRaw;
  end;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisDecoderMode                                                                               *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisDecoderMode = (
    ZYDIS_DECODER_MODE_MINIMAL,
    ZYDIS_DECODER_MODE_AMD_BRANCHES,
    ZYDIS_DECODER_MODE_KNC,
    ZYDIS_DECODER_MODE_MPX,
    ZYDIS_DECODER_MODE_CET,
    ZYDIS_DECODER_MODE_LZCNT,
    ZYDIS_DECODER_MODE_TZCNT,
    ZYDIS_DECODER_MODE_WBNOINVD,

    ZYDIS_DECODER_MODE_MAX_VALUE = ZYDIS_DECODER_MODE_WBNOINVD
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisDecoder                                                                                   *}
{* ---------------------------------------------------------------------------------------------- *}

  PZydisDecoder = ^TZydisDecoder;
  TZydisDecoder = record
  public
    MachineMode: TZydisMachineMode;
    AddressWidth: TZydisAddressWidth;
    DecoderMode: array[TZydisDecoderMode] of ZydisBool;
  end;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisFormatterStyle                                                                            *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisFormatterStyle = (
    ZYDIS_FORMATTER_STYLE_INTEL
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisFormatterProperty                                                                         *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisFormatterProperty = (
    ZYDIS_FORMATTER_PROP_UPPERCASE,
    ZYDIS_FORMATTER_PROP_FORCE_MEMSEG,
    ZYDIS_FORMATTER_PROP_FORCE_MEMSIZE,
    ZYDIS_FORMATTER_PROP_ADDR_FORMAT,
    ZYDIS_FORMATTER_PROP_DISP_FORMAT,
    ZYDIS_FORMATTER_PROP_IMM_FORMAT,
    ZYDIS_FORMATTER_PROP_HEX_UPPERCASE,
    ZYDIS_FORMATTER_PROP_HEX_PREFIX,
    ZYDIS_FORMATTER_PROP_HEX_SUFFIX,
    ZYDIS_FORMATTER_PROP_HEX_PADDING_ADDR,
    ZYDIS_FORMATTER_PROP_HEX_PADDING_DISP,
    ZYDIS_FORMATTER_PROP_HEX_PADDING_IMM,

    ZYDIS_FORMATTER_PROP_MAX_VALUE = ZYDIS_FORMATTER_PROP_HEX_PADDING_IMM
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisAddressFormat                                                                             *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisAddressFormat = (
    ZYDIS_ADDR_FORMAT_ABSOLUTE,
    ZYDIS_ADDR_FORMAT_RELATIVE_SIGNED,
    ZYDIS_ADDR_FORMAT_RELATIVE_UNSIGNED,

    ZYDIS_ADDR_FORMAT_MAX_VALUE = ZYDIS_ADDR_FORMAT_RELATIVE_UNSIGNED
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisDisplacementFormat                                                                        *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisDisplacementFormat = (
    ZYDIS_DISP_FORMAT_AUTO,
    ZYDIS_DISP_FORMAT_HEX_SIGNED,
    ZYDIS_DISP_FORMAT_HEX_UNSIGNED,

    ZYDIS_DISP_FORMAT_MAX_VALUE = ZYDIS_DISP_FORMAT_HEX_UNSIGNED
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisImmediateFormat                                                                           *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisImmediateFormat = (
    ZYDIS_IMM_FORMAT_AUTO,
    ZYDIS_IMM_FORMAT_HEX_SIGNED,
    ZYDIS_IMM_FORMAT_HEX_UNSIGNED,

    ZYDIS_IMM_FORMAT_MAX_VALUE = ZYDIS_IMM_FORMAT_HEX_UNSIGNED
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisFormatterHookType                                                                         *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisFormatterHookType = (
    ZYDIS_FORMATTER_HOOK_PRE_INSTRUCTION,
    ZYDIS_FORMATTER_HOOK_POST_INSTRUCTION,
    ZYDIS_FORMATTER_HOOK_PRE_OPERAND,
    ZYDIS_FORMATTER_HOOK_POST_OPERAND,
    ZYDIS_FORMATTER_HOOK_FORMAT_INSTRUCTION,
    ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_REG,
    ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_MEM,
    ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_PTR,
    ZYDIS_FORMATTER_HOOK_FORMAT_OPERAND_IMM,
    ZYDIS_FORMATTER_HOOK_PRINT_MNEMONIC,
    ZYDIS_FORMATTER_HOOK_PRINT_REGISTER,
    ZYDIS_FORMATTER_HOOK_PRINT_ADDRESS,
    ZYDIS_FORMATTER_HOOK_PRINT_DISP,
    ZYDIS_FORMATTER_HOOK_PRINT_IMM,
    ZYDIS_FORMATTER_HOOK_PRINT_MEMSIZE,
    ZYDIS_FORMATTER_HOOK_PRINT_PREFIXES,
    ZYDIS_FORMATTER_HOOK_PRINT_DECORATOR,

    ZYDIS_FORMATTER_HOOK_MAX_VALUE = ZYDIS_FORMATTER_HOOK_PRINT_DECORATOR
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisDecoratorType                                                                             *}
{* ---------------------------------------------------------------------------------------------- *}

  {$Z1}
  TZydisDecoratorType = (
    ZYDIS_DECORATOR_TYPE_INVALID,
    ZYDIS_DECORATOR_TYPE_MASK,
    ZYDIS_DECORATOR_TYPE_BC,
    ZYDIS_DECORATOR_TYPE_RC,
    ZYDIS_DECORATOR_TYPE_SAE,
    ZYDIS_DECORATOR_TYPE_SWIZZLE,
    ZYDIS_DECORATOR_TYPE_CONVERSION,
    ZYDIS_DECORATOR_TYPE_EH,

    ZYDIS_DECORATOR_TYPE_MAX_VALUE = ZYDIS_DECORATOR_TYPE_EH
  );

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisFormatter                                                                                 *}
{* ---------------------------------------------------------------------------------------------- *}

  PZydisFormatter = ^TZydisFormatter;

  TZydisFormatterFunc =
    function(const Formatter: PZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction; UserData: Pointer): TZydisStatus; cdecl;

  TZydisFormatterOperandFunc =
    function(const Formatter: PZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction; const Operand: TZydisDecodedOperand;
      UserData: Pointer): TZydisStatus; cdecl;

  TZydisFormatterRegisterFunc =
    function(const Formatter: PZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction; const Operand: TZydisDecodedOperand;
      Reg: TZydisRegister; UserData: Pointer): TZydisStatus; cdecl;

  TZydisFormatterAddressFunc =
    function(const Formatter: PZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction; const Operand: TZydisDecodedOperand;
      Address: ZydisU64; UserData: Pointer): TZydisStatus; cdecl;

  TZydisFormatterDecoratorFunc =
    function(const Formatter: PZydisFormatter; var Str: TZydisString;
      const Instruction: TZydisDecodedInstruction; const Operand: TZydisDecodedOperand;
      Decorator: TZydisDecoratorType; UserData: Pointer): TZydisStatus; cdecl;

  TZydisFormatter = record
  public
    LetterCase: TZydisLetterCase;
    ForceMemorySegment: ZydisBool;
    ForceMemorySize: ZydisBool;
    FormatAddress: TZydisAddressFormat;
    FormatDisp: TZydisDisplacementFormat;
    FormatImm: TZydisImmediateFormat;
    HexUppercase: ZydisBool;
    HexPrefix: PZydisString;
    HexPrefixData: TZydisString;
    HexSuffix: PZydisString;
    HexSuffixData: TZydisString;
    HexPaddingAddress: ZydisU8;
    HexPaddingDisp: ZydisU8;
    HexPaddingImm: ZydisU8;
    FuncPreInstruction: TZydisFormatterFunc;
    FuncPostInstruction: TZydisFormatterFunc;
    FuncPreOperand: TZydisFormatterOperandFunc;
    FuncPostOperand: TZydisFormatterOperandFunc;
    FuncFormatInstruction: TZydisFormatterFunc;
    FuncPostOperandReg: TZydisFormatterOperandFunc;
    FuncPostOperandMem: TZydisFormatterOperandFunc;
    FuncPostOperandPtr: TZydisFormatterOperandFunc;
    FuncPostOperandImm: TZydisFormatterOperandFunc;
    FuncPrintMnemonic: TZydisFormatterFunc;
    FuncPrintRegister: TZydisFormatterRegisterFunc;
    FuncPrintAddress: TZydisFormatterAddressFunc;
    FuncPrintDisp: TZydisFormatterOperandFunc;
    FuncPrintImm: TZydisFormatterOperandFunc;
    FuncPrintMemSize: TZydisFormatterOperandFunc;
    FuncPrintPrefixes: TZydisFormatterFunc;
    FuncPrintDecorator: TZydisFormatterDecoratorFunc;
  end;

{* ---------------------------------------------------------------------------------------------- *}

{* ============================================================================================== *}
{* Imports                                                                                        *}
{* ============================================================================================== *}

{$IFDEF ZYDIS_DYNAMIC_LINK}
const
  {$IFDEF CPUX86}
  ZYDIS_LIBRARY_NAME = 'Zydis32.dll';
  {$ENDIF}
  {$IFDEF CPUX64}
  ZYDIS_LIBRARY_NAME = 'libZydis.dylib';
  {$ENDIF}
  ZYDIS_SYMBOL_PREFIX = '';
{$ELSE}
const
ZYDIS_SYMBOL_PREFIX = '';
  {$IFDEF Darwin}
    {$IFDEF CPUX64}
      {$LinkLib './Build/libraries/osx/libZydis.a'}
    {$ENDIF}
  {$ENDIF}
  {$IFDEF linux}
    {$IFDEF CPUX64}
      {$LinkLib './Build/libraries/linux/libZydis.a'}
    {$ENDIF}
  {$ENDIF}
  {$IFDEF Windows}
    {$IFDEF CPUX86}
      {$LinkLib './Build/libraries/win32/libZydis32.a'}
    {$ENDIF}
    {$IFDEF CPUX64}
      {$LinkLib './Build/libraries/win64/libZydis64.a'}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{* ---------------------------------------------------------------------------------------------- *}
{* Zydis                                                                                          *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisGetVersion: ZydisU64; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisGetVersion';

{* ---------------------------------------------------------------------------------------------- *}
{* String                                                                                         *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisStringInit(var Str: TZydisString; const Value: PAnsiChar): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisStringInit';

function ZydisStringFinalize(var Str: TZydisString): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisStringFinalize';

function ZydisStringAppend(var Str: TZydisString; const Text: PZydisString): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisStringAppend';

function ZydisStringAppendEx(var Str: TZydisString; const Text: PZydisString;
  LetterCase: TZydisLetterCase): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisStringAppendEx';

function ZydisStringAppendC(var Str: TZydisString; const Text: PAnsiChar): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisStringAppendC';

function ZydisStringAppendExC(var Str: TZydisString; const Text: PAnsiChar;
  LetterCase: TZydisLetterCase): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisStringAppendExC';

function ZydisStringAppendDecU(var Str: TZydisString; Value: ZydisU64;
  PaddingLength: ZydisU8): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisStringAppendDecU';

function ZydisStringAppendDecS(var Str: TZydisString; Value: ZydisI64;
  PaddingLength: ZydisU8): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisStringAppendDecS';

function ZydisStringAppendHexU(var Str: TZydisString; Value: ZydisU64; PaddingLength: ZydisU8;
  UpperCase: ZydisBool; const Prefix, Suffix: PZydisString): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisStringAppendHexU';

function ZydisStringAppendHexS(var Str: TZydisString; Value: ZydisI64; PaddingLength: ZydisU8;
  UpperCase: ZydisBool; const Prefix, Suffix: PZydisString): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisStringAppendHexS';

{* ---------------------------------------------------------------------------------------------- *}
{* Register                                                                                       *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisRegisterEncode(RegisterClass: TZydisRegisterClass;
  Id: ZydisU8): TZydisRegister; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisRegisterEncode';

function ZydisRegisterGetId(Reg: TZydisRegister): ZydisI16; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisRegisterGetId';

function ZydisRegisterGetClass(Reg: TZydisRegister): TZydisRegisterClass; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisRegisterGetClass';

function ZydisRegisterGetWidth(Reg: TZydisRegister): TZydisRegisterWidth; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisRegisterGetWidth';

function ZydisRegisterGetWidth64(Reg: TZydisRegister): TZydisRegisterWidth; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisRegisterGetWidth64';

function ZydisRegisterGetString(Reg: TZydisRegister): PAnsiChar; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisRegisterGetString';

function ZydisRegisterGetStaticString(Reg: TZydisRegister): PZydisStaticString; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisRegisterGetStaticString';

{* ---------------------------------------------------------------------------------------------- *}
{* Mnemonic                                                                                       *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisMnemonicGetString(Mnemonic: TZydisMnemonic): PAnsiChar; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisMnemonicGetString';

function ZydisMnemonicGetStaticString(Mnemonic: TZydisMnemonic): PZydisStaticString; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisMnemonicGetStaticString';

{* ---------------------------------------------------------------------------------------------- *}
{* MetaInfo                                                                                       *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisCategoryGetString(Category: TZydisInstructionCategory): PAnsiChar; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisCategoryGetString';

function ZydisISASetGetString(ISASet: TZydisISASet): PAnsiChar; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisISASetGetString';

function ZydisISAExtGetString(ISAExt: TZydisISAExt): PAnsiChar; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisISAExtGetString';

{* ---------------------------------------------------------------------------------------------- *}
{* Decoder                                                                                        *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisDecoderInit(var Decoder: TZydisDecoder; MachineMode: TZydisMachineMode;
  AddressWidth: TZydisAddressWidth): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisDecoderInit';

function ZydisDecoderEnableMode(var Decoder: TZydisDecoder; DecoderMode: TZydisDecoderMode;
  Enabled: ZydisBool): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisDecoderEnableMode';

function ZydisDecoderDecodeBuffer(const Decoder: PZydisDecoder; Buffer: Pointer;
  BufferLen: ZydisUSize; InstructionPointer: ZydisU64;
  var Instruction: TZydisDecodedInstruction): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisDecoderDecodeBuffer';

{* ---------------------------------------------------------------------------------------------- *}
{* Formatter                                                                                      *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisFormatterInit(var Formatter: TZydisFormatter;
  Style: TZydisFormatterStyle): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisFormatterInit';

function ZydisFormatterSetProperty(var Formatter: TZydisFormatter;
  &Property: TZydisFormatterProperty; Value: ZydisUPointer): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisFormatterSetProperty';

function ZydisFormatterSetHook(var Formatter: TZydisFormatter;
  Hook: TZydisFormatterHookType; var Callback: Pointer): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisFormatterSetHook';

function ZydisFormatterFormatInstruction(const Formatter: PZydisFormatter;
  const Instruction: PZydisDecodedInstruction; Buffer: Pointer;
  BufferLen: ZydisUSize): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisFormatterFormatInstruction';

function ZydisFormatterFormatInstructionEx(const Formatter: PZydisFormatter;
  const Instruction: PZydisDecodedInstruction; Buffer: Pointer;
  BufferLen: ZydisUSize; UserData: Pointer): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisFormatterFormatInstructionEx';

function ZydisFormatterFormatOperand(const Formatter: PZydisFormatter;
  const Instruction: PZydisDecodedInstruction; Index: ZydisU8; Buffer: Pointer;
  BufferLen: ZydisUSize): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisFormatterFormatOperand';

function ZydisFormatterFormatOperandEx(const Formatter: PZydisFormatter;
  const Instruction: PZydisDecodedInstruction; Index: ZydisU8; Buffer: Pointer;
  BufferLen: ZydisUSize; UserData: Pointer): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisFormatterFormatOperandEx';

{* ---------------------------------------------------------------------------------------------- *}
{* Utils                                                                                          *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisCalcAbsoluteAddress(const Instruction: PZydisDecodedInstruction;
  const Operand: PZydisDecodedOperand; var Address: ZydisU64): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisCalcAbsoluteAddress';

function ZydisGetAccessedFlagsByAction(const Instruction: PZydisDecodedInstruction;
  Action: TZydisCPUFlagAction; var Flags: TZydisCPUFlagMask): TZydisStatus; cdecl;
  external {$IFDEF ZYDIS_DYNAMIC_LINK}ZYDIS_LIBRARY_NAME{$ENDIF}
  name ZYDIS_SYMBOL_PREFIX + 'ZydisGetAccessedFlagsByAction';

{* ---------------------------------------------------------------------------------------------- *}

{* ============================================================================================== *}
{* Macros                                                                                         *}
{* ============================================================================================== *}

{* ---------------------------------------------------------------------------------------------- *}
{* Zydis                                                                                          *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisVersionMajor(Version: ZydisU64): ZydisU16; inline;
function ZydisVersionMinor(Version: ZydisU64): ZydisU16; inline;
function ZydisVersionPatch(Version: ZydisU64): ZydisU16; inline;
function ZydisVersionBuild(Version: ZydisU64): ZydisU16; inline;

{* ---------------------------------------------------------------------------------------------- *}
{* Status                                                                                         *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisSuccess(Status: TZydisStatus): Boolean; inline;

{* ---------------------------------------------------------------------------------------------- *}

{* ============================================================================================== *}
{* Helper                                                                                         *}
{* ============================================================================================== *}

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisString                                                                                    *}
{* ---------------------------------------------------------------------------------------------- *}

type
  TZydisStringHelper = record helper for TZydisString
  public
    function Init(Buffer: PAnsiChar; Capacity: ZydisUSize): TZydisStatus; overload; inline;
    function Init(const Text: PAnsiChar): TZydisStatus; overload; inline;
    function Append(const Value: TZydisString): TZydisStatus; overload; inline;
    function Append(const Value: PAnsiChar): TZydisStatus; overload; inline;
  end;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisMnemonic                                                                                  *}
{* ---------------------------------------------------------------------------------------------- *}

type
  TZydisMnemonicHelper = record helper for TZydisMnemonic
  public
    function ToString: String; inline;
  end;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisRegister                                                                                  *}
{* ---------------------------------------------------------------------------------------------- *}

type
  TZydisRegisterHelper = record helper for TZydisRegister
  public
    function ToString: String; inline;
  end;

{* ---------------------------------------------------------------------------------------------- *}

{* ============================================================================================== *}

implementation

{* ============================================================================================== *}
{* Internal symbols                                                                               *}
{* ============================================================================================== *}

{$IFNDEF ZYDIS_DYNAMIC_LINK}
procedure ZydisDecoderTreeGetRootNode; external
  name ZYDIS_SYMBOL_PREFIX + 'ZydisDecoderTreeGetRootNode';
procedure ZydisDecoderTreeGetChildNode; external
  name ZYDIS_SYMBOL_PREFIX + 'ZydisDecoderTreeGetChildNode';
procedure ZydisGetInstructionEncodingInfo; external
  name ZYDIS_SYMBOL_PREFIX + 'ZydisGetInstructionEncodingInfo';
procedure ZydisGetInstructionDefinition; external
  name ZYDIS_SYMBOL_PREFIX + 'ZydisGetInstructionDefinition';
procedure ZydisGetOperandDefinitions; external
  name ZYDIS_SYMBOL_PREFIX + 'ZydisGetOperandDefinitions';
procedure ZydisGetElementInfo; external
  name ZYDIS_SYMBOL_PREFIX + 'ZydisGetElementInfo';
procedure ZydisGetAccessedFlags; external
  name ZYDIS_SYMBOL_PREFIX + 'ZydisGetAccessedFlags';

{$IFDEF CPUX86}

function c_udivdi3(num,den:uint64):uint64; cdecl; {$ifdef darwin}[public, alias: '___udivdi3'];{$else}alias: '___udivdi3';{$endif}
begin
 result:=num div den;
end;

procedure __allmul; assembler;
asm
  mov         eax, dword ptr[esp+8]
  mov         ecx, dword ptr[esp+10h]
  or          ecx, eax
  mov         ecx, dword ptr[esp+0Ch]
  jne         @@hard
  mov         eax, dword ptr[esp+4]
  mul         ecx
  ret         10h
@@hard:
  push        ebx
  mul         ecx
  mov         ebx, eax
  mov         eax, dword ptr[esp+8]
  mul         dword ptr[esp+14h]
  add         ebx, eax
  mov         eax, dword ptr[esp+8]
  mul         ecx
  add         edx, ebx
  pop         ebx
  ret         10h
end;

procedure __aulldiv; assembler;
asm
  push        ebx
  push        esi
  mov         eax,dword ptr [esp+18h]
  or          eax,eax
  jne         @@L1
  mov         ecx,dword ptr [esp+14h]
  mov         eax,dword ptr [esp+10h]
  xor         edx,edx
  div         ecx
  mov         ebx,eax
  mov         eax,dword ptr [esp+0Ch]
  div         ecx
  mov         edx,ebx
  jmp         @@L2
@@L1:
  mov         ecx,eax
  mov         ebx,dword ptr [esp+14h]
  mov         edx,dword ptr [esp+10h]
  mov         eax,dword ptr [esp+0Ch]
@@L3:
  shr         ecx,1
  rcr         ebx,1
  shr         edx,1
  rcr         eax,1
  or          ecx,ecx
  jne         @@L3
  div         ebx
  mov         esi,eax
  mul         dword ptr [esp+18h]
  mov         ecx,eax
  mov         eax,dword ptr [esp+14h]
  mul         esi
  add         edx,ecx
  jb          @@L4
  cmp         edx,dword ptr [esp+10h]
  ja          @@L4
  jb          @@L5
  cmp         eax,dword ptr [esp+0Ch]
  jbe         @@L5
@@L4:
  dec         esi
@@L5:
  xor         edx,edx
  mov         eax,esi
@@L2:
  pop         esi
  pop         ebx
  ret         10h
end;

procedure __aullshr; assembler;
asm
  cmp         cl,40h
  jae         @@RETZERO
  cmp         cl,20h
  jae         @@MORE32
  shrd        eax,edx,cl
  shr         edx,cl
  ret
@@MORE32:
  mov         eax,edx
  xor         edx,edx
  and         cl,1Fh
  shr         eax,cl
  ret
@@RETZERO:
  xor         eax,eax
  xor         edx,edx
  ret
end;
{$ENDIF}

{$IFDEF CPUX86}
procedure _memcpy(destination: Pointer; const source: Pointer; num: NativeUInt); cdecl;
{$ENDIF}
{$IFDEF CPUX64}
procedure memcpy(destination: Pointer; const source: Pointer; num: NativeUInt); cdecl;
{$ENDIF}
begin
  Move(source^, destination^, num);
end;

{$IFDEF CPUX86}
procedure _memset(ptr: Pointer; value: Integer; num: NativeUInt); cdecl;
{$ENDIF}
{$IFDEF CPUX64}
procedure memset(ptr: Pointer; value: Integer; num: NativeUInt); cdecl;
{$ENDIF}
begin
  FillChar(ptr^, num, value);
end;
{$ENDIF}

{* ============================================================================================== *}
{* Macros                                                                                         *}
{* ============================================================================================== *}

{* ---------------------------------------------------------------------------------------------- *}
{* Zydis                                                                                          *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisVersionMajor(Version: ZydisU64): ZydisU16;
begin
  Result := (Version and $FFFF000000000000) shr 48;
end;

function ZydisVersionMinor(Version: ZydisU64): ZydisU16;
begin
  Result := (Version and $0000FFFF00000000) shr 32;
end;

function ZydisVersionPatch(Version: ZydisU64): ZydisU16;
begin
  Result := (Version and $00000000FFFF0000) shr 16;
end;

function ZydisVersionBuild(Version: ZydisU64): ZydisU16;
begin
  Result := (Version and $000000000000FFFF);
end;

{* ---------------------------------------------------------------------------------------------- *}
{* Status                                                                                         *}
{* ---------------------------------------------------------------------------------------------- *}

function ZydisSuccess(Status: TZydisStatus): Boolean;
begin
  Result := (Status = ZYDIS_STATUS_SUCCESS);
end;

{* ---------------------------------------------------------------------------------------------- *}

{* ============================================================================================== *}
{* Helper                                                                                         *}
{* ============================================================================================== *}

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisString                                                                                    *}
{* ---------------------------------------------------------------------------------------------- *}

function TZydisStringHelper.Append(const Value: TZydisString): TZydisStatus;
begin
  Result := ZydisStringAppend(Self, @Value);
end;

function TZydisStringHelper.Append(const Value: PAnsiChar): TZydisStatus;
begin
  Result := ZydisStringAppendC(Self, Value);
end;

function TZydisStringHelper.Init(Buffer: PAnsiChar; Capacity: ZydisUSize): TZydisStatus;
begin
  if (not Assigned(Buffer)) or (Capacity = 0) then
  begin
    Exit(ZYDIS_STATUS_INVALID_PARAMETER);
  end;
  Self.Buffer := Buffer;
  Self.Length := 0;
  Self.Capacity := Capacity;
  Result := ZYDIS_STATUS_SUCCESS;
end;

function TZydisStringHelper.Init(const Text: PAnsiChar): TZydisStatus;
begin
  Result := ZydisStringInit(Self, Text);
end;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisRegister                                                                                  *}
{* ---------------------------------------------------------------------------------------------- *}

function TZydisRegisterHelper.ToString: String;
var
  S: PAnsiChar;
begin
  Result := '';
  S := ZydisRegisterGetString(Self);
  if Assigned(S) then
  begin
    Result := String(AnsiString(S));
  end;
end;

{* ---------------------------------------------------------------------------------------------- *}
{* ZydisMnemonic                                                                                  *}
{* ---------------------------------------------------------------------------------------------- *}

function TZydisMnemonicHelper.ToString: String;
var
  S: PAnsiChar;
begin
  Result := '';
  S := ZydisMnemonicGetString(Self);
  if Assigned(S) then
  begin
    Result := String(AnsiString(S));
  end;
end;

{* ---------------------------------------------------------------------------------------------- *}

{* ============================================================================================== *}

end.

{
  Pascal language binding for the Capstone engine <http://www.capstone-engine.org/>

  Copyright (C) 2014, Stefan Ascher
}

unit CapstoneXCore;
{
  xcore.h
}

interface

type
  //> Operand type for instruction's operands
  xcore_op_type = (
    XCORE_OP_INVALID = 0, // = CS_OP_INVALID (Uninitialized).
    XCORE_OP_REG, // = CS_OP_REG (Register operand).
    XCORE_OP_IMM, // = CS_OP_IMM (Immediate operand).
    XCORE_OP_MEM_ // = CS_OP_MEM (Memory operand).
  );
  
  // Instruction's operand referring to memory
  // This is associated with XCORE_OP_MEM operand type above
  xcore_op_mem = record
    base: Byte;
    index: Byte;
    disp: Integer;
    direct: Integer;
  end;

  // Instruction operand
  cs_xcore_op = record
    _type: xcore_op_type;
    case Integer of
      0: (reg: Cardinal);
      1: (imm: Integer);
      2: (mem: xcore_op_mem);
  end;
 
  // Instruction structure
  cs_xcore = record
    op_count: Byte;
    operands: array[0..7] of cs_xcore_op;
  end;
  
  //> XCore registers
  xcore_reg = (
    XCORE_REG_INVALID = 0,

    XCORE_REG_CP,
    XCORE_REG_DP,
    XCORE_REG_LR,
    XCORE_REG_SP,
    XCORE_REG_R0,
    XCORE_REG_R1,
    XCORE_REG_R2,
    XCORE_REG_R3,
    XCORE_REG_R4,
    XCORE_REG_R5,
    XCORE_REG_R6,
    XCORE_REG_R7,
    XCORE_REG_R8,
    XCORE_REG_R9,
    XCORE_REG_R10,
    XCORE_REG_R11,

    //> pseudo registers
    XCORE_REG_PC,	// pc

    // internal thread registers
    // see The-XMOS-XS1-Architecture(X7879A).pdf
    XCORE_REG_SCP,	// save pc
    XCORE_REG_SSR,	// save status
    XCORE_REG_ET,	// exception type
    XCORE_REG_ED,	// exception data
    XCORE_REG_SED,	// save exception data
    XCORE_REG_KEP,	// kernel entry pointer
    XCORE_REG_KSP,	// kernel stack pointer
    XCORE_REG_ID,	// thread ID

    XCORE_REG_ENDING	// <-- mark the end of the list of registers
  );
  
  //> XCore instruction
  xcore_insn = (
    XCORE_INS_INVALID = 0,

    XCORE_INS_ADD,
    XCORE_INS_ANDNOT,
    XCORE_INS_AND,
    XCORE_INS_ASHR,
    XCORE_INS_BAU,
    XCORE_INS_BITREV,
    XCORE_INS_BLA,
    XCORE_INS_BLAT,
    XCORE_INS_BL,
    XCORE_INS_BF,
    XCORE_INS_BT,
    XCORE_INS_BU,
    XCORE_INS_BRU,
    XCORE_INS_BYTEREV,
    XCORE_INS_CHKCT,
    XCORE_INS_CLRE,
    XCORE_INS_CLRPT,
    XCORE_INS_CLRSR,
    XCORE_INS_CLZ,
    XCORE_INS_CRC8,
    XCORE_INS_CRC32,
    XCORE_INS_DCALL,
    XCORE_INS_DENTSP,
    XCORE_INS_DGETREG,
    XCORE_INS_DIVS,
    XCORE_INS_DIVU,
    XCORE_INS_DRESTSP,
    XCORE_INS_DRET,
    XCORE_INS_ECALLF,
    XCORE_INS_ECALLT,
    XCORE_INS_EDU,
    XCORE_INS_EEF,
    XCORE_INS_EET,
    XCORE_INS_EEU,
    XCORE_INS_ENDIN,
    XCORE_INS_ENTSP,
    XCORE_INS_EQ,
    XCORE_INS_EXTDP,
    XCORE_INS_EXTSP,
    XCORE_INS_FREER,
    XCORE_INS_FREET,
    XCORE_INS_GETD,
    XCORE_INS_GET,
    XCORE_INS_GETN,
    XCORE_INS_GETR,
    XCORE_INS_GETSR,
    XCORE_INS_GETST,
    XCORE_INS_GETTS,
    XCORE_INS_INCT,
    XCORE_INS_INIT,
    XCORE_INS_INPW,
    XCORE_INS_INSHR,
    XCORE_INS_INT,
    XCORE_INS_IN,
    XCORE_INS_KCALL,
    XCORE_INS_KENTSP,
    XCORE_INS_KRESTSP,
    XCORE_INS_KRET,
    XCORE_INS_LADD,
    XCORE_INS_LD16S,
    XCORE_INS_LD8U,
    XCORE_INS_LDA16,
    XCORE_INS_LDAP,
    XCORE_INS_LDAW,
    XCORE_INS_LDC,
    XCORE_INS_LDW,
    XCORE_INS_LDIVU,
    XCORE_INS_LMUL,
    XCORE_INS_LSS,
    XCORE_INS_LSUB,
    XCORE_INS_LSU,
    XCORE_INS_MACCS,
    XCORE_INS_MACCU,
    XCORE_INS_MJOIN,
    XCORE_INS_MKMSK,
    XCORE_INS_MSYNC,
    XCORE_INS_MUL,
    XCORE_INS_NEG,
    XCORE_INS_NOT,
    XCORE_INS_OR,
    XCORE_INS_OUTCT,
    XCORE_INS_OUTPW,
    XCORE_INS_OUTSHR,
    XCORE_INS_OUTT,
    XCORE_INS_OUT,
    XCORE_INS_PEEK,
    XCORE_INS_REMS,
    XCORE_INS_REMU,
    XCORE_INS_RETSP,
    XCORE_INS_SETCLK,
    XCORE_INS_SET,
    XCORE_INS_SETC,
    XCORE_INS_SETD,
    XCORE_INS_SETEV,
    XCORE_INS_SETN,
    XCORE_INS_SETPSC,
    XCORE_INS_SETPT,
    XCORE_INS_SETRDY,
    XCORE_INS_SETSR,
    XCORE_INS_SETTW,
    XCORE_INS_SETV,
    XCORE_INS_SEXT,
    XCORE_INS_SHL,
    XCORE_INS_SHR,
    XCORE_INS_SSYNC,
    XCORE_INS_ST16,
    XCORE_INS_ST8,
    XCORE_INS_STW,
    XCORE_INS_SUB,
    XCORE_INS_SYNCR,
    XCORE_INS_TESTCT,
    XCORE_INS_TESTLCL,
    XCORE_INS_TESTWCT,
    XCORE_INS_TSETMR,
    XCORE_INS_START,
    XCORE_INS_WAITEF,
    XCORE_INS_WAITET,
    XCORE_INS_WAITEU,
    XCORE_INS_XOR,
    XCORE_INS_ZEXT,

    XCORE_INS_ENDING   // <-- mark the end of the list of instructions
  );

  //> Group of XCore instructions
  xcore_insn_group = (
    XCORE_GRP_INVALID = 0, // = CS_GRP_INVALID

    //> Generic groups
    // all jump instructions (conditional+direct+indirect jumps)
    XCORE_GRP_JUMP,	// = CS_GRP_JUMP

    XCORE_GRP_ENDING   // <-- mark the end of the list of groups
  );
  
implementation

end.
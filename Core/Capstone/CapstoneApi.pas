{
  Pascal language binding for the Capstone engine <http://www.capstone-engine.org/>

  Copyright (C) 2014, Stefan Ascher
}
unit CapstoneApi;
{
  capstone.h
}
{$SMARTLINK ON}
{$PackRecords C}

interface

uses
  SysUtils,ctypes, CapstoneX86, CapstoneArm64, CapstoneArm, CapstoneMips,
  CapstonePpc, CapstoneSparc, CapstoneSystemZ, CapstoneXCore;


{$ifdef darwin}
   {$Link ../libraries/osx/libcapstone.a}
{$endif}
{$ifdef Linux}
   {$Link ../libraries/linux/libcapstone.a}
{$endif}
{$ifdef windows}
const
  {$IFDEF CPU64}
   LIB_FILE =  'capstone64.dll';
  {$ELSE}
    LIB_FILE = 'capstone32.dll';
  {$ENDIF}
{$endif}

type
  csh = NativeUInt;
  Pcsh = ^csh;

  // Architecture type
  cs_arch = (
    CS_ARCH_ARM = 0,     // ARM architecture (including Thumb, Thumb-2)
    CS_ARCH_ARM64,       // ARM-64, also called AArch64
    CS_ARCH_MIPS,        // Mips architecture
    CS_ARCH_X86,         // X86 architecture (including x86 & x86-64)
    CS_ARCH_PPC,         // PowerPC architecture
    CS_ARCH_SPARC,       // Sparc architecture
    CS_ARCH_SYSZ,        // SystemZ architecture
    CS_ARCH_XCORE,       // XCore architecture
    CS_ARCH_MAX,
    CS_ARCH_ALL = $FFFF  // All architectures - for cs_support()
  );

type
  // Mode type
  cs_mode = Cardinal;

const
  CS_MODE_LITTLE_ENDIAN = 0;      // little-endian mode (default mode)
  CS_MODE_ARM = 0;                // 32-bit ARM
  CS_MODE_16 = 1 shl 1;           // 16-bit mode (X86)
  CS_MODE_32 = 1 shl 2;           // 32-bit mode (X86)
  CS_MODE_64 = 1 shl 3;           // 64-bit mode (X86, PPC)
  CS_MODE_THUMB = 1 shl 4;        // ARM's Thumb mode, including Thumb-2
  CS_MODE_MCLASS = 1 shl 5;       // ARM's Cortex-M series
  CS_MODE_V8 = 1 shl 6;           // ARMv8 A32 encodings for ARM
  CS_MODE_MICRO = 1 shl 4;        // MicroMips mode (MIPS)
  CS_MODE_MIPS3 = 1 shl 5;        // Mips III ISA
  CS_MODE_MIPS32R6 = 1 shl 6;     // Mips32r6 ISA
  CS_MODE_MIPSGP64 = 1 shl 7;     // General Purpose Registers are 64-bit wide (MIPS)
  CS_MODE_V9 = 1 shl 4;           // SparcV9 mode (Sparc)
  CS_MODE_BIG_ENDIAN = 1 shl 31;  // big-endian mode
  CS_MODE_MIPS32 = CS_MODE_32;    // Mips32 ISA (Mips)
  CS_MODE_MIPS64 = CS_MODE_64;    // Mips64 ISA (Mips)

type
  // Runtime option for the disassembled engine
  cs_opt_type = (
    CS_OPT_SYNTAX = 1,    // Asssembly output syntax
    CS_OPT_DETAIL,        // Break down instruction structure into details
    CS_OPT_MODE,          // Change engine's mode at run-time
    CS_OPT_MEM,           // User-defined dynamic memory related functions
    CS_OPT_SKIPDATA,      // Skip data when disassembling. Then engine is in SKIPDATA mode.
    CS_OPT_SKIPDATA_SETUP // Setup user-defined function for SKIPDATA option
  );

  // Runtime option value (associated with option type above)
  cs_opt_value = (
    CS_OPT_OFF = 0,            // Turn OFF an option - default option of CS_OPT_DETAIL, CS_OPT_SKIPDATA.
    CS_OPT_ON = 3,             // Turn ON an option (CS_OPT_DETAIL, CS_OPT_SKIPDATA).
    CS_OPT_SYNTAX_DEFAULT = 0, // Default asm syntax (CS_OPT_SYNTAX).
    CS_OPT_SYNTAX_INTEL,       // X86 Intel asm syntax - default on X86 (CS_OPT_SYNTAX).
    CS_OPT_SYNTAX_ATT,         // X86 ATT asm syntax (CS_OPT_SYNTAX).
    CS_OPT_SYNTAX_NOREGNAME    // Prints register name with only number (CS_OPT_SYNTAX)
  );

  //> Common instruction operand types - to be consistent across all architectures.
  cs_op_type = (
    CS_OP_INVALID = 0,  // uninitialized/invalid operand.
    CS_OP_REG,          // Register operand.
    CS_OP_IMM,          // Immediate operand.
    CS_OP_MEM,          // Memory operand.
    CS_OP_FP            // Floating-Point operand.
  );

  //> Common instruction groups - to be consistent across all architectures.
  cs_group_type = (
    CS_GRP_INVALID = 0,  // uninitialized/invalid group.
    CS_GRP_JUMP,    // all jump instructions (conditional+direct+indirect jumps)
    CS_GRP_CALL,    // all call instructions
    CS_GRP_RET,     // all return instructions
    CS_GRP_INT,     // all interrupt instructions (int+syscall)
    CS_GRP_IRET     // all interrupt return instructions
  );

  cs_detail = record
    regs_read: array[0..11] of Byte;
    regs_read_count: Byte;

    regs_write: array[0..19] of Byte;
    regs_write_count: Byte;

    groups: array[0..7] of Byte;
    groups_count: Byte;

    // Architecture-specific instruction info
    case Byte of
      0: (x86: cs_x86);
      1: (arm64: cs_arm64);
      2: (arm: cs_arm);
      3: (mips: cs_mips);
      4: (ppc: cs_ppc);
      5: (sparc: cs_sparc);
      6: (sysz: cs_sysz);
      7: (xcore: cs_xcore);
  end;

  cs_insn = record
    id: cuint;
    address: cuint64;
    size: cuint16;
    bytes: array[0..15] of Byte;
    mnemonic: array[0..31] of AnsiChar;
    op_str: array[0..159] of AnsiChar;
    detail: ^cs_detail;
  end;
  Pcs_insn = ^cs_insn;

  // All type of errors encountered by Capstone API.
  // These are values returned by cs_errno()
  cs_err = (
    CS_ERR_OK = 0,   // No error: everything was fine
    CS_ERR_MEM,      // Out-Of-Memory error: cs_open(), cs_disasm(), cs_disasm_iter()
    CS_ERR_ARCH,     // Unsupported architecture: cs_open()
    CS_ERR_HANDLE,   // Invalid handle: cs_op_count(), cs_op_index()
    CS_ERR_CSH,      // Invalid csh argument: cs_close(), cs_errno(), cs_option()
    CS_ERR_MODE,     // Invalid/unsupported mode: cs_open()
    CS_ERR_OPTION,   // Invalid/unsupported option: cs_option()
    CS_ERR_DETAIL,   // Information is unavailable because detail option is OFF
    CS_ERR_MEMSETUP, // Dynamic memory management uninitialized (see CS_OPT_MEM)
    CS_ERR_VERSION,  // Unsupported version (bindings)
    CS_ERR_DIET,     // Access irrelevant data in "diet" engine
    CS_ERR_SKIPDATA, // Access irrelevant data for "data" instruction in SKIPDATA mode
    CS_ERR_X86_ATT,  // X86 AT&T syntax is unsupported (opt-out at compile time)
    CS_ERR_X86_INTEL // X86 Intel syntax is unsupported (opt-out at compile time)
  );

{
 Return combined API version & major and minor version numbers.

 @major: major number of API version
 @minor: minor number of API version

 @return hexical number as (major << 8 | minor), which encodes both
   major & minor versions.
   NOTE: This returned value can be compared with version number made
   with macro CS_MAKE_VERSION

 For example, second API version would return 1 in @major, and 1 in @minor
 The return value would be 0x0101

 NOTE: if you only care about returned value, but not major and minor values,
 set both @major & @minor arguments to NULL.
}
function cs_version(var major, minor: integer): Cardinal; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 This API can be used to either ask for archs supported by this library,
 or check to see if the library was compile with 'diet' option (or called
 in 'diet' mode).

 To check if a particular arch is supported by this library, set @query to
 arch mode (CS_ARCH_* value).
 To verify if this library supports all the archs, use CS_ARCH_ALL.

 To check if this library is in 'diet' mode, set @query to CS_SUPPORT_DIET.

 @return True if this library supports the given arch, or in 'diet' mode.
}
function cs_support(query: integer): boolean; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Initialize CS handle: this must be done before any usage of CS.

 @arch: architecture type (CS_ARCH_*)
 @mode: hardware mode. This is combined of CS_MODE_*
 @handle: pointer to handle, which will be updated at return time

 @return CS_ERR_OK on success, or other value on failure (refer to cs_err enum
 for detailed error).
}
function cs_open(arch: Cardinal; mode: Cardinal; handle: Pcsh): cs_err; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Close CS handle: MUST do to release the handle when it is not used anymore.
 NOTE: this must be only called when there is no longer usage of Capstone,
 not even access to cs_insn array. The reason is the this API releases some
 cached memory, thus access to any Capstone API after cs_close() might crash
 your application.

 In fact,this API invalidate @handle by ZERO out its value (i.e *handle = 0).

 @handle: pointer to a handle returned by cs_open()

 @return CS_ERR_OK on success, or other value on failure (refer to cs_err enum
 for detailed error).
}
function cs_close(var handle: csh): cs_err; cdecl; external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Set option for disassembling engine at runtime

 @handle: handle returned by cs_open()
 @type: type of option to be set
 @value: option value corresponding with @type

 @return: CS_ERR_OK on success, or other value on failure.
 Refer to cs_err enum for detailed error.

 NOTE: in the case of CS_OPT_MEM, handle's value can be anything,
 so that cs_option(handle, CS_OPT_MEM, value) can (i.e must) be called
 even before cs_open()
}
function cs_option(handle: csh; _type: cs_opt_type; value: NativeUInt): cs_err; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Report the last error number when some API function fail.
 Like glibc's errno, cs_errno might not retain its old value once accessed.

 @handle: handle returned by cs_open()

 @return: error code of cs_err enum type (CS_ERR_*, see above)
}
function cs_errno(handle: csh): cs_err; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Return a string describing given error code.

 @code: error code (see CS_ERR_* above)

 @return: returns a pointer to a string that describes the error code
  passed in the argument @code
}
function cs_strerror(code: cs_err): PansiChar; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Disassemble binary code, given the code buffer, size, address and number
 of instructions to be decoded.
 This API dynamicly allocate memory to contain disassembled instruction.
 Resulted instructions will be put into @*insn

 NOTE 1: this API will automatically determine memory needed to contain
 output disassembled instructions in @insn.

 NOTE 2: caller must free the allocated memory itself to avoid memory leaking.

 NOTE 3: for system with scarce memory to be dynamically allocated such as
 OS kernel or firmware, the API cs_disasm_iter() might be a better choice than
 cs_disasm(). The reason is that with cs_disasm(), based on limited available
 memory, we have to calculate in advance how many instructions to be disassembled,
 which complicates things. This is especially troublesome for the case @count=0,
 when cs_disasm() runs uncontrolly (until either end of input buffer, or
 when it encounters an invalid instruction).

 @handle: handle returned by cs_open()
 @code: buffer containing raw binary code to be disassembled.
 @code_size: size of the above code buffer.
 @address: address of the first instruction in given raw code buffer.
 @insn: array of instructions filled in by this API.
     NOTE: @insn will be allocated by this function, and should be freed
     with cs_free() API.
 @count: number of instrutions to be disassembled, or 0 to get all of them

 @return: the number of succesfully disassembled instructions,
 or 0 if this function failed to disassemble the given code

 On failure, call cs_errno() for error code.
}
function cs_disasm(handle: csh;
  const code: Pointer; size: NativeUInt;
  address: UInt64;
  count: NativeUInt;
  var insn: array of Pcs_insn): NativeUInt; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Free memory allocated by cs_malloc() or cs_disasm() (argument @insn)

 @insn: pointer returned by @insn argument in cs_disasm() or cs_malloc()
 @count: number of cs_insn structures returned by cs_disasm(), or 1
     to free memory allocated by cs_malloc().
}
procedure cs_free(insn: Pcs_insn; count: NativeUInt); cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Allocate memory for 1 instruction to be used by cs_disasm_iter().

 @handle: handle returned by cs_open()

 NOTE: when no longer in use, you can reclaim the memory allocated for
 this instruction with cs_free(insn, 1)
}
function cs_malloc(handle: csh): Pcs_insn; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Fast API to disassemble binary code, given the code buffer, size, address
 and number of instructions to be decoded.
 This API put the resulted instruction into a given cache in @insn.
 See tests/test_iter.c for sample code demonstrating this API.

 NOTE 1: this API will update @code, @size & @address to point to the next
 instruction in the input buffer. Therefore, it is covenient to use
 cs_disasm_iter() inside a loop to quickly iterate all the instructions.
 While decoding one instruction at a time can also be achieved with
 cs_disasm(count=1), some benchmarks shown that cs_disasm_iter() can be 30%
 faster on random input.

 NOTE 2: the cache in @insn can be created with cs_malloc() API.

 NOTE 3: for system with scarce memory to be dynamically allocated such as
 OS kernel or firmware, this API is recommended over cs_disasm(), which
 allocates memory based on the number of instructions to be disassembled.
 The reason is that with cs_disasm(), based on limited available memory,
 we have to calculate in advance how many instructions to be disassembled,
 which complicates things. This is especially troublesome for the case
 @count=0, when cs_disasm() runs uncontrolly (until either end of input
 buffer, or when it encounters an invalid instruction).

 @handle: handle returned by cs_open()
 @code: buffer containing raw binary code to be disassembled
 @code_size: size of above code
 @address: address of the first insn in given raw code buffer
 @insn: pointer to instruction to be filled in by this API.

 @return: true if this API successfully decode 1 instruction,
 or false otherwise.

 On failure, call cs_errno() for error code.
}
function cs_disasm_iter(handle: csh;
  var code: Pointer; var size: NativeUInt;
  var address: UInt64; insn: Pcs_insn): boolean; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Return friendly name of regiser in a string.
 Find the instruction id from header file of corresponding architecture (arm.h for ARM,
 x86.h for X86, ...)

 WARN: when in 'diet' mode, this API is irrelevant because engine does not
 store register name.

 @handle: handle returned by cs_open()
 @reg_id: register id

 @return: string name of the register, or NULL if @reg_id is invalid.
}
function cs_reg_name(handle: csh; reg_id: Cardinal): PAnsiChar; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Return friendly name of an instruction in a string.
 Find the instruction id from header file of corresponding architecture (arm.h for ARM, x86.h for X86, ...)

 WARN: when in 'diet' mode, this API is irrelevant because the engine does not
 store instruction name.

 @handle: handle returned by cs_open()
 @insn_id: instruction id

 @return: string name of the instruction, or NULL if @insn_id is invalid.
}
function cs_insn_name(handle: csh; insn_id: Cardinal): PAnsiChar; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Return friendly name of a group id (that an instruction can belong to)
 Find the group id from header file of corresponding architecture (arm.h for ARM, x86.h for X86, ...)

 WARN: when in 'diet' mode, this API is irrelevant because the engine does not
 store group name.

 @handle: handle returned by cs_open()
 @group_id: group id

 @return: string name of the group, or NULL if @group_id is invalid.
}
function cs_group_name(handle: csh; group_id: Cardinal): PAnsiChar; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Check if a disassembled instruction belong to a particular group.
 Find the group id from header file of corresponding architecture (arm.h for ARM, x86.h for X86, ...)
 Internally, this simply verifies if @group_id matches any member of insn->groups array.

 NOTE: this API is only valid when detail option is ON (which is OFF by default).

 WARN: when in 'diet' mode, this API is irrelevant because the engine does not
 update @groups array.

 @handle: handle returned by cs_open()
 @insn: disassembled instruction structure received from cs_disasm() or cs_disasm_iter()
 @group_id: group that you want to check if this instruction belong to.

 @return: true if this instruction indeed belongs to aboved group, or false otherwise.
}
function cs_insn_group(handle: csh; const insn: Pcs_insn; group_id: Cardinal): boolean; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Check if a disassembled instruction IMPLICITLY used a particular register.
 Find the register id from header file of corresponding architecture (arm.h for ARM, x86.h for X86, ...)
 Internally, this simply verifies if @reg_id matches any member of insn->regs_read array.

 NOTE: this API is only valid when detail option is ON (which is OFF by default)

 WARN: when in 'diet' mode, this API is irrelevant because the engine does not
 update @regs_read array.

 @insn: disassembled instruction structure received from cs_disasm() or cs_disasm_iter()
 @reg_id: register that you want to check if this instruction used it.

 @return: true if this instruction indeed implicitly used aboved register, or false otherwise.
}
function cs_reg_read(handle: csh; const insn: Pcs_insn; reg_id: Cardinal): boolean; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Check if a disassembled instruction IMPLICITLY modified a particular register.
 Find the register id from header file of corresponding architecture (arm.h for ARM, x86.h for X86, ...)
 Internally, this simply verifies if @reg_id matches any member of insn->regs_write array.

 NOTE: this API is only valid when detail option is ON (which is OFF by default)

 WARN: when in 'diet' mode, this API is irrelevant because the engine does not
 update @regs_write array.

 @insn: disassembled instruction structure received from cs_disasm() or cs_disasm_iter()
 @reg_id: register that you want to check if this instruction modified it.

 @return: true if this instruction indeed implicitly modified aboved register, or false otherwise.
}
function cs_reg_write(handle: csh; const insn: Pcs_insn; reg_id: Cardinal): boolean; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Count the number of operands of a given type.
 Find the operand type in header file of corresponding architecture (arm.h for ARM, x86.h for X86, ...)

 NOTE: this API is only valid when detail option is ON (which is OFF by default)

 @handle: handle returned by cs_open()
 @insn: disassembled instruction structure received from cs_disasm() or cs_disasm_iter()
 @op_type: Operand type to be found.

 @return: number of operands of given type @op_type in instruction @insn,
 or -1 on failure.
}
function cs_op_count(handle: csh; const insn: Pcs_insn; op_type: Cardinal): integer; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

{
 Retrieve the position of operand of given type in <arch>.operands[] array.
 Later, the operand can be accessed using the returned position.
 Find the operand type in header file of corresponding architecture (arm.h for ARM, x86.h for X86, ...)

 NOTE: this API is only valid when detail option is ON (which is OFF by default)

 @handle: handle returned by cs_open()
 @insn: disassembled instruction structure received from cs_disasm() or cs_disasm_iter()
 @op_type: Operand type to be found.
 @position: position of the operand to be found. This must be in the range
      [1, cs_op_count(handle, insn, op_type)]

 @return: index of operand of given type @op_type in <arch>.operands[] array
 in instruction @insn, or -1 on failure.
}
function cs_op_index(handle: csh; const insn: Pcs_insn; op_type: Cardinal; position: Cardinal): integer; cdecl external {$ifdef windows}LIB_FILE{$ENDIF};

// Calculate relative address for X86-64, given cs_insn structure
function X86_REL_ADDR(insn: cs_insn): UInt64;

implementation

function X86_REL_ADDR(insn: cs_insn): UInt64;
begin
	Result := insn.address + insn.size + insn.detail^.x86.disp;
end;

end.

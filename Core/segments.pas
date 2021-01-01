{$IFDEF FPC}
    {$MODE Delphi}
    {$PackRecords C}
    {$SMARTLINK ON}
{$ENDIF}
unit Segments;



interface

uses
  Classes, SysUtils , ctypes , math,
  Unicorn_dyn, UnicornConst, X86Const,Utils;


type
  T4Bits = 0..15;
  T2Bits = 0..3;
  T1Bit  = 0..1;

  TFlags = bitpacked record
    case boolean of
      false : (
      // FLAGS .
        CF,            // Carry flag .
        Reserved1,     // Reserved, always 1 in EFLAGS .
        PF,            // Parity flag .
        Reserved2,     // Reserved .
        AF,            // Adjust flag .
        Reserved3,     // Reserved .
        ZF,            // Zero flag .
        SF,            // Sign flag .
        TF,            // Trap flag (single step) .
        &IF,           // Interrupt enable flag .
        DF,            // Direction flag .
        &OF            // Overflow flag .
        : T1Bit;
        IOPL : T2Bits; // I/O privilege level (286+ only), always 1 on 8086 and 186 .
        NT,            // Nested task flag (286+ only), always 1 on 8086 and 186 .
        Reserved4,     // Reserved, always 1 on 8086 and 186, always 0 on later models .
      // EFLAGS .
        RF,            // Resume flag (386+ only) .
        VM,            // Virtual 8086 mode flag (386+ only) .
        AC,            // Alignment check (486SX+ only) .
        VIF,           // Virtual interrupt flag (Pentium+) .
        VIP,           // Virtual interrupt pending (Pentium+).
        ID,            // Able to use CPUID instruction (Pentium+).
        ID2            // Able to use CPUID instruction (Pentium+).
        : T1Bit;
        VAD : T2Bits;  // VAD Flag .
      // RFLAGS .
        Reserved5 : DWORD;
      );
      true : (FLAGS : uint64) ;
  end;

  TSegmentDescriptor = bitpacked record
    case boolean of
    false :(
      limit0      : cshort;
      base0       : cshort;
      base1       : cchar;
      &type       : T4Bits;
      system      : T1Bit;   //* S flag */
      dpl         : T2Bits;
      present     : T1Bit;   //* P flag */
      limit1      : T4Bits;
      avail       : T1Bit;
      is_64_code  : T1Bit;   //* L flag */
      db          : T1Bit;   //* DB flag */
      granularity : T1Bit;   //* G flag */
      base2       : cchar;
    );
    true : (desc: uint64);
  end;
  PSegmentDescriptor = ^TSegmentDescriptor;



const
  F_GRANULARITY   = $8;	 // If set block=4KiB otherwise block=1B .
  F_PROT_32 	  = $4;  // Protected Mode 32 bit .
  F_LONG 	  = $2;	 // Long Mode .
  F_AVAILABLE 	  = $1;	 // Free Use .
  A_PRESENT 	  = $80; // Segment active .
  A_PRIV_3 	  = $60; // Ring 3 Privs .
  A_PRIV_2 	  = $40; // Ring 2 Privs .
  A_PRIV_1 	  = $20; // Ring 1 Privs .
  A_PRIV_0 	  = $0;	 // Ring 0 Privs .
  A_CODE 	  = $10; // Code Segment .
  A_DATA 	  = $10; // Data Segment .
  A_TSS 	  = $0;	 // TSS .
  A_GATE 	  = $0;	 // GATE .
  A_EXEC 	  = $8;	 // Executable .
  A_DATA_WRITABLE = $2;
  A_CODE_READABLE = $2;
  A_DIR_CON_BIT   = $4;
  S_GDT 	  = $0;	// Index points to GDT .
  S_LDT 	  = $4;	// Index points to LDT .
  S_PRIV_3 	  = $3;	// Ring 3 Privs .
  S_PRIV_2        = $2;	// Ring 2 Privs .
  S_PRIV_1        = $1;	// Ring 1 Privs .
  S_PRIV_0        = $0;	// Ring 0 Privs .

  FSMSR = $C0000100;
  GSMSR = $C0000101;


function CreateSelector(idx,flags : UInt32): UInt64;
procedure Init_Descriptor(desc : PSegmentDescriptor; base, limit{, access, flags} : UInt32; is_code : boolean);
procedure Init_GDT(desc : PSegmentDescriptor; base, limit, access, flags : UInt32);


function SetFS(uc : uc_engine; addr : UInt64): boolean;
function GetFS(uc : uc_engine; var addr : UInt64): boolean;

function SetGS(uc : uc_engine; addr : UInt64): boolean;
function GetGS(uc : uc_engine; var addr : UInt64): boolean;


implementation
  uses
    Globals;

function setMSR(uc : uc_engine; msr , value : UInt64; SCRATCH_ADDR : UInt64 = $80000) : boolean;
var
  o_rax,o_rdx,o_rcx,o_rip : UInt64;
  err : uc_err;
const
  code : array [0..1] of byte = ($0f,$30); // wrmsr .
begin
  Result := false;
  o_rax := reg_read_x64(uc,UC_X86_REG_RAX);
  o_rdx := reg_read_x64(uc,UC_X86_REG_RDX);
  o_rcx := reg_read_x64(uc,UC_X86_REG_RCX);
  o_rip := reg_read_x64(uc,UC_X86_REG_RIP);
  err := uc_mem_write_(uc,SCRATCH_ADDR,@code,Length(code));
  if err = UC_ERR_OK then
  begin
    reg_write_x64(uc,UC_X86_REG_RAX,(value and $FFFFFFFF));
    reg_write_x64(uc,UC_X86_REG_RDX,((value shr 32) and $FFFFFFFF));
    reg_write_x64(uc,UC_X86_REG_RCX,(msr and $FFFFFFFF));
    err := uc_emu_start(uc,SCRATCH_ADDR,SCRATCH_ADDR+Length(code),0,1);
    if err = UC_ERR_OK then
    begin
      Result := true;
    end;
    reg_write_x64(uc,UC_X86_REG_RAX,o_rax);
    reg_write_x64(uc,UC_X86_REG_RDX,o_rdx);
    reg_write_x64(uc,UC_X86_REG_RCX,o_rcx);
    reg_write_x64(uc,UC_X86_REG_RIP,o_rip);
  end;
end;

function getMSR(uc : uc_engine; msr : UInt64; var value : UInt64; SCRATCH_ADDR : UInt64 = $80000) : boolean;
var
  o_rax,o_rdx,o_rcx,o_rip,r_eax,r_edx : UInt64;
  err : uc_err;
const
  code : array [0..1] of byte = ($0f,$32); // rdmsr .
begin
  Result := false; value := 0;

  o_rax := reg_read_x64(uc,UC_X86_REG_RAX);
  o_rdx := reg_read_x64(uc,UC_X86_REG_RDX);
  o_rcx := reg_read_x64(uc,UC_X86_REG_RCX);
  o_rip := reg_read_x64(uc,UC_X86_REG_RIP);

  err := uc_mem_write_(uc,SCRATCH_ADDR,@code,Length(code));
  if err = UC_ERR_OK then
  begin
    reg_write_x64(uc,UC_X86_REG_RCX,(msr and $FFFFFFFF));
    err := uc_emu_start(uc,SCRATCH_ADDR,SCRATCH_ADDR+Length(code),0,1);
    if err = UC_ERR_OK then
    begin
      Result := true;
      r_eax := reg_read_x32(uc,UC_X86_REG_EAX);
      r_edx := reg_read_x32(uc,UC_X86_REG_EDX);
      value := (r_edx shl 32) or (r_eax and $FFFFFFFF);
    end;
    reg_write_x64(uc,UC_X86_REG_RAX,o_rax);
    reg_write_x64(uc,UC_X86_REG_RDX,o_rdx);
    reg_write_x64(uc,UC_X86_REG_RCX,o_rcx);
    reg_write_x64(uc,UC_X86_REG_RIP,o_rip);
  end;
end;
// set FS for x64 CPU ..
function SetFS(uc : uc_engine; addr : UInt64): boolean;
begin
  Result := setMSR(uc,FSMSR,addr);
end;

// Get FS for x64 CPU ..
function GetFS(uc : uc_engine; var addr : UInt64): boolean;
begin
  Result := getMSR(uc,FSMSR,addr);
end;

// set GS for x64 CPU ..
function SetGS(uc : uc_engine; addr : UInt64): boolean;
begin
  Result := setMSR(uc,GSMSR,addr);
end;

// Get GS for x64 CPU ..
function GetGS(uc : uc_engine; var addr : UInt64): boolean;
begin
  Result := getMSR(uc,GSMSR,addr);
end;

function CreateSelector(idx,flags : UInt32): UInt64;
begin
  Result := flags;
  Result := UInt64(Result or idx shl 3);
end;
                                                            // access, flags
procedure Init_Descriptor(desc : PSegmentDescriptor; base, limit : UInt32;  is_code : boolean);
begin
  desc.desc := 0;  //clear the descriptor .
  desc.base0 := base and $ffff;
  desc.base1 := cchar((base shr 16) and $ff);
  desc.base2 := base shr 24;
  if (limit > $fffff) then
  begin
      //need Giant granularity .
      limit := limit shr 12;
      desc.granularity := 1;
  end;
  desc.limit0 := cshort(limit and $ffff);
  desc.limit1 := limit shr 16;

  //some sane defaults
  if Emulator.isx64 then
    desc.is_64_code := 1;
  desc.dpl := 3;
  desc.present := 1;
  desc.db := 1;   //32 bit
  desc.&type := ifthen(is_code, $b, 3);
  desc.system := 1;  //code or data
end;

// not used but maybe i'll improve it .
procedure Init_GDT(desc : PSegmentDescriptor;
  base, limit, access, flags : UInt32);
begin
  access := access or 1 shr 7;
  if limit > $fffff then
  begin
   limit := limit shr 12;
   flags := flags or 8;
  end;

  desc.desc := 0;
  desc.desc := UInt64(limit) and $ffff;
  desc.desc := desc.desc or ((UInt64(limit) shr 16) and $f ) shl 48;
  desc.desc := desc.desc or (UInt64(base) and $ffffff) shl 16;
  desc.desc := desc.desc or ((UInt64(base) shr 24) and $ff) shl 56;
  desc.desc := desc.desc or (UInt64(access) and $ff) shl 40;
  desc.desc := desc.desc or (UInt64(flags) and $ff) shl 52;
  desc.desc := UInt64(desc.desc);

  Writeln(Format('desc : %x',[desc.desc]));

end;

end.

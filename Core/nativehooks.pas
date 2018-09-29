unit NativeHooks;

{$mode delphi}

interface

uses
  Classes, SysUtils, Crt ,JSEmuObj,FnHook,Emu,math,
  Unicorn_dyn , UnicornConst, X86Const;


procedure InstallNativeHooks();

implementation
  uses
    Globals,Utils,TEP_PEB;

function ZwContinue( uc : uc_engine; Address , ret : UInt64 ) : Boolean; stdcall;
var
  ExceptionRec : UInt64 = 0;
  Context      : UInt64 = 0;
  ExceptionRecord : EXCEPTION_RECORD_32;
  ContextRecord : CONTEXT_32;
begin

  ExceptionRec := pop();
  pop(); // Old ESP ..
  Context := pop();

  Initialize(ExceptionRecord);
  FillByte(ExceptionRecord,SizeOf(ExceptionRecord),0);
  Initialize(ContextRecord);
  FillByte(ContextRecord,SizeOf(ContextRecord),0);

  Emulator.err := uc_mem_read_(uc,ExceptionRec,@ExceptionRecord,SizeOf(ExceptionRecord));

  Emulator.err := uc_mem_read_(uc,Context,@ContextRecord,SizeOf(ContextRecord));
  if Emulator.err <> UC_ERR_OK then
  begin
    TextColor(LightRed);
    Writeln('ZwContinue : Error While Reading ContextRecord');
    NormVideo;
    halt(0);
  end;

  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RBP,UC_X86_REG_EBP),@ContextRecord.Ebp);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RSP,UC_X86_REG_ESP),@ContextRecord.Esp);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RIP,UC_X86_REG_EIP),@ContextRecord.Eip);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RDI,UC_X86_REG_EDI),@ContextRecord.Edi);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RSI,UC_X86_REG_ESI),@ContextRecord.Esi);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RBX,UC_X86_REG_EBX),@ContextRecord.Ebx);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RDX,UC_X86_REG_EDX),@ContextRecord.Edx);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RCX,UC_X86_REG_ECX),@ContextRecord.Ecx);
  uc_reg_write(uc,ifthen(Emulator.PE_x64,UC_X86_REG_RAX,UC_X86_REG_EAX),@ContextRecord.Eax);

  Emulator.Flags.FLAGS := ContextRecord.EFlags;
  reg_write_x64(uc,UC_X86_REG_EFLAGS,Emulator.Flags.FLAGS);

  if VerboseExcp then
  begin
    TextColor(LightMagenta);
    Writeln(Format('ZwContinue -> Context = 0x%x',[Context]));
    NormVideo;
  end;

  Result := True;
end;

procedure InstallNativeHooks();
begin
  Emulator.Hooks.ByName.AddOrSetValue('ZwContinue',THookFunction.Create(
   'ntdll','ZwContinue',0,False,@ZwContinue,nil));

end;

end.


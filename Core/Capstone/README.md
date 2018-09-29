# Capstone for Delphi

Delphi/Free Pascal Unit to use the [Capstone Disassembler Library](http://www.capstone-engine.org/).
This Unit has been tested with Free Pascal 2.6.4 and Delphi XE3.

I was able to compile and run the test project on Linux Debian 7.8. I used quite dated 
versions of Lazarus (0.9.30.4-6) and Free Pascal (2.6.0) with no problems.

[Sad Sam](https://0x2a.wtf/projects/sad) uses this unit to disassemble binaries.

## License

BSD

## Usage

Included is the wrapper class `TCapstone` in `Capstone.pas`. The example bellow 
is incomplete, but it may give you an impression how to use it.

    uses
      ..., Capstone, CapstoneCmn, CapstoneApi;
      
    var 
      disasm: TCapstone;
      addr: Int64;
      insn: TCsInsn;
      stream: TMemoryStream;
    begin
      // Load the code into stream
      disasm := TCapstone.Create;
      try
        disasm.Mode := [csm32];
        disasm.Arch := csaX86;
        addr := 0;
        if disasm.Open(stream.Memory, stream.Size) = CS_ERR_OK then begin
          while disasm.GetNext(addr, insn) do begin
            WriteLn(Format('%x  %s %s', [addr, insn.mnemonic, insn.op_str]));
          end;
        end else begin
          WriteLn('ERROR!');
        end;
      finally
        disasm.Free;
      end;
    end;

## Compiling

The Capstone DLL is *early bound*, so make sure it is in the applications 
search path when you run it. On Windows this is preferably in the same directory 
of the executeable. On Linux just compile and install the Capstone library.

Lazarus
: To compile the Test program, open the file `test.lpi` in [Lazarus](http://www.lazarus-ide.org/) and click Start -> Compile.

Delphi
: Open `test.dpr` or `test.dproj` in Delphi and click Compile.

## Screenshot

![Capstone](http://0x2a.wtf/content/projects/capstone.png "Capstone test program output")

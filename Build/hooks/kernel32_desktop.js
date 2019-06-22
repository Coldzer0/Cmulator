'use strict';

var GetTapePosition = new ApiHook();
/*
DWORD GetTapePosition(
  HANDLE  hDevice,
  DWORD   dwPositionType,
  LPDWORD lpdwPartition,
  LPDWORD lpdwOffsetLow,
  LPDWORD lpdwOffsetHigh
);
*/
GetTapePosition.OnCallBack = function (Emu, API, ret) {

	Emu.pop();// return addr

	var hDevice = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwPositionType = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.pop();
	var lpdwPartition = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
	var lpdwOffsetLow = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.pop();
	// 32 Shadow for x64 as MS describe it :D
	var lpdwOffsetHigh = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop(); 

	// warn --> was testing on emotet sample :D 
	warn("GetTapePosition('0x{0}')".format(hDevice));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 6);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
GetTapePosition.install('kernel32.dll', 'GetTapePosition');

/*
###################################################################################################
###################################################################################################
*/




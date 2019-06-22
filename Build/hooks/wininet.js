'use strict';

var InternetGetConnectedState = new ApiHook();
/*
BOOLAPI InternetGetConnectedState(
  LPDWORD lpdwFlags,
  DWORD   dwReserved
);
*/
InternetGetConnectedState.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..
	
	var lpdwFlags   = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
	var dwReserved	= Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();

	log("InternetGetConnectedState(0x{0}, 0x{1})".format(
		lpdwFlags.toString(16),
		dwReserved.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // true if you handle it / false if you want Emu to handle it and set PC to (pop ret) .
};

InternetGetConnectedState.install('wininet.dll', 'InternetGetConnectedState');

/*
###################################################################################################
###################################################################################################
*/
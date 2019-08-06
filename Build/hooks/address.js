var addr_hook_example = new ApiHook();
addr_hook_example.OnCallBack = function () {

	info('EDI = ',Emu.ReadReg(REG_EDI).toString(16))
	info('ESI = ',Emu.ReadReg(REG_ESI).toString(16))
	info('Module : ',Emu.ReadStringA(Emu.ReadReg(REG_EAX)))

    return true;
};

addr_hook_example.install(0x401369);

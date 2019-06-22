

// _wcmdln fix

// var Path = '"C:\\pla\\' + Emu.Filename + '"'; // :D 
// var _wcmdln_ptr = Emu.GetProcAddr(Emu.GetModuleHandle('msvcr90.dll'), '_wcmdln');
// var po = 
// Emu.WriteStringW(_wcmdln_ptr,Path) : Emu.WriteStringA(_wcmdln_ptr,Path);




// var tmpx = new ApiHook();
// tmpx.OnCallBack = function () {


// 	info('EDI = ',Emu.ReadReg(REG_EDI).toString(16))
// 	info('ESI = ',Emu.ReadReg(REG_ESI).toString(16))
// 	info('Module : ',Emu.ReadStringA(Emu.ReadReg(REG_EAX)))

//     return true;
// };

// tmpx.install(0x401369);

// var tmpx = new ApiHook();
// tmpx.OnCallBack = function () {

// 	info('esi = ',Emu.ReadReg(REG_ESI).toString(16))
// 	info('ecx = ',Emu.ReadReg(REG_ECX).toString(16))

// 	info('Module : ',Emu.ReadStringW(Emu.ReadReg(REG_ESI)))

//     return true;
// };

// tmpx.install(0x401037);


// var tmpz = new ApiHook();
// tmpz.OnCallBack = function () {

// 	info('esi = ',Emu.ReadReg(REG_ESI).toString(16))

// 	info('API : ',Emu.ReadStringA(Emu.ReadReg(REG_ESI)))

//     return true;
// };

// tmpz.install(0x401068);


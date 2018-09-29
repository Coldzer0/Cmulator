'use strict';

var URLDownloadToFile = new ApiHook();
/*
HRESULT URLDownloadToFile(
  LPUNKNOWN pCaller,
  LPCTSTR szURL,
  LPCTSTR szFileName,
  DWORD dwReserved,
  LPBINDSTATUSCALLBACK lpfnCB
);
*/
URLDownloadToFile.OnCallBack = function (Emu, API, ret) {
    
    Emu.pop(); // PC

    var pCaller    = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();
    var url        = Emu.isx64 ? Emu.ReadReg(REG_RDX) : Emu.pop();
    var filename   = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.pop();
    var dwReserved = Emu.isx64 ? Emu.ReadReg(REG_R9D) : Emu.pop();
    // 32 Shadow space for x64 as MS describe it :V
    // not we are at the 5th param .
    var lpfnCB    = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.pop();     

    var msg = "0x{0} : {1}(0, '{2}', '{3}', {4}, {5})".format(
      ret.toString(16),
      API.name,
      API.IsWapi ? Emu.ReadStringW(url) : Emu.ReadStringA(url),
      API.IsWapi ? Emu.ReadStringW(filename) : Emu.ReadStringA(filename),
      dwReserved,
      lpfnCB
    );

    warn(msg);

    Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0); // return 0 << from MS docs. 
    Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
    return true; // true if you handle it false if you want Emu to handle it and set PC .
};
URLDownloadToFile.install('urlmon.dll', 'URLDownloadToFileA');
URLDownloadToFile.install('urlmon.dll', 'URLDownloadToFileW');

/*
###################################################################################################
###################################################################################################
*/

// @ts-check
/// <reference path="./ApiHook.d.ts"/>
/// <reference path="./const.js" />
/// <reference path="./API.d.ts"/>

'use strict';

//TODO : add mem manager .

var next = 0x40000000; // pla + 0x50000.
var malloc = new ApiHook();
/*
	void *malloc(  
	   size_t size   
	); 
*/
malloc.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var size = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP));

	print('malloc({0}) = 0x{1}'.format(
		size,
		next.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, next); // just for now :P .
	// if (size <= 0x48){
	// 	size = 0x60;
	// }
	// next += size;
	next = ((next + size) + 0x60 - 1) &~ (0x60 - 1); // align it .
	

	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true; // we handled the Stack and other things :D .
};
malloc.install('msvcrt.dll', 'malloc');
malloc.install('msvcr90.dll', 'malloc');

/*
###################################################################################################
###################################################################################################
*/

var free = new ApiHook();
/*
void free(   
   void *memblock   
);
*/
free.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var memblock = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP));

	print('free({0})'.format(
		memblock.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
free.install('msvcrt.dll', 'free');
free.install('msvcr90.dll', 'free');


/*
###################################################################################################
###################################################################################################
*/

var _vsnprintf = new ApiHook();
_vsnprintf.OnCallBack = function (Emu, API, ret) {

	_vsnprintf.args[0] = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + 4);

	// i think implementing this in JS is hard 
	// so just let the library handle it :D 
	return true;
};

_vsnprintf.OnExit = function(Emu,API){

	var buffer = _vsnprintf.args[0];

	warn("OnExit : _vsnprintf() = '{0}' ".format(
		Emu.ReadStringA(buffer)
	));
}

_vsnprintf.install('msvcrt.dll', '_vsnprintf');

/*
###################################################################################################
###################################################################################################
*/


var _vsnprintf_l = new ApiHook();

_vsnprintf_l.OnCallBack = function (Emu, API, ret) {

	return true;
};
_vsnprintf_l.install('msvcrt.dll', '_vsnprintf_l');


/*
###################################################################################################
###################################################################################################
*/

var _isleadbyte_l = new ApiHook();

_isleadbyte_l.OnCallBack = function (Emu, API, ret) {

	return true;
};
_isleadbyte_l.install('msvcrt.dll', '_isleadbyte_l');

/*
###################################################################################################
###################################################################################################
*/

var wctomb_s = new ApiHook();
wctomb_s.OnCallBack = function (Emu, API, ret) {

	// i think implementing this in JS is a bit hard so
	// just let the library handle it :D 
	return true;
};
wctomb_s.install('msvcrt.dll', 'wctomb_s');


/*
###################################################################################################
###################################################################################################
*/

var _wctomb_s_l = new ApiHook();
_wctomb_s_l.OnCallBack = function (Emu, API, ret) {

	// i think implementing this in JS is a bit hard so
	// just let the library handle it :D 
	return true;
};
_wctomb_s_l.install('msvcrt.dll', '_wctomb_s_l');


/*
###################################################################################################
###################################################################################################
*/

var _lock = new ApiHook();
/*
void __cdecl _lock  
   int locknum  
);
*/
_lock.OnCallBack = function (Emu, API, ret) {

	// Emu.pop(); // pop return address ..

	// var locknum = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP));

	// print('_lock({0})'.format(
	// 	locknum
	// ));

	// Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 100);
	// Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);

	// just let the library handle it :D
	return true;
};
_lock.install('msvcrt.dll', '_lock');


/*
###################################################################################################
###################################################################################################
*/

var _unlock = new ApiHook();
/*
void __cdecl _unlock(  
   int locknum  
); 
*/
_unlock.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..

	var locknum = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP));

	print('_unlock({0})'.format(
		locknum
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 100);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
_unlock.install('msvcrt.dll', '_unlock');


/*
###################################################################################################
###################################################################################################
*/

var getenv = new ApiHook();
/*
char *getenv(   
   const char *varname   
);
*/
getenv.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..


	var appdata = [0x43,0x3A,0x5C,0x55,0x73,0x65,0x72,0x73,0x5C,0x43,0x6F,0x6C,0x64,0x7A,0x65,0x72,0x30,0x5C,0x41,0x70,0x70,0x44,0x61,0x74,0x61,0x5C,0x52,0x6F,0x61,0x6D,0x69,0x6E,0x67,0x00];

	var varname = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP));
	var result  = Emu.ReadStringA(varname);

	var addr = (0x40000000 + 0x70000);

	if ( result == 'APPDATA') {
		print('plaa');
		Emu.WriteMem(addr,appdata);
	}

	print("0x{0} : getenv('{1}')".format(
		ret.toString(16),
		result
	));


	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, addr);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
getenv.install('msvcrt.dll', 'getenv');


/*
###################################################################################################
###################################################################################################
*/

var _beginthreadex = new ApiHook();
/*
uintptr_t _beginthreadex( // NATIVE CODE  
   void *security,  
   unsigned stack_size,  
   unsigned ( __stdcall *start_address )( void * ),  
   void *arglist,  
   unsigned initflag,  
   unsigned *thrdaddr   
); 
*/
_beginthreadex.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..


	var security      = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 0) );
	var stack_size	  = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 1) );
	var start_address = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 2) );
	var arglist	   	  = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 3) );
	// 32 Shadow for x64 as MS describe it :D
	// not we are at the 5th param .
	var initflag  	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 4)); 
	var thrdaddr	  = Emu.isx64 ? (Emu.ReadReg(REG_RSP) + 32 + 8) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 5)); 


	warn("0x{0} : _beginthreadex({1}, {2}, start_address = 0x{3}, 0x{4}, {5}, 0x{6}) - TODO: Implement Threading <<".format(
		ret.toString(16),
		security,
		stack_size,
		start_address.toString(16),
		arglist.toString(16),
		initflag,
		thrdaddr.toString(16)
	));

	Emu.WriteDword(thrdaddr,111); // threadID :V  

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1009);// Thread Handle :D 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
_beginthreadex.install('msvcrt.dll', '_beginthreadex');


/*
###################################################################################################
###################################################################################################
*/
 
var fopen = new ApiHook();
/*
FILE *fopen(   
   const char *filename,  
   const char *mode   
);
*/
fopen.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..


	var filename      = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 0) );
	var mode	  	  = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 1) );

	info("0x{0} : fopen('{1}', '{2}')".format(
		ret.toString(16),
		Emu.ReadStringA(filename),
		Emu.ReadStringA(mode)
	));

	var addr = (0x40000000 + 0x71000);

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, addr);// File Handle :D 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
fopen.install('msvcrt.dll', 'fopen');


/*
###################################################################################################
###################################################################################################
*/

var fread = new ApiHook();
/*
size_t fread(   
   void *buffer,  
   size_t size,  
   size_t count,  
   FILE *stream   
);
*/
fread.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..


	var buffer = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 0) );
	var size   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 1) );
	var count  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 2) );
	var stream = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 3) );

	log("0x{0} : fread({1}, {2}, 0x{3}, 0x{4})".format(
		ret.toString(16),
		buffer.toString(16),
		size,
		count,
		stream.toString(16)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);// TODO: handle it .
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
fread.install('msvcrt.dll', 'fread');


/*
###################################################################################################
###################################################################################################
*/

var fsetpos = new ApiHook();
/*
int fsetpos(   
   FILE *stream,  
   const fpos_t *pos   
);
*/
fsetpos.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..


	var stream = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 0) );
	var pos    = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 1) );

	log("0x{0} : fsetpos(0x{1}, {2})".format(
		ret.toString(16),
		stream.toString(16),
		Emu.ReadDword(pos)
	));

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 1009);// Thread Handle :D 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
fsetpos.install('msvcrt.dll', 'fsetpos');


/*
###################################################################################################
###################################################################################################
*/
  
var fwrite = new ApiHook();
/*
size_t fwrite(  
   const void *buffer,  
   size_t size,  
   size_t count,  
   FILE *stream   
);
*/
fwrite.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..


	var buffer = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 0) );
	var size   = Emu.isx64 ? Emu.ReadReg(REG_EDX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 1) );
	var count  = Emu.isx64 ? Emu.ReadReg(REG_R8)  : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 2) );
	var stream = Emu.isx64 ? Emu.ReadReg(REG_R9)  : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 3) );

	warn('==============================================================================');
	log("0x{0} : fwrite({1}, {2}, 0x{3}, 0x{4})".format(
		ret.toString(16),
		buffer.toString(16),
		size,
		count,
		stream.toString(16)
	));

	Emu.HexDump(buffer,count);

	warn('==============================================================================');

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, count);// Thread Handle :D 
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
fwrite.install('msvcrt.dll', 'fwrite');

/*
###################################################################################################
###################################################################################################
*/

var fclose = new ApiHook();
/*
int fclose(   
   FILE *stream   
);
*/
fclose.OnCallBack = function (Emu, API, ret) {

	Emu.pop(); // pop return address ..


	var stream = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + (4 * 0));

	log("0x{0} : fclose(0x{1}) ".format(
		ret.toString(16),
		stream.toString(16)
	));


	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};

fclose.install('msvcrt.dll', 'fclose');

/*
###################################################################################################
###################################################################################################
*/

var _get_osplatform = new ApiHook();
_get_osplatform.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
_get_osplatform.install('msvcrt.dll', '_get_osplatform');

/*
###################################################################################################
###################################################################################################
*/

var _get_winmajor = new ApiHook();
_get_winmajor.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
_get_winmajor.install('msvcrt.dll', '_get_winmajor');

/*
###################################################################################################
###################################################################################################
*/

var _CrtDbgBreak = new ApiHook();
_CrtDbgBreak.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
_CrtDbgBreak.install('msvcrt.dll', '_CrtDbgBreak');

/*
###################################################################################################
###################################################################################################
*/

var _setmbcp = new ApiHook();
_setmbcp.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
_setmbcp.install('msvcrt.dll', '_setmbcp');

/*
###################################################################################################
###################################################################################################
*/

var _freea = new ApiHook();
_freea.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
_freea.install('msvcrt.dll', '_freea');

/*
###################################################################################################
###################################################################################################
*/

var __crtLCMapStringA = new ApiHook();
__crtLCMapStringA.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
__crtLCMapStringA.install('msvcrt.dll', '__crtLCMapStringA');

/*
###################################################################################################
###################################################################################################
*/

var _initterm = new ApiHook();
_initterm.OnCallBack = function (Emu, API, ret) {
	
	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
_initterm.install('msvcrt.dll', '_initterm');
_initterm.install('msvcr90.dll', '_initterm');
_initterm.install('ucrtbase.dll', '_initterm');
_initterm.install('ucrtbase.dll', '_get_initial_narrow_environment');
/*
###################################################################################################
###################################################################################################
*/
var _initterm_e = new ApiHook();
_initterm_e.OnCallBack = function (Emu, API, ret) {

	Emu.SetReg(Emu.isx64 ? REG_RAX : REG_EAX, 0);
	Emu.SetReg(Emu.isx64 ? REG_RIP : REG_EIP, ret);
	return true;
};
_initterm_e.install('msvcrt.dll', '_initterm_e');
_initterm_e.install('msvcr90.dll', '_initterm_e');
_initterm_e.install('ucrtbase.dll', '_initterm_e');
/*
###################################################################################################
###################################################################################################
*/

var __dllonexit = new ApiHook();
__dllonexit.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
__dllonexit.install('msvcrt.dll', '__dllonexit');

/*
###################################################################################################
###################################################################################################
*/

var _msize = new ApiHook();
_msize.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
_msize.install('msvcrt.dll', '_msize');

/*
###################################################################################################
###################################################################################################
*/

var strcpy_s = new ApiHook();
strcpy_s.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
strcpy_s.install('msvcrt.dll', 'strcpy_s');

/*
###################################################################################################
###################################################################################################
*/

var wcscat_s = new ApiHook();
wcscat_s.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
wcscat_s.install('msvcrt.dll', 'wcscat_s');

/*
###################################################################################################
###################################################################################################
*/

var swprintf_s = new ApiHook();
swprintf_s.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
swprintf_s.install('msvcrt.dll', 'swprintf_s');

/*
###################################################################################################
###################################################################################################
*/

var vswprintf_s = new ApiHook();
vswprintf_s.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};
vswprintf_s.install('msvcrt.dll', 'vswprintf_s');

/*
###################################################################################################
###################################################################################################
*/

var Generic = new ApiHook();
Generic.OnCallBack = function (Emu, API, ret) {

	// just let the library handle it :D 
	return true;
};

// Generic.install('kernel32.dll', '_lcreat');
// Generic.install('kernel32.dll', '_hwrite');
// Generic.install('kernel32.dll', '_lclose');


Generic.install('msvcrt.dll', '__set_app_type');
Generic.install('msvcrt.dll', '_mbtowc_l');
Generic.install('msvcrt.dll', 'mbtowc');
Generic.install('msvcrt.dll', '_woutput_s');
Generic.install('msvcrt.dll', '__p__commode');
Generic.install('msvcrt.dll', '_controlfp');

Generic.install('msvcrt.dll', '__getmainargs');

Generic.install('msvcrt.dll', '__p__fmode');

Generic.install('msvcrt.dll', '_ismbblead');
Generic.install('msvcrt.dll', '_cexit');

Generic.install('msvcrt.dll', 'strrchr');

Generic.install('msvcrt.dll', 'strstr');

Generic.install('msvcrt.dll', 'strncpy');

Generic.install('msvcrt.dll', 'strncat');

Generic.install('msvcrt.dll', '__p___initenv');


Generic.install('msvcr90.dll', '__set_app_type');


Generic.install('msvcr90.dll', '_controlfp_s');
Generic.install('msvcr90.dll', '__p__commode');
Generic.install('msvcr90.dll', '__p__fmode');
Generic.install('msvcr90.dll', '_except_handler4_common');

Generic.install('msvcr90.dll', '_unlock');
Generic.install('msvcr90.dll', '_lock');

Generic.install('msvcr90.dll', '__wgetmainargs');

Generic.install('msvcr90.dll', '_calloc_crt');

Generic.install('msvcr90.dll', '_malloc_crt');
Generic.install('msvcr90.dll', 'memcpy');
Generic.install('msvcr90.dll', 'wcslen');

Generic.install('msvcr90.dll', '__dllonexit');
Generic.install('msvcr90.dll', '_control87');
Generic.install('msvcr90.dll', '_onexit');
Generic.install('msvcr90.dll', '_msize');
Generic.install('msvcr90.dll', '_errno');

Generic.install('msvcr90.dll', '__set_flsgetvalue');
Generic.install('msvcr90.dll', '_invalid_parameter');


Generic.install('msvcr90.dll', '_initptd');
Generic.install('msvcr90.dll', '_encoded_null');
Generic.install('msvcrt.dll', '_except_handler4_common');


Generic.install('vcruntime140.dll', '__telemetry_main_invoke_trigger');
Generic.install('vcruntime140.dll', '_except_handler4_common');


Generic.install('ucrtbase.dll', '__p___argv');
Generic.install('ucrtbase.dll', '__p___argc');


Generic.install('ucrtbase.dll', '__report_gsfailure');

/*
###################################################################################################
###################################################################################################
*/





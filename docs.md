# Examples for hooking an API(s).
```js
var ExitProcess = new ApiHook();
ExitProcess.OnCallBack = function (API,ret) {

	Emu.pop();

	var ExitCode = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.pop();

	error("{0}(0x{1})".format(
		API.name,
		ExitCode.toString(16)
	));

	Emu.Stop();

	return true; // true if you handle it false if you want Cmulator to handle it and set PC .
};

ExitProcess.install('kernel32.dll', 'FatalExit');
ExitProcess.install('kernel32.dll', 'ExitProcess');
ExitProcess.install('ntdll.dll', 'RtlExitUserThread');
ExitProcess.install('ntdll.dll', 'RtlExitUserProcess');
ExitProcess.install('ucrtbase.dll', 'exit');
ExitProcess.install('ucrtbase.dll', '_Exit');
```
### A good use of args prop.
```js
var sprintf = new ApiHook();
/*
int WINAPIV wsprintf(
  LPSTR  ,
  LPCSTR ,
  ...    
);
*/
sprintf.OnCallBack = function ( API, ret) {

	sprintf.args[0] = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + 4);
	sprintf.args[1] = Emu.isx64 ? Emu.ReadReg(REG_RCX) : Emu.ReadDword(Emu.ReadReg(REG_ESP) + 8);

	Emu.HexDump(sprintf.args[0], 16);
	Emu.HexDump(sprintf.args[1], 16);

	// i think implementing this in JS is hard 
	// so just let the library handle it :D 
	return true; // we handled the Stack and other things :D .
};

sprintf.OnExit = function(API){

	var buffer = sprintf.args[0];
	var Format = sprintf.args[1];

	Emu.HexDump(buffer, 16);
	Emu.HexDump(Format, 16);

	warn("{0}(0x{1},'{2}') ".format(
		API.name,
		buffer,
		Format.toString(16)
	));
}

sprintf.install('user32.dll', 'wsprintfA');
sprintf.install('user32.dll', 'wsprintfW');

```

## ApiHook Class
```js
/**
 * 
 *
 * @class ApiHook
 */
declare class ApiHook{
		
	/**
	 * Creates an instance of ApiHook.
	 * @memberof ApiHook
	 */
	constructor();

	/**
	 *
	 * 
	 * @param {Api} API
	 * @param {number} ret
	 * @returns {boolean} boolean
	 * @memberof ApiHook
	 */
	public OnCallBack: (arg0: Api, ret: number) => boolean;


	/**
	 *
	 * 
	 * @param {string} LibraryName
	 * @param {string} ApiName
	 * @returns {boolean} boolean
	 * @memberof ApiHook
	 */
	public install(LibraryName: string, ApiName: string): boolean;
	/**
	 *
	 *
	 * @param {string} LibraryName
	 * @param {number} Ordinal
	 * @returns {boolean} boolean
	 * @memberof ApiHook
	 */
	public install(LibraryName: string, Ordinal : number): boolean;

}
```


```js
/**
 *
 *
 * @class Api
 */
declare class Api {

	/**
	 * Get the name of current API.
	 *
	 * @type {String}
	 * @memberof Api
	 */
	public name: String;

}
```

```js
/**
 *
 *
 * @interface Emu
 */
declare interface Emu {


	
	/**
	 * Is Current PE x64 .
	 *
	 * @type {boolean}
	 * @memberof Emu
	 */
	public isx64 : boolean;

	/**
	 * Read X86 Register
	 *
	 * @param {number} Register - REG_{RegName}
	 * @memberof Emu
	 */
	public ReadReg(Register : number) : number;

	
	/**
	 *
	 * Set Register Value .
	 *
	 * @param {number} Register
	 * @param {number} Value
	 * @returns {boolean}
	 * @memberof Emu
	 */
	public SetReg(Register : number, Value : number) : boolean;

	/**
	 * return the top of Stack 
	 * and Add 4 or 8 to Stack Pointer 
	 *
	 * @returns {number}
	 * @memberof Emu
	 */
	public pop() : number;

	/**
	 * Strop the Cmulator .
	 *
	 * @memberof Emu
	 */
	public Stop(); void;
}
```

/**
 *
 *
 * @interface EmuAPI
 */
declare interface EmuAPI {


	
	/**
	 * Is Current PE x64 .
	 *
	 * @type {boolean}
	 * @memberof EmuAPI
	 */
	public isx64 : boolean;

	/**
	 * Read X86 Register
	 *
	 * @param {number} Register - REG_{RegName}
	 * @memberof EmuAPI
	 */
	public ReadReg(Register : number) : number;

	
	/**
	 *
	 * Set Register Value .
	 *
	 * @param {number} Register
	 * @param {number} Value
	 * @returns {boolean}
	 * @memberof EmuAPI
	 */
	public SetReg(Register : number, Value : number) : boolean;

	/**
	 * return the top of Stack 
	 * and Add 4 or 8 to Stack Pointer 
	 *
	 * @returns {number}
	 * @memberof EmuAPI
	 */
	public pop() : number;

	/**
	 * Strop the Cmulator .
	 *
	 * @memberof EmuAPI
	 */
	public Stop(); void;
}

/**
 *
 *
 * @class ApiHook
 */
declare class ApiHook{
		
	/**
	 *Creates an instance of ApiHook.
	 * @memberof ApiHook
	 */
	constructor();


	/**
	 *
	 * 
	 * @param {EmuAPI} Emu
	 * @param {number} Address
	 * @returns {boolean}
	 * @memberof ApiHook
	 */
	public OnCallBack: (Emu: EmuAPI, Address: number) => boolean;


	/**
	 *
	 * 
	 * @param {string} LibraryName
	 * @param {string} ApiName
	 * @returns {boolean}
	 * @memberof ApiHook
	 */
	public install(LibraryName: string, ApiName: string): boolean;
	/**
	 *
	 *
	 * @param {string} LibraryName
	 * @param {number} Ordinal
	 * @returns {boolean}
	 * @memberof ApiHook
	 */
	public install(LibraryName: string, Ordinal : number): boolean;

}

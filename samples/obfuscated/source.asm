;
; Obfuscator v2.0 sample
;
; Bartosz Wójcik | www.pelock.com
;
	.586
	.model flat,stdcall

	includelib	\masm32\lib\kernel32.lib
	includelib	\masm32\lib\user32.lib

	include		\masm32\include\kernel32.inc
	include		\masm32\include\user32.inc
	include		\masm32\include\windows.inc

	assume		fs:flat

.data
	szCaption	db 'Visit us at www.pelock.com',0
	szText		db 'Hello world',0
.code


ShowInformation proc

;
; MessageBox(NULL, "Hello world", "Visit us at www.pelock.com", MB_ICONINFORMATION);
;
	push	MB_ICONINFORMATION
	push	offset szCaption
	push	offset szText
	push	0
	call	MessageBoxA

	ret

ShowInformation endp

start:
	call	ShowInformation

;
; ExitProcess(0);
;
	push	0
	call	ExitProcess

end start

		.386
		.model flat, stdcall
		option casemap: none
include 	windows.inc
include 	user32.inc
includelib 	user32.lib
include 	kernel32.inc
includelib 	kernel32.lib
IAT_OPCODE_LEN	equ 6
;JMPOPCODE		struct

;JMPOPCODE		ends
		.data
szCaption	db	'Hello',0
szText		db	'Hello World!',0
szNewText	db	'Bye world!',0
		
		.code
_HookFunc		proc
;_HookFunc::
		mov [esp+8],offset szNewText
		
_OrgJmp::
		db 90h,90h,90h,90h,90h,90h
_HookFunc		endp

_WriteMem		proc	_lpAddr,_dwSize,_lpbData ;lpAddr 叫 pvoidAddr比较好
		local @flOrgProtect
		local @flMyProtect
		invoke	VirtualProtect,_lpAddr,_dwSize,PAGE_EXECUTE_READWRITE,addr @flOrgProtect
		invoke	RtlMoveMemory,_lpAddr,_lpbData,_dwSize
		;mov ecx,_dwSize		;counter
		;mov esi,_lpbData	;pBuffer
		;mov edi,_lpAddr		;pWriter
		;rep movs byte ptr es:[edi],byte ptr ds:[esi]
		invoke	VirtualProtect,_lpAddr,_dwSize,@flOrgProtect,addr @flMyProtect
		ret
_WriteMem		endp

start			proc
		local	@lpdwJmpAddr
		local	@byOrgJmpAddr[6]:byte
		local	@byNewJmpAddr[6]:byte
		invoke	MessageBox,NULL,offset szText,offset szCaption,MB_OK

;********************************************************************
; 备份原重定位地址,加载新地址
;********************************************************************
		mov @lpdwJmpAddr, offset MessageBox
		
		invoke	RtlMoveMemory,addr @byOrgJmpAddr,offset MessageBox,IAT_OPCODE_LEN
		
		;mov esi,@lpdwJmpAddr
		;add esi,2
		;mov eax,[esi];eax is orginal jmp addr
		
		;mov bx,0ff25h
		;mov word ptr[@byOrgJmpAddr],bx
		
		;mov dword ptr[@byOrgJmpAddr+2],eax
		
		mov eax,offset _HookFunc
		mov ebx,offset MessageBox
		sub eax,ebx
		sub eax,5;eax is offset to hookfunc E9xxxxxxxx90
		mov byte ptr[@byNewJmpAddr],0e9h
		mov dword ptr[@byNewJmpAddr+1],eax
		mov byte ptr[@byNewJmpAddr+sizeof dword+1],90h
;********************************************************************
; 写新地址,测试
;********************************************************************
		invoke	_WriteMem,offset _OrgJmp,IAT_OPCODE_LEN,addr @byOrgJmpAddr
		mov edi,@lpdwJmpAddr
		invoke	_WriteMem,edi,sizeof @byNewJmpAddr,addr @byNewJmpAddr			;addr @lpdwJmpAddr传的是堆栈地址
		invoke	MessageBox,NULL,offset szText,offset szCaption,MB_OK

;********************************************************************
; 恢复源地址,测试
;********************************************************************
		mov edi,@lpdwJmpAddr
		invoke	_WriteMem,edi,sizeof @byOrgJmpAddr,addr @byOrgJmpAddr
		invoke	MessageBox,NULL,offset szText,offset szCaption,MB_OK
		invoke	ExitProcess,NULL
		ret
start 			endp
		end	start
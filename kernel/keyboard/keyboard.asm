%include "keyboard/keyboard.inc"
INCLUDE "vga/vga_driver.inc"
INCLUDE "apic/apic.inc"
%include "SD/system_desc.inc"

asciiNonShift db NULL, ESC, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', BACKSPACE,\
TAB, 'q', 'w',   'e', 'r', 't', 'z', 'u', 'i', 'o', 'p',   '[', ']', ENTER, 0,\
'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '`', 0, '\',\
'y', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' ', 0,\
KF1, KF2, KF3, KF4, KF5, KF6, KF7, KF8, KF9, KF10, 0, 0,\
KHOME, KUP, KPGUP,'-', KLEFT, '5', KRIGHT, '+', KEND, KDOWN, KPGDN, KINS, KDEL, 0, 0, 0, KF11, KF12


asciiShift db NULL, ESC, '!', '"', '3', '$', '%', '&', '/', '(', ')', '=', '?', '`', BACKSPACE,\
TAB, 'Q', 'W',   'E', 'R', 'T', 'Z', 'U', 'I', 'O', 'P',   '{', '}', ENTER, 0,\
'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', 0, '|',\
'Y', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, 0, 0, ' ', 0,\
KF1,   KF2, KF3, KF4, KF5, KF6, KF7, KF8, KF9, KF10, 0, 0,\
KHOME, KUP, KPGUP, '-', KLEFT, '5',   KRIGHT, '+', KEND, KDOWN, KPGDN, KINS, KDEL, 0, 0, 0, KF11, KF12


DeclareFunction KeyboardInstallIRQ()
	secure_call MapIOAPICEntryToIRQ( 1, 40 ) ;Use interrupt 40 for keyboard entrys
	secure_call SetIDTGate( 40, KeyboardTip, 3 )
EndFunction

align 16
KeyboardTip:
	CreateStack Umbrella
	push rax
	push rbx
	xor rbx, rbx

	in al, 0x60
	mov bl, al
	in al, 0x61
	or al, 0x80
	out 0x61, al
	and al, 0x7F
	out 0x61, al

	test bl, 0x80
	jz .try_rel

	and bl, 0x7F

	cmp bl, KRLEFT_SHIFT
	jz .untoogle_shift

	cmp bl, KRRIGHT_SHIFT
	jz .untoogle_shift
	jmp .end


	.try_rel:
		cmp bl, KRLEFT_SHIFT
		jz .toogle_shift

		cmp bl, KRRIGHT_SHIFT
		jz .toogle_shift

		xor rax, rax
		add rbx, qword[ CurrentScanCode ]
		mov al, byte[ rbx ]

		cmp al, 'R'
		jz ResetCPU
		secure_call DrawCharacter( rax )
	.end:	
	
	secure_call sendEOI()
	pop rbx
	pop rax
	DestroyStack Umbrella
	iretq

	.untoogle_shift:
		mov qword[ CurrentScanCode ], asciiNonShift
		jmp .end
	.toogle_shift:
		mov qword[ CurrentScanCode ], asciiShift
		jmp .end


ResetCPU:
	in al, 0x64
	test al, 2
	jnz ResetCPU

	mov al, 0xFE
	out 0x64, al
	jmp $


CurrentScanCode dq asciiNonShift

ImportAllMgrFunctions
section .bss
KeyboardBuffer resb 64

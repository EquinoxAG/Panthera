%include "Morgenroetev1.inc"
INCLUDE "vga/vga_driver.inc"

global GraphicDriverInterface
GraphicDriverInterface:
	.clearscreen dq ClearScreen
	.set_foreground_attr dq SetForegroundAttribute
	.set_background_attr dq SetBackgroundAttribute
	.draw_character dq DrawCharacter
	.draw_string dq DrawString

ClearScreen:
	mov edi, dword[ vga_driver.lfb_address ]
	mov ecx, dword[ vga_driver.phys_scr_size ]
	mov dword[ vga_driver.curr_write_addr ], edi
	shr ecx, 1

	mov al, 0x20
	mov ah, byte[ vga_driver.background_attr ]

	rep stosw
	ret

SetForegroundAttribute:
	mov ax, di
	and al, 0xF
	mov byte[ vga_driver.foreground_attr ], al
	ret

SetBackgroundAttribute:
	mov ax, di
	shl al, 4
	and al, 0xF0
	mov byte[ vga_driver.background_attr ], al
	ret

;edi = character
DrawCharacter:
	and di, 0x00FF
	sub rsp, 8
	mov word[ rsp ], di
	mov rdi, rsp
	call DrawString
	add rsp, 8
	ret


;edi = string address
DrawString:
	mov rsi, rdi
	mov ah, byte[ vga_driver.foreground_attr ]
	mov edi, dword[ vga_driver.curr_write_addr ]
	or ah, byte[ vga_driver.background_attr ]

	.draw:
		mov al, byte[ rsi ]
		add esi, 1

		or al, al
		jz .done

		cmp al, CONSOLE_CHANGE_FOREGROUND_CHAR
		jz .changeFG

		cmp al, CONSOLE_CHANGE_BACKGROUND_CHAR
		jz .chageBG

		cmp al, CONSOLE_LINEBREAK
		jz .linebreak

		mov word[ edi ], ax
		add edi, 2
		jmp .draw
	
	.changeFG:
		mov ah, byte[ rsi ]
		and ah, 0x0F
		mov byte[ vga_driver.foreground_attr ], ah
		or ah, byte[ vga_driver.background_attr ]
		add esi, 1
		jmp .draw
	
	.changeBG:
		mov ah, byte[ rsi ]
		shl ah, 4
		and ah, 0xF0
		mov byte[ vga_driver.background_attr ], ah
		or ah, byte[ vga_driver.foreground_attr ]
		add esi, 1
		jmp .draw

	.linebreak:
		push rax
		
		xor edx, edx
		mov eax, edi
		sub eax, dword[ vga_driver.lfb_address ]
		add edi, 160
		div dword[ vga_driver.bytes_per_scanline ]
		sub edi, edx

		pop rax
		jmp .draw		
		
	.done:
		ret
	

vga_driver:
	.foreground_attr db 0xF
	.background_attr db 0
	.lfb_address dd 0xb8000
	.curr_write_addr dd 0xb8000
	.phys_scr_size dd (80*25*2)
	.bytes_per_scanline dd 160

%include "Morgenroetev1.inc"
INCLUDE "string/string.inc"


;Setzt 
DeclareFunction KString::StrConstructor(buffer_ptr, buffer_size)
	mov_ts qword[ (Arg_this->KString).length ], 0
	mov_ts qword[ (Arg_this->KString).str_ptr ], Arg_buffer_ptr
	mov_ts qword[ (Arg_this->KString).max_strlen ], Arg_buffer_size
EndFunction

DeclareFunction KString1024::KStringConstStack()
	mov rax, Arg_this
	mov_ts qword[ (Arg_this->KString1024).length ], 0
	add rax, KString1024.buffer
	mov_ts qword[ (Arg_this->KString1024).max_strlen ], 1024
	mov_ts qword[ (Arg_this->KString1024).str_ptr ], rax
EndFunction

DeclareFunction KString::c_str()
	mov_ts rax, qword[ (Arg_this->KString).str_ptr ]
EndFunction

DeclareFunction KString::clear()
	mov_ts qword[ (Arg_this->KString).length ], 0
	mov_ts rdi, qword[ (Arg_this->KString).str_ptr ]
	mov byte[ rdi ], 0
EndFunction

;rdi = this
DeclareFunction KString::nline()
	mov_ts edx, dword[ (Arg_this->KString).length ]
	mov_ts rsi, qword[ (Arg_this->KString).str_ptr ]
	mov_ts ecx, dword[ (Arg_this->KString).max_strlen ]
	add rsi, rdx

	sub ecx, 1
	cmp ecx, edx
	jz .done

	mov byte[ rsi ], 0x0A	;New line
	mov byte[ rsi + 1 ], 0

	add edx, 1


	.done:
		mov_ts dword[ (Arg_this->KString).length ], edx
EndFunction

;rdi = this ptr, rsi = ival
DeclareFunction KString::append_int( ival )
	push rbx
	
	mov r8, Arg_this

	mov rax, Arg_ival

	mov rsi, rsp
	sub rsi, 1
	sub rsp, 40	;Make 40 bytes place
	mov rbx, 10

	xor edx, edx
	mov byte[ rsi ], 0
	sub rsi, 1

	.MakeStr:
		div rbx
		add dl, 48
		mov byte[ rsi ], dl
		sub rsi, 1
		xor edx, edx
		test rax, rax
		jnz .MakeStr

	add rsi, 1
	secure_call (r8->KString).append_str( rsi )
	add rsp, 40
	pop rbx
EndFunction

DeclareFunction KString::append_inth( ival )
	mov rax, Arg_ival
	mov r9, Arg_ival
	mov_ts rdx, qword[ (Arg_this->KString).max_strlen ]
	mov_ts r8, qword[ (Arg_this->KString).length ]
	mov_ts rsi, qword[ (Arg_this->KString).str_ptr ]

	add rsi, r8

	add r8, 1
	cmp r8d, edx
	jae .done

	mov byte[ rsi ], '0'
	
	add r8, 1
	cmp r8d, edx
	jae .done

	add rsi, 1
	mov byte[ rsi ], 'x'

	add r8, 1

	mov cl, 60

	.ParseString:
		cmp r8d, edx
		jae .done

		shr rax, cl

		add rsi, 1

		and al, 0x0F

		cmp al, 10
		jae .hex

		add al, 48
		jmp .contParse
	.hex:
		add al, 55
	.contParse:
		mov byte[ rsi ], al
	
		add r8, 1
		mov rax, r9
		sub cl, 4
		jns .ParseString
	.done:
		sub r8, 1
		add rsi, 1
		mov byte[ rsi ], 0
		mov_ts qword[ (rdi->KString).length ], r8
EndFunction

;rdi = this, rsi = app_str, 
DeclareFunction KString::append_str( app_str, length )
	push rbx
	mov rcx, Arg_length
	mov_ts rax, qword[ (rdi->KString).str_ptr ]
	mov_ts r8d, dword[ (rdi->KString).length ]
	mov_ts edx, dword[ (rdi->KString).max_strlen ]
	add rax, r8
	sub edx, 1

	.copy_str:
		mov bl, byte[ rsi ]
		mov byte[ rax ], bl

		test bl, bl
		jz .done

		add r8, 1
		cmp r8d, edx
		jz .done
		
		add rsi, 1
		add rax, 1
		sub ecx, 1
		jnz .copy_str
	.done:
		mov byte[ rax ], 0
		mov_ts dword[ (rdi->KString).length ], r8d
		pop rbx
EndFunction

DeclareFunction KString::str_cmp( other_str )
	
	mov_ts rdi, qword[ (rdi->KString).str_ptr ]

	xor rax, rax
	.start_cmp:
		mov al, byte[ rdi ]
		cmp al, byte[ rsi ]
		jnz .unequal

		add rdi, 1
		add rsi, 1

		test al, al
		jnz .start_cmp
		jmp .done

	.unequal:
		mov al, 0xFF
		stc
	.done:
EndFunction

;rdi = this, rsi = app_str because calling convention will be converted to STDCALL_GCC64 
DeclareFunction KString::append_str( app_str )
	mov_ts rax, qword[ (rdi->KString).str_ptr ]
	mov_ts r8d, dword[ (rdi->KString).length ]
	mov_ts ecx, dword[ (rdi->KString).max_strlen ]
	add rax, r8
	sub ecx, 1


	.copy_str:
		mov dl, byte[ rsi ]
		mov byte[ rax ], dl


		test dl, dl
		jz .done
		
		add r8, 1
		cmp r8d, ecx
		jz .done

		add rsi, 1
		add rax, 1
		jmp .copy_str


	.done:
		mov byte[ rax ], 0
		mov_ts dword[ (rdi->KString).length ], r8d
EndFunction

DeclareFunction KString::append_double( value, precision )
	mov rcx, rsi
	shr rcx, 52
	xor rax, rax
	and ecx, 0x7FF
	bts rax, rcx

	push rdi
	secure_call (rdi->KString).append_int(rax)
	pop rdi

EndFunction

ImportAllMgrFunctions

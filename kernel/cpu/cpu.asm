%include "cpu/cpu.inc"
%include "SD/system_desc.inc"
%include "heap/heap.inc"

DeclareFunction InitialiseCPU()
	mov eax, gs
	cmp ax, 0x28
	jns .end

	secure_call malloc( CPUInfo_size, "Local cpu info structure" )
	secure_call CreateNewSegment( rax, 0, GDT_TYPE_READWRITE )
	mov gs, eax

	.gather_info:
		mov rax, CPUInfoSignature
		mov qword[ gs:CPUInfo.signature ], rax

		mov ecx, 0x1B
		rdmsr
		bts eax, 11
		wrmsr

		and eax, 0xFFFFF000
		mov qword[ gs:CPUInfo.apic_addr ], rax

		mov eax, 0x80000001	;Check if the Not executable bit is valid
		cpuid
		test edx, (1<<20)	;Is nxe-bit supported?
		jz .no_nxe

		mov ecx, 0xC0000080	;Hardware enable the nxe bit
		rdmsr
		or eax, (1<<11)
		wrmsr

		mov rax,  0xFFFFFFFFFFFFFFFF

		mov qword[ gs:CPUInfo.nxe_bit_mask ], rax
		jmp .continue

	.no_nxe:
		mov rax,  0x7FFFFFFFFFFFFFFF
		mov qword[ gs:CPUInfo.nxe_bit_mask ], rax
	
	.continue:

	.end:
EndFunction


ImportAllMgrFunctions

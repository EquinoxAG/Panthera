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
		mov ecx, 0x1B
		rdmsr
		and eax, 0xFFFFF000
		mov qword[ gs:CPUInfo.apic_addr ], rax


	.end:
EndFunction


ImportAllMgrFunctions

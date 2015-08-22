%include "memory/virtual_memory.inc"

DeclareFunction InitialiseVirtualMemoryManager( bootup_pml4 )
	ReserveStackSpace OperatedPML4, qword
	UpdateStackPtr

	mov_ts qword[ OperatedPML4 ], Arg_bootup_pml4


EndFunction

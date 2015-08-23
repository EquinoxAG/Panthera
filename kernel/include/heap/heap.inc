%ifndef _KRNEL_HEAP_INC_
%define _KRNEL_HEAP_INC_
%include "Morgenroetev1.inc"

DefineFunction InitialiseHeap, 1
DefineFunction malloc, 2
DefineFunction malloc, 3
DefineFunction free,1
DefineFunction PrintMemoryMap, 0
DefineFunction PrintFreeMap, 0

interface_open HeapInfoBlock
	add size, dword
	add alloc_reason, dword
	add next, dword
interface_close

interface_open HeapInfoBlockReserved
	add size, dword
	add alloc_reason, dword
	add last_ptr, dword
interface_close 

%define BLOCK_FREE 0
%define BLOCK_UPDATE 1
%define BLOCK_ON_MERGE 2
%define BLOCK_RESERVED 0x100
%define BLOCK_ON_MERGE_DESTRUCTIVE 0x101

%define BLOCK_USERDEFINED 0x1000

%endif

;Virtual memory manager MASTER file
;Reserves and maps the virtual addresses to the physcial addresses, keeps track of unused virtual address spacce
;Must be thread safe to ensure that multiple cpus/cores can simultanesly acces the vmm


%ifndef _VIRTUAL_MEMORY_INC_
%define _VIRTUAL_MEMORY_INC_

%include "Morgenroetev1.inc"

DefineFunction InitialiseVirtualMemoryManager, 1

interface_open UnusedPageLayoutRange
interface_close



%endif

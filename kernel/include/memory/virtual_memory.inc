;Virtual memory manager MASTER file
;Reserves and maps the virtual addresses to the physcial addresses, keeps track of unused virtual address spacce
;Must be thread safe to ensure that multiple cpus/cores can simultanesly acces the vmm


%ifndef _VIRTUAL_MEMORY_INC_
%define _VIRTUAL_MEMORY_INC_

%include "Morgenroetev1.inc"

DefineFunction InitialiseVirtualMemoryManager, 1

%define PAGE_READ 0
%define PAGE_READ_WRITE 2
%define PAGE_READ_WRITE_EXECUTE (PAGE_READ_WRITE|0x8000000000000000)
%define PAGE_USR_ACCESS 4


%define PAGE_CACHE_TYPE_WB (0<<3)
%define PAGE_CACHE_TYPE_WT (1<<3)
%define PAGE_CACHE_TYPE_UCWEAK (2<<3)
%define PAGE_CACHE_TYPE_UC (3<<3)
%define PAGE_CACHE_TYPE_WP (6<<3)
%define PAGE_CACHE_TYPE_WC (7<<3)




interface_open UnusedPageLayoutRange
interface_close



%endif

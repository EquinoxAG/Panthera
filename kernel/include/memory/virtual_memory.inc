;Virtual memory manager MASTER file
;Reserves and maps the virtual addresses to the physcial addresses, keeps track of unused virtual address spacce
;Must be thread safe to ensure that multiple cpus/cores can simultanesly acces the vmm


%ifndef _VIRTUAL_MEMORY_INC_
%define _VIRTUAL_MEMORY_INC_

%include "Morgenroetev1.inc"

DefineFunction InitialiseVirtualMemoryManager, 1

%define IA32_PAT_MSR 0x277

%define PAT_MEM_TYPE_UC 0
%define PAT_MEM_TYPE_WC 1
%define PAT_MEM_TYPE_WT 4
%define PAT_MEM_TYPE_WP 5
%define PAT_MEM_TYPE_WB 6
%define PAT_MEM_TYPE_UCWEAK 7


%define PAGE_CACHE_TYPE_WB 0
%define PAGE_CACHE_TYPE_WT 1
%define PAGE_CACHE_TYPE_UCWEAK 2
%define PAGE_CACHE_TYPE_UC 3
%define PAGE_CACHE_TYPE_WP 6
%define PAGE_CACHE_TYPE_WC 7




interface_open UnusedPageLayoutRange
interface_close



%endif

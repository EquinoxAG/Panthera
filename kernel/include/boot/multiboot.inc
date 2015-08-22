%include "Morgenroetev1.inc"
struc multiboot
	.flags resd 1
	.mem_lower resd 1
	.mem_upper resd 1
	.bootdevice resd 1
	.commandline resd 1
	.mod_count resd 1
	.mod_addr resd 1
	.sys resd 4
	.mmap_length resd 1
	.mmap_addr resd 1
	.drives_length resd 1
	.drives_addr resd 1
	.config_table resd 1
	.bootloader_name resd 1
	.apm_table resd 1
	.vbe_ctrl_info resd 1
	.vbe_mode_info resd 1
	.vbe_mode resw 1
	.vbe_interface_seg resw 1
	.vbe_interface_off resw 1
	.vbe_interface_len resw 1
endstruc

interface_open multibootSup
	add flags, dword
	add mem_lower, dword
	add mem_upper, dword
	add bootdevice, dword
	add commandline, dword
	add mod_count, dword
	add mod_addr, dword
	add sys_low, qword
	add sys_hi, qword
	add mmap_len, dword
	add mmap_addr, dword
	add drives_length, dword
	add drives_addr, dword
	add config_table, dword
	add bootloader_name, dword
	add apm_table, dword
	add vbe_ctrl_info, dword
	add vbe_mode_info, dword
	add vbe_mode, word
	add vbe_interface_seq, word
	add vbe_interface_off, word
	add vbe_interface_len, word 
interface_close

%define MultibootStrucAddr 0x500 ;Address at which the multiootstructure will be relocated to or written by the self written bootloader to
%define MemMapAddr 0x600 ;Relocates the MemMap to address 0x600 or if the bootloader from PerfOS is used create it at that address
%define BOOTUP_PML4_ADDR 0x400000 

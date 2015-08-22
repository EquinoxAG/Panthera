%define ELFMAGIC ('ELF'<<8)|0x7F

struc elf64header
	.imagic0 resb 1
	.imagicELF resb 3
	.iclass resb 1
	.idata resb 1
	.iversion resb 1
	.iosabi resb 1
	.iabiversion resb 1
	.padding resb 7

	.object_type resw 1
	.machine_type resw 1
	.version resd 1
	.entry_point resq 1
	.programmheader_offset resq 1
	.sectionheader_offset resq 1	
	.processor_flags resd 1
	.programmheader_size resw 1
	.programmheader_num resw 1
	.sectionheader_size resw 1
	.sectionheader_num resw 1
	.sectionnamestringtableindex resw 1
endstruc
	
struc programmheader
	.type resd 1
	.flags resd 1
	.offsetinfile resq 1
	.vaddr resq 1
	.paddr resq 1
	.sizeofsegmentinfile resq 1	
	.sizeofsegmentinmem resq 1	
	.alignment resq 1
endstruc 

	%define HeaderSize 56

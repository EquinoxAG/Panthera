%ifndef _CPU_INIT_
%define _CPU_INIT_

%include "Morgenroetev1.inc"
	
DefineFunction InitialiseCPU, 0

interface_open CPUInfo
	add apic_addr, qword
	add nxe_bit_mask, qword
interface_close

%endif

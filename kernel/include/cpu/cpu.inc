%ifndef _CPU_INIT_
%define _CPU_INIT_

%include "Morgenroetev1.inc"
	
DefineFunction InitialiseCPU, 0


%define CPUInfoSignature 'CPU SV2'

interface_open CPUInfo
	add signature, qword
	add apic_addr, qword
	add nxe_bit_mask, qword
interface_close

%endif

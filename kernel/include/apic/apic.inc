%ifndef _APIC_INC_
%define _APIC_INC_

%include "Morgenroetev1.inc"

DefineFunction SupplyACPIApicTable, 1
DefineFunction InitialiseAPIC, 0
DefineFunction sendEOI,0


%define PIC_MASTER_CMD 0x20
%define PIC_MASTER_DATA 0x21
%define PIC_SLAVE_CMD 0xA0
%define PIC_SLAVE_DATA 0xA1

interface_open APICRegisters
	add local_apic_id, 0x20, dword
	add local_apic_ver, 0x30, dword
	add task_priority, 0x80, dword
	add arbiration_priority, 0x90, dword
	add processor_priority, 0xA0, dword
	add eoi, 0xB0, dword
	add logical_destination, 0xD0, dword
	add destination_format, 0xE0, dword
	add spurious_interrupt_vector, 0xF0, dword
	add error_status, 0x280, dword
	add interrupt_command, 0x300, dword
	add interrupt_command_hi, 0x310, dword
	add lvt_timer, 0x320, dword
	add lvt_thermal_sensor, 0x330, dword
	add lvt_performance_monitoring, 0x340, dword
	add lvt_lint0, 0x350, dword
	add lvt_lint1, 0x360, dword
	add lvt_error, 0x370, dword
	add initial_count, 0x380, dword
	add current_count, 0x390, dword
	add divide_config, 0x3E0, dword
interface_close

interface_open IOAPICDesc
	add id, dword
	add base, dword
	add num_remapping_intr, dword
	add global_intr_source, dword
	add next_ptr, dword
interface_close

interface_open interrupt_gate64
	add offset_lo, word
	add segment_sel, word
	add interrupt_stack_table, byte
	add flags, byte
	add offset_mid, word
	add offet_hi, dword
	add padding, dword
interface_close

%define IOAPIC_REGSEL 0
%define IOAPIC_DATA 0x10

%define IOAPIC_REG_ID 0
%define IOAPIC_REG_VER 1
%define IOAPIC_REG 2
%define IOAPIC_REG_FIRST_ENTRY 0x10

DefineFunction MapIOAPICEntryToIRQ, 2

%define IDT_INTERRUPT_GATE64 0x0E
%define IDT_TRAP_GATE64 0x0F
%define IDT_CALL_GATE64 0x0C
%define IDT_DESC_PRESENT 0x80

%define APIC_LOCAL_INTERRUPT_MASKED 0x10000
%define APIC_LOCAL_SPURIOUS_ENABLE 0x100

%endif

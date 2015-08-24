%ifndef _ACPI_KERNEL_INC_
%define _ACPI_KERNEL_INC_

%include "Morgenroetev1.inc"

interface_open RootSystemDescriptionPointer
	add signature, qword
	add checksum, byte
	add oem_first, dword
	add oem_sec, word
	add revision, byte
	add rsdt_addr, dword
interface_close

interface_open RootSystemDescriptionPointer20
	DeriveInterface RootSystemDescriptionPointer
	add length, dword
	add xsdt_addr, qword
	add ext_check, byte
	add padd_0, word
	add padd_1, byte
interface_close

interface_open ACPISystemDescriptorTableHeader
	add signature, dword
	add length, dword
	add revision, byte
	add checksum, byte
	add oem_id0, dword
	add oem_id1, word
	add oem_table_id, qword
	add oem_rev, dword
	add creator_id, dword
	add creator_rev, dword
interface_close

interface_open eXtendedSDT
	DeriveInterface ACPISystemDescriptorTableHeader
	add ptr_start, qword
interface_close

interface_open rootSDT
	DeriveInterface ACPISystemDescriptorTableHeader
	add ptr_start, dword
interface_close

interface_open HPETDescriptionTable
	DeriveInterface ACPISystemDescriptorTableHeader
	add event_timer_block_rev, dword
	add base_addr, dword
	add base_addr_mid, qword
	add hpet_number, byte
	add minimum_clock_ticks, word
	add page_protection, byte
interface_close

interface_open MultipleApicDescTable
	DeriveInterface ACPISystemDescriptorTableHeader
	add local_apic_addr, dword
	add flags, dword
	;The flags following a variable length table which describes the system apic/io-apics
interface_close

interface_open MADTEntryHeader
	add type, byte
	add length, byte
interface_close

%define MADT_ProcessorEntryType 0
interface_open MADTEntryProcessor
	DeriveInterface MADTEntryHeader
	add acpi_proc_id, byte
	add apic_proc_id, byte
	add flags, dword
interface_close

%define MADT_IOApicEntryType 1
interface_open MADTEntryIOAPIC
	DeriveInterface MADTEntryHeader
	add ioapic_id, byte
	add reserved, byte
	add ioapic_addr, dword
	add global_system_intr_base, dword
interface_close

%define MADT_IntrSrcOverrideEntryType 2
interface_open MADTEntryIntrSrcOverride
	DeriveInterface MADTEntryHeader
	add bus_source, byte
	add irq_source, byte
	add global_system_intr, dword
	add flags, word
interface_close



DefineFunction InitialiseACPI, 0

%define RSDP_Signature 'RSD PTR '
%define XSDT_Signature 'XSDT'
%define RSDT_Signature 'RSDT'
%define MADT_Signature 'APIC'
%define HPET_Signature 'HPET'

%endif

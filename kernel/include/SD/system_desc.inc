%ifndef _SYSTEM_DESCRIPTORS_
%define _SYSTEM_DESCRIPTORS_

%include "Morgenroetev1.inc"

DefineFunction InitialiseSD, 0
DefineFunction SetIDTGate, 3
DefineFunction CreateNewSegment, 3  ;offset, dpl, opmode

%define IDT_INTERRUPT_GATE64 0x0E
%define IDT_TRAP_GATE64 0x0F
%define IDT_CALL_GATE64 0x0C
%define IDT_DESC_PRESENT 0x80

%define GDT_TYPE_READONLY 0
%define GDT_TYPE_READWRITE 2

%define GDT_TYPE_EXECUTE_ONLY 8
%define GDT_TYPE_EXECUTE_READ 0xA
%define GDT_PRESENT 0x80

%endif

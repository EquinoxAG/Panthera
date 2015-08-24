%ifndef _EXCEPTION_INC_
%define _EXCEPTION_INC_

%include "Morgenroetev1.inc"

;1 = adress to break to, 2 = function to call
DefineFunction SetDebugBreakpoint, 4
DefineFunction InitialiseExceptions, 0
DefineFunction UnsetBreakpoint, 1
DefineFunction DumpRegisters, 0

%define EXCP_GLOBAL_BREAKPOINT 2
%define EXCP_LOCAL_BREAKPOINT 1

%define EXCP_BREAKPOINT_INST 0
%define EXCP_BREAKPOINT_WRITE 1
%define EXCP_BREAKPOINT_IO 2
%define EXCP_BREAKPOINT_READ_WRITE 3

%define EXCP_BREAKPOINT_LEN1 0
%define EXCP_BREAKPOINT_LEN_INST 0
%define EXCP_BREAKPOINT_LEN2 1
%define EXCP_BREAKPOINT_LEN4 3
%define EXCP_BREAKPOINT_LEN8 2

%define EFLAGS_RESUME_FLAG (1<<16)


%endif

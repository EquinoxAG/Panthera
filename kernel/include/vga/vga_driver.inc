%ifndef _VGA_DRIVER_INC_
%define _VGA_DRIVER_INC_

%include "Morgenroetev1.inc"


%define COLOR_BLACK 0


ExportSymbolIfInFile 'vga_driver.asm',GraphicDriverInterface


%macro CallGraphicFunction 2
	call qword[ GraphicDriverInterface + %2 ]
%endmacro

interface_open IGraphicDriver
	add clearScreen, qword
	add set_foreground_attr, qword
	add set_background_attr, qword
	add draw_character, qword
	add draw_string, qword
interface_close

DefineFunction LoadVGADriver, 0
DefineFunction ClearScreen, 0, STDCALL_GCC64, CallGraphicFunction, IGraphicDriver.clearScreen
DefineFunction SetForegroundAttribute, 1, STDCALL_GCC64, CallGraphicFunction, IGraphicDriver.set_foreground_attr
DefineFunction SetBackgroundAttribute, 1, STDCALL_GCC64, CallGraphicFunction, IGraphicDriver.set_background_attr
DefineFunction DrawCharacter, 1, STDCALL_GCC64, CallGraphicFunction, IGraphicDriver.draw_character
DefineFunction DrawString, 1, STDCALL_GCC64, CallGraphicFunction, IGraphicDriver.draw_string


%define COLOR_BLACK 0
%define COLOR_BLUE 1
%define COLOR_GREEN 2
%define COLOR_CYAN 3
%define COLOR_RED 4
%define COLOR_MAGENTA 5
%define COLOR_BROWN 6
%define COLOR_BRIGHTGREY 7
%define COLOR_GREY 8
%define COLOR_BRIGHTBLUE 9
%define COLOR_BRIGHTGREEN 10
%define COLOR_BRIGHTCYAN 11
%define COLOR_BRIGHTRED 12
%define COLOR_BRIGHTMAGENTA 13
%define COLOR_YELLOW 14
%define COLOR_WHITE 15

%define CONSOLE_LINEBREAK 0x0A
%define CONSOLE_CHANGE_FOREGROUND_CHAR 0x0D
%define CONSOLE_CHANGE_BACKGROUND_CHAR 0x0F

%define CONSOLE_CHANGEFG(x) CONSOLE_CHANGE_FOREGROUND_CHAR,x
%define CONSOLE_CHANGEBG(x) CONSOLE_CHANGE_BACKGROUND_CHAR,x

%define VGA_AC_INDEX 0x3C0
%define VGA_AC_WRITE 0x3C0
%define VGA_AC_READ 0x3C1
%define VGA_MISC_WRITE 0x3C2
%define VGA_SEQ_INDEX 0x3C4
%define VGA_SEQ_DATA 0x3C5
%define VGA_DAC_READ_INDEX 0x3C7
%define VGA_DAC_WRITE_INDEX 0x3C8
%define VGA_DAC_DATA 0x3C9
%define VGA_MISC_READ 0x3CC
%define VGA_GC_INDEX 0x3CE
%define VGA_GC_DATA 0x3CF
%define VGA_CRTC_INDEX 0x3D4
%define VGA_CRTC_DATA 0x3D5
%define VGA_INSTAT_READ 0x3DA

%define VGA_NUM_SEQ_REGS 5
%define VGA_NUM_CRTC_REGS 25
%define VGA_NUM_GC_REGS 9
%define VGA_NUM_AC_REGS 21
%define VGA_NUM_REGS (1 + VGA_NUM_SEQ_REGS + VGA_NUM_CRTC_REGS + VGA_NUM_GC_REGS + VGA_NUM_AC_REGS)

%endif

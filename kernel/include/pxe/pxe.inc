%ifndef _PXE_MASTER_FILE_
%define _PXE_MASTER_FILE_

%include "Morgenroetev1.inc"

interface_open pxe_v1
	add signature, dword
	add signature2, word
	add version, word
	add length, byte
	add checksum, byte
	add RMEntry, dword
	add PMOffset, dword
interface_close

interface_open pxe_v2
	add signature, dword
	add length, byte
	add checksum, byte
	add rev, byte
 	add reserved, byte

	add UNDIROMID, dword
	add BCROMID, dword

	add RMEntry, dword
	add PMEntry, dword
interface_close


%define SIZED_128_size 128
interface_open tft_open
	add Status, word
	add Filename, SIZED_128
	add BufferSize, dword
	add BufferAddr, dword

	add ServerIP, dword
	add AgentIP, dword
	add MCastIP, dword

	add portcl, word
	add port, word
	add timeout, word
	add reopendelay, word
interface_close

interface_open tft_read
	add Status, word
	add PacketNumber, word
	add BufferSize, word
	add BufferOff, word
	add BufferSeg, word
interface_close

%endif

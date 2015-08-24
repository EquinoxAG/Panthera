all: link_all
	
boot/prekernel.asm:
	nasm -f elf64 -o ./bin/prekernel.elf ./boot/prekernel.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/kernel.asm:
	nasm -f elf64 -o ./bin/kernel.elf ./kernel/kernel.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
boot/mbr.asm:
	nasm -f bin -o ./bin/bootloader.bin ./boot/mbr.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
boot/netboot.asm:
	sudo nasm -f bin -o /srv/tftp/boot.bin ./boot/netboot.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/memory/vmemory.asm:
	nasm -f elf64 -o ./bin/virtual_memory.elf ./kernel/memory/vmemory.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/heap/heap.asm:
	nasm -f elf64 -o ./bin/heap.elf ./kernel/heap/heap.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/vga/vga_driver.asm:	
	nasm -f elf64 -o ./bin/vga_driver.elf ./kernel/vga/vga_driver.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/string/string.asm:	
	nasm -f elf64 -o ./bin/string.elf ./kernel/string/string.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/SystemDescriptors/system_desc.asm:	
	nasm -f elf64 -o ./bin/system_desc.elf ./kernel/SystemDescriptors/system_desc.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/exceptions/exception.asm:
	nasm -f elf64 -o ./bin/exception.elf ./kernel/exceptions/exception.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/cpu/cpu.asm:
	nasm -f elf64 -o ./bin/cpu.elf ./kernel/cpu/cpu.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/acpi/acpi.asm:
	nasm -f elf64 -o ./bin/acpi.elf ./kernel/acpi/acpi.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/apic/apic.asm:
	nasm -f elf64 -o ./bin/apic.elf ./kernel/apic/apic.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/
kernel/keyboard/keyboard.asm:	
	nasm -f elf64 -o ./bin/keyboard.elf ./kernel/keyboard/keyboard.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/

link_all: boot/prekernel.asm kernel/apic/apic.asm kernel/kernel.asm boot/mbr.asm kernel/memory/vmemory.asm kernel/heap/heap.asm kernel/memory/pmemory.asm kernel/vga/vga_driver.asm kernel/string/string.asm kernel/SystemDescriptors/system_desc.asm kernel/exceptions/exception.asm kernel/cpu/cpu.asm kernel/acpi/acpi.asm kernel/keyboard/keyboard.asm
	ld -z max-page-size=0x1000 -nostdlib -m elf_x86_64 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/prekernel.elf ./bin/kernel.elf ./bin/virtual_memory.elf ./bin/heap.elf ./bin/physical_memory.elf ./bin/vga_driver.elf ./bin/string.elf ./bin/system_desc.elf ./bin/exception.elf ./bin/cpu.elf ./bin/acpi.elf ./bin/apic.elf ./bin/keyboard.elf
	cat ./bin/kernel.bin >>./bin/bootloader.bin
	./appender ./bin/bootloader.bin ./bin/bootloader.bin

kernel/memory/pmemory.asm:
	nasm -f elf64 -o ./bin/physical_memory.elf ./kernel/memory/pmemory.asm -i ./kernel/include/ -i ./kernel/include/Morgenroete/

netboot: all boot/netboot.asm
	sudo cp ./bin/kernel.bin /srv/tftp/kernel.bin


run:
	qemu-system-x86_64 -hda ./bin/bootloader.bin -smp 4 -monitor stdio -m 256M
run_net:	
	qemu-system-x86_64 -bootp tftp://127.0.0.1//boot.bin -tftp /srv/tftp -smp 4 -monitor stdio -m 256M
update:
	cd kernel/include
	rm -rf ./Morgenroete
	git clone https://github.com/EquinoxAG/Morgenroete
	cd ..
	cd ..

.PHONY: kernel/SystemDescriptors/system_desc.asm boot/prekernel.asm boot/netboot.asm kernel/memory/vmemory.asm kernel/keyboard/keyboard.asm kernel/kernel.asm boot/mbr.asm kernel/vga/vga_driver.asm kernel/memory/pmemory.asm kernel/memory/vmemory.asm kernel/string/string.asm kernel/cpu/cpu.asm kernel/heap/heap.asm kernel/ata/ata_driver.asm kernel/acpi/acpi.asm kernel/apic/apic.asm kernel/exceptions/exception.asm kernel/hpet/hpet.asm link_all


clean:
	rm ./bin/prekernel.elf
	rm ./bin/kernel.elf
	rm ./bin/virtual_memory.elf
	rm ./bin/heap.elf
	rm ./bin/physical_memory.elf
	rm ./bin/vga_driver.elf
	rm ./bin/string.elf
	rm ./bin/system_desc.elf
	rm ./bin/exception.elf
	rm ./bin/cpu.elf
	rm ./bin/acpi.elf
	rm ./bin/apic.elf
	rm ./bin/keyboard.elf

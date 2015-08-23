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

link_all: boot/prekernel.asm kernel/kernel.asm boot/mbr.asm kernel/memory/vmemory.asm kernel/heap/heap.asm kernel/memory/pmemory.asm
	ld -z max-page-size=0x1000 -nostdlib -m elf_x86_64 -T ./kernel/link.ld -o ./bin/kernel.bin ./bin/prekernel.elf ./bin/kernel.elf ./bin/virtual_memory.elf ./bin/heap.elf ./bin/physical_memory.elf

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

.PHONY: boot/prekernel.asm boot/netboot.asm kernel/memory/vmemory.asm kernel/keyboard/keyboard.asm kernel/kernel.asm boot/mbr.asm kernel/graphics/vga_driver.asm kernel/memory/pmemory.asm kernel/memory/vmemory.asm kernel/string/string.asm kernel/heap/heap.asm kernel/ata/ata_driver.asm kernel/acpi/acpi.asm kernel/apic/apic.asm kernel/exception/exception.asm kernel/hpet/hpet.asm link_all


clean:
	rm ./bin/prekernel.elf
	rm ./bin/kernel.elf
<<<<<<< HEAD
	rm ./bin/virtual_memory.elf
	rm ./bin/heap.elf
=======
	rm ./bin/physical_memory.elf

>>>>>>> PhysMemManager

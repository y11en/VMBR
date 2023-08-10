# C COMPILER

C_COMPILER = gcc
C_FLAGS = -c -nostdlib -fno-builtin -nostdinc -fno-stack-protector -Wall -I./include -g

# LINKER

LINKER = ld
LINKER_FLAGS = -nostdlib --oformat elf64-x86-64 -n -Ttext 0x7c00

# ASM ASSEMBLER

ASM_ASSEMBLER = nasm
ASM_FLAGS = -f elf64 -w-all -g -F dwarf

# -------------------------------------------------------- #

ASM_MAIN_FILE := src/boot/boot.asm
ASM_MAINO_FILE := build/boot.o

C_FILES = $(shell find src/ -name '*.c')
ASM_FILES = $(shell find src/ -name '*.asm')
OBJ_FILES = $(addprefix build/, $(notdir $(C_FILES:.c=.o))) $(ASM_MAINO_FILE)

LINKER_SCRIPT := src/linker.ld
GRUB_CFG := src/boot/grub.cfg

default: run

.PHONY: default build run clean scr gdb

build: build/vmbr.iso

scr: build
	qemu-system-x86_64 -cdrom build/vmbr.iso -nographic --enable-kvm -serial mon:stdio

run: build
	qemu-system-x86_64 -cdrom build/vmbr.iso -serial stdio --enable-kvm -cpu host

gdb: build
	qemu-system-x86_64 -cdrom build/vmbr.iso -s -S --enable-kvm -serial stdio & gdb

clean:
	rm -rf build

build/%.o: src/*/*%.c
	mkdir -p build
	$(C_COMPILER) $(C_FLAGS) -o $@ $<

$(ASM_MAINO_FILE): $(ASM_FILES)
	$(ASM_ASSEMBLER) $(ASM_FLAGS) $(ASM_MAIN_FILE) -o $@ 

build/vmbr.so: $(OBJ_FILES) $(LINKER_SCRIPT)
	mkdir -p build
	$(LINKER) $(LINKER_FLAGS) -T $(LINKER_SCRIPT) $(OBJ_FILES) -o $@

build/vmbr.iso: build/vmbr.so $(GRUB_CFG)
	mkdir -p build/isofiles/boot/grub
	cp $(GRUB_CFG) build/isofiles/boot/grub
	cp build/vmbr.so build/isofiles/boot
	grub-mkrescue -o $@ build/isofiles

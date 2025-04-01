# Makefile para el juego de carreras

# Herramientas
NASM = nasm
QEMU = qemu-system-i386

# Archivos
BOOT = boot1
STAGE = stage
IMAGE = disk.img

# Reglas
all: run

# Compilar el bootloader
$(BOOT).bin: $(BOOT).asm
	$(NASM) -f bin $< -o $@

# Compilar el stage 2
$(STAGE).bin: $(STAGE).asm
	$(NASM) -f bin $< -o $@

# Crear la imagen de disco
$(IMAGE): $(BOOT).bin $(STAGE).bin
	cat $(BOOT).bin $(STAGE).bin > $(IMAGE)

# Compilar y ejecutar en QEMU
run: $(IMAGE)
	$(QEMU) -fda $(IMAGE) -boot a

# Limpiar archivos generados
clean:
	rm -f *.bin $(IMAGE)

.PHONY: all run clean
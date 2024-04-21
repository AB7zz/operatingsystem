ASM=nasm

SRC_DIR = src
BUILD_DIR = build


.PHONY: all floppy_image kernel bootloader clean always

#
# Floppy Image
#
floppy_image: $(BUILD_DIR)/main_floppy.img
$(BUILD_DIR)/main_floppy.img: bootloader kernel
	# Generate empty 1.44MB File
	# if(input source) /dev/zero is a special file that provides infinite stream of zeros
	# of(output file) will be main_floppy.img
	# bs (block size) is set to 512 bytes which is the standard sector size
	# count is set to 2880 because 2880*512 = 1.44MB which is the standard size of a 3.5-inch floppy disk
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	# Formats the empty file main_floppy.img as a FAT12 file system type
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img
	# Writes the bootloader.bin to main_floppy.img without truncating
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	# mcopy compies the kernel binary into the main_flooppy.img
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"




#
# Bootloader
#
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin




#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin


always:
	mkdir -p $(BUILD_DIR)


clean:
	rm -rf $(BUILD_DIR)

; BIOS boots OS at address 7C00
org 0x7C00

; start in 16-bit mode
bits 16


%define ENDL 0x0D, 0x0A

;
; FAT12 headers
;
jmp short start
nop

bdb_oem:			        db 'MSWIN4.1'		; 8 bytes
bdb_bytes_per_sector:		dw 512
bdb_sectors_per_clusters:	db 1
bdb_reserved_sectors: 		dw 1
bdb_fat_count: 				db 2
bdb_dir_entries_count:		dw 0E0h
bdb_total_sectors:			dw 2880				; 2880 * 512
bdb_media_descriptor_type: 	db 0F0h				; F0 = 3.5-inch floppy disk
bdb_sectors_per_fat:		dw 9
bdb_sectors_per_track: 		dw 18
bdb_heads: 					dw 2
bdb_hidden_sectors: 		dd 0
bdb_large_sector_count:		dd 0

ebr_drive_number:			db 0 					; 0x00 floppy, 0x80 hdd
							db 0 					; reserved
ebr_signature:				db 29h
ebr_volume_id:				db 12h, 34h, 56h, 78h	; serial number, value doesn't matter
ebr_volume_label: 			db 'OS'					; 11 bytes, padded with spaces
ebr_system_id:				db 'FAT12	'			; 8 bytes



;
; Code goes here
;


start:
	jmp main


;
; Prints a string to the screen
; Params:
; - ds:si points to a string
;
puts:
	; save registers we will modify
	push si
	push ax

.loop:
	lodsb					; loads next character in a string into AL register
	or al, al				; verify if next character is null. It also modifies the flags register. If result is zero, it sets flag as zero
	jz .done				; conditional jump. jumps to done if flag is zero

	mov ah, 0x0e
	mov bh, 0
	int 0x10

	jmp .loop
	
.done:
	pop ax
	pop si
	ret

main:
	; setup data segments
	mov ax, 0
	mov ds, ax				; can't write to ds/es directly, that's why I'm using an intermediatery register
	mov es, ax

	; setup stack
	; when a function is called, the address of the function is pushed to the stack;
	; when you return from a function, the processor will read the return address from the stack and jump to it
	mov ss, ax
	mov sp, 0x7C00			; stack grows downards, hence we are are pointing to the start of the OS, so that it doesn't overwrite the OS	


	; read something from floppy disk
	; BIOS should set DL to drive number
	mov [ebr_drive_number], dl
	mov ax, 1 					; LBA = 1, second sector from disk
	mov cl, 1 					; 1 sector to read
	mov bx, 0x7E00 				; data should be after the bootloader
	call disk_read


	mov si, msg_hello
	call puts
	
	hlt


;
; Error handlers
;
floppy_error:
	mov si, msg_read_failed
	call puts
	jmp wait_key_and_reboot
	hlt



wait_key_and_reboot:
	mov ah, 0
	int 16h						; wait for keypress
	jmp 0FFFh:0 				; jumps to beginning of BIOS, should reboot



.halt:
	cli 						; disable interrupts, this way we can't get out of halt state
	hlt

;
; Disk routines
;

;
; Converts an LBA to a CHS address
; Parameters:
;	- ax: LBA address
; Returns:
;	- cx [bits 0-5]: sector number
;	- cx [bits 6-15]: cylinder
;	- dh: head
;
lba_to_chs:
	xor dx, dx;								; dx = 0
	div word [bdb_sectors_per_track]		; ax = LBA / SectorsPerTrack
											; dx = LBA % SectorsPerTrack
	inc dx									; dx = (LBA % SectorsPerTrack + 1) = sector
	mov cx, dx								; cx = sector

	xor dx, dx;								; dx = 0
	div word [bdb_heads]					; ax = (LBA / SectorsPerTrack) / Heads = cylinder
											; dx = (LBA / SectorsPerTrack) % Heads = head
	mov dh, dl								; dh = head
	mov ch, al 								; ch = cylinder (lower 8 bits)
	shl ah, 6
	or cl, ah								; pur upper 2 bits of cylinder in CL

	pop ax
	mov dl, al
	pop ax
	ret



;
; Reads sectors from a disk
; Uses BIOS interrup 0x13
; Parameters:
; 	-ax: LBA address
;   -cl: number of sectosr to read (up to 128)
; 	-dl: drive number
;   -es:bx: memory address where to store read data

disk_read:
	; save all registers we will modify
	push ax
	push bx
	push cx
	push dx
	push di
	
	; saves current value of cx (sector) to the stack. This is done to preserver the cx value before the call to lba_to_cha
	push cx
	call lba_to_chs
	pop ax

	; moves 0x02 to ah register. Its the BIOS interrup service number for reading data from the disk 
	mov ah, 02h
	; Moves 3 to di register. Retry count 
	mov di, 3


.retry:
	pusha					; save all general-purpose register values
	stc						; sets the carry flags in the eflags register. Usually done to prepare the CPU for an operation that may modify the carry flag
	int 13h					; calls BIOS interrupt for disk operations like read or writing
	jnc .done               ; if carry flag is clear, it jumps to .done

	; read failed
	popa					; restores all general-purpose register values
	call disk_reset			; resets disk. Clears all errors, prepares disk for another attempt

	dec di 					; decrements the retry count
	test di, di 			; tests the di to check if its 0 or not
	jnz .retry              ; if di is not 0 then it retries again


.fail:
	jmp floppy_error


.done:
	popa

	; restore registers modified
	push ax
	push bx
	push cx
	push dx
	push di

	ret


;
; Resets disk controllers
; Paramteres:
;	dl: drive number
;
disk_reset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc floppy_error
	popa
	ret




msg_hello: db 'Hello world', ENDL, 0
msg_read_failed: db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h

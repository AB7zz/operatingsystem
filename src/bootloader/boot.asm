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

	mov si, msg_hello
	call puts
	
	hlt
.halt:
	jmp .halt

msg_hello: db 'Hello world', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h

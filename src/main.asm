; BIOS boots OS at address 7C00
org 0x7C00

; start in 16-bit mode
bits 16


%define ENDL 0x0D, 0x0A

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

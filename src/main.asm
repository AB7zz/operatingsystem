; BIOS boots OS at address 7C00
org 0x7C00

; start in 16-bit mode
bits 16

main:
	hlt
.halt:
	jmp .halt

times 510-($-$$) db 0
dw 0AA55h

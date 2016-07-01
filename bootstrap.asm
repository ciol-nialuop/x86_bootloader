BITS 16
[ORG 0x7C00]	; code that follows should be placed at offset 0x7C00

jmp start

; DATA
; ----------------------------------------------------------------------
bootdrive db 0
msg_start db 'Booting...', 13, 10, 0
msg_reset db 'Reseting drive...', 13, 10, 0
msg_a20 db 'Enable a20...', 13, 10, 0
msg_kernel db 'Loading Kernel (at 0x07E00)', 13, 10, 0
msg_gdt db 'Loading GDT... (at 0x00500)', 13, 10, 0
msg_pmode db 'Entering Protected Mode...', 13, 10, 0
; ----------------------------------------------------------------------

;GDT
; ----------------------------------------------------------------------
GDTR:
GDTsize DW GDT_END-GDT-1
GDTbase DD 0x500

GDT:
NULL_SEL         EQU $-GDT  ; null descriptor is required (64bit per entry)
      DD 0x0
      DD 0x0
CODESEL          EQU $-GDT  ; 4GB Flat Code at 0x0 with max 0xFFFFF limit
      DW     0xFFFF           ; Limit(2):0xFFFF
      DW     0x0              ; Base(3)
      DB     0x0              ; Base(2)
      DB     0x9A             ; Type: present,ring0,code,exec/read/accessed (10011000)
      DB     0xCF             ; Limit(1):0xF | Flags:4Kb inc,32bit (11001111)
      DB     0x0              ; Base(1)
DATASEL          EQU $-GDT  ; 4GB Flat Data at 0x0 with max 0xFFFFF limit
      DW     0xFFFF           ; Limit(2):0xFFFF
      DW     0x0              ; Base(3)
      DB     0x0              ; Base(2)
      DB     0x92             ; Type: present,ring0,data/stack,read/write (10010010)
      DB     0xCF             ; Limit(1):0xF | Flags:4Kb inc,32bit (11001111)
      DB     0x0              ; Base(1)
GDT_END:
; ----------------------------------------------------------------------

; FUNCTIONS
; ----------------------------------------------------------------------
print_char:
	mov ah, 0x0E	; teletype
	mov bh, 0x00	; Page no
	mov bl, 0x07	; text attribute: lightgrey font on black background
	int 0x10
	ret

print_string:
	nextc:
		mov al, [si]	; al = *si
		inc si		; si++
		cmp al, 0	; if al=0 call exit
		je exit
		call print_char
		jmp nextc
		exit: ret

error:
	hlt
	jmp error
; ----------------------------------------------------------------------

; START
; ----------------------------------------------------------------------
start:
	mov ax, cs	; Update the segment registers
	mov ds, ax	; set data segment
	mov es, ax	; set extra segment
	mov ss, ax	; set stack segment
	mov [bootdrive], dl	; retrieve bootdrive id
	mov si, msg_start
	call print_string

reset_drive:
	mov si, msg_reset
	call print_string
	mov ax,	0x00		; Select Reset Disk Drive BIOS Function
	mov dl, [bootdrive]	; Select the drive booted from
	int 13h				; Reset the drive
	jc error			; If there was a error, try again.

loadkernel:	; kernel is placed to 2nd sector load it to h7E00
	mov si, msg_kernel
	call print_string
	mov ax, 0x07E0	; segment
	mov es, ax
	mov bx, 0x0000 ; offset add => 0x7E00
	mov ah, 02	; BIOS read sector function
	mov al, 01	; read one sector
	mov ch,	00	; Track to read
	mov cl,	02	; Sector to read
	mov dh,	00	; Head to read
	mov dl, [bootdrive]	; Drive to read
	int 0x13
	jc error	; Error, try again.

a20:
	mov si, msg_a20
	call print_string
	cli
	mov ax, 0x2401	; support du Fast A20 Gate
	int 0x15
	jc error
	mov ax,0x2401	; active a20 bios call
	int	0x15
	jc error

load_GDT: ; move GDT to 0x500
	mov si, msg_gdt
	call print_string
	xor ax,ax
	mov ds,ax
	mov es,ax
	mov si,GDT                    ; Move From [DS:SI]
	mov di,[GDTbase]              ; Move to [ES:DI]
	mov cx,[GDTsize]              ; size of GDT
	cld                           ; Clear the Direction Flag
	rep movsb                     ; Move it
	lgdt [GDTR]

enter_pmode: ; enter protected mode
	mov si, msg_pmode
	call print_string

	;mov ah,3
	;int 0x10    ; set VGA text mode 3

	mov eax, cr0            ; load the control register in
	or  al, 1               ; set bit 1: pmode bit
	mov cr0, eax            ; copy it back to the control register

	;clear cs/ip/eip
	jmp 08h:next        ; set cs to CODESEL

; PROTECTED MODE
; ----------------------------------------------------------------------
[bits 32]
	next:

	;refresh all segment registers
	mov eax, DATASEL ;0x10
	mov ds, eax
	mov es, eax
	mov fs, eax
	mov gs, eax
	mov ss, eax
	mov esp, 0xffff

	;jump to k_init.asm
	jmp CODESEL:0x7E00

	hlt
; ----------------------------------------------------------------------

times 510-($-$$) db 0
SIGNATURE dw 0AA55h	; boot signature

; ok for C64, adjust for other platforms
data_ptr = $35

	.segment "BSS"
A0:	.res 1
A1:	.res 1
A2:	.res 1
A3:	.res 1
B0:	.res 1
B1:	.res 1
B2:	.res 1
B3:	.res 1
C0:	.res 1
C1:	.res 1
C2:	.res 1
C3:	.res 1
D0:	.res 1
D1:	.res 1
D2:	.res 1
D3:	.res 1
_a_0: .res 4
_b_0: .res 4
_c_0: .res 4
_d_0: .res 4

	; zeropage the most often used variables
	.ifdef __C64__
	F0 = $fb
	F1 = $fc
	F2 = $fd
	F3 = $fe
	.else
F0:	.res 1
F1:	.res 1
F2:	.res 1
F3:	.res 1
	.endif

final_block_size: .res 1
block_counter: .res 3

.import popa
.export _md5_init, _md5_finalize
.export _buffer, _md5_next_block, _md5_next_block_fastcall
.export _a_0, _b_0, _c_0, _d_0
.export _md5_hash

_md5_hash = _a_0

	.SEGMENT "CODE"
; 32-bit addition: src + dst -> dst
.macro add_32 src, dst
	clc
	.repeat 4, I
	lda src + I
	adc dst + I
	sta dst + I
	.endrep
.endmacro

; 32-bit move: dst -> src
.macro mov_32 src, dst
	.repeat 4, I
	lda src + I
	sta dst + I
	.endrep
.endmacro


_md5_init:
	ldx #15
init_const:
	lda initial_consts,x
	sta _a_0,x
	dex
	bpl init_const

	lda #0
	sta block_counter
	sta block_counter + 1
	sta block_counter + 2
	rts

copy_block_to_buffer:
	dey		; copy block to our internal buffer
copy_loop:	; so that we can pad at will
	lda (data_ptr),y
	sta _buffer,y
	dey
	bpl copy_loop
	rts

; Pad the buffer with zeros
; Y holds the index (0 based) of the last data byte
pad_buffer:
	lda #0
next_pad_byte:
	iny
	cpy #64
	beq padding_done
	sta _buffer,y
	bne next_pad_byte
padding_done:
	lda #<_buffer	; we'll be using the copy of the block
	sta data_ptr
	lda #>_buffer
	sta data_ptr + 1
	rts

; Calculate the total message size in bits
calc_total_bits:
	; convert block counter to bit counter
	; multiply by 512 by assuming implicit LSByte (zero)
	clc
	asl block_counter
	rol block_counter + 1
	rol block_counter + 2

	; now add bits from the final block
	clc
	lda final_block_size
	asl
	asl
	asl
	bcc no_bit_overflow
	inc block_counter + 1
	clc
no_bit_overflow:
	adc block_counter
	sta block_counter
	bcc no_carry2
	inc block_counter + 1
no_carry2:
; Append size of the original message (in bits) at
; the end of the final block. Assumes that block_counter
; has been converted to bits already.
	lda block_counter
	sta _buffer + 56
	lda block_counter + 1
	sta _buffer + 57
	lda block_counter + 2
	sta _buffer + 58
	rts

_md5_finalize:
	lda final_block_size
	cmp #56
	bcs extra_block
	rts
extra_block:
	ldy #255
	cmp #64
	bcc no_1_bit
	iny
	lda #$80
	sta _buffer,y
no_1_bit:
	jsr pad_buffer

	jmp append

_md5_next_block_fastcall:
	sta data_ptr
	stx data_ptr + 1
	jsr popa
	tay
	jmp md5_skip_ptr
	
	
_md5_next_block:
	sta data_ptr
	stx data_ptr + 1
md5_skip_ptr:
	sty final_block_size
	cpy #64
	beq normal_block
	cpy #0
	beq append_1_bit	; empty block
	jsr copy_block_to_buffer
append_1_bit:
	ldy final_block_size
	lda #$80	; add extra "1" bit right after the data
	sta _buffer,y
padding:
	jsr pad_buffer

	ldy final_block_size
	cpy #56
	bcs size_wont_fit
append:
	jsr calc_total_bits

normal_block:
	inc block_counter + 1
	bne no_carry
	inc block_counter + 2
no_carry:
size_wont_fit:


	

_md5:

	ldx #15
init_loop:
	lda _a_0,x
	sta A0,x
	dex
	bpl init_loop

	ldx #0

loop_0_15:
	.repeat 4,I
	lda C0 + I
	eor D0 + I
	and B0 + I
	eor D0 + I
	sta F0 + I
	.endrep

	jsr sum_F
	inx
	cpx #16
	bne loop_0_15

loop_16_31:
	.repeat 4,I
	lda B0 + I
	eor C0 + I
	and D0 + I
	eor C0 + I
	sta F0 + I
	.endrep
	
	jsr sum_F
	inx
	cpx #32
	bne loop_16_31

loop_32_47:
	.repeat 4,I
	lda B0 + I
	eor C0 + I
	eor D0 + I
	sta F0 + I
	.endrep
	
	jsr sum_F
	inx
	cpx #48
	bne loop_32_47

loop_48_63:
	.repeat 4,I
	lda #255
	eor D0 + I
	ora B0 + I
	eor C0 + I
	sta F0 + I
	.endrep
	
	jsr sum_F
	inx

	cpx #64
	bne loop_48_63

	add_32 A0, _a_0
	add_32 B0, _b_0
	add_32 C0, _c_0
	add_32 D0, _d_0

	rts


sum_F:
	; just some feedback if needed
	.ifdef __C64__
;	stx $d020
	.endif

	ldy msg_idx,x
	clc
	lda (data_ptr),y
	adc F0
	sta F0
	iny
	lda (data_ptr),y
	adc F1
	sta F1
	iny
	lda (data_ptr),y
	adc F2
	sta F2
	iny
	lda (data_ptr),y
	adc F3
	sta F3

	txa
	asl
	asl
	tay
	clc
	lda k_table,y
	adc F0
	sta F0
	lda k_table+1,y
	adc F1
	sta F1
	lda k_table+2,y
	adc F2
	sta F2
	lda k_table+3,y
	adc F3
	sta F3

	add_32 A0, F0


rotate:
	mov_32 D0, A0
	mov_32 C0, D0

	lda s_table+1,y
	beq skip_first_func
	sta jump_ptr1 + 2
	lda s_table,y
	sta jump_ptr1 + 1
jump_ptr1:
	jmp $0000
skip_first_func:
	lda s_table+3,y
	sta jump_ptr2 + 2
	lda s_table+2,y
	sta jump_ptr2 + 1
jump_ptr2:
	jmp $0000

rotate_cont:
	clc
	lda B0
	sta C0
	adc F0
	sta B0

	lda B1
	sta C1
	adc F1
	sta B1

	lda B2
	sta C2
	adc F2
	sta B2

	lda B3
	sta C3
	adc F3
	sta B3

	rts

	.repeat 3,SHIFT
	.ident (.concat ("rol", .string(3-SHIFT))):
	.repeat 3-SHIFT
	lda F3
	asl
	rol F0
	rol F1
	rol F2
	rol F3
	.endrep
	jmp skip_first_func
	.endrep

	.repeat 4,SHIFT
	.ident (.concat ("ror", .string(4-SHIFT))):
	.repeat 4-SHIFT
	lda F0
	lsr
	ror F3
	ror F2
	ror F1
	ror F0
	.endrep
	jmp skip_first_func
	.endrep

bl3:
	ldy F0
	lda F1
	sta F0
	lda F2
	sta F1
	lda F3
	sta F2
	sty F3
	jmp rotate_cont

bl2:
	ldy F0
	lda F2
	sta F0
	sty F2
	ldy F1
	lda F3
	sta F1
	sty F3
	jmp rotate_cont

bl1:
	ldy F3
	lda F2
	sta F3
	lda F1
	sta F2
	lda F0
	sta F1
	sty F0
	jmp rotate_cont


.segment "DATA"
k_table:
	.dword $d76aa478, $e8c7b756, $242070db, $c1bdceee
	.dword $f57c0faf, $4787c62a, $a8304613, $fd469501
	.dword $698098d8, $8b44f7af, $ffff5bb1, $895cd7be
	.dword $6b901122, $fd987193, $a679438e, $49b40821
	.dword $f61e2562, $c040b340, $265e5a51, $e9b6c7aa
	.dword $d62f105d, $02441453, $d8a1e681, $e7d3fbc8
	.dword $21e1cde6, $c33707d6, $f4d50d87, $455a14ed
	.dword $a9e3e905, $fcefa3f8, $676f02d9, $8d2a4c8a
	.dword $fffa3942, $8771f681, $6d9d6122, $fde5380c
	.dword $a4beea44, $4bdecfa9, $f6bb4b60, $bebfbc70
	.dword $289b7ec6, $eaa127fa, $d4ef3085, $04881d05
	.dword $d9d4d039, $e6db99e5, $1fa27cf8, $c4ac5665
	.dword $f4292244, $432aff97, $ab9423a7, $fc93a039
	.dword $655b59c3, $8f0ccc92, $ffeff47d, $85845dd1
	.dword $6fa87e4f, $fe2ce6e0, $a3014314, $4e0811a1
	.dword $f7537e82, $bd3af235, $2ad7d2bb, $eb86d391

s_table:
	;.byte 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22
	.word ror1, bl1, ror4, bl2, rol1, bl2, ror2, bl3
	.word ror1, bl1, ror4, bl2, rol1, bl2, ror2, bl3
	.word ror1, bl1, ror4, bl2, rol1, bl2, ror2, bl3
	.word ror1, bl1, ror4, bl2, rol1, bl2, ror2, bl3

	;.byte 5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20
	.word ror3, bl1, rol1, bl1, ror2, bl2, ror4, bl3
	.word ror3, bl1, rol1, bl1, ror2, bl2, ror4, bl3
	.word ror3, bl1, rol1, bl1, ror2, bl2, ror4, bl3
	.word ror3, bl1, rol1, bl1, ror2, bl2, ror4, bl3

	;.byte 4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23
	.word ror4, bl1, rol3, bl1, 0, bl2, ror1, bl3
	.word ror4, bl1, rol3, bl1, 0, bl2, ror1, bl3
	.word ror4, bl1, rol3, bl1, 0, bl2, ror1, bl3
	.word ror4, bl1, rol3, bl1, 0, bl2, ror1, bl3

	;.byte 6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
	.word ror2, bl1, rol2, bl1, ror1, bl2, ror3, bl3
	.word ror2, bl1, rol2, bl1, ror1, bl2, ror3, bl3
	.word ror2, bl1, rol2, bl1, ror1, bl2, ror3, bl3
	.word ror2, bl1, rol2, bl1, ror1, bl2, ror3, bl3

msg_idx:
	.byte 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60
	.byte 4, 24, 44, 0, 20, 40, 60, 16, 36, 56, 12, 32, 52, 8, 28, 48
	.byte 20, 32, 44, 56, 4, 16, 28, 40, 52, 0, 12, 24, 36, 48, 60, 8
	.byte 0, 28, 56, 20, 48, 12, 40, 4, 32, 60, 24, 52, 16, 44, 8, 36

_buffer:
	.res 64,$0

initial_consts:
	.dword $67452301
	.dword $efcdab89
	.dword $98badcfe
	.dword $10325476

; vim: set autoindent noexpandtab tabstop=4 shiftwidth=4 :

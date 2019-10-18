.export _main
.import _md5_next_block, _md5_init, _md5_finalize
.import _md5_hash
.import exit

    .segment "BSS"
counter: .res 1
test_idx: .res 1

; Run tests from https://www.ietf.org/rfc/rfc1321.txt
; and one additional, larger (16KB) text.
	.segment "STARTUP"
_main:
	lda #0
	sta test_idx
test_loop:
	jsr _md5_init
	lda test_idx
	asl
	asl
	tay
	lda test_table,y
	pha
	ldx test_table + 1,y
	lda test_table + 2,y
	tay
	pla
	jsr _md5_next_block
	jsr _md5_finalize

	jsr verify_hash

	inc test_idx
	lda test_idx
	cmp #(test_table_end - test_table) / 4
	bne test_loop
	beq long_tests

verify_hash:
	ldx #0
	lda test_idx
	asl
	asl
	asl
	asl
	tay
hash_loop:
	lda hash_table,y
	cmp _md5_hash,x
	bne error
	iny
	inx
	cpx #16
	bne hash_loop
	rts
error:
	ldx test_idx
	inx
	txa
	jmp exit
  

long_tests:    
	jsr _md5_init
	lda #<data4
	ldx #>data4
	ldy #64
	jsr _md5_next_block
 	lda #<(data4+64)
	ldx #>(data4+64)
	ldy #16
	jsr _md5_next_block
	jsr _md5_finalize

	jsr verify_hash

	inc test_idx

	lda #0		; loop 256 times for 64*256=16384 bytes
	sta counter
	jsr _md5_init
next_block:
	lda #<data5
	ldx #>data5
	ldy #64
	jsr _md5_next_block
	dec counter
	bne next_block
	jsr _md5_finalize

	jsr verify_hash

	lda #0
	rts

	.SEGMENT "DATA"
test_table:
	.word data0, 0
	.word data0, 1
	.word data0, 3
	.word data1, 14
	.word data2, 26
	.word data3, 62
test_table_end:

hash_table:
	.byte $d4,$1d,$8c,$d9,$8f,$00,$b2,$04,$e9,$80,$09,$98,$ec,$f8,$42,$7e
	.byte $0c,$c1,$75,$b9,$c0,$f1,$b6,$a8,$31,$c3,$99,$e2,$69,$77,$26,$61
	.byte $90,$01,$50,$98,$3c,$d2,$4f,$b0,$d6,$96,$3f,$7d,$28,$e1,$7f,$72
	.byte $f9,$6b,$69,$7d,$7c,$b7,$93,$8d,$52,$5a,$2f,$31,$aa,$f1,$61,$d0
	.byte $c3,$fc,$d3,$d7,$61,$92,$e4,$00,$7d,$fb,$49,$6c,$ca,$67,$e1,$3b
	.byte $d1,$74,$ab,$98,$d2,$77,$d9,$f5,$a5,$61,$1c,$2c,$9f,$41,$9d,$9f
	.byte $57,$ed,$f4,$a2,$2b,$e3,$c9,$55,$ac,$49,$da,$2e,$21,$07,$b6,$7a
	.byte $5e,$43,$d5,$50,$cf,$52,$d2,$9f,$50,$60,$e8,$72,$d5,$f2,$62,$8d
data0:
	.byte "abc"
data1:
	.byte "message digest"
data2:
	.byte "abcdefghijklmnopqrstuvwxyz"
data3:
	.byte "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
data4:
	.byte "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
data5:
	.byte "123456789012345678901234567890123456789012345678901234567890123",10

; vim: set autoindent noexpandtab tabstop=4 shiftwidth=4 :

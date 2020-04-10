BasicUpstart2(Entry)


Entry:
		sei
			lda #$7f
			sta $dc0d
			sta $dd0d

			lda #$35
			sta $01

			lda #%00	//Select vic bank
			sta $dd00

			lda #%00000010
			sta $d018

			lda $d016
			and #%11110111
			ora #%00010111
			sta $d016

			lda #$00
			sta $d020
			lda #$00
			sta $d022
			lda #$09
			sta $d023


			ldx #$00
			jsr DrawMapFull


		cli

	!Loop:
		lda #$ff 
		cmp $d012
		bne *-3

		inc MapPosition

	//Columns left to right
	// inc $d020
	// 	ldx MapPosition
	// 	jsr DrawMapFull
	// dec $d020

	// Rows top to bottom
	// inc $d020
	// 	ldx MapPosition
	// 	jsr DrawMapFull2
	// dec $d020


	//Shift rows to left top to bottom
	inc $d020
		ldx MapPosition
		jsr ShiftMap
	dec $d020


		jmp !Loop-



MapPosition:
		.byte $00


* = * "ShiftMap"
ShiftMap: {
		txa 
		clc
		adc #$27
		tax 
		.for(var i=0; i< 19; i++) {
			lda CHAR_MAP + $100 * i, x	
			sta SCREEN_RAM + $28 * i + $26
		}
		.for(var i=0; i< 19; i++) {
			.for(var j=0; j<38; j++) {
				lda SCREEN_RAM + $28 * i + j + 1
				sta SCREEN_RAM + $28 * i + j + 0
			}
		}
		rts
}


* = * "DrawMapFull2"
DrawMapFull2: {

		lda #>SCREEN_RAM
		sta ScrMod + 2
		lda #$00
		sta ScrMod + 1

		lda #>CHAR_MAP
		sta MapMod + 2
		stx MapMod + 1

		ldy #$19
	!OuterLoop:
		ldx #$27
	!Loop:
	MapMod:
		lda $BEEF, x
	ScrMod:
		sta $BE00, x
		dex
		bpl !Loop-

		inc MapMod + 2

		clc 
		lda ScrMod + 1
		adc #$28
		sta ScrMod + 1
		bcc !+
		inc ScrMod + 2
	!:
		dey
		bne !OuterLoop-

		rts
}

* = * "DrawMapFull"
DrawMapFull: {
		ldy #$00
	!:
		.for(var i=0; i<25; i++) {
			lda CHAR_MAP + $100 * i, x
			sta SCREEN_RAM + $28 * i, y
		}
		inx
		iny
		cpy #$28
		beq !+
		jmp !-
	!:
		rts
}


ClearScreen: {
		ldx #$00
	!:
		sta SCREEN_RAM, x
		sta SCREEN_RAM + $100, x
		sta SCREEN_RAM + $200, x
		sta SCREEN_RAM + $300, x
		dex
		bne !-
		rts
}

//Map data
* =$8000
CHAR_MAP:
	.import binary "./assets/map.bin"
COLOR_MAP:
	.import binary "./assets/cols.bin"

//VIC BANK
//$c000-$ffff
//screen at $c000
//char set at $c800
.label SCREEN_RAM = $c000
* = $c800 "Charset"
	.import binary "./assets/chars.bin"







* = $02 virtual
ZP_MapLookup: .word $0000
ZP_ScreenLookup: .word $0000



BasicUpstart2(Entry)

Entry: 
		sei
			lda #$7f
			sta $dc0d
			sta $dd0d

			lda #$35
			sta $01

			lda #%10	//Select vic bank
			sta $dd00

			lda #%00000010
			sta $d018

			lda $d016
			ora #%00010000 //Turn on MC char mode
			sta $d016

			lda #$00
			sta $d020
			lda #$06
			sta $d021

			lda #$00
			sta $d022
			lda #$09
			sta $d023

			lda #<Split01
			sta $fffe
			lda #>Split01
			sta $ffff
			lda #$ff
			sta $d012
			lda $d011
			and #$7f
			sta $d011

			lda #$01
			sta $d01a

			asl $d019
		cli

		jsr DrawInitialMap

	!Loop:
		lda FrameUpdateFlag
		beq !Loop-
		inc TIMER
		lda #$00
		sta FrameUpdateFlag


		// lda TIMER
		// and #$1f
		// bne !Loop-


		inc $d020
			lda FineScroll
			sec
			sbc #$01
			and #$07
			sta FineScroll 

			lda $d011        
			and #%01110000 
			ora FineScroll  
			sta $d011

			lda FineScroll
			cmp #$07
			bne !+
			jsr ShiftMap
		!:

		dec $d020
		
		jmp !Loop-


TIMER:
	.byte $00
MapPosition:
	.byte $00
FineScroll:
	.byte $07
FrameUpdateFlag:
	.byte $00

ShiftMap: {
		// .for(var i=0; i<24; i++) {
		// 	ldx #$27
		// !:
		// 	lda SCREEN_RAM + $28 + i * $28, x
		// 	sta SCREEN_RAM + $00 + i * $28, x
		// 	dex
		// 	bpl !-			
		// }

		.for(var i=0; i<24; i++) {
			.for(var j=0; j<40; j++) {
				lda SCREEN_RAM + $28 + i * $28 + j
				sta SCREEN_RAM + $00 + i * $28 + j	
				lda COLOR_RAM + $28 + i * $28 + j
				sta COLOR_RAM + $00 + i * $28 + j	
			}	
		}
	
		ldy #$27
	!Loop:
		lda (ZP_MapLookup), y
		sta SCREEN_RAM + $28 * $18, y
		tax 
		lda CHAR_COLORS, x
		sta COLOR_RAM + $28 * $18, y
		dey
		bpl !Loop-

		lda ZP_MapLookup + 0
		clc
		adc #$28
		sta ZP_MapLookup + 0
		lda ZP_MapLookup + 1
		adc #$00
		cmp #$a8
		bne !+
		lda #$80
	!:
		sta ZP_MapLookup + 1

		rts
}


DrawInitialMap: {
		lda #<MAP
		sta ZP_MapLookup + 0
		lda #>MAP
		sta ZP_MapLookup + 1

		lda #<SCREEN_RAM
		sta ZP_ScreenLookup + 0
		lda #>SCREEN_RAM
		sta ZP_ScreenLookup + 1

		ldx #$18
	!OuterLoop:
		ldy #$27
	!Loop:
		lda (ZP_MapLookup), y
		sta (ZP_ScreenLookup), y
		dey
		bpl !Loop-

		lda ZP_MapLookup + 0
		clc
		adc #$28
		sta ZP_MapLookup + 0
		sta ZP_ScreenLookup + 0
		bcc !+
		inc ZP_MapLookup + 1
		inc ZP_ScreenLookup + 1
	!:
		dex
		bpl !OuterLoop-


		ldx #$00
	!:
		ldy SCREEN_RAM + $000, x
		lda CHAR_COLORS, y
		sta $d800, x
		ldy SCREEN_RAM + $100, x
		lda CHAR_COLORS, y
		sta $d900, x
		ldy SCREEN_RAM + $200, x
		lda CHAR_COLORS, y
		sta $da00, x
		ldy SCREEN_RAM + $300, x
		lda CHAR_COLORS, y
		sta $db00, x
		dex
		bne !-

		rts
}




Split01: {
		pha

			lda #$01
			sta FrameUpdateFlag



		asl $d019
		pla
		rti
}



.label SCREEN_RAM = $4000
.label COLOR_RAM = $d800

* = $4800 "Charset"
	.import binary "./assets/chars_v.bin"
* = $7f00 
CHAR_COLORS:
	.import binary "./assets/cols_v.bin"
* = $8000
MAP:
	.import binary "./assets/map_v.bin"
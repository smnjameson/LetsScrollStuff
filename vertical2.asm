* = $02 virtual
ZP_MapLookup: .word $0000
ZP_ScreenLookup: .word $0000

ZP_LineBuffer: .fill 40, 0
ZP_LineColBuffer: .fill 40, 0


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
			lda #$90
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
			clc
			adc #$01
			and #$07
			sta FineScroll 

			lda $d011        
			and #%01110000 
			ora FineScroll  
			sta D011_Val

			lda FineScroll
			cmp #$00
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
	.byte $00
FrameUpdateFlag:
	.byte $00
D011_Val:
	.byte $1b

.label BUFFER_SPLIT_LINE = $0c
ShiftMap: {
		lda ZP_MapLookup + 0
		sec
		sbc #$28
		sta ZP_MapLookup + 0
		lda ZP_MapLookup + 1
		sbc #$00
		cmp #$7f
		bne !+
		lda #$a7
	!:
		sta ZP_MapLookup + 1

		.for(var j=0; j<40; j++) {
			lda SCREEN_RAM + $00 + BUFFER_SPLIT_LINE * $28 + j
			sta ZP_LineBuffer + j
			lda COLOR_RAM + $00 + BUFFER_SPLIT_LINE * $28 + j
			sta ZP_LineColBuffer + j
		}


		.for(var i=BUFFER_SPLIT_LINE; i>0; i--) {
			.for(var j=0; j<40; j++) {
				lda SCREEN_RAM - $28 + i * $28 + j
				sta SCREEN_RAM + $00 + i * $28 + j	
				lda COLOR_RAM - $28 + i * $28 + j
				sta COLOR_RAM + $00 + i * $28 + j	
			}	
		}

		ldy #$27
	!Loop:
		lda (ZP_MapLookup), y
		sta SCREEN_RAM, y
		tax 
		lda CHAR_COLORS, x
		sta COLOR_RAM, y
		dey
		bpl !Loop-


		.for(var i=24; i>(BUFFER_SPLIT_LINE); i--) {

			.if(i == BUFFER_SPLIT_LINE + 1) {
				.for(var j=0; j<40; j++) {
					lda ZP_LineBuffer + j
					sta SCREEN_RAM + $00 + i * $28 + j	
					lda ZP_LineColBuffer + j
					sta COLOR_RAM + $00 + i * $28 + j	
				}
			} else {
				.for(var j=0; j<40; j++) {
					lda SCREEN_RAM - $28 + i * $28 + j
					sta SCREEN_RAM + $00 + i * $28 + j	
					lda COLOR_RAM - $28 + i * $28 + j
					sta COLOR_RAM + $00 + i * $28 + j	
				}	
			}
		}
	




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


		lda #<MAP
		sta ZP_MapLookup + 0
		lda #>MAP
		sta ZP_MapLookup + 1

		rts
}




Split01: {
		pha

			lda #$01
			sta FrameUpdateFlag

			lda #<Split02
			sta $fffe
			lda #>Split02
			sta $ffff
			lda #$ff
			sta $d012

		asl $d019
		pla
		rti
}

Split02: {
		pha

			lda #<Split01
			sta $fffe
			lda #>Split01
			sta $ffff
			lda #$90
			sta $d012
				
			lda D011_Val
			sta $d011

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
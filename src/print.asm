; Simple printing module.
;
; Copyright (C) 2012-2023 Patrik Rak (patrik@raxoft.cz)
;
; This source code is released under the MIT license, see included license.txt.


printinit:  ; GRAPHIC 1 (SCREEN 1)にする
            ld      a,0         ; VDP mode register 0 (R#0)
            ld      b,%00000000
            call    write_vdp_reg

            ld      a,1         ; VDP mode register 0 (R#1)
            ld      b,%01000000
            call    write_vdp_reg

            ld      a,2         ; VDP pattern name table base address register 0 (R#2)
            ld      b,%00000110 ; 01800H
            call    write_vdp_reg

            ld      a,3         ; VDP color table base address register (b13-b5) (R#3)
            ld      b,%10000000 ; 02000H
            call    write_vdp_reg

            ld      a,10        ; VDP color table base address register (b16-b14) (R#0)
            ld      b,%00000000 ; 02000H
            call    write_vdp_reg

            ld      a,4         ; VDP pattern generator table base address register (b16-b11) (R#4)
            ld      b,%00000000 ; 00000H
            call    write_vdp_reg
            

            ; pattern generator tableへの転送
            ld      hl,character_data
            ld      a,0x00
            out     (0x98+1),a  ; pattern generator table 00100Hの下位8bit
            ld      a,0x40 + 0x01
            out     (0x98+1),a  ; pattern generator table 00100Hの上位8bit + ライトフラグ(b14)
            ld      d,128
.pgt_loop_d:
            ld      e,8
.pgt_loop_e:
            ld      a,(hl)
            out     (0x98+0),a          ; アドレスはオートインクリメントされる
            inc     hl
            dec     e
            jr      nz,.pgt_loop_e
            dec     d
            jr      nz,.pgt_loop_d

            ; color tableへの転送
            ld      a,0x00
            out     (0x98+1),a      ; color table 02000Hの下位8bit
            ld      a,0x40 + 0x20
            out     (0x98+1),a      ; color table 02000Hの上位8bit + ライトフラグ
            ld      d,32
            ld      a,0xf0
.ct_loop_d  out     (0x98+0),a
            dec     d
            jr      nz,.ct_loop_d

            ret

printchr:   push    hl
            push    bc
            sub     13
            jr      z,.cr
            add     13
            ld      l,a
            ld      a,(.printpos+0) ; 下位 8bit
            out     (0x98+1),a
            ld      a,(.printpos+1) ; 上位 8bit
            or      0x40            ; ライトフラグ
            out     (0x98+1),a
            ld      a,l
            out     (0x98+0),a
            ld      hl,(.printpos)
            inc     hl
            ld      a,h
            and     0x03            ; bit 9-0だけでループさせる
            or      0x18            ; パターンネームテーブルベースアドレス
            ld      h,a
            ld      (.printpos),hl
            pop     bc
            pop     hl      
            ret
.cr:
            ld      hl,(.printpos)
            ld      a,l
            and     0xe0            ; 32の倍数にする
            ld      l,a
            ld      bc,32
            add     hl,bc
            ld      a,h
            and     0x03            ; bit 9-0だけでループさせる
            or      0x18            ; パターンネームテーブルベースアドレス
            ld      h,a
            ld      (.printpos),hl
            pop     bc
            pop     hl      
            ret

.printpos   dw      0x1800

; A = register
; B = value
write_vdp_reg:
            push    af
            ld      a,b
            out     (0x98+1),a  ; data→portの順番で書き込む
            pop     af
            out     (0x98+1),a
            ret

print:      ex      (sp),hl
            call    printhl
            ex      (sp),hl
            ret

printhl:
.loop       ld      a,(hl)
            inc     hl
            or      a
            ret     z
            call    printchr
            jr      .loop


printdeca:  ld      h,a
            ld      b,-100
            call    .digit
            ld      b,-10
            call    .digit
            ld      b,-1

.digit      ld      a,h
            ld      l,'0'-1
.loop       inc     l
            add     a,b
            jr      c,.loop
            sub     b
            ld      h,a
            ld      a,l
            jr      printchr


printcrc:   ld      b,4

printhexs:
.loop       ld      a,(hl)
            inc     hl
            call    printhexa
            djnz    .loop
            ret


printhexa:  push    af
            rrca
            rrca
            rrca
            rrca
            call    .nibble
            pop     af

.nibble     or      0xf0
            daa
            add     a,0xa0
            adc     a,0x40

            align   256

            include character.asm

; EOF ;

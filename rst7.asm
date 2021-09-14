	; обработка прерывания
interrupt:
	push af
	push hl
	push bc

	ld hl,int_counter		; увеличить таймер
	inc (hl)
	ld a,$01				; разделяем сбор и обработку клавиш
	and a,(hl)
	call nz,parse_keys

	ld a,$8a
	out ($00),a

	ld hl,keys_line_0
	ld c,$fe

	REPT 8
	ld a,c					; сканируем клавиатуру
	out ($03),a
	rlca
	ld c,a
	in a,($02)
	ld (hl),a	
	inc l
	ENDM

_interrupt_end_keys:

	ld a,$88
	out ($00),a				; режим порта
	
	ld a,(scroll_pos)
	out ($03),a				; скроллинг экрана
	
	ld a,(border_color)		; бордюр экрана и 256 точек экран
	out ($02),a

	pop bc
	pop hl
	pop af
	ei
	ret

	; TODO разбор клавиш	
parse_keys:
	ld hl,_interrupt_end_keys
	EX (SP),HL

	ret


keys_line_0:
	DEFB $ff				; DOWN RIGHT UP LEFT BS CR LF TAB
keys_line_1:
	DEFB $ff				; F5 F4 F3 F2 F1 AR2 STR LEFT-UP
keys_line_2:
	DEFB $ff				; 7 6 5 4 3 2 1 0
keys_line_3:
	DEFB $ff				; / . = , ; : 9 8
keys_line_4:
	DEFB $ff				; G F E D C B A @
keys_line_5:
	DEFB $ff				; O N M L K J I H
keys_line_6:
	DEFB $ff				; W V M L K J I H
keys_line_7:
	DEFB $ff				; SP ^ ] \ [ Z Y X

int_counter:
	DEFB $00				; счетчик прерываний

scroll_pos:
	DEFB $ff				; аппаратный скроллинг

border_color:
	DEFB $01				; цвет бордюра

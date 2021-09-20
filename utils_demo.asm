	org $100

	jp start_prog

	include "rst7.asm"
	include "koi8r-font.asm"
	include "utils.asm"
	include "strings.asm"

start_prog:
	di					; запретить прерывания
	xor a				; выключить квазидиск
	out ($10),a
	ld sp,$8000-1		; инициализировать указатель стека

	ld a,$C3			; код инструкции jp start_prog
	ld ($0000),a		; записать по адресу 0
	ld hl,start_prog
	ld ($0001),hl

	ld ($0038),a		; записать команду jp
	ld hl,interrupt		; по адресу 0x38 (адрес прерывания)
	ld ($0039),hl

	ei					; разрешить прерывания

	call palette_off	; выключить палитру
	call clear_scr		; очистить экран
	call palette_on		; включить палитру

	ld a,%00001111		; разрешить доступ ко всем плоскостям (0-4)
	call set_planes

	ld a,15				; начальный цвет символов
	call set_color		; установить

	ld hl,$001f			; начальная координата h=x, l=y
	call set_cur		; установить

	ld de,str_test		; строка для вывода
	call print_str		; печатать

	ld a,27				; новая ширина табуляции
	call set_tab_width
	ld a,'.'			; новый заполнитель табуляции
	call set_tab_placeholder

	ld de,str_test2		; строка для вывода
	call print_str		; печатать

wait_space:
	ld a,(keys_lines)	; ждем пробел
	and %10000000
	jp z,wait_space

	call clear_scr		; очистить экран

	ld hl,$1f1f			; начальная координата
	call set_cur
	ld b,0				; цвет
	ld c,' '

loop:
	ld a,b				; меняем цвет
	call set_color
	inc b

	call char_next_pos
	call char_coord_to_scr_addr
	ld a,c
	call print_char		; печать символа

	inc c				; меняем символ
	jp nz,loop
	ld c, ' '

	jp loop
	end

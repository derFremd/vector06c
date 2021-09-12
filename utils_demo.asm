	org $100

	jp start_prog

	include "koi8r-font.asm"
	include "utils.asm"
	include "rst7.asm"
	include "strings.asm"

start_prog:
	di					; запретить прерывания
	xor a				; выключить квазидиск
	out ($10),a
	ld sp,$8000			; инициализировать указатель стека

	ld a,$C3			; код инструкции jp start_prog
	ld ($0000),a		; записать по адресу 0
	ld hl,start_prog
	ld ($0001),hl

	ld ($0038),a		; записать команду jp int_proc
	ld hl,int_proc		; по адресу 0x38 (адрес прерывания)
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

	;exx
	ld a,27				; новая ширина табуляции
	call set_tab_width
	ld a,'.'			; новый заполнитель табуляции
	call set_tab_placeholder

	ld de,str_test2		; строка для вывода
	call print_str		; печатать

loop:
	nop					; бесконечный цикл
	jp loop

	end
BITS 16
ORG 0x7C00   ; Este es el punto de inicio del código en memoria

mov ax, 0x13
int 0x10    ; Cambia a modo gráfico 320x200

jmp $       ; Un loop infinito que hace lo mismo, pero usa menos bytes

; ========================
; Rellenar hasta 510 bytes (Si el código es muy corto, NASM lo llenará con ceros)
; ========================
times 510 - ($ - $$) db 0  

; ========================
; Firma de arranque (OBLIGATORIA PARA QEMU)
; ========================
dw 0xAA55  

; lib.asm

section .text
 
; callee-saved registers: rbx rbp rsp r12 .. r15
; caller-saved registers: rax rcx rdx rsi rdi r8
; arguments:              rdi rsi
; return values:          rax rdx


; Terminates current process with a given error code
; pred: rdi - return code - unit64
; post: process terminated
exit: 
    mov rax, 60             ; sys_exit code
    syscall 


; Takes null-terminated string and returns its length
; symbols are one byte size
; pred: rdi - string beginning (a pointer to the first char)
; post: rax - length of the given string
string_length:
    mov rax, rdi            ; rax - pointer to current char
    .count_current_char:       
        cmp byte [rax], 0  
        je .calculate_length            
        inc rax             
        jmp .count_current_char
    .calculate_length:
        sub rax, rdi        
        ret  

; Writes null-terminated string in a given file
; pred: rdi - string beginning (a pointer to the first char) 
;       rsi - descriptor of file where to write
; post: string is writted to file
write_string:
    push rdi
    push rsi
    call string_length      ; rax = strlen(arg_string)
    pop rsi
    pop rdi
    mov rdx, rax            ; rdx = rax = strlen(arg_string)
    mov r8, rdi             ; swap rdi <-> rsi
    mov rdi, rsi            ; rdi - file descriptor
    mov rsi, r8             ; rsi - string
    mov rax, 1              ; sys_write code
    syscall
    ret


; Prints null-terminated string to stdout
; pred: rdi - null-terminated string to print
; post: string is printed to stdout
print_string:
    mov rsi, 1              ; stdout file descriptor
    jmp write_string        ; tail-optimization


; Takes string from rdi and prints it ro stdout
; WARNING: don't forget to add 0 - null-terminator - as the last symbol
print_string_with_length_8:
    push rdi
    mov rdi, rsp            ; set arg for print_string 
    call print_string    
    pop rax
    ret


; Takes character and prints it in stdout
; pred: rdi - byte - character to print
; post: character printed to stdout
print_char:
    jmp print_string_with_length_8


; Prints a newline char to stdout
; post: \n printed to stdout
print_newline:
    mov rdi, 10
    jmp print_char


; Reverses string inplace 
; rdi - null-terminated string to reverse
; rdi - reversed string
; example: "abcdse\0" -> "esdcba\0"
string_reverse:
    push rdi
    call string_length      ; rax = strlen(rdi)
    pop rdi
    mov rsi, rdi            ; rsi - left pointer
    add rdi, rax            ; rdi - right pointer
    sub rdi, 1
    .swap_next_pair:
        mov dl, byte [rdi]
        mov al, byte [rsi]
        mov byte [rdi], al
        mov byte [rsi], dl
        dec rdi
        inc rsi
        cmp rdi, rsi
        jb .end
        jmp .swap_next_pair
    .end:
        ret


; Takes uint64 number and stores its decimal representation
; as null-terminated string at given address
; pred: rdi - unit64 - number
;       rsi - address where to write string, buffer must be 24 bytes long
; post: number in decimal format saved at given address
store_uint64_as_string_in_decimal_format:
    push rsi
    test rdi, rdi           ; if rdi == 0
    je .number_is_zero                ;   number is zero
    mov rax, rdi            ; rax - n - current number
    .shift_lowest_runked_digit:
        xor rdx, rdx        ; dividable is a n = rdx:rax
        mov rdi, 10
        div rdi             ; rax = n / 10, rdx = n % 10
        add rdx, '0'        ; rdx = digit ascii code
        mov [rsi], rdx      ; store digit
        inc rsi             ; move pointer
        test rax, rax       ; if rax == 0
        je .end             ;   that is all over
        jmp .shift_lowest_runked_digit           
    .number_is_zero:
        mov byte [rsi], '0' ; put '0'
        inc rsi             ; move pointer
    .end:
        mov byte [rsi], 0   ; put null-terminator
        pop rdi
        jmp string_reverse


; Calculates absolute value of the given number 
; pred: rdi: int64 = x
; post: rdi = |x|
_abs:
    cmp rdi, 0      
    jnl .n_is_not_negative   
    neg rdi
    .n_is_not_negative:
        ret
    

; Takes int64 number and stores its decimal representation
; as null-terminated string at given address
; pred: rdi - nit64 - number
;       rsi - address where to write string, buffer must be 21 bytes long
; post: number in decimal format saved at given address
store_int64_as_string_in_decimal_format:
    cmp rdi, 0
    jnl .not_negative
    mov byte [rsi], '-'
    inc rsi
    call _abs 
    .not_negative:
        call store_uint64_as_string_in_decimal_format
        ret


; Takes unit64 and prints it in decimal format to stdout
; pred: rdi - number uint64 to print
; post: number is printed
print_uint:
    push r12
    mov r12, rsp            ; initial rsp
    sub rsp, 24             ; allocate 24 bytes on stack
    mov rsi, rsp   
    call store_uint64_as_string_in_decimal_format
    mov rdi, rsp
    call print_string
    mov rsp, r12            ; free allocated 24 bytes
    pop r12
    ret


; Prints int64 to stdout in decimal format
; pred: rdi - int64 - number to print
; post: number is printed
print_int:
    push r12
    mov r12, rsp            ; initial rsp
    sub rsp, 24             ; allocate 24 bytes on stack
    mov rsi, rsp          
    call store_int64_as_string_in_decimal_format
    mov rdi, rsp
    call print_string
    mov rsp, r12            ; free allocated 24 bytes
    pop r12
    ret

; pred: rdi, rsi - null-terminated strings a and b
; post: rax = 1 <=> a = b else rax = 0
string_equals:
    mov rax, 1              ; assyme that they are equal by default
    .take_next_character:
        mov dl, byte [rdi]  ; compare current characters
        cmp dl, byte [rsi]  
        jne .not_equals
        cmp byte [rdi], 0  
        je .end            
        inc rdi             ; move to the next chars pair
        inc rsi
        jmp .take_next_character   
    .not_equals:
        mov rax, 0    
    .end:
        ret


_string_copy:
    .copy_current_char:
        mov al, byte [rdi]
        mov byte [rsi], al        
        test al, al
        je .end
        inc rdi
        inc rsi
        jmp .copy_current_char
    .end:
        ret
     

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
; rdi, rsi, rdx
string_copy:
    push rdi
    push rsi
    push rdx
    call string_length
    pop rdx
    pop rsi
    pop rdi
    cmp rax, rdx
    ja .error
    .ok:
        push rdi
        call _string_copy
        pop rdi
        jmp string_length
    .error:
        mov rax, 0
        ret
      

; Читает один символ из stdin и возвращает его. 
; Возвращает 0 если достигнут конец потока
read_char:
    push 0
    mov rax, 0
    mov rdi, 0
    mov rsi, rsp
    mov rdx, 1
    syscall
    pop rax
    ret


; sets flags dont want to explain, sorry
_is_whitespace:
    cmp al, 0x20
    je .yes
    cmp al, 0x09
    je .yes
    cmp al, 0x0A
    je .yes
    cmp al, 0x0A
    ret
    .yes:
        cmp al, al
        ret


; Reads one word from stdin skipping leading 
; whitespaces (0x20 - space, 0x9 - tab, 0xA - newline)
; Takes a buffer and its size
; pred: rdi - pointer to buffer size
;       rsi - size of buffer in bytes
; if succeeds 
;   rax is buffer begin pointer where null-terminated string is 
;   rdx is word size  
; else if error 
;   rax = 0 
read_word:
    push rdi
    mov r8, rdi
    mov rcx, rdi    ; buffer end
    add rcx, rsi
    dec rcx
    .skipping_leading_whitespaces:
        push r8
        push rcx
        call read_char
        pop rcx
        pop r8
        cmp al, 0x20
        je .skipping_leading_whitespaces
        cmp al, 0x09
        je .skipping_leading_whitespaces
        cmp al, 0x0A
        je .skipping_leading_whitespaces
    .scanning_letters:
        cmp al, 0x20
        je .end_word
        cmp al, 0x09
        je .end_word
        cmp al, 0x0A
        je .end_word
        cmp al, 0x00
        je .end_word
        mov byte [r8], al
        inc r8
        cmp r8, rcx
        je .buffer_overflow
        push r8
        push rcx
        call read_char
        pop rcx
        pop r8
        jmp .scanning_letters
    .end_word:
        pop rax
        mov byte [r8], 0
        sub r8, rax
        mov rdx, r8
        ret
    .buffer_overflow:
        pop rax
        mov rax, 0
        ret


; Takes string and trying to read an positive int64
; from its start 
; if succeeds
;   rax is parsed number
;   rdx its length in characters
; else if error
;   rdx = 0
; example:
;   2131aaa... -> 2131, 4
;   aaaa... -> ???, 0
;   0a... -> 0, 1
parse_uint:
    push rdi
    mov r8, 10          ; BASE 10
    mov rcx, rdi        ; pointer to next character
    mov rax, 0          ; result number
    mov rdi, 0          ; read character
    .first_digit:
        mov dil, byte [rcx]
        inc rcx
        cmp dil, '0'
        je .zero
        cmp dil, '1'
        jb .error
        cmp dil, '9'
        ja .error
        sub dil, '0'
        add rax, rdi 
    .next_digit:
        mov dil, byte [rcx]
        inc rcx
        cmp dil, '0'
        jb .end       ; TODO: use _is_digit
        cmp dil, '9'
        ja .end
        mul r8
        sub dil, '0'
        add rax, rdi
        jmp .next_digit
    .zero:
        mov dil, byte [rcx]
        inc rcx
        cmp dil, 0
        je .end
    .end:
        dec rcx
        pop rdi
        mov rdx, rcx
        sub rdx, rdi
        ret
    .error:
        pop rdi
        mov rdx, 0
        ret


; Similar to parse_uint, but reads int64 with sign
parse_int:
    mov al, byte [rdi]
    inc rdi
    cmp al, '-'
    je .negative_sign
    cmp al, '+'
    je .positive_sign
    jmp .positive
    .negative_sign:
        call parse_uint
        neg rax
        inc rdx
        ret
    .positive_sign:
        call parse_uint
        inc rdx
        ret
    .positive:
        dec rdi
        call parse_uint
        ret

; dict.asm
; NB: here `char*` is a pointer to null-terminated string
; NB: dict: Dict* ~ first_dict_node: Node*

%define NULL 0

%define value_at_address_shifted_by(shift, register) [register + shift * 8]

%macro return_instance_field_with_shift 1
  mov rax, value_at_address_shifted_by(%1)
  ret
%endmacro

section .text:
extern string_equals         

global dict_find_entry_by_key
global dict_node_get_next
global dict_node_get_key
global dict_node_get_value

; TODO: remove before release
; RAX, RCX, RDX, R8,  R9,  R10, R11           - caller-saved 
; RBX, RBP, RDI, RSI, RSP, R12, R13, R14, R15 - callee-saved

dict_find_node_with_key:
    ; invariants: rbp - current node to consider
    ;             r12 - search key - const
    ;             rbx - pointer to found dict node 

    push rbp
    push r12
    push rbx

    mov rbp, rdi
    mov r12, rsi
    mov rbx, NULL                       ; initially node is not found

    .consider_next_node:
        test rbp, rbp
        je .no_more_nodes_to_consider

        mov rdi, rbp
        call dict_node_get_key

        mov rdi, rax
        mov rsi, r12
        call string_equals 

        je .found_suitable_node

        mov rdi, rbp
        call dict_node_get_next
        mov rbp, rax

        jmp .consider_next_node

    .found_suitable_node:
        mov rbx, rbx

    .no_more_nodes_to_consider:
        pop rbx
        pop r12
        pop rbp

        mov rax, rbx
        ret

dict_node_get_next:
    return_instance_field_with_shift 0

dict_node_get_key:
    return_instance_field_with_shift 1

dict_node_get_value:
    return_instance_field_with_shift 2

// Лабораторная 4. Косвенная адресация. Вариант 19.
// A[i] == i  ->  копировать A[i] в B.
// scanf/printf на macOS: variadic-аргументы передаются через стек [sp].

.global _main

.equ MAX_N, 32

.text
.align 2

_main:
    // Выделяем память на стеке (выровнено по 16 байт)
    sub sp, sp, #96
    stp x29, x30, [sp, #80]
    add x29, sp, #80

    // --- Ввод N ---
    sub x8, x29, #24

    mov x11, sp
    str x8, [x11]                      // Кладем адрес для scanf на стек

    adrp x0, input_n_str@PAGE
    add x0, x0, input_n_str@PAGEOFF
    bl _scanf

    ldr x23, [x29, #-24]               // x23 = N

    cmp x23, #0
    b.le print_error_n

    mov x12, #MAX_N
    cmp x23, x12
    b.gt print_error_n

    adrp x20, array_a@PAGE
    add x20, x20, array_a@PAGEOFF

    mov x19, x20
    mov x25, x23                       // счётчик ввода

    // Инициализируем массив B нулями
    adrp x21, array_b@PAGE
    add x21, x21, array_b@PAGEOFF
    mov x27, x23
init_b_loop:
    cbz x27, init_b_done
    str xzr, [x21], #8
    subs x27, x27, #1
    b.ne init_b_loop
init_b_done:

    // Выведем адрес переменной для отладки
    sub x8, x29, #24
    mov x11, sp
    str x8, [x11]
    adrp x0, debug_addr@PAGE
    add x0, x0, debug_addr@PAGEOFF
    bl _printf
    
input_loop:
    cbz x25, process_array

    sub x8, x29, #24
    
    mov x11, sp
    str x8, [x11]                      // Адрес для ввода элемента на стек

    adrp x0, input_elem_str@PAGE
    add x0, x0, input_elem_str@PAGEOFF
    bl _scanf

    ldr x9, [x29, #-24]
    
    str x9, [x19], #8
    
    mov x11, sp
    str x9, [x11]
    adrp x0, debug_value@PAGE
    add x0, x0, debug_value@PAGEOFF
    bl _printf
    
    subs x25, x25, #1
    b.ne input_loop

process_array:
    adrp x20, array_a@PAGE
    add x20, x20, array_a@PAGEOFF
    adrp x21, array_b@PAGE
    add x21, x21, array_b@PAGEOFF

    // Отладка: выводим содержимое A
    adrp x0, debug_msg@PAGE
    add x0, x0, debug_msg@PAGEOFF
    bl _printf

    mov x28, #0
debug_loop_a:
    cmp x28, x23
    b.ge debug_done

    ldr x14, [x20, x28, lsl #3]
    
    mov x11, sp
    str x14, [x11]
    adrp x0, debug_elem@PAGE
    add x0, x0, debug_elem@PAGEOFF
    bl _printf

    add x28, x28, #1
    b.ne debug_loop_a
debug_done:
    adrp x0, newline_str@PAGE
    add x0, x0, newline_str@PAGEOFF
    bl _printf

    // Основная логика: копирование из A в B, если A[i] == i
    mov x10, x23
    mov x24, #0                        // x24 - счетчик элементов в массиве B
    mov x17, #0                        // x17 - индекс i

process_loop:
    cmp x17, x10
    b.ge print_result

    ldr x14, [x20, x17, lsl #3]        // Загружаем A[i]

    // Условие: копировать A[i] в B если A[i] == i
    cmp x14, x17
    b.ne next_i

    str x14, [x21, x24, lsl #3]        // Сохраняем в B
    add x24, x24, #1                   // Увеличиваем счетчик элементов B

next_i:
    add x17, x17, #1
    b process_loop

print_result:
    mov x26, x24                       // Копируем счетчик B для вывода

    adrp x0, result_msg@PAGE
    add x0, x0, result_msg@PAGEOFF
    bl _printf

    cbz x26, print_empty

    adrp x22, array_b@PAGE
    add x22, x22, array_b@PAGEOFF

print_loop:
    cbz x26, print_newline

    ldr x14, [x22], #8

    mov x11, sp
    str x14, [x11]

    adrp x0, output_elem_str@PAGE
    add x0, x0, output_elem_str@PAGEOFF
    bl _printf

    subs x26, x26, #1
    b.ne print_loop

print_newline:
    adrp x0, newline_str@PAGE
    add x0, x0, newline_str@PAGEOFF
    bl _printf
    b exit_main

print_empty:
    adrp x0, empty_msg@PAGE
    add x0, x0, empty_msg@PAGEOFF
    bl _printf
    b exit_main

print_error_n:
    adrp x0, error_msg@PAGE
    add x0, x0, error_msg@PAGEOFF
    bl _printf

exit_main:
    ldp x29, x30, [sp, #80]
    add sp, sp, #96

    mov x0, #0
    mov x16, #1                        // Syscall exit (macOS)
    svc #0x80

.section __DATA, __bss
.align 3
array_a:
    .space (MAX_N * 8)
array_b:
    .space (MAX_N * 8)

.section __TEXT,__cstring,cstring_literals
input_n_str:
    .asciz "%lld"
input_elem_str:
    .asciz "%lld"
result_msg:
    .asciz "Result: "
output_elem_str:
    .asciz "%lld "
newline_str:
    .asciz "\n"
error_msg:
    .asciz "Error: N must be in 1..32\n"
empty_msg:
    .asciz "none\n"
debug_msg:
    .asciz "Array A: "
debug_elem:
    .asciz "%lld "
debug_addr:
    .asciz "Address for scanf: %p\n"
debug_value:
    .asciz "Read value: %lld\n"
// Лабораторная 5. Поразрядная обработка. Вариант 54.
// Заменить каждый байт X на количество единиц в нём.
// Все вычисления в пользовательской функции transform_popcount.

.global _main

.text
.align 2

_main:
    // Выравнивание стека и сохранение регистров кадра
    sub sp, sp, #112
    stp x29, x30, [sp, #96]
    add x29, sp, #96

    // --- Ввод X ---
    adrp x0, prompt@PAGE
    add x0, x0, prompt@PAGEOFF
    mov x8, #0
    bl _printf

    adrp x0, fmt_in@PAGE
    add x0, x0, fmt_in@PAGEOFF
    add x1, x29, #-8          // адрес локальной переменной для ввода
    str x1, [sp]              // Apple ABI: дублирование аргумента в стек для variadic
    mov x8, #0
    bl _scanf

    // Вызов пользовательской функции
    ldr x0, [x29, #-8]        // загрузка X в x0
    bl transform_popcount     // результат вернётся в x0

    str x0, [x29, #-16]       // сохранение результата

    // Вывод результата
    adrp x0, fmt_out@PAGE
    add x0, x0, fmt_out@PAGEOFF
    ldr x1, [x29, #-16]
    str x1, [sp]              // Apple ABI: дублирование аргумента в стек для variadic
    mov x8, #0
    bl _printf

    // Выход
    ldp x29, x30, [sp, #96]
    add sp, sp, #112
    mov x0, #0
    ret


/* Функция: transform_popcount
    ВХОД:  x0 = X (длинное целое число)
    ВЫХОД: x0 = результат (каждый байт заменён на popcount)
*/
transform_popcount:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x9, #0            // аккумулятор результата
    mov x10, #0           // текущий сдвиг (0, 8, 16, ..., 56)
    mov x11, #8           // счётчик байтов

byte_loop:
    // 1. Извлечение текущего байта из X
    lsr x12, x0, x10
    and x12, x12, #0xFF

    // 2. Поразрядный подсчёт единиц в байте
    mov x13, #0           // счётчик установленных битов
    mov x14, x12          // рабочая копия байта
    mov x15, #8           // цикл на 8 бит

bit_loop:
    and x16, x14, #1      // выделяем младший бит
    add x13, x13, x16     // добавляем к счётчику
    lsr x14, x14, #1      // сдвигаем байт вправо
    subs x15, x15, #1
    b.ne bit_loop

    // 3. Вставка результата в нужный байт итогового значения
    lsl x13, x13, x10
    orr x9, x9, x13

    // 4. Переход к следующему байту
    add x10, x10, #8
    subs x11, x11, #1
    b.ne byte_loop

    mov x0, x9            // возврат результата
    ldp x29, x30, [sp], #16
    ret

.section __TEXT,__cstring,cstring_literals
prompt:
    .asciz "Enter X: "
fmt_in:
    .asciz "%lld"
fmt_out:
    .asciz "Result: %lld\n"
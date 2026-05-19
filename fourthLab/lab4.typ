#set page(
  paper: "a4",
  margin: (top: 2cm, bottom: 2cm, left: 3cm, right: 1cm),
  numbering: none,
  footer: context {
    let p = counter(page).get().first()
    if p > 1 {
      align(center)[#p]
    }
  }
)

#set text(
  lang: "ru",
  font: "Times New Roman",
  size: 12pt
)

//Рамка для блока с кодом
#show raw: block.with(
  fill: luma(245),
  inset: 10pt,
  radius: 5pt,
  stroke: luma(200),
)

//Для таблиц - подпись сверху
#show figure.where(kind: table): set figure.caption(position: top)



#align(center)[
  #upper[ГУАП]
  #v(0.5cm)
  #upper[КАФЕДРА № 14]
  #v(2cm)
]

#grid(
  columns: (2fr),
  align(left)[
    #upper[ОТЧЕТ]\
    #upper[ЗАЩИЩЕН С ОЦЕНКОЙ]\
    #upper[]\
    #upper[ПРЕПОДАВАТЕЛЬ]
  ],
  align(center)[
    #v(0.5cm)
    #grid(
      columns: (2fr, 1fr, 2fr),
      gutter: 0.3em,
      [Старший преподаватель],
      [14.05.2026],
      [Н.И. Синёв],
      line(length: 100%),
      line(length: 100%),
      line(length: 100%),
      [должность, уч. степень, звание],
      [подпись, дата],
      [инициалы, фамилия]
    )
  ]
)

#align(center)[
  #v(2cm)
  #upper[ОТЧЕТ О ЛАБОРАТОРНОЙ РАБОТЕ №4]
  #v(0.8cm)
  #text[Косвенная адресация]
  #v(0.8cm)
  #text[по курсу:]
  #text[Программирование на языках Ассемблера]
  #v(4cm)
]

#grid(
  columns: (2fr),
  align(left)[
    #upper[РАБОТУ ВЫПОЛНИЛ]
  ],
  align(center)[
    #v(0.5cm)
    #grid(
      columns: (1fr, 1fr, 1fr, 1.5fr),
      gutter: 0.3em,
      align(left)[#upper[СТУДЕНТ гр. № 1443]],
      [2026],
      [14.05.2026],
      [А.Н. Корякин],
      line(length: 0%),
      line(length: 100%),
      line(length: 100%),
      line(length: 100%),
      [],
      [],
      [подпись, дата],
      [инициалы, фамилия]
    )

    #v(4cm)

    Санкт-Петербург 2026
]
)


= Описание задачи
Написать программу с использованием косвенной адресации в ассемблере Apple ARM 64.

= Формализация
Переписать из массива А в массив В те элементы массива А, индексы которых совпадают со значениями.
Результат программы должен выглядить следующим образом, результат - вывод массива A и B.
Задача принимает два значения N,A, - N является размером массива А, затем вводится сам массив А, пользователем с клавиатуры.
Ссылка на все исходники на GitHub: https://github.com/Snctnm/Assembler
= Блок-схема
#import "@preview/fletcher:0.5.8": diagram, node, edge, shapes

#import shapes: parallelogram

#figure(
  diagram(
    spacing: (2.2em, 3.8em),
    node-stroke: 1pt + black,
    node-fill: none,

    node((0, 0), [Начало], shape: rect, corner-radius: 1em),

    edge("-|>"),

    //Вывод как действие
    node((0, -1), [Ввод данных N и А], shape: rect),

    edge("-|>"),

    //Вывод как действие
    node((0, -2), [Вычисление по заданию], shape: rect),

    edge("-|>"),

    //Вывод как на консоль
    node((0, -3), [Вывод массивов результата],
      shape: parallelogram,
      inset: 1em,
    ),

    edge("-|>"),

    node((0, -4), [Конец], shape: rect, corner-radius: 1em),
  ),

  caption: [Блок-схема программы],
)

= Исходный код программы

Код на ассемблере:
```asm
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
```

= Тестирование
Выполним три сценария тестов по работе программы, с ручным вычислениям и работой программы.

#figure(
  table(
    columns: 4,
    align: center + horizon,
    // stroke: none,
    table.hline(),
    [*Набор тестовых данных *], [*N*], [*A*], [*Результат(массив В)*],
    table.hline(),
    [1], [3],  [$0[0], 2[1], 2[2]$], [$0[0], 2[2]$],
    [2], [0],  [-], [1 <= N <= 31],
    [3], [1],  [2[0]], [none],
    table.hline(),
  ),
  caption: [Копирование массива A в массив B],
)
#figure(
  image("lab4.png"),
  caption: [Результат тестов в программе]
)

= Выводы
В ходе выполнения лабораторной работы была успешно решена задача разработки программы на языке ассемблера ARM64 для копирование через косвенную адресацию из массива А в массив В,
все значения котороые равны своим индексам.

Что было сделано:

Формализация задачи - были выполнены ввод данных N и А, реализованы механизмы отладки для нахождения ошибок и их устранение,
копирование в массив В и её проверка для 0 и отрицательных значений.
Разработка программы - написан код на ассемблере ARM64, включающий:
  1. Выделение и освобождение стека с сохранением регистров
  2. Организацию ввода двуз значений через scanf
  3. Нахождение чисел равных своим индексам
  4. Копирование чисел в массив В
  5. Проверка копирования
  6. Отладка всей программы
  7. Вывод результатов через printf
Тестирование - проведено ручное тестирование для трёх наборов входных данных. Результаты работы программы полностью совпали с теоретическими расчётами.
Итог:
Все поставленные цели лабораторной работы достигнуты. Программа корректно работает на платформе ARM64 macOS,
правильно обрабатывает ввод массива и её размера, выполняет необходимые вычисления для дальнейшего копирования и выводит результат в требуемом формате.

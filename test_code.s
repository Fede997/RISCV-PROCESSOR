.text
    addi    x5, x0, 6           # 00600293
    addi    x6, x0, 10          # 00A00313
    add     x7, x5, x6          # 005303B3
    sub     x28, x6, x5         # 40530E33
    mul     x29, x5, x6         # 02530EB3
    div     x30, x6, x5         # 02534F33
    auipc   x31, 10             # 0000AF97
    sw      x29, 0(x0)          # 01D02223
    lw      x9, 0(x0)           # 00402483

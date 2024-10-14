.data
    string_1: .string "\nlog2(4) = " 
    string_2: .string "\nlog2(10) = "
    string_3: .string "\nlog2(1025) = "
    input_1: .word 4
    input_2: .word 10
    input_3: .word 1025
.text

main:
    # print string_1
    la a0, string_1        # load string_1
    li a7, 4               # print syscall code
    ecall                  # syscall
    # log2(2)
    lw  a0, input_1        # load input_1
    jal ra, log2           # output_1 = log2(2)      
    li a7, 1               # print output_1
    ecall                  # syscall
    # print string_2
    la a0, string_2        # load string_2
    li a7, 4               # print syscall code
    ecall                  # syscall
    # log2(7)
    lw  a0, input_2        # load input_2
    jal ra, log2           # output_1 = log2(2)      
    li a7, 1               # print output_1
    ecall                  # syscall
    # print string_3
    la a0, string_3        # load string_3
    li a7, 4               # print syscall code
    ecall                  # syscall
    # log2(16)
    lw  a0, input_3        # load input_3
    jal ra, log2           # output_1 = log2(2)      
    li a7, 1               # print output_1
    ecall                  # syscall
    # Exit the program
    li a7, 10              # exit syscall
    ecall                  # syscall

# a0 : parameter n
# t0 : temp
log2:
    li t0, 31              # t0 = 31
    mv t3, a0              # t3 = n
# t3 : parameter x
# t4 : r
# t5 : c
# t6 : temp value
my_clz:
    li t4, 0               # r = 0
    li t6, 0x00010000      # tmp = 0x00010000
    sltu t5, t3, t6        # c = (x < 0x00010000)
    slli t5, t5, 4         # c = (x < 0x00010000) << 4;
    add t4, t4, t5         # r += c
    sll t3, t3, t5         # x <<= c

    li t6, 0x01000000
    sltu t5, t3, t6        # c = (x < 0x01000000)
    slli t5, t5, 3         # c = (x < 0x01000000) << 3;
    add t4, t4, t5         # r += c
    sll t3, t3, t5         # x <<= c
    
    li t6, 0x10000000
    sltu t5, t3, t6        # c = (x < 0x10000000)
    slli t5, t5, 2         # c = (x < 0x10000000) << 2;
    add t4, t4, t5         # r += c
    sll t3, t3, t5         # x <<= c
    
    srli t5, t3, 27             
    andi t5, t5, 0x1e      # c = (x >> (32 - 4 - 1))  & 0x1e
    li t3, 0x55af               
    srl t3, t3, t5              
    andi t3, t3, 3              
    add a0, t4, t3         # r + (0x55af >> c) & 3
    
my_clz_end:
    sub a0, t0, a0         # a0 = 31 - my_clz(n)

log2_end:
    ret
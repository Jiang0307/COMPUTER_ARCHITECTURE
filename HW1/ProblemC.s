 .data
    string_1: .string "\nresult_1 = "
    string_2: .string "\nresult_2 =  "
    string_3: .string "\nresult_3 =  "
    string_4: .string "\nresult_4 =  "
    string_5: .string "\nresult_5 =  "
    input_1: .word 0xFFFF
    input_2: .word 0x0710
    input_3: .word 0x80F3
    input_4: .word 0x00FA
    input_5: .word 0x1234
.text

main:
    # print string_1
    la a0, string_1
    li a7, 4               # print syscall code
    ecall                  # syscall
    lw  a0, input_1           
    jal ra, fp16_to_fp32   # result_1 = fp16_to_fp32(0x0710)      
    li a7, 1               # print result_1
    ecall                  # syscall
    # print string_2
    la a0, string_2
    li a7, 4               # print syscall code
    ecall                  # syscall
    lw  a0, input_2           
    jal ra, fp16_to_fp32   # result_2 = fp16_to_fp32(0x0710)      
    li a7, 1               # print result_2
    ecall                  # syscall
    # print string_3
    la a0, string_3
    li a7, 4               # print syscall code
    ecall                  # syscall
    lw  a0, input_3           
    jal ra, fp16_to_fp32   # result_3 = fp16_to_fp32(0x80F3)      
    li a7, 1               # print result_3
    ecall                  # syscall
    # print string_4
    la a0, string_4
    li a7, 4               # print syscall code
    ecall                  # syscall
    lw  a0, input_4       
    jal ra, fp16_to_fp32   # result_4 = fp16_to_fp32(0x80F3)      
    li a7, 1               # print result_4
    ecall                  # syscall
    # print string_5
    la a0, string_5
    li a7, 4               # print syscall code
    ecall                  # syscall
    lw  a0, input_5
    jal ra, fp16_to_fp32   # result_5 = fp16_to_fp32(0x80F3)      
    li a7, 1               # print result_5
    ecall                  # syscall
    # exit program
    li a7, 10              # exit syscall code
    ecall                  # syscall

# a0 : h
# t0 : w
# t1 : sign
# t2 : nonsign
# t3 : renorm_shift
# t4 : inf_nan_mask 
# t5 : zero_mask 
# t6 : temp value
fp16_to_fp32:
    slli t0, a0, 16        # w = h << 16;

    li t6, 0x80000000      # UINT32_C(0x80000000)
    and t1, t0, t6         # sign = w & UINT32_C(0x80000000);
    
    li t6, 0x7FFFFFFF      # UINT32_C(0x7FFFFFFF)
    and t2, t0, t6         # nonsign = w & UINT32_C(0x7FFFFFFF);
    
    mv t3, t2              # t3 : argument for my_clz
    
# t3 : parameter x
# t4 : r
# t5 : c
# t6 : temp value
my_clz:
    li t4, 0                    # r = 0
    li t6, 0x00010000           # tmp = 0x00010000
    sltu t5, t3, t6             # c = (x < 0x00010000)
    slli t5, t5, 4              # c = (x < 0x00010000) << 4;
    add t4, t4, t5              # r += c
    sll t3, t3, t5              # x <<= c

    li t6, 0x01000000
    sltu t5, t3, t6             # c = (x < 0x01000000)
    slli t5, t5, 3              # c = (x < 0x01000000) << 3;
    add t4, t4, t5              # r += c
    sll t3, t3, t5              # x <<= c
    
    li t6, 0x10000000
    sltu t5, t3, t6             # c = (x < 0x10000000)
    slli t5, t5, 2              # c = (x < 0x10000000) << 2;
    add t4, t4, t5              # r += c
    sll t3, t3, t5              # x <<= c
    
    srli t5, t3, 27             
    andi t5, t5, 0x1e           # c = (x >> (32 - 4 - 1))  & 0x1e
    li t3, 0x55af               
    srl t3, t3, t5              # (0x55af >> c)
    andi t3, t3, 3              # (0x55af >> c) & 3
    add t3, t4, t3              # renorm_shift = r + (0x55af >> c) & 3
my_clz_end:
    
# renorm_shif_begin
    li t6, 5
    bgtu t3, t6, greater_than_5
less_than_5:
    li t3, 0               # renorm_shift = 0
    j renorm_shift_end     
        
greater_than_5:
    sub t3, t3, t6         # renorm_shift = renorm_shitft - 5

renorm_shift_end:
    li t6, 0x04000000      
    add t4, t2, t6         # inf_nan_mask = (nonsign + 0x04000000)			
    srai t4, t4, 8         # inf_nan_mask = (nonsign + 0x04000000) >> 8
    li t6, 0x7F800000
    and t4, t4, t6         # inf_nan_mask = ((nonsign + 0x04000000) >> 8) & INT32_C(0x7F800000)
        
    li t6, 1
    sub t5, t2, t6         # zero_mask = (nonsign - 1)
    srai t5, t5, 31        # zero_mask = (nonsign - 1) >> 31
        
return_sign:
#    return sign | ((((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)) | inf_nan_mask) & ~zero_mask);
    sll t2, t2, t3         # nonsign << renorm_shift
    srli t2, t2, 3         # (nonsign << renorm_shift >> 3)
    li t6, 0x70
    sub t3, t6, t3         # 0x70 - renorm_shift
    slli t3, t3, 23        # ((0x70 - renorm_shift) << 23)
    add t2, t2, t3         # (((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)))
    or t2, t2, t4          # (((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)) | inf_nan_mask)
    not t5, t5             # ~zero_mask
    and t2, t2, t5         # ((((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)) | inf_nan_mask) & ~zero_mask)
    mv a0, t1              # a0 = sign
    or a0, a0, t2          # sign | ((((nonsign << renorm_shift >> 3) + ((0x70 - renorm_shift) << 23)) | inf_nan_mask) & ~zero_mask)
    ret
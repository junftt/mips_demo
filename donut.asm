    # ported from https://www.dropbox.com/s/79ga2m7p2bnj1ga/donut_deobfuscated.c?dl=0
    .data
    # float A = 0, B = 0;
    A: .float 0.0
    B: .float 0.0
    z: .space 7040 # float z[1760]
    b: .space 1760 # char b[1760]

    CHARS:
    .byte 46
    .byte 44
    .byte 45
    .byte 126
    .byte 58
    .byte 59
    .byte 61
    .byte 33
    .byte 42
    .byte 35
    .byte 36
    .byte 64

    RAF_EVENT: .asciiz "raf"
    last_frame_time: .word 0
    FPS: .asciiz "FPS: "

    .text

    # @param a0 buf address
    # @param a1 byte value
    # @param a2 num of bytes
    memset:
        memset_loop_start:
        blez $a2 memset_loop_done
            sb $a1 0($a0)
            addi $a0 $a0 1
            addi $a2 $a2 -1
            j memset_loop_start
        memset_loop_done:
        jr $ra

    # v0: current frame time
    render_frame:
        addi $sp $sp -8
        sw $ra 4($sp)
        sw $s0 0($sp)
        move $s0 $v0 # $s0 = current frame time

la $a0 RAF_EVENT
la $a1 render_frame
li $v0 300
syscall

li $v0 401
syscall
    # memset(b,32,1760);
    # memset(z,0,7040);
        la $a0 b
        li $a1 32
        li $a2 1760
        jal memset
        la $a0 z
        li $a1 0
        li $a2 7040
        jal memset

        # for(j=0; j < 6.28; j += 0.07)
        li.s $f12 0.0 # j = 0
        render_frame_j_loop_start:
        li.s $f31 6.28
        c.ge.s $f12 $f31
        bc1t render_frame_j_loop_done
            # for(i=0; i < 6.28; i += 0.02)
            li.s $f11 0.0 # i = 0
            render_frame_i_loop_start:
            li.s $f31 6.28
            c.ge.s $f11 $f31
            bc1t render_frame_i_loop_done

            # float c:$f0 = sin(i:$f11)
            sin $f0 $f11
            # float l:$f1 = cos(i:$f11)
            cos $f1 $f11
            # float d:$f2 = cos(j:$f12)
            cos $f2 $f12
            # float f:$f3 = sin(j:$f12)
            sin $f3 $f12
        
            la $t7 A
            l.s $f31 0($t7) # $f31 = A
            # float e:$f4 = sin(A:$f31)
            sin $f4 $f31
            # float g:$f5 = cos(A:$f31)
            cos $f5 $f31
        
            la $t7 B
            l.s $f31 0($t7) # $f31 = B
            # float n:$f6 = sin(B:$f31)
            sin $f6 $f31
            # float m:$f7 = cos(B:$f31)
            cos $f7 $f31

            # float h:$f8 = d:$f2 + 2;
            li.s $f31 2.0
            add.s $f8 $f2 $f31
            # float D:$f9 = 1 / (c:$f0 * h:$f8 * e:$f4 + f:$f3 * g:$f5 + 5);
            li.s $f31 5.0
            mul.s $f30 $f3 $f5
            add.s $f31 $f31 $f30
            mul.s $f30 $f0 $f8
            mul.s $f30 $f30 $f4
            add.s $f31 $f31 $f30
            li.s $f30 1.0
            div.s $f9 $f30 $f31
            # float t:$f10 = c:$f0 * h:$f8 * g:$f5 - f:$f3 * e:$f4;
            mul.s $f31 $f3 $f4
            mul.s $f30 $f0 $f8
            mul.s $f30 $f30 $f5
            sub.s $f10 $f30 $f31
        
            # $f31 = l:$f1 * h:$f8 * m:$f7 - t:$f10 * n:$f6
            mul.s $f31 $f1 $f8
            mul.s $f31 $f31 $f7
            mul.s $f30 $f10 $f6
            sub.s $f31 $f31 $f30
            # int x:$t2 = 40 + 30 * D:$f9 * $f31;
            li.s $f30 30.0
            mul.s $f31 $f31 $f30
            mul.s $f31 $f31 $f9
            li.s $f30 40.0
            add.s $f31 $f30 $f31
            cvt.w.s $f31 $f31
            mfc1 $t2 $f31

            # $f31 = l:$f1 * h:$f8 * n:$f6 + t:$f10 * m:$f7
            mul.s $f31 $f1 $f8
            mul.s $f31 $f31 $f6
            mul.s $f30 $f10 $f7
            add.s $f31 $f31 $f30
            # int y:$t3 = 12 + 15 * D:$f9 * $f31;
            li.s $f30 15.0
            mul.s $f31 $f31 $f30
            mul.s $f31 $f31 $f9
            li.s $f30 12.0
            add.s $f31 $f30 $f31
            cvt.w.s $f31 $f31
            mfc1 $t3 $f31

            # int o:$t4 = x:$t2 + 80 * y:$t3;
            li $t7 80
            mult $t7 $t3
            mflo $t4
            add $t4 $t2 $t4

            # int N:$t5 = 8 * ((f:$f3 * e:$f4 - c:$f0 * d:$f2 * g:$f5) * m:$f7
                            # - c:$f0 * d:$f2 * e:$f4 - f:$f3 * g:$f5 - l:$f1 * d:$f2 * n:$f6);
            mul.s $f31 $f3 $f4
            mul.s $f30 $f0 $f2
            mul.s $f30 $f30 $f5
            sub.s $f31 $f31 $f30 # $f31 = f:$f3 * e:$f4 - c:$f0 * d:$f2 * g:$f5
            mul.s $f31 $f31 $f7 # $f31 *= m:$f7
            mul.s $f30 $f0 $f2
            mul.s $f30 $f30 $f4
            sub.s $f31 $f31 $f30 # $f31 -= c:$f0 * d:$f2 * e:$f4
            mul.s $f30 $f3 $f5
            sub.s $f31 $f31 $f30 # $f31 -= f:$f3 * g:$f5
            mul.s $f30 $f1 $f2
            mul.s $f30 $f30 $f6
            sub.s $f31 $f31 $f30 # $f31 -= l:$f1 * d:$f2 * n:$f6
            li.s $f30 8.0
            mul.s $f31 $f31 $f30 # $f31 *= 8
            cvt.w.s $f31 $f31
            mfc1 $t5 $f31

            # if(22 > y:$t3 && y:$t3 > 0 && x:$t2 > 0 && 80 > x:$t2 && D:$f9 > z[o]) {
            li $t7 22
            ble $t7 $t3 render_frame_skip_update
            li $t7 0
            ble $t3 $t7 render_frame_skip_update
            ble $t2 $t7 render_frame_skip_update
            li $t7 80
            ble $t7 $t2 render_frame_skip_update

            # $f31 = z[o]
            la $t7 z
            li $t6 4
            mult $t6 $t4
            mflo $t6
            add $t7 $t7 $t6 # $t7 = &(z[o])
            l.s $f31 0($t7)
            c.le.s $f9 $f31
            bc1t render_frame_skip_update

            ## begin update z, b
            # z[o] = D;
            s.s $f9 0($t7)

            # $t5: N
            # b[o] = ".,-~:;=!*#$@"[N > 0 ? N : 0];
            li $t6 0
            ble $t5 $t6 negative_N_skip
            move $t6 $t5
            negative_N_skip:
            # $t6 = N > 0 ? N : 0
            la $t7 CHARS
            add $t7 $t7 $t6
            lb $t6 0($t7) # $t6 holds the character to be printed

            la $t7 b
            add $t7 $t7 $t4 # $t7 = &(b[o])
            sb $t6 0($t7)
            ## end update z, b
            render_frame_skip_update:
            # i+=0.02
            li.s $f31 0.02
            add.s $f11 $f11 $f31
            j render_frame_i_loop_start
            render_frame_i_loop_done:
            # j+=0.07
            li.s $f31 0.07
            add.s $f12 $f12 $f31
            j render_frame_j_loop_start
        render_frame_j_loop_done:

        la $t0 last_frame_time
        lw $t1 0($t0) # $t1 = last_frame_time
        sub $t1 $s0 $t1 # $t1 = delta time
        sw $s0 0($t0) # last_frame_time = current frame time
        blez $t1 skip_print_fps

        li $v0 4 # print string
        la $a0 FPS
        syscall
        li $t0 1000
        div $t0 $t1
        mflo $a0 # $a0 = 1000/frame_time = FPS
        li $v0 1
        syscall
        skip_print_fps:
        li $v0 11
        li $a0 32 #space
        syscall
        li $a0 10 #\n
        syscall

        la $t0 A
        l.s $f0 0($t0)
        la $t0 B
        l.s $f1 0($t0)
        li.s $f2 0.00002

        li $t0 0
        li $t1 1761
        render_frame_putchar_loop_start:
        bge $t0 $t1 render_frame_putchar_loop_done
            li $t2 80
            div $t0 $t2
            li $a0 10
            mfhi $t2
            beqz $t2 skip_char
            #li $a0 97
            la $t2 b
            add $t2 $t2 $t0 # $t2=&(b[k])
            lb $a0 0($t2)
            skip_char:
#############################terminal print
            li $v0 11
            syscall
#############################terminal print
            addi $t0 $t0 1
            add.s $f0 $f0 $f2
            add.s $f0 $f0 $f2 # A+=0.00002+0.00002
            add.s $f1 $f1 $f2 # B+=0.00002+0.00002
            j render_frame_putchar_loop_start
        render_frame_putchar_loop_done:
        la $t0 A
        s.s $f0 0($t0)
        la $t0 B
        s.s $f1 0($t0)

        lw $ra 4($sp)
        lw $s0 0($sp)
        addi $sp $sp 8
        jr $ra

    .main
    jal render_frame
li $v0 999
syscall

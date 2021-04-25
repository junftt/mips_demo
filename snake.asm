.data
BLOCK_SIZE: .word 10
HOWMANY_BEANS: .word 3
SNAKE_MAXLEN: .word 10
SNAKE_INILEN: .word 3
CANVAS_WIDTH: .word 200
CANVAS_HEIGHT: .word 400

horizontal_speed: .word 0
vertical_speed: .word -10

TIMEOUT_EVENT: .asciiz "timeout"
KEYDOWN_EVENT: .asciiz "keydown"

score: .word 0

snake_curlen: .word 0

snakex: .word 99999 99999 99999 99999 99999 99999 99999 99999 99999 99999
snakey: .word 99999 99999 99999 99999 99999 99999 99999 99999 99999 99999

beansx: .word 99999 99999 99999 99999 99999
beansy: .word 99999 99999 99999 99999 99999

.text
fun_collect:
    addScore:
        la $t0 score
        lw $t1 0($t0)
        addi $t1 $t1 1
        sw $t1 0($t0)
        jr $ra

    resetScore:
        la $t0 score
        li $t1 0
        sw $t1 0($t0) #bug: $0?
        jr $ra

    drawSnake:
        #fillStyle
        li $a0 0
        li $a1 0
        li $a2 255
        li $v0 103
        syscall

        li $t0 0 #index
        while0_drawSnake:
        #check length
        la $t1 snake_curlen
        lw $t1 0($t1)
        bge $t0 $t1 return_drawSnake

        li $t1 4
        mult $t0 $t1
        mflo $t1
        la $t2 snakex
        add $t1 $t1 $t2
        lw $t1 0($t1)
        # $t1 snakex coor
        li $t2 99999
        beq $t1 $t2 return_drawSnake

        li $t2 4
        mult $t0 $t2
        mflo $t2
        la $t3 snakey
        add $t2 $t2 $t3
        lw $t2 0($t2) # $t2 snakey coor

        la $t3 BLOCK_SIZE
        lw $t3 0($t3) # $t3 block size

        move $a0 $t1
        move $a1 $t2
        move $a2 $t3
        move $a3 $t3
        li $v0 101
        syscall

        addi $t0 $t0 1
        j while0_drawSnake
        return_drawSnake:
        jr $ra

    clearSnake:
        addi $sp $sp -16
        sw $ra 0($sp)
        sw $s0 4($sp)
        sw $s1 8($sp)
        sw $s2 12($sp)

        la $s0 snake_curlen
        lw $s0 0($s0)
        addi $s0 $s0 -1

        bltz $s0 clearSnake_return #bug

        la $a0 snakex
        move $a1 $s0
        jal getWordInArray
        move $s1 $v0 # $s1 snake x 

        la $a0 snakey
        move $a1 $s0
        jal getWordInArray
        move $s2 $v0 # $s2 snake y

        la $t0 BLOCK_SIZE
        lw $t0 0($t0)

        move $a0 $s1
        move $a1 $s2
        move $a2 $t0
        move $a3 $t0

        li $v0 102
        syscall

        clearSnake_return:
        lw $ra 0($sp)
        lw $s0 4($sp)
        lw $s1 8($sp)
        lw $s2 12($sp)
        addi $sp $sp 16
        jr $ra

    # $a0 adr
    # $v0 return val
    getWord:
    lw $v0 0($a0)
    jr $ra

    # $a0 adr, $a1 val
    setWord:
    sw $a1 0($a0)
    jr $ra

    # arg: $a0 head of data var, $a1 index
    # return_val: $v0
    getWordInArray:
        li $t0 4
        mult $a1 $t0
        mflo $t0
        add $t0 $a0 $t0
        lw $v0 0($t0)
        jr $ra

    # arg: $a0 head of data var, $a1 index, $a2 val
    setWordInArray:
        li $t0 4
        mult $a1 $t0
        mflo $t0
        add $t0 $a0 $t0
        sw $a2 0($t0)
        jr $ra

    # rand syscall 45
    # $a0 lo
    # $a1 up
    # $a2 unit
    # $v0 xcoor
    # $v1 ycoor
    generatePosition:
        li $a0 0
        la $a1 CANVAS_WIDTH
        lw $a1 0($a1)
        la $a2 BLOCK_SIZE
        lw $a2 0($a2)
        li $v0 45
        syscall
        move $t0 $v0 #$t0 xcoor

        li $a0 0
        la $a1 CANVAS_HEIGHT
        lw $a1 0($a1)
        la $a2 BLOCK_SIZE
        lw $a2 0($a2)
        li $v0 45
        syscall 
        move $t1 $v0 #$t0 xcoor

        move $v0 $t0
        move $v1 $t1

        jr $ra

    generateOneProperBeans:
        addi $sp $sp -20
        sw $ra 0($sp)
        sw $s0 4($sp)
        sw $s1 8($sp)
        sw $s2 12($sp)
        sw $s3 16($sp)

        gen_while:
            jal generatePosition
            move $s0 $v0 # $s0 beans xcoor
            move $s1 $v1 # $s1 beans ycoor

            la $s2 snake_curlen
            lw $s2 0($s2) # snake curlen
            li $s3 0 #snake i
            snake_travel_loop:
            bge $s3 $s2 exit_snake_travel_loop
                la $a0 snakex
                move $a1 $s3
                jal getWordInArray
                bne $s0 $v0 con_snake_travel_loop

                la $a0 snakey
                move $a1 $s3
                jal getWordInArray
                bne $s1 $v0 con_snake_travel_loop

                j gen_while

                con_snake_travel_loop:
                addi $s3 $s3 1 # i++
                j snake_travel_loop
            exit_snake_travel_loop:

            la $s2 HOWMANY_BEANS
            lw $s2 0($s2) # $s2 bound
            li $s3 0 # $s3 index
            beans_selfcheck_loop:
            bge $s3 $s1 exit_beans_selfcheck_loop
                la $a0 beansx
                move $a1 $s3
                jal getWordInArray
                bne $s0 $v0 con_beans_selfcheck_loop

                la $a0 beansy
                move $a1 $s3
                jal getWordInArray
                bne $s1 $v0 con_beans_selfcheck_loop

                j gen_while
            con_beans_selfcheck_loop:
            addi $s3 $s3 1
            j beans_selfcheck_loop
            exit_beans_selfcheck_loop:

        move $v0 $s0 # $v0 beans xcoor
        move $v1 $s1 # $v1 beans ycoor

        lw $ra 0($sp)
        lw $s0 4($sp)
        lw $s1 8($sp)
        lw $s2 12($sp)
        lw $s3 16($sp)
        addi $sp $sp 20
        jr $ra
    

    drawBean:
        addi $sp $sp -24
        sw $ra 0($sp)
        sw $s0 4($sp)
        sw $s1 8($sp)
        sw $s2 12($sp)
        sw $s3 16($sp)
        sw $s4 20($sp)

        # fillstyle
        li $a0 255
        li $a1 0
        li $a2 0
        li $v0 103
        syscall

        la $s0 HOWMANY_BEANS
        lw $s0 0($s0) # beans len
        li $s1 0 # i beans index

        beans_travel_loop:
        bge $s1 $s0 exit_beans_travel_loop
        
        jal generateOneProperBeans
        move $s3 $v0
        move $s4 $v1

        #set the xcoor and ycoor into beans arr
        la $a0 beansx
        move $a1 $s1
        move $a2 $s3
        jal setWordInArray

        la $a0 beansy
        move $a1 $s1
        move $a2 $s4
        jal setWordInArray

        #draw the beans[i]
        la $t0 BLOCK_SIZE
        lw $t0 0($t0)

        move $a0 $s3
        move $a1 $s4
        move $a2 $t0
        move $a3 $t0

        li $v0 101
        syscall

        addi $s1 $s1 1 # i++
        j beans_travel_loop
        exit_beans_travel_loop:
        lw $ra 0($sp)
        lw $s0 4($sp)
        lw $s1 8($sp)
        lw $s2 12($sp)
        lw $s3 16($sp)
        lw $s4 20($sp)
        addi $sp $sp 24
        jr $ra
    
    resetGame:
        addi $sp $sp -20
        sw $ra 0($sp)
        sw $s0 4($sp)
        sw $s1 8($sp)
        sw $s2 12($sp)
        sw $s3 16($sp)

        # clear canvas
        li $a0 0
        li $a1 0
        la $a2 CANVAS_WIDTH
        lw $a2 0($a2)
        la $a3 CANVAS_HEIGHT
        lw $a3 0($a3)
        li $v0 102
        syscall

        #bug: 越界？
        jal generatePosition# $v0 xoor $v1 yoor
        move $s0 $v0
        move $s1 $v1

        la $s2 SNAKE_INILEN
        lw $s2 0($s2) #bound
        li $s3 0 #index
        reset_snake_loop:
        bge $s3 $s2 exit_reset_snake_loop
            la $a0 snakex
            move $a1 $s3
            move $a2 $s0
            jal setWordInArray

            la $t0 BLOCK_SIZE
            lw $t0 0($t0)
            mult $t0 $s3
            mflo $t0
            add $t0 $t0 $s1
            
            la $a0 snakey
            move $a1 $s3
            move $a2 $t0
            jal setWordInArray
        addi $s3 $s3 1
        j reset_snake_loop
        exit_reset_snake_loop:

        # set snake cur len
        la $a0 SNAKE_INILEN
        jal getWord
        move $s0 $v0
        la $a0 snake_curlen
        move $a1 $s0
        jal setWord

        jal drawBean

        la $a0 horizontal_speed
        li $a1 0
        jal setWord

        la $t0 BLOCK_SIZE
        lw $t0 0($t0)
        li $t1 -1
        mult $t0 $t1
        la $a0 vertical_speed
        mflo $a1
        jal setWord

        jal resetScore

        lw $ra 0($sp)
        lw $s0 4($sp)
        lw $s1 8($sp)
        lw $s2 12($sp)
        lw $s3 16($sp)
        addi $sp $sp 20
        jr $ra


    snakeMove:
        # setTimeout(snakeMove, 1000 / 5);
        la $a0 TIMEOUT_EVENT
        la $a1 snakeMove
        li $a2 200
        li $v0 300
        syscall

        addi $sp $sp -24
        sw $ra 0($sp)
        sw $s0 4($sp)
        sw $s1 8($sp)
        sw $s2 12($sp)
        sw $s3 16($sp)
        sw $s4 20($sp)

        la $a0 snake_curlen
        jal getWord
        move $s0 $v0 # $s0 bound
        li $s1 1 #index

        la $a0 snakex
        li $a1 0
        jal getWordInArray
        move $s2 $v0 # $s2 snake head x
        la $a0 snakey
        li $a1 0
        jal getWordInArray
        move $s3 $v0 # $s3 snake head y

        snake_self_ImpactCheck:
        bge $s1 $s0 exit_snake_self_ImpactCheck
            la $a0 snakex
            move $a1 $s1
            jal getWordInArray
            bne $s2 $v0 con_snake_self_ImpactCheck
            la $a0 snakey
            move $a1 $s1
            jal getWordInArray
            bne $s3 $v0 con_snake_self_ImpactCheck

            #bug: alert syscall?
            jal resetGame
            j exit_snakeMove
            con_snake_self_ImpactCheck:
        addi $s1 $s1 1
        j snake_self_ImpactCheck
        exit_snake_self_ImpactCheck:

        move $s0 $s2 # $s0 snake head x
        move $s1 $s3 # $s1 snake head y

        la $a0 CANVAS_WIDTH
        jal getWord
        move $s2 $v0 # $s2 CANVAS_WIDTH
        la $a0 CANVAS_HEIGHT
        jal getWord
        move $s3 $v0 # $s3 CANVAS_HEIGHT
        # bound check
        bgez $s0 con_xboundCheck
            add $a2 $s0 $s2
            la $a0 snakex
            li $a1 0
            jal setWordInArray
        j yboundCheck
        con_xboundCheck:
        blt $s0 $s2 yboundCheck
            sub $a2 $s0 $s2
            la $a0 snakex
            li $a1 0
            jal setWordInArray

        yboundCheck:
        bgez $s1 con_yboundCheck
            add $a2 $s1 $s3
            la $a0 snakey
            li $a1 0
            jal setWordInArray
        j exit_boundCheck
        con_yboundCheck:
        blt $s1 $s3 exit_boundCheck
            sub $a2 $s1 $s3
            la $a0 snakey
            li $a1 0
            jal setWordInArray
        exit_boundCheck:

        move $a0 $s0
        move $a1 $s1
        jal scoreCheck
        # $v0 dec

        li $t0 1
        bne $v0 $t0 con_snakeMove
            la $s0 snake_curlen
            lw $s0 0($s0) # $s0 snake_curlen
            la $t0 SNAKE_MAXLEN
            lw $t0 0($t0)# $t0 SNAKE_MAXLEN
            blt $s0 $t0 push_snake
                jal resetGame
                j exit_snakeMove
            push_snake:
                la $a0 snakex
                addi $a1 $s0 -1
                jal getWordInArray

                la $a0 snakex
                move $a1 $s0
                move $a2 $v0
                jal setWordInArray

                la $a0 snakey
                addi $a1 $s0 -1
                jal getWordInArray

                la $a0 snakey
                move $a1 $s0
                move $a2 $v0
                jal setWordInArray

                la $a0 snake_curlen
                addi $a1 $s0 1
                jal setWord

        con_snakeMove:
        
        jal updateSnakeFrame

        exit_snakeMove:
        lw $ra 0($sp)
        lw $s0 4($sp)
        lw $s1 8($sp)
        lw $s2 12($sp)
        lw $s3 16($sp)
        lw $s4 20($sp)
        addi $sp $sp 24
        jr $ra

    # $a0 snake head x
    # $a1 snake head y
    # $v0 dec
    scoreCheck:
        addi $sp $sp -24
        sw $ra 0($sp)
        sw $s0 4($sp)
        sw $s1 8($sp)
        sw $s2 12($sp)
        sw $s3 16($sp)
        sw $s4 20($sp)

        move $s0 $a0 # $s0 snake head x
        move $s1 $a1 # $s1 snake head y

        la $s2 HOWMANY_BEANS
        lw $s2 0($s2) # $s2 bound
        li $s3 0 # $s3 index
        li $s4 0 # dec
        eatCheck_loop:
        bge $s3 $s2 exit_eatCheck_loop
            la $a0 beansx
            move $a1 $s3
            jal getWordInArray
            bne $s0 $v0 con_eatCheck_loop

            la $a0 beansy
            move $a1 $s3
            jal getWordInArray
            bne $s1 $v0 con_eatCheck_loop

            li $s4 1 # dec = 1

            jal generateOneProperBeans
            move $s0 $v0 # $s0 new beans x
            move $s1 $v1 # $s1 new beans y

            la $a0 beansx
            move $a1 $s3
            move $a2 $s0
            jal setWordInArray
            la $a0 beansy
            move $a1 $s3
            move $a2 $s1
            jal setWordInArray

            # fillstyle
            li $a0 255
            li $a1 0
            li $a2 0
            li $v0 103
            syscall

            #draw the new bean
            la $t0 BLOCK_SIZE
            lw $t0 0($t0)

            move $a0 $s0
            move $a1 $s1
            move $a2 $t0
            move $a3 $t0

            li $v0 101
            syscall

            j exit_eatCheck_loop
        con_eatCheck_loop:
        addi $s3 $s3 1
        j eatCheck_loop
        exit_eatCheck_loop:

        move $v0 $s4 # $v0 dec

        exit_scoreCheck:
        lw $ra 0($sp)
        lw $s0 4($sp)
        lw $s1 8($sp)
        lw $s2 12($sp)
        lw $s3 16($sp)
        lw $s4 20($sp)
        addi $sp $sp 24
        jr $ra

    updateSnakeFrame:
        addi $sp $sp -20
        sw $ra 0($sp)
        sw $s0 4($sp)
        sw $s1 8($sp)

        jal clearSnake
        la $s0 snake_curlen

        lw $s0 0($s0)

        addi $s0 $s0 -1 # $s0 index
        updateSnakeCoor_loop:
        blez $s0 exit_updateSnakeCoor_loop
            la $a0 snakex
            addi $a1 $s0 -1
            jal getWordInArray
            move $s1 $v0

            la $a0 snakex
            move $a1 $s0
            move $a2 $s1
            jal setWordInArray

            la $a0 snakey
            addi $a1 $s0 -1
            jal getWordInArray
            move $s1 $v0

            la $a0 snakey
            move $a1 $s0
            move $a2 $s1
            jal setWordInArray
        addi $s0 $s0 -1
        j updateSnakeCoor_loop
        exit_updateSnakeCoor_loop:

        la $a0 snakex
        li $a1 0
        jal getWordInArray
        move $s0 $v0

        la $a0 horizontal_speed
        jal getWord
        add $a2 $s0 $v0
        la $a0 snakex
        li $a1 0
        jal setWordInArray

        la $a0 snakey
        li $a1 0
        jal getWordInArray
        move $s0 $v0

        la $a0 vertical_speed
        jal getWord
        add $a2 $s0 $v0
        la $a0 snakey
        li $a1 0
        jal setWordInArray

        jal drawSnake

        lw $ra 0($sp)
        lw $s0 4($sp)
        lw $s1 8($sp)
        addi $sp $sp 20
        jr $ra

    onkeydown:
        addi $sp $sp -4
        sw $ra 0($sp)

        li $t0 87 # w/87, up/38
        beq $v0 $t0 caseup
        li $t0 38
        beq $v0 $t0 caseup
        
        li $t0 83 # s/83, down/40
        beq $v0 $t0 casedown
        li $t0 40
        beq $v0 $t0 casedown

        
        li $t0 65 # a/65, left/37
        beq $v0 $t0 caseleft
        li $t0 37
        beq $v0 $t0 caseleft

        
        li $t0 68 # d/68, right/39
        beq $v0 $t0 caseright
        li $t0 39
        beq $v0 $t0 caseright
        j onkeydown_done
        
        caseup:
            la $t0 vertical_speed
            lw $t0 0($t0)
            bnez $t0 onkeydown_done
                la $a0 horizontal_speed
                li $a1 0
                jal setWord

                la $a0 BLOCK_SIZE
                jal getWord
                li $t0 -1
                mult $v0 $t0
                mflo $a1
                la $a0 vertical_speed
                jal setWord
        j onkeydown_done
        casedown:
            la $t0 vertical_speed
            lw $t0 0($t0)
            bnez $t0 onkeydown_done
                la $a0 horizontal_speed
                li $a1 0
                jal setWord

                la $a0 BLOCK_SIZE
                jal getWord
                move $a1 $v0
                la $a0 vertical_speed
                jal setWord
        j onkeydown_done
        caseleft:
            la $t0 horizontal_speed
            lw $t0 0($t0)
            bnez $t0 onkeydown_done
                la $a0 vertical_speed
                li $a1 0
                jal setWord

                la $a0 BLOCK_SIZE
                jal getWord
                li $t0 -1
                mult $v0 $t0
                mflo $a1
                la $a0 horizontal_speed
                jal setWord
        j onkeydown_done
        caseright:
            la $t0 horizontal_speed
            lw $t0 0($t0)
            bnez $t0 onkeydown_done
                la $a0 vertical_speed
                li $a1 0
                jal setWord

                la $a0 BLOCK_SIZE
                jal getWord
                move $a1 $v0
                la $a0 horizontal_speed
                jal setWord
        j onkeydown_done # ???

        ##################
        la $a0 horizontal_speed
        jal getWord
        move $a0 $v0
        li $v0 1
        syscall

        la $a0 vertical_speed
        jal getWord
        move $a0 $v0
        li $v0 1
        syscall

        onkeydown_done:
        lw $ra 0($sp)
        addi $sp $sp 4

        jr $ra
.main
    #create a canvas
    la $a0 CANVAS_WIDTH
    lw $a0 0($a0)
    la $a1 CANVAS_HEIGHT
    lw $a1 0($a1)
    li $v0 100
    syscall
    
    li $v0 300
    la $a0 KEYDOWN_EVENT
    la $a1 onkeydown
    syscall

    jal resetGame
    jal snakeMove

    li $v0 999
    syscall

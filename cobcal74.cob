      *>>SOURCE FORMAT IS FIXED
       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBCAL74.
      *    THIS CODE WAS MEANT TO COMPILE IN COBOL 74.
      *    (IT SHOULD RUN IN A TK4- ENVIRONMENT)
       AUTHOR. MANNY JUAN.
       DATE-WRITTEN. 10/17/2025.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  INPUT-EXPR          PIC X(80) VALUE SPACES.
       01  FILLER REDEFINES INPUT-EXPR.
         03  INPUT-EXPR-CH PIC X(01) OCCURS 80 TIMES.
       01  CURR-POS            PIC 999 VALUE 1.
       01  EXPR-LEN            PIC 999 VALUE 0.

       01  VALUE-STACK.
           05  VAL-VALUES          COMP-2 OCCURS 50 TIMES.
           05  VAL-VALUE-TOP       PIC 99 VALUE 0.

       01  VAL-TOP-HISTORY.
           05  VAL-TOP-AT-OPEN     OCCURS 50 TIMES PIC 99.
       01  OP-STACK.
           05  OPS             PIC X OCCURS 50 TIMES.
           05  OP-TOP          PIC 99 VALUE 0.

              01  TEMP-CHAR           PIC X.
       01  TEMP-CHAR-VAL REDEFINES TEMP-CHAR PIC 9.
       01  TEMP-NUM            COMP-2  VALUE 0.
       01  WHOLE-NUMBER        PIC S9(15) COMP-3 VALUE 1.
       01  DENOM               PIC S9(13) COMP-3 VALUE 1.
       01  DENOM-MULT          PIC S9(03) COMP-3 VALUE 1.
       01  WRK-RESULT PIC Z(9)9.99999-.

       01  LEFT-VAL            COMP-2.
       01  RIGHT-VAL           COMP-2.
       01  RESULT              COMP-2.

       01  PREC-CURR           PIC 9 VALUE 0.
       01  PREC-TOP            PIC 9 VALUE 0.
       01  EARLY-EXIT         PIC 9 VALUE 0.
       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY 'ENTER EXPRESSION (OR END): '.
           ACCEPT INPUT-EXPR.
           PERFORM CALC-REPL UNTIL INPUT-EXPR='END'.
           STOP RUN.

       CALC-REPL.
           PERFORM FIND-LEN VARYING EXPR-LEN FROM 80 BY -1
           UNTIL EXPR-LEN = 1
            OR INPUT-EXPR-CH (EXPR-LEN) NOT = SPACE.
           display 'expr-len=' expr-len
           PERFORM SOLVE-EXPR.
           ACCEPT INPUT-EXPR.

       FIND-LEN.
           EXIT.

       SOLVE-EXPR.
           DISPLAY 'EXP = ' INPUT-EXPR
           PERFORM INIT-STACKS.
           PERFORM SCAN-LOOP THRU SCAN-LOOP-EXIT
               UNTIL CURR-POS > EXPR-LEN.
           PERFORM APPLY-REMAINING-OPS.
           MOVE VAL-VALUES(1) TO RESULT.
           MOVE RESULT TO WRK-RESULT
           DISPLAY 'ANS = ' WRK-RESULT.

       INIT-STACKS.
           MOVE 0 TO   VAL-VALUE-TOP.
           MOVE 0 TO OP-TOP.
           MOVE 1 TO CURR-POS.

       SCAN-LOOP.
           MOVE INPUT-EXPR-CH(CURR-POS) TO TEMP-CHAR.
      *    DISPLAY '>>> SCANNING POS ' CURR-POS ' CHAR=[' TEMP-CHAR ']'
           IF TEMP-CHAR = SPACE
               ADD 1 TO CURR-POS
               GO TO SCAN-LOOP-EXIT.

           IF TEMP-CHAR IS NUMERIC OR TEMP-CHAR = '.'
               PERFORM PARSE-NUMBER
               GO TO SCAN-LOOP-EXIT.

           IF TEMP-CHAR = '('
               ADD 1 TO OP-TOP
               MOVE '(' TO OPS(OP-TOP)
               MOVE VAL-VALUE-TOP TO VAL-TOP-AT-OPEN(OP-TOP)
               ADD 1 TO CURR-POS
               GO TO SCAN-LOOP-EXIT.

           IF TEMP-CHAR = ')'
               PERFORM APPLY-UNTIL-OPEN-PAREN
               ADD 1 TO CURR-POS
               GO TO SCAN-LOOP-EXIT.

           IF TEMP-CHAR = '+'
      *> Unary '+' is ignored; binary '+' handled normally
               IF VAL-VALUE-TOP > 0
      *> This is binary plus
                   MOVE 1 TO PREC-CURR
                   PERFORM APPLY-WHILE-HIGHER-OR-EQUAL
                   ADD 1 TO OP-TOP
                   MOVE '+' TO OPS(OP-TOP)
                   ADD 1 TO CURR-POS
                   GO TO SCAN-LOOP-EXIT
               ELSE
                   ADD 1 TO CURR-POS
                   GO TO SCAN-LOOP-EXIT.

           IF TEMP-CHAR = '-'
      *> Check for unary minus
               IF (VAL-VALUE-TOP = 0 AND OP-TOP = 0)
                  OR (OP-TOP > 0 AND OPS(OP-TOP) = '('
                  AND VAL-VALUE-TOP = VAL-TOP-AT-OPEN(OP-TOP))
      *> Unary minus: push 0 and treat as binary minus
                   ADD 1 TO VAL-VALUE-TOP
                   MOVE 0 TO VAL-VALUES(VAL-VALUE-TOP)
                   MOVE 1 TO PREC-CURR
                   PERFORM APPLY-WHILE-HIGHER-OR-EQUAL
                   ADD 1 TO OP-TOP
                   MOVE '-' TO OPS(OP-TOP)
                   ADD 1 TO CURR-POS
                   GO TO SCAN-LOOP-EXIT
               ELSE
      *> Binary minus
                   MOVE 1 TO PREC-CURR
                   PERFORM APPLY-WHILE-HIGHER-OR-EQUAL
                   ADD 1 TO OP-TOP
                   MOVE '-' TO OPS(OP-TOP)
                   ADD 1 TO CURR-POS
                   GO TO SCAN-LOOP-EXIT.

           IF TEMP-CHAR = '*' OR TEMP-CHAR = '/'
               MOVE 2 TO PREC-CURR
               PERFORM APPLY-WHILE-HIGHER-OR-EQUAL
               ADD 1 TO OP-TOP
               MOVE TEMP-CHAR TO OPS(OP-TOP)
               ADD 1 TO CURR-POS
               GO TO SCAN-LOOP-EXIT.

           IF TEMP-CHAR = '^'
               MOVE 3 TO PREC-CURR
               PERFORM APPLY-WHILE-HIGHER-OR-EQUAL
               ADD 1 TO OP-TOP
               MOVE TEMP-CHAR TO OPS(OP-TOP)
               ADD 1 TO CURR-POS
               GO TO SCAN-LOOP-EXIT.
           DISPLAY 'INVALID CHARACTER: ' TEMP-CHAR
           STOP RUN.
       SCAN-LOOP-EXIT.
           EXIT.


       PARSE-NUMBER.
           MOVE 0 TO TEMP-NUM.
           MOVE 0 TO WHOLE-NUMBER
           MOVE 1 TO DENOM.
           MOVE 1 TO DENOM-MULT.
           PERFORM PARSE-NUM-LOOP UNTIL CURR-POS > EXPR-LEN
               OR NOT (INPUT-EXPR-CH(CURR-POS) IS NUMERIC
                       OR INPUT-EXPR-CH(CURR-POS) = '.').
           COMPUTE TEMP-NUM = WHOLE-NUMBER / DENOM.

           ADD 1 TO VAL-VALUE-TOP.
           MOVE TEMP-NUM TO VAL-VALUES(VAL-VALUE-TOP).
      *    DISPLAY 'PUSHED: ' TEMP-NUM ' TOP=' VAL-VALUE-TOP.


       PARSE-NUM-LOOP.
           MOVE INPUT-EXPR-CH(CURR-POS) TO TEMP-CHAR
           IF TEMP-CHAR IS NUMERIC
               COMPUTE WHOLE-NUMBER = WHOLE-NUMBER * 10 + TEMP-CHAR-VAL
               COMPUTE DENOM = DENOM * DENOM-MULT
           ELSE
               IF TEMP-CHAR = '.'
                   MOVE 10 TO DENOM-MULT.

           ADD 1 TO CURR-POS.

       APPLY-UNTIL-OPEN-PAREN.
           PERFORM APPLY-TOP-OP UNTIL OP-TOP = 0 OR OPS(OP-TOP) = '('.

           IF OP-TOP = 0
               DISPLAY 'MISMATCHED PARENTHESES'
               STOP RUN.
      *> Discard '('.
           SUBTRACT 1 FROM OP-TOP.

       APPLY-WHILE-HIGHER-OR-EQUAL.
           PERFORM TEST-AND-APPLY.
           MOVE 0 TO EARLY-EXIT
           PERFORM CHECK-PREC
           UNTIL (OP-TOP = 0 OR OPS(OP-TOP) = '(' OR EARLY-EXIT=1).

       CHECK-PREC.
           IF OPS(OP-TOP) = '^'
               MOVE 3 TO PREC-TOP
           ELSE
               IF OPS(OP-TOP) = '*' OR OPS(OP-TOP) = '/'
                   MOVE 2 TO PREC-TOP
               ELSE
                   MOVE 1 TO PREC-TOP.

           IF PREC-TOP NOT < PREC-CURR
               PERFORM APPLY-TOP-OP
               PERFORM TEST-AND-APPLY
           ELSE
               MOVE 1 TO EARLY-EXIT.

       TEST-AND-APPLY.
           EXIT.
       APPLY-TOP-OP.
      *    DISPLAY '>>> APPLY-TOP-OP: VAL-TOP=' VAL-VALUE-TOP
      *    ' OP-TOP=' OP-TOP ' OP=' OPS(OP-TOP)
           IF VAL-VALUE-TOP < 2
               DISPLAY 'SYNTAX ERROR: INSUFFICIENT OPERANDS'
               STOP RUN.

           MOVE    VAL-VALUES(VAL-VALUE-TOP) TO RIGHT-VAL.
           SUBTRACT 1 FROM VAL-VALUE-TOP.
           MOVE VAL-VALUES(VAL-VALUE-TOP) TO LEFT-VAL.

            IF OPS(OP-TOP) = '^'
               COMPUTE VAL-VALUES(VAL-VALUE-TOP) = LEFT-VAL ** RIGHT-VAL
           ELSE IF OPS(OP-TOP) = '+'
               COMPUTE VAL-VALUES(VAL-VALUE-TOP) = LEFT-VAL + RIGHT-VAL
           ELSE IF OPS(OP-TOP) = '-'
               COMPUTE VAL-VALUES(VAL-VALUE-TOP) = LEFT-VAL - RIGHT-VAL
           ELSE IF OPS(OP-TOP) = '*'
               COMPUTE VAL-VALUES(VAL-VALUE-TOP) = LEFT-VAL * RIGHT-VAL
           ELSE IF OPS(OP-TOP) = '/' AND RIGHT-VAL = 0
               DISPLAY 'DIVISION BY ZERO'
               STOP RUN
           ELSE IF OPS(OP-TOP) = '/' AND RIGHT-VAL NOT = 0
               COMPUTE VAL-VALUES(VAL-VALUE-TOP) = LEFT-VAL / RIGHT-VAL.

           SUBTRACT 1 FROM OP-TOP.
      *    DISPLAY 'AFTER DECREMENT: OP-TOP=' OP-TOP.


       APPLY-REMAINING-OPS.
           PERFORM APPLY-TOP-OP UNTIL OP-TOP = 0.


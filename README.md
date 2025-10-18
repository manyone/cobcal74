
# cobcal74.cob – A COBOL-74 Expression Evaluator (for TK4-)

A **classic fixed-format COBOL-74** program that evaluates arithmetic expressions with floating-point precision. Designed to run in vintage environments like **TK4- (Hercules MVS)** and modern GNU COBOL (with `-std=cobol74`).

No recursion, no `EVALUATE`, no `END-xxx` scope terminators — just pure COBOL-74 procedural logic.

---

## ✨ Features

- **Operators supported**:
  - Binary: `+`, `-`, `*`, `/`, `^` (exponentiation)
  - Unary minus: `-5`, `-(2+3)` — allowed **only at start** or **after `(`**
- **Floating-point arithmetic** using `COMP-2` (IEEE double precision in GNU COBOL)
- **Interactive REPL**: type expressions, get results instantly
- **Full operator precedence**:
  - `^` (highest, **left-associative**)
  - `*` and `/`
  - `+` and `-` (lowest)
- **Parentheses** for grouping: `(2+3)*4`, `2^(3^2)`, etc.
- **Ignores all whitespace** — leading, embedded, or trailing

---

## ⚙️ How It Works

The parser uses a **shunting-yard algorithm** to convert infix expressions to **Reverse Polish Notation (RPN)** on the fly, using two stacks:
- **Value stack**: holds operands (`COMP-2` numbers)
- **Operator stack**: holds operators and parentheses

Evaluation proceeds **left to right**, applying operators according to precedence and associativity rules.

> 🔹 **Note on exponentiation**: `^` is implemented as **left-associative** (e.g., `2^3^2 = (2^3)^2 = 64`). Use parentheses for right-associative behavior: `2^(3^2) = 512`.

> 🔹 **Unary minus** is handled by pushing a `0` and treating `-` as binary: `-5` → `0 - 5`.
> 
> 🔹 **Unary minus**  is **only supported** at the start of an expression or right after `'('`. Expressions like `3 * -4` are **not accepted**; use `3 * (-4)` instead.
> 
> 🔹 The **sqrt**  can be calculated using exponentiation:  `(3^4+4^5)^(0.5))`
---

## 🧪 Examples

| Input            | Output     | Notes |
|------------------|------------|-------|
| `2 + 3 * 4`      | `14.00000` | `*` before `+` |
| `-5`             | `-5.00000` | Unary minus |
| `2^3^2`          | `64.00000` | Left-assoc `^` |
| `2^(3^2)`        | `512.00000`| Parentheses override |
| `(10 - 2) / 2`   | `4.00000`  | Grouping |
| `1/3`            | `0.33333`  | Floating-point division |

Type `END` to quit.

(see *testfile.txt* for test suite)

---

## 🛠️ Compilation & Usage

### GNU COBOL (Linux/macOS/Windows via WSL)
```sh
cobc -x -std=cobol74 cobcal74.cob -o cobcal74
./cobcal74
```

### TK4- (MVS Mainframe Emulator)

-   Upload `cobcal74.cob` as fixed-format (columns 1–6 unused, code in 8–72)
-   Compile with standard COBOL-74 compiler (e.g., `IGYCRCTL`)
-   Should run without modification

> 💡 The program includes `>>SOURCE FORMAT IS FIXED` for compatibility with GNU COBOL in online IDEs like JDoodle.

Below is the actual step for running the test suite
```
//HERC02C  JOB (COB),                         
//             'COBCAL74',                    
//             CLASS=A,                       
//             MSGCLASS=C,                    
//             REGION=0M,TIME=1440,           
//             MSGLEVEL=(1,1)                 
//*             
//RUN  EXEC PGM=COBCAL74                      
//SYSOUT  DD SYSOUT=*                         
//STEPLIB DD DISP=SHR,DSN=HERC02.RUN.LOAD     
//SYSIN DD *                                  
5                                             
(5)                                           
-5                                            
(-5)                                          
3+4                                           
3-4                                           
3*4                                           
8/2                                           
2^3                                           
2^3^2                                         
2^(3^2)                                       
2+3*4                                         
(2+3)*4                                       
10-2*3                                        
2*3+4*5                                       
10/2-3                                        
-2+3                                          
-(2+3)                                        
2^3*4                                         
2*3^2                                         
10/2^2                                        
-2^2                                          
(-2)^2                                        
1+2*3^2                                       
((2))                                         
0/5                                           
1/3                                           
2^0                                           
END
```
----------

## 📜 License

Public domain. Use, modify, and share freely — especially in mainframe classrooms and COBOL retro projects!

----------

**Author**: Manny Juan (`manyone`)  
**Date**: October 2025  
**Target Standard**: ANSI COBOL-74

1

2

3

4

  

---



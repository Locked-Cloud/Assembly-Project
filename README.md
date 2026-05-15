<p align="center">
  <h1 align="center">🖥️ x86 Assembly Projects — Emu8086</h1>
  <p align="center">
    <strong>CSE132 · Computer Architecture & Organization · Spring 2026</strong>
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/Language-x86_Assembly-blue?style=for-the-badge" alt="Language">
    <img src="https://img.shields.io/badge/Platform-Emu8086-green?style=for-the-badge" alt="Platform">
    <img src="https://img.shields.io/badge/Architecture-8086_ISA-red?style=for-the-badge" alt="Architecture">
    <img src="https://img.shields.io/badge/Model-.MODEL_SMALL-orange?style=for-the-badge" alt="Memory Model">
  </p>
</p>

---

A collection of three x86 Assembly programs built for the **Emu8086** emulator, covering all difficulty tiers of the CSE132 Final Project — from basic arithmetic to real-time game development and hardware simulation.

---

## 📑 Table of Contents

- [Overview](#-overview)
- [Projects](#-projects)
  - [1. Multi-functional Calculator](#1--multi-functional-calculator)
  - [2. Traffic Light Controller](#2--traffic-light-controller)
  - [3. Snake Game](#3--snake-game)
- [Technical Highlights](#-technical-highlights)
- [How to Run](#-how-to-run)
- [Project Structure](#-project-structure)
- [Course Information](#-course-information)

---

## 🔭 Overview

This repository demonstrates core competencies in **low-level system design** and **hardware-software interfacing** using the 8086 Instruction Set Architecture:

| Concept | Implementation |
|---|---|
| **Register Management** | `AX`, `BX`, `CX`, `DX`, `SI`, `DI` used across all programs for data processing |
| **Control Flow** | Conditional jumps (`JE`, `JNE`, `JA`, `JB`, `JAE`), `LOOP`, and `CMP` for decision-making |
| **Memory Segmentation** | `.DATA` and `.STACK` segments properly initialized in every program |
| **DOS Interrupts** | `INT 21h` for keyboard input, string output, and program termination |
| **BIOS Video** | `INT 10h` for cursor control, character rendering, screen clearing, and color attributes |
| **Hardware I/O** | `OUT` instruction for direct port communication with virtual devices |

---

## 🚀 Projects

### 1. 🧮 Multi-functional Calculator

> **Difficulty:** Beginner · **File:** `calculator.asm`

A menu-driven calculator that performs the four basic arithmetic operations on two user-entered numbers (0–99).

#### Features

- Interactive menu with 5 options (Add, Subtract, Multiply, Divide, Exit)
- Handles **division by zero** with a dedicated error message
- Converts multi-digit ASCII input to binary and binary results back to decimal output
- Screen clearing between operations for a clean user experience

#### Menu Preview

```
===== CALCULATOR MENU =====
 1. Addition       (+)
 2. Subtraction    (-)
 3. Multiplication (*)
 4. Division       (/)
 5. Exit
Select (1-5):
```

#### Key Procedures

| Procedure | Purpose |
|---|---|
| `GET_TWO_NUMS` | Prompts and reads two operands from the user |
| `READ_BYTE` | Converts up to 2 ASCII digit characters → binary value (0–99) |
| `PRINT_NUMBER` | Converts a 16-bit unsigned integer → decimal ASCII output |
| `CLEAR_SCREEN` | Clears the 80×25 text screen via `INT 10h / AH=06h` |
| `WAIT_KEY` | Pauses execution until a key is pressed |

#### Interrupts Used

- `INT 21h / AH=01h` — Read character with echo
- `INT 21h / AH=09h` — Print `$`-terminated string
- `INT 21h / AH=4Ch` — Terminate program
- `INT 10h / AH=06h` — Scroll window (clear screen)
- `INT 10h / AH=02h` — Set cursor position

---

### 2. 🚦 Traffic Light Controller

> **Difficulty:** Advanced · **File:** `traffic_light.asm`

Controls the **Emu8086 Virtual Traffic Light** device using the `OUT` instruction on **Port 4**, simulating a realistic traffic signal cycle.

#### Signal Cycle

```
┌─────────────────────────────────────────┐
│  🟢 GREEN  (10s)  →  Bit 2 = 1 (04h)  │
│  🟡 YELLOW  (3s)  →  Bit 1 = 1 (02h)  │
│  🔴 RED    (10s)  →  Bit 0 = 1 (01h)  │
│  ↻ Repeat                               │
└─────────────────────────────────────────┘
```

#### Features

- Direct hardware port communication via `OUT 4, AL`
- Realistic timing using `INT 15h / AH=86h` (BIOS microsecond delay)
- Non-blocking ESC key detection between each 1-second interval
- Clean shutdown — all lights turned off on exit

#### Port 4 Bit Map

| Bit | Light |
|-----|-------|
| 0 | Red |
| 1 | Yellow |
| 2 | Green |

#### Key Procedures

| Procedure | Purpose |
|---|---|
| `DELAY_SECONDS` | Waits `BL` seconds using 1-second intervals with ESC checking |

#### Interrupts Used

- `INT 21h / AH=09h` — Print status messages
- `INT 15h / AH=86h` — Microsecond delay (1,000,000 µs = 1 second)
- `INT 16h / AH=01h` — Non-blocking keyboard check
- `OUT 4, AL` — Send signal to virtual traffic light port

---

### 3. 🐍 Snake Game

> **Difficulty:** Advanced · **File:** `snake.asm`

A fully playable Snake game rendered on the 80×25 text-mode screen with real-time keyboard input, collision detection, food spawning, and score tracking.

#### Controls

| Key | Action |
|-----|--------|
| ↑ Arrow | Move Up |
| ↓ Arrow | Move Down |
| ← Arrow | Move Left |
| → Arrow | Move Right |
| ESC | Quit Game |

#### Features

- **Real-time movement** with tick-based speed control via `INT 1Ah`
- **Non-blocking input** — snake moves continuously; arrow keys change direction
- **180° turn prevention** — cannot reverse directly into yourself
- **Wall collision** — game over when hitting the `#` border
- **Self collision** — game over when the head overlaps any body segment
- **Food system** — pseudo-random food placement using BIOS tick count; avoids spawning on the snake
- **Visual rendering** — `@` head (bright green), `o` body (dark green), `*` food (yellow)
- **Live score display** on the bottom border
- **Max length cap** of 100 segments

#### Screen Layout

```
##SNAKE GAME - Arrows=Move, ESC=Quit################
#                                                  #
#                                                  #
#                    *                             #
#                                                  #
#                  ooo@                            #
#                                                  #
############################### SCORE: 3 ###########
```

#### Key Procedures

| Procedure | Purpose |
|---|---|
| `READ_INPUT` | Non-blocking keyboard read; maps arrow scan codes to direction |
| `WAIT_TICK` | Speed control — returns `AL=1` when enough BIOS ticks have elapsed |
| `MOVE_SNAKE` | Shifts body array forward, moves head in current direction |
| `CHECK_FOOD` | Detects food collision, grows snake, increments score |
| `SPAWN_FOOD` | Generates random food position; validates it's not on the snake |
| `DRAW_BORDER` | Renders `#` border around the 80×25 play area |
| `DRAW_SNAKE` | Renders head (`@`) and body (`o`) with color attributes |
| `ERASE_TAIL` | Clears the last tail segment before each move |
| `DRAW_FOOD` | Renders food (`*`) in yellow |
| `DRAW_SCORE` | Displays live score and title on the border |
| `PRINT_NUMBER` | Converts 16-bit integer to decimal for score display |

#### Interrupts Used

- `INT 10h / AH=02h` — Set cursor position for each character
- `INT 10h / AH=09h` — Write character with color attribute
- `INT 10h / AH=01h` — Hide/restore cursor
- `INT 10h / AH=00h` — Set video mode (clear screen on start)
- `INT 16h / AH=00h` — Read key from keyboard buffer
- `INT 16h / AH=01h` — Check keyboard buffer (non-blocking)
- `INT 1Ah / AH=00h` — Read BIOS tick count for timing and RNG
- `INT 21h / AH=4Ch` — Terminate program

---

## ⚙️ Technical Highlights

### Memory Model

All three programs use the **`.MODEL SMALL`** directive with a **256-byte stack** (`.STACK 100h`), keeping code and data in separate 64KB segments — the standard configuration for Emu8086 programs.

### Register Usage

```
┌──────────────────────────────────────────────────┐
│  AX  — Primary accumulator, arithmetic, I/O      │
│  BX  — Base register, multiplier/divisor          │
│  CX  — Loop counter, digit counter                │
│  DX  — I/O port data, division remainder          │
│  SI  — Source index for array traversal            │
│  DI  — Destination index                          │
│  DS  — Data segment pointer                       │
│  SS:SP — Stack segment and pointer                │
└──────────────────────────────────────────────────┘
```

### Interrupt Map

| Interrupt | Service | Used In |
|---|---|---|
| `INT 10h` | BIOS Video Services | Calculator, Snake |
| `INT 15h` | BIOS Delay | Traffic Light |
| `INT 16h` | BIOS Keyboard | Snake, Traffic Light |
| `INT 1Ah` | BIOS Timer/Tick Count | Snake |
| `INT 21h` | DOS Services | All Programs |
| `OUT` | Direct Port I/O | Traffic Light |

### Arithmetic Techniques

- **ASCII ↔ Binary conversion** — `SUB AL, '0'` and `ADD DL, '0'` for digit processing
- **Multi-digit input** — Accumulator pattern: `result = result × 10 + digit`
- **8-bit MUL** — Used in Calculator's `READ_BYTE` to avoid corrupting `DX`
- **16-bit DIV** — Used for number-to-decimal extraction (divide by 10, push remainders)
- **Pseudo-RNG** — BIOS tick count modulo play-area dimensions for food placement

---

## 🏃 How to Run

### Prerequisites

- [**Emu8086**](https://emu8086-microprocessor-emulator.en.softonic.com/) — 8086 Microprocessor Emulator

### Steps

1. **Clone** this repository:
   ```bash
   git clone https://github.com/<your-username>/x86-assembly-projects.git
   ```

2. **Open** Emu8086 and load any `.asm` file:
   - `calculator.asm` — Run directly
   - `snake.asm` — Run directly
   - `traffic_light.asm` — Open the **Virtual Traffic Light** from the `Virtual Devices` menu before running

3. **Compile & Run** — Click the **Compile** button, then **Run** (or press **F5**)

4. **Debug** — Use **Single Step (F8)** to observe register and flag changes

> **Note:** For the Traffic Light project, make sure to open the virtual device from **Emu8086 → Virtual Devices → Traffic Lights** before executing the program.

---

## 📁 Project Structure

```
.
├── calculator.asm          # Beginner  — Menu-driven arithmetic calculator
├── snake.asm               # Advanced  — Real-time Snake game
├── traffic_light.asm       # Advanced  — Virtual traffic light controller
├── CSE132 Final Project Sp26.pdf   # Project specification document
└── README.md               # This file
```

---

## 🎓 Course Information

| | |
|---|---|
| **Course** | CSE132 — Computer Architecture & Organization |
| **Semester** | Spring 2026 |
| **Topic** | x86 Internal Architecture & Operating Modes |
| **Platform** | Emu8086 Microprocessor Emulator |
| **ISA** | Intel 8086 (16-bit) |

---

<p align="center">
  <sub>Built with 8086 Assembly · Powered by Emu8086</sub>
</p>
# Assembly-Project

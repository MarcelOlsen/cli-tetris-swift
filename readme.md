# Tetris CLI Game

This is a simple Tetris game implemented in Swift for the terminal. The game uses raw mode to handle keyboard input and a timer to drop pieces automatically.

Started this project to learn a bit about CLI's. Definitely not as straight-forward as expected, since there is no super easy way to get user input without blocking the main thread (at least i couldn't think of one yet). So I ended up with a super convoluted workaround including a thing called raw mode, which I didn't even know existed.

All in all, a fun two day project to laern Swift and google stuff for many hours.

## Features

- Basic Tetris gameplay with piece rotation and movement.
- Random piece generation with a preview of the next pieces.
- Line clearing
- Game over detection.
- TODO: Implement score tracking some time

## Requirements

- Swift
- A computer that can run swift

## How to Run

1. Clone the repository:

   ```sh
   git clone https://github.com/yourusername/shitty-terminal-game.git
   cd shitty-terminal-game
   ```

2. Compile the Swift file:

   ```sh
   swiftc main.swift -o tetris
   ```

3. Run the game:
   ```sh
   ./tetris
   ```

### Or simply without building

```sh
swift main.swift
```

## Controls

- `a`: Move piece left
- `d`: Move piece right
- `s`: Move piece down
- `w`: Rotate piece

## Code Overview

The main components of the game are:

- **Raw Mode Handling**: Functions to enable and disable raw mode for terminal input.
- **Piece Management**: Struct to represent a Tetris piece and handle its rotation.
- **Grid Rendering**: Functions to render the game grid and the upcoming pieces.
- **Game Logic**: Functions to handle piece movement, collision detection, line clearing, and game over conditions.
- **Input Handling**: Asynchronous input handling to read user commands without blocking the main thread.
- **Game Timer**: A timer to drop pieces automatically at regular intervals.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgements

- Inspired by the classic Tetris game.
- Uses Swift's Foundation and Darwin libraries for terminal handling and input.

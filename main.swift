import Darwin
import Foundation

// Function to enable raw mode
func enableRawMode() {
    var term = termios()
    tcgetattr(STDIN_FILENO, &term)
    term.c_lflag &= ~(UInt(ICANON | ECHO))
    tcsetattr(STDIN_FILENO, TCSANOW, &term)
}

// Function to disable raw mode
func disableRawMode() {
    var term = termios()
    tcgetattr(STDIN_FILENO, &term)
    term.c_lflag |= UInt(ICANON | ECHO)
    tcsetattr(STDIN_FILENO, TCSANOW, &term)
}

// Enable raw mode at the start
enableRawMode()
defer { disableRawMode() }  // Ensure raw mode is disabled when the program exits

let rows = 20
let columns = 10
var grid = Array(repeating: Array(repeating: 0, count: columns), count: rows)

let shapes = [
    [[1, 1, 1, 1]],  // I
    [[1, 1], [1, 1]],  // O
    [[1, 1, 1], [0, 1, 0]],  // T
    [[1, 1, 0], [0, 1, 1]],  // S
    [[0, 1, 1], [1, 1, 0]],  // Z
]

let shapeQueueLength = 3
var shapeQueue: [[[Int]]] = []
fillShapeQueue()

func fillShapeQueue() {
    while shapeQueue.count < shapeQueueLength {
        shapeQueue.append(shapes.randomElement()!)
    }
}

struct Piece {
    var shape: [[Int]]
    var x: Int
    var y: Int

    mutating func rotate() {
        shape = shape[0].indices.map { i in
            shape.reversed().map { $0[i] }
        }
    }
}

var currentPiece = Piece(shape: shapes.randomElement()!, x: columns / 2 - 1, y: 0)

// Function to render the shape queue
func renderShapeQueue() {
    print("Next:")
    for shape in shapeQueue {
        for row in shape {
            for cell in row {
                print(cell == 1 ? "■" : "·", terminator: "")
            }
            print("")
        }
        print("")
    }
}

func renderGrid() {
    print("\u{001B}[2J")  // Clear screen

    // Display the grid with the label for the shape queue
    for row in -1..<rows {  // Start from -1 to add the label before the grid
        if row == -1 {
            // Print the label above the queue
            let queueLabel = (0..<columns).map { _ in " " }.joined()
            print(queueLabel + "    Next shapes:", terminator: "")
        } else {
            // Render each row of the grid
            for col in 0..<columns {
                if grid[row][col] == 1 {
                    print("█", terminator: "")
                } else if isPieceAt(row: row, col: col) {
                    print("■", terminator: "")
                } else {
                    print("·", terminator: "")
                }
            }

            // Render a gap, then the queue
            print("    ", terminator: "")

            // Display the upcoming shape for this row
            if row < shapeQueueLength * 4 {
                let shapeIndex = row / 4
                let shapeRow = row % 4
                if shapeRow < shapeQueue[shapeIndex].count {
                    for cell in shapeQueue[shapeIndex][shapeRow] {
                        print(cell == 1 ? "■" : " ", terminator: "")
                    }
                } else {
                    print("    ", terminator: "")
                }
            }
        }

        print("")  // Move to the next line
    }
}

func isPieceAt(row: Int, col: Int) -> Bool {
    let pieceHeight = currentPiece.shape.count
    let pieceWidth = currentPiece.shape[0].count
    let relativeRow = row - currentPiece.y
    let relativeCol = col - currentPiece.x

    return relativeRow >= 0 && relativeRow < pieceHeight && relativeCol >= 0
        && relativeCol < pieceWidth && currentPiece.shape[relativeRow][relativeCol] == 1
}

func canMove(_ piece: Piece, dx: Int, dy: Int) -> Bool {
    for row in 0..<piece.shape.count {
        for col in 0..<piece.shape[row].count {
            if piece.shape[row][col] == 1 {
                let newX = piece.x + col + dx
                let newY = piece.y + row + dy
                if newX < 0 || newX >= columns || newY >= rows
                    || (newY >= 0 && grid[newY][newX] == 1)
                {
                    return false
                }
            }
        }
    }
    return true
}

func placePiece(_ piece: Piece) {
    for row in 0..<piece.shape.count {
        for col in 0..<piece.shape[row].count {
            if piece.shape[row][col] == 1 {
                grid[piece.y + row][piece.x + col] = 1
            }
        }
    }
}

func clearLines() {
    grid = grid.filter { row in row.contains(0) }
    let cleared = rows - grid.count
    grid = Array(repeating: Array(repeating: 0, count: columns), count: cleared) + grid
}

var tickCount = 0
let dropInterval = 1

// Game timer for automatic piece drop
let gameTimer = DispatchSource.makeTimerSource()
gameTimer.schedule(deadline: .now(), repeating: .milliseconds(500))
gameTimer.setEventHandler {
    tickCount += 1
    if tickCount >= dropInterval {
        tickCount = 0
        if canMove(currentPiece, dx: 0, dy: 1) {
            currentPiece.y += 1
        } else {
            placePiece(currentPiece)
            clearLines()
            currentPiece = Piece(shape: shapeQueue.removeFirst(), x: columns / 2 - 1, y: 0)
            fillShapeQueue()
            if !canMove(currentPiece, dx: 0, dy: 0) {
                print("Game Over")
                disableRawMode()
                exit(0)
            }
        }
    }
    renderGrid()
}

//input handler shenanigans, can't use readLine() because it blocks the main thread
//we need to read input asynchronously to keep the game timer running
//so we use FileHandle.standardInput.readabilityHandler to read input from the terminal
//and update the game state accordingly
//weeeeeeird stuff
FileHandle.standardInput.readabilityHandler = { handle in
    let input = handle.availableData
    guard let key = String(data: input, encoding: .utf8)?.first else { return }

    switch key {
    case "a":
        if canMove(currentPiece, dx: -1, dy: 0) { currentPiece.x -= 1 }
    case "d":
        if canMove(currentPiece, dx: 1, dy: 0) { currentPiece.x += 1 }
    case "s":
        if canMove(currentPiece, dx: 0, dy: 1) { currentPiece.y += 1 }
    case "w":
        var rotatedPiece = currentPiece
        rotatedPiece.rotate()
        if canMove(rotatedPiece, dx: 0, dy: 0) { currentPiece.rotate() }
    default:
        break
    }
}

// Start the game timer and keep the main thread alive
gameTimer.resume()
RunLoop.main.run()

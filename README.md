<p align="center">
    <img src="Logo.png" width="400" max-width="90%" alt=“SwiftShogi” />
</p>

SwiftShogi is a pure Swift shogi library with game management, bitboard-based board representation, and move generation/validation.

## Features

- [x] Game management
- [x] Board representation
- [x] Move generation/validation
- [x] SFEN parsing
- [ ] KIF parsing
- [ ] Pretty printing

## Example

To understand how to develop apps using SwiftShogi, you can refer to the following app.

- [SwiftUIShogi](https://github.com/kk-no/SwiftUIShogi) \- An example shogi app using SwiftUI

## Usage

Initialize a game with [SFEN](https://en.wikipedia.org/wiki/Shogi_notation#SFEN):

```swift
var game = Game(sfen: .default)
```

To get all valid moves, use the `validMoves()` method, and to get valid moves for a specified piece, use the `validMoves(from:piece:)` method:

```swift
let moves = game.validMoves()

let pieceMoves = game.validMoves(
    from: .board(.twoG),
    piece: Piece(kind: .pawn(.normal), color: .black)
)
```

You can perform a move by calling the game's `perform(_:)` method:

```swift
let move = Move(
    source: .board(.twoG),
    destination: .board(.twoF),
    piece: Piece(kind: .pawn(.normal), color: .black)
)
try game.perform(move)
```

## Installation

Add the SwiftShogi package to your target dependencies in `Package.swift`:

```swift
import PackageDescription

let package = Package(
    name: "YourProject",
    dependencies: [
        .package(
            url: "https://github.com/kk-no/SwiftShogi",
            from: "0.1.0"
        ),
    ]
)
```

Then run the `swift build` command to build your project.

## License

MIT

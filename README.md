# Chess in Lua

Currently working on a chess game implementation in Lua language using Love2D framework. Have no experience in Lua and Love2D and new to game development so logic and code is probably is bad and not optimized. But its still work. Currently trying to implement full game logic and remove any bugs that current implementation might have.

## What logic game has

1. Turns
2. Piece movements
3. Check (May be some problems)
4. Usage of FEN(Forsyth-Edwards Notation) (Castling Rights, Possible En Passant Targets and Halfmove Clock are still missing)
5. Generation of FEN in sepearte txt file
6. Castling (Not fully implemented)

## What logic game still missing

1. Implementation of En Passant logic
2. Mate logic
3. Implementation of time
4. Implemenation of promoting pawns
5. More user friendly UI showing board coordinates, place to input FEN and get FEN, ability to see previous moves, offer draw and resign as well as changing color positions.

## Usage

For usage Love2D must be installed.
After Installation just dragging the main.lua file into the love2d extenstion starts the game.
Generated FEN value also can be obtained from txt file that is generated in the same directory as the main.lua file.

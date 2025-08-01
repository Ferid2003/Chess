# Chess in Lua

Currently working on a chess game implementation in Lua language using Love2D framework. Have no experience in Lua and Love2D and new to game development so logic and code is probably is bad and not optimized. But its still work. Currently trying to implement full game logic and remove any bugs that current implementation might have.

## What logic game has

The game has all the logic of chess + implementation of usage and generation of FEN(Forsyth-Edwards Notation) value, stored history of moves, ability to go to previous/next moves and flip board.

## What logic game still missing

1. Implementation of setting board by dragging/dropping pieces
2. Implementation of scoreboard
3. Implementation of time
4. Bot opponent

## Usage

For usage Love2D must be installed.
After Installation just dragging the main.lua file into the love2d extenstion starts the game.
Generated FEN value also can be obtained from txt file that is generated in the same directory as the main.lua file.

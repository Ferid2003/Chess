function love.load()
	anim8 = require "libraries/anim8"

	love.graphics.setDefaultFilter("nearest","nearest")


	debugText = ""

	grid={}
	grid.x = 0
	grid.y = 0

	selectedPiece = nil
	selectedPos = {x = nil, y = nil}

	

	gameState = {
    turn = "w", -- 1 for white, 0 for black
		fen = {{"r","n","b","q","k","b","n","r"},
		{"p","p","p","p","p","p","p","p"},
		{8},
		{8},
		{8},
		{8},
		{"P","P","P","P","P","P","P","P"},
		{"R","N","B","Q","K","B","N","R"},
		},
		white_king_moved = false,
		black_king_moved = false,
		black_rook1_moved = false,
		black_rook2_moved = false,
		white_rook1_moved = false,
		white_rook2_moved = false
	}

	-- popupVisible = true

  --   -- Define buttons for the popup menu
  --   buttons = {
  --       createButton("Button 1", 300, 200, 150, 50, function() print("Button 1 clicked!") end),
  --       createButton("Button 2", 500, 200, 150, 50, function() print("Button 2 clicked!") end),
  --       createButton("Button 3", 700, 200, 150, 50, function() print("Button 3 clicked!") end),
  --       createButton("Button 4", 900, 200, 150, 50, function() print("Button 4 clicked!") end),
  --   }

	pieces={}

	pieces.test = {}

	pieces.test, gameState.turn = translate_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w")

	

	success = love.window.setMode(0, 0, {fullscreen = false, vsync = false, msaa = 0})

	map = {
		{0,1,0,1,0,1,0,1},
		{1,0,1,0,1,0,1,0},
		{0,1,0,1,0,1,0,1},
		{1,0,1,0,1,0,1,0},
		{0,1,0,1,0,1,0,1},
		{1,0,1,0,1,0,1,0},
		{0,1,0,1,0,1,0,1},
		{1,0,1,0,1,0,1,0}
	}


	
	screen_width = love.graphics.getWidth()
	screen_height = love.graphics.getHeight()

	cellsize = screen_height/8


end


function love.update(dt)
	
end

function love.draw()

	local pieceSprites = {
		r = love.graphics.newImage("sprites/rook_black.png"),
		R = love.graphics.newImage("sprites/rook_white.png"),
		n = love.graphics.newImage("sprites/knight_black.png"),
		N = love.graphics.newImage("sprites/knight_white.png"),
		b = love.graphics.newImage("sprites/bispoh_black.png"),
		B = love.graphics.newImage("sprites/bishop_white.png"),
		q = love.graphics.newImage("sprites/queen_black.png"),
		Q = love.graphics.newImage("sprites/queen_white.png"),
		k = love.graphics.newImage("sprites/king_black.png"),
		K = love.graphics.newImage("sprites/king_white.png"),
		p = love.graphics.newImage("sprites/pawn_black.png"),
		P = love.graphics.newImage("sprites/pawn_white.png")
	}

	love.graphics.setBackgroundColor(love.math.colorFromBytes(235, 236, 208))

	local offsetX = (screen_width - cellsize * #map[1]) / 2
	local offsetY = (screen_height - cellsize * #map) / 2

	for y=1, #map do
		for x=1, #map[y] do
			local drawX = offsetX + (x - 1) * cellsize
			local drawY = offsetY + (y - 1) * cellsize
			if map[y][x] == 0 then
				love.graphics.rectangle("line", drawX, drawY, cellsize, cellsize)
			elseif map[y][x] == 1 then
				love.graphics.setColor(love.math.colorFromBytes(115, 149, 82))
				love.graphics.rectangle("fill", drawX, drawY, cellsize, cellsize)
			end

			-- Highlight the selected piece
			if selectedPiece and selectedPos.x == x and selectedPos.y == y then
				love.graphics.setColor(1, 1, 0, 0.5) -- Yellow with transparency
				love.graphics.rectangle("fill", drawX, drawY, cellsize, cellsize)
			end

			-- Draw piece
			love.graphics.setColor(1,1,1)
			local piece = pieces.test[y][x]
			if piece and piece ~= " " then
					love.graphics.draw(pieceSprites[piece], drawX, drawY, 0, cellsize / pieceSprites[piece]:getWidth(), cellsize / pieceSprites[piece]:getHeight())
			end
		end
	end
	love.graphics.setColor(1,1,1)
	love.graphics.print(debugText,10, 10)


-- 	if popupVisible then
-- 		-- Draw popup background
-- 		love.graphics.setColor(0, 0, 0, 0.8) -- Semi-transparent black
-- 		love.graphics.rectangle("fill", 250, 150, 900, 150)

-- 		-- Draw buttons
-- 		for _, button in ipairs(buttons) do
-- 				-- Button background
-- 				love.graphics.setColor(0.8, 0.8, 0.8) -- Light gray
-- 				love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)

-- 				-- Button text
-- 				love.graphics.setColor(0, 0, 0) -- Black
-- 				love.graphics.printf(button.label, button.x, button.y + button.height / 4, button.width, "center")
-- 		end
-- end

end



function love.mousepressed(x, y, button, istouch)
	if button == 1 then -- Left mouse button
			-- Calculate the grid cell indices
	
			gridX = math.floor(x / cellsize) -2
			gridY = math.floor(y / cellsize) + 1

	

			clicked_pos_x = x-x%cellsize+(math.abs(32*3.6-cellsize))/2
			clicked_pos_y = y-y%cellsize

			

			-- Check if the indices are within the bounds of the map
			if gridX >= 1 and gridX <= #map[1] and gridY >= 1 and gridY <= #map then
				if not selectedPiece then
					-- First click: Select the piece
					selectedPiece = find_piece_from_cell(gridX,gridY,pieces.test,gameState.turn)
					if selectedPiece then
							selectedPos.x = gridX
							selectedPos.y = gridY
							debugText = "Selected " .. selectedPiece .. " at " .. gridX .. ", " .. gridY

					else
							debugText = "No piece at " .. gridX .. ", " .. gridY
					end
			else
				-- Second click: Move the piece
				if gridX ~= selectedPos.x or gridY ~= selectedPos.y then
					move_piece(selectedPiece, selectedPos, {x = gridX, y = gridY}, gameState.turn)
					selectedPiece = nil
					selectedPos = {x = nil, y = nil}
				else
					debugText = "Clicked the same cell, deselecting"
					selectedPiece = nil
					selectedPos = {x = nil, y = nil}
				end
			end
		else 
			debugText = "Clicked outside of the board"
		end
end
end


function createButton(label, x, y, width, height, callback)
	return {
			label = label,
			x = x,
			y = y,
			width = width,
			height = height,
			callback = callback,
	}
end



function generate_fen(board)
	local fen = ""

	for y = 1, #board do
			local row = ""
			local empty_count = 0

			for x = 1, #board[y] do
					local piece = board[y][x]
					if piece == " " then
							empty_count = empty_count + 1
					else
							if empty_count > 0 then
									row = row .. tostring(empty_count)
									empty_count = 0
							end
							row = row .. piece
					end
			end

			-- Append remaining empty spaces at the end of the row
			if empty_count > 0 then
					row = row .. tostring(empty_count)
			end

			-- Add the row to the FEN string
			fen = fen .. row
			if y < #board then
					fen = fen .. "/"
			end
	end

	write_fen_to_file(fen, "game.txt")

	return fen
end

function write_fen_to_file(fen, filename)
	local file = io.open(filename, "w") -- Open file in write mode (overwrite)
	if file then
			file:write(fen) -- Write the FEN value to the file
			file:close() -- Close the file to save changes
			print("FEN written to file:", filename)
	else
			print("Error: Could not open file for writing.")
	end
end


function find_piece_from_cell(x,y,fen,turn)
	if x>=1 and y>=1 and fen[y][x]~=" " then
		local piece = fen[y][x]
		if turn=="w" and (piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K") then
			piece_pos = {x,y}
			return fen[y][x]
		elseif turn=="b" and (piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k") then
			piece_pos = {x,y}
			return fen[y][x]
		else
			debugText = "Move opposite color pieces"
		end
	end
end

function move_piece(piece, from, to, turn)
		local moves = get_legal_moves(piece,from.x,from.y)
		local legal_moves = filter_legal_moves(piece, {x = from.x, y = from.y},moves)
		local black_castle_queen_side = {x = 3, y = 1}
		local black_castle_king_side = {x = 7, y = 1}
		local white_castle_queen_side = {x = 3, y = 8}
		local white_castle_king_side = {x = 7, y = 8}
		for i=1, #legal_moves do
			if legal_moves[i].x==to.x and legal_moves[i].y==to.y then
				if piece=="k" then
					if black_castle_queen_side.x==to.x and black_castle_queen_side.y==to.y then
						pieces.test[1][1] = " "
						pieces.test[1][4] = "r"
					elseif black_castle_king_side.x==to.x and black_castle_king_side.y==to.y then
						pieces.test[1][8] = " "
						pieces.test[1][6] = "r"
					end
					pieces.black_king_moved=true
				end
				if piece=="K" then
					if white_castle_queen_side.x==to.x and white_castle_queen_side.y==to.y then
						pieces.test[8][1] = " "
						pieces.test[8][4] = "R"
					elseif white_castle_king_side.x==to.x and white_castle_king_side.y==to.y then
						pieces.test[8][8] = " "
						pieces.test[8][6] = "R"
					end
					pieces.white_king_moved=true
				end
				pieces.test[from.y][from.x] = " "
				pieces.test[to.y][to.x] = piece
				if turn=="b" then
					gameState.turn="w"
					generate_fen(pieces.test)
				else 
					gameState.turn="b"
					generate_fen(pieces.test)
				end
				debugText = piece .. " moved to " .. to.x .. ", " .. to.y
			else
				debugText =  " Invalid moving position " 
			end
		end
end

function find_king_position(board, king)
	for y = 1, #board do
			for x = 1, #board[y] do
					if board[y][x] == king then
							return {x = x, y = y}
					end
			end
	end
	return nil
end

function is_king_in_check(board, king, opponent_pieces)
	-- Find the king's position
	local king_pos = find_king_position(board, king)

	if not king_pos then
			error("King not found on the board!")
	end

	-- Check for threats
	for y = 1, #board do
			for x = 1, #board[y] do
					local piece = board[y][x]
					if opponent_pieces[piece] then
							
						if can_piece_threaten_king(piece, x, y, king_pos) then
							local legal_moves = get_legal_moves(piece, x, y)
							for _, move in ipairs(legal_moves) do
									if move.x == king_pos.x and move.y == king_pos.y then
											return true
									end
							end
						end
					end
			end
	end

	return false
end

function will_king_be_in_check(board, king_posi, opponent_pieces)
	-- Find the king's position
	local king_pos = king_posi

	if not king_pos then
			error("King not found on the board!")
	end

	-- Check for threats
	for y = 1, #board do
			for x = 1, #board[y] do
					local piece = board[y][x]
					if opponent_pieces[piece] then
							local legal_moves = get_legal_moves(piece, x, y)
							for _, move in ipairs(legal_moves) do
									if move.x == king_pos.x and move.y == king_pos.y then
											return true
									end
							end
					end
			end
	end

	return false
end

function can_piece_threaten_king(piece, px, py, king_pos)
	local dx = math.abs(king_pos.x - px)
	local dy = math.abs(king_pos.y - py)

	-- Example logic for different pieces:
	if piece == "p" then
			return dy == 1 and dx == 1
	elseif piece == "r" or piece == "R" then
			return dx == 0 or dy == 0
	elseif piece == "n" or piece == "N" then
			return (dx == 2 and dy == 1) or (dx == 1 and dy == 2)
	elseif piece == "b" or piece == "B" then
			return dx == dy
	elseif piece == "q" or piece == "Q" then
			return dx == 0 or dy == 0 or dx == dy
	elseif piece == "k" or piece == "K" then
			return dx <= 1 and dy <= 1
	end
	return false
end

function castle(board,king,legal_moves,opponent_pieces)
	if is_king_in_check(board, king, opponent_pieces) then
		debugText =  " Castling is not possible because king is in check " 
	else
		if king=="k" then
			if not pieces.black_king_moved and not pieces.black_rook1_moved and (board[1][2]==" " and board[1][3]==" " and board[1][4]==" ") then
				table.insert(legal_moves,{x = 3, y = 1})
			end
			if not pieces.black_king_moved and not pieces.black_rook2_moved and (board[1][6]==" " and board[1][7]==" ") then
				table.insert(legal_moves,{x = 7, y = 1})
			end
		elseif king=="K" then
			if not pieces.white_king_moved and not pieces.white_rook1_moved and (board[8][2]==" " and board[8][3]==" " and board[8][4]==" ") then
				table.insert(legal_moves,{x = 3, y = 8})
			end
			if not pieces.white_king_moved and not pieces.white_rook2_moved and (board[8][6]==" " and board[8][7]==" ") then
				table.insert(legal_moves,{x = 7, y = 8})
			end
		end
	end
	
end



function string:split(sep, pattern)
	if sep == "" then
			return self:totable()
	end
	local rs = {}
	local previdx = 1
	while true do
			local startidx, endidx = self:find(sep, previdx, not pattern)
			if not startidx then
					table.insert(rs, self:sub(previdx))
					break
			end
			table.insert(rs, self:sub(previdx, startidx - 1))
			previdx = endidx + 1
	end
	return rs
end

function string:trim(chars)
	chars = chars or "%s"
	return self:trimstart(chars):trimend(chars)
end

function string:trimstart(chars)
	return self:gsub("^[" .. (chars or "%s") .. "]+", "")
end

function string:trimend(chars)
	return self:gsub("[" .. (chars or "%s") .. "]+$", "")
end

function string:totable()
	local result = {}
	for ch in self:gmatch(".") do
			table.insert(result, ch)
	end
	return result
end

function translate_fen(fen)
	local loaded_fen = {}

	 -- Split FEN into board and additional fields
	 local board_part, turn = fen:match("([^ ]+) ([^ ]+)")

	local rows = fen:trim():split("/")
	for i=1, #rows, 1 do
		local row = {}
		for char in rows[i]:gmatch(".") do
			if tonumber(char) then
					for _ = 1, tonumber(char) do
							table.insert(row, " ") -- Add empty squares as a single row
					end
			else
					table.insert(row, char) -- Add the piece
			end
	end
	table.insert(loaded_fen, row) -- Insert the complete row into loaded_fen
	end
	return loaded_fen, turn
end

function deep_copy(board)
	local board_copy = {}
	for i = 1,#board do
		board_copy[i] = {}
		for j = 1, #board[i] do
			board_copy[i][j] = board[i][j]
		end
	end
	return board_copy
end

function filter_legal_moves(piece, from, legal_moves)
	local filtered_moves = {}
	local king = gameState.turn == "w" and "K" or "k"
	local opponent_pieces = gameState.turn == "w"
				and {p = true, r = true, n = true, b = true, q = true, k = true}
				or {P = true, R = true, N = true, B = true, Q = true, K = true}


	for _, move in ipairs(legal_moves) do
			-- Simulate the move
			local temp_board = deep_copy(pieces.test)
			temp_board[from.y][from.x] = " "
			temp_board[move.y][move.x] = piece

			local king_pos = find_king_position(temp_board, king)
			

			
			if not is_king_in_check(temp_board, king, opponent_pieces) then
					table.insert(filtered_moves, move)
			end
			
	end
	return filtered_moves
end


function get_legal_moves(piece,cordx,cordy)

	local legal_moves = {}

	local grater = 0
	local lesser = 0

	if cordx>=cordy then
		grater = cordx
		lesser = cordy
	else
		grater = cordy
		lesser = cordx
	end

	local move_logic = {

	

		p = function()
				if cordy == 2 and pieces.test[cordy + 1][cordx] == " " and pieces.test[cordy + 2][cordx] == " " then
					table.insert(legal_moves, {x = cordx, y = cordy + 2})
				end
	
			-- One-tile advance if the square in front is empty
				if cordy + 1 <= 8 and pieces.test[cordy + 1][cordx] == " " then
					table.insert(legal_moves, {x = cordx, y = cordy + 1})
				end
					if cordx-1~=0 or cordx+1~=9 then
						if pieces.test[cordy+1][cordx-1]~=" " and (pieces.test[cordy+1][cordx-1]=="P" or pieces.test[cordy+1][cordx-1]=="R" or pieces.test[cordy+1][cordx-1]=="N" or pieces.test[cordy+1][cordx-1]=="B" or pieces.test[cordy+1][cordx-1]=="Q" or pieces.test[cordy+1][cordx-1]=="K") then
							table.insert(legal_moves, {x = cordx-1, y = cordy + 1})
						end
						if pieces.test[cordy+1][cordx+1]~=" " and (pieces.test[cordy+1][cordx+1]=="P" or pieces.test[cordy+1][cordx+1]=="R" or pieces.test[cordy+1][cordx+1]=="N" or pieces.test[cordy+1][cordx+1]=="B" or pieces.test[cordy+1][cordx+1]=="Q" or pieces.test[cordy+1][cordx+1]=="K") then
							table.insert(legal_moves, {x = cordx+1, y = cordy + 1})
						end
			end
		end,

		P = function()
			if cordy == 7 and pieces.test[cordy - 1][cordx] == " " and pieces.test[cordy - 2][cordx] == " " then
        table.insert(legal_moves, {x = cordx, y = cordy - 2})
    	end

    -- One-tile advance if the square in front is empty
    	if cordy + 1 <= 8 and pieces.test[cordy - 1][cordx] == " " then
        table.insert(legal_moves, {x = cordx, y = cordy - 1})
    	end
				if cordx-1~=0 or cordx+1~=9 then
					if pieces.test[cordy-1][cordx-1]~=" " and (pieces.test[cordy-1][cordx-1]=="p" or pieces.test[cordy-1][cordx-1]=="r" or pieces.test[cordy-1][cordx-1]=="n" or pieces.test[cordy-1][cordx-1]=="b" or pieces.test[cordy-1][cordx-1]=="q" or pieces.test[cordy-1][cordx-1]=="k") then
						table.insert(legal_moves, {x = cordx - 1, y = cordy - 1})
					end
					if pieces.test[cordy-1][cordx+1]~=" " and (pieces.test[cordy-1][cordx+1]=="p" or pieces.test[cordy-1][cordx+1]=="r" or pieces.test[cordy-1][cordx+1]=="n" or pieces.test[cordy-1][cordx+1]=="b" or pieces.test[cordy-1][cordx+1]=="q" or pieces.test[cordy-1][cordx+1]=="k") then
						table.insert(legal_moves, {x = cordx + 1, y = cordy - 1})
					end
				end
		end,
		-- Add other pieces here (e.g., rook, knight, etc.)
		r = function()
				for i = 1, 8-cordx do
					if cordx+i<=8 then
						local piece = pieces.test[cordy][cordx + i]
						if piece==" " then
							table.insert(legal_moves, {x = cordx + i, y = cordy}) -- Horizontal moves
						elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
							table.insert(legal_moves, {x = cordx + i, y = cordy}) -- Horizontal moves
							break
						else
							break
						end
					end
				end

				for i = 1, cordx do
					if cordx-i>=1 then
						local piece = pieces.test[cordy][cordx - i]
						if piece==" " then
							table.insert(legal_moves, {x = cordx - i, y = cordy}) -- Horizontal moves
						elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
							table.insert(legal_moves, {x = cordx - i, y = cordy}) -- Horizontal moves
							break
						else
							break
						end
					end
				end

				for i = 1, 8-cordy do
					if cordy+i<=8 then
						local piece = pieces.test[cordy + i][cordx]
						if piece==" " then
							table.insert(legal_moves, {x = cordx, y = cordy + i}) -- Horizontal moves
						elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
							table.insert(legal_moves, {x = cordx, y = cordy + i}) -- Horizontal moves
							break
						else
							break
						end
					end
				end

				for i = 1, cordy do
					if cordy-i>=1 then
						local piece = pieces.test[cordy - i][cordx]
						if piece==" " then
							table.insert(legal_moves, {x = cordx, y = cordy - i}) 
						elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
							table.insert(legal_moves, {x = cordx, y = cordy - i}) 
							break
						else
							break
						end
					end
				end
		end,

		R = function()
			for i = 1, 8-cordx do
				if cordx+i<=8 then
					local piece = pieces.test[cordy][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, cordx do
				if cordx-i>=1 then
					local piece = pieces.test[cordy][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 8-cordy do
				if cordy+i<=8 then
					local piece = pieces.test[cordy + i][cordx]
					if piece==" " then
						table.insert(legal_moves, {x = cordx, y = cordy + i}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, cordy do
				if cordy-i>=1 then
					local piece = pieces.test[cordy - i][cordx]
					if piece==" " then
						table.insert(legal_moves, {x = cordx, y = cordy - i}) 
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx, y = cordy - i}) 
						break
					else
						break
					end
				end
			end
		end,

		b = function()
			for i = 1, 7 do
				if cordx+i<=8 and cordy-i>=1 then
					local piece = pieces.test[cordy - i][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy - i}) -- Horizontal moves
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy - i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordx-i>=1 and cordy+i<=8 then
					local piece = pieces.test[cordy + i][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy + i}) -- Horizontal moves
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordy+i<=8 and cordx+i<=8 then
					local piece = pieces.test[cordy + i][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy + i}) -- Horizontal moves
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordy-i>=1 and cordx-i>=1 then
					local piece = pieces.test[cordy - i][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy - i}) 
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy - i}) 
						break
					else
						break
					end
				end
			end
		end,

		B = function()
			for i = 1, 7 do
				if cordx+i<=8 and cordy-i>=1 then
					local piece = pieces.test[cordy - i][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy - i}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy - i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordx-i>=1 and cordy+i<=8 then
					local piece = pieces.test[cordy + i][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy + i}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordy+i<=8 and cordx+i<=8 then
					local piece = pieces.test[cordy + i][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy + i}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordy-i>=1 and cordx-i>=1 then
					local piece = pieces.test[cordy - i][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy - i}) 
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy - i}) 
						break
					else
						break
					end
				end
			end
		end,

		n = function()
			local knight_moves = {
				{x = cordx + 1, y = cordy - 2},
				{x = cordx - 1, y = cordy - 2},
				{x = cordx - 2, y = cordy - 1},
				{x = cordx - 2, y = cordy + 1},
				{x = cordx - 1, y = cordy + 2},
				{x = cordx + 1, y = cordy + 2},
				{x = cordx + 2, y = cordy + 1},
				{x = cordx + 2, y = cordy - 1}
			}
			for i = 1, 8 do
				if knight_moves[i].x>=1 and knight_moves[i].x<=8 and knight_moves[i].y>=1 and knight_moves[i].y<=8 and (pieces.test[knight_moves[i].y][knight_moves[i].x]=="P" or pieces.test[knight_moves[i].y][knight_moves[i].x]=="R" or pieces.test[knight_moves[i].y][knight_moves[i].x]=="B" or pieces.test[knight_moves[i].y][knight_moves[i].x]=="N" or pieces.test[knight_moves[i].y][knight_moves[i].x]=="Q" or pieces.test[knight_moves[i].y][knight_moves[i].x]=="K" or pieces.test[knight_moves[i].y][knight_moves[i].x]==" ") then
					table.insert(legal_moves, {x = knight_moves[i].x, y = knight_moves[i].y})
				end
			end
		end,

		N = function()
			local knight_moves = {
				{x = cordx + 1, y = cordy - 2},
				{x = cordx - 1, y = cordy - 2},
				{x = cordx - 2, y = cordy - 1},
				{x = cordx - 2, y = cordy + 1},
				{x = cordx - 1, y = cordy + 2},
				{x = cordx + 1, y = cordy + 2},
				{x = cordx + 2, y = cordy + 1},
				{x = cordx + 2, y = cordy - 1}
			}
			for i = 1, 8 do
				if knight_moves[i].x>=1 and knight_moves[i].x<=8 and knight_moves[i].y>=1 and knight_moves[i].y<=8 and (pieces.test[knight_moves[i].y][knight_moves[i].x]=="p" or pieces.test[knight_moves[i].y][knight_moves[i].x]=="r" or pieces.test[knight_moves[i].y][knight_moves[i].x]=="b" or pieces.test[knight_moves[i].y][knight_moves[i].x]=="n" or pieces.test[knight_moves[i].y][knight_moves[i].x]=="q" or pieces.test[knight_moves[i].y][knight_moves[i].x]=="k" or pieces.test[knight_moves[i].y][knight_moves[i].x]==" ") then
					table.insert(legal_moves, {x = knight_moves[i].x, y = knight_moves[i].y})
				end
			end
		end,

		q = function()
			for i = 1, 7 do
				if cordx+i<=8 then
					local piece = pieces.test[cordy][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy}) -- Horizontal moves
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordx-i>=1 then
					local piece = pieces.test[cordy][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy}) -- Horizontal moves
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordy+i<=8 then
					local piece = pieces.test[cordy + i][cordx]
					if piece==" " then
						table.insert(legal_moves, {x = cordx, y = cordy + i}) -- Horizontal moves
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordy-i>=1 then
					local piece = pieces.test[cordy - i][cordx]
					if piece==" " then
						table.insert(legal_moves, {x = cordx, y = cordy - i}) 
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx, y = cordy - i}) 
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordx+i<=8 and cordy-i>=1 then
					local piece = pieces.test[cordy - i][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy - i}) -- Horizontal moves
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy - i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordx-i>=1 and cordy+i<=8 then
					local piece = pieces.test[cordy + i][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy + i}) -- Horizontal moves
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end
			
			for i = 1, 7 do
				if cordy+i<=8 and cordx+i<=8 then
					local piece = pieces.test[cordy + i][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy + i}) -- Horizontal moves
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordy-i>=1 and cordx-i>=1 then
					local piece = pieces.test[cordy - i][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy - i}) 
					elseif piece=="P" or piece=="R" or piece=="N" or piece=="B" or piece=="Q" or piece=="K" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy - i}) 
						break
					else
						break
					end
				end
			end
		end,

		Q = function()
			for i = 1, 7 do
				if cordx+i<=8 then
					local piece = pieces.test[cordy][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordx-i>=1 then
					local piece = pieces.test[cordy][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordy+i<=8 then
					local piece = pieces.test[cordy + i][cordx]
					if piece==" " then
						table.insert(legal_moves, {x = cordx, y = cordy + i}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordy-i>=1 then
					local piece = pieces.test[cordy - i][cordx]
					if piece==" " then
						table.insert(legal_moves, {x = cordx, y = cordy - i}) 
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx, y = cordy - i}) 
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordx+i<=8 and cordy-i>=1 then
					local piece = pieces.test[cordy - i][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy - i}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy - i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordx-i>=1 and cordy+i<=8 then
					local piece = pieces.test[cordy + i][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy + i}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end
			
			for i = 1, 7 do
				if cordy+i<=8 and cordx+i<=8 then
					local piece = pieces.test[cordy + i][cordx + i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx + i, y = cordy + i}) -- Horizontal moves
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx + i, y = cordy + i}) -- Horizontal moves
						break
					else
						break
					end
				end
			end

			for i = 1, 7 do
				if cordy-i>=1 and cordx-i>=1 then
					local piece = pieces.test[cordy - i][cordx - i]
					if piece==" " then
						table.insert(legal_moves, {x = cordx - i, y = cordy - i}) 
					elseif piece=="p" or piece=="r" or piece=="n" or piece=="b" or piece=="q" or piece=="k" then-- Horizontal moves
						table.insert(legal_moves, {x = cordx - i, y = cordy - i}) 
						break
					else
						break
					end
				end
			end
		end,

		k = function()
			local king_moves = {
				{x = cordx, y = cordy - 1},
				{x = cordx - 1, y = cordy - 1},
				{x = cordx - 1, y = cordy},
				{x = cordx - 1, y = cordy + 1},
				{x = cordx, y = cordy + 1},
				{x = cordx + 1, y = cordy + 1},
				{x = cordx + 1, y = cordy},
				{x = cordx + 1, y = cordy - 1}
			}
			for i = 1, 8 do
				if king_moves[i].x>=1 and king_moves[i].x<=8 and king_moves[i].y>=1 and king_moves[i].y<=8 and (pieces.test[king_moves[i].y][king_moves[i].x]=="P" or pieces.test[king_moves[i].y][king_moves[i].x]=="R" or pieces.test[king_moves[i].y][king_moves[i].x]=="N" or pieces.test[king_moves[i].y][king_moves[i].x]=="B" or pieces.test[king_moves[i].y][king_moves[i].x]=="Q" or pieces.test[king_moves[i].y][king_moves[i].x]=="K" or pieces.test[king_moves[i].y][king_moves[i].x]==" ") then
					table.insert(legal_moves, {x = king_moves[i].x, y = king_moves[i].y})
				end
			end
			if not pieces.black_king_moved then
				castle(pieces.test,"k",legal_moves,{P = true, R = true, N = true, B = true, Q = true, K = true})
			end
		end,

		K = function()
			local king_moves = {
				{x = cordx, y = cordy - 1},
				{x = cordx - 1, y = cordy - 1},
				{x = cordx - 1, y = cordy},
				{x = cordx - 1, y = cordy + 1},
				{x = cordx, y = cordy + 1},
				{x = cordx + 1, y = cordy + 1},
				{x = cordx + 1, y = cordy},
				{x = cordx + 1, y = cordy - 1}
			}
			for i = 1, 8 do
				if king_moves[i].x>=1 and king_moves[i].x<=8 and king_moves[i].y>=1 and king_moves[i].y<=8 and (pieces.test[king_moves[i].y][king_moves[i].x]=="p" or pieces.test[king_moves[i].y][king_moves[i].x]=="r" or pieces.test[king_moves[i].y][king_moves[i].x]=="n" or pieces.test[king_moves[i].y][king_moves[i].x]=="b" or pieces.test[king_moves[i].y][king_moves[i].x]=="q" or pieces.test[king_moves[i].y][king_moves[i].x]=="k" or pieces.test[king_moves[i].y][king_moves[i].x]==" ") then
					table.insert(legal_moves, {x = king_moves[i].x, y = king_moves[i].y})
				end
				if not pieces.white_king_moved then
					castle(pieces.test,"K",legal_moves,{p = true, r = true, n = true, b = true, q = true, k = true})
				end
			end
		end,

		-- Default case (optional)
		default = function()
				print("Unknown piece type: " .. piece)
		end,


	}

	(move_logic[piece] or move_logic.default)()

	return legal_moves
end

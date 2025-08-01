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

function createEmptyBoard()
	local board = {}
	for row = 1, 8 do
		board[row] = {}
		for col = 1, 8 do
			board[row][col] = nil
		end
	end
	return board
end

function flipBoard(originalBoard)
	local board = createEmptyBoard()
	for row = 1, 8 do
		for col = 1, 8 do
			board[9-row][9-col] =originalBoard[row][col]
		end
	end
	if gameState.selectedPiece then
		gameState.selectedPos = {x = 9-gameState.selectedPos.x, y = 9-gameState.selectedPos.y}
	end
	return board
end

function translate_fen(fen)
	local board = createEmptyBoard()
	local castling ={
		black_king_moved = true,
		black_rook1_moved = true,
		black_rook2_moved = true,
		white_king_moved = true,
		white_rook1_moved = true,
		white_rook2_moved = true
	}

	local parts = {}
	for part in string.gmatch(fen, "%S+") do
		table.insert(parts, part)
	end

	local board_part        = parts[1]
	local turn              = parts[2] or "w"
	local castling_rights   = parts[3] or "-"
	local enPassant         = parts[4] or "-"
	local halfmove_clock    = tonumber(parts[5]) or 0
	local fullmove          = tonumber(parts[6]) or 1



	local rows = board_part:trim():split("/")
	for i=1, #rows, 1 do
		local x = 8
		local type = nil
		for char in rows[i]:gmatch(".") do
			if char=="p" or char=="P" then
				type = "pawn"
			elseif char=="r" or char=="R" then
				type = "rook"
			elseif char=="n" or char=="N" then
				type = "knight"
			elseif char=="b" or char=="B" then
				type = "bishop"
			elseif char=="q" or char=="Q" then
				type = "queen"
			elseif char=="k" or char=="K" then
				type = "King"
			end
			if tonumber(char) then
				x = x - tonumber(char)
			else
				board[9-i][x] = Piece:new(type, tostring(char):match("%l") and "black" or "white")
				x = x - 1
			end
		end
	end
	if castling_rights~=nil and castling_rights~="-" then
		for char in castling_rights:gmatch(".") do
			if char:match("%l") then
				castling.black_king_moved = false
				if char=="k" then
					castling.black_rook1_moved =false
				elseif char=="q" then
					castling.black_rook2_moved =false
				else
					castling.black_rook1_moved =false
					castling.black_rook2_moved =false
				end
			else
				castling.white_king_moved = false
				if char=="K" then
					castling.white_rook1_moved =false
				elseif char=="Q" then
					castling.white_rook2_moved =false
				else
					castling.white_rook1_moved =false
					castling.white_rook2_moved =false
				end
			end
		end
	end
	return board, turn, castling, enPassant, halfmove_clock, fullmove
end

function generate_fen(board)
	local fen = ""
	local enPassant = nil

	if gameState.starting=="b" then
		board = flipBoard(board)
	end

	for y = 1, #board do
		local row = ""
		local empty_count = 0

		for x = 1, 8 do
			local piece = board[y][x]
			if piece == nil then
				empty_count = empty_count + 1
			else
				if piece.type=="pawn" and piece.eligible_for_enPassant then
					if gameState.starting=="w" then
						enPassant = {x=x,y=y}
					else
						enPassant = {x=9-x,y=9-y}
					end

				end
				if empty_count > 0 then
					row = row .. tostring(empty_count)
					empty_count = 0
				end
				row = row .. Piece_to_String(piece.type, piece.color)
			end
		end


		if empty_count > 0 then
			row = row .. tostring(empty_count)
		end

		fen = fen .. row
		if y < 8 then
			fen = fen .. "/"
		end
	end

	--adding turn
	fen = fen .. " " .. gameState.turn .. " "

	--adding castling_rights
	local castling_moves = ""
	if not gameState.castling.white_king_moved then
		if not gameState.castling.white_rook1_moved then
			castling_moves = castling_moves .. "K"
		end
		if not gameState.castling.white_rook2_moved then
			castling_moves = castling_moves .. "Q"
		end
	end
	if not gameState.castling.black_king_moved then
		if not gameState.castling.black_rook1_moved then
			castling_moves = castling_moves .. "k"
		end
		if not gameState.castling.black_rook2_moved then
			castling_moves = castling_moves .. "q"
		end
	end
	if castling_moves=="" then
		fen = fen .. "-"
	else
		fen = fen .. castling_moves
	end

	
	--adding enPassant
	if enPassant~=nil then
		local cord = arrCord_to_chessCord(enPassant)
		fen = fen .. " " .. string.sub(cord,1,1) .. tostring(tonumber(string.sub(cord,2,2))-1) .. " "
	else
		fen = fen .. " " .. "-" .. " "
	end

	
	--adding halfmove_clock
	fen = fen .. gameState.halfmove_clock .. " "
	
	--adding fullmove
	fen = fen .. gameState.fullmove

	love.system.setClipboardText(fen)


end



Piece = {}
Piece.__index = Piece

function Piece:new (type,color,eligible_for_enPassant,promoted)
	local obj = {
		type = type,
		color = color,
		eligible_for_enPassant = eligible_for_enPassant,
		promoted = promoted
	}
	setmetatable(obj, self)
	return obj
end

function Piece_to_String (piece,color)
	if piece==nil then
		return piece
	end
	local first = string.sub(piece, 1, 1)
	if first == "r" then
		if color == "black" then
			return "r"
		else
			return "R"
		end
	elseif first == "k" then
		if color == "black" then
			return "n"
		else
			return "N"
		end
	elseif first == "b" then
		if color == "black" then
			return "b"
		else
			return "B"
		end
	elseif first == "K" then
		if color == "black" then
			return "k"
		else
			return "K"
		end
	elseif first == "q" then
		if color == "black" then
			return "q"
		else
			return "Q"
		end
	else
		if color == "black" then
			return "p"
		else
			return "P"
		end
	end
end

function setupBoard (starting)
	local board = createEmptyBoard()

	local function place(row, col, type, color)
		board[row][col] = Piece:new(type, color)
	end

	-- Pawns
	for col = 1, 8 do
		if starting=="b" then
			place(2, col, "pawn", "white",false,false)
			place(7, col, "pawn", "black",false,false)
		else
			place(7, col, "pawn", "white",false,false)
			place(2, col, "pawn", "black",false,false)
		end

	end

	-- Queens
	if starting=="b" then
		--Rooks
		place(1, 1, "rook", "white")
		place(1, 8, "rook", "white")
		place(8, 1, "rook", "black")
		place(8, 8, "rook", "black")
		--Knights
		place(1, 2, "knight", "white")
		place(1, 7, "knight", "white")
		place(8, 2, "knight", "black")
		place(8, 7, "knight", "black")
		--Bishops
		place(1, 3, "bishop", "white")
		place(1, 6, "bishop", "white")
		place(8, 3, "bishop", "black")
		place(8, 6, "bishop", "black")
		--Queens
		place(1, 5, "queen", "white")
		place(8, 5, "queen", "black")
		-- Kings
		place(1, 4, "King", "white")
		place(8, 4, "King", "black")
	else
		--Rooks
		place(1, 1, "rook", "black")
		place(1, 8, "rook", "black")
		place(8, 1, "rook", "white")
		place(8, 8, "rook", "white")
		--Knights
		place(1, 2, "knight", "black")
		place(1, 7, "knight", "black")
		place(8, 2, "knight", "white")
		place(8, 7, "knight", "white")
		--Bishops
		place(1, 3, "bishop", "black")
		place(1, 6, "bishop", "black")
		place(8, 3, "bishop", "white")
		place(8, 6, "bishop", "white")
		--Queens
		place(1, 4, "queen", "black")
		place(8, 4, "queen", "white")
		-- Kings
		place(1, 5, "King", "black")
		place(8, 5, "King", "white")
	end



	return board
end

function areBoardsEqual(board1, board2)
	for y = 1, 8 do
		for x = 1, 8 do
			local p1 = board1[y][x]
			local p2 = board2[y][x]

			if (p1 == nil) ~= (p2 == nil) then
				return false
			elseif p1 and p2 then
				if p1.type ~= p2.type or p1.color ~= p2.color then
					return false
				end
			end
		end
	end
	return true
end

function find_piece_from_cell(x,y,fen,turn)
	if x>=1 and y>=1 and fen[y][x]~=nil then
		local piece = fen[y][x]
		local piece_name = Piece_to_String(piece.type,piece.color)
		if turn=="w" and (piece_name=="P" or piece_name=="R" or piece_name=="N" or piece_name=="B" or piece_name=="Q" or piece_name=="K") then
			piece_pos = {x,y}
			return fen[y][x]
		elseif turn=="b" and (piece_name=="p" or piece_name=="r" or piece_name=="n" or piece_name=="b" or piece_name=="q" or piece_name=="k") then
			piece_pos = {x,y}
			return fen[y][x]
		else
			return -1
		end
	end
end

function castle(board,king,legal_moves)
	if is_king_in_check(board, king) then
		-- Castling is not possible because king is in check
	else
		if (king=="k" and gameState.starting=="w") then
			if not gameState.castling.black_king_moved and not gameState.castling.black_rook2_moved and (board[1][2]==nil and board[1][3]==nil and board[1][4]==nil) then
				table.insert(legal_moves,{x = 3, y = 1})
			end
			if not gameState.castling.black_king_moved and not gameState.castling.black_rook1_moved and (board[1][6]==nil and board[1][7]==nil) then
				table.insert(legal_moves,{x = 7, y = 1})
			end
		elseif (king=="K" and gameState.starting=="b") then
			if not gameState.castling.white_king_moved and not gameState.castling.white_rook1_moved and (board[1][2]==nil and board[1][3]==nil) then
				table.insert(legal_moves,{x = 2, y = 1})
			end
			if not gameState.castling.white_king_moved and not gameState.castling.white_rook2_moved and (board[1][5]==nil and board[1][6]==nil and board[1][7]==nil) then
				table.insert(legal_moves,{x = 6, y = 1})
			end
		elseif (king=="k" and gameState.starting=="b") then
			if not gameState.castling.black_king_moved and not gameState.castling.black_rook1_moved and (board[8][2]==nil and board[8][3]==nil) then
				table.insert(legal_moves,{x = 2, y = 8})
			end
			if not gameState.castling.black_king_moved and not gameState.castling.black_rook2_moved and (board[8][5]==nil and board[8][6]==nil and board[8][7]==nil)then
				table.insert(legal_moves,{x = 6, y = 8})
			end
		elseif (king=="K" and gameState.starting=="w") then
			if not gameState.castling.white_king_moved and not gameState.castling.white_rook2_moved and (board[8][2]==nil and board[8][3]==nil and board[8][4]==nil) then
				table.insert(legal_moves,{x = 3, y = 8})
			end
			if not gameState.castling.white_king_moved and not gameState.castling.white_rook1_moved and (board[8][6]==nil and board[8][7]==nil)then
				table.insert(legal_moves,{x = 7, y = 8})
			end
		end
	end

end

function enPassant (board,pawn,legal_moves,cordx,cordy)
	local opposing_pawn = board[cordy][cordx+1]
	local opposing_pawn2 = board[cordy][cordx-1]
	local opposing_pawn_str = nil
	local opposing_pawn_str2 = nil
	local other_pawn_str = nil
	if opposing_pawn~=nil then
		opposing_pawn_str = Piece_to_String(opposing_pawn.type, opposing_pawn.color)
	end
	if opposing_pawn2~=nil then
		opposing_pawn_str2 = Piece_to_String(opposing_pawn2.type, opposing_pawn2.color)
	end
	if pawn=="p" then
		other_pawn_str = "P"
	else
		other_pawn_str = "p"
	end
	if (pawn=="p" and gameState.starting=="w") or (pawn=="P" and gameState.starting=="b") then
		if opposing_pawn_str==other_pawn_str and opposing_pawn~=nil and opposing_pawn.eligible_for_enPassant and board[cordy+1][cordx+1]==nil then
			table.insert(legal_moves,{x = cordx+1, y = cordy+1})
		end
		if opposing_pawn_str2==other_pawn_str and opposing_pawn2~=nil and opposing_pawn2.eligible_for_enPassant and board[cordy+1][cordx-1]==nil then
			table.insert(legal_moves,{x = cordx-1, y = cordy+1})
		end
	elseif (pawn=="p" and gameState.starting=="b") or (pawn=="P" and gameState.starting=="w") then
		if opposing_pawn_str==other_pawn_str and opposing_pawn~=nil and opposing_pawn.eligible_for_enPassant and board[cordy-1][cordx+1]==nil then
			table.insert(legal_moves,{x = cordx+1, y = cordy-1})
		end
		if opposing_pawn_str2==other_pawn_str and opposing_pawn2~=nil and opposing_pawn2.eligible_for_enPassant and board[cordy-1][cordx-1]==nil then
			table.insert(legal_moves,{x = cordx-1, y = cordy-1})
		end
	end
end

function promotePawn(pieceColor,promotedPiece,to)
	local promoted_pawn_str = "="
	gameState.board[to.y][to.x] = nil
	gameState.board[to.y][to.x] = Piece:new(promotedPiece, pieceColor)
	if promotedPiece=="queen" then
		promoted_pawn_str = promoted_pawn_str .. "Q"
	elseif promotedPiece=="rook" then
		promoted_pawn_str = promoted_pawn_str .. "R"
	elseif promotedPiece=="bishop" then
		promoted_pawn_str = promoted_pawn_str .. "B"
	else
		promoted_pawn_str = promoted_pawn_str .. "N"
	end
	if is_king_in_check(gameState.board,gameState.turn) then
		if is_king_in_mate(gameState.board,gameState.turn) then
			end_screen_visible = true
			promoted_pawn_str = promoted_pawn_str .. "#"
		else
			promoted_pawn_str = promoted_pawn_str .. "+"
		end
	else
		if isStalemate(gameState.board,gameState.turn) then
			end_screen_visible = true
			end_screen.text = "Stalemate"
		end
	end
	if gameState.starting == "w" then
		gameState.history[#gameState.history].move = gameState.history[#gameState.history].move .. promoted_pawn_str
		gameState.history[#gameState.history].board = cloneBoard(gameState.board)
	else
		gameState.history[#gameState.history].move = gameState.history[#gameState.history].move .. promoted_pawn_str
		gameState.history[#gameState.history].board = cloneBoard(flipBoard(gameState.board))
	end

end

function get_legal_moves(board,piece,cordx,cordy,skipCastling)

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

		p = gameState.starting=="w" and function()
			if cordy == 2 and board[cordy + 1][cordx] == nil and board[cordy + 2][cordx] == nil then
				table.insert(legal_moves, {x = cordx, y = cordy + 2, enPassant = true})
			end

			-- One-tile advance if the square in front is empty
			if cordy + 1 <= 8 and board[cordy + 1][cordx] == nil then
				table.insert(legal_moves, {x = cordx, y = cordy + 1})
			end
			if cordx-1~=0 or cordx+1~=9 then
				enPassant(board,piece,legal_moves,cordx,cordy)
				if cordy+1<9 and cordx-1>0 and board[cordy+1][cordx-1]~=nil then
					local piece_str = Piece_to_String(board[cordy+1][cordx-1].type,board[cordy+1][cordx-1].color)
					if piece_str=="P" or piece_str=="R" or piece_str=="N" or piece_str=="B" or piece_str=="Q" or piece_str=="K" then
						table.insert(legal_moves, {x = cordx-1, y = cordy + 1})
					end
				end
				if cordy+1<9 and cordx+1<9 and board[cordy+1][cordx+1]~=nil then
					local piece_str2 = Piece_to_String(board[cordy+1][cordx+1].type,board[cordy+1][cordx+1].color)
					if piece_str2=="P" or piece_str2=="R" or piece_str2=="N" or piece_str2=="B" or piece_str2=="Q" or piece_str2=="K" then
						table.insert(legal_moves, {x = cordx+1, y = cordy + 1})
					end
				end

			end
		end or function()
			if cordy == 7 and board[cordy - 1][cordx] == nil and board[cordy - 2][cordx] == nil then
				table.insert(legal_moves, {x = cordx, y = cordy - 2, enPassant = true})
			end

			-- One-tile advance if the square in front is empty
			if cordy - 1 >= 1 and board[cordy - 1][cordx] == nil then
				table.insert(legal_moves, {x = cordx, y = cordy - 1})
			end
			if cordx-1~=0 or cordx+1~=9 then
				enPassant(board,piece,legal_moves,cordx,cordy)
				if cordy-1>0 and cordx-1>0 and board[cordy-1][cordx-1]~=nil then
					local piece_str = Piece_to_String(board[cordy-1][cordx-1].type,board[cordy-1][cordx-1].color)
					if piece_str=="P" or piece_str=="R" or piece_str=="N" or piece_str=="B" or piece_str=="Q" or piece_str=="K" then
						table.insert(legal_moves, {x = cordx - 1, y = cordy - 1})
					end
				end
				if cordy-1>0 and cordx+1<9 and board[cordy-1][cordx+1]~=nil then
					local piece_str2 = Piece_to_String(board[cordy-1][cordx+1].type,board[cordy-1][cordx+1].color)
					if piece_str2=="P" or piece_str2=="R" or piece_str2=="N" or piece_str2=="B" or piece_str2=="Q" or piece_str2=="K" then
						table.insert(legal_moves, {x = cordx + 1, y = cordy - 1})
					end
				end

			end
		end,

		P = gameState.starting=="w" and function()
			if cordy == 7 and board[cordy - 1][cordx] == nil and board[cordy - 2][cordx] == nil then
				table.insert(legal_moves, {x = cordx, y = cordy - 2,enPassant = true})
			end

			-- One-tile advance if the square in front is empty
			if cordy - 1 >= 1 and board[cordy - 1][cordx] == nil then
				table.insert(legal_moves, {x = cordx, y = cordy - 1})
			end
			if cordx-1~=0 or cordx+1~=9 then
				enPassant(board,piece,legal_moves,cordx,cordy)
				if cordy-1>0 and cordx-1>0 and board[cordy-1][cordx-1]~=nil then
					local piece_str = Piece_to_String(board[cordy-1][cordx-1].type,board[cordy-1][cordx-1].color)
					if piece_str=="p" or piece_str=="r" or piece_str=="n" or piece_str=="b" or piece_str=="q" or piece_str=="k" then
						table.insert(legal_moves, {x = cordx - 1, y = cordy - 1})
					end
				end
				if cordy-1>0 and cordx+1<9 and board[cordy-1][cordx+1]~=nil then
					local piece_str2 = Piece_to_String(board[cordy-1][cordx+1].type,board[cordy-1][cordx+1].color)
					if piece_str2=="p" or piece_str2=="r" or piece_str2=="n" or piece_str2=="b" or piece_str2=="q" or piece_str2=="k" then
						table.insert(legal_moves, {x = cordx + 1, y = cordy - 1})
					end
				end

			end
		end or function()
			if cordy == 2 and board[cordy + 1][cordx] == nil and board[cordy + 2][cordx] == nil then
				table.insert(legal_moves, {x = cordx, y = cordy + 2,enPassant = true})
			end

			-- One-tile advance if the square in front is empty
			if cordy + 1 <= 8 and board[cordy + 1][cordx] == nil then
				table.insert(legal_moves, {x = cordx, y = cordy + 1})
			end
			if cordx-1~=0 or cordx+1~=9 then
				enPassant(board,piece,legal_moves,cordx,cordy)
				if cordy+1<9 and cordx-1>0 and board[cordy+1][cordx-1]~=nil then
					local piece_str = Piece_to_String(board[cordy+1][cordx-1].type,board[cordy+1][cordx-1].color)
					if piece_str=="p" or piece_str=="r" or piece_str=="n" or piece_str=="b" or piece_str=="q" or piece_str=="k"  then
						table.insert(legal_moves, {x = cordx-1, y = cordy + 1})
					end
				end
				if cordy+1<9 and cordx+1<9 and board[cordy+1][cordx+1]~=nil then
					local piece_str2 = Piece_to_String(board[cordy+1][cordx+1].type,board[cordy+1][cordx+1].color)
					if piece_str2=="p" or piece_str2=="r" or piece_str2=="n" or piece_str2=="b" or piece_str2=="q" or piece_str2=="k" then
						table.insert(legal_moves, {x = cordx+1, y = cordy + 1})
					end
				end

			end
		end,
		r = function()
			local directions = {
				{dx = 1, dy = 0},
				{dx = -1, dy = 0},
				{dx = 0, dy = 1},
				{dx = 0, dy = -1}
			}

			for _, dir in ipairs(directions) do
				for i = 1, 7 do
					local tx = cordx + dir.dx * i
					local ty = cordy + dir.dy * i

					if tx >= 1 and tx <= 8 and ty >= 1 and ty <= 8 then
						local target = board[ty][tx]

						if target == nil then
							table.insert(legal_moves, {x = tx, y = ty})
						else
							local pieceStr = Piece_to_String(target.type, target.color)
							if pieceStr:match("%u") then
								table.insert(legal_moves, {x = tx, y = ty})
							end
							break
						end
					else
						break
					end
				end
			end
		end,


		R = function()
			local directions = {
				{dx = 1, dy = 0},
				{dx = -1, dy = 0},
				{dx = 0, dy = 1},
				{dx = 0, dy = -1}
			}

			for _, dir in ipairs(directions) do
				for i = 1, 7 do
					local tx = cordx + dir.dx * i
					local ty = cordy + dir.dy * i

					if tx >= 1 and tx <= 8 and ty >= 1 and ty <= 8 then
						local target = board[ty][tx]

						if target == nil then
							table.insert(legal_moves, {x = tx, y = ty})
						else
							local pieceStr = Piece_to_String(target.type, target.color)
							if pieceStr:match("%l") then
								table.insert(legal_moves, {x = tx, y = ty})
							end
							break
						end
					else
						break
					end
				end
			end
		end,


		b = function()
			local directions = {
				{dx = 1, dy = -1},
				{dx = -1, dy = 1},
				{dx = 1, dy = 1},
				{dx = -1, dy = -1}
			}

			for _, dir in ipairs(directions) do
				for i = 1, 7 do
					local tx = cordx + dir.dx * i
					local ty = cordy + dir.dy * i

					if tx >= 1 and tx <= 8 and ty >= 1 and ty <= 8 then
						local target = board[ty][tx]
						if target == nil then
							table.insert(legal_moves, {x = tx, y = ty})
						else
							local pieceStr = Piece_to_String(target.type, target.color)
							if pieceStr:match("%u") then
								table.insert(legal_moves, {x = tx, y = ty})
							end
							break
						end
					else
						break
					end
				end
			end
		end,

		B = function()
			local directions = {
				{dx = 1, dy = -1},
				{dx = -1, dy = 1},
				{dx = 1, dy = 1},
				{dx = -1, dy = -1}
			}

			for _, dir in ipairs(directions) do
				for i = 1, 7 do
					local tx = cordx + dir.dx * i
					local ty = cordy + dir.dy * i

					if tx >= 1 and tx <= 8 and ty >= 1 and ty <= 8 then
						local target = board[ty][tx]

						if target == nil then
							table.insert(legal_moves, {x = tx, y = ty})
						else
							local pieceStr = Piece_to_String(target.type, target.color)

							if pieceStr:match("%l") then
								table.insert(legal_moves, {x = tx, y = ty})
							end

							break
						end
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
				local move = knight_moves[i]
				if move.x >= 1 and move.x <= 8 and move.y >= 1 and move.y <= 8 then
					local piece = board[knight_moves[i].y][knight_moves[i].x]
					local piece_str = nil
					if piece~=nil then
						piece_str = Piece_to_String(board[knight_moves[i].y][knight_moves[i].x].type,board[knight_moves[i].y][knight_moves[i].x].color)
					end
					if knight_moves[i].x>=1 and knight_moves[i].x<=8 and knight_moves[i].y>=1 and knight_moves[i].y<=8 and (piece_str=="P" or piece_str=="R" or piece_str=="B" or piece_str=="N" or piece_str=="Q" or piece_str=="K" or piece_str==nil) then
						table.insert(legal_moves, {x = knight_moves[i].x, y = knight_moves[i].y})
					end
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
				local move = knight_moves[i]
				if move.x >= 1 and move.x <= 8 and move.y >= 1 and move.y <= 8 then
					local piece = board[knight_moves[i].y][knight_moves[i].x]
					local piece_str = nil
					if piece~=nil then
						piece_str = Piece_to_String(board[knight_moves[i].y][knight_moves[i].x].type,board[knight_moves[i].y][knight_moves[i].x].color)
					end
					if knight_moves[i].x>=1 and knight_moves[i].x<=8 and knight_moves[i].y>=1 and knight_moves[i].y<=8 and (piece_str=="p" or piece_str=="r" or piece_str=="b" or piece_str=="n" or piece_str=="q" or piece_str=="k" or piece_str==nil) then
						table.insert(legal_moves, {x = knight_moves[i].x, y = knight_moves[i].y})
					end
				end
			end
		end,

		q = function()
			local directions = {
				{dx = 1, dy = 0},   -- right
				{dx = -1, dy = 0},  -- left
				{dx = 0, dy = 1},   -- down
				{dx = 0, dy = -1},  -- up
				{dx = 1, dy = 1},   -- bottom-right
				{dx = -1, dy = -1}, -- top-left
				{dx = 1, dy = -1},  -- top-right
				{dx = -1, dy = 1}   -- bottom-left
			}

			for _, dir in ipairs(directions) do
				for i = 1, 7 do
					local tx = cordx + dir.dx * i
					local ty = cordy + dir.dy * i

					if tx >= 1 and tx <= 8 and ty >= 1 and ty <= 8 then
						local target = board[ty][tx]

						if target == nil then
							table.insert(legal_moves, {x = tx, y = ty})
						else
							local pieceStr = Piece_to_String(target.type, target.color)

							if pieceStr:match("%u") then
								table.insert(legal_moves, {x = tx, y = ty})
							end
							break
						end
					else
						break
					end
				end
			end
		end,

		Q = function()
			local directions = {
				{dx = 1, dy = 0},   -- right
				{dx = -1, dy = 0},  -- left
				{dx = 0, dy = 1},   -- down
				{dx = 0, dy = -1},  -- up
				{dx = 1, dy = 1},   -- bottom-right
				{dx = -1, dy = -1}, -- top-left
				{dx = 1, dy = -1},  -- top-right
				{dx = -1, dy = 1}   -- bottom-left
			}

			for _, dir in ipairs(directions) do
				for i = 1, 7 do
					local tx = cordx + dir.dx * i
					local ty = cordy + dir.dy * i

					if tx >= 1 and tx <= 8 and ty >= 1 and ty <= 8 then
						local target = board[ty][tx]

						if target == nil then
							table.insert(legal_moves, {x = tx, y = ty})
						else
							local pieceStr = Piece_to_String(target.type, target.color)

							if pieceStr:match("%l") then
								table.insert(legal_moves, {x = tx, y = ty})
							end
							break
						end
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
				local move = king_moves[i]
				if move and move.x >= 1 and move.x <= 8 and move.y >= 1 and move.y <= 8 then
					local piece = board[move.y][move.x]
					local piece_str = nil
					if piece~=nil then
						piece_str = Piece_to_String(board[move.y][move.x].type,board[move.y][move.x].color)
					end
					if (piece_str=="P" or piece_str=="R" or piece_str=="N" or piece_str=="B" or piece_str=="Q" or piece_str=="K" or piece_str==nil) then
						table.insert(legal_moves, {x = move.x, y = move.y})
					end
				end
				if not skipCastling and not gameState.castling.black_king_moved and not (gameState.castling.black_rook1_moved or gameState.castling.black_rook2_moved) then
					castle(board,"k",legal_moves)
				end
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
				local move = king_moves[i]
				if move and move.x >= 1 and move.x <= 8 and move.y >= 1 and move.y <= 8 then
					local piece = board[move.y][move.x]
					local piece_str = nil
					if piece~=nil then
						piece_str = Piece_to_String(board[move.y][move.x].type,board[move.y][move.x].color)
					end
					if (piece_str=="p" or piece_str=="r" or piece_str=="n" or piece_str=="b" or piece_str=="q" or piece_str=="k" or piece_str==nil) then
						table.insert(legal_moves, {x = move.x, y = move.y})
					end
					if not skipCastling and not gameState.castling.white_king_moved and not (gameState.castling.white_rook1_moved or gameState.castling.white_rook2_moved) then
						castle(board,"K",legal_moves)
					end
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

function cloneBoard(board)
	local copy = {}
	for y = 1, 8 do
		copy[y] = {}
		for x = 1, 8 do
			local piece = board[y][x]
			if piece then
				copy[y][x] = Piece:new(piece.type, piece.color)
			else
				copy[y][x] = nil
			end
		end
	end
	return copy
end


function find_king_position(board, king)
	for y = 1, 8 do
		for x = 1, 8 do
			local piece = board[y][x]
			if piece and Piece_to_String(piece.type,piece.color) == king  then
				return {x = x, y = y}
			end
		end
	end
	print("ERROR: King '" .. king .. "' not found on board!")
	for y = 1, #board do
		for x = 1, #board[y] do
			local piece = board[y][x]
			if piece then
				local piece_str = Piece_to_String(piece.type, piece.color)
				if piece_str == "k" or piece_str == "K" then
					print("Found king: " .. piece_str .. " at " .. x .. "," .. y)
				end
			end
		end
	end
	return nil
end

function is_king_in_check(board, color)
	local king_char = (color == "w") and "K" or "k"
	local king_pos = find_king_position(board,king_char)

	-- Safety check - if king position is nil, return false to prevent crash
	if not king_pos then
		print("WARNING: King position not found for color " .. color)
		return false
	end

	for y = 1, 8 do
		for x = 1, 8 do
			local piece = board[y][x]
			if piece~=nil and string.sub(piece.color,1,1) ~= color then
				local piece_str = Piece_to_String(piece.type, piece.color)
				local moves = get_legal_moves(board,piece_str, x, y,true)
				for _, move in ipairs(moves) do
					if move.x == king_pos.x and move.y == king_pos.y then
						return true
					end
				end
			end
		end
	end
	return false
end

function is_king_in_mate(board, color)
	for y = 1, 8 do
		for x = 1, 8 do
			local piece = board[y][x]
			if piece~=nil and string.sub(piece.color,1,1) == color then
				local piece_str = Piece_to_String(piece.type, piece.color)
				local moves = get_legal_moves(board,piece_str, x, y,true)
				for _, move in ipairs(moves) do
					if not simulateMove(board, piece_str, {x=x,y=y}, move, color) then
						return false
					end
				end
			end
		end
	end
	return true
end

function isStalemate(board,turn)
	for row = 1, 8 do
		for col = 1, 8 do
			local piece = board[row][col]
			if piece and string.sub(piece.color,1,1) == turn then
				local legal_moves = get_legal_moves(board,Piece_to_String(piece.type,piece.color), col, row, false)
				for _, move in ipairs(legal_moves) do
					if not simulateMove(board, Piece_to_String(piece.type,piece.color), {x = col, y = row}, move, turn) then
						-- A legal move exists that does not expose king to check
						return false
					end
				end
			end
		end
	end

	return true -- Stalemate
end

function simulateMove(originalBoard, piece, from, to,color)
	local black_castle_queen_side =  gameState.starting=="w" and {x = 3, y = 1} or {x = 6, y = 8}
	local black_castle_king_side = gameState.starting=="w" and {x = 7, y = 1} or {x = 2, y = 8}
	local white_castle_queen_side = gameState.starting=="w" and {x = 3, y = 8} or {x = 6, y = 1}
	local white_castle_king_side = gameState.starting=="w" and {x = 7, y = 8} or {x = 2, y = 1}
	local temp_piece = nil
	local board = cloneBoard(originalBoard)
	local king_moved_by_castle = false
	if (piece=="p" or piece=="P") and (board[to.y][to.x]==nil) and ((from.x+1==to.x and from.y+1==to.y) or (from.x+1==to.x and from.y-1==to.y) or (from.x-1==to.x and from.y+1==to.y) or (from.x-1==to.x and from.y-1==to.y)) then
		if (piece=="p" and gameState.starting=="b") or (piece=="P" and gameState.starting=="w") then
			local opposing_pawn = board[to.y+1][to.x]
			if opposing_pawn.eligible_for_enPassant then
				board[to.y+1][to.x] = nil
			end
		elseif (piece=="P" and gameState.starting=="b") or (piece=="p" and gameState.starting=="w") then
			local opposing_pawn = board[to.y-1][to.x]
			if opposing_pawn.eligible_for_enPassant then
				board[to.y-1][to.x] = nil
			end
		end
	end
	if piece=="k" and gameState.starting=="w" then
		if black_castle_queen_side.x==to.x and black_castle_queen_side.y==to.y then
			local rook = board[1][1]
			local king = board[from.y][from.x]
			board[from.y][from.x] = nil
			board[1][1] = nil
			board[1][4] = rook
			board[to.y][to.x] = king
			king_moved_by_castle = true
		elseif black_castle_king_side.x==to.x and black_castle_king_side.y==to.y then
			local rook = board[1][8]
			local king = board[from.y][from.x]
			board[from.y][from.x] = nil
			board[1][8] = nil
			board[1][6] = rook
			board[to.y][to.x] = king
			king_moved_by_castle = true
		end
	end
	if piece=="k" and gameState.starting=="b" then
		if black_castle_queen_side.x==to.x and black_castle_queen_side.y==to.y then
			local rook = board[8][8]
			local king = board[from.y][from.x]
			board[from.y][from.x] = nil
			board[8][8] = nil
			board[8][5] = rook
			board[to.y][to.x] = king
			king_moved_by_castle = true
		elseif black_castle_king_side.x==to.x and black_castle_king_side.y==to.y then
			local rook = board[8][1]
			local king = board[from.y][from.x]
			board[from.y][from.x] = nil
			board[8][1] = nil
			board[8][3] = rook
			board[to.y][to.x] = king
			king_moved_by_castle = true
		end
	end
	if piece=="K" and gameState.starting=="w" then
		if white_castle_queen_side.x==to.x and white_castle_queen_side.y==to.y then
			local rook = board[8][1]
			local king = board[from.y][from.x]
			board[from.y][from.x] = nil
			board[8][1] = nil
			board[8][4] = rook
			board[to.y][to.x] = king
			king_moved_by_castle = true
		elseif white_castle_king_side.x==to.x and white_castle_king_side.y==to.y then
			local rook = board[8][8]
			local king = board[from.y][from.x]
			board[from.y][from.x] = nil
			board[8][8] = nil
			board[8][6] = rook
			board[to.y][to.x] = king
			king_moved_by_castle = true
		end
	end
	if piece=="K" and gameState.starting=="b" then
		if white_castle_queen_side.x==to.x and white_castle_queen_side.y==to.y then
			local rook = board[1][8]
			local king = board[from.y][from.x]
			board[from.y][from.x] = nil
			board[1][8] = nil
			board[1][5] = rook
			board[to.y][to.x] = king
			king_moved_by_castle = true
		elseif white_castle_king_side.x==to.x and white_castle_king_side.y==to.y then
			local rook = board[1][1]
			local king = board[from.y][from.x]
			board[from.y][from.x] = nil
			board[1][1] = nil
			board[1][3] = rook
			board[to.y][to.x] = king
			king_moved_by_castle = true
		end
	end
	if not king_moved_by_castle then
		temp_piece = board[from.y][from.x]
		board[from.y][from.x] = nil
		board[to.y][to.x] = temp_piece
	end
	return is_king_in_check(board, color)
end


function move_piece(piece, from, to, turn)

	if gameState.history and #gameState.history > 0 and gameState.history[#gameState.history].board and
			not areBoardsEqual(gameState.board, gameState.history[#gameState.history].board) and gameState.history_move_index~=nil then
		local new_history = {}
		for i, move in ipairs(gameState.history) do
			if gameState.history_move_index~=nil  then
				if i<gameState.history_move_index then
					table.insert(new_history,{move=move.move,board=move.board,turn=move.turn})
				elseif i==gameState.history_move_index then
					table.insert(new_history,{move=move.move,board= gameState.starting=="w" and cloneBoard(gameState.board) or cloneBoard(flipBoard(gameState.board)),turn=move.turn})
				end
			end
		end
		gameState.history = new_history
		gameState.history_move_index = nil
	end



	local black_castle_queen_side =  gameState.starting=="w" and {x = 3, y = 1} or {x = 6, y = 8}
	local black_castle_king_side = gameState.starting=="w" and {x = 7, y = 1} or {x = 2, y = 8}
	local white_castle_queen_side = gameState.starting=="w" and {x = 3, y = 8} or {x = 6, y = 1}
	local white_castle_king_side = gameState.starting=="w" and {x = 7, y = 8} or {x = 2, y = 1}
	local temp_piece = nil
	local legal_moves = is_king_in_check(gameState.board, gameState.turn=="w" and "K" or "k") and get_legal_moves(gameState.board,piece,from.x,from.y,true) or get_legal_moves(gameState.board,piece,from.x,from.y,false)
	local filtered_moves = {}
	local king_moved_by_castle = false
	local moves = ""

	for _, move in ipairs(legal_moves) do
		if not simulateMove(gameState.board, piece, from, move, turn) then
			table.insert(filtered_moves, move)
		end
	end

	for i=1, #filtered_moves do
		if filtered_moves[i].x==to.x and filtered_moves[i].y==to.y then
			if (piece=="p" or piece=="P") and (gameState.board[to.y][to.x]==nil) and ((from.x+1==to.x and from.y+1==to.y) or (from.x+1==to.x and from.y-1==to.y) or (from.x-1==to.x and from.y+1==to.y) or (from.x-1==to.x and from.y-1==to.y)) then
				if (piece=="p" and gameState.starting=="b") or (piece=="P" and gameState.starting=="w") then
					local opposing_pawn = gameState.board[to.y+1][to.x]
					if opposing_pawn.eligible_for_enPassant then
						gameState.board[to.y+1][to.x] = nil
					end
				elseif (piece=="P" and gameState.starting=="b") or (piece=="p" and gameState.starting=="w") then
					local opposing_pawn = gameState.board[to.y-1][to.x]
					if opposing_pawn.eligible_for_enPassant then
						gameState.board[to.y-1][to.x] = nil
					end
				end
				moves = get_pawn_cordy(from.x).."x"
				gameState.halfmove_clock = 0
			end
			if piece=="k" and gameState.starting=="w" and not gameState.castling.black_king_moved then
				if black_castle_queen_side.x==to.x and black_castle_queen_side.y==to.y then
					local rook = gameState.board[1][1]
					local king = gameState.board[from.y][from.x]
					gameState.board[from.y][from.x] = nil
					gameState.board[1][1] = nil
					gameState.board[1][4] = rook
					gameState.board[to.y][to.x] = king
					king_moved_by_castle = true
					moves = "O-O-O"
				elseif black_castle_king_side.x==to.x and black_castle_king_side.y==to.y then
					local rook = gameState.board[1][8]
					local king = gameState.board[from.y][from.x]
					gameState.board[from.y][from.x] = nil
					gameState.board[1][8] = nil
					gameState.board[1][6] = rook
					gameState.board[to.y][to.x] = king
					king_moved_by_castle = true
					moves = "O-O"
				end
				gameState.castling.black_king_moved=true
				gameState.halfmove_clock = gameState.halfmove_clock + 1
			end
			if piece=="k" and gameState.starting=="b" and not gameState.castling.black_king_moved then
				if black_castle_queen_side.x==to.x and black_castle_queen_side.y==to.y then
					local rook = gameState.board[8][8]
					local king = gameState.board[from.y][from.x]
					gameState.board[from.y][from.x] = nil
					gameState.board[8][8] = nil
					gameState.board[8][5] = rook
					gameState.board[to.y][to.x] = king
					king_moved_by_castle = true
					moves = "O-O-O"
				elseif black_castle_king_side.x==to.x and black_castle_king_side.y==to.y then
					local rook = gameState.board[8][1]
					local king = gameState.board[from.y][from.x]
					gameState.board[from.y][from.x] = nil
					gameState.board[8][1] = nil
					gameState.board[8][3] = rook
					gameState.board[to.y][to.x] = king
					king_moved_by_castle = true
					moves = "O-O"
				end
				gameState.castling.black_king_moved=true
				gameState.halfmove_clock = gameState.halfmove_clock + 1
			end
			if piece=="K" and gameState.starting=="w" and not gameState.castling.white_king_moved then
				if white_castle_queen_side.x==to.x and white_castle_queen_side.y==to.y then
					local rook = gameState.board[8][1]
					local king = gameState.board[from.y][from.x]
					gameState.board[from.y][from.x] = nil
					gameState.board[8][1] = nil
					gameState.board[8][4] = rook
					gameState.board[to.y][to.x] = king
					king_moved_by_castle = true
					moves = "O-O-O"
				elseif white_castle_king_side.x==to.x and white_castle_king_side.y==to.y then
					local rook = gameState.board[8][8]
					local king = gameState.board[from.y][from.x]
					gameState.board[from.y][from.x] = nil
					gameState.board[8][8] = nil
					gameState.board[8][6] = rook
					gameState.board[to.y][to.x] = king
					king_moved_by_castle = true
					moves = "O-O"
				end
				gameState.castling.white_king_moved=true
				gameState.halfmove_clock = gameState.halfmove_clock + 1
			end
			if piece=="K" and gameState.starting=="b" and not gameState.castling.white_king_moved then
				if white_castle_queen_side.x==to.x and white_castle_queen_side.y==to.y then
					local rook = gameState.board[1][8]
					local king = gameState.board[from.y][from.x]
					gameState.board[from.y][from.x] = nil
					gameState.board[1][8] = nil
					gameState.board[1][5] = rook
					gameState.board[to.y][to.x] = king
					king_moved_by_castle = true
					moves = "O-O-O"
				elseif white_castle_king_side.x==to.x and white_castle_king_side.y==to.y then
					local rook = gameState.board[1][1]
					local king = gameState.board[from.y][from.x]
					gameState.board[from.y][from.x] = nil
					gameState.board[1][1] = nil
					gameState.board[1][3] = rook
					gameState.board[to.y][to.x] = king
					king_moved_by_castle = true
					moves = "O-O"
				end
				gameState.castling.white_king_moved=true
				gameState.halfmove_clock = gameState.halfmove_clock + 1
			end
			if not king_moved_by_castle then
				temp_piece = gameState.board[from.y][from.x]
				if gameState.board[to.y][to.x]==nil then
					if temp_piece.type~="pawn" then
						moves = string.upper(string.sub(piece,1,1))
						local a = is_other_piece_sharing_to_cords(temp_piece.color,{x=from.x,y=from.y},{x=to.x,y=to.y},Piece_to_String(temp_piece.type,temp_piece.color))
						if a then
							moves = moves .. get_pawn_cordy(from.x)
						end
						gameState.halfmove_clock = gameState.halfmove_clock + 1
					else
						gameState.halfmove_clock = 0
					end
					moves = moves .. arrCord_to_chessCord({x=to.x,y=to.y})
				else
					if temp_piece.type~="pawn" then
						local a = is_other_piece_sharing_to_cords(temp_piece.color,{x=from.x,y=from.y},{x=to.x,y=to.y},Piece_to_String(temp_piece.type,temp_piece.color))
						if a then
							moves = string.upper(string.sub(piece,1,1)) .. get_pawn_cordy(from.x) .. "x"
						else
							moves = string.upper(string.sub(piece,1,1)).."x"
						end
					else
						moves = get_pawn_cordy(from.x).."x"
					end
					moves = moves .. arrCord_to_chessCord({x=to.x,y=to.y})
					gameState.halfmove_clock = 0
				end
				gameState.board[from.y][from.x] = nil
				gameState.board[to.y][to.x] = temp_piece
				if temp_piece.type=="pawn" then
					local temp_piece_str = Piece_to_String(temp_piece.type, temp_piece.color)
					if (temp_piece_str=="p" and gameState.starting=="b" and to.y==1) or (temp_piece_str=="P" and gameState.starting=="w" and to.y==1) then
						if temp_piece_str=="p" then
							popup.color="black"
						else
							popup.color="white"
						end
						popup.to = to
						popupVisible = true
					elseif (temp_piece_str=="p" and gameState.starting=="w" and to.y==8) or (temp_piece_str=="P" and gameState.starting=="b" and to.y==8) then
						if temp_piece_str=="p" then
							popup.color="black"
						else
							popup.color="white"
						end
						popup.to = to
						popupVisible = true
					end
				end
			end
			if gameState.prev_enPassant.x~=nil then
				if gameState.starting=="b" then
					if gameState.board[gameState.prev_enPassant.y][gameState.prev_enPassant.x]~=nil then
						gameState.board[gameState.prev_enPassant.y][gameState.prev_enPassant.x].eligible_for_enPassant = false
					end
				else
					if gameState.board[9-gameState.prev_enPassant.y][9-gameState.prev_enPassant.x]~=nil then
						gameState.board[9-gameState.prev_enPassant.y][9-gameState.prev_enPassant.x].eligible_for_enPassant = false
					end
				end
				gameState.prev_enPassant = {x = nil, y = nil}
			end
			if filtered_moves[i].enPassant==true then
				gameState.board[to.y][to.x].eligible_for_enPassant = true
				gameState.prev_enPassant = {x = to.x, y = to.y}
			end
			if turn=="b" then
				gameState.turn="w"
				gameState.fullmove=gameState.fullmove+1
			else
				gameState.turn="b"
			end
			if is_king_in_check(gameState.board,gameState.turn) then
				if is_king_in_mate(gameState.board,gameState.turn) then
					end_screen_visible = true
					moves = moves .. "#"
				else
					moves = moves .. "+"
				end
			else
				if isStalemate(gameState.board,gameState.turn) then
					end_screen_visible = true
					end_screen.text = "Stalemate"
				end
			end
			if gameState.halfmove_clock==100 then
				end_screen_visible = true
				end_screen.text = "Stalemate"
				end_screen.winner = "Halfmove reached 100"
			end
		else
			-- Invalid moving position
		end
	end
	if moves~=nil and moves~="" then
		if gameState.starting == "w" then
			table.insert(gameState.history,{move=moves,board=cloneBoard(gameState.board),turn=gameState.turn})
		else
			table.insert(gameState.history,{move=moves,board=cloneBoard(flipBoard(gameState.board)),turn=gameState.turn})
		end
	end
end

function get_pawn_cordy(x)
	local cord_for_white = {
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g",
		"h"
	}
	local cord_for_black = {
		"h",
		"g",
		"f",
		"e",
		"d",
		"c",
		"b",
		"a"
	}
	if gameState.starting=="w" then
		return cord_for_white[x]
	else
		return cord_for_black[x]
	end
end

function arrCord_to_chessCord(arrCord)
	local cord = nil
	if gameState.starting=="w" then
		cord = cord_for_white[arrCord.x]..tostring((9-arrCord.y))
	else
		cord = cord_for_black[arrCord.x]..tostring((arrCord.y))
	end
	return cord
end

function chessCord_to_arrCord(chessCord)
	local cord = nil
	local cord_for_black = {
		a=8,
		b=7,
		c=6,
		d=5,
		e=4,
		f=3,
		g=2,
		h=1
	}
	local cord_for_white = {
		h=8,
		g=7,
		f=6,
		e=5,
		d=4,
		c=3,
		b=2,
		a=1
	}
	if gameState.starting=="w" then
		cord = {y=9-tonumber(string.sub(chessCord,2,2))-1, x=cord_for_white[string.sub(chessCord,1,1)]}
	else
		cord = {y=tonumber(string.sub(chessCord,2,2))+1, x=cord_for_black[string.sub(chessCord,1,1)]}
	end
	return cord
end

function is_other_piece_sharing_to_cords(color,piece1_from_cord,piece1_to_cord,piece1)
	for y = 1, 8 do
		for x = 1, 8 do
			local piece = gameState.board[y][x]
			if piece and Piece_to_String(piece.type,piece.color) == piece1 and ((piece1_from_cord.x~=x and piece1_from_cord.y~=y) or (piece1_from_cord.x==x and piece1_from_cord.y~=y) or (piece1_from_cord.x~=x and piece1_from_cord.y==y)) then
				local moves = get_legal_moves(gameState.board,piece1,x,y,true)
				for _, move in ipairs(moves) do
					if not simulateMove(gameState.board, piece1, {x=x,y=y}, move, color) then
						if move.x==piece1_to_cord.x and move.y==piece1_to_cord.y then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

function restart_game()
	gameState = {
		starting = "w",
		turn = "w",
		board = setupBoard("w"),
		selectedPiece = nil,
		selectedPieceColor = nil,
		selectedPos = {x = nil, y = nil},
		prev_enPassant = {x = nil, y = nil},
		enPassant = nil,
		castling ={
			white_king_moved = false,
			black_king_moved = false,
			black_rook1_moved = false,
			black_rook2_moved = false,
			white_rook1_moved = false,
			white_rook2_moved = false
		},
		halfmove_clock = 0,
		fullmove = 0,
		history = {},
		historyClickRegions = {},
		history_move_index = nil,
		historyScrollY = 0,
		historyScrollSpeed = 20
	}
	popupVisible = false
end

function change_history_move_index(index,next)
	if next then
		if index+1<=#gameState.history then
			if gameState.starting=="w" then
				gameState.board =  cloneBoard(gameState.history[index+1].board)
			else
				gameState.board = flipBoard(cloneBoard(gameState.history[index+1].board))
			end
			gameState.turn = gameState.history[index+1].turn
			if index+1==#gameState.history then
				gameState.history_move_index = nil
			else
				gameState.history_move_index = index + 1
			end

		end
	else
		if index-1>0 then
			if gameState.starting=="w" then
				gameState.board =  cloneBoard(gameState.history[index-1].board)
			else
				gameState.board = flipBoard(cloneBoard(gameState.history[index-1].board) )
			end
			gameState.turn = gameState.history[index-1].turn
			gameState.history_move_index = index - 1
		end
	end
	gameState.selectedPiece = nil
	gameState.selectedPieceColor = nil
	gameState.selectedPos = {x = nil, y = nil}
end

love.window.setMode(1000, 600, {
	resizable = true,
	minwidth = 500,
	minheight = 300,
	vsync = true
})


function love.load()
	anim8 = require "libraries/anim8"

	love.graphics.setDefaultFilter("nearest","nearest")


	gameState = {
		starting = "w",
		turn = "w", -- 1 for white, 0 for black
		board = setupBoard("w"),
		selectedPiece = nil,
		selectedPieceColor = nil,
		selectedPos = {x = nil, y = nil},
		prev_enPassant = {x = nil, y = nil},
		enPassant = nil,
		castling ={
			white_king_moved = false,
			black_king_moved = false,
			black_rook1_moved = false,
			black_rook2_moved = false,
			white_rook1_moved = false,
			white_rook2_moved = false
		},
		halfmove_clock = 0,
		fullmove = 0,
		history = {},
		historyClickRegions = {},
		history_move_index = nil,
		historyScrollY = 0,
		historyScrollSpeed = 20
	}

	--Booleans and scroll
	left_side_present = false

	popupVisible = false

	end_screen_visible = false

	FENPanelScrollY = 0

	--Constants
	backspaceHeld = false
	backspaceTimer = 0
	backspaceDelay = 0.4
	backspaceRepeat = 0.05

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

	cord_for_white = {
		"a",
		"b",
		"c",
		"d",
		"e",
		"f",
		"g",
		"h"
	}
	cord_for_black = {
		"h",
		"g",
		"f",
		"e",
		"d",
		"c",
		"b",
		"a"
	}

	--Screen calculations
	screen_width = love.graphics.getWidth()
	screen_height = love.graphics.getHeight()

	cellsize = math.min(screen_width, screen_height) / 8

	--Drawable Contents
	popup = {
		scaleX = 1.5*cellsize / 32,
		scaleY = 1.5*cellsize / 32,
		width = 6*cellsize,
		height = 3*cellsize,
		color = nil,
		to = nil,
		title = "Promote",
		message = "Select a piece",
		buttons = {
			{ text = "rook", x = cellsize, y = 4*cellsize, width = 1.5*cellsize, height = 1.5*cellsize, onClick = function()
				promotePawn(popup.color, "rook", popup.to)
				popupVisible = false
			end
			} ,
			{ text = "knight",  x = 2.5*cellsize, y = 4*cellsize, width = 1.5*cellsize, height = 1.5*cellsize, onClick = function()
				promotePawn(popup.color, "knight", popup.to)
				popupVisible = false
			end
		} ,
			{ text = "bishop", x = 4*cellsize, y = 4*cellsize, width = 1.5*cellsize, height = 1.5*cellsize, onClick = function()
				promotePawn(popup.color, "bishop", popup.to)
				popupVisible = false
			end
			} ,
			{ text = "queen",  x = 5.5*cellsize, y = 4*cellsize, width = 1.5*cellsize, height = 1.5*cellsize, onClick = function()
			promotePawn(popup.color, "queen", popup.to)
			popupVisible = false
			end
			}
		}
	}

	newGame_button = {
		x = (((screen_width - (cellsize * 8)) / 2)-(cellsize*2))/2,
		y = 50,
		height = 50,
		text = "New Board",
		onClick = function()
			restart_game()
		end
	}

	flipBoard_button = {
		x = (((screen_width - (cellsize * 8)) / 2)-(cellsize*2))/2,
		y = 110,
		width = cellsize*2,
		height = 50,
		text = "Flip Board",
		onClick = function()
			gameState.board = flipBoard(gameState.board)
			if gameState.starting=="w" then
				gameState.starting = "b"
			else
				gameState.starting = "w"
			end
		end
	}

	FEN_input = {
		text = "Input FEN here",
		active = false,
		selectAll = false,
		x = (((screen_width - (cellsize * 8)) / 2)-(cellsize*2))/2,
		y = 170,
		height = 70
	}


	loadFEN_button = {
		x = (((screen_width - (cellsize * 8)) / 2)-(cellsize*2))/2,
		y = 250,
		height = 50,
		text = "Load FEN",
		onClick = function()
			if FEN_input.text=="" or FEN_input.text==nil or FEN_input.text=="Input FEN here" then
			else
				gameState.board, gameState.turn, gameState.castling, gameState.enPassant, gameState.halfmove_clock, gameState.fullmove = translate_fen(FEN_input.text)
				gameState.history = {}
				if gameState.turn=="b" then
					table.insert(gameState.history,{move = "...", board = nil})
				end
				gameState.starting="b"
				if gameState.enPassant~="-" then
					gameState.prev_enPassant = chessCord_to_arrCord(gameState.enPassant)
					gameState.board[gameState.prev_enPassant.y][gameState.prev_enPassant.x].eligible_for_enPassant=true
					gameState.enPassant = "-"
				end

			end
		end
	}

	generateFEN_button = {
		x = (((screen_width - (cellsize * 8)) / 2)-(cellsize*2))/2,
		y = 310,
		height = 50,
		text = "Generate FEN",
		onClick = function()
			generate_fen(gameState.board)
		end
	}

	end_screen = {
		width = cellsize * 4,
		height = cellsize * 3,
		x = (screen_width - cellsize * 4)/2,
		y = (screen_height - cellsize * 3)/2,
		text = "Checkmate",
		winner = "Checkmate",
		end_screen_restart = {
			width = cellsize*4-30,
			height = 30,
			x = (screen_width - cellsize * 4)/2+15,
			y = (screen_height - cellsize * 3)/2+cellsize * 3-50,
			text = "Restart",
			onClick = function()
				restart_game()
				end_screen_visible = false
			end
		}
	}

	next_button = {
		y = screen_height - 60,
		height = 40,
		text = "Next",
		onClick = function()
			if gameState.history_move_index~=nil then
				change_history_move_index(gameState.history_move_index,true)
			end
		end
	}

	prev_button = {
		y = screen_height - 60,
		height = 40,
		text = "Prev",
		onClick = function()
			if gameState.history_move_index~=nil then
				change_history_move_index(gameState.history_move_index,false)
			else
				change_history_move_index(#gameState.history,false)
			end
	end
	}

end

function love.resize(w, h)
	screen_width = w
	screen_height = h
	cellsize = math.min(screen_width, screen_height) / 8


	popup.width = 6*cellsize
	popup.height = 3*cellsize
	popup.scaleX = 1.5*cellsize / 32
	popup.scaleY = 1.5*cellsize / 32
	for i, btn in ipairs(popup.buttons) do
		btn.x = (i-1)*1.5*cellsize + cellsize
		btn.y = 4*cellsize
		btn.height = 1.5*cellsize
		btn.width = 1.5*cellsize
	end

	end_screen.width = cellsize * 4
	end_screen.height = cellsize * 3
	end_screen.x = (screen_width - end_screen.width) / 2
	end_screen.y = (screen_height - end_screen.height) / 2
	end_screen.end_screen_restart.width = end_screen.width - 30
	end_screen.end_screen_restart.height = 30
	end_screen.end_screen_restart.x = end_screen.x + 15
	end_screen.end_screen_restart.y = end_screen.y + end_screen.height - 50

	prev_button.y = h - 60
	next_button.y = h - 60
end

function mouseInHistoryPanel()
	local xOffset = (screen_width - (cellsize * 8)) / 2
	local mx, my = love.mouse.getPosition()
	local panelX = left_side_present and screen_width - xOffset or screen_width - 2 * xOffset
	return mx >= panelX and mx <= screen_width and my >= 0 and my <= screen_height
end

function mouseInLeftSide()
	local xOffset = (screen_width - (cellsize * 8)) / 2
	local panelWidth = xOffset
	local mx, my = love.mouse.getPosition()
	return mx >= 0 and mx <= panelWidth and my >= 0 and my <= screen_height
end

function love.wheelmoved(x, y)
	if mouseInHistoryPanel() then
		gameState.historyScrollY = gameState.historyScrollY + y * gameState.historyScrollSpeed
		local maxScroll = math.max(0, #gameState.history * 14 - screen_height + 60)
		gameState.historyScrollY = math.min(0, math.max(-maxScroll, gameState.historyScrollY))
	end
	if mouseInLeftSide() then
		FENPanelScrollY = FENPanelScrollY + y * 20
		maxScrollY = math.max(0, (generateFEN_button.y + generateFEN_button.height + 40) - screen_height)
		FENPanelScrollY = math.max(math.min(FENPanelScrollY, 0), -maxScrollY)
	end
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

	local xOffset = (screen_width - (cellsize * 8)) / 2
	local panelX = 0
	local panelWidth = xOffset
	local panelHeight = screen_height

	if xOffset>=140 then
		love.graphics.push("all")
		love.graphics.setScissor(panelX, 0, panelWidth, panelHeight)
		love.graphics.translate(0, FENPanelScrollY)

		left_side_present = true

		love.graphics.setColor(0.2, 0.6, 1)
		love.graphics.rectangle("fill", newGame_button.x, newGame_button.y, (xOffset-2*flipBoard_button.x), newGame_button.height, 10)

		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(newGame_button.text, newGame_button.x, newGame_button.y + 15, (xOffset-2*flipBoard_button.x), "center")

		love.graphics.setColor(0.2, 0.6, 1)
		love.graphics.rectangle("fill", flipBoard_button.x, flipBoard_button.y, (xOffset-2*flipBoard_button.x), flipBoard_button.height, 10)

		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(flipBoard_button.text, flipBoard_button.x, flipBoard_button.y + 15, (xOffset-2*flipBoard_button.x), "center")

		if FEN_input.active then
			love.graphics.setColor(0.2, 0.2, 0.2)  -- dark gray for active
		else
			love.graphics.setColor(0.15, 0.15, 0.15)  -- darker gray for inactive
		end
		love.graphics.rectangle("fill", FEN_input.x, FEN_input.y, (xOffset-2*flipBoard_button.x), FEN_input.height)

		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(FEN_input.text, FEN_input.x + 5, FEN_input.y + 8, (xOffset-2*flipBoard_button.x) - 10, "left")

		love.graphics.setColor(0.2, 0.6, 1)
		love.graphics.rectangle("fill", loadFEN_button.x, loadFEN_button.y, (xOffset-2*flipBoard_button.x), loadFEN_button.height, 10)

		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(loadFEN_button.text, loadFEN_button.x, loadFEN_button.y + 15, (xOffset-2*flipBoard_button.x), "center")

		love.graphics.setColor(0.2, 0.6, 1)
		love.graphics.rectangle("fill", generateFEN_button.x, generateFEN_button.y, (xOffset-2*flipBoard_button.x), generateFEN_button.height, 10)

		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(generateFEN_button.text, generateFEN_button.x, generateFEN_button.y + 15, (xOffset-2*flipBoard_button.x), "center")

		love.graphics.setScissor()
		love.graphics.pop()
	else
		left_side_present = false
	end

	love.graphics.setBackgroundColor(love.math.colorFromBytes(235, 236, 208))



	for y=1, #map do
		for x=1, #map[y] do
			local drawX = left_side_present and xOffset + (x - 1) * cellsize or (x - 1) * cellsize
			local drawY = (y - 1) * cellsize
			--draw cells
			if map[y][x] == 0 then
				love.graphics.rectangle("line", drawX, drawY, cellsize, cellsize)
			elseif map[y][x] == 1 then
				love.graphics.setColor(love.math.colorFromBytes(115, 149, 82))
				love.graphics.rectangle("fill", drawX, drawY, cellsize, cellsize)
			end
			--Draw cord helpers
			love.graphics.setColor(0, 0, 0)
			if x==1 then
				if gameState.starting=="w" then
					love.graphics.printf(tostring(9-y),  drawX+2, drawY+2, cellsize, "left")
				else
					love.graphics.printf(tostring(y),  drawX+2, drawY+2, cellsize, "left")
				end
			end
			if y==8 then
				if gameState.starting=="w" then
					love.graphics.printf(cord_for_white[x],  drawX, screen_height-0.2*cellsize, cellsize-2, "right")
				else
					love.graphics.printf(cord_for_black[x],  drawX, screen_height-0.2*cellsize, cellsize-2, "right")
				end
			end

			-- Highlight the selected piece
			if gameState.selectedPiece and gameState.selectedPos.x == x and gameState.selectedPos.y == y then
				love.graphics.setColor(1, 1, 0, 0.5) -- Yellow with transparency
				love.graphics.rectangle("fill", drawX, drawY, cellsize, cellsize)
			end

			-- Draw piece
			love.graphics.setColor(1,1,1)
			local piece = gameState.board[y][x]
			if piece and piece ~= nil then
				love.graphics.draw(pieceSprites[Piece_to_String(piece.type,piece.color)], drawX, drawY, 0, cellsize / pieceSprites[Piece_to_String(piece.type,piece.color)]:getWidth(), cellsize / pieceSprites[Piece_to_String(piece.type,piece.color)]:getHeight())
			end
		end
	end

	if popupVisible then
		-- Draw background box
		love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
		love.graphics.rectangle("fill", left_side_present and  xOffset+cellsize or cellsize, 2.5*cellsize, popup.width, popup.height, 10, 10)

		-- Draw title and message
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(popup.title, left_side_present and  xOffset+cellsize or cellsize, 2.5*cellsize + 10, popup.width, "center")
		love.graphics.printf(popup.message, left_side_present and  xOffset+cellsize or cellsize, 2.5*cellsize + 30, popup.width, "center")

		-- Draw buttons
		for _, btn in ipairs(popup.buttons) do
			local img = pieceSprites[Piece_to_String(btn.text,popup.color)]
			love.graphics.setColor(0.4, 0.4, 0.4)
			love.graphics.draw(img,left_side_present and btn.x+xOffset or btn.x, btn.y, 0, popup.scaleX, popup.scaleY)
			love.graphics.setColor(1, 1, 1)
		end
	end

	if end_screen_visible then
		-- Box
		love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
		love.graphics.rectangle("fill",left_side_present and end_screen.x or (8*cellsize - end_screen.width) / 2, end_screen.y, end_screen.width, end_screen.height, 10, 10)

		-- Title
		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(end_screen.text, left_side_present and end_screen.x or (8*cellsize - end_screen.width) / 2, end_screen.y + 10, end_screen.width, "center")

		-- Winner message
		if end_screen.winner ~="Stalemate" then
			end_screen.winner = gameState.turn == "b" and "White won" or "Black won"
		end

		love.graphics.printf(end_screen.winner, left_side_present and end_screen.x or (8*cellsize - end_screen.width) / 2, end_screen.y + 40, end_screen.width, "center")


		local img = pieceSprites[gameState.turn == "b" and "P" or "p"]

		if img then
			local scale = cellsize / img:getWidth()
			local imgX = left_side_present and end_screen.x + (end_screen.width - cellsize) / 2 or (8*cellsize - end_screen.width) / 2 + (end_screen.width - cellsize) / 2
			local imgY = end_screen.y + (end_screen.height - cellsize) / 2
			love.graphics.setColor(1, 1, 1)
			love.graphics.draw(img, imgX, imgY, 0, scale, scale)
		end

		-- Restart Button
		love.graphics.setColor(0.2, 0.6, 1)
		love.graphics.rectangle("fill", left_side_present and end_screen.end_screen_restart.x or 2*cellsize+15, end_screen.end_screen_restart.y, end_screen.end_screen_restart.width, end_screen.end_screen_restart.height, 10)

		love.graphics.setColor(1, 1, 1)
		love.graphics.printf(end_screen.end_screen_restart.text, left_side_present and end_screen.end_screen_restart.x or 2*cellsize+15, end_screen.end_screen_restart.y + 7, end_screen.end_screen_restart.width, "center")

		-- Background
		love.graphics.setBackgroundColor(love.math.colorFromBytes(235, 236, 208))
	end

	love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
	love.graphics.rectangle("fill",left_side_present and screen_width - xOffset or screen_width - 2*xOffset, 0, left_side_present and screen_width - 8*cellsize - xOffset or screen_width - 8*cellsize, screen_height)

	-- Draw the move history text
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("Move History", left_side_present and screen_width - xOffset or screen_width - 2*xOffset, 0, left_side_present and screen_width - 8*cellsize - xOffset or screen_width - 8*cellsize, "center")


	--Drawing Next button
	love.graphics.setColor(0.2, 0.6, 1)
	love.graphics.rectangle("fill", left_side_present and screen_width - xOffset/2 or screen_width - xOffset, next_button.y, left_side_present and xOffset/2 or xOffset, next_button.height, 10, 10)
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(next_button.text, left_side_present and screen_width - xOffset/2 or screen_width - xOffset, next_button.y + 10,  xOffset/2, "center")

	--Drawing Previous button
	love.graphics.setColor(0.2, 0.6, 1)
	love.graphics.rectangle("fill", left_side_present and screen_width - xOffset or screen_width - 2*xOffset, prev_button.y, left_side_present and xOffset/2 or xOffset, prev_button.height, 10, 10)
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(prev_button.text, left_side_present and screen_width - xOffset or screen_width - 2*xOffset, prev_button.y + 10,  xOffset/2, "center")

	if gameState.history~=nil then
		gameState.historyClickRegions = {}

		love.graphics.push("all")
		love.graphics.setScissor(screen_width - 2*xOffset, 0, 2*xOffset, screen_height-100) -- Optional: only render in bounds
		love.graphics.translate(0, gameState.historyScrollY)

		for i, move in ipairs(gameState.history) do
			local x, y
			local text
			if i % 2 == 0 then
				x = left_side_present and screen_width - xOffset + 70 or screen_width - 2*xOffset + 70
				y = 30 + (i-1) * 12
				text = " " .. move.move
			else
				local move_number = i / 2 + 0.5
				x = left_side_present and screen_width - xOffset + 10 or screen_width - 2*xOffset + 10
				y = 30 + i * 12
				text = move_number .. ". " .. move.move
			end

			-- Draw move
			love.graphics.printf(text, x, y, 60, "left")

			-- Estimate text width and height
			local font = love.graphics.getFont()
			local width = font:getWidth(text)
			local height = font:getHeight()


			table.insert(gameState.historyClickRegions, {
				x = x,
				y = y - gameState.historyScrollY,
				width = width,
				height = height,
				moveIndex = i,
				board = move.board,
				turn = move.turn,
			})

		end
		love.graphics.setScissor()
		love.graphics.pop()
	end
end



function love.mousepressed(x, y, button)

	local xOffset =  (screen_width - (cellsize * 8)) / 2

	if popupVisible then
		for _, btn in ipairs(popup.buttons) do
			if x >= (left_side_present and btn.x+xOffset or btn.x) and x <= (left_side_present and btn.x+xOffset or btn.x) + btn.width and
					y >= btn.y and y <= btn.y + btn.height then
				btn.onClick()
				return -- ⛔ Don't allow clicks to fall through!
			end
		end
		return -- ⛔ Block all other clicks behind popup
	end

	if end_screen_visible then
		local restart_x = left_side_present and end_screen.end_screen_restart.x or 2*cellsize+15
		if x >= restart_x and x <= restart_x + end_screen.end_screen_restart.width and
				y >= end_screen.end_screen_restart.y and y <= end_screen.end_screen_restart.y + end_screen.end_screen_restart.height then
			end_screen.end_screen_restart.onClick()
			return -- ⛔ Don't allow clicks to fall through!
		end
		return -- ⛔ Block all other clicks behind popup
	end



	if button == 1 then

		if left_side_present then
			local adjustedY = y - FENPanelScrollY

			if x >= newGame_button.x and x <= newGame_button.x + (xOffset-2*flipBoard_button.x) and
					adjustedY >= newGame_button.y and adjustedY <= newGame_button.y + newGame_button.height then
				newGame_button.onClick()
			end

			if x >= flipBoard_button.x and x <= flipBoard_button.x + (xOffset-2*flipBoard_button.x) and
					adjustedY >= flipBoard_button.y and adjustedY <= flipBoard_button.y + flipBoard_button.height then
				flipBoard_button.onClick()
			end

			FEN_input.active = x >= FEN_input.x and x <= FEN_input.x + (xOffset-2*flipBoard_button.x) and
					adjustedY >= FEN_input.y and adjustedY <= FEN_input.y + FEN_input.height

			if FEN_input.active and FEN_input.text=="Input FEN here" then
				FEN_input.text =  ""
			elseif not FEN_input.active and FEN_input.text=="" then
				FEN_input.text = "Input FEN here"
			end

			if x >= loadFEN_button.x and x <= loadFEN_button.x + (xOffset-2*flipBoard_button.x) and
					adjustedY >= loadFEN_button.y and adjustedY <= loadFEN_button.y + loadFEN_button.height then
				loadFEN_button.onClick()
			end

			if x >= generateFEN_button.x and x <= generateFEN_button.x + (xOffset-2*flipBoard_button.x) and
					adjustedY >= generateFEN_button.y and adjustedY <= generateFEN_button.y + generateFEN_button.height then
				generateFEN_button.onClick()
			end
			--Next button clicking
			if x >= screen_width - xOffset/2 and x <= screen_width and
					y >= next_button.y and y <= next_button.y + next_button.height then
				next_button.onClick()
				return
			end
			--Prev button clicking
			if x >= screen_width - xOffset and x <= screen_width - xOffset/2 and
					y >= prev_button.y and y <= prev_button.y + prev_button.height then
				prev_button.onClick()
				return
			end
		else
			--Next button clicking
			if x >= screen_width - xOffset and x <= screen_width and
					y >= next_button.y and y <= next_button.y + next_button.height then
				next_button.onClick()
				return
			end
			--Prev button clicking
			if x >= screen_width - 2*xOffset and x <= screen_width - xOffset and
					y >= prev_button.y and y <= prev_button.y + prev_button.height then
				prev_button.onClick()
				return
			end

		end



		love.graphics.rectangle("fill", left_side_present and screen_width - xOffset or screen_width - 2*xOffset,  screen_height - cellsize , screen_height, 50, 50, 10)



		if xOffset<=140 then
			xOffset = 0
		end


		if gameState.historyClickRegions then
			for _, region in ipairs(gameState.historyClickRegions) do
				if x >= region.x and x <= region.x + region.width and
						y >= region.y and y <= region.y + region.height then
					if gameState.starting=="w" then
						gameState.board = cloneBoard(region.board)
					else
						gameState.board = flipBoard(cloneBoard(region.board))
					end
					gameState.turn = region.turn
					gameState.history_move_index =  region.moveIndex
					gameState.selectedPiece = nil
					gameState.selectedPieceColor = nil
					gameState.selectedPos = {x = nil, y = nil}
					return
				end
			end
		end

		gridX = math.floor((x-xOffset) / cellsize) +1
		gridY = math.floor(y / cellsize) + 1



		clicked_pos_x = x-x%cellsize+(math.abs(32*3.6-cellsize))/2
		clicked_pos_y = y-y%cellsize


		if gridX >= 1 and gridX <= #map[1] and gridY >= 1 and gridY <= #map then
			if not gameState.selectedPiece then
				-- First click: Select the piece
				local piece_temp = find_piece_from_cell(gridX,gridY,gameState.board,gameState.turn)
				if (piece_temp~=-1 and piece_temp~=nil) then
					gameState.selectedPiece = piece_temp.type
					gameState.selectedPieceColor = piece_temp.color
				end
				if gameState.selectedPiece then
					gameState.selectedPos.x = gridX
					gameState.selectedPos.y = gridY
				else
					--No piece at " .. gridX .. ", " .. gridY
				end
			else
				-- Second click: Move the piece
				if gridX ~= gameState.selectedPos.x or gridY ~= gameState.selectedPos.y then
					move_piece(Piece_to_String(gameState.selectedPiece,gameState.selectedPieceColor), gameState.selectedPos, {x = gridX, y = gridY}, gameState.turn)
					gameState.selectedPiece = nil
					gameState.selectedPos = {x = nil, y = nil}
				else
					--Clicked the same cell, deselecting
					gameState.selectedPiece = nil
					gameState.selectedPos = {x = nil, y = nil}
				end
			end
		else
			--
		end
	end
end

function love.update(dt)
	if backspaceHeld then
		backspaceTimer = backspaceTimer + dt
		if backspaceTimer >= 0 then
			FEN_input.text = FEN_input.text:sub(1, -2)
			backspaceTimer = backspaceTimer - backspaceRepeat
		end
	end
end

function love.keyreleased(key)
	if key == "backspace" then
		backspaceHeld = false
	end
end

function love.keypressed(key)
	if FEN_input.active then
		if key == "backspace" or key == "delete" then
			if FEN_input.selectAll then
				FEN_input.text = ""
				FEN_input.selectAll = false
			else
				FEN_input.text = FEN_input.text:sub(1, -2)
				backspaceHeld = true
				backspaceTimer = -backspaceDelay
			end
		elseif (key == "v" or key == "V") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
			local clip = love.system.getClipboardText()
			if clip then
				FEN_input.text = FEN_input.text .. clip
			end
		elseif (key == "c" or key == "C") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
			love.system.setClipboardText(FEN_input.text)
		elseif (key == "a" or key == "A") and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
			FEN_input.selectAll = true
		else
			FEN_input.selectAll = false
		end
	end
end


function love.textinput(t)
	if FEN_input.active then
		FEN_input.text = FEN_input.text .. t
	end
end



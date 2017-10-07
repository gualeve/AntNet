
function [dir] = fw_calc_next(ain_port, asrc, adst, atileID, vetP, data_vctmp)

	load vars;
	
	if atileID == adst
		dir = C;
	else
		[row_local, col_local]=xy(atileID, COLS);
		[row_dest, col_dest]=xy(adst, COLS);
		
		a=0;
		if col_dest < col_local				%< dest column left
			if row_dest < row_local			%< dest row above (NW)
				a=N;
				b=W;
			else
				if row_dest > row_local		%< dest row below (SW)
					a=S;
					b=W;
				else                                %< dest same row (W)
					dir = W;
				end
			end
		else
			if (col_dest > col_local)				%< dest column right
				if (row_dest < row_local)           %< dest row above (NE)
					a=N;
					b=E;
				else
					if (row_dest > row_local)			%/< dest row below (SE)
						a=S;
						b=E;
					else							%< dest in the same row (E)
						dir = E;
					end
				end
			else                                    %< dest in the same column
				if (row_dest < row_local)				%< dest row above (N)
					dir = N;
				else						%< dest row above (S)
					dir = S;
						
				end
			end
		end
		if a != 0
			%< calculate probability to Pa and Pb
			if (data_vctmp(a) / MAX_DATA_BUFF > ALPHA),
				wafull = 1;
			else
				wafull = 0;
			end
			if (data_vctmp(b) / MAX_DATA_BUFF > ALPHA),
				wbfull = 1;
			else
				wbfull = 0;
			end
			if wafull > wbfull,
				La=4;
				Lb=0;
			else
				if wafull < wbfull,
					La=0;
					Lb=4;
				else
					La=Lb=2;
				end
			end
			nPa = ( 3 * vetP(a) + La ) / 4;
			nPb = ( 3 * vetP(b) + Lb ) / 4;
			if nPa > nPb
				dir = a;
			else
				if nPa < nPb
					dir = b;
				else
					a(2)=b;
					dir = a(fix(rand*2)+1);
				end
			end
		end
	end

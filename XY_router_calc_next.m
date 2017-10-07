function [dir]=XY_router_calc_next(ip_dir, source, dest_id, tileID)

	load vars;

	[xco, yco]=xy(tileID,COLS);
	[dest_xco, dest_yco]=xy(dest_id,COLS);
	%disp "ip_dir=";
	%disp ip_dir;
    
    if dest_yco > yco
        dir = E;
    else
		if (dest_yco < yco)
			dir = W;
		else 
			if dest_yco == yco
				if dest_xco < xco
					dir = N;
				else
					if dest_xco > xco
						dir = S;
					else
						if dest_xco == xco
							dir = C;
						else
							dir = ND;
						end
					end
				end
			end
		end
	end

function [dir, troute] = bw_calc_next(troute)

	load vars;
	
	tmp = mod(troute,8);
	troute = fix(troute/8);
	switch tmp
		case N
			dir = S;
		case S
			dir = N;
		case E
			dir = W;
		case W
			dir = E;
		case C
			dir = 5;
		case 0
			dir = 0;
	end
	
	
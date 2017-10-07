function [x,y]=xy(tileID,COLS)
	x = fix((tileID-1) / (COLS))+1;
	y = mod(tileID-1, COLS)+1;
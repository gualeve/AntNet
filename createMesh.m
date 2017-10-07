
function [data_vc, ant_vc, tableP, poptable, popindex, CS, packets]=createMesh(ROWS, COLS)
	
	pid=1; pstatus=2; pstart=3; psrc=4; pdst=5; pflit_count=6;
	load vars
	tileID=0;
	numTiles=ROWS*COLS;
	for i=1:ROWS	
		for j=1:COLS
			tileID=tileID+1;
			%< structs to packets
			%<PKG_SIZE=
			
			packets(tileID, pstatus) = 0;
			packets(tileID, pstart) = ceil(rand()*PKG_SIZE);
			packets(tileID, psrc) = tileID;
			packets(tileID, pflit_count) = PKG_SIZE;
			packets(tileID, pid) = 0;
			
			
			for v=N:C		% for each tile VC						
				data_vc(tileID,v,free)=MAX_DATA_BUFF;	%< virtual channel of link-router
				data_vc(tileID,v,locked)=0; 				%< lock/unlock Data-VC to use
				data_vc(tileID,v,congestion)=0;			%< 0/1
				data_vc(tileID,v,prev_free)=0;			%< 0..MAX_DATA_BUFF
			
				ant_vc(tileID,v,free)=MAX_ANT_BUFF;		
				ant_vc(tileID,v,locked)=0; 				%< lock/unlock Ant-VC to use
			%	%wfull(tileID,v)=0;			%< warn full - buffer full, change (0/1)
			end
			
			for k=1:HS
				poptable(tileID,k)=tileID;
			end
			popindex(tileID)=1;
			%CVCp(tileID,:)=[0 0 0 0];
			%CSn(tileID,:)=[0 0 0 0];
			CS(tileID)=0;				%< Congestion Status register
		
			
			[row_local, col_local]=xy(tileID,COLS);
			for d=1:numTiles       % < 0,1,2,3,4 ==> 0.00, 0.25, 0.50, 0.75, 1.00
				% disp "tile=", tileID << " j=" <<j<< endl;
				[row_dest, col_dest]=xy(d, COLS);
				if col_dest < col_local				%< dest column left
					if row_dest < row_local			%< dest row above (NW)
						tableP(tileID,d,N)=2;
						tableP(tileID,d,S)=0;
						tableP(tileID,d,E)=0;
						tableP(tileID,d,W)=2;
					else
						if row_dest > row_local		%< dest row below (SW)
							tableP(tileID,d,N)=0;
							tableP(tileID,d,S)=2;
							tableP(tileID,d,E)=0;
							tableP(tileID,d,W)=2;
						else                                %< dest same row (W)
							tableP(tileID,d,N)=0;
							tableP(tileID,d,S)=0;
							tableP(tileID,d,E)=0;
							tableP(tileID,d,W)=4;
						end
					end
				else
					if (col_dest > col_local)				%< dest column right
						if (row_dest < row_local)           %< dest row above (NE)
							tableP(tileID,d,N)=2;
							tableP(tileID,d,S)=0;
							tableP(tileID,d,E)=2;
							tableP(tileID,d,W)=0;
						else
							if (row_dest > row_local)			%/< dest row below (SE)
								tableP(tileID,d,N)=0;
								tableP(tileID,d,S)=2;
								tableP(tileID,d,E)=2;
								tableP(tileID,d,W)=0;
							else							%< dest in the same row (E)
								tableP(tileID,d,N)=0;
								tableP(tileID,d,S)=0;
								tableP(tileID,d,E)=4;
								tableP(tileID,d,W)=0;
							end
						end
					else                                    %< dest in the same column
						if (row_dest < row_local)				%< dest row above (N)
							tableP(tileID,d,N)=4;
							tableP(tileID,d,S)=0;
							tableP(tileID,d,E)=0;
							tableP(tileID,d,W)=0;
						else
							if row_dest > row_local			%< dest row above (S)
								tableP(tileID,d,N)=0;
								tableP(tileID,d,S)=4;
								tableP(tileID,d,E)=0;
								tableP(tileID,d,W)=0;
							else							%< dest == local
								tableP(tileID,d,N)=0;
								tableP(tileID,d,S)=0;
								tableP(tileID,d,E)=0;
								tableP(tileID,d,W)=0;
							end
								
						end
					end
				end
			end % endfor numTiles
		end % for COLS
	end % for ROWS

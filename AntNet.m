% Sistemas Bioinspirados Aplicados a Engenharia
%
% AntNet - Simulador de NoC 2D baseado no algoritmo de roteamento das formigas
% José Adalberto Façanha Gualeve
% -- UnB(c) - Graco/Laico 2016
%
% Artigo base: Masoud Daneshtalab, Ali Afzali Kusha, Ashkan Sobhani, Zainanabedin Navabi, 
% Mohammad D. Mottaghi, Omid Fatemi, Ant Colony Based Routing Architecture for Minimizing Hot Spots in NOCs,
% SBCCI, 2006

function AntNet(  )
	logging=20;		%< set log level
	save ("log","logging");

	%more;
	%clc;
	clear all;
	format short
	
	%< Ajustable variables

	ALGO="ANTNET";	%< XY or ANTNET
	%ALGO="XY";

	COLS=8;
	ROWS=8;
	HS=5;					%< Popularity history size
	MAX_DATA_BUFF=8;		%< Maximum VCs by DATA link
	MAX_ANT_BUFF=5;			%< Maximum VCs by ANT link
	QUANTUM=10;				%< Interval between ANTs generations
	burst=0.2; 				%< Initial DATA burst (% of total iteration)
	maxIteration=1000;
	ALPHA=0.5;
	DISP=100;
	PKG_SIZE=8;
	pkg=0;
	
	%< constants 
	id=1; tile=2;  src=3; dst=4; in_port=5; out_port=6; status=7; charge=8; hops=9; unrouted=10;
	route=11; pkt=11; start=12; stop=13; flit_count=14; pnumber=0;
	port=2; free=3; locked=4; congestion=5; prev_free=6;
	FORWARD=1; BACKWARD=2;
	numTiles=ROWS*COLS;
	N=1; S=2; E=3; W=4; C=5; ND=6; % North, South, East, West, Core(Local), Not Defined
	save("vars","COLS","ROWS","N","S","E","W","C", "ND", "HS","MAX_DATA_BUFF", "MAX_ANT_BUFF", "PKG_SIZE");
	save("-append","vars","pkt","start","stop", "id", "flit_count");
	save("-append", "vars", "ALPHA", "port", "free", "locked", "congestion", "prev_free", "hops", "unrouted");
	save("-append","vars","dst","src","tile","out_port","in_port","status", "route", "charge", "FORWARD", "BACKWARD");
	
	tileID=0;
	dflitcount=0;
	dflitconsumed=0;
	dflitqueued=0;
	aflitcount=0;
	aflitconsumed=0;
	bflitconsumed=0;
	aflitqueued=0;
	dflits=[];
	aflits=[];
	%packets=[];
	
%---------------%< create MESH -------------------------------------------------
	[data_vc, ant_vc, tableP, poptable, popindex, CS, packets]=createMesh(ROWS, COLS);
	fprintf('\n\n\n\n\n');
	genlog(3, 'flits created: ', ROWS*COLS);

	disp 'Starting';
	for t=1:maxIteration
		genlog(10, 'Iteration: ***********************', t, '**********************************');

		genlog(2,'----------Data flit --------|| ---------Ant FORWARD--------- || ----------Ant BACKWARD-------------');
%---------------%< create traffic -- random dests ------------------------------
		if t <= maxIteration*burst,
			[dflits,data_vc,dflitcount, pnumber, packets, pkg]=create_flits(dflitcount,numTiles,t,data_vc,dflits, pnumber, packets, pkg);
		end;
		
%---------------%< create ANTs Forwards ----------------------------------------
		if strcmp(ALGO, 'ANTNET') && mod( t, QUANTUM ) == 0
			[aflits,ant_vc,aflitcount]=create_ants(aflitcount,numTiles,t,ant_vc,aflits, poptable);
		end
		
%---------------%< calculating next hop to flits -------------------------------
		data_vc(:,:,locked)=0; 		%< free output links to new transmissions
		ant_vc(:,:,locked)=0; 		%< free output links to new transmissions
		switch ALGO
			case "XY"
				parfor i=1:dflitcount
					if dflits(i,status) == 1 && dflits(i,unrouted),
						dflits(i,out_port)=XY_router_calc_next(dflits(i,in_port), dflits(i,src), dflits(i,dst), dflits(i,tile));
						dflits(i,unrouted)=false;
					end
				end
			case "ANTNET"
%---------------%< routing DATA ------------------------------------------------
				%< read congestion status before update VCs
				for cx=1:numTiles
					for z=N:W
						data_vc(cx,z,prev_free) = data_vc(cx,z,free);
					end
				end
				parfor i=1:dflitcount
					%< if flit still lives?
					if dflits(i,status) == 1 && dflits(i,unrouted),
						ftileID = dflits(i,tile);
						fdst   = dflits(i, dst);
						fsrc    = dflits(i,src);
						vetP   = tableP(ftileID, fdst, :);	%< gets just one dest from route table
						fin_port  = dflits(i, in_port);
						
						if  ftileID == fdst			%< data flit arrived at destination
							dflits(i,out_port) = C;
						else
							dflits(i,out_port)=ANT_router_calc_next(i,fin_port, fsrc, fdst, ftileID, vetP);
							%/// update popularity table
						end
						dflits(i,unrouted)=false;
					end
					
					genlog(10, 'calculated data out_port: flit(',i,')=', dflits(i,out_port));
						
				end
%---------------%< routing ANTs ------------------------------------------------
				parfor i = 1:aflitcount
					if aflits(i,unrouted),
						genlog(1, 'ID do flit:', i);
						atileID = aflits(i,tile);
						genlog(1, 'TileID do flit.....................................................:', atileID);
						asrc    = aflits(i,src);
						genlog(1,  'src do flit:', asrc);
						adst   = aflits(i, dst);
						genlog(1, 'dest do flit:', adst);
						genlog(1, 'status do flit:', aflits(i,status));
						vetP   = tableP(atileID, adst, :);
						ain_port  = aflits(i, in_port);
						data_vctmp = data_vc(atileID,:,:);	
						switch (aflits(i,status))
							%	case 0  %< killed ANT
							case FORWARD								
								aflits(i,out_port) = fw_calc_next(ain_port, asrc, adst, atileID, vetP, data_vctmp );
								aflits(i,charge) = aflits(i,charge)*8 + CS(atileID);
								genlog(2, 'Charge:', aflits(i,charge));
								genlog(10, 'calculated ant FW out_port: flit(',i,')=', aflits(i,out_port));
								%aflits(i,:)
							case BACKWARD		%< BACKWARD
								[aflits(i,out_port), aflits(i,route)] = bw_calc_next( aflits( i,route));
								genlog(10, 'calculated ant BW out_port: flit(',i,')=', aflits(i,out_port));
						end	
						aflits(i,unrouted)=false;
					end
				end
			
		end
%---------------%< moving DATA flits -------------------------------------------		
		parfor i=1:dflitcount
			if dflits(i,status) == 1 && dflits(i, unrouted)==false, %< if flit still lives?
				dcurrent_in_port=dflits(i,in_port);
				
				switch dflits(i,out_port)
					case N
						dnext_in_port=S;
						data_tile_next=dflits(i,tile)-COLS; %< tileID next above
					case S
						dnext_in_port=N;
						data_tile_next=dflits(i,tile)+COLS; % tileID next below
					case E
						dnext_in_port=W;
						data_tile_next=dflits(i,tile)+1; % tileID next right 
					case W
						dnext_in_port=E;
						data_tile_next=dflits(i,tile)-1; % tileID next left
					case C
						dnext_in_port=0;
						data_tile_next=dflits(i,tile);
				end
				
				if data_tile_next > numTiles,	%< crashed
					genlog(20,'*-------*');
					genlog(20, 'Data flit ID:', i);
					genlog(20, 'Flit TileID:', dflits(i,tfile));
					genlog(20, 'Flit Src:', dflits(i,src));
					genlog(20, 'Flit Dst:', dflits(i,dst));
					genlog(20, 'TileID dest:', data_tile_next);
					genlog(20, 'Output port:', dflits(i,out_port));
					genlog(20, 'Input Port:', dnext_in_port);
					genlog(20, 'Hops:', dflits(i,hops));
					
					%disp('dflits::')
					%dflits(i,:)					
					%genlog(20, '*-------*');
				
				end
				
				genlog(2,'*-------*');
				genlog(2, 'Data flit ID:', i);
				genlog(2, 'Flit TileID:', dflits(i,tile));
				genlog(2, 'TileID dest:', data_tile_next);
				genlog(2, 'Output port:', dflits(i,out_port));
				genlog(2, 'Input Port:', dnext_in_port);
				
				genlog(2, '*-------*');
				
				if dnext_in_port == 0, % consume
					dflitconsumed++;
					dflits(i, stop) = t;
					dflits(i,status)= 0;
				else			% routing (if possible)
					if mod(t,DISP) == 0,
						data_vc;
					end
					genlog(10, 'Src', dflits(i,src), 'dst', dflits(i,dst));
					genlog(10, "Current tile:", dflits(i,tile), "Next tile", data_tile_next, "Next in port", dnext_in_port);
					if data_vc(data_tile_next,dnext_in_port,free) > 0 && data_vc(data_tile_next,dnext_in_port,locked) == 0 , %< change flit to here
						data_vc(data_tile_next,dnext_in_port,locked)=1;
						genlog(10, "moving dflit", i);
						genlog(10,'   tile,     src,      dst,      inp,      outp,     stat,     chrg,     hops');
						genlog(10,'dflits(i,:)', dflits(i,:));
						
						%< update popularity table
						poptable(dflits(i,tile),popindex(dflits(i,tile))) = dflits(i, dst);
						popindex(dflits(i,tile)) = mod( popindex(dflits(i,tile)), HS) + 1;
						
						genlog(2, '(i)=',i);
						genlog(2, '(dcurrent_in_port)=',dcurrent_in_port);
						genlog(2, '(dflits(i,tile))=',dflits(i,tile));
						genlog(2, '(data_vc(dflits(i,tile),dcurrent_in_port,free)=',data_vc(dflits(i,tile),dcurrent_in_port,free));
						
						data_vc(dflits(i,tile),dcurrent_in_port,free)++;
						
						genlog(2, '(data_vc(dflits(i,tile),dcurrent_in_port,free)++=',data_vc(dflits(i,tile),dcurrent_in_port,free));
						
						dflits(i,tile) = data_tile_next;
						dflits(i,in_port) = dnext_in_port;
						dflits(i,hops)++;
						
						
						genlog(2, 'data_vc_dest=',data_tile_next);
						genlog(2, '(inport_next)=',dnext_in_port);
						genlog(2, 'data_vc(data_vc_dest,inport_next,free)=',data_vc(data_tile_next,dnext_in_port,free));
						
						data_vc(data_tile_next,dnext_in_port,free)--;
						
						genlog(2, 'data_vc(data_vc_dest,inport_next,free)--=',data_vc(data_tile_next,dnext_in_port,free));
						dflits(i,unrouted)=true;
					else
						genlog(2, 'target buffer full, flit in waiting: ', i);
						dflitqueued++;
						%dflits(i,unrouted)=false; %< redundant
					end
				end  % end routing
				
			end
		end		% end update dflits positions
		
		if strcmp(ALGO,"ANTNET") != 0
			%< update congestion status of VCs
			parfor cx=1:numTiles
				for z=1:4								%< for each link
					if data_vc(cx,z,free) > data_vc(cx,z,prev_free) 	
						data_vc(cx,z,congestion) = 1;	%< increased
					else
						data_vc(cx,z,congestion) = 0;	%< decreased
					end
				end
				CS(cx)=sum(data_vc(cx,:,congestion));	%< Tile's Congestion register
			end
			
%---------------%< moving ANT flits --------------------------------------------	
			parfor i=1:aflitcount
				if aflits(i,status) != 0 && aflits(i,unrouted) == false, %< if flit still lives?
					%genlog(2, 'out_port:',aflits(i,out_port));
					acurrent_in_port=aflits(i,in_port);
					switch aflits(i,out_port)
						case N
							anext_in_port=S;
							ant_tile_next=aflits(i,tile)-COLS; %< tileID next above
						case S
							anext_in_port=N;
							ant_tile_next=aflits(i,tile)+COLS; % tileID next below
						case E
							anext_in_port=W;
							ant_tile_next=aflits(i,tile)+1; % tileID next right 
						case W
							anext_in_port=E;
							ant_tile_next=aflits(i,tile)-1; % tileID next left
						case C
							anext_in_port=0;
							%ant_tile_next=i; % 
							
							
					end
					if ant_tile_next > numTiles,	%< crashed
						genlog(20,'*-------*');
						genlog(20,'ant_tile_next', ant_tile_next, 'numTiles', numTiles);
						genlog(20, 'Ant flit ID:', i);
						genlog(20, 'Flit TileID:', aflits(i,tile));
						genlog(20, 'Flit Src:', aflits(i,src));
						genlog(20, 'Flit Dst:', aflits(i,dst));
						genlog(20, 'Output port:', aflits(i,out_port));
						genlog(20, 'Input Port:', anext_in_port);
						genlog(20, 'TileID dest:', ant_tile_next);
						%disp('aflits::')
						%aflits(i,:);
						%disp('ant_vc::')
						%ant_vc
						genlog(20, '*-------*');
					
					end
				
					genlog(2,'                           *-------*');
					genlog(2, '                           Ant flit ID:', i);
					genlog(2, '                           Flit TileID:', aflits(i,tile));
					genlog(2, '                           TileID dest:', ant_tile_next);
					genlog(2, '                           Output port:', aflits(i,out_port));
					genlog(2, '                           Input Port:', anext_in_port);
					genlog(2,'                           *-------*');
					
					switch (aflits(i,status))
					%	case 0  %< killed ANT
						case FORWARD 	%< FORWARD active
							if anext_in_port == 0, % change to BACKWARD
								aflitconsumed++;
								aflits(i,status) = BACKWARD;
								tmp = aflits(i,dst);
								aflits(i,dst)   = aflits(i,src);
								aflits(i,src)   = tmp;
								genlog(3,'backing ANT');
							else			% routing (if possible)
								if ant_vc(ant_tile_next,anext_in_port,free) > 0 && ant_vc(ant_tile_next,anext_in_port,locked) == 0, % change flit to here
									ant_vc(ant_tile_next,anext_in_port,locked) = 1;
									aflits(i,route) = aflits(i,route)*8 + aflits(i,out_port); % shifting and adding new direction to route-backward
					genlog(2, '                                                            acurrent_in_port', acurrent_in_port);
					genlog(2, '                                                            aflits(i,tile)', aflits(i,tile));
					genlog(2, '                                                            ant_vc(aflits(i,tile),acurrent_in_port,free)= ',ant_vc(aflits(i,tile),acurrent_in_port,free));
									ant_vc(aflits(i,tile),acurrent_in_port,free)++;
									
					genlog(2, '                                                            ant_vc(aflits(i,tile),acurrent_in_port,free)++ = ',ant_vc(aflits(i,tile),acurrent_in_port,free));
									aflits(i,tile) = ant_tile_next;
									aflits(i,in_port) = anext_in_port;
									aflits(i,hops)++;
					genlog(2, '                                                            ant_tile_next=',ant_tile_next);
					genlog(2, '                                                            (anext_in_port)=',anext_in_port);
					genlog(2, '                                                            ant_vc(ant_tile_next,anext_in_port, free)=',ant_vc(ant_tile_next,anext_in_port,free));
									ant_vc(ant_tile_next,anext_in_port,free)--;
									
					genlog(2, '                                                            ant_vc(ant_tile_next,anext_in_port,free)--=',ant_vc(ant_tile_next,anext_in_port,free));	
									aflits(i,unrouted)=true;
								else
									genlog(2,'full buffer, queueing ANT FORWARD flit');
									aflitqueued++;
									%aflits(i,unrouted)=false; %<redundant
								end
							end
						case BACKWARD	%< BACKWARD active

							if anext_in_port == 0, % ended BACKWARD
								bflitconsumed++;
								aflits(i,status) = 0;
								genlog(2, 'killing ANT');
							else			% routing (if possible)
								if ant_vc(ant_tile_next,anext_in_port,free) > 0 && ant_vc(ant_tile_next,anext_in_port,locked) == 0, % change flit to here
									ant_vc(ant_tile_next,anext_in_port,locked) = 1;
									ant_vc(aflits(i,tile),acurrent_in_port,free)++;
									
									aflits(i,tile) = ant_tile_next;
									aflits(i,in_port) = anext_in_port;
									aflits(i,hops)++;
									ant_vc(ant_tile_next,anext_in_port,free)--;
									
		%---------------%< updating routing table by backward ANT ----------------------		
									vetP   = tableP(aflits(i,tile), aflits(i,src), :);
									
									genlog(3,'updating routing table',aflits(i,tile));
									tableP(aflits(i, tile),aflits(i,src),:);
									
									genlog(3,'updating routing table',tableP(aflits(i, tile),aflits(i,src),:));
									[vetP, aflits(i, charge)] = update_tableP(aflits(i,charge),vetP, acurrent_in_port);
									tableP(aflits(i,tile), aflits(i,src), :) = vetP;
									genlog(3,'updating routing table',tableP(aflits(i, tile),aflits(i,src),:));
									aflits(i,unrouted)=true;
								else
									genlog(2,'full buffer, queueing ANT BACKWARD flit');
									aflitqueued++;
									%aflits(i,unrouted)=false; 
								end
							end
					end		
				end
			end		% end update dflits positions
		end
		genlog(5,'Data flits', dflitcount ,'Ant flits', aflitcount)
		
		
	end % < maxIteration
	packs(1:pkg)=zeros;
	for i=1:dflitcount
		if dflits(i,status)==0,
			fprintf("Flit(%5d)/Pack(%5d) (%2d ->> %2d) - Start time: %3d  -- Stop time: %3d || %2d Cycles to %2d hops\n" ,dflits(i,id), dflits(i,pkt), dflits(i,src), dflits(i,dst), dflits(i,start), dflits(i,stop), dflits(i,stop)-dflits(i,start), dflits(i,hops));
			packs(dflits(i,pkt))++;
		else
			fprintf("Flit(%5d)/Pack(%5d) (%2d ->> %2d) - Start time: %3d  -- Stop time: %3d || %2d Cycles to %2d hops (Didnt Reach)\n" ,dflits(i,id), dflits(i,pkt), dflits(i,src), dflits(i,dst), dflits(i,start), dflits(i,stop), dflits(i,stop)-dflits(i,start), dflits(i,hops));
		end
	end
	%packs
	packconsumed=0;
	for i=1:pkg
		if packs(i) == PKG_SIZE
			packconsumed++;
		end
	end

	
	
	logging=1;
	save ("log","logging");
	disp ('');
	genlog(100, 'Number of tiles:.............', numTiles);
	genlog(100, 'Cycles:......................', t);
	genlog(100, 'Generated Packets:...........', pkg);
	genlog(100, 'Consumed Packets:............', packconsumed);
	genlog(100, 'Generated DATA flits:........', dflitcount);
	genlog(100, 'Queued DATA flits:...........', dflitqueued);
	genlog(100, 'Consumed DATA flits:.........', dflitconsumed);
	genlog(100, 'Generated ANT flits:.........', aflitcount);
	genlog(100, 'Queued ANT flits:............', aflitqueued);
	genlog(100, 'Consumed ANT Forward flits:..', aflitconsumed);
	genlog(100, 'Consumed ANT Backward flits:.', aflitconsumed);
	
	out = fopen('antnet-8x8-a.log' ,'a');
		fprintf(out, 'Routing Algorithm:...........%s\n', ALGO);
		fprintf(out, 'Number of tiles:.............%d\n', numTiles);
		fprintf(out, 'Cycles:......................%d\n', t);
		fprintf(out, 'Generated Packets:...........%d\n', pkg);
		fprintf(out, 'Consumed Packets:............%d\n', packconsumed);
		fprintf(out, 'Generated DATA flits:........%d\n', dflitcount);
		fprintf(out, 'Queued DATA flits:...........%d\n', dflitqueued);
		fprintf(out, 'Consumed DATA flits:.........%d\n', dflitconsumed);
		fprintf(out, 'Generated ANT flits:.........%d\n', aflitcount);
		fprintf(out, 'Queued ANT flits:............%d\n', aflitqueued);
		fprintf(out, 'Consumed ANT Forward flits:..%d\n', aflitconsumed);
		fprintf(out, 'Consumed ANT Backward flits:.%d\n\n', aflitconsumed);
		
		for i=1:dflitcount
			if dflits(i,status)==0,
				fprintf(out, "Flit(%5d)/Pack(%5d) (%2d ->> %2d) - Start time: %3d  -- Stop time: %3d || %2d Cycles to %2d hops\n" ,dflits(i,id), dflits(i,pkt), dflits(i,src), dflits(i,dst), dflits(i,start), dflits(i,stop), dflits(i,stop)-dflits(i,start), dflits(i,hops));
			else
				fprintf(out, "Flit(%5d)/Pack(%5d) (%2d ->> %2d) - Start time: %3d  -- Stop time: %3d || %2d Cycles to %2d hops (Didnt Reach)\n" ,dflits(i,id), dflits(i,pkt), dflits(i,src), dflits(i,dst), dflits(i,start), dflits(i,stop), dflits(i,stop)-dflits(i,start), dflits(i,hops));
			
			end
		end
		fprintf(out, '==================================================================\n');
	fclose(out);
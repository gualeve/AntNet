
function [dflits,data_vc,fid, pnumber, packets, pkg]=create_flits(fid,numTiles,t,data_vc,dflits, pnumber, packets, pkg)
	
	%dest=1; src=2; tile=3; out_port=4; in_port=5; status=6;
	pid=1; pstatus=2; pstart=3; psrc=4; pdst=5; pflit_count=6;
	load vars;
	for i=1:numTiles
		if packets(i,pstatus) == 0,
			if mod(t, packets(i, pstart)) == 0, %< create new pack
				packets(i,pstatus)=1;
			end
		end
		if data_vc(i,C,free) > 0 && packets(i,pstatus) != 0
			if packets(i, pflit_count) == PKG_SIZE
				%disp('new pack--------------');
				%< create new packet
				while true
					tdst=fix(numTiles * rand())+1;
					if tdst != i,
						break;
					end
				end
				packets(i,pdst)=tdst;
				pkg++;
				packets(i, pid)=pkg;
			end
			packets(i,psrc)=i;
			packets(i, pflit_count)--;
			if packets(i, pflit_count) == 0,
				packets(i, pflit_count) = PKG_SIZE;
			end
			%disp('stats strt src dst count');	
			%packets
			
			fid++;
			data_vc(i,C,free)--;
			dflits(fid,id)=fid;
			dflits(fid,tile)=i;
			dflits(fid,src)=i;
			dflits(fid,dst)= packets(i,pdst);
			dflits(fid,in_port)=C;
			dflits(fid,out_port)=6;
			dflits(fid,status)=1;
			dflits(fid,charge)=rand();
			dflits(fid,hops)=0;
			dflits(fid,start)=t;
			dflits(fid,stop)=t;
			dflits(fid,pkt)=packets(i, pid);
			dflits(fid,unrouted)=true;
			
			genlog(1,'FlitID:', fid);
			genlog(1,'Tile:', i);
			genlog(1,'Src:/Dest', i, ' --> ', packets(i,pdst));
			
			
		end
	end
function [out_port]=ANT_router_calc_next(flitid, ip_dir, source, dest_id, tileID, vetP)

	load vars;
	
	if tileID == dest_id
        out_port = C;
    else
		[maxi,ind]=max(vetP);
		clear lr;
		c=1;
		for j=ind:4,
			if vetP(j) == maxi,
				lr(c)=j;
				c++;
			end
		end
		ix=fix(1+(c-1)*rand);
		genlog(5,'Flit ID',flitid,'lr=',lr,'ix=',ix);
		out_port = lr(ix);
	end

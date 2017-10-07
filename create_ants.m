
function [aflits,ant_vc,fid]=create_ants(fid,numTiles,t,ant_vc,aflits, poptable);

	%dest=1; src=2; tile=3; out_port=4; in_port=5; status=6;
	load vars;
	for i=1:numTiles
	%i=1
		if ant_vc(i,C,free) > 0,
			tdst=max(poptable(i,:));
			%tdst = numTiles;
			if tdst == i,  %< dont create ANT, dst == src
				%disp (''); 
				%disp ('killing ant');
			else
				fid++;
				ant_vc(i,C,free)--;
				aflits(fid,tile)=i;
				aflits(fid,src)=i;
				aflits(fid,dst)=tdst;
				genlog(5,'ant src=',i,'ant dst=',tdst);
				aflits(fid,in_port)=C;
				aflits(fid,out_port)=6;
				aflits(fid,status)=1;	%< 1 = FORWARD, 2 = BACKWARD
				aflits(fid,charge)=0;
				aflits(fid,hops)=0;
				aflits(fid,unrouted)=true;
				aflits(fid,route)=5;
			end
		end
	end

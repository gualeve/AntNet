
function [dflits,vc]=update_flits(numTiles,t,vc,dflits)
	
	dest=1;
	for i=1:numTiles
		if vc(i,5) > 0,
			while 1
				dst=fix(numTiles * rand())+1;
				if dst != i,
					break;
				end
			end
			dflits(t,i,dest)=dst;
			vc(i,5)=vc(i,5)-1;
		else
			dflits(t,i,dest)=-1;
		end
	end
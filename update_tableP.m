
function [vetP, charge] = update_tableP(charge, vetP, inport_next)

	tcs=mod(charge,8);
	charge=fix(charge/8);
	
	%< update link where came in
	vetP(inport_next) = vetP(inport_next)+( (4-tcs)*(4-vetP(inport_next)))/4;
	
	%< update the others links
	for i=1:3
		ind=mod(inport_next+i-1,4)+1;
		vetP(ind) = vetP(ind) - (( 4-tcs)*vetP(ind))/4;
	end

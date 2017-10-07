
function genlog ( LOG ,a1, v1, a2, v2, a3, v3)
	load log;
	if logging != 0 && LOG >= logging
		switch nargin
			case 2
				fprintf("%s\n", a1);
			case 3
				if size(v1,1)==1 && size(v1,2)==1
					fprintf ("%s %d\n", a1, v1);
				else
					disp(a1);
					disp(v1);
				end
			case 4
				if size(v1,1)==1 && size(v1,2)==1 && size(v1,3)==1
					fprintf ("%s %d %s\n", a1, v1, a2);
				else
					disp(a1);
					disp(v1);
					disp(a2);
				end
			case 5
				if size(v1,1)==1 && size(v1,2)==1 && size(v2,1)==1 && size(v2,2)==1 
					fprintf ("%s %d %s %d\n", a1, v1, a2, v2);
				else
					disp(a1);
					disp(v1);
					disp(a2);
					disp(v2);
				end
			case 7
				if size(v1,1)==1 && size(v1,2)==1 && size(v2,1)==1 && size(v2,2)==1 
					fprintf ("%s %d %s %d %s %d\n", a1, v1, a2, v2, a3, v3);
				else
					disp(a1);
					disp(v1);
					disp(a2);
					disp(v2);
				end
		end
	end
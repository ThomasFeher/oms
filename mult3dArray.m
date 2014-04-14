function result = mult3dArray(arr1,arr2)
% Multiply 3D array. First two dimensions are used for the normal matrix
% product and the operation is expanded to the third dimension.
% It works only for arrays where the first dimension of <arr1> and second
% dimension of <arr2> is 1.
% See example: http://www.gnu.org/software/octave/doc/interpreter/Broadcasting.html
% "a*b = sum (permute (a, [1, 3, 2]) .* permute (b, [3, 2, 1]), 3)"

if(size(arr1,2) ~= size(arr2,1))
	error(sprintf('nonconformant arguments (op1 is %dx%d, op2 is %dx1d)'...
	              ,size(arr1,1),size(arr1,2),size(arr2,1),size(arr2,2)));
end
%if((size(arr1,1)~=1) || (size(arr2,2)~=1))
	%error('first dimension of op1 and second dimension of op2 must be of size 1');
%end
if(ndims(arr1)>2 || ndims(arr2)>2) % TODO is this necessary?
	for cnt=3:max(ndims(arr1),ndims(arr2))
		if(size(arr1,cnt)~=size(arr2,cnt))
			error(sprintf(['nonconformant arguments (dimension %d''s size '...
			               'is %d (op1) and %d (op2)'],cnt,size(arr1,cnt)...
			                                          ,size(arr2,cnt)));
		end
	end
end

commonSize = size(arr1,2);

%result = sum(permute(arr1,[2,1,3]) .* arr2);
result = (permute(sum(permute(arr1,[1,4,2,3]) .* permute(arr2,[4,2,1,3]),3),[1,2,4,3]));
%result = ((sum(permute(arr1,[1,4,2,3]) .* permute(arr2,[4,2,1,3]),3)));

%!test # inner product
%! arr1 = rand(1,5,2);
%! arr2 = rand(5,1,2);
%! result = mult3dArray(arr1,arr2);
%! for cnt=1:2
%!   resultComp(:,:,cnt) = arr1(:,:,cnt) * arr2(:,:,cnt);
%! end
%! assert(result,resultComp);

%!test # outer product
%! arr1 = rand(5,1,2);
%! arr2 = rand(1,5,2);
%! result = mult3dArray(arr1,arr2);
%! for cnt=1:2
%!   resultComp(:,:,cnt) = arr1(:,:,cnt) * arr2(:,:,cnt);
%! end
%! assert(result,resultComp);

%!test # matrices
%! arr1 = rand(3,5,2);
%! arr2 = rand(5,4,2);
%! result = mult3dArray(arr1,arr2);
%! for cnt=1:2
%!   resultComp(:,:,cnt) = arr1(:,:,cnt) * arr2(:,:,cnt);
%! end
%! assert(result,resultComp);


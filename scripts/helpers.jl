macro d2_xi(A) esc(:(($A[ix+1+1, iy+1, iz+1] - $A[ix+1, iy+1, iz+1]) - ($A[ix+1, iy+1, iz+1] - $A[ix+1-1, iy+1, iz+1]))) end
macro d2_yi(A) esc(:(($A[ix+1, iy+1+1, iz+1] - $A[ix+1, iy+1, iz+1]) - ($A[ix+1, iy+1, iz+1] - $A[ix+1, iy+1-1, iz+1]))) end
macro d2_zi(A) esc(:(($A[ix+1, iy+1, iz+1+1] - $A[ix+1, iy+1, iz+1]) - ($A[ix+1, iy+1, iz+1] - $A[ix+1, iy+1, iz+1-1]))) end
macro inn(A)   esc(:($A[ix+1, iy+1, iz+1])) end

inn(A) = A[2:end-1, 2:end-1, 2:end-1]

function get_ranges(b_w, nx, ny, nz)
    return ((b_w[1]+1:nx-b_w[1], b_w[2]+1:ny-b_w[2], b_w[3]+1:nz-b_w[3]),
            (1:b_w[1]          , 1:ny              , 1:nz              ),
            (nx-b_w[1]+1:nx    , 1:ny              , 1:nz              ),
            (b_w[1]+1:nx-b_w[1], 1:ny              , 1:b_w[3]          ),
            (b_w[1]+1:nx-b_w[1], 1:ny              , nz-b_w[3]+1:nz    ),
            (b_w[1]+1:nx-b_w[1], 1:b_w[2]          , b_w[3]+1:nz-b_w[3]),
            (b_w[1]+1:nx-b_w[1], ny-b_w[2]+1:ny    , b_w[3]+1:nz-b_w[3]))
end
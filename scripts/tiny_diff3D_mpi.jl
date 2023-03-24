using TinyKernels
using TinyKernels.CPUBackend
using TinyKernels.CUDABackend, CUDA
using ImplicitGlobalGrid
using Plots; opts = (aspect_ratio=1, c=:turbo, clims=(0, 1), xlabel="lx", ylabel="ly")
include("helpers.jl")

@tiny function step!(T2, T, ρCp, λ, dt, dx, dy, dz)
    ix, iy, iz = @indices()
    if ix <= size(T, 1) - 2 && iy <= size(T, 2) - 2 && iz <= size(T, 3) - 2
        @inbounds @inn(T2) = @inn(T) + dt * (λ * @inn(ρCp) * (@d2_xi(T) / dx^2 + @d2_yi(T) / dy^2 + @d2_zi(T) / dz^2))
    end
    return
end

function diffusion3D(; do_visu=false, device)
    # Physics
    lx = ly = lz = 10.0           # Domain length x|y|z
    λ            = 1.0            # Thermal conductivity
    ρCp0         = 2.0            # Heat capacity
    # Numerics
    nx = ny = nz = 32             # Nb gridpoints x|y|z
    nt           = 100            # Nb time steps
    nout         = 10
    me, dims,    = init_global_grid(nx, ny, nz)
    dx, dy, dz   = lx / (nx_g() - 1), ly / (ny_g() - 1), lz / (nz_g() - 1) # gird size
    b_w          = (8, 4, 2)
    # Initial conditions
    T            = device_array(Float64, device, nx, ny, nz)
    ρCp          = device_array(Float64, device, nx, ny, nz)
    copyto!(T, [exp(-(x_g(ix, dx, T) - lx / 2)^2 - (y_g(iy, dy, T) - ly / 2)^2 - (z_g(iz, dz, T) - lz / 2)^2) for ix = 1:size(T, 1), iy = 1:size(T, 2), iz=1:size(T, 3)]) # Temperature
    fill!(ρCp, 1.0 / ρCp0)        # Diffusion coeff
    T2           = copy(T)        # Temperature (2nd)
    comp!        = step!(device)  # Materialise kernel
    ranges       = get_ranges(b_w, nx, ny, nz)
    sz           = ceil(Int, nz_g()/2)
    if do_visu
        if (me==0) ENV["GKSwstype"]="nul"; if isdir("../out_visu")==false mkdir("../out_visu") end; loadpath = "../out_visu/"; anim = Animation(loadpath,String[]); println("Animation directory: $(anim.dir)") end
        nx_v, ny_v, nz_v = (nx - 2) * dims[1], (ny - 2) * dims[2], (nz - 2) * dims[3]
        T_v   = zeros(nx_v, ny_v, nz_v)       # global array for visu
        T_inn = zeros(nx - 2, ny - 2, nz - 2) # no halo local array for visu
    end
    TinyKernels.device_synchronize(device)
    # Time loop
    dt = min(dx^2, dy^2, dz^2) / λ / maximum(ρCp) / 6.1
    for it = 1:nt
        inn_ev  =  comp!(T2, T, ρCp, λ, dt, dx, dy, dz; ndrange=ranges[1])
        out_evs = [comp!(T2, T, ρCp, λ, dt, dx, dy, dz; ndrange=ranges[i], priority=:high) for i in 2:lastindex(ranges)]
        wait(out_evs)
        update_halo!(T2)
        wait(inn_ev)
        T, T2 = T2, T
        if do_visu && (it % nout == 0)
            T_inn .= inn(Array(T)); gather!(T_inn, T_v)
            (me == 0) && (heatmap(T_v[:, :, sz]', title="it=$it", xlims=(1, nx_g() - 2), ylims=(1, ny_g() - 2); opts...); frame(anim))
        end
    end
    (do_visu && me == 0) && gif(anim, "../out_visu/tiny_diff3D.gif", fps=5)
    finalize_global_grid()
    return
end

# diffusion3D(; do_visu=true, device=CPUDevice())
diffusion3D(; do_visu=true, device=CUDADevice())
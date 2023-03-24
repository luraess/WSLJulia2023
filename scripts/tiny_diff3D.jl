using TinyKernels
using TinyKernels.CPUBackend
# using TinyKernels.CUDABackend
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
    nx = ny = nz = 64             # Nb gridpoints x|y|z
    nt           = 100            # Nb time steps
    nout         = 10
    dx, dy, dz   = lx / (nx - 1), ly / (ny - 1), lz / (nz - 1) # gird size
    b_w          = (16, 8, 2)
    # Initial conditions
    T            = device_array(Float64, device, nx, ny, nz)
    ρCp          = device_array(Float64, device, nx, ny, nz)
    copyto!(T, [exp(-((ix - 1) * dx - lx / 2)^2 - ((iy - 1) * dy - ly / 2)^2 - ((iz - 1) * dz - lz / 2)^2)
                for ix = 1:size(T, 1), iy = 1:size(T, 2), iz = 1:size(T, 3)]) # Temperature
    fill!(ρCp, 1.0 / ρCp0)        # Diffusion coeff
    T2           = copy(T)        # Temperature (2nd)
    comp!        = step!(device)  # Materialise kernel
    ranges       = get_ranges(b_w, nx, ny, nz)
    sz           = ceil(Int, nz/2)
    TinyKernels.device_synchronize(device)
    # Time loop
    dt = min(dx^2, dy^2, dz^2) / λ / maximum(ρCp) / 6.1
    GC.gc(); @time for it = 1:nt
        inn_ev  =  comp!(T2, T, ρCp, λ, dt, dx, dy, dz; ndrange=ranges[1])
        out_evs = [comp!(T2, T, ρCp, λ, dt, dx, dy, dz; ndrange=ranges[i], priority=:high) for i in 2:lastindex(ranges)]
        wait(out_evs)
        wait(inn_ev)
        T, T2 = T2, T
        (do_visu && (it % nout == 0)) && display(heatmap(T[:, :, sz]', title="it=$it", xlims=(1, nx), ylims=(1, ny); opts...))
    end
    return
end

diffusion3D(; do_visu=true, device=CPUDevice())
# diffusion3D(; do_visu=true, device=CUDADevice())
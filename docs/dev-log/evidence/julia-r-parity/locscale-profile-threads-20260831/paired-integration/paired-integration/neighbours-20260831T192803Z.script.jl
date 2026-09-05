using DRM, Test, LinearAlgebra
@assert Threads.nthreads()==1 && BLAS.get_num_threads()==1
@testset "paired frontend and legacy neighbour checks" begin
 for name in ["test_locscale_frontend.jl", "test_locscale_infer.jl", "test_sigma_axis_re.jl"]
  include(joinpath(pwd(),"test",name))
 end
end
println("PAIRED_NEIGHBOURS_OK")

using LinearAlgebra,SparseArrays,Test
Q=sparse([4. 1 1 1;1 2 0 0;1 0 2 0;1 0 0 2])
F=cholesky(Symmetric(Q)); p=copy(F.p); U=UpperTriangular(sparse(F.L)')
T=zeros(4,4); T[p,:]=U\Matrix{Float64}(I,4,4)
@test p!=collect(1:4)
@test T*T'≈inv(Matrix(Q)) rtol=1e-13 atol=1e-14
L=[.55 0.;.31 .42]
S=kron(T,L)
@test S*S'≈kron(inv(Matrix(Q)),L*L') rtol=1e-13 atol=1e-14
wrong=inv(Matrix(Q))
@test !isapprox(wrong*wrong',inv(Matrix(Q));rtol=1e-3)
@test !isapprox((U\Matrix{Float64}(I,4,4))*(U\Matrix{Float64}(I,4,4))',inv(Matrix(Q));rtol=1e-3)
println("SPARSE_IMMUTABLE_PRECISION_DRAW_CONTRACT_OK permutation=",p)

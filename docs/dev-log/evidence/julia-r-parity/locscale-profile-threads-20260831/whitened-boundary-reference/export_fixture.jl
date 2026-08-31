using Serialization, SparseArrays, LinearAlgebra, SHA, TOML
const ROOT=@__DIR__
const SOURCE=joinpath(dirname(ROOT),"post-compensation-profile/post-compensation-profile-20260831T175800Z.jls")
@assert bytes2hex(sha256(read(SOURCE)))=="fabf3e4c1a7d016ecff94a6926944553bb5238a744f03d178b7e3548e9d6c89c"
d=deserialize(SOURCE).design
files=["whitened-boundary-case1-20260831T183848Z.jls","whitened-boundary-case2-20260831T183848Z.jls",
       "whitened-boundary-case3-20260831T183728Z.jls","whitened-boundary-case4-20260831T183950Z.jls"]
cases=Dict[]
for file in files
    r=deserialize(joinpath(ROOT,file));@assert r.extra.phase==:complete && r.extra.passed
    base=only(filter(x->x.bits==256 && x.coordinate==0,r.records)).result
    push!(cases,Dict("idx"=>r.idx,"side"=>string(r.side),"theta"=>r.theta,"nll"=>Float64(base.r.M),
        "gradient"=>Float64.(r.extra.reference_gradient),"reference_z"=>Float64.(base.r.z),
        "receipt"=>file,"receipt_sha256"=>bytes2hex(sha256(read(joinpath(ROOT,file))))))
end
data=Dict("provenance"=>"Independent128/256-bit intended-L/Q Gamma reference; current175800Z dataset; generated values only",
    "source_sha256"=>bytes2hex(sha256(read(SOURCE))),"y"=>d.y,"Xmu"=>[collect(row) for row in eachrow(d.Xmu)],
    "Xpsi"=>[collect(row) for row in eachrow(d.Xpsi)],"gidx"=>collect(d.gidx),"G"=>d.G,
    "Q"=>[collect(row) for row in eachrow(Matrix(d.Q))],"cases"=>cases)
out=joinpath(ROOT,"reference-fixture.toml");@assert !isfile(out)
open(io->TOML.print(io,data;sorted=true),out,"w")
println(out," SHA ",bytes2hex(sha256(read(out))))

using LinearAlgebra, SparseArrays, Serialization, SHA
const BASE="/private/tmp/drm-parity-20260830/profile-threads-s11"
const INPUT=joinpath(BASE,"post-compensation-profile/post-compensation-profile-20260831T175800Z.jls")
const INPUT_SHA="fabf3e4c1a7d016ecff94a6926944553bb5238a744f03d178b7e3548e9d6c89c"
const ORACLE=joinpath(BASE,"whitened-oracle/fixed-outer-gamma-oracle-20260831T163817Z.script-snapshot.jl")
const ORACLE_SHA="405f28114a2d665cf40bc8c4ec46ec324422a00a141250849e35bead4dace73d"
const CANDIDATE=joinpath(BASE,"whitened-gradient/diagnose.jl")
const CANDIDATE_SHA="6f4c6fd72d4ab7183f21728f5e2aaf7460e82c1dd8ff50ba5d1e3afa366e0e28"
sha(p)=bytes2hex(sha256(read(p)))
@assert sha(INPUT)==INPUT_SHA && sha(ORACLE)==ORACLE_SHA && sha(CANDIDATE)==CANDIDATE_SHA
module Reference end
module Candidate end
function definition(ex)
    ex isa LineNumberNode && return true
    ex isa Expr || return false
    ex.head in (:using,:import,:const,:function,:macro) && return true
    ex.head===:(=) && ex.args[1] isa Expr && ex.args[1].head===:call
end
# Evaluate definitions at top level before any calling method is compiled.
for (m,p) in ((Reference,ORACLE),(Candidate,CANDIDATE))
    for ex in Meta.parseall(read(p,String)).args
        definition(ex) || break
        ex isa LineNumberNode || Core.eval(m,ex)
    end
end

function solve_reference(label,t,d,start,bits)
    setprecision(BigFloat,bits) do
        r=Reference.evaluate_case(label,t,d,bits;transformed_a=start)
        B,L=Reference.block_B(BigFloat.(t[4:6]),d.G)
        terms=Reference.oracle_terms(r.z,BigFloat.(d.y),BigFloat.(d.Xmu)*BigFloat.(t[1:2]),
                                    BigFloat.(d.Xpsi)*BigFloat.(t[3:3]),d.gidx,B)
        ga=transpose(B)\terms.g; bound=BigFloat(1e-9)*(1+norm(r.a))
        @assert norm(ga)<=bound && r.pd && r.inside
        (;r,original_residual=norm(ga),original_bound=bound)
    end
end

function main()
    out=ARGS[1]; which=parse(Int,ARGS[2]);@assert which in 1:4
    runtime=(julia=string(VERSION),julia_threads=Threads.nthreads(),blas_threads=BLAS.get_num_threads())
    @assert runtime.julia_threads==1 && runtime.blas_threads==1
    before=Candidate.hashes();input=deserialize(INPUT);d=input.design;e=input.endpoints[which]
    @assert Matrix(d.Q)==Matrix{Float64}(I,d.G,d.G) && d.kind==Val(:gamma)
    records=NamedTuple[]
    save(extra) = serialize(out,(;which,idx=e.idx,side=e.side,theta=e.theta,input_sha256=INPUT_SHA,
        oracle_sha256=ORACLE_SHA,candidate_sha256=CANDIDATE_SHA,records,before,runtime,extra))
    values=Dict{Tuple{Int,Int,Int,Int},BigFloat}()
    for bits in (128,256)
        setprecision(BigFloat,bits) do
            t=BigFloat.(e.theta)
            save((phase=:attempting,bits,coordinate=0,step=0,sign=0,completed=length(records)))
            r=solve_reference(:base,t,d,e.cold_mode,bits)
            push!(records,(bits=bits,coordinate=0,step=0,sign=0,result=r));values[(bits,0,0,0)]=r.r.M
            save((phase=:running,completed=length(records)))
            for k in 1:6, j in 1:3, sign in (-1,1)
                h=big"1e-4"/2^(j-1);tp=copy(t);tp[k]+=sign*h
                save((phase=:attempting,bits,coordinate=k,step=j,sign,completed=length(records)))
                rr=solve_reference(:perturbed,tp,d,e.cold_mode,bits)
                push!(records,(bits=bits,coordinate=k,step=j,sign=sign,result=rr))
                values[(bits,k,j,sign)]=rr.r.M
                save((phase=:running,completed=length(records)))
            end
        end
        println("BOUNDARY_REFERENCE_BITS_COMPLETE ",bits," records=",length(records));flush(stdout)
    end
    comparisons=setprecision(BigFloat,256) do
        rows=NamedTuple[]
        for k in 1:6
            numerators=[values[(bits,k,j,1)]-values[(bits,k,j,-1)] for bits in (128,256),j in 1:3]
            central=[numerators[b,j]/(2*(big"1e-4"/2^(j-1))) for b in 1:2,j in 1:3]
            rich=[(4central[b,j+1]-central[b,j])/3 for b in 1:2,j in 1:2]
            push!(rows,(;coordinate=k,numerators,central,rich,
                numerator_agreement=maximum(abs,numerators[1,:]-numerators[2,:]),
                richardson_stability=maximum(abs,rich[:,2]-rich[:,1]),
                crossprecision_derivative=abs(rich[1,2]-rich[2,2])))
        end
        rows
    end
    n=length(d.y);design=(;kind=d.kind,y=d.y,Xmu=d.Xmu,Xpsi=d.Xpsi,gidx=d.gidx,G=d.G,Q=d.Q,
        Zeta=hcat(ones(n),zeros(n)),Zpsi=hcat(zeros(n),ones(n)))
    candidate=try (ok=true,result=Candidate.white_eval(design,e.theta),error=nothing) catch err
        (ok=false,result=nothing,error=sprint(showerror,err))
    end
    candidate_certificate=candidate.ok ? setprecision(BigFloat,256) do
        t=BigFloat.(e.theta);B,L=Reference.block_B(t[4:6],d.G)
        terms=Reference.oracle_terms(BigFloat.(candidate.result.z),BigFloat.(d.y),
            BigFloat.(d.Xmu)*t[1:2],BigFloat.(d.Xpsi)*t[3:3],d.gidx,B)
        ga=transpose(B)\terms.g;bound=BigFloat(1e-9)*(1+norm(terms.a))
        ch=cholesky(Symmetric(terms.H);check=false)
        (;original_residual=norm(ga),bound,pd=issuccess(ch),inside=terms.inside,
            pass=norm(ga)<=bound && issuccess(ch) && terms.inside,
            target=:implicit_true_BigL_times_candidate_z_not_rounded_a)
    end : nothing
    reference_gradient=[c.rich[2,2] for c in comparisons]
    gradient_error=candidate.ok ? maximum(abs,BigFloat.(candidate.result.grad)-reference_gradient) : BigFloat(Inf)
    objective_error=candidate.ok ? abs(BigFloat(candidate.result.value)-values[(256,0,0,0)]) : BigFloat(Inf)
    objective_agreement=abs(values[(128,0,0,0)]-values[(256,0,0,0)])
    all_objective_agreement=maximum(abs(values[(128,k,j,s)]-values[(256,k,j,s)]) for (bits,k,j,s) in keys(values) if bits==128)
    after=Candidate.hashes()
    reference_pass=objective_agreement<=big"1e-20" && all_objective_agreement<=big"1e-20" &&
        all(c->c.numerator_agreement<=big"1e-20" && c.richardson_stability<=big"1e-10" && c.crossprecision_derivative<=big"1e-10",comparisons)
    passed=reference_pass && candidate.ok && candidate_certificate.pass && gradient_error<=big"1e-7" && objective_error<=big"1e-8" && before==after
    damaged_gradient_rejected=candidate.ok && maximum(abs,-BigFloat.(candidate.result.grad)-reference_gradient)>big"1e-7"
    save((;phase=:complete,completed=length(records),comparisons,candidate,candidate_certificate,reference_gradient,
        gradient_error,objective_error,objective_agreement,all_objective_agreement,reference_pass,passed,
        damaged_gradient_rejected,after,source_unchanged=before==after))
    println((;which,idx=e.idx,side=e.side,reference_pass,candidate_ok=candidate.ok,
        gradient_error,objective_error,objective_agreement,all_objective_agreement,passed,damaged_gradient_rejected))
    for c in comparisons;println((;c.coordinate,c.richardson_stability,c.numerator_agreement));end
    @assert passed && damaged_gradient_rejected
    println("WHITENED_BOUNDARY_REFERENCE_PASS")
end
main()

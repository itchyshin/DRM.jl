# Versioned finite-state transport. R owns formula/factor preparation; this file
# validates generated arrays and calls the same prepared kernel as direct Julia.
function _prepare_finite_joint_bridge(d)
    required=Set(["schema","predictor","variable","levels","y","x","observed_y","observed_x",
        "X_mu","X_mu_state","state_layout","X_sigma","X_predictor","mu_names","sigma_names",
        "predictor_names","original_row","options"])
    Set(keys(d))==required || throw(ArgumentError("joint finite bridge: payload fields differ from joint_missing_finite_v1"))
    d["predictor"] in ("ordinal","categorical") || throw(ArgumentError("joint finite bridge: unknown predictor family"))
    variable=d["variable"]
    variable isa AbstractString && !isempty(variable) || throw(ArgumentError("joint finite bridge: invalid variable"))
    levels=d["levels"]
    levels isa AbstractVector && length(levels)>=3 || throw(ArgumentError("joint finite bridge: at least three declared levels required"))
    levels=_joint_bridge_names(levels,length(levels),"levels");K=length(levels)
    y,x=d["y"],d["x"]
    y isa AbstractVector && x isa AbstractVector && length(y)==length(x) || throw(ArgumentError("joint finite bridge: invalid response/predictor vectors"))
    n=length(y);oy=_joint_bridge_mask(d["observed_y"],n,"observed_y");ox=_joint_bridge_mask(d["observed_x"],n,"observed_x")
    all(i -> !oy[i] || (y[i] isa Real && isfinite(y[i])),1:n) || throw(ArgumentError("joint finite bridge: observed response must be finite"))
    all(i -> !ox[i] || (x[i] isa Real && !(x[i] isa Bool) && isfinite(x[i]) && isinteger(x[i]) && 1<=x[i]<=K),1:n) ||
        throw(ArgumentError("joint finite bridge: observed predictor must be a declared state code"))
    d["state_layout"]=="row_then_state" || throw(ArgumentError("joint finite bridge: invalid state layout"))
    matrices=[d[key] for key in ("X_mu","X_sigma","X_predictor")]
    all(A -> A isa AbstractMatrix && size(A,1)==n && all(v -> v isa Real && isfinite(v),A),matrices) ||
        throw(ArgumentError("joint finite bridge: design matrices must be finite with matching rows"))
    Xmu,Xsigma,Xp=Matrix{Float64}.(matrices);p=size(Xmu,2)
    Xstate=d["X_mu_state"]
    Xstate isa AbstractMatrix && size(Xstate)==(n*K,p) && all(v -> v isa Real && isfinite(v),Xstate) ||
        throw(ArgumentError("joint finite bridge: state design must have n*K rows and p columns"))
    A=Array{Float64}(undef,n,K,p)
    for i in 1:n,k in 1:K
        A[i,k,:].=Xstate[(i-1)*K+k,:]
    end
    for i in 1:n
        if ox[i]
            all(isapprox.(Xmu[i,:],A[i,Int(x[i]),:];rtol=1e-12,atol=1e-12)) ||
                throw(ArgumentError("joint finite bridge: observed design and state order disagree"))
        end
    end
    mn=_joint_bridge_names(d["mu_names"],p,"mu_names")
    sn=_joint_bridge_names(d["sigma_names"],size(Xsigma,2),"sigma_names")
    pn=_joint_bridge_names(d["predictor_names"],size(Xp,2),"predictor_names")
    options=_joint_bridge_dict(d["options"],"options")
    all(==("g_tol"),keys(options)) || throw(ArgumentError("joint finite bridge: unsupported options"))
    g_tol=get(options,"g_tol",1e-8)
    g_tol isa Real && isfinite(g_tol) && g_tol>0 || throw(ArgumentError("joint finite bridge: invalid gradient tolerance"))
    model=prepared_joint_model([oy[i] ? Float64(y[i]) : missing for i in 1:n],
        [ox[i] ? levels[Int(x[i])] : missing for i in 1:n],A,Xsigma,Xp;
        predictor=Symbol(d["predictor"]),levels=levels,variable=Symbol(variable),
        mu_names=mn,sigma_names=sn,predictor_names=pn,original_row=d["original_row"])
    ranges=_finite_joint_ranges(model)
    permutation=vcat(collect(ranges.beta),collect(ranges.delta),collect(ranges.cutraw),collect(ranges.alpha))
    return (;model,permutation,mu_names=mn,sigma_names=sn,predictor_names=pn,variable=String(variable),g_tol=Float64(g_tol))
end

function _fit_finite_joint_bridge(prepared)
    model=prepared.model;fit=fit_prepared_joint(model;g_tol=prepared.g_tol)
    out=_bridge_flatten(fit.fit;family="gaussian")
    blocks=vcat(fill("mu",length(prepared.mu_names)),fill("sigma",length(prepared.sigma_names)))
    terms=vcat(prepared.mu_names,prepared.sigma_names)
    ranges=_finite_joint_ranges(model)
    if model.predictor===:ordinal
        cutraw=fit.fit.theta[ranges.cutraw]
        cuts=cumsum(vcat(cutraw[1],exp.(cutraw[2:end])))
        append!(blocks,fill("rawcut_"*prepared.variable,length(cutraw)))
        append!(terms,[k==1 ? "cut1" : "log_spacing$k" for k in eachindex(cutraw)])
        out["ordinal"]=Dict("cutpoints"=>cuts,"theta_raw"=>copy(cutraw),"labels"=>[model.levels[k]*"|"*model.levels[k+1] for k in 1:length(cutraw)])
        pn=prepared.predictor_names
    else
        out["ordinal"]=nothing
        pn=[level*":"*term for level in model.levels[2:end] for term in prepared.predictor_names]
    end
    append!(blocks,fill("mi_"*prepared.variable,length(pn)));append!(terms,pn)
    names=blocks.*"_".*terms
    allunique(names) || throw(ArgumentError("joint finite bridge: ambiguous coefficient names"))
    values=fit.fit.theta[prepared.permutation]
    out["schema"]="joint_missing_finite_result_v1"
    out["coef_names"]=names;out["coefficients"]=values;out["coef"]=Dict(names .=> values)
    out["vcov"]=fit.fit.vcov[prepared.permutation,prepared.permutation];out["vcov_names"]=names
    out["coefficient_blocks"]=blocks;out["coefficient_terms"]=terms
    out["optimizer_status"]=String(fit.metadata.optimizer_status);out["covariance_status"]=String(fit.metadata.covariance_status)
    table=imputed(fit;rows=:all)
    columns=Dict{String,Any}(String(key)=>collect(value) for (key,value) in pairs(table))
    columns["std_error"]=[ismissing(v) ? NaN : v for v in table.std_error]
    columns["se_available"]=.!ismissing.(table.std_error)
    out["imputation"]=columns
    out["original_row"]=copy(model.original_row);out["observed_y"]=copy(model.observed_y);out["observed_x"]=copy(model.observed_x)
    out["predictor_levels"]=copy(model.levels)
    out["conditional_probabilities"]=copy(fit.metadata.conditional_probabilities)
    return out
end

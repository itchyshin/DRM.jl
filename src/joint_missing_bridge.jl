# Primitive transport for the shared joint model. R retains formula preparation;
# only generated design matrices, masks, names and row IDs enter this boundary.
function _joint_bridge_dict(value, label)
    value isa AbstractDict || throw(ArgumentError("joint bridge: $label must be a dictionary"))
    all(k -> k isa Symbol || k isa AbstractString, keys(value)) ||
        throw(ArgumentError("joint bridge: $label keys must be strings or symbols"))
    out = Dict(String(k) => v for (k,v) in value)
    length(out) == length(value) || throw(ArgumentError("joint bridge: duplicate $label keys"))
    return out
end

function _joint_bridge_mask(value, n, label)
    value isa AbstractVector && length(value) == n ||
        throw(ArgumentError("joint bridge: $label has wrong length"))
    all(v -> v isa Bool || (v isa Integer && v in (0,1)), value) ||
        throw(ArgumentError("joint bridge: $label must contain nonmissing Boolean values"))
    return Bool.(value)
end

function _joint_bridge_names(value, n, label)
    names = value isa AbstractString ? [String(value)] :
        value isa AbstractVector && all(v -> v isa AbstractString, value) ? String.(value) :
        throw(ArgumentError("joint bridge: $label must contain strings"))
    length(names) == n && all(!isempty, names) && allunique(names) ||
        throw(ArgumentError("joint bridge: $label has invalid or duplicate names"))
    return names
end

function _prepare_joint_bridge(payload)
    d = _joint_bridge_dict(payload,"payload")
    get(d,"schema",nothing) == "joint_missing_two_gaussian_v1" && return _prepare_two_joint_bridge(d)
    get(d,"schema",nothing) == "joint_missing_finite_v1" && return _prepare_finite_joint_bridge(d)
    required = Set(["schema","predictor","variable","y","x","observed_y","observed_x",
        "X_mu","X_sigma","X_predictor","mu_col","mu_names","sigma_names","predictor_names","original_row","options"])
    Set(keys(d)) == required || throw(ArgumentError("joint bridge: payload fields differ from joint_missing_v1"))
    d["schema"] == "joint_missing_v1" || throw(ArgumentError("joint bridge: unknown schema"))
    d["predictor"] in ("gaussian","bernoulli") || throw(ArgumentError("joint bridge: predictor family not admitted"))
    variable = d["variable"]
    variable isa AbstractString && !isempty(variable) || throw(ArgumentError("joint bridge: invalid variable name"))
    y,x = d["y"],d["x"]
    y isa AbstractVector && x isa AbstractVector && length(y)==length(x) ||
        throw(ArgumentError("joint bridge: x and y must be equal-length vectors"))
    n=length(y);oy=_joint_bridge_mask(d["observed_y"],n,"observed_y");ox=_joint_bridge_mask(d["observed_x"],n,"observed_x")
    all(i -> !oy[i] || (y[i] isa Real && isfinite(y[i])),1:n) &&
        all(i -> !ox[i] || (x[i] isa Real && isfinite(x[i])),1:n) ||
        throw(ArgumentError("joint bridge: observed values must be finite numbers"))
    matrices = [d[key] for key in ("X_mu","X_sigma","X_predictor")]
    all(A -> A isa AbstractMatrix && size(A,1)==n && all(v -> v isa Real && isfinite(v),A), matrices) ||
        throw(ArgumentError("joint bridge: design matrices must be finite with matching rows"))
    Xmu,Xsigma,Xpredictor = Matrix{Float64}.(matrices)
    k=size(Xmu,2);col=d["mu_col"]
    col isa Integer && !(col isa Bool) && 1<=col<=k || throw(ArgumentError("joint bridge: invalid mi column"))
    all(i -> !ox[i] || isapprox(Xmu[i,col],x[i];rtol=1e-12,atol=1e-12),1:n) ||
        throw(ArgumentError("joint bridge: observed predictor and marked design column disagree"))
    mu_names=_joint_bridge_names(d["mu_names"],k,"mu_names")
    sigma_names=_joint_bridge_names(d["sigma_names"],size(Xsigma,2),"sigma_names")
    predictor_names=_joint_bridge_names(d["predictor_names"],size(Xpredictor,2),"predictor_names")
    options=_joint_bridge_dict(d["options"],"options")
    all(key -> key=="g_tol",keys(options)) || throw(ArgumentError("joint bridge: unsupported options"))
    g_tol=get(options,"g_tol",1e-8)
    g_tol isa Real && isfinite(g_tol) && g_tol>0 || throw(ArgumentError("joint bridge: invalid gradient tolerance"))
    fixed=setdiff(collect(1:k),[Int(col)])
    model=prepared_joint_model([oy[i] ? Float64(y[i]) : missing for i in 1:n],
        [ox[i] ? Float64(x[i]) : missing for i in 1:n],Xmu[:,fixed],Xsigma,Xpredictor;
        predictor=Symbol(d["predictor"]),mu_names=mu_names[fixed],sigma_names=sigma_names,
        predictor_names=predictor_names,original_row=d["original_row"])
    # The prepared engine appends the missing-predictor slope. Restore native
    # R model-matrix order for *both* theta and covariance before transport.
    mean_permutation=[j==col ? k : j<col ? j : j-1 for j in 1:k]
    permutation=vcat(mean_permutation,collect((k+1):_joint_ntheta(model)))
    return (;model,permutation,mu_names,sigma_names,predictor_names,variable=String(variable),g_tol=Float64(g_tol))
end

"""
    drm_bridge_joint(payload)

Fit the shared prepared Gaussian-response joint likelihood from a versioned
primitive payload. R owns formula parsing and exogenous-design validation.
Observation masks, not working placeholder values, identify missing data.
The result retains native design-column order, raw covariance coordinates,
original row IDs and conditional imputation uncertainty. This internal bridge
does not add new family, weighting, REML, profile or bootstrap admissions.
"""
function drm_bridge_joint(payload)
    prepared=_prepare_joint_bridge(payload)
    prepared.model isa PreparedTwoJointGaussianModel && return _fit_two_joint_bridge(prepared)
    prepared.model isa PreparedFiniteJointModel && return _fit_finite_joint_bridge(prepared)
    fit=fit_prepared_joint(prepared.model;g_tol=prepared.g_tol)
    out=_bridge_flatten(fit.fit;family="gaussian")
    k=length(prepared.mu_names);r=length(prepared.sigma_names);q=length(prepared.predictor_names)
    blocks=vcat(fill("mu",k),fill("sigma",r),fill("mi_"*prepared.variable,q))
    terms=vcat(prepared.mu_names,prepared.sigma_names,prepared.predictor_names)
    if prepared.model.predictor===:gaussian
        push!(blocks,"logsd_mi_"*prepared.variable);push!(terms,"log_sd")
    end
    names=blocks.*"_".*terms
    values=fit.fit.theta[prepared.permutation]
    out["schema"]="joint_missing_result_v1"
    out["coef_names"]=names;out["coefficients"]=values;out["coef"]=Dict(names .=> values)
    out["vcov"]=fit.fit.vcov[prepared.permutation,prepared.permutation];out["vcov_names"]=names
    out["coefficient_blocks"]=blocks;out["coefficient_terms"]=terms
    out["optimizer_status"]=String(fit.metadata.optimizer_status)
    out["covariance_status"]=String(fit.metadata.covariance_status)
    table=_imputed_joint(fit,Symbol(prepared.variable);rows=:all)
    imputation=Dict{String,Any}(String(key)=>collect(value) for (key,value) in pairs(table))
    imputation["std_error"]=[ismissing(v) ? NaN : v for v in table.std_error]
    imputation["se_available"]=.!ismissing.(table.std_error)
    out["imputation"]=imputation
    out["original_row"]=copy(prepared.model.original_row)
    out["observed_y"]=copy(prepared.model.observed_y)
    out["observed_x"]=copy(prepared.model.observed_x)
    return out
end

# The two-predictor schema keeps all predictor-indexed fields in explicit order.
# It is separate from v1 so old callers cannot silently misread matrices as vectors.
function _prepare_two_joint_bridge(d)
    required = Set(["schema","predictor","variable","y","x","observed_y","observed_x",
        "X_mu","X_sigma","X_predictor","mu_col","mu_names","sigma_names","predictor_names","original_row","options"])
    Set(keys(d)) == required || throw(ArgumentError("joint bridge: payload fields differ from joint_missing_two_gaussian_v1"))
    d["predictor"] == "gaussian" || throw(ArgumentError("joint bridge: two predictors require Gaussian families"))
    variables = _joint_bridge_names(d["variable"],2,"variable")
    y,x = d["y"],d["x"]
    y isa AbstractVector || throw(ArgumentError("joint bridge: y must be a vector"))
    n=length(y)
    x isa AbstractMatrix && size(x)==(n,2) || throw(ArgumentError("joint bridge: x must be n by 2"))
    ox=d["observed_x"]
    ox isa AbstractMatrix && size(ox)==(n,2) || throw(ArgumentError("joint bridge: observed_x must be n by 2"))
    observed_x=(_joint_bridge_mask(ox[:,1],n,"observed_x[1]"),_joint_bridge_mask(ox[:,2],n,"observed_x[2]"))
    oy=_joint_bridge_mask(d["observed_y"],n,"observed_y")
    all(i -> !oy[i] || (y[i] isa Real && isfinite(y[i])),1:n) &&
        all(!observed_x[j][i] || (x[i,j] isa Real && isfinite(x[i,j])) for i in 1:n,j in 1:2) ||
        throw(ArgumentError("joint bridge: observed values must be finite numbers"))
    xp=d["X_predictor"]
    (xp isa Tuple || xp isa AbstractVector) && length(xp)==2 ||
        throw(ArgumentError("joint bridge: X_predictor must contain two design matrices"))
    matrices=[d["X_mu"],d["X_sigma"],xp[1],xp[2]]
    all(A -> A isa AbstractMatrix && size(A,1)==n && all(v -> v isa Real && isfinite(v),A),matrices) ||
        throw(ArgumentError("joint bridge: design matrices must be finite with matching rows"))
    Xmu,Xsigma,Xp1,Xp2=Matrix{Float64}.(matrices)
    k=size(Xmu,2);cols=d["mu_col"]
    cols isa AbstractVector && length(cols)==2 &&
        all(c -> c isa Integer && !(c isa Bool) && 1<=c<=k,cols) && allunique(cols) ||
        throw(ArgumentError("joint bridge: mu_col must contain two distinct integer columns"))
    cols=Int.(cols)
    for j in 1:2
        all(i -> !observed_x[j][i] || isapprox(Xmu[i,cols[j]],x[i,j];rtol=1e-12,atol=1e-12),1:n) ||
            throw(ArgumentError("joint bridge: observed predictor and marked design column disagree"))
    end
    mu_names=_joint_bridge_names(d["mu_names"],k,"mu_names")
    sigma_names=_joint_bridge_names(d["sigma_names"],size(Xsigma,2),"sigma_names")
    pn=d["predictor_names"]
    (pn isa Tuple || pn isa AbstractVector) && length(pn)==2 ||
        throw(ArgumentError("joint bridge: predictor_names must contain two name vectors"))
    predictor_names=(_joint_bridge_names(pn[1],size(Xp1,2),"predictor_names[1]"),
        _joint_bridge_names(pn[2],size(Xp2,2),"predictor_names[2]"))
    options=_joint_bridge_dict(d["options"],"options")
    all(key -> key=="g_tol",keys(options)) || throw(ArgumentError("joint bridge: unsupported options"))
    g_tol=get(options,"g_tol",1e-8)
    g_tol isa Real && isfinite(g_tol) && g_tol>0 || throw(ArgumentError("joint bridge: invalid gradient tolerance"))
    fixed=setdiff(collect(1:k),cols)
    model=prepared_joint_model([oy[i] ? Float64(y[i]) : missing for i in 1:n],
        [observed_x[j][i] ? Float64(x[i,j]) : missing for i in 1:n,j in 1:2],
        Xmu[:,fixed],Xsigma,(Xp1,Xp2);predictor_variables=Tuple(Symbol.(variables)),
        mu_names=mu_names[fixed],sigma_names=sigma_names,predictor_names=predictor_names,original_row=d["original_row"])
    # Prepared mean order is fixed columns followed by the two predictor slopes.
    # invperm restores the caller's entire design, including non-monotonic mi_col.
    permutation=vcat(invperm(vcat(fixed,cols)),collect((k+1):_two_joint_ntheta(model)))
    return (;model,permutation,mu_names,sigma_names,predictor_names,variable=variables,g_tol=Float64(g_tol))
end

function _fit_two_joint_bridge(prepared)
    fit=fit_prepared_joint(prepared.model;g_tol=prepared.g_tol)
    out=_bridge_flatten(fit.fit;family="gaussian")
    blocks=vcat(fill("mu",length(prepared.mu_names)),fill("sigma",length(prepared.sigma_names)))
    terms=vcat(prepared.mu_names,prepared.sigma_names)
    for j in 1:2
        append!(blocks,fill("mi_"*prepared.variable[j],length(prepared.predictor_names[j])))
        append!(terms,prepared.predictor_names[j])
        push!(blocks,"logsd_mi_"*prepared.variable[j]);push!(terms,"log_sd")
    end
    names=blocks.*"_".*terms
    allunique(names) || throw(ArgumentError("joint bridge: generated coefficient names are ambiguous"))
    values=fit.fit.theta[prepared.permutation]
    out["schema"]="joint_missing_two_gaussian_result_v1"
    out["coef_names"]=names;out["coefficients"]=values;out["coef"]=Dict(names .=> values)
    out["vcov"]=fit.fit.vcov[prepared.permutation,prepared.permutation];out["vcov_names"]=names
    out["coefficient_blocks"]=blocks;out["coefficient_terms"]=terms
    out["optimizer_status"]=String(fit.metadata.optimizer_status)
    out["covariance_status"]=String(fit.metadata.covariance_status)
    imputation=Dict{String,Any}()
    for variable in prepared.variable
        table=imputed(fit;variable=variable,rows=:all)
        columns=Dict{String,Any}(String(key)=>collect(value) for (key,value) in pairs(table))
        columns["std_error"]=[ismissing(v) ? NaN : v for v in table.std_error]
        columns["se_available"]=.!ismissing.(table.std_error)
        imputation[variable]=columns
    end
    out["imputation"]=imputation
    out["original_row"]=copy(prepared.model.original_row)
    out["observed_y"]=copy(prepared.model.observed_y)
    out["observed_x"]=hcat(prepared.model.observed_x...)
    out["conditional_covariance"]=copy(fit.metadata.conditional_covariance)
    return out
end

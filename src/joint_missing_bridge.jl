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

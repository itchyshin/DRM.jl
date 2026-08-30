# Native-compatible imputation summaries for the prepared joint model.
# Derived from Gaussian conditional moments and the first-order prediction-error
# identity Var(u_hat-u) ≈ H_uu^-1 + J Var(theta_hat) J'. No native source is copied.

function _joint_uncertainty_status(status::Symbol)
    status === :observed_information_inverse && return "ok"
    status === :hessian_not_positive_definite && return "sdreport_non_pd_hessian"
    status === :hessian_unavailable && return "sdreport_failed"
    return "sdreport_unavailable"
end

function _joint_imputation_uncertainty(model::PreparedJointModel, theta, covariance;
                                      se::Bool = true,
                                      covariance_status::Symbol = :observed_information_inverse)
    moments = prepared_joint_conditional_moments(model, theta)
    n = length(model.y)
    std_error = fill(NaN,n)
    parameter_variance = zeros(n)
    status = _joint_uncertainty_status(covariance_status)
    statuses = fill(status,n)
    result() = (estimate = Float64.(moments.mean), std_error = std_error,
                conditional_variance = Float64.(moments.variance),
                parameter_variance = parameter_variance, uncertainty_status = statuses)
    # Like the native accessor, se=false does not erase an existing fit-level
    # uncertainty failure. Optimizer convergence is a separate diagnostic.
    (!se || status != "ok") && return result()
    p = length(theta)
    if size(covariance) != (p,p) || !all(isfinite,covariance)
        fill!(statuses,"sdreport_unavailable")
        return result()
    end
    V = Matrix{Float64}(covariance)
    if !isapprox(V,V';rtol=1e-12,atol=1e-12) ||
       !issuccess(cholesky(Symmetric(V);check=false))
        fill!(statuses,"sdreport_non_pd_hessian")
        return result()
    end
    ids = findall(.!model.observed_x)
    isempty(ids) && return result()
    if model.predictor === :gaussian
        # Only missing rows need a Jacobian. Multiplication is O(m*p^2), with
        # m missing rows and p fitted parameters; never form an m-by-m matrix.
        J = try
            ForwardDiff.jacobian(t -> prepared_joint_conditional_moments(model,t).mean[ids],theta)
        catch
            fill(NaN,length(ids),p)
        end
        delta = vec(sum((J*V).*J;dims=2))
        parameter_variance[ids] .= delta
    end
    for i in ids
        variance = moments.variance[i]+parameter_variance[i]
        if isfinite(variance) && variance >= 0
            std_error[i] = sqrt(variance)
        else
            statuses[i] = "route_conditional_se_unavailable"
        end
    end
    return result()
end

function _imputed_joint(fit::PreparedJointFit, variable::Symbol; rows = :missing, se::Bool = true)
    choice = rows isa Symbol ? rows : rows isa AbstractString ? Symbol(rows) : nothing
    choice in (:missing,:all) || throw(ArgumentError("imputed: rows must be :missing or :all"))
    values = _joint_imputation_uncertainty(fit.prepared,fit.fit.theta,fit.fit.vcov;
        se=se,covariance_status=fit.metadata.covariance_status)
    model = fit.prepared
    ids = choice === :all ? collect(eachindex(model.y)) : findall(.!model.observed_x)
    sd = Union{Missing,Float64}[isfinite(values.std_error[i]) ? values.std_error[i] : missing for i in ids]
    source = [model.observed_x[i] ? "observed" : model.predictor === :gaussian ?
              "conditional_mode" : "conditional_probability" for i in ids]
    return (variable=fill(String(variable),length(ids)), original_row=copy(model.original_row[ids]),
            model_row=ids, observed=copy(model.observed_x[ids]), estimate=copy(values.estimate[ids]),
            std_error=sd, source=source, uncertainty_status=copy(values.uncertainty_status[ids]))
end

"""
    imputed(fit::PreparedJointFit; variable = :x, rows = :missing, se = true)

Return a Tables-compatible column table of modelled predictor summaries, with
`variable`, `original_row`, `model_row`, `observed`, `estimate`, `std_error`,
`source`, and `uncertainty_status`. `rows=:all` includes observed predictors,
whose standard errors are `missing`; the default returns missing-predictor rows.

Gaussian means are conditional modes. Their standard errors add first-order
parameter uncertainty to conditional variance, matching TMB's prediction-error
approximation. Bernoulli estimates are conditional probabilities and use the
conditional Bernoulli standard deviation. Neither route returns multiple
imputations, posterior intervals, or exact integration over parameter uncertainty.

`se=false` omits all standard errors but retains fit-level uncertainty failures.
The prepared-array interface names its predictor `x`; formula fits retain their
user-supplied predictor name.
"""
function imputed(fit::PreparedJointFit; variable = :x, rows = :missing, se::Bool = true)
    variable in (:x,"x",nothing) || throw(ArgumentError("imputed: the prepared predictor is named x"))
    return _imputed_joint(fit,:x;rows=rows,se=se)
end

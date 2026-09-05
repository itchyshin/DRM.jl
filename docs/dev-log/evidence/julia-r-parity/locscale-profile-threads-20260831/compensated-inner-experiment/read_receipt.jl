using Serialization, SparseArrays
r=deserialize(ARGS[1])
println("inputs_unchanged=",r.inputs_unchanged," all_claims_valid=",r.all_claims_valid," baseline_zero=",r.baseline_zero_reproduces_failure," input_P=",r.input_P_unchanged," candidate_reached=",r.candidate_method_reached," candidate_calls=",r.candidate_method_calls," fallback_calls=",r.generic_fallback_calls)
println("override=",r.override_method)
for phase in (:baseline,:compensated)
 println(phase)
 for x in getfield(r,phase)
  println(x.label," inner=",x.inner_ok," raw_ok=",x.raw_ok," raw=",x.raw_marginal," pd=",x.hessian_pd," l2=",x.gradient_l2," inf=",x.gradient_inf," cert=",x.certificate_bound," bigl2=",x.independent_bigfixed_l2," bigbound=",x.independent_bigfixed_certificate_bound," bigcert=",x.independent_bigfixed_certified," native_big=",x.native_vs_bigfixed_inf," fallback=",x.generic_fallback_calls," candidate=",x.candidate_method_calls," iter=",x.iterations)
 end
end

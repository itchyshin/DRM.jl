using DRM, Serialization
for path in ARGS
 r=deserialize(path)
 println("MODE ", r.mode, " unchanged=", r.source_unchanged, " sameP=", r.input_P_unchanged, " counters=", r.counters)
 for c in r.cases
  println((label=c.label,accepted=c.inner_ok,raw_ok=c.raw_ok,bigcert=c.independent_bigfixed_certified,L2=c.gradient_l2,bigL2=Float64(c.independent_bigfixed_l2),objective_error=Float64(c.f64_minus_frozen_nll_objective)))
 end
 for t in r.direction.rows
  println((alpha=t.alpha,float_change=t.f64_change,big_change=Float64(t.full_bigfixed_change),frozen_change=Float64(t.frozen_nll_change),descent=t.descent_recovered))
 end
end

using DRM, Serialization, SparseArrays
r=deserialize(ARGS[1]);println("source_unchanged=",r.source_unchanged)
for c in r.cases
 println(c.idx,"/",c.side," cold=",c.cold_mode_accepted," invL=",c.invL_opnorm," tight=",c.white_tight_tol)
 for (nm,x) in ((:first,c.first),(:second,c.second))
  x===nothing && continue; q=x.certificate
  println(nm," tol=",x.tol," inner=",x.inner_returned_ok," hpd=",x.returned_hpd," elapsed=",x.elapsed_seconds,
   " ga=",q.ga_l2," bound=",q.original_bound," orig=",q.original_certificate," gz=",q.white_l2,
   " predz/a=",q.finite_predictions_z,"/",q.finite_predictions_a," bigactual=",q.big_actual_l2,"/",q.big_actual_certificate,
   " bigimplicit=",q.big_implicit_l2,"/",q.big_implicit_certificate," map=",q.implicit_vs_actual_maxabs,
   " rt=",q.roundtrip_maxabs," zback=",q.zback_minus_z_maxabs)
 end
end

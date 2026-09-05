using DRM, Serialization, SparseArrays
r=deserialize(ARGS[1]);println("unchanged=",r.source_unchanged," scope=",r.scope)
for c in r.cases
 println(c.idx,"/",c.side," cold=",c.cold_mode_accepted,
  " orig=",c.original.M64," white=",c.intended_whitening.M64," frozen=",c.frozenP64_whitening.M64,
  " big=",Float64(c.big_reference.Moriginal)," err=",Float64(c.big_reference.original_surrogate_abs_error),"/",Float64(c.big_reference.intended_surrogate_abs_error),"/",Float64(c.big_reference.frozenP64_surrogate_abs_error),
  " rt=",c.intended_whitening.roundtrip_maxabs," cond=",c.original.H_condition,"/",c.intended_whitening.H_condition,
  " map=",Float64(c.big_reference.intended_mapping_maxabs)," Cdiff=",c.frozenP64_whitening.C_target_maxabs,
  " ident=",Float64(c.big_reference.identity_error))
end

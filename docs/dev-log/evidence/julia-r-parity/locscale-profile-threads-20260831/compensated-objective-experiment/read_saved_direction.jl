using DRM, Serialization, SparseArrays
r=deserialize(ARGS[1])
println(r.base)
for t in r.trials
 println(t.alpha," ",t.f64_change," ",t.bigfixed_change," signs=",t.float_big_same_sign)
end

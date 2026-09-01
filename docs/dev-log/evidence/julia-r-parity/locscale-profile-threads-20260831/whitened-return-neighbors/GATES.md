# Fixed-point representability diagnostic

CHECK: python3 run_capped.py <fresh UTC stamp>
EXPECT: status0 and FIXED_NEIGHBOR_ENUMERATION_COMPLETE, within30s.

Execution success is not numerical success. For each endpoint, retain all9
pair-neighbor residuals pergroup, original and selected full residual, threshold,
exact points and component gradients. A numerical pass requires the full
independent256-bit original-coordinate residual <=1e-9*(1+norm(a)). Q must beI.
No inner/outer solves; no production repair or inference gate closure implied.

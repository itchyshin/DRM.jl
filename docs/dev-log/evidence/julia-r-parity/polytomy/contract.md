# Rooted multifurcation contract

For directed incidence matrix B (one edge row, -1 at parent and +1 at child),
positive lengths b define Q = Bᵀ diag(1/b) B. A connected tree has N-1 edges and
rank(Q)=N-1 regardless of node degree. Conditioning the root removes its row/column;
every retained state is a sum of independent edge increments. Therefore
C[i,j] = sum(b[e] for e shared by root→tip i and root→tip j).
This path formula is the independent oracle; inverting Q alone is not independent.
Binary N=2p-1 is only a special case. Use actual N and q=N-1 downstream.

Direct Julia retains supplied lengths and raw Brownian SD scale. The R bridge
retains its existing correlation-scale conversion. No arbitrary binary resolution,
positive invented branches, root ridge or estimator change is permitted. Tests must
cover star, mixed multifurcations, reordered edges and a root not numbered last,
non-unit heights, repeated observations and malformed graphs. Keep valid binary
fixtures. A breadth-first height walk must not shift a wide queue on every node.

This slice addresses positive-length multifurcations. Native R accepts additional
zero-length/unary/label cases that remain required full parity work. Preserving an
explicit current refusal for these does not close their capability requirement.
Ayumi's profile/bootstrap report remains unverified without her exact model.

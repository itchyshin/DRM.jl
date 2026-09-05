# Stable difference identity — prototype only

No refits or production source changes. On the saved Gamma/NB2 endpoints,
Float-Hessian GL1/2/4/8 quadrature converges to negative differences agreeing
with128/256bit full-NLL evaluation: Gamma GL8-4.565700313e-20(reference
-4.565766337e-20), NB2 GL8-4.674520777e-19(reference-4.674503040e-19).
Opposite steps are positive. Exactquadratic and nearbyquartic controls distinguish
an exactidentity from insufficientquadratureorder.

BigFloat Hessian evaluation is UNSUPPORTED: trigamma(::BigFloat) raises a
MethodError for both families. No silentfallback occurred. Float quadrature
agreement is an error-estimation signal, NOT a rigorous remainder bound or
certifieddescent claim. Failed firstprobe is retained. A finitevalidation and
estimatederror contract is under independentreview before productionchanges.

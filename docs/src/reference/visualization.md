# Visualization

!!! note "Status — Reference"
    Mirrors drmTMB's [Visualization](https://itchyshin.github.io/drmTMB/reference/index.html) (3 in drmTMB). DRM.jl keeps the base package plotting-dependency-free: these return the *data* a plot needs — a profile-deviance grid, a correlation summary — so any backend (Makie / Plots) can render them in a few lines. They are the data behind drmTMB's `plot_parameter_surface` / `plot_corpairs`.

## Plotting data providers

```@docs
parameter_surface
corpairs_data
```

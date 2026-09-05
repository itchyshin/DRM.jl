# Read the literal production pages tree without running makedocs or deploydocs.
# Do not eval this AST: calls, interpolation and computed paths are not data.
function navigation_literal(x)
    x isa String && return x
    if x isa Expr && x.head == :vect
        return map(navigation_literal, x.args)
    elseif x isa Expr && x.head == :call && length(x.args) == 3 && x.args[1] == :(=>)
        x.args[2] isa String || throw(ArgumentError("navigation title must be literal text"))
        return x.args[2] => navigation_literal(x.args[3])
    end
    throw(ArgumentError("production navigation must contain only literal strings, arrays and pairs"))
end

function production_navigation(source::String)
    ast = Meta.parseall(source)
    statements(x) = x isa Expr && x.head == :toplevel ? reduce(vcat, map(statements, x.args); init=Any[]) : Any[x]
    calls = filter(x -> x isa Expr && x.head == :call && x.args[1] == :makedocs, statements(ast))
    length(calls) == 1 || throw(ArgumentError("expected one top-level makedocs call"))
    kwargs = Any[]
    for x in calls[1].args[2:end]
        if x isa Expr && x.head == :parameters
            append!(kwargs, x.args)
        else
            push!(kwargs, x)
        end
    end
    pages = filter(x -> x isa Expr && x.head == :kw && x.args[1] == :pages, kwargs)
    length(pages) == 1 || throw(ArgumentError("expected one literal pages keyword"))
    result = navigation_literal(pages[1].args[2])
    result isa Vector || throw(ArgumentError("pages must be an array"))
    return result
end

function navigation_paths(x)
    x isa String && return [x]
    x isa Pair && return navigation_paths(x.second)
    x isa Vector && return reduce(vcat, map(navigation_paths, x); init=String[])
    throw(ArgumentError("invalid navigation node"))
end

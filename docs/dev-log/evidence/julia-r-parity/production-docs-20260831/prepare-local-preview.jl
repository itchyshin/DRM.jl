using Documenter, DocumenterVitepress, SHA
root = abspath(only(ARGS))
isdir(root) || error("existing isolated preview required")
for name in ("siteinfo.js", "versions.js")
    ispath(joinpath(root,name)) && error("metadata must be absent before preparation")
end
# Local-only preview: no deploydocs, git, network or push is called.
Documenter.HTMLWriter.generate_siteinfo_file(root, "dev", true)
Documenter.postprocess_before_push(DocumenterVitepress.BaseVersion("");
    subfolder=nothing, devurl="dev", deploy_dir=root, dirname=root)
for name in ("siteinfo.js", "versions.js")
    println(name, " ", bytes2hex(sha256(read(joinpath(root,name)))))
end

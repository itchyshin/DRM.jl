using DRM, Test, Random
_say(m)=(println(stdout,m);flush(stdout))
for f in ["test_student.jl","test_student_re.jl","test_student_slope_re.jl"]
    t0=time()
    try; _say(">>> "*f); include(f); _say(">>> ok  "*f*"  $(round(time()-t0;digits=1))s")
    catch e; _say(">>> FAILED "*f*" :: "*sprint(showerror,e)); end
end
_say(">>> STUDENT DONE")

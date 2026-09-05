using Serialization
using SHA

log_path, script_path, status_path, output_path = ARGS
lines = readlines(log_path)
record = (
    kind=:DERIVED_FROM_LOG_STRING,
    log_path=log_path,
    log_sha256=bytes2hex(sha256(read(log_path))),
    script_path=script_path,
    script_sha256=bytes2hex(sha256(read(script_path))),
    status_path=status_path,
    status_json=read(status_path, String),
    case_records=filter(line -> startswith(line, "S11_WHITE_CASE="), lines),
    cross_precision_records=filter(line -> startswith(line, "S11_WHITE_CROSS_PRECISION="), lines),
    control_records=filter(line -> startswith(line, "S11_WHITE_GAMMA_DENSITY_ANCHOR=") ||
                             startswith(line, "S11_WHITE_DERIVATIVE_CONTROL=") ||
                             startswith(line, "S11_WHITE_GAUSSIAN_NORMALIZATION_CONTROL="), lines),
)
serialize(output_path, record)
println("S11_WHITE_FREEZE=", repr((output=output_path, log_sha256=record.log_sha256,
    script_sha256=record.script_sha256, cases=length(record.case_records),
    cross_precision=length(record.cross_precision_records), controls=length(record.control_records))))

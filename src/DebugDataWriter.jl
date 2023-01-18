module DebugDataWriter

using JSON

export get_debug_id, debug_output, @debug_output, config

mutable struct DdwConfig
    enable_dump::Bool
    enable_log::Bool

    out_dir::String

    default_writer::Function

    log_filename::String

    type_writer::Dict{Type,Function}
end

struct DdbContext
    prefix::String
end

GLOBAL_DDW_CONFIG = DdwConfig(
    false,
    false,
    "debug_out",
    ((io, data),) -> JSON.write(io, data, 2),
    "debug_out.log",
    Dict()
)

config() = GLOBAL_DDW_CONFIG

get_file_name(title) =
    replace(title, r"[\s,]+" => "_") |> fn -> fn[1:min(100, end)]

function get_debug_id(title::String)
    ms = round(Int64, time() * 1000)
    prefix = string(ms, base=16)
    if !isempty(title)
        prefix *= "_" * get_file_name(title)
    end
    return prefix
end

get_debug_id() = get_debug_id("")

function debug_output(data_getter::Function, debug_id::AbstractString,
    code_pos::Union{AbstractString,Nothing}, title::AbstractString)
    cfg = config()

    data = nothing
    details_fn = nothing

    if cfg.enable_dump || cfg.enable_log
        data = data_getter()
    end

    if cfg.enable_dump
        path = joinpath(cfg.out_dir, debug_id)

        isdir(cfg.out_dir) || mkdir(cfg.out_dir)
        isdir(path) || mkdir(path)

        details_fn = joinpath(path, get_file_name(title) * ".json")

        open(details_fn, "w") do io
            JSON.print(io, data, 2)
        end
    end

    if cfg.enable_log
        isnothing(code_pos) || @info code_pos debug_id title data details_fn
    end
end

debug_output(debug_id::AbstractString, code_pos, title::AbstractString, data::Any) =
    debug_output(() -> data, debug_id, code_pos, title)

debug_output(debug_id::AbstractString, code_pos, title::AbstractString, data_getter::Function) =
    debug_output(data_getter, debug_id, code_pos, title)

macro debug_output(debug_id, title, data_func)
    code_pos = string(__source__)
    # code_pos = string(@__FILE__, ":", @__LINE__)
    return :(debug_output($(esc(debug_id)), $code_pos, $title, $data_func))
end

end

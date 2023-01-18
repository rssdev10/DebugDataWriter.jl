module DebugDataWriter

using JSON
using PrettyTables
using Dates

export get_debug_id, debug_output, @debug_output, config

mutable struct DdwConfig
    enable_dump::Bool
    enable_log::Bool

    out_dir::String

    default_writer::Function

    log_filename::String

    format_writers::Dict{Symbol,Function}

    path_format_fulltime::Bool
end

struct DdbContext
    prefix::String
end

const FORMAT_WRITERS = Dict(
    :JSON => (io, data) -> JSON.print(io, data, 2),
    :HTML => (io, data) -> begin
        PrettyTables.pretty_table(io, data; backend=Val(:html), standalone=true)
    end,
    :TXT => (io, data) -> begin
        if isa(data, AbstractString)
            write(io, data)
        else
            PrettyTables.pretty_table(io, data)
        end
    end,
    :SVG => (io, data) -> write(io, data),
    :XML => (io, data) -> write(io, data)
)

const GLOBAL_DDW_CONFIG = DdwConfig(
    false,
    false,
    "debug_out",
    FORMAT_WRITERS[:JSON],
    "debug_out.log",
    FORMAT_WRITERS,
    true
)

config() = GLOBAL_DDW_CONFIG

get_file_name(title) =
    replace(title, r"[\s,]+" => "_") |> fn -> fn[1:min(100, end)]

function get_debug_id(title::String)
    cfg = config()

    if !cfg.enable_dump && !cfg.enable_log
        return ""
    end

    prefix = if cfg.path_format_fulltime
        dt = Dates.now()
        Dates.format(dt, "yyyymmdd-HHMMSS-SSS")
    else
        ms = round(Int64, time() * 1000)
        string(ms, base=16)
    end

    if !isempty(title)
        prefix *= "_" * get_file_name(title)
    end
    return prefix
end

get_debug_id() = get_debug_id("")

function debug_output(data_getter::Function, debug_id::AbstractString,
    code_pos::Union{AbstractString,Nothing}, title::AbstractString, fmt=:JSON)
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

        details_fn = joinpath(path, get_file_name(title) * "." * lowercase(string(fmt)))

        open(details_fn, "w") do io
            func = get(cfg.format_writers, fmt, cfg.default_writer)
            func(io, data)
        end
    end

    if cfg.enable_log
        isnothing(code_pos) || @info code_pos debug_id title data details_fn
    end
end

debug_output(debug_id::AbstractString, code_pos,
    title::AbstractString, data::Any; fmt=:JSON) =
    debug_output(() -> data, debug_id, code_pos, title, fmt)

debug_output(debug_id::AbstractString, code_pos,
    title::AbstractString, data_getter::Function; fmt=:JSON) =
    debug_output(data_getter, debug_id, code_pos, title, fmt)

macro debug_output(debug_id, title, data_func)
    code_pos = string(__source__)
    return :(debug_output($(esc(debug_id)), $code_pos, $title, $data_func))
end

macro debug_output(debug_id, title, data_func, fmt)
    code_pos = string(__source__)

    supported_outputs = keys(FORMAT_WRITERS)
    local fmt_expr = last(esc(fmt).args)
    # @show esc(fmt), fmt_expr, typeof(fmt_expr)
    if !isa(fmt_expr, QuoteNode) || !(fmt_expr.value in supported_outputs)
        throw(
            ErrorException(
                "Error format $fmt. Only the following formats are supported: " *
                join(supported_outputs, "; "
                )
            )
        )
    end

    # code_pos = string(@__FILE__, ":", @__LINE__)
    return :(debug_output($(esc(debug_id)), $code_pos, $title, $data_func, fmt=$fmt_expr))
end

end

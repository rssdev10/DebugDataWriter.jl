module DebugDataWriter

using JSON
using PrettyTables
using Dates

export get_debug_id, debug_output, @debug_output, config,
    @ddw_dout, @ddw_get_id

mutable struct DdwConfig
    """
    Enable saving dumps of data structures.
    """
    enable_dump::Bool

    """
    Enable adding trace info with the `@info` macro and output into stdout.
    Each record contains links to the source code and to the saved data file. 
    """
    enable_log::Bool

    """
    Output path for new directories and files 
    """
    out_dir::String

    default_writer::Function

    log_filename::String

    format_writers::Dict{Symbol,Function}

    """
    Use full ISO date/time format (default).
    Or just HEX representaion of time in seconds.
    """
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

truncate_string(str, limit) =
    limit < length(str) ? str[begin:nextind(str, 0, limit)] : str

get_file_name(title) =
    replace(title, r"\W+" => "_") |> fn -> truncate_string(fn, 100)

"""
    get_debug_id(title)

Generates `id` based on current date/time and the `title`.
`id` is used as a name of further output sub-directory of `debug_out`.
"""
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

"""
    get_debug_id()

Generates `id` based on current date/time only.
"""
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

"""
    @debug_output debug_id title data_or_func

    `debug_id` in fact is a name of output sub-directory

    `title` is used as a name of the output file in that directory
    to distinguish output data. All non alpha-num symbols are translated
    into the `_` character.

    `data_or_func`. The data for debug output might be provided as a literal,
    a variable or a lambda function. The lambda-function will be activated
    if only `enable_dump` is true.    
"""
macro debug_output(debug_id, title, data_func)
    code_pos = string(__source__)
    return :(debug_output($(esc(debug_id)), $code_pos, $(esc(title)), $(esc(data_func))))
end

"""
    @debug_output debug_id title data_or_func fmt


    Same as [`@debug_output debug_id title data_or_func`](@ref).
    Additional `fmt` argument specifies an output format. Default is JSON. 
    Implemented formats are JSON with JSON.jl, HTML and TXT with PrettyTables.jl,
    and SVG, XML as raw data output.

    See details of the `FORMAT_WRITERS` dictionary
"""
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
    return :(debug_output($(esc(debug_id)), $code_pos, $(esc(title)), $(esc(data_func)), fmt=$fmt_expr))
end

# Zero cost mode

"""
Do nothing if `DEBUG_OUTPUT` environment variable is not defined
Enables debug mode if `DEBUG_OUTPUT` contains `log` or `dump` 
"""
function is_debug_output_enabled()
    mode = get(ENV, "DEBUG_OUTPUT", nothing)

    isnothing(mode) && return false

    contains(mode, "log") && (config().enable_log = true)
    contains(mode, "dump") && (config().enable_dump = true)

    return true
end

"""
Get `debug_id`. 
The `debug_id` is used to merge multiple outputs into a single directory
with a name starting with `debug_id`.
"""
macro ddw_get_id(title)
    is_debug_output_enabled() || return :("")

    return :(get_debug_id($(esc(title))))
end

macro ddw_get_id()
    return :(@ddw_get_id(""))
end

"""
Do debug output
`debug_id` - name of the directory for the `log` mode output
`title` - name of the file inside the output directory
`data_func` - source data function
"""
macro ddw_dout(debug_id, title, data_func)
    is_debug_output_enabled() || return

    return :(@debug_output($(esc(debug_id)), $(esc(title)), $(esc(data_func))))
end

"""
Do debug output
`debug_id` - name of the directory for the `log` mode output
`title` - name of the file inside the output directory
`data_func` - source data function
`fmt` - format of ouput. See `FORMAT_WRITERS` constant.
"""
macro ddw_dout(debug_id, title, data_func, fmt)
    is_debug_output_enabled() || return

    return :(@debug_output($(esc(debug_id)), $(esc(title)), $(esc(data_func)), $fmt))
end

end

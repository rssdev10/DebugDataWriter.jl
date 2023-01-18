using DebugDataWriter
using Test

@testset "DebugDataWriter.jl" begin

    DebugDataWriter.config().enable_log = true
    DebugDataWriter.config().enable_dump = true

    id = get_debug_id()
    debug_output(id, nothing, "array") do
        collect(1:100)
    end

    id = get_debug_id("query with something interesting")
    debug_output(id, nothing, "some dict", Dict(1 => 2, "a" => :b))

    id = get_debug_id("Another query")
    @debug_output id "some complex structure" ones(2, 3)
    @debug_output id "some structure as lambda" begin
        zeros(5, 2)
    end

    @debug_output id "some structure as lambda" begin
        zeros(5, 2)
    end

    # check the case with logging but without details
    DebugDataWriter.config().path_format_fulltime = false
    id_hexpath = get_debug_id("Another query")
    @debug_output id_hexpath "with details" 0
    DebugDataWriter.config().enable_dump = false
    @debug_output id_hexpath "without details" 0
    DebugDataWriter.config().enable_dump = true
    DebugDataWriter.config().path_format_fulltime = true

    @debug_output id "text table" ones(2, 3) :JSON
    @debug_output id "text table" ones(2, 3) :TXT
    @debug_output id "HTML table" ones(2, 3) :HTML
    @debug_output id "text as a text" "ones(2, 3)" :TXT
    @debug_output id "some SVG" "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><svg></svg>" :SVG
    @debug_output id "some XML" "<?xml version=\"1.0\" encoding=\"UTF-8\" ?><doc></doc>" :XML

    # @macroexpand @debug_output debug_id "some complex structure" ones(2, 3)
end

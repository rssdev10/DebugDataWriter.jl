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

    DebugDataWriter.config().enable_dump = false

    @debug_output id "without details" 0

    # @macroexpand @debug_output debug_id "some complex structure" ones(2, 3)
end

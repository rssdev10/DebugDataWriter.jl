# DebugDataWriter

The package provides saving of debug data into separate files. 

Minimal use case:
```julia
    using DebugDataWriter

    # Enable adding trace info with the @info macro
    # Each record contains links to the source code and to the saved data file 
    DebugDataWriter.config().enable_log = true

    # Enable saving dumps of data structures
    DebugDataWriter.config().enable_dump = true

    id = get_debug_id("Some query")
    @debug_output id "some complex structure" ones(2, 3)
    @debug_output id "some complex structure" ones(2, 3) :HTML
    @debug_output id "some complex structure" ones(2, 3) :TXT

    # the lambda is executed when enable_dump == true
    @debug_output id "some data structure as a lambda" begin
        zeros(5, 2)
    end
```

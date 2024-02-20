# DebugDataWriter

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rssdev10.github.io/DebugDataWriter.jl/stable)

The package provides saving of debug data into separate files. 

## Minimal use case
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

## Environment based output

This is case is zero cost when the environment variable `DEBUG_OUTPUT` is not defined.
The variable may be initialized in the system environment:

```bash
export DEBUG_OUTPUT="log | dump"
```

Or be initialized directly in Julia, but BEFORE including the code where macos are used.

```julia
ENV["DEBUG_OUTPUT"] = "log | dump"
```

There string contains the same names of modes as in the previous case. It can be any combination of modes: "log", "dump | log", etc.

Example:
```julia
    # id = @ddw_get_id  # this call gives a default name
    id = @ddw_get_id "test" # id will have this prefix

    @ddw_dout id "some structure as lambda" begin
        zeros(5, 2)
    end
    @ddw_dout id "text as a text" "ones(2, 3)" :TXT
```

# DebugDataWriter

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rssdev10.github.io/DebugDataWriter.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rssdev10.github.io/DebugDataWriter.jl/dev)

GitHub Actions : [![Build Status](https://github.com/rssdev10/DebugDataWriter.jl/workflows/CI/badge.svg)](https://github.com/rssdev10/DebugDataWriter.jl/actions?query=workflow%3ACI+branch%3Amaster)

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

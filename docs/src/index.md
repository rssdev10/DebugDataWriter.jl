# DebugDataWriter

Simple debug data formatter and writer. The package DebugDataWriter.jl provides writing of debug information into external files in a human readable format.

### Examples
```julia
    id = get_debug_id("Some query")

    @debug_output id "some complex structure" ones(2, 3)

    @debug_output id "some structure as lambda" begin
        zeros(5, 2) # here we can put some code for preparing data for output
    end


    matrix = ones(2, 3)
    @debug_output id "text table" ones(2, 3) :JSON
    @debug_output id "text table" ones(2, 3) :TXT
    @debug_output id "HTML table" ones(2, 3) :HTML
    @debug_output id "HTML table from variable" matrix :HTML
    @debug_output id title matrix :HTML  
```

### Configuration

There are two ways to configure the module. First case is to do it with configuration variable.

Enable saving dumps of data structures. If the output disabled (`false`), there is no overhead in a program execution
```julia
DebugDataWriter.config().enable_dump = true
```

Enable adding trace info with the `@info` macro and output into stdout.
Each record contains links to the source code and to the saved data file. 
```julia
DebugDataWriter.config().enable_log = true
```

In this case, the output will look like this. 
```txt
┌ Info: #= /Users/.../DebugDataWriter/test/runtests.jl:48 =#
│   debug_id = "20230330-084712-012_Another_query"
│   title = "text as a text"
│   data = "ones(2, 3)"
└   details_fn = "debug_out/20230330-084712-012_Another_query/text_as_a_text.txt"
```
If you are using VS Code, simply click on this link. VS Code will open the line of code where this message/data was generated.

Additionally, if you are using that option, just click on `debug_out/20230330-084712-012_Another_query/text_as_a_text.txt` to open that in an editor.


Date/time prefix for generated directories in an output path. There are two options: full ISO date/time format - `20230330-084712-012_Some_title` (default) or just HEX representation of time in seconds like `187310e4a8e_Another_title` when `path_format_fulltime` is `false`.
```julia
DebugDataWriter.config().path_format_fulltime = false

```

Alternative way to enable debug output is usage of the system environment variable `DEBUG_OUTPUT`.
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

    @ddw_out id "some structure as lambda" begin
        zeros(5, 2)
    end
    @ddw_out id "text as a text" "ones(2, 3)" :TXT
```

The advantage of this approach is zero impact on the code if `DEBUG_OUTPUT` is not defined. However, the disadvantage of this approach is that debug output cannot be enabled within the program dynamically. If you want to enable or disable debug output, you must rerun the application with a different value of the `DEBUG_OUTPUT` variable.

### Functions

```@autodocs
Modules = [DebugDataWriter]
```

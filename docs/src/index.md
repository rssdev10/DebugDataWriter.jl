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

Enable saving dumps of data structures. If the output disabled (`false`), there is no overhead in a program execution
```julia
DebugDataWriter.config().enable_dump = true
```

Enable adding trace info with the `@info` macro and output into stdout.
Each record contains links to the source code and to the saved data file. 
```julia
DebugDataWriter.config().enable_log = true
```

Output in that case looks like here. While using VS Code, just click on that link and open the code line from where that message/data were generated.
```txt
┌ Info: #= /Users/.../DebugDataWriter/test/runtests.jl:48 =#
│   debug_id = "20230330-084712-012_Another_query"
│   title = "text as a text"
│   data = "ones(2, 3)"
└   details_fn = "debug_out/20230330-084712-012_Another_query/text_as_a_text.txt"
```
Additionally, if you are using that option, just click on `debug_out/20230330-084712-012_Another_query/text_as_a_text.txt` to open that in an editor.


Date/time prefix for generated directories in an output path. There are two options: full ISO date/time format - `20230330-084712-012_Some_title` (default) or just HEX representation of time in seconds like `187310e4a8e_Another_title` when `path_format_fulltime` is `false`.
```julia
DebugDataWriter.config().path_format_fulltime = false

```

### Functions

```@autodocs
Modules = [DebugDataWriter]
```

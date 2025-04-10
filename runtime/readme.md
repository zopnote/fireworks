# Engine runtime
The engine runtime is build in the same way as every module does. First in the build process the 
``cmdline`` tooling will be built and then parts of it will be used to compile the engine runtime.
CMake will then collect the output binaries of the ``cmdline`` builder tool, the tool itself, the libraries and headers
as well the extra tooling (``tools/``) and put all together in the finished sdk build.
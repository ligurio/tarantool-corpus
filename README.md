### How-to build

```sh
$ git clone https://github.com/tarantool/tarantool
$ cd tarantool
$ CC=clang CXX=clang++ cmake -S . -B build -G Ninja -DENABLE_FUZZER=ON -DENABLE_UB_SANITIZER=ON
$ cmake --build build/ --parallel 8 --target lua_fuzzer
```

### How-to run

Structure-aware fuzzing:

```
$ git clone https://github.com/ligurio/test-corpus
$ ./build/test/fuzz/lua_fuzzer/lua_fuzzer -reduce_inputs=1 -mutate_depth=20 -print_final_stats=1 -report_slow_units=5 -use_value_profile=1 -artifact_prefix="luajit-" -print_pcs=1 -reload=1 -jobs=8 -dict=./test-corpus/luajit.dict test-corpus/luajit/protobuf/
```

```
$ git clone https://github.com/ligurio/test-corpus
$ ./build/test/fuzz/luaL_loadbuffer_fuzzer -reduce_inputs=1 -mutate_depth=20 -print_final_stats=1 -report_slow_units=5 -use_value_profile=1 -artifact_prefix="luajit-" -print_pcs=1 -reload=1 -only_ascii=1 -dict=./test-corpus/luajit.dict test-corpus/luajit/lua/lua
```

### How-to merge corpuses

```sh
$ ./build/test/fuzz/lua_fuzzer/lua_fuzzer -set_cover_merge=1 corpus new_corpus
$ ./build/test/fuzz/lua_fuzzer/lua_fuzzer -merge=1 corpus new_corpus
```

### Code coverage

Compile and link with `-fprofile-instr-generate -fcoverage-mapping` options. When
using `-fsanitize=address`, no `.profraw` will be written on crash or abort, so
once the fuzzing test is finished, a second run is needed by passing only files
in corpus, run: `./fuzzer -runs=0 ./corpora_minimized`:

```
$ CFLAGS="-fprofile-instr-generate -fcoverage-mapping" CC=clang CXX=clang++ cmake -S . -B build -G Ninja -DENABLE_FUZZER=ON
$ cmake --build build --parallel
$ ./build/test/fuzz/http_parser_fuzzer -runs=0
```

Then to generate an html view:

```sh
$ llvm-profdata merge -sparse default.profraw -o default.profdata
$ llvm-cov show --format=html ./build/src/tarantool -instr-profile=default.profdata > coverage.html
```

Show code coverage for a single function with a name `http_parser`:

```sh
$ llvm-cov show ./build/src/tarantool -instr-profile=default.profdata -name=http_parser
```

<!--
https://github.com/google/fuzzing/blob/master/tutorial/libFuzzerTutorial.md#visualizing-coverage
https://clang.llvm.org/docs/SourceBasedCodeCoverage.html
https://llvm.org/docs/CoverageMappingFormat.html
https://github.com/google/fuzzing/issues/41#issuecomment-1031942660
https://google.github.io/oss-fuzz/advanced-topics/code-coverage/#generate-code-coverage-reports
-->

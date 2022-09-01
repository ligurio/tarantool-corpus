### How-to build

```sh
$ git clone https://github.com/tarantool/tarantool
$ cd tarantool
$ CC=clang CXX=clang++ cmake -S . -B build -G Ninja -DENABLE_FUZZER=ON -DENABLE_UB_SANITIZER=ON
$ cmake --build build/ --parallel 8 --target lua_fuzzer
```

### How-to run

```
$ git clone https://github.com/ligurio/test-corpus
$ ./build/test/fuzz/lua_fuzzer/lua_fuzzer -reduce_inputs=1 -mutate_depth=20 -print_final_stats=1 -report_slow_units=5 -use_value_profile=1 -artifact_prefix="luajit-" -print_pcs=1 -reload=1 -jobs=8 -dict=./test-corpus/luajit.dict test-corpus/luajit/corpus_lua/
```

### How-to merge corpuses

```sh
$ ./build/test/fuzz/lua_fuzzer/lua_fuzzer -set_cover_merge=1 corpus new_corpus
$ ./build/test/fuzz/lua_fuzzer/lua_fuzzer -merge=1 corpus new_corpus
```

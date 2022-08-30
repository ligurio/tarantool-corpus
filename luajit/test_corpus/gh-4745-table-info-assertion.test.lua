test_run = require('test_run').new()
engine = test_run:get_cfg('engine')
--
-- Make sure that 'pragma table_info()' correctly handles tables
-- without primary key.
--
T = box.schema.create_space('T', {         \
    engine = engine,                       \
    format = {{'i', 'integer'}}            \
})
_ = box.execute('pragma table_info(T)')
T:drop()

--
-- Basic test for transaction throttling.
--
-- It checks that write transactions aren't stalled for long
-- due to hitting the memory limit, but instead are throttled
-- in advance.
--
test_run = require('test_run').new()
test_run:cmd("create server test with script='vinyl/low_quota.lua'")
test_run:cmd(string.format("start server test with args='%d'", 32 * 1024 * 1024))
test_run:cmd('switch test')

fiber = require('fiber')
digest = require('digest')

box.cfg{snap_io_rate_limit = 8}

FIBER_COUNT = 5
TUPLE_SIZE = 1000
TX_TUPLE_COUNT = 10
TX_SIZE = TUPLE_SIZE * TX_TUPLE_COUNT
TX_COUNT = math.ceil(box.cfg.vinyl_memory / (TX_SIZE * FIBER_COUNT))

s = box.schema.space.create('test', {engine = 'vinyl'})
_ = s:create_index('primary', {parts = {1, 'unsigned', 2, 'unsigned', 3, 'unsigned'}})

latency = 0
c = fiber.channel(FIBER_COUNT)

test_run:cmd("setopt delimiter ';'")
for i = 1, FIBER_COUNT do
    fiber.create(function()
        for j = 1, TX_COUNT do
            local t1 = fiber.time()
            box.begin()
            for k = 1, TX_TUPLE_COUNT do
                s:replace{i, j, k, digest.urandom(TUPLE_SIZE)}
            end
            box.commit()
            local t2 = fiber.time()
            latency = math.max(latency, t2 - t1)
        end
        c:put(true)
    end)
end;
test_run:cmd("setopt delimiter ''");

for i = 1, FIBER_COUNT do c:get() end

latency < 0.2 or latency

test_run:cmd('switch default')
test_run:cmd("stop server test")
test_run:cmd("cleanup server test")

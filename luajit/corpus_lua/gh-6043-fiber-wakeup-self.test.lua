#!/usr/bin/env tarantool

local tap = require('tap')
local fiber = require('fiber')

--
-- gh-6043: fiber.wakeup() on self could lead to a crash if followed by
-- fiber.create(). Also it could lead to spurious wakeup if followed by a sleep
-- with non-zero timeout, or by, for example, an infinite yield such as WAL
-- write.
--

local function test_wakeup_self_and_call(test)
    test:plan(3)

    local self = fiber.self()
    fiber.wakeup(self)
    local count = 0
    local f = fiber.create(function()
        count = count + 1
        fiber.yield()
        count = count + 1
    end)
    test:is(count, 1, 'created a fiber')
    fiber.yield()
    test:is(count, 2, 'it yielded')
    test:is(f:status(), 'dead', 'and ended')
end

box.cfg{}

local test = tap.test('gh-6043-fiber-wakeup-self')
test:plan(1)
test:test('wakeup self + call', test_wakeup_self_and_call)

os.exit(test:check() and 0 or 1)

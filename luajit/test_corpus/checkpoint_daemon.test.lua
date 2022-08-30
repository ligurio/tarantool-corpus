fio = require 'fio'
errno = require 'errno'
fiber = require 'fiber'
env = require('test_run')
test_run = env.new()

test_run:cleanup_cluster()

default_checkpoint_count = box.cfg.checkpoint_count
default_checkpoint_interval = box.cfg.checkpoint_interval
box.cfg{checkpoint_interval = 0}

PERIOD = jit.os == 'Linux' and 0.03 or 1.5
WAIT_COND_TIMEOUT = 10

space = box.schema.space.create('checkpoint_daemon')
index = space:create_index('pk', { type = 'tree', parts = { 1, 'unsigned' }})

test_run:cmd("setopt delimiter ';'")

-- wait_snapshot* functions update these variables.
snaps = {};
xlogs = {};

-- Wait until tarantool creates a snapshot containing current
-- data slice.
function wait_snapshot(timeout)
    snaps = {}
    xlogs = {}
    local signature_str = tostring(box.info.signature)
    signature_str = string.rjust(signature_str, 20, '0')
    local exp_snap_filename = string.format('%s.snap', signature_str)
    return test_run:wait_cond(function()
        snaps = fio.glob(fio.pathjoin(box.cfg.memtx_dir, '*.snap'))
        xlogs = fio.glob(fio.pathjoin(box.cfg.wal_dir, '*.xlog'))
        return fio.basename(snaps[#snaps]) == exp_snap_filename
    end, timeout)
end;

-- Wait until snapshots count will be equal to the
-- checkpoint_count option.
function wait_snapshot_gc(timeout)
    snaps = {}
    xlogs = {}
    return test_run:wait_cond(function()
        snaps = fio.glob(fio.pathjoin(box.cfg.memtx_dir, '*.snap'))
        xlogs = fio.glob(fio.pathjoin(box.cfg.wal_dir, '*.xlog'))
        return #snaps == box.cfg.checkpoint_count
    end, timeout)
end;

test_run:cmd("setopt delimiter ''");

box.cfg{checkpoint_interval = PERIOD, checkpoint_count = 2 }

no = 1
row_count_per_wal = box.cfg.wal_max_size / 50
-- first xlog
for i = 1, row_count_per_wal + 10 do space:insert { no } no = no + 1 end
-- second xlog
for i = 1, row_count_per_wal + 10 do space:insert { no } no = no + 1 end

wait_snapshot(WAIT_COND_TIMEOUT)

-- third xlog
for i = 1, row_count_per_wal + 10 do space:insert { no } no = no + 1 end
-- fourth xlog
for i = 1, row_count_per_wal + 10 do space:insert { no } no = no + 1 end

wait_snapshot(WAIT_COND_TIMEOUT)
wait_snapshot_gc(WAIT_COND_TIMEOUT)

#snaps == 2 or snaps
#xlogs > 0

-- gh-2780: check that a last snapshot mtime will be changed at
-- least two times.
test_run:cmd("setopt delimiter ';'")
last_mtime = fio.stat(snaps[#snaps]).mtime;
mtime_changes_cnt = 0;
test_run:wait_cond(function()
    local mtime = fio.stat(snaps[#snaps]).mtime
    if mtime ~= last_mtime then
        mtime_changes_cnt = mtime_changes_cnt + 1
        last_mtime = mtime
    end
    return mtime_changes_cnt == 2
end, WAIT_COND_TIMEOUT);
test_run:cmd("setopt delimiter ''");

-- Check that checkpoint_count can't be < 1.
box.cfg{ checkpoint_count = 1 }
box.cfg{ checkpoint_count = 0 }
box.cfg.checkpoint_count

-- Restore default options.
box.cfg{checkpoint_count = default_checkpoint_count}
box.cfg{checkpoint_interval = default_checkpoint_interval}

space:drop()

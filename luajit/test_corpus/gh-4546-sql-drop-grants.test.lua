test_run = require('test_run').new()
engine = test_run:get_cfg('engine')

--
-- gh-4546: DROP TABLE must delete all privileges given on that
-- table to any user.
--

box.schema.user.create('test_user1')
box.schema.user.create('test_user2')
test_space = box.schema.create_space('T', {		\
	engine = engine,				\
	format = {{'i', 'integer'}}			\
})
box.schema.user.grant('test_user1', 'read', 'space', 'T')
box.schema.user.grant('test_user2', 'write', 'space', 'T')
box.execute([[DROP TABLE T;]])
box.schema.user.drop('test_user1')
box.schema.user.drop('test_user2')

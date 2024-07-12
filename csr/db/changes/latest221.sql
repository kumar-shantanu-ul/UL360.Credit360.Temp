-- Please update version.sql too -- this keeps clean builds in sync
define version=221
@update_header

-- wasn't in actions clean create script, so doing here for DT upgrades in future
grant execute on stragg to actions;

@update_tail
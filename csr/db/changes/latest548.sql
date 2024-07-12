-- Please update version.sql too -- this keeps clean builds in sync
define version=548
@update_header

connect actions/actions@&_CONNECT_IDENTIFIER;
grant select, references on actions.task to csr;
connect csr/csr@&_CONNECT_IDENTIFIER;
@@..\strategy_pkg
@@..\strategy_body

@update_tail

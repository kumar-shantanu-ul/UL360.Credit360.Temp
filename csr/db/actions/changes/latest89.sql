-- Please update version.sql too -- this keeps clean builds in sync
define version=89
@update_header

grant execute on actions.initiative_pkg to csr;

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=757
@update_header

@..\issue_pkg
@..\issue_body


@update_tail

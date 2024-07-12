-- Please update version.sql too -- this keeps clean builds in sync
define version=1636
@update_header

grant select, references on security.application to chain;
grant select, references on security.user_table to chain;

@..\chain\filter_pkg
@..\issue_pkg
@..\chain\filter_body
@..\issue_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2577
@update_header

@..\issue_body
@..\enable_body
@..\enable_pkg
@..\..\..\aspen2\cms\db\tab_body

@update_tail

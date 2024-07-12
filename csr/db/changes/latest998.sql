-- Please update version.sql too -- this keeps clean builds in sync
define version=998
@update_header

delete from cms.col_type where col_type = 25;

@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\tab_body

@update_tail

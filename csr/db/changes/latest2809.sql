-- Please update version.sql too -- this keeps clean builds in sync
define version=2809
define minor_version=0
@update_header

@..\..\..\aspen2\cms\db\filter_body

@update_tail

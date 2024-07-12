-- Please update version.sql too -- this keeps clean builds in sync
define version=1832
@update_header


@..\..\..\aspen2\cms\db\util_pkg
@..\..\..\aspen2\cms\db\util_body

@..\..\..\aspen2\cms\db\tab_body
		
@update_tail
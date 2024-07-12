-- Please update version.sql too -- this keeps clean builds in sync
define version=2554
@update_header
   
@..\..\..\aspen2\db\utils_pkg
@..\..\..\aspen2\db\utils_body

@update_tail

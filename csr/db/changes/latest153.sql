-- Please update version.sql too -- this keeps clean builds in sync
define version=153
@update_header

@..\truncateString
@..\issue_body
	  
@update_tail

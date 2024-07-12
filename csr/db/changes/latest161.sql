-- Please update version.sql too -- this keeps clean builds in sync
define version=161
@update_header

ALTER TABLE section MODIFY visible_version_number NULL;

@..\text\section_body	  
	  
@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=154
@update_header

ALTER TABLE csr_user 
		ADD (
			show_portal_help NUMBER(1) DEFAULT  1 NOT NULL
		);

@..\portlet_pkg
@..\portlet_body
	  
@update_tail

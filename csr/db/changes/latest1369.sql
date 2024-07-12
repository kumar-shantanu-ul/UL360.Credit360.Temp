-- Please update version.sql too -- this keeps clean builds in sync
define version=1369
@update_header

update security.menu set action ='/csr/site/newHelp/editor/editor.acds' where lower(action) = lower('/csr/site/newHelp/editor.acds');
	
@update_tail

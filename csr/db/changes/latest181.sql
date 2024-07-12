-- Please update version.sql too -- this keeps clean builds in sync
define version=181
@update_header

alter table ind rename column help_text to lookup_Key;

update ind set lookup_key=substr(lookup_key,1,64) where length(lookup_key)>64;

alter table ind modify lookup_key varchar2(64);

@..\indicator_pkg
@..\indicator_body
@..\delegation_pkg
@..\delegation_body
@..\schema_pkg
@..\schema_body
	 
@update_tail

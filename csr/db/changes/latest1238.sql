-- Please update version.sql too -- this keeps clean builds in sync
define version=1238
@update_header

GRANT INSERT, SELECT, UPDATE, DELETE ON csrimp.region_description
 TO web_user;
 
GRANT INSERT, SELECT, UPDATE, DELETE ON csrimp.delegation_region_description
 TO web_user;
 
GRANT INSERT, SELECT, UPDATE, DELETE ON csrimp.dataview_region_description
 TO web_user;

@update_tail

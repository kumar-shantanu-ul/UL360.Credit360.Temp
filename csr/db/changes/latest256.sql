-- Please update version.sql too -- this keeps clean builds in sync
define version=256
@update_header

-- note 
-- this column is already on live
-- as I had to fix something when live db_version was = 255
ALTER TABLE tab_group ADD (pos number(10));
@..\portlet_body
    
@update_tail

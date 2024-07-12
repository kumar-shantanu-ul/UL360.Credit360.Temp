-- Please update version.sql too -- this keeps clean builds in sync
define version=2052
@update_header

ALTER TABLE
   csr.section_module
DROP COLUMN
   parent_folder_sid;  

@../section_root_body   
   
@update_tail

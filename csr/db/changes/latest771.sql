-- Please update version.sql too -- this keeps clean builds in sync
define version=771
@update_header

ALTER TABLE csr.custom_location RENAME COLUMN is_google_fail TO is_search_fail;
ALTER TABLE csr.location RENAME COLUMN is_google_fail TO is_search_fail;

@..\logistics_pkg
@..\logistics_body

@update_tail

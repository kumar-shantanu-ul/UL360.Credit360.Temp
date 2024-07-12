-- Please update version.sql too -- this keeps clean builds in sync
define version=2813
define minor_version=0
@update_header

@..\fileupload_pkg
@..\fileupload_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=1495
@update_header

@..\indicator_pkg
@..\indicator_body
@..\val_pkg
@..\val_body
 
@update_tail

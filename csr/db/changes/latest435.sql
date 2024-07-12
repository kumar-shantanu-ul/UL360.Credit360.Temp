-- Please update version.sql too -- this keeps clean builds in sync
define version=435
@update_header

grant update on csr.model to web_user;

@..\model_pkg.sql
@..\model_body.sql

@update_tail

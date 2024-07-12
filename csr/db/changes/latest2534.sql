-- Please update version.sql too -- this keeps clean builds in sync
define version=2534
@update_header

GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.user_setting TO web_user;

@update_tail

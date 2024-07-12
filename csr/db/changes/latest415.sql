-- Please update version.sql too -- this keeps clean builds in sync
define version=415
@update_header

REVOKE ALL ON help_image FROM web_user;
GRANT SELECT, UPDATE ON help_image TO web_user;

@update_tail

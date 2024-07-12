-- Please update version.sql too -- this keeps clean builds in sync
define version=2468
@update_header

@..\..\..\yam\db\webmail_pkg
@..\..\..\yam\db\webmail_body
@..\property_pkg
@..\property_body

@update_tail
-- Please update version.sql too -- this keeps clean builds in sync
define version=1079
@update_header

@..\..\..\security\db\oracle\accountpolicyhelper_pkg
@..\..\..\security\db\oracle\accountpolicyhelper_body

@update_tail

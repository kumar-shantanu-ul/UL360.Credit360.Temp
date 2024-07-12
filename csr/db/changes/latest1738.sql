-- Please update version too -- this keeps clean builds in sync
define version=1738
@update_header

@../chain/type_capability_pkg
@../chain/type_capability_body

@../../../security/db/oracle/user_pkg
@../../../security/db/oracle/user_body

@../chain/uninvited_body

@update_tail
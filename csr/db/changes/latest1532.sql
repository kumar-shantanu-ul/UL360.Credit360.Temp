-- Please update version.sql too -- this keeps clean builds in sync
define version=1532
@update_header

@../chain/company_body
@../chain/company_user_pkg
@../chain/company_user_body

@update_tail
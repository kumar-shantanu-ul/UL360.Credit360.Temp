-- Please update version.sql too -- this keeps clean builds in sync
define version=3151
define minor_version=0
@update_header

-- Package body is run in latest3150.sql. Keep empty script to maintain version numbers
-- @../chain/company_filter_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2166
@update_header

-- *** Packages ***
@..\indicator_pkg
@..\indicator_body
@..\calc_body

@update_tail
-- Please update version.sql too -- this keeps clean builds in sync
define version=2165
@update_header

-- *** Packages ***
@..\measure_pkg
@..\measure_body

@update_tail
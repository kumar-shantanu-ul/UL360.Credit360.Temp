-- Please update version.sql too -- this keeps clean builds in sync
define version=55
@update_header

ALTER TABLE donations.scheme ADD helper_pkg VARCHAR2(255);


--@../helpers/build

-- new exception type
@../scheme_pkg
@../scheme_body

@update_tail

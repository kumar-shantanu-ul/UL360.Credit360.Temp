-- Please update version.sql too -- this keeps clean builds in sync
define version=326
@update_header

PROMPT Enter connection string (e.g. ASPEN)
connect postcode/postcode@&&1

grant select, references on city_full to csr;

connect csr/csr@&&1

@..\region_pkg
@..\region_body

@update_tail
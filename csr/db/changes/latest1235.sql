-- Please update version.sql too -- this keeps clean builds in sync
define version=1235
@update_header

INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (10, 'Lower level properties');

@update_tail

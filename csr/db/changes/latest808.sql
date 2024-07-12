-- Please update version.sql too -- this keeps clean builds in sync
define version=808
@update_header

INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (7, 'Immediate children');

@update_tail
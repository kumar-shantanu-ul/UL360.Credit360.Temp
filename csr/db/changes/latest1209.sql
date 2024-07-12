-- Please update version.sql too -- this keeps clean builds in sync
define version=1209
@update_header

CREATE UNIQUE INDEX CT.IDX_SUPPLIER_1 ON CT.SUPPLIER (APP_SID,CASE WHEN COMPANY_SID IS NULL THEN 'S'||SUPPLIER_ID ELSE 'C'||COMPANY_SID END);

GRANT SELECT, REFERENCES ON CHAIN.INVITATION TO CT;
GRANT SELECT, REFERENCES ON CHAIN.SUPPLIER_RELATIONSHIP TO CT;

@..\ct\ct_pkg
@..\ct\link_pkg
@..\ct\supplier_pkg
@..\ct\supplier_body
@..\ct\link_body
@..\ct\breakdown_body

@update_tail

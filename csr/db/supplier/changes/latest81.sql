-- Please update version.sql too -- this keeps clean builds in sync
define version=81
@update_header

-- this name is confusing
alter table supplier.product_questionnaire_link rename to all_product_questionnaire;

CREATE OR REPLACE VIEW SUPPLIER.PRODUCT_QUESTIONNAIRE
(PRODUCT_ID, QUESTIONNAIRE_ID, QUESTIONNAIRE_STATUS_ID, DUE_DATE) AS
SELECT PR.PRODUCT_ID, PR.QUESTIONNAIRE_ID, PR.QUESTIONNAIRE_STATUS_ID, PR.DUE_DATE
FROM ALL_PRODUCT_QUESTIONNAIRE PR
WHERE USED = 1
;

@../product_body.sql
@../product_pkg.sql
@../questionnaire_body.sql
@../questionnaire_pkg.sql

@update_tail
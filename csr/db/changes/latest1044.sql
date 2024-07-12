-- Please update version.sql too -- this keeps clean builds in sync
define version=1044
@update_header

DROP INDEX CHAIN.UK_BU_IS_PRIMARY;
CREATE UNIQUE INDEX CHAIN.UK_BU_IS_PRIMARY ON CHAIN.BUSINESS_UNIT_MEMBER(APP_SID, USER_SID, NVL(IS_PRIMARY_BU, BUSINESS_UNIT_ID))
;

DROP INDEX CHAIN.UK_BU_SUP_IS_PRIMARY;
CREATE UNIQUE INDEX CHAIN.UK_BU_SUP_IS_PRIMARY ON CHAIN.BUSINESS_UNIT_SUPPLIER(APP_SID, SUPPLIER_COMPANY_SID, NVL(IS_PRIMARY_BU, BUSINESS_UNIT_ID))
;

UPDATE chain.card
   SET description='Confirmation page for inviting a new supplier that includes check to prevent duplicates'
 WHERE js_class_type='Chain.Cards.InvitationSummaryWithCheck';

@..\chain\company_pkg
@..\chain\company_user_pkg

@..\chain\company_body
@..\chain\company_user_body
@..\chain\company_filter_body
@..\chain\helper_body
@..\chain\setup_body
@..\csr_data_body
@..\csr_user_body
@..\region_body
@..\supplier_body

@update_tail

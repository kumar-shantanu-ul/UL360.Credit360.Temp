-- Please update version.sql too -- this keeps clean builds in sync
define version=1448
@update_header

ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD (LANDING_URL VARCHAR2(1000));

UPDATE CSR.USER_SETTING
   SET SETTING = 'ccMe'
 WHERE CATEGORY IN ('CHAIN QUESTIONNAIRE INVITATION', 'CLIENTS.MAERSK.CARDS.SUPPLIERDATA')
   AND SETTING = 'alwaysCcMe';

@..\chain\helper_body

@update_tail

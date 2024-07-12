-- Please update version.sql too -- this keeps clean builds in sync
define version=925
@update_header

@..\chain\helper_pkg
@..\chain\helper_body

@..\portlet_pkg
@..\portlet_body

DROP TABLE CHAIN.TMP_USER_SETTING_MAP;
DROP VIEW csr.V$USER_SETTING;
DROP VIEW csr.V$USER_PORTLET_SETTING; 
DROP PACKAGE CSR.JSON;
DROP TABLE CSR.TAB_PORTLET_USER_STATE;
DROP TABLE CHAIN.USER_SETTING;

@update_tail

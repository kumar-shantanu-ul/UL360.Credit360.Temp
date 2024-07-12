-- Please update version.sql too -- this keeps clean builds in sync
define version=58
@update_header


UPDATE csr.alert_type 
SET params_xml = '<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="USER_NAME"/><param name="PRODUCT_DESC"/><param name="PRODUCT_CODE"/><param name="PRODUCT_ASSIGNMENT_DATA"/></params>' 
WHERE alert_type_id=1000;

UPDATE csr.alert_type 
SET params_xml = '<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="USER_NAME"/><param name="PRODUCT_DESC"/><param name="PRODUCT_CODE"/><param name="ACTIVATION_TYPE"/><param name="PRODUCT_ASSIGNMENT_DATA"/></params>' 
WHERE alert_type_id=1001;

UPDATE csr.alert_type 
SET params_xml = '<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="USER_NAME"/><param name="PRODUCT_DESC"/><param name="PRODUCT_CODE"/><param name="GROUP_STATUS"/><param name="COMMENT"/></params>'
WHERE alert_type_id=1002;

@update_tail

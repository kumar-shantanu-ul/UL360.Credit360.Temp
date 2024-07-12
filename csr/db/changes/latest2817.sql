-- Please update version.sql too -- this keeps clean builds in sync
define version=2817
define minor_version=0
@update_header

ALTER TABLE csrimp.alert_template
 DROP CONSTRAINT CK_ALERT_TEMPLATE_SEND_TYPE;

ALTER TABLE csrimp.alert_template
  ADD CONSTRAINT CK_ALERT_TEMPLATE_SEND_TYPE
	  CHECK (SEND_TYPE IN ('manual', 'automatic', 'inactive'));

@update_tail

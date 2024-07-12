-- Please update version.sql too -- this keeps clean builds in sync
define version=595
@update_header

-- in the model but missing from live
alter table REPORTING_PERIOD modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table REGION_TREE modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table REGION modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table APPROVAL_STEP_TEMPLATE modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table CUSTOMER_HELP_LANG modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table CUSTOMER_ALERT_TYPE modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table AUTOCREATE_USER modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table AUDIT_LOG modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table FEED modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table FACTOR_HISTORY modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table ACCURACY_TYPE modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table ROLE modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table TEMPLATE modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table MEASURE modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table DEFAULT_RSS_FEED modify app_sid default SYS_CONTEXT('SECURITY','APP');
alter table IND modify app_sid default SYS_CONTEXT('SECURITY','APP');

@update_tail

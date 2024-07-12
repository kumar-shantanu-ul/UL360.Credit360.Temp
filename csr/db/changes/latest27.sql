-- Please update version.sql too -- this keeps clean builds in sync
define version=27
@update_header

alter table alert_template add (active number(1,0) default 1 not null);
/


delete from alert_type where alert_type_id in (3,4);
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP ) VALUES ( 3, 'Delegation data overdue', 'alert_pkg.GetAlerts_DelegDataOverdue'); 
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP ) VALUES ( 4, 'Delegation state changed', 'alert_pkg.GetAlerts_DelegStateChange'); 
commit;

@update_tail

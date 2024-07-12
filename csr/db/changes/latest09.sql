-- Please update version.sql too -- this keeps clean builds in sync
define version=09
@update_header

alter table alert add (error varchar2(1024));

INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP ) VALUES ( 2, 'New delegation', 'alert_pkg.GetAlerts_NewDelegation'); 



@update_tail

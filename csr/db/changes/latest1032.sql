-- Please update version.sql too -- this keeps clean builds in sync
define version=1032
@update_header

delete from csr.delegation_change_alert 
where delegation_change_alert_id NOT IN (
	select max(delegation_change_alert_id) from csr.delegation_change_alert group by sheet_id having count(*) > 1
	union
	select max(delegation_change_alert_id) from csr.delegation_change_alert group by sheet_id having count(*) = 1
);

ALTER TABLE CSR.DELEGATION_CHANGE_ALERT
ADD CONSTRAINT UK_DELEGATION_CHANGE_ALERT UNIQUE 
(
  SHEET_ID
)
ENABLE;

@../sheet_body

@update_tail
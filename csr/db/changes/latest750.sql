-- Please update version.sql too -- this keeps clean builds in sync
define version=750
@update_header

ALTER TABLE csr.FLOW_STATE_TRANSITION ADD (
	HELPER_SP	VARCHAR2(255)
);

INSERT INTO csr.PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Meter list', 'Credit360.Portlets.MeterList', '/csr/site/portal/Portlets/MeterList.js');

@..\flow_pkg
@..\approval_dashboard_pkg

@..\flow_body
@..\approval_dashboard_body
@..\portlet_body

@update_tail

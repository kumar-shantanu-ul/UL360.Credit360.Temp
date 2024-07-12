-- Please update version.sql too -- this keeps clean builds in sync
define version=2246
@update_header

ALTER TABLE CSR.INTERNAL_AUDIT ADD (
	AUDITOR_COMPANY_SID NUMBER(10),
	CONSTRAINT FK_INTERNAL_AUDIT_AUDITOR_SUP FOREIGN KEY (APP_SID, AUDITOR_COMPANY_SID) REFERENCES CSR.SUPPLIER (APP_SID, COMPANY_SID)
);

INSERT INTO csr.flow_involvement_type (flow_involvement_type_id, flow_alert_class, label, css_class)
	VALUES (2, 'audit', 'Auditor company', 'CSRUsers');

UPDATE csr.internal_audit ia
   SET (auditor_company_sid) = (
	SELECT auditor_company_sid
	  FROM chain.audit_request ar
	 WHERE ar.audit_sid = ia.internal_audit_sid
	)
 WHERE ia.internal_audit_sid IN (
	SELECT audit_sid
	  FROM chain.audit_request
	);

@../audit_pkg

@../audit_body
@../flow_body
@../chain/audit_request_body
@../chain/supplier_audit_body

@update_tail

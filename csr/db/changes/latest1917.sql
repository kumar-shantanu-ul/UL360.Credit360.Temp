-- Please update version.sql too -- this keeps clean builds in sync
define version=1917
@update_header

BEGIN
	/* Add Supply Chain Company filter picker */
	INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, DEFAULT_STATE, SCRIPT_PATH) 
		VALUES (1039, 'Supply Chain Company filter picker', 'Credit360.Portlets.Chain.CompanyFilterPicker', EMPTY_CLOB(), '/csr/site/portal/portlets/chain/CompanyFilterPicker.js');

END;
/

@../audit_pkg

@../audit_body
@../chain/supplier_audit_body

@update_tail
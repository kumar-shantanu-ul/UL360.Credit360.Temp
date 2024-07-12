define version=137
@update_header

	INSERT INTO csr.portlet (portlet_id, name, type, script_path) VALUES (csr.portlet_id_seq.nextval, 'Supply Chain Product Work Summary', 'Credit360.Portlets.Chain.ProductWorkSummary', '/csr/site/portal/Portlets/Chain/ProductWorkSummary.js');
	
@update_tail
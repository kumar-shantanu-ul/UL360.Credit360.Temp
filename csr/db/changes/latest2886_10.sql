-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- wtf, this is a client script
begin
	for r in (select 1 from all_users where username='OWL') loop
		execute immediate 'GRANT SELECT, INSERT ON owl.owl_client TO csr';
		execute immediate 'GRANT SELECT, INSERT ON owl.client_module TO csr';
		execute immediate 'GRANT SELECT ON owl.handling_office TO csr';
		execute immediate 'GRANT SELECT, INSERT ON owl.credit_module TO csr';
	end loop;
end;
/

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_module_id NUMBER(2);
BEGIN	
	v_module_id := 61;
	INSERT INTO CSR.MODULE (module_id, module_name, enable_sp, description)
		VALUES (v_module_id, 'Enable Client Connect', 'EnableClientConnect', 'Enable Client Connect');	 
	--Add the params
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (v_module_id, 'in_admin_access', 0, 'Admin Access (default=y)');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (v_module_id, 'in_handling_office', 1, 'Handling Office (eg=Cambridge)');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (v_module_id, 'in_customer_name', 2, 'Customer Name');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (v_module_id, 'in_parent_host', 3, 'Parent Host (www.credit360.com)');

	v_module_id := 62;
	INSERT INTO CSR.MODULE (module_id, module_name, enable_sp, description)
		VALUES (v_module_id, 'Enable Fogbugz', 'EnableFogbugz', 'Enable Support Cases for Client Connect');	 
	--Add the params
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (v_module_id, 'in_customer_fogbugz_project_id', 0, 'Old id for pulling historical cases, or 0 if none');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (v_module_id, 'in_customer_fogbugz_area', 1, 'Text of the new area to search for in XLog projects');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_pkg
@..\enable_body

@update_tail

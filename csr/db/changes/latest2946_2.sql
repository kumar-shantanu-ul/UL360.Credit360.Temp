-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- C:\cvs\csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW chain.v$qnr_security_scheme_summary
AS
	SELECT NVL(p.security_scheme_id, s.security_scheme_id) security_scheme_id, 
       NVL(p.action_security_type_id, s.action_security_type_id) action_security_type_id,
       CASE WHEN p.company_function_id > 0 THEN 1 ELSE 0 END has_procurer_config, 
       CASE WHEN s.company_function_id > 0 THEN 1 ELSE 0 END has_supplier_config
	  FROM (
			  SELECT security_scheme_id, action_security_type_id, company_function_id
				FROM qnr_security_scheme_config
			   WHERE company_function_id = 1
			   GROUP BY security_scheme_id, action_security_type_id, company_function_id
		   ) p
	 FULL JOIN (           
			  SELECT security_scheme_id, action_security_type_id, company_function_id
				FROM qnr_security_scheme_config
			   WHERE company_function_id = 2
			   GROUP BY security_scheme_id, action_security_type_id, company_function_id
		   ) s
	   ON p.security_scheme_id = s.security_scheme_id AND p.action_security_type_id = s.action_security_type_id;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\csr_data_body
@..\csr_user_body
@..\initiative_body
@..\section_body
@..\util_script_body

@..\actions\task_body
@..\donations\donation_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3186
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_company_cap_id			NUMBER;
	v_suppliers_cap_id			NUMBER;
	v_company_scores_pri_cap_id	NUMBER;
	v_company_scores_sec_cap_id	NUMBER;
BEGIN
	security.user_pkg.logonadmin;

	-- Only these capabilities actually use anything other than Read and Write, and they only additional use Delete:
	
	SELECT capability_id INTO v_company_cap_id				FROM chain.capability WHERE capability_name = 'Company';
	SELECT capability_id INTO v_suppliers_cap_id			FROM chain.capability WHERE capability_name = 'Suppliers';
	SELECT capability_id INTO v_company_scores_pri_cap_id	FROM chain.capability WHERE capability_name = 'Company scores' AND is_supplier = 0;
	SELECT capability_id INTO v_company_scores_pri_cap_id	FROM chain.capability WHERE capability_name = 'Company scores' AND is_supplier = 1;

	UPDATE chain.company_type_capability
	   SET permission_set = CASE
				WHEN capability_id IN (v_company_cap_id, v_suppliers_cap_id, v_company_scores_pri_cap_id, v_company_scores_pri_cap_id) THEN BITAND(permission_set, 7)
				ELSE BITAND(permission_set, 3)
		   END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

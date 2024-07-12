-- Please update version.sql too -- this keeps clean builds in sync
define version=3030
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_company_score_cap_id	NUMBER;
	v_supplier_score_cap_id	NUMBER;
	v_company_cap_id		NUMBER;
	v_supplier_cap_id		NUMBER;
BEGIN
	-- Log out of any apps from other scripts
	security.user_pkg.LogonAdmin;

	-- Change to specific capability and rename
	UPDATE chain.capability
	   SET capability_name = 'Company scores',
		   perm_type = 0
	 WHERE capability_name = 'Set company scores';
	
	SELECT capability_id INTO v_company_score_cap_id  FROM chain.capability WHERE is_supplier = 0 AND capability_name = 'Company scores';
	SELECT capability_id INTO v_supplier_score_cap_id FROM chain.capability WHERE is_supplier = 1 AND capability_name = 'Company scores';
	SELECT capability_id INTO v_company_cap_id		  FROM chain.capability WHERE is_supplier = 0 AND capability_name = 'Company';
	SELECT capability_id INTO v_supplier_cap_id		  FROM chain.capability WHERE is_supplier = 1 AND capability_name = 'Suppliers';

	-- We already have write capability from previous type, add read capbability from company
	-- There are some instances where user has write on score but not read on company
	UPDATE chain.company_type_capability cs
	   SET cs.permission_set = cs.permission_set + NVL((
		SELECT BITAND(permission_set, 1)
		  FROM chain.company_type_capability c
		 WHERE c.app_sid = cs.app_sid
		   AND c.primary_company_type_id = cs.primary_company_type_id
		   AND NVL(c.secondary_company_type_id, -1) = NVL(cs.secondary_company_type_id, -1)
		   AND NVL(c.primary_company_group_type_id, -1) = NVL(cs.primary_company_group_type_id, -1)
		   AND NVL(c.primary_company_type_role_sid, -1) = NVL(cs.primary_company_type_role_sid, -1)
		   AND c.capability_id IN (v_company_cap_id, v_supplier_cap_id)
		), 0)
	 WHERE cs.capability_id IN (v_company_score_cap_id, v_supplier_score_cap_id)
	   AND cs.permission_set IN (0, 2); -- check we haven't applied read permission before so script is rerunnable
	
	-- Where we have no capability already (i.e. no row in company_type_capability), we still want read access
	INSERT INTO chain.company_type_capability (app_sid, primary_company_type_id, secondary_company_type_id,
		   primary_company_group_type_id, primary_company_type_role_sid, capability_id, permission_set)
	SELECT app_sid, primary_company_type_id, secondary_company_type_id,
		   primary_company_group_type_id, primary_company_type_role_sid, 
		   DECODE(capability_id, v_company_cap_id, v_company_score_cap_id, v_supplier_cap_id, v_supplier_score_cap_id), 1
	  FROM chain.company_type_capability cs
	 WHERE BITAND(permission_set, 1) = 1
	   AND capability_id IN (v_company_cap_id, v_supplier_cap_id)
	   AND NOT EXISTS (
		SELECT *
		  FROM chain.company_type_capability c
		 WHERE c.app_sid = cs.app_sid
		   AND c.primary_company_type_id = cs.primary_company_type_id
		   AND NVL(c.secondary_company_type_id, -1) = NVL(cs.secondary_company_type_id, -1)
		   AND NVL(c.primary_company_group_type_id, -1) = NVL(cs.primary_company_group_type_id, -1)
		   AND NVL(c.primary_company_type_role_sid, -1) = NVL(cs.primary_company_type_role_sid, -1)
		   AND c.capability_id IN (v_company_score_cap_id, v_supplier_score_cap_id)
		);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***
DROP PACKAGE chain.report_pkg;

-- *** Packages ***
@..\chain\chain_pkg

@..\chain\company_body
@..\chain\company_filter_body
@..\chain\dashboard_body
@..\supplier_body


@update_tail

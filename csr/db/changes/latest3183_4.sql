-- Please update version.sql too -- this keeps clean builds in sync
define version=3183
define minor_version=4
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
	v_capability_name		VARCHAR2(100) := 'View supplier company reference fields';
	v_primary_cap_id		NUMBER;
	v_secondary_cap_id		NUMBER;
	v_company_cap_id		NUMBER;
	v_suppliers_cap_id		NUMBER;
BEGIN
	security.user_pkg.LogonAdmin;
	
	SELECT capability_id
	  INTO v_primary_cap_id
	  FROM chain.capability
	 WHERE capability_name = v_capability_name
	   AND capability_type_id = 1;
	
	SELECT capability_id
	  INTO v_secondary_cap_id
	  FROM chain.capability
	 WHERE capability_name = v_capability_name
	   AND capability_type_id = 2;

	SELECT capability_id
	  INTO v_company_cap_id
	  FROM chain.capability
	 WHERE capability_name = 'Company';
	
	SELECT capability_id
	  INTO v_suppliers_cap_id
	  FROM chain.capability
	 WHERE capability_name = 'Suppliers';

	DELETE FROM chain.company_type_capability
	 WHERE capability_id IN (v_primary_cap_id, v_secondary_cap_id);

	-- capability_flow_capability and card_group_card have no rows
	-- on live pointing to these capabilities, but I had some locally.
	-- CFC is easy to deal with; CGC has a bunch of child rows so I try
	-- migrating them to the company/supplier capability instead.

	DELETE FROM chain.capability_flow_capability
	 WHERE capability_id IN (
			SELECT capability_id
			  FROM chain.capability
			 WHERE capability_name = v_capability_name
	 );

	UPDATE chain.card_group_card
	   SET required_capability_id = v_company_cap_id,
		   required_permission_set = CASE required_permission_set WHEN 2 THEN 1 ELSE required_permission_set END
	 WHERE required_capability_id = v_primary_cap_id;

	UPDATE chain.card_group_card
	   SET required_capability_id = v_suppliers_cap_id,
		   required_permission_set = CASE required_permission_set WHEN 2 THEN 1 ELSE required_permission_set END
	 WHERE required_capability_id = v_secondary_cap_id;

	-- chain.group_capability.capability_id points to capability, but no rows 
	-- on live point to these capabilities, and I _think_ they're basedata
	-- so it should be OK to leave it alone.
	
	DELETE FROM chain.capability
	 WHERE capability_id IN (v_primary_cap_id, v_secondary_cap_id);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg

@../chain/chain_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2941
define minor_version=15
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
BEGIN
	-- Logoin as admin (no site)
	security.user_pkg.logonadmin;

	-- Properties
	FOR r IN (
		SELECT sid_id, description, context
		  FROM security.menu
		 -- Catches everything
		 WHERE LOWER(action) LIKE '/csr/site/property/properties/myproperties.acds%'
		    OR LOWER(action) LIKE '%/site/properties/myproperties.acds%'
	) LOOP
		-- Users will already have access to the /csr/site/property/properties
		-- web resource as other required components are already located there.
		-- The list page doesn't specify a "SelectedMenu" property but the system 
		-- appears to pick-up the correct menu context, so no need to rename the 
		-- menu item securable object node.
		security.menu_pkg.SetMenu(
			security.security_pkg.GetACT,
			r.sid_id,
			r.description,
			'/csr/site/property/properties/list.acds',
			NULL,
			r.context
		);
	END LOOP;

	-- Initiatives
	FOR r IN (
		SELECT sid_id, description, context
		  FROM security.menu
		 -- Avoids teamroom (M and S)
		 WHERE LOWER(action) LIKE '%/site/initiatives2/myinitiatives.acds%'
		    OR LOWER(action) LIKE '%/site/initiatives/myinitiatives.acds%'
	) LOOP
		-- Users will already have access to the /csr/site/initiatives
		-- web resource as other required components are already located there.
		-- The list page doesn't specify a "SelectedMenu" property but the system 
		-- appears to pick-up the correct menu context, so no need to rename the 
		-- menu item securable object node.
		security.menu_pkg.SetMenu(
			security.security_pkg.GetACT,
			r.sid_id,
			r.description,
			'/csr/site/initiatives/list.acds',
			NULL,
			r.context
		);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

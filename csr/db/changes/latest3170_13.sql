-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=13
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
-- Set EU & UK/NAT to out of scope, can be completely removed by utility script later.
UPDATE csr.compliance_item_region reg
   SET out_of_scope = 1
 WHERE EXISTS (
		SELECT 1
		  FROM csr.compliance_item_rollout cirt 
		  JOIN csr.compliance_item ci on cirt.compliance_item_id = ci.compliance_item_id
		 WHERE (cirt.country_group = 'eu' or (cirt.country = 'gb' and cirt.region_group is null)) and ci.source = 1 AND reg.compliance_item_id = cirt.compliance_item_id);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3254
define minor_version=2
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
BEGIN
	UPDATE csr.customer_flow_capability
	   SET is_system_managed = 1
	 WHERE flow_capability_id in (
		  SELECT csr_cfc.flow_capability_id
			FROM csr.customer_flow_capability csr_cfc
			JOIN chain.capability_flow_capability ch_cfc ON ch_cfc.flow_capability_id = csr_cfc.flow_capability_id
			JOIN chain.capability cap ON cap.capability_id = ch_cfc.capability_id
		   WHERE ( cap.capability_name IN ('Company', 'Suppliers'))
		   GROUP BY csr_cfc.flow_capability_id);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

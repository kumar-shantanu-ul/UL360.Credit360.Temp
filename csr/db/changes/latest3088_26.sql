-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.CUSTOMER_FLOW_CAPABILITY 
  ADD (IS_SYSTEM_MANAGED NUMBER(1) DEFAULT 0 NOT NULL);

ALTER TABLE CSR.CUSTOMER_FLOW_CAPABILITY
  ADD CONSTRAINT CK_CUST_FLOW_CAP_IS_SYS_MNGD CHECK (IS_SYSTEM_MANAGED IN (0, 1)) ENABLE;

ALTER TABLE CSRIMP.CUSTOMER_FLOW_CAPABILITY 
  ADD (IS_SYSTEM_MANAGED NUMBER(1) NOT NULL);

ALTER TABLE CSRIMP.CUSTOMER_FLOW_CAPABILITY
  ADD CONSTRAINT CK_CUST_FLOW_CAP_IS_SYS_MNGD CHECK (IS_SYSTEM_MANAGED IN (0, 1)) ENABLE;


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

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
@../flow_pkg
@../flow_body
@../schema_body
@../chain/type_capability_body
@../csrimp/imp_body

@update_tail
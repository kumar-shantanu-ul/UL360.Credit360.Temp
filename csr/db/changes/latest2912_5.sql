-- Please update version.sql too -- this keeps clean builds in sync
define version=2912
define minor_version=5
@update_header


-- *** DDL ***
-- Create tables

-- Alter tables
-- Missed from schema, so installed systems won't have this!
DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	 INTO v_count
	 FROM all_constraints
	WHERE constraint_name = 'FK_EST_CUST_GLOBAL_APP'
	AND owner='CSR';

	IF v_count != 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.est_customer DROP CONSTRAINT FK_EST_CUST_GLOBAL_APP';
	END IF;
END;
/

ALTER TABLE csr.est_options
DROP CONSTRAINT FK_EST_CUSTOMER_OPTIONS;

ALTER TABLE csr.est_customer ADD (
	ORG_NAME	VARCHAR2(256),
	EMAIL		VARCHAR2(256)
);

BEGIN
	security.user_pkg.LogonAdmin;
	MERGE INTO csr.est_customer ec
	USING 
	(
		SELECT pm_customer_id,
			   org_name,
			   email
		  FROM csr.est_customer_global
	) ecg ON (ecg.pm_customer_id = ec.pm_customer_id)
	WHEN MATCHED THEN UPDATE 
	 SET ec.org_name = ecg.org_name, 
		 ec.email = ecg.email;
END;
/
 
ALTER TABLE csr.est_customer MODIFY (
	ORG_NAME NOT NULL
); 

DROP VIEW csr.v$est_customer;
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

DELETE FROM csr.est_customer_global WHERE pm_customer_id IN (
	SELECT pm_customer_id FROM csr.est_customer);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../energy_star_pkg
@../energy_star_body
@../property_body

@update_tail

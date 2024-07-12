-- Please update version.sql too -- this keeps clean builds in sync
define version=3428
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.est_account_global RENAME column password TO password_old;

-- Doesn't exist on prod, but might on new laptops.
DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	 INTO v_count
	 FROM all_constraints
	WHERE constraint_name = 'FK_EST_CUST_GLOBAL'
	AND owner='CSR';

	IF v_count != 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.est_customer DROP CONSTRAINT FK_EST_CUST_GLOBAL';
	END IF;
END;
/


-- *** Grants ***
-- Not required on prod db's, but might be required for new laptops.
grant execute on csr.energy_star_customer_pkg to security;
grant execute on csr.energy_star_customer_pkg to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW csr.v$est_account AS
	SELECT a.app_sid, a.est_account_sid, a.est_account_id, a.account_customer_id,
		g.user_name, g.base_url,
		g.connect_job_interval, g.last_connect_job_dtm,
		a.share_job_interval, a.last_share_job_dtm,
		a.building_job_interval, a.meter_job_interval,
		a.auto_map_customer, a.allow_delete
	 FROM csr.est_account a
	 JOIN csr.est_account_global g ON a.est_account_id = g.est_account_id
;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../energy_star_pkg

@../enable_body
@../energy_star_body

@update_tail

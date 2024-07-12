-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.EST_OPTIONS ADD (
	TRASH_WHEN_SHARING		NUMBER(1)	DEFAULT 0 NOT NULL,
	TRASH_WHEN_POLLING		NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT CK_TRASH_WHEN_SHARING CHECK (TRASH_WHEN_SHARING IN (0, 1)),
	CONSTRAINT CK_TRASH_WHEN_POLLING CHECK (TRASH_WHEN_POLLING IN (0, 1))
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$est_account AS
	SELECT a.app_sid, a.est_account_sid, a.est_account_id, a.account_customer_id,
		g.user_name, g.password, g.base_url,
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
BEGIN
	FOR r IN (
		SELECT o.app_sid, a.strict_building_poll
		  FROM csr.est_options o
		  JOIN csr.est_account a ON a.est_account_sid = o.default_account_sid
	) LOOP
		UPDATE csr.est_options
		   SET trash_when_polling = r.strict_building_poll
		 WHERE app_sid = r.app_sid;
	END LOOP;
END;
/

-- This table Needs to be amended after data changes
ALTER TABLE CSR.EST_ACCOUNT DROP COLUMN STRICT_BUILDING_POLL;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../energy_star_pkg

@../energy_star_body
@../enable_body

@update_tail

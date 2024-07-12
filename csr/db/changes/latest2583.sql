-- Please update version.sql too -- this keeps clean builds in sync
define version=2583
@update_header

ALTER TABLE CSR.EST_ACCOUNT ADD (
	STRICT_BUILDING_POLL		NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CHECK (STRICT_BUILDING_POLL IN (0,1))
);

CREATE OR REPLACE VIEW csr.v$est_account AS
	SELECT a.app_sid, a.est_account_sid, a.est_account_id, a.account_customer_id,
		g.user_name, g.password, g.base_url,
		g.connect_job_interval, g.last_connect_job_dtm,
		a.share_job_interval, a.last_share_job_dtm,
		a.building_job_interval, a.meter_job_interval,
		a.auto_map_customer, a.allow_delete, a.strict_building_poll
	 FROM csr.est_account a
	 JOIN csr.est_account_global g ON a.est_account_id = g.est_account_id
;

@../energy_star_body

@update_tail

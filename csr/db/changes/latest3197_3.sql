-- Please update version.sql too -- this keeps clean builds in sync
define version=3197
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE chain.geotag_batch_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

-- no csrimp needed for these tables as they are linked to batch job instances
CREATE TABLE chain.geotag_batch(
	app_sid 			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	geotag_batch_id		NUMBER(10, 0) NOT NULL,
	batch_job_id		NUMBER(10, 0) NOT NULL,
	source				NUMBER(1) NOT NULL,
	CONSTRAINT pk_geotag_batch PRIMARY KEY (app_sid, geotag_batch_id),
	CONSTRAINT fk_geotag_batch_job FOREIGN KEY (app_sid, batch_job_id) REFERENCES csr.batch_job (app_sid, batch_job_id),
	-- cross schema constraint
	CONSTRAINT chk_geotag_batch_trigger CHECK (source IN (0,1,2,3))
);

CREATE TABLE chain.geotag_batch_company_queue(
	app_sid 			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	geotag_batch_id		NUMBER(10, 0) NOT NULL,
	company_sid			NUMBER(10, 0) NOT NULL,
	processed_dtm		DATE,
	longitude			NUMBER,
	latitude			NUMBER,
	CONSTRAINT pk_geotag_batch_company_queue PRIMARY KEY (app_sid, geotag_batch_id, company_sid),
	CONSTRAINT fk_geotag_batch_company FOREIGN KEY (app_sid, company_sid) REFERENCES chain.company (app_sid, company_sid),
	CONSTRAINT fk_geotag_batch FOREIGN KEY (app_sid, geotag_batch_id) REFERENCES chain.geotag_batch (app_sid, geotag_batch_id)
);
-- indices
CREATE INDEX chain.ix_geotag_batch_batch_job_id ON chain.geotag_batch (app_sid, batch_job_id);
CREATE INDEX chain.ix_geotag_batch_queue_comp ON chain.geotag_batch_company_queue (app_sid, company_sid);
CREATE INDEX chain.ix_geotag_batch_queue_batch ON chain.geotag_batch_company_queue (app_sid, geotag_batch_id);
-- Alter tables

ALTER TABLE chain.customer_options ADD company_geotag_enabled NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE chain.customer_options ADD CONSTRAINT chk_company_geotag_enabled CHECK (company_geotag_enabled IN (1,0));

ALTER TABLE csrimp.chain_customer_options ADD company_geotag_enabled NUMBER(1,0) NOT NULL;


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/helper_pkg
@../chain/company_pkg

@../util_script_body
@../schema_body
@../chain/helper_body
@../chain/company_body
@../csrimp/imp_body

@update_tail

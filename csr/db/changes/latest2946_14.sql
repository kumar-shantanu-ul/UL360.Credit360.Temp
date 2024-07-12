-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.aggregation_period(
	app_sid					NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	aggregation_period_id	NUMBER(10)		NOT NULL,
	label					VARCHAR2(100) 	NOT NULL,
	no_of_months			NUMBER(2)		NOT NULL,
	CONSTRAINT PK_AGGREGATION_PERIOD PRIMARY KEY (app_sid, aggregation_period_id)
);

CREATE TABLE csrimp.aggregation_period (
	csrimp_session_id		NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	aggregation_period_id	NUMBER(10)		NOT NULL,
	label					VARCHAR2(100) 	NOT NULL,
	no_of_months			NUMBER(2)		NOT NULL,
	CONSTRAINT pk_aggregation_period PRIMARY KEY (csrimp_session_id, aggregation_period_id)
);

-- Alter tables
ALTER TABLE csr.customer
  ADD show_aggregate_override NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.dataview
  ADD aggregation_period_id NUMBER(10);

ALTER TABLE csr.dataview_history
  ADD aggregation_period_id NUMBER(10);

ALTER TABLE csrimp.customer
  ADD show_aggregate_override NUMBER(1) NOT NULL;

ALTER TABLE csrimp.dataview
  ADD aggregation_period_id NUMBER(10);

ALTER TABLE csrimp.dataview_history
  ADD aggregation_period_id NUMBER(10);
  
ALTER TABLE csr.aggregation_period
  ADD CONSTRAINT fk_aggregation_period_customer FOREIGN KEY (app_sid) REFERENCES csr.customer (app_sid);

ALTER TABLE csrimp.aggregation_period
  ADD CONSTRAINT fk_aggregation_period_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
  
ALTER TABLE csr.dataview
  ADD CONSTRAINT fk_dataview_aggregation_period FOREIGN KEY (app_sid, aggregation_period_id) REFERENCES csr.aggregation_period (app_sid, aggregation_period_id);

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON csr.aggregation_period TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.aggregation_period TO web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\csr_app_body
@..\customer_pkg
@..\customer_body
@..\dataview_pkg
@..\dataview_body
@..\schema_pkg
@..\schema_body
@..\csrimp\imp_body

@update_tail

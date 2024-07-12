-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=33
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.flow_inv_type_alert_class (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	flow_involvement_type_id		NUMBER(10) NOT NULL,
	flow_alert_class				VARCHAR2(256) NOT NULL,
	CONSTRAINT pk_flow_inv_type_alert_class PRIMARY KEY (app_sid, flow_involvement_type_id, flow_alert_class)
);

CREATE TABLE csrimp.flow_inv_type_alert_class (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	flow_involvement_type_id		NUMBER(10) NOT NULL,
	flow_alert_class				VARCHAR2(256) NOT NULL,
	CONSTRAINT pk_flow_inv_type_alert_class PRIMARY KEY (csrimp_session_id, flow_involvement_type_id, flow_alert_class)
);

-- Alter tables
ALTER TABLE csr.flow_inv_type_alert_class
  ADD CONSTRAINT fk_flow_inv_type_alert_class FOREIGN KEY (app_sid, flow_involvement_type_id)
	  REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);

ALTER TABLE csr.flow_inv_type_alert_class
  ADD CONSTRAINT fk_inv_type_flow_alert_class FOREIGN KEY (app_sid, flow_alert_class)
	  REFERENCES csr.customer_flow_alert_class (app_sid, flow_alert_class);

ALTER TABLE csrimp.flow_inv_type_alert_class
  ADD CONSTRAINT fk_flow_inv_type_alert_cls_is FOREIGN KEY (csrimp_session_id)
	  REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;

ALTER TABLE csr.flow_involvement_type RENAME COLUMN flow_alert_class TO product_area;
ALTER TABLE csrimp.flow_involvement_type RENAME COLUMN flow_alert_class TO product_area;

-- *** Grants ***
GRANT SELECT, DELETE ON csr.region_role_member TO chain WITH GRANT OPTION;
GRANT SELECT, INSERT, REFERENCES ON csr.flow_inv_type_alert_class TO chain;
GRANT INSERT ON csr.flow_inv_type_alert_class TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.flow_inv_type_alert_class TO tool_user;
GRANT SELECT ON chain.v$all_purchaser_involvement TO csr;
GRANT SELECT ON chain.v$purchaser_involvement TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW csr.v$flow_involvement_type AS
	SELECT fit.app_sid, fit.flow_involvement_type_id, fit.product_area, fit.label, fit.css_class, fit.lookup_key,
		   fitac.flow_alert_class
	  FROM csr.flow_involvement_type fit
	  JOIN csr.flow_inv_type_alert_class fitac ON fit.flow_involvement_type_id = fitac.flow_involvement_type_id;

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.LogonAdmin;
	
	INSERT INTO csr.flow_inv_type_alert_class (app_sid, flow_involvement_type_id, flow_alert_class)
	SELECT fit.app_sid, fit.flow_involvement_type_id, fit.product_area
	  FROM csr.flow_involvement_type fit
	 WHERE NOT EXISTS (
		SELECT 1
		  FROM csr.flow_inv_type_alert_class
		 WHERE app_sid = fit.app_sid
		   AND flow_involvement_type_id = fit.flow_involvement_type_id
		   AND flow_alert_class = fit.product_area
	);

	security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../flow_pkg

@../csr_app_body
@../schema_body
@../flow_body
@../enable_body
@../audit_body
@../training_flow_helper_body
@../csrimp/imp_body
@../chain/setup_body


@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3124
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CSR.COMPLIANCE_ITEM_ROLLOUT_ID_SEQ;

-- Alter tables
ALTER TABLE csr.compliance_item_rollout ADD
compliance_item_rollout_id NUMBER NULL;

UPDATE csr.compliance_item_rollout
   SET compliance_item_rollout_id = csr.compliance_item_rollout_id_seq.nextval;

ALTER TABLE csr.compliance_item_rollout
MODIFY compliance_item_rollout_id NOT NULL;

ALTER TABLE csr.compliance_item_rollout
DROP CONSTRAINT PK_COMPLIANCE_ITEM_ROLLOUT;

ALTER TABLE csr.compliance_item_rollout
ADD CONSTRAINT PK_COMPLIANCE_ITEM_ROLLOUT PRIMARY KEY(app_sid, compliance_item_rollout_id);

CREATE UNIQUE INDEX CSR.IX_COMPLIANCE_ITEM_ROLLOUT ON csr.compliance_item_rollout(app_sid, compliance_item_id, NVL(country, compliance_item_id), NVL(region, compliance_item_id), NVL(country_group, compliance_item_id), NVL(region_group, compliance_item_id));

ALTER TABLE csr.compliance_item_rollout
ADD CONSTRAINT CHK_COMP_ITEM_ROL_REGION CHECK((region IS NOT NULL AND country IS NOT NULL) OR region IS NULL);

ALTER TABLE csr.compliance_item_rollout
ADD CONSTRAINT CHK_COMP_ITEM_ROL_REGION_GRP CHECK((region_group IS NOT NULL AND country IS NOT NULL) OR region_group IS NULL);


ALTER TABLE csrimp.compliance_item_rollout
ADD compliance_item_rollout_id NUMBER NOT NULL;

ALTER TABLE csrimp.compliance_item_rollout
DROP CONSTRAINT PK_COMPLIANCE_ITEM_ROLLOUT;

ALTER TABLE csrimp.compliance_item_rollout
ADD CONSTRAINT PK_COMPLIANCE_ITEM_ROLLOUT PRIMARY KEY(csrimp_session_id, compliance_item_rollout_id);

CREATE UNIQUE INDEX CSRIMP.IX_COMPLIANCE_ITEM_ROLLOUT ON csrimp.compliance_item_rollout(csrimp_session_id, compliance_item_id, NVL(country, compliance_item_id), NVL(region, compliance_item_id), NVL(country_group, compliance_item_id), NVL(region_group, compliance_item_id));

ALTER TABLE csrimp.compliance_item_rollout
ADD CONSTRAINT CHK_COMP_ITEM_ROL_REGION CHECK((region IS NOT NULL AND country IS NOT NULL) OR region IS NULL);

ALTER TABLE csrimp.compliance_item_rollout
ADD CONSTRAINT CHK_COMP_ITEM_ROL_REGION_GRP CHECK((region_group IS NOT NULL AND country IS NOT NULL) OR region_group IS NULL);

CREATE TABLE csrimp.map_compliance_item_rollout (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_compliance_item_rollout_id	NUMBER(10) NOT NULL,
	new_compliance_item_rollout_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_compliance_item_rollout PRIMARY KEY (csrimp_session_id, old_compliance_item_rollout_id),
	CONSTRAINT uk_map_compliance_item_rollout UNIQUE (csrimp_session_id, new_compliance_item_rollout_id),
    CONSTRAINT fk_map_compliance_item_rollout FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- *** Grants ***
GRANT SELECT ON csr.compliance_item_rollout_id_seq TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$comp_item_rollout_location AS
	SELECT cir.app_sid, cir.compliance_item_id,
			listagg(pc.name, ', ') within GROUP(ORDER BY pc.name) AS countries,
			listagg(pr.name, ', ') within GROUP(order by pr.name) AS regions,
			listagg(rg.group_name, ', ') within GROUP(ORDER BY region_group_id) AS region_group_names,
			listagg(cg.group_name, ', ') within GROUP(ORDER BY country_group_id) AS country_group_names
	  FROM csr.compliance_item_rollout cir
	  LEFT JOIN postcode.country pc ON cir.country = pc.country
	  LEFT JOIN postcode.region pr ON cir.country = pr.country AND cir.region = pr.region
	  LEFT JOIN csr.region_group rg ON cir.region_group = rg.region_group_id
	  LEFT JOIN csr.country_group cg ON cir.country = cg.country_group_id
	 GROUP BY cir.app_Sid, cir.compliance_item_id;

-- *** Data changes ***
-- RLS

-- Data


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../compliance_pkg
@../schema_body
@../compliance_body
@../compliance_library_report_body
@../csrimp/imp_body

@update_tail

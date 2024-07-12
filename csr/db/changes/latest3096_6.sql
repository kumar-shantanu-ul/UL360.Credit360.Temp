-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.COMPLIANCE_ROLLOUT_REGIONS
  (
    APP_SID            NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    COMPLIANCE_ITEM_ID NUMBER(10) NOT NULL,
    REGION_SID        NUMBER(10,0) NOT NULL,
    CONSTRAINT PK_COMPLIANCE_ROLLOUT_REGIONS PRIMARY KEY (APP_SID,COMPLIANCE_ITEM_ID,REGION_SID)
  );

CREATE TABLE csrimp.compliance_rollout_regions(
                csrimp_session_id                           NUMBER(10)     DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
                compliance_item_id                       NUMBER(10) NOT NULL,
                region_sid                                                           NUMBER(10,0) NOT NULL, 
                CONSTRAINT pk_compliance_rollout_regions PRIMARY KEY (csrimp_session_id, compliance_item_id, region_sid)
);

create index csr.ix_compliance_ro_region_sid on csr.compliance_rollout_regions (app_sid, region_sid);

-- Alter tables

ALTER TABLE csr.compliance_rollout_regions ADD CONSTRAINT fk_comp_rollout_reg_comp_item
                FOREIGN KEY (app_sid, compliance_item_id)
                REFERENCES csr.compliance_item (app_sid, compliance_item_id);

ALTER TABLE csr.compliance_rollout_regions ADD CONSTRAINT fk_comp_rollout_regions_region
                FOREIGN KEY (app_sid, region_sid)
                REFERENCES csr.region(app_sid, region_sid);
                
ALTER TABLE csrimp.compliance_rollout_regions ADD CONSTRAINT fk_comp_rollout_regions_is 
                FOREIGN KEY (csrimp_session_id)
                REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
                
-- *** Grants ***
grant select, insert, update, delete on csrimp.compliance_rollout_regions to tool_user;
grant insert on csr.compliance_rollout_regions TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../compliance_pkg
@../compliance_body
@../compliance_library_report_body
@../compliance_register_report_body
@../csrimp/imp_body
@update_tail

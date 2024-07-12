-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTO_IMP_USER_IMP_SETTINGS ADD REGION_MAPPING_TYPE_ID NUMBER(2) DEFAULT 1 NOT NULL;
ALTER TABLE CSR.AUTO_IMP_USER_IMP_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_USER_SET_REGMAP
    FOREIGN KEY (REGION_MAPPING_TYPE_ID)
    REFERENCES CSR.AUTO_IMP_MAPPING_TYPE(MAPPING_TYPE_ID);

create index csr.ix_auto_imp_user_region_mappin on csr.auto_imp_user_imp_settings (region_mapping_type_id);	

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\automated_import_pkg
@..\automated_import_body
@..\user_profile_pkg
@..\user_profile_body

@update_tail

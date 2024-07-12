-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE chain.company_type_relationship 
ADD (
	follower_role_sid				NUMBER(10) NULL,
	CONSTRAINT fk_co_type_rel_follower FOREIGN KEY (app_sid, follower_role_sid)
	REFERENCES csr.role (app_sid, role_sid)
);

ALTER TABLE csrimp.chain_compan_type_relati
ADD (
	follower_role_sid				NUMBER(10) NULL
);

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

@..\chain\company_pkg
@..\chain\company_type_pkg
@..\role_pkg
@..\supplier_pkg

@..\chain\company_body
@..\chain\company_type_body
@..\csrimp\imp_body
@..\role_body
@..\schema_body
@..\supplier_body


@update_tail

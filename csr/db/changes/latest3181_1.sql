-- Please update version.sql too -- this keeps clean builds in sync
define version=3181
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.enhesa_site_type
DROP CONSTRAINT PK_ENHESA_SITE_TYPE;

ALTER TABLE csrimp.enhesa_site_type
ADD CONSTRAINT PK_ENHESA_SITE_TYPE PRIMARY KEY (csrimp_session_id, site_type_id);

ALTER TABLE csrimp.enhesa_site_type_heading
DROP CONSTRAINT PK_ENHESA_SITE_TYPE_HEADING;

ALTER TABLE csrimp.enhesa_site_type_heading
ADD CONSTRAINT PK_ENHESA_SITE_TYPE_HEADING PRIMARY KEY (csrimp_session_id, site_type_heading_id);

ALTER TABLE csrimp.enhesa_site_type_heading
ADD CONSTRAINT UK_SITE_TYPE_HEADING UNIQUE (csrimp_session_id, site_type_id, heading_code);

DROP TABLE csrimp.map_compliance_condition_type;


-- *** Grants ***
GRANT UPDATE ON csr.tag to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_body

@update_tail

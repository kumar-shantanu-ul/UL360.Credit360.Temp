-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=42
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.compliance_permit_history (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	prev_permit_id					NUMBER(10,0) NOT NULL,
	next_permit_id					NUMBER(10,0) NOT NULL,
	CONSTRAINT pk_compliance_permit_history PRIMARY KEY (app_sid, prev_permit_id, next_permit_id)
);

-- Alter tables

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
@../permit_pkg
@../schema_pkg

@../permit_body
@../schema_body
@../csr_app_body

@update_tail

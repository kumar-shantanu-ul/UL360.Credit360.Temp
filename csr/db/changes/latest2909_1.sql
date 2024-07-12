-- Please update version.sql too -- this keeps clean builds in sync
define version=2909
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.internal_audit_type ADD (
	AUDIT_COORD_ROLE_OR_GROUP_SID				NUMBER(10)	NULL
);

ALTER TABLE csr.audit_type_flow_inv_type ADD (
	USERS_ROLE_OR_GROUP_SID					NUMBER(10)	NULL
);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\audit_pkg

@..\audit_body
@update_tail

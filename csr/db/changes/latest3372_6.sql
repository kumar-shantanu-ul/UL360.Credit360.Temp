-- Please update version.sql too -- this keeps clean builds in sync
define version=3372
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.flow_item ADD resource_uuid VARCHAR2(64);

CREATE UNIQUE INDEX csr.ix_flow_item_resource_uuid ON csr.flow_item (lower(resource_uuid));

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

@..\flow_pkg
@..\flow_body

@update_tail

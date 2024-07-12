-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.business_relationship_type ADD(
LOOKUP_KEY VARCHAR2(255)
);

ALTER TABLE chain.business_relationship_tier ADD(
LOOKUP_KEY VARCHAR2(255)
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

@update_tail

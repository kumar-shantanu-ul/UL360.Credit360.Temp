-- Please update version.sql too -- this keeps clean builds in sync
define version=2764
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.portlet
ADD (
  available_on_home_portal 		NUMBER(1) DEFAULT 1 NOT NULL,
  available_on_approval_portal 	NUMBER(1) DEFAULT 1 NOT NULL,
  available_on_chain_portal		NUMBER(1) DEFAULT 1 NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
UPDATE CSR.PORTLET
   SET 	available_on_home_portal = 0,
		available_on_chain_portal = 0
 WHERE portlet_id IN (1051, 1050, 1052);

UPDATE CSR.PORTLET
   SET	available_on_home_portal = 0,
		available_on_approval_portal = 0
 WHERE LOWER(type) LIKE 'credit360.portlets.chain.%'
    OR portlet_id IN (543, 803, 683, 563, 1044, 1043); --Client portlet ids

-- ** New package grants **

-- *** Packages ***
@..\portlet_pkg
@..\portlet_body

@update_tail

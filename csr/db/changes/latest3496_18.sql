-- Please update version.sql too -- this keeps clean builds in sync
define version=3496
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE aspen2.application ADD (
   maxmind_enabled NUMBER(1) DEFAULT 1 NOT NULL
   CONSTRAINT CK_MAXMIND_ENABLED CHECK (maxmind_enabled IN (0,1))
);

ALTER TABLE csrimp.aspen2_application ADD (
  maxmind_enabled NUMBER(1) DEFAULT 1 NOT NULL
  CONSTRAINT CK_MAXMIND_ENABLED CHECK (maxmind_enabled IN (0,1))
);

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (128, 'MaxMind Geo Location', 'EnableMaxMind', 'Enables MaxMind Geo location.');

INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (128, 'Enable/Disable', 0, '0=disable, 1=enable');
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
@..\enable_pkg
@..\schema_body
@..\csrimp\imp_body
@..\enable_body

@..\..\..\aspen2\db\tr_pkg
@..\..\..\aspen2\db\aspenapp_body
@..\..\..\aspen2\db\tr_body

@update_tail

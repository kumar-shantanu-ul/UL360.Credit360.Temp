-- Please update version.sql too -- this keeps clean builds in sync
define version=3329
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.PLUGIN ADD (ALLOW_MULTIPLE NUMBER(10, 0) DEFAULT 0);
ALTER TABLE CSR.PLUGIN ADD CONSTRAINT CK_ALLOW_MULTIPLE CHECK (ALLOW_MULTIPLE IN (1,0));

ALTER TABLE CSRIMP.PLUGIN ADD (ALLOW_MULTIPLE NUMBER(10, 0));
ALTER TABLE CSRIMP.PLUGIN ADD CONSTRAINT CK_ALLOW_MULTIPLE CHECK (ALLOW_MULTIPLE IN (1,0));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE CSR.PLUGIN
   SET allow_multiple = 1
 WHERE js_class IN ('Chain.ManageCompany.BusinessRelationshipGraph', 'Chain.ManageCompany.IntegrationSupplierDetailsTab');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body
@../plugin_body


@../chain/integration_pkg
@../chain/integration_body

@update_tail

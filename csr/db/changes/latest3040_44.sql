-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=44
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.CUSTOMER_OPTIONS
ADD ENABLE_PRODUCT_COMPLIANCE NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD CONSTRAINT CHK_ENABLE_PRODUCT_COMPLIANCE CHECK (ENABLE_PRODUCT_COMPLIANCE IN (0,1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (93, 'Product Compliance', 'EnableProductCompliance', 'Enables the product compliance pages. !!! This module is currently in development and this script should not be used on live client sites !!!');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/helper_pkg
@../enable_pkg

@../chain/helper_body
@../chain/product_type_body
@../enable_body

@update_tail

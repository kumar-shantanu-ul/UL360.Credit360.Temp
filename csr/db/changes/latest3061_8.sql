-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

CREATE GLOBAL TEMPORARY TABLE chain.tt_product (
	product_type_id				NUMBER(10) NOT NULL,
	product						VARCHAR2(255) NOT NULL,
	certification_type			VARCHAR2(255) NULL
) ON COMMIT DELETE ROWS;

-- Alter tables

-- *** Grants ***

GRANT SELECT ON csr.internal_audit_type_id_seq TO chain;

GRANT INSERT ON csr.internal_audit_type TO chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\plugin_pkg
@..\chain\plugin_pkg
@..\chain\test_product_data_pkg

@..\plugin_body
@..\chain\plugin_body
@..\chain\chain_body
@..\chain\test_product_data_body

@update_tail

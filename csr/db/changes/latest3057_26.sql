-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables

CREATE OR REPLACE TYPE CHAIN.T_OBJECT_CERTIFICATION_ROW AS
	 OBJECT (
		OBJECT_ID					NUMBER(10),
		CERTIFICATION_TYPE_ID		NUMBER(10),
		IS_CERTIFIED				NUMBER(1),
		FROM_DTM					DATE,
		TO_DTM						DATE,
		MAP MEMBER FUNCTION MAP
			RETURN VARCHAR2
	 );
/

CREATE OR REPLACE TYPE BODY chain.T_OBJECT_CERTIFICATION_ROW IS
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN OBJECT_ID||'@'||CERTIFICATION_TYPE_ID;
	END;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_OBJECT_CERTIFICATION_TABLE AS
	TABLE OF CHAIN.T_OBJECT_CERTIFICATION_ROW;
/


-- Alter tables
ALTER TABLE chain.certification_type ADD (
	product_requirement_type_id			NUMBER(10, 0) DEFAULT 0 NOT NULL 
);

ALTER TABLE csrimp.chain_certification_type ADD (
	product_requirement_type_id			NUMBER(10, 0) NOT NULL 
);

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
@../chain/chain_pkg
@../chain/certification_pkg
@../chain/company_product_pkg
@../chain/product_report_pkg

@../chain/certification_body
@../chain/company_product_body
@../chain/product_report_body
@../schema_body
@../csrimp/imp_body

@update_tail

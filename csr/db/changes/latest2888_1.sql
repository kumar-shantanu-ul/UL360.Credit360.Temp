-- Please update version.sql too -- this keeps clean builds in sync
define version=2888
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
DROP TYPE CHAIN.T_CAPABILITY_CHECK_TABLE;
DROP TYPE CHAIN.T_CAPABILITY_CHECK_ROW;

--permissible company types
CREATE OR REPLACE TYPE CHAIN.T_PERMISSIBLE_TYPES_ROW AS 
	OBJECT ( 
		CAPABILITY_ID				NUMBER(10),
		PRIMARY_COMPANY_TYPE_ID		NUMBER(10),
		SECONDARY_COMPANY_TYPE_ID	NUMBER(10),
		TERTIARY_COMPANY_TYPE_ID	NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CHAIN.T_PERMISSIBLE_TYPES_TABLE AS 
	TABLE OF CHAIN.T_PERMISSIBLE_TYPES_ROW;
/

--supplier relationships
CREATE OR REPLACE TYPE CHAIN.T_SUPPLIER_RELATIONSHIP_ROW AS 
	 OBJECT ( 
		PURCHASER_COMPANY_SID	NUMBER(10),
		SUPPLIER_COMPANY_SID	NUMBER(10),
		SUPPLIER_REGION_SID		NUMBER(10),
		FLOW_ITEM_ID			NUMBER(10)
	 ); 
/

CREATE OR REPLACE TYPE CHAIN.T_SUPPLIER_RELATIONSHIP_TABLE AS 
	TABLE OF CHAIN.T_SUPPLIER_RELATIONSHIP_ROW;
/

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
@../chain/type_capability_pkg

@../supplier_body
@../chain/type_capability_body
@../chain/company_body
@../chain/company_type_body
@../chain/company_user_body
@../chain/company_filter_body
@../chain/invitation_body
@../chain/supplier_audit_body
@../chain/business_relationship_body
@../chain/audit_request_body

@update_tail

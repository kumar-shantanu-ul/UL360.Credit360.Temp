-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

CREATE OR REPLACE TYPE CHAIN.T_DEDUPE_COMPANY_ROW AS
	OBJECT (
		NAME				VARCHAR2(255),
		PARENT_COMPANY_NAME	VARCHAR2(255),
		COMPANY_TYPE		VARCHAR2(255),
		CREATED_DTM			DATE,
		ACTIVATED_DTM		DATE,
		ACTIVE				NUMBER(1),
		ADDRESS				VARCHAR2(1024),
		ADDRESS_1			VARCHAR2(255),
		ADDRESS_2			VARCHAR2(255),
		ADDRESS_3			VARCHAR2(255),
		ADDRESS_4			VARCHAR2(255),
		STATE				VARCHAR2(255),
		POSTCODE			VARCHAR2(32),
		COUNTRY_CODE		VARCHAR2(255),
		PHONE				VARCHAR2(255),
		FAX					VARCHAR2(255),
		WEBSITE				VARCHAR2(255),
		EMAIL				VARCHAR2(255),
		DELETED				NUMBER(1),
		SECTOR				VARCHAR2(255),
		CITY				VARCHAR2(255),
		DEACTIVATED_DTM		DATE,
		PURCHASER_COMPANY	NUMBER(10),
		CONSTRUCTOR FUNCTION T_DEDUPE_COMPANY_ROW
		RETURN self AS RESULT
	);
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO chain.dedupe_field (dedupe_field_id, entity, field, description) VALUES (19, 'COMPANY', 'PURCHASER_COMPANY', 'Purchaser company');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\chain_pkg
@..\chain\chain_body

@..\chain\company_dedupe_body

@update_tail

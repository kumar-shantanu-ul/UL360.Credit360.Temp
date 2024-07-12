-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=35
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_EST_ERROR_INFO
(
	REGION_SID					NUMBER(10),
	PROP_REGION_SID				NUMBER(10),
	EST_ACCOUNT_SID				NUMBER(10),
	PM_CUSTOMER_ID				VARCHAR2(256),
	PM_BUILDING_ID				VARCHAR2(256),
	PM_SPACE_ID					VARCHAR2(256),
	PM_METER_ID					VARCHAR2(256),
	BUILDING_NAME				VARCHAR2(1024),
	SPACE_NAME					VARCHAR2(1024),
	METER_NAME					VARCHAR2(1024),
	ERROR_ID					NUMBER(10),
	ERROR_CODE					NUMBER(10),
	ERROR_COUNT					NUMBER(10),
	ERROR_MESSAGE				VARCHAR2(4000),
	ERROR_DTM					DATE
) ON COMMIT DELETE ROWS;

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
@../energy_star_body
@../energy_star_job_body

@update_tail

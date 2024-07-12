-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(table_name)
	  INTO v_check
	  FROM all_tables
	 WHERE owner = 'CSR'
	   AND table_name = 'TEMP_FLOW_ITEM_REGION';

	IF v_check = 1 THEN
		EXECUTE IMMEDIATE 'DROP TABLE CSR.TEMP_FLOW_ITEM_REGION';
	END IF;
END;
/

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_FLOW_ITEM_REGION (
	FLOW_ITEM_ID		NUMBER(10) NOT NULL,
	REGION_SID			NUMBER(10) NOT NULL
) ON COMMIT DELETE ROWS;

CREATE INDEX CSR.IX_TEMP_FLOW_ITEM_REGION_F ON CSR.TEMP_FLOW_ITEM_REGION(FLOW_ITEM_ID);
CREATE INDEX CSR.IX_TEMP_FLOW_ITEM_REGION_R ON CSR.TEMP_FLOW_ITEM_REGION(REGION_SID);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.util_script_param
   SET param_hint = 'System ID of a workflow. Supports Chain, Campaign and CMS workflow types only.'
 WHERE util_script_id = 27;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_report_pkg
@../../../aspen2/cms/db/tab_pkg

@../flow_report_body
@../../../aspen2/cms/db/tab_body

@update_tail

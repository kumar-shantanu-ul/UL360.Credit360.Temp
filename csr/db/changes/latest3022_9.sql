-- Please update version.sql too -- this keeps clean builds in sync
define version=3022
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.IMG_CHART ADD (
	SCENARIO_RUN_TYPE		NUMBER(1, 0)      DEFAULT 0 NOT NULL
);

ALTER TABLE CSRIMP.IMG_CHART ADD (
	SCENARIO_RUN_SID		NUMBER(10, 0),
	SCENARIO_RUN_TYPE		NUMBER(1, 0)      DEFAULT 0 NOT NULL
);


-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE CSR.IMG_CHART ADD CONSTRAINT CK_IMG_CHART_SCN_RUN_TYPE CHECK (SCENARIO_RUN_TYPE IN (0,1,2));



-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	UPDATE csr.img_chart
	   SET scenario_run_type = use_unmerged
	 WHERE scenario_run_sid IS NULL;
	
	UPDATE csr.img_chart
	   SET scenario_run_type = 2
	 WHERE scenario_run_sid IS NOT NULL;
END;
/
ALTER TABLE CSR.IMG_CHART ADD CONSTRAINT CK_IMG_CHART_SCN_RUN_SID 
CHECK ((SCENARIO_RUN_TYPE = 2 AND SCENARIO_RUN_SID IS NOT NULL) OR
	   (SCENARIO_RUN_TYPE IN (0,1) AND SCENARIO_RUN_SID IS NULL));
ALTER TABLE csr.img_chart DROP COLUMN use_unmerged;


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../img_chart_pkg
@../img_chart_body
@../schema_body

@update_tail

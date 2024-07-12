-- Please update version.sql too -- this keeps clean builds in sync
define version=3022
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.img_chart ADD (
	scenario_run_sid		NUMBER(10, 0),
	use_unmerged			NUMBER(1, 0)      DEFAULT 0 NOT NULL
);

ALTER TABLE csr.img_chart ADD CONSTRAINT FK_IMG_CHART_SCENARIO_RUN
	FOREIGN KEY (APP_SID, SCENARIO_RUN_SID)
	REFERENCES CSR.SCENARIO_RUN (APP_SID, SCENARIO_RUN_SID)
;

ALTER TABLE csr.img_chart ADD CONSTRAINT CK_IMG_CHART_USE_UNMERGED CHECK (USE_UNMERGED IN (0,1));

create index csr.ix_img_chart_scenario_run_ on csr.img_chart (app_sid, scenario_run_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	FOR r IN (
		SELECT DISTINCT app_sid, merged_scenario_run_sid
		  FROM csr.customer
	) LOOP
		UPDATE csr.img_chart
		   SET scenario_run_sid = r.merged_scenario_run_sid
		 WHERE app_sid = r.app_sid;
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../img_chart_pkg
@../img_chart_body
@../schema_body

@update_tail

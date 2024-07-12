-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_options ADD (
	score_type_id NUMBER(10),
	CONSTRAINT FK_COMP_OPTIONS_SCORE_TYPE FOREIGN KEY (app_sid, score_type_id) REFERENCES csr.score_type(app_sid, score_type_id)
);

CREATE INDEX csr.ix_compliance_op_score_type_id ON csr.compliance_options (app_sid, score_type_id);

ALTER TABLE csrimp.compliance_options ADD (
	score_type_id NUMBER(10)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

CREATE OR REPLACE VIEW csr.v$compliance_item_rag AS 
	SELECT t.region_sid, t.total_items, t.compliant_items, t.pct_compliant, 
		TRIM(TO_CHAR ((
			SELECT DISTINCT FIRST_VALUE(text_colour)
			  OVER (ORDER BY st.max_value ASC) AS text_colour
			  FROM csr.compliance_options co
			  JOIN csr.score_threshold st ON co.score_type_id = st.score_type_id AND st.app_sid = co.app_sid
			 WHERE co.app_sid = security.security_pkg.GetApp
				 AND t.pct_compliant <= st.max_value
		), 'XXXXXX')) pct_compliant_colour
	FROM (
		SELECT app_sid, region_sid, total_items, compliant_items, DECODE(total_items, 0, 0, ROUND(100*compliant_items/total_items)) pct_compliant
		 FROM (
			SELECT cir.app_sid, cir.region_sid, COUNT(*) total_items, SUM(DECODE(fsn.label, 'Compliant', 1, 0)) compliant_items
				FROM csr.compliance_item_region cir
				JOIN csr.compliance_item ci ON cir.compliance_item_id = ci.compliance_item_id
				JOIN csr.flow_item fi ON fi.flow_item_id = cir.flow_item_id
				JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id
				LEFT JOIN csr.flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id
			 WHERE fsn.flow_alert_class IN ('regulation', 'requirement')
				 AND lower(fsn.label) NOT IN ('retired', 'not applicable')
			 GROUP BY cir.app_sid, cir.region_sid
		)
		ORDER BY region_sid
	) t
;


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@../geo_map_pkg
@@../compliance_pkg
@@../region_body
@@../geo_map_body
@@../property_report_body
@@../compliance_body
@@../schema_body
@@../enable_body
@@../csrimp/imp_body

@update_tail

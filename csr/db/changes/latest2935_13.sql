-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- Reverse
/*
ALTER TABLE chain.saved_filter DROP CONSTRAINT chk_ranking_mode;
ALTER TABLE chain.saved_filter DROP COLUMN ranking_mode;
ALTER TABLE csrimp.chain_saved_filter DROP COLUMN ranking_mode;
*/

ALTER TABLE chain.saved_filter ADD (
	ranking_mode NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_ranking_mode CHECK (ranking_mode IN (0, 1, 2))
);

ALTER TABLE csrimp.chain_saved_filter ADD (
	ranking_mode NUMBER(1,0) NULL
);

UPDATE csrimp.chain_saved_filter SET ranking_mode = 0;
ALTER TABLE csrimp.chain_saved_filter MODIFY (ranking_mode NUMBER(1,0) NOT NULL);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
EXEC security.user_pkg.LogonAdmin;

UPDATE chain.saved_filter 
   SET ranking_mode = 1 /* Ascending */
 WHERE (app_sid, saved_filter_sid) IN (
	SELECT app_sid, saved_filter_sid
	FROM (
	  SELECT 
		  app_sid,
		  saved_filter_sid, 
		  COUNT(CASE WHEN chart_type = 3 THEN 1 END) bar_charts,
		  COUNT(CASE WHEN chart_type <> 3 THEN 1 END) other_charts
	  FROM (
		  SELECT app_sid, saved_filter_sid, filter_result_mode chart_type 
		    FROM csr.tpl_report_tag_dataview 
		   WHERE saved_filter_sid IS NOT NULL
		     AND filter_result_mode IS NOT NULL
		UNION ALL
		  SELECT tp.app_sid,
				 TO_NUMBER(REGEXP_REPLACE(tp.state, '.*"dataviewSid":([0-9]+).*', '\1')) saved_filter_sid,
				 TO_NUMBER(REGEXP_REPLACE(tp.state, '.*"chartType":([0-9]+).*', '\1')) chart_type
		    FROM csr.tab_portlet tp
		    JOIN csr.customer_portlet cp 
		      ON cp.customer_portlet_sid = tp.customer_portlet_sid
		    JOIN csr.portlet p
		      ON cp.portlet_id = p.portlet_id
		   WHERE p.type = 'Credit360.Portlets.Chart'
		     AND REGEXP_LIKE(tp.state, '"dataviewSid":([0-9]+)')
		     AND REGEXP_LIKE(tp.state, '"chartType":([0-9]+)')
		     AND REGEXP_LIKE(tp.state, '"isFilter":true')
		UNION ALL
		  SELECT tp.app_sid,
				 TO_NUMBER(REGEXP_REPLACE(tp.state, '.*"dataviewSid":([0-9]+).*', '\1')) saved_filter_sid,
				 99 chart_type /* table... */
		    FROM csr.tab_portlet tp
		    JOIN csr.customer_portlet cp 
		      ON cp.customer_portlet_sid = tp.customer_portlet_sid
		    JOIN csr.portlet p
		      ON cp.portlet_id = p.portlet_id
		   WHERE p.type = 'Credit360.Portlets.Table'
		     AND REGEXP_LIKE(tp.state, '"dataviewSid":([0-9]+)')
		     AND REGEXP_LIKE(tp.state, '"isFilter":true')
	  )
	  GROUP BY app_sid, saved_filter_sid
	)
	WHERE bar_charts > 0 AND other_charts = 0
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg
@../chain/filter_body
@../csrimp/imp_body
@../schema_body

@update_tail

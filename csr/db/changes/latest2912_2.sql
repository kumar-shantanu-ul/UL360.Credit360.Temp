-- Please update version.sql too -- this keeps clean builds in sync
define version=2912
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- add columns
ALTER TABLE csr.region_metric_val ADD measure_sid					NUMBER(10);
ALTER TABLE csr.region_metric_val ADD source_type_id 				NUMBER(10);
ALTER TABLE csr.region_metric_val ADD entry_measure_conversion_id	NUMBER(10);
ALTER TABLE csr.region_metric_val ADD entry_val 					NUMBER(24,10);

ALTER TABLE csr.temp_region_metric_val ADD source_type_id			NUMBER(10);

-- copy data
DECLARE
BEGIN
	UPDATE csr.region_metric_val rmv
	SET (rmv.measure_sid, rmv.source_type_id, rmv.entry_measure_conversion_id) =
		(SELECT measure_sid, source_type_id, measure_conversion_id
		   FROM csr.region_metric_region rmr
		  WHERE rmv.app_sid = rmr.app_sid
		    AND rmv.ind_sid = rmr.ind_sid
		    AND rmv.region_sid = rmr.region_sid
		);

	UPDATE csr.region_metric_val
	SET entry_val = val;

	FOR r IN (
		SELECT app_sid, ind_sid, region_sid, entry_val, entry_measure_conversion_id, effective_dtm
		  FROM csr.region_metric_val
		 WHERE entry_measure_conversion_id IS NOT NULL
	)
	LOOP
		UPDATE csr.region_metric_val rmv
		   SET val = CASE
		   				WHEN NVL(r.entry_measure_conversion_id, -1) = -1 THEN
		   					rmv.entry_val
		   				ELSE
							-- csr.measure_pkg.UNSEC_GetBaseValue
						   (SELECT NVL(NVL(mc.a, mcp.a), 1) * POWER(rmv.entry_val, NVL(NVL(mc.b, mcp.b), 1)) + NVL(NVL(mc.c, mcp.c), 0)
							  FROM csr.measure_conversion mc,
							  	   csr.measure_conversion_period mcp
							 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
							   AND r.entry_measure_conversion_id = mc.measure_conversion_id(+)
							   AND (r.effective_dtm >= mcp.start_dtm or mcp.start_dtm IS NULL)
							   AND (r.effective_dtm < mcp.end_dtm or mcp.end_dtm IS NULL))
		   				END
		 WHERE app_sid = r.app_sid
		   AND ind_sid = r.ind_sid
		   AND region_sid = r.region_sid
		   AND entry_measure_conversion_id = r.entry_measure_conversion_id;
	END LOOP;
END;
/

-- set NOT NULLs
ALTER TABLE csr.region_metric_val MODIFY (measure_sid NOT NULL, source_type_id NOT NULL);

-- add new FKs to region_metric_val
ALTER TABLE csr.region_metric_val ADD CONSTRAINT FK_REGION_METRIC_VAL_REGION
	FOREIGN KEY (app_sid, region_sid)
	REFERENCES csr.region(app_sid, region_sid)
;
ALTER TABLE csr.region_metric_val ADD CONSTRAINT FK_REGION_METRIC_VAL_REGION_M
	FOREIGN KEY (app_sid, ind_sid, measure_sid)
	REFERENCES csr.region_metric(app_sid, ind_sid, measure_sid)
;
ALTER TABLE csr.region_metric_val ADD CONSTRAINT FK_REGION_METRIC_VAL_MEASURE_C
	FOREIGN KEY (app_sid, measure_sid, entry_measure_conversion_id)
	REFERENCES csr.measure_conversion(app_sid, measure_sid, measure_conversion_id)
;
ALTER TABLE csr.region_metric_val ADD CONSTRAINT FK_REGION_METRIC_VAL_SOURCE_T
	FOREIGN KEY (source_type_id)
	REFERENCES csr.source_type(source_type_id)
;

-- create indexes for the new FKs
CREATE INDEX csr.IX_REGION_METRIC_VAL_REGION ON csr.region_metric_val (app_sid, region_sid);
CREATE INDEX csr.IX_REGION_METRIC_VAL_REGION_M ON csr.region_metric_val (app_sid, ind_sid, measure_sid);
CREATE INDEX csr.IX_REGION_METRIC_VAL_MEASURE_C ON csr.region_metric_val (app_sid, measure_sid, entry_measure_conversion_id);
CREATE INDEX csr.IX_REGION_METRIC_VAL_SOURCE_T ON csr.region_metric_val (source_type_id);

-- backup region_metric_region
CREATE TABLE csr.FB87487_region_metric_region
AS
SELECT * FROM csr.region_metric_region;

-- drop region_metric_region
DROP TABLE csr.region_metric_region CASCADE CONSTRAINTS;
DROP TABLE csrimp.region_metric_region CASCADE CONSTRAINTS;

-- drop unused index
DROP INDEX csr.IX_RMETRICR_RMETRIC_VAL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

DROP VIEW csr.v$region_metric_region;
DROP VIEW csr.v$region_metric_val_converted;

-- C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$imp_val_mapped AS
	SELECT iv.imp_val_id, iv.imp_session_Sid, iv.file_sid, ii.maps_to_ind_sid, iv.start_dtm, iv.end_dtm,
		   ii.description ind_description,
		   i.description maps_to_ind_description,
		   ir.description region_description,
		   i.aggregate,
		   iv.val,
		   NVL(NVL(mc.a, mcp.a),1) factor_a,
		   NVL(NVL(mc.b, mcp.b),1) factor_b,
		   NVL(NVL(mc.c, mcp.c),0) factor_c,
		   m.description measure_description,
		   im.maps_to_measure_conversion_id,
		   mc.description from_measure_description,
		   NVL(i.format_mask, m.format_mask) format_mask,
		   ir.maps_to_region_sid,
		   iv.rowid rid,
		   ii.app_Sid, iv.note,
		   CASE WHEN m.custom_field LIKE '|%' THEN 1 ELSE 0 END is_text_ind,
		   icv.imp_conflict_id,
		   m.measure_sid,
		   iv.imp_ind_id, iv.imp_region_id,
		   CASE WHEN rm.ind_Sid IS NOT NULL THEN 1 ELSE 0 END is_region_metric
	  FROM imp_val iv
		   JOIN imp_ind ii
		   		 ON iv.imp_ind_id = ii.imp_ind_id
		   		AND iv.app_sid = ii.app_sid
		   		AND ii.maps_to_ind_sid IS NOT NULL
		   JOIN imp_region ir
		  		 ON iv.imp_region_id = ir.imp_region_id
		   		AND iv.app_sid = ir.app_sid
		   		AND ir.maps_to_region_sid IS NOT NULL
	  LEFT JOIN imp_measure im
	      		 ON iv.imp_ind_id = im.imp_ind_id
	      		AND iv.imp_measure_id = im.imp_measure_id
	      		AND iv.app_sid = im.app_sid
	  LEFT JOIN measure_conversion mc
				 ON im.maps_to_measure_conversion_id = mc.measure_conversion_id
				AND im.app_sid = mc.app_sid
      LEFT JOIN measure_conversion_period mcp
				 ON mc.measure_conversion_id = mcp.measure_conversion_id
				AND (iv.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
				AND (iv.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
	  LEFT JOIN imp_conflict_val icv
				 ON iv.imp_val_id = icv.imp_val_id
				AND iv.app_sid = icv.app_sid
		   JOIN v$ind i
				 ON ii.maps_to_ind_sid = i.ind_sid
				AND ii.app_sid = i.app_sid
				AND i.ind_type = 0
	  LEFT JOIN region_metric rm
				 ON i.ind_sid = rm.ind_sid AND i.app_sid = rm.app_sid
			   JOIN measure m
				 ON i.measure_sid = m.measure_sid
				AND i.app_sid = m.app_sid;

CREATE OR REPLACE VIEW csr.v$imp_merge AS
	SELECT *
	  FROM v$imp_val_mapped
	 WHERE imp_conflict_id IS NULL;

-- csrimp
ALTER TABLE csrimp.region_metric_val ADD measure_sid					NUMBER(10);
ALTER TABLE csrimp.region_metric_val ADD source_type_id 				NUMBER(10);
ALTER TABLE csrimp.region_metric_val ADD entry_measure_conversion_id	NUMBER(10);
ALTER TABLE csrimp.region_metric_val ADD entry_val 						NUMBER(24,10);

-- csrimp: fix data for the nasty devs
UPDATE csrimp.region_metric_val rmv
   SET measure_sid = (SELECT measure_sid FROM csrimp.ind WHERE ind_sid = rmv.ind_sid),
	   source_type_id = 14;

-- csrimp: set NOT NULLs
ALTER TABLE csrimp.region_metric_val MODIFY (measure_sid NOT NULL, source_type_id NOT NULL);


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body
@../csrimp/imp_body
@../measure_body
@../property_pkg
@../property_body
@../property_report_body
@../region_body
@../region_metric_pkg
@../region_metric_body
@../imp_body
@../energy_star_body
@../energy_star_helper_body
@../energy_star_job_data_body
@../schema_pkg
@../schema_body

@update_tail

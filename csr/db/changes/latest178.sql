-- Please update version.sql too -- this keeps clean builds in sync
define version=178
@update_header

drop table get_value_result;

CREATE GLOBAL TEMPORARY TABLE GET_VALUE_RESULT
(
	period_start_dtm	DATE,
	period_end_dtm		DATE,
	source				NUMBER(10,0),
	source_id			NUMBER(10,0),
	ind_sid				NUMBER(10,0),
	region_sid			NUMBER(10,0),
	val_number			NUMBER(24,10),
	changed_dtm			DATE,
	note				CLOB,
	flags				NUMBER (10,0),
	is_leaf				NUMBER(1,0),
	is_merged			NUMBER(1,0),
	path				VARCHAR2(1024)
) ON COMMIT DELETE ROWS;

CREATE OR REPLACE VIEW V$GET_VALUE_RESULT_FILES AS
		SELECT r.source_id, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM get_value_result r, val_file vf, file_upload fu
		 WHERE r.source = 0 AND vf.val_id = r.source_id AND fu.file_upload_sid = vf.file_upload_sid
	 UNION ALL
		SELECT r.source_id, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM get_value_result r, sheet_value_file svf, file_upload fu
		 WHERE r.source = 1 AND svf.sheet_value_id = r.source_id AND fu.file_upload_sid = svf.file_upload_sid;

@..\indicator_body
@..\sheet_body
@..\..\..\aspen2\tools\recompile_packages
    
@update_tail

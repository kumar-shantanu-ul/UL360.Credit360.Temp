-- Please update version.sql too -- this keeps clean builds in sync
define version=1008
@update_header

CREATE OR REPLACE VIEW csr.v$doc_approved AS
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
		   dc.version,
		   df.lifespan, 
		   dv.filename, dv.description, dv.change_description, dv.changed_by_sid, dv.changed_dtm, 
		   dd.sha1, dd.mime_type, dd.data, dd.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE	
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dv.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status,
		   dd.app_sid
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dv ON dc.doc_id = dv.doc_id AND dc.version = dv.version 
		LEFT JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
		-- don't return stuff that's added but never approved
	   WHERE dc.version IS NOT NULL; 
	   
	   
@..\doc_body

@update_tail

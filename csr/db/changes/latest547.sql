-- Please update version.sql too -- this keeps clean builds in sync
define version=547
@update_header

INSERT INTO AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 17, 'Suspicious access');


CREATE OR REPLACE VIEW v$doc_current_status AS
	SELECT parent_sid, doc_id, locked_by_sid, pending_version, 
		version, lifespan,
		filename, description, change_description, changed_by_sid, changed_dtm,
		sha1, mime_type, data, doc_data_id,
		locked_by_me, expiry_status
	  FROM v$doc_approved
	   WHERE NVL(locked_by_sid,-1) != SYS_CONTEXT('SECURITY','SID') OR pending_version IS NULL
	   UNION ALL
	SELECT dc.parent_sid, dc.doc_id, dc.locked_by_sid, dc.pending_version,
			-- if it's the approver then show them the right version, otherwise pass through null (i.e. dc.version) to other users so they can't fiddle
		   CASE WHEN NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL THEN dc.pending_version ELSE dc.version END version,		   
		   df.lifespan, 
		   dvp.filename, dvp.description, dvp.change_description, dvp.changed_by_sid, dvp.changed_dtm, 
		   ddp.sha1, ddp.mime_type, ddp.data, ddp.doc_data_id,
		   CASE WHEN dc.locked_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END locked_by_me,
		   CASE	
				WHEN df.lifespan IS NULL THEN 0
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan) THEN 2 -- csr_data_pkg.DOCLIB_EXPIRED
				WHEN SYSDATE > ADD_MONTHS(dvp.changed_dtm, df.lifespan - 1) THEN 1 -- csr_data_pkg.DOCLIB_NEARLY_EXPIRED
				ELSE 0
		   END expiry_status		
	  FROM doc_current dc
		JOIN doc_folder df ON dc.parent_sid = df.doc_folder_sid
		LEFT JOIN doc_version dvp ON dc.doc_id = dvp.doc_id AND dc.pending_version = dvp.version 
		LEFT JOIN doc_data ddp ON dvp.doc_data_id = ddp.doc_data_id
	   WHERE (NVL(dc.locked_by_sid,-1) = SYS_CONTEXT('SECURITY','SID') AND dc.pending_version IS NOT NULL) OR dc.version IS null;

@..\csr_data_pkg
@..\doc_pkg
@..\doc_folder_pkg
@..\doc_lib_pkg

@..\csr_data_body
@..\doc_body
@..\doc_folder_body
@..\doc_lib_body

@update_tail

define version=1989
@update_header

CREATE OR REPLACE VIEW csr.v$term_cond_doc AS
	SELECT tcd.doc_id, dv.filename, tcd.version, tcd.company_type_id, dv.description
	  FROM (
	    SELECT DISTINCT tcd.doc_id, dc.version, tcd.company_type_id
	      FROM csr.term_cond_doc tcd
	      JOIN csr.doc_current dc ON dc.app_sid = tcd.app_sid AND dc.doc_id = tcd.doc_id
	     WHERE tcd.app_sid = security_pkg.GetApp
		   AND dc.locked_by_sid IS NULL -- only set if current doc version needs approval or it has been marked as deleted
		   ) tcd
	  JOIN csr.doc_version dv ON dv.app_sid = security_pkg.GetApp AND dv.doc_id = tcd.doc_id AND dv.version = tcd.version;
	  
@..\doc_pkg
@..\doc_body

@update_tail
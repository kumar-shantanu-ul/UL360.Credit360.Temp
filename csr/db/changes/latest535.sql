-- Please update version.sql too -- this keeps clean builds in sync
define version=535
@update_header

create or replace view v$doc_current as
	select d.parent_sid, dv.doc_id, dv.version, dv.filename, dv.description, dv.change_description, 
		   dv.changed_by_sid, dv.changed_dtm, dd.doc_data_id, dd.data, dd.sha1, dd.mime_type, 
		   d.locked_by_sid, d.pending_approval, df.lifespan
	  from doc_current d, doc_version dv, doc_data dd, doc_folder df
	 where d.doc_id = dv.doc_id and d.version = dv.version and dv.doc_data_id = dd.doc_data_id AND d.parent_sid = df.doc_folder_sid;

@update_tail

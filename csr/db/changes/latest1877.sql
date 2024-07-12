-- Please update version.sql too -- this keeps clean builds in sync
define version=1877
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_INITIATIVE_SIDS
(
	INITIATIVE_SID 			NUMBER(10, 0)	NOT NULL
)
ON COMMIT DELETE ROWS;

CREATE SEQUENCE CSR.INIT_IMPORT_MAPPING_POS_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

CREATE SEQUENCE CSR.INIT_IMPORT_TEMPLATE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

@../initiative_metric_pkg
@../initiative_pkg
@../initiative_doc_pkg
@../initiative_project_pkg
@../initiative_import_pkg
@../initiative_aggr_pkg

@../initiative_metric_body
@../initiative_body
@../initiative_doc_body
@../initiative_project_body
@../initiative_import_body
@../initiative_aggr_body

grant execute on csr.initiative_pkg to web_user;
grant execute on csr.initiative_doc_pkg to web_user;
grant execute on csr.initiative_project_pkg to web_user;
grant execute on csr.initiative_metric_pkg to web_user;
grant execute on csr.initiative_import_pkg to web_user;

@update_tail

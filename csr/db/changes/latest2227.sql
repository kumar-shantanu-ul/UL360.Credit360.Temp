-- Please update version.sql too -- this keeps clean builds in sync
define version=2227
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_DOC_REFERENCE
(
	MODULE				VARCHAR2(100)	NOT NULL,
	DESCRIPTION			VARCHAR2(500)	NOT NULL,
	URL					VARCHAR2(300)
) ON COMMIT DELETE ROWS;

create or replace package csr.doc_helper_pkg as end;
/

grant execute on csr.doc_helper_pkg to web_user;

@..\doc_helper_pkg
@..\doc_helper_body

@update_tail

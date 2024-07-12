-- Please update version.sql too -- this keeps clean builds in sync
define version=395
@update_header

CREATE OR REPLACE TYPE T_VARCHAR2_TABLE AS TABLE OF VARCHAR2(4000);
/

@..\str_functions
@..\doc_body
 
@update_tail

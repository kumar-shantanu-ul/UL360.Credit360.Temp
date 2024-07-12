-- Please update version.sql too -- this keeps clean builds in sync
define version=2712
@update_header

DECLARE
	v_count 	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE index_name = 'IX_QS_ANSWER_FILE_SEARCH'
	   AND owner = 'CSR';
	   
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER INDEX csr.ix_qs_answer_file_search RENAME TO ix_qs_response_file_srch';
	END IF;
END;
/

@update_tail

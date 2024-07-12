-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=4
@update_header

-- Exact copy of latest2712 because of missing basedata.
-- All installed customers since the 18th June 2015 will NOT
-- have the correct index. Having the old index causes the Windows
-- Sched task: JobRunner.exe to continuously fail.
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

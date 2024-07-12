-- Please update version.sql too -- this keeps clean builds in sync
define version=2745
@update_header

DECLARE v_count NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CMS'
	   AND table_name = 'TT_FILTERED_ID'
	   AND index_name = 'UK_TT_FILTERED_ID';
	
	IF v_count = 0 THEN 
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX CMS.UK_TT_FILTERED_ID ON CMS.TT_FILTERED_ID (ID)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CMS'
	   AND table_name = 'TT_ID'
	   AND index_name = 'UK_TT_ID';
	
	IF v_count = 0 THEN 
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX CMS.UK_TT_ID ON CMS.TT_ID (ID)';
	END IF;
	
END;
/

@update_tail

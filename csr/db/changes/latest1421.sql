-- Please update version.sql too -- this keeps clean builds in sync
define version=1421
@update_header


DECLARE
	v_nullable VARCHAR2(1);
BEGIN
	-- Add missing nullable that wasn't in a clean script for a while 
	SELECT nullable 
	  INTO v_nullable
	  FROM all_tab_columns 
	 WHERE table_name = 'PRODUCT' 
	   AND owner= 'CHAIN' 
	   AND column_name='LAST_PUBLISHED_BY_USER_SID';	
	
	IF v_nullable = 'N' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.PRODUCT MODIFY (LAST_PUBLISHED_BY_USER_SID NULL)';
	END IF;
END;
/

@update_tail

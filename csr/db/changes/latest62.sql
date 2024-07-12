-- Please update version.sql too -- this keeps clean builds in sync
define version=62
@update_header

VARIABLE version NUMBER
BEGIN :version := 62; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
END;
/	


WHENEVER SQLERROR CONTINUE

-- delete all dupe vals  
BEGIN  
  FOR r IN (
	  SELECT *
	    FROM (
	    	SELECT val_id, MAX(val_id) OVER (PARTITION BY period_start_dtm, period_end_Dtm, ind_sid, region_sid) max_val_id,
		    	COUNT(*) OVER (PARTITION BY period_start_dtm, period_end_Dtm, ind_sid, region_sid) cnt
			  FROM VAL
	       )x
	   WHERE x.cnt > 1 AND x.val_id != max_val_id
    )
  LOOP
  	DELETE FROM VAL WHERE val_id = r.val_id;
  END LOOP;
END;   
/
commit;
   
-- stick a constraint on to stop this happening in future   
ALTER TABLE CSR.VAL ADD 
CONSTRAINT VAL_UNIQUE
 UNIQUE (IND_SID, PERIOD_END_DTM, PERIOD_START_DTM, REGION_SID)
 ENABLE
 VALIDATE


-- add indicator stuff
ALTER TABLE IND ADD (
    TOLERANCE_TYPE        NUMBER(2, 0)      DEFAULT 0 NOT NULL,
    PCT_UPPER_TOLERANCE   NUMBER(10, 4),
    PCT_LOWER_TOLERANCE   NUMBER(10, 4)
);


ALTER TABLE ind ADD CONSTRAINT ind_tolerance CHECK (tolerance_type = 0 OR (pct_upper_tolerance IS NOT NULL AND pct_lower_tolerance IS NOT NULL)); 


-- fix up new tolerance thing
BEGIN
	FOR r IN (
		SELECT ind_sid, lower_bracket, upper_bracket, 
			CASE MIN(
				CASE period 
			    	WHEN 'y' THEN comparison_offset*12 
			        WHEN 'q' THEN comparison_offset*3
			        WHEN 'm' THEN comparison_offset
			    END)
		        WHEN -12 THEN 2
		        ELSE 1 
		    END tolerance_type
		  FROM ind_window
		 GROUP BY ind_sid, lower_bracket, upper_bracket
	)
	LOOP
		UPDATE ind 
	       SET pct_lower_tolerance = r.lower_bracket,
	       	   pct_upper_tolerance = r.upper_bracket,
	           tolerance_type = r.tolerance_type
	     WHERE ind_sid = r.ind_sid;
	END LOOP;
END;
/
    
commit;





UPDATE version SET db_version = :version;
COMMIT;
PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT
EXIT

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=1159
@update_header

-- Set company_sid on region breakdown types where a company is set.
BEGIN
  FOR bt IN (
		SELECT app_sid, company_sid, breakdown_type_id
		  FROM ct.breakdown_type
		   WHERE is_hotspot = 1
         AND is_region = 1
	) LOOP 		
    UPDATE ct.breakdown_type
       SET company_sid = (SELECT company_sid FROM ct.breakdown WHERE app_sid = bt.app_sid AND breakdown_type_id = bt.breakdown_type_id AND rownum = 1)
     WHERE app_sid = bt.app_sid
       AND breakdown_type_id = bt.breakdown_type_id;
	END LOOP;	
END;
/

@update_tail
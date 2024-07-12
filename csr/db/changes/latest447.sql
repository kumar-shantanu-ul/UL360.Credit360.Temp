-- Please update version.sql too -- this keeps clean builds in sync
define version=447
@update_header

BEGIN
	For r IN (
		SELECT index_name
		  FROM all_indexes
		 WHERE OWNER = 'CSR'
		   AND table_name = 'DATAVIEW_IND_MEMBER'
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP INDEX' || r.index_name;
	END LOOP;

	For r IN (
		SELECT index_name
		  FROM all_indexes
		 WHERE OWNER = 'CSR'
		   AND table_name = 'DATAVIEW_REGION_MEMBER'
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP INDEX' || r.index_name;
	END LOOP;

	INSERT INTO calculation_type (calculation_type_id, description)
		VALUES (0, 'None');
	INSERT INTO calculation_type (calculation_type_id, description)
		VALUES (1, 'Percentage change');
	INSERT INTO calculation_type (calculation_type_id, description)
		VALUES (2, 'Previous period');
		
	FOR r IN (
		SELECT rim.app_sid, rim.range_sid, rim.ind_sid, rim.description
		  FROM range_ind_member rim
		  JOIN dataview d ON rim.range_sid = d.dataview_sid
	)
	LOOP
		INSERT INTO dataview_ind_member (app_sid, dataview_sid, ind_sid, calculation_type_id, description)
			VALUES  (r.app_sid, r.range_sid, r.ind_sid, 0, r.description);
	END LOOP;
	
	FOR r IN (
		SELECT rrm.app_sid, rrm.range_sid, rrm.region_sid
		  FROM range_region_member rrm
		  JOIN dataview d ON rrm.range_sid = d.dataview_sid
	)
	LOOP
		INSERT INTO dataview_region_member (app_sid, dataview_sid, region_sid)
			VALUES  (r.app_sid, r.range_sid, r.region_sid);
	END LOOP;
END;
/

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=1386
@update_header

ALTER TABLE CHEM.PROCESS_DESTINATION MODIFY CONSTRAINT FK_PROC_PROC_DEST DISABLE;
ALTER TABLE CHEM.SUBSTANCE_USE MODIFY CONSTRAINT FK_SUBST_RGN_SUBST_USE DISABLE;
ALTER TABLE CHEM.PROCESS MODIFY CONSTRAINT FK_SUBST_RGN_PROC DISABLE;
ALTER TABLE CHEM.SUBSTANCE_USE_FILE MODIFY CONSTRAINT FK_SUBST_USE_SUBST_USE_FILE DISABLE;

DECLARE
	v_substance_id				NUMBER:=0;
	v_substance_old_id			NUMBER:=0;
	v_count						NUMBER:=0;
	v_substance_cas_restricted	NUMBER:=0;
	v_waiver_status_id			NUMBER:=0;
BEGIN
	DBMS_OUTPUT.ENABLE(null);
	DBMS_OUTPUT.PUT_LINE('-- BEGIN --');

	v_count := 0;

	FOR r IN (
		SELECT DISTINCT ref, app_sid
		  FROM (
			SELECT substance_Id, ref, description, app_sid,
				   count(*) over (partition by ref, app_sid) cnt
			  FROM chem.substance
		) WHERE cnt > 1
	) LOOP
		BEGIN
			SELECT MAX(s.substance_id)
			  INTO v_substance_id
			  FROM chem.substance s
			 WHERE s.ref = r.ref
			   AND s.app_sid = r.app_sid
			 GROUP BY s.ref;
			 
			SELECT MIN(s.substance_id)
			  INTO v_substance_old_id
			  FROM chem.substance s
			 WHERE s.ref = r.ref
			   AND s.app_sid = r.app_sid
			 GROUP BY s.ref;
			 
			IF v_substance_old_id <> v_substance_id THEN
				BEGIN
					DBMS_OUTPUT.PUT_LINE('-- SUCCESSFULL: found new substance_id = ' || v_substance_id || ' for old substance_id = ' || v_substance_old_id);
					
					BEGIN
						UPDATE chem.substance_region
						   SET substance_id = v_substance_id
						 WHERE substance_id = v_substance_old_id;
					EXCEPTION
						WHEN DUP_VAL_ON_INDEX THEN
							DELETE FROM chem.substance_region WHERE substance_id = v_substance_old_id;
					END;
					
					UPDATE chem.substance_use_file
					   SET substance_id = v_substance_id
					 WHERE substance_id = v_substance_old_id;
					
					UPDATE chem.substance_use
					   SET substance_id = v_substance_id
					 WHERE substance_id = v_substance_old_id;
					 
					UPDATE chem.process_destination
					   SET substance_id = v_substance_id
					 WHERE substance_id = v_substance_old_id;
					
					BEGIN
						UPDATE chem.process
						   SET substance_id = v_substance_id
						 WHERE substance_id = v_substance_old_id;
					EXCEPTION
						WHEN DUP_VAL_ON_INDEX THEN
							DELETE FROM chem.process WHERE substance_id = v_substance_old_id;
					END;
					
					BEGIN
						UPDATE chem.substance_region 
						   SET substance_id = v_substance_id
						 WHERE substance_id = v_substance_old_id;
					EXCEPTION
						WHEN DUP_VAL_ON_INDEX THEN
							DELETE FROM chem.substance_region WHERE substance_id = v_substance_old_id;
					END;
					
					DELETE FROM chem.substance_cas WHERE substance_id = v_substance_old_id;
					
					DELETE FROM chem.substance_file WHERE substance_id = v_substance_old_id;
					
					DELETE FROM chem.substance WHERE substance_id = v_substance_old_id;
					
					v_count := v_count + 1;
				EXCEPTION
					WHEN OTHERS THEN
						DBMS_OUTPUT.PUT_LINE('FAILED: ' || r.ref || ' -- ' || SQLERRM);
				END;
			END IF;
		 EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		 END;
	END LOOP;
	
	DBMS_OUTPUT.PUT_LINE('-- TOTAL PROCESSED: ' || v_count);
	DBMS_OUTPUT.PUT_LINE('-- END --');
END;
/

COMMIT;

ALTER TABLE CHEM.PROCESS_DESTINATION MODIFY CONSTRAINT FK_PROC_PROC_DEST ENABLE;
ALTER TABLE CHEM.SUBSTANCE_USE MODIFY CONSTRAINT FK_SUBST_RGN_SUBST_USE ENABLE;
ALTER TABLE CHEM.PROCESS MODIFY CONSTRAINT FK_SUBST_RGN_PROC ENABLE;
ALTER TABLE CHEM.SUBSTANCE_USE_FILE MODIFY CONSTRAINT FK_SUBST_USE_SUBST_USE_FILE ENABLE;

ALTER TABLE CHEM.SUBSTANCE DROP CONSTRAINT UK_SUBSTANCE;
ALTER TABLE CHEM.SUBSTANCE ADD CONSTRAINT UK_SUBSTANCE UNIQUE (APP_SID, REF);

@update_tail
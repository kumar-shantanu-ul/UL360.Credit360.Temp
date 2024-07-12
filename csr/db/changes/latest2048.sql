-- Please update version.sql too -- this keeps clean builds in sync
define version=2048
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Save shared region sets', 0);
INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Save shared indicator sets', 0);

ALTER TABLE csr.tpl_report_tag_ind ADD interval VARCHAR2(32 BYTE);

ALTER TABLE csr.tpl_report_tag_eval ADD interval VARCHAR2(32 BYTE);

ALTER TABLE csr.tpl_report_tag_logging_form ADD interval VARCHAR2(32 BYTE);

ALTER TABLE csr.tpl_report_tag_dataview ADD interval VARCHAR2(32 BYTE);

ALTER TABLE csr.tpl_report_non_compl ADD interval VARCHAR2(32 BYTE);

-- Ensure that region / indicator sets have unique names per user by renaming old sets
DECLARE
	v_count		NUMBER;
BEGIN
	FOR r IN (
		SELECT app_sid, owner_sid, name
		  FROM csr.region_set
		 WHERE disposal_dtm IS NULL
		 GROUP BY app_sid, owner_sid, name
		HAVING COUNT(*) > 1
		) 
	LOOP
		v_count := 0;
		FOR s IN (
			SELECT *
			  FROM csr.region_set
			 WHERE app_sid = r.app_sid and owner_sid = r.owner_sid AND name = r.name
			 ORDER BY region_set_id DESC
			)
		LOOP
			IF v_count > 0 THEN
				UPDATE csr.region_set
				   SET name = name || '_' || v_count
				 WHERE region_set_id = s.region_set_id;
			END IF;
			v_count := v_count + 1;
		END LOOP;
	END LOOP;
END;
/

ALTER TABLE csr.region_set ADD UNIQUE(app_sid, owner_sid, name, disposal_dtm);

DECLARE
	v_count		NUMBER;
BEGIN
	FOR r IN (
		SELECT app_sid, owner_sid, name
		  FROM csr.ind_set
		 WHERE disposal_dtm IS NULL
		 GROUP BY app_sid, owner_sid, name
		HAVING COUNT(*) > 1
		) 
	LOOP
		v_count := 0;
		FOR s IN (
			SELECT *
			  FROM csr.ind_set
			 WHERE app_sid = r.app_sid and owner_sid = r.owner_sid AND name = r.name
			 ORDER BY ind_set_id DESC
			)
		LOOP
			IF v_count > 0 THEN
				UPDATE csr.ind_set
				   SET name = name || '_' || v_count
				 WHERE ind_set_id = s.ind_set_id;
			END IF;
			v_count := v_count + 1;
		END LOOP;
	END LOOP;
END;
/

ALTER TABLE csr.ind_set ADD UNIQUE(app_sid, owner_sid, name, disposal_dtm);

@..\region_set_pkg;
@..\indicator_set_pkg;
@..\templated_report_pkg;
@..\region_set_body;
@..\indicator_set_body;
@..\templated_report_body;

@update_tail
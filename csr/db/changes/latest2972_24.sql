-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=24
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE cms.tab ADD is_basedata NUMBER(1) DEFAULT(0) NOT NULL;

ALTER TABLE cms.tab ADD CONSTRAINT CK_TAB_IS_BASEDATA_1_0 CHECK (is_basedata IN (0,1));

ALTER TABLE cms.ck_cons ADD (
	constraint_owner	VARCHAR2(30),
	constraint_name		VARCHAR2(30)
);
ALTER TABLE cms.fk_cons ADD (
	constraint_owner	VARCHAR2(30),
	constraint_name		VARCHAR2(30)
);
ALTER TABLE cms.uk_cons ADD (
	constraint_owner	VARCHAR2(30),
	constraint_name		VARCHAR2(30)
);

ALTER TABLE csrimp.cms_tab ADD is_basedata NUMBER(1) NOT NULL;

ALTER TABLE csrimp.cms_tab ADD CONSTRAINT CK_TAB_IS_BASEDATA_1_0 CHECK (is_basedata IN (0,1));
ALTER TABLE csrimp.cms_ck_cons ADD (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
ALTER TABLE csrimp.cms_fk_cons ADD (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
ALTER TABLE csrimp.cms_uk_cons ADD (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);

BEGIN
	FOR x IN (SELECT app_sid,fk_cons_id,owner, constraint_name
		FROM (SELECT fk.app_sid, fk.fk_cons_id, fk.owner,
				DECODE(t.managed, 0, fk.table_name, 1, 'C$'||fk.table_name) table_name, fk.table_name tab_name,
				LISTAGG(fk.column_name, ', ') WITHIN GROUP (ORDER BY pos) column_names, fk.uk_cons_id, fk.r_owner,
				DECODE(tr.managed, 0, fk.r_table_name, 1, 'C$'||fk.r_table_name) r_table_name, fk.r_table_name r_tab_name,
				LISTAGG(fk.r_column_name, ', ') WITHIN GROUP (ORDER BY pos) r_column_names
		  FROM cms.fk fk
		  JOIN cms.tab t ON fk.fk_tab_sid = t.tab_sid
		  JOIN cms.tab tr ON fk.r_tab_sid = tr.tab_sid
		 GROUP BY fk.app_sid, fk.fk_cons_id, fk.fk_tab_sid, fk.owner, t.managed, fk.table_name,
				  fk.uk_cons_id, fk.r_owner, fk.r_tab_sid, tr.managed, fk.r_table_name)
		LEFT JOIN (WITH ac AS (
			SELECT constraint_type, owner, constraint_name, table_name, r_owner, r_constraint_name,
					LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY position) column_names
			  FROM all_constraints
			  JOIN all_cons_columns USING(owner, table_name, constraint_name)
			 GROUP BY constraint_type, owner, constraint_name, table_name, r_owner, r_constraint_name)
			SELECT ac.owner, ac.constraint_name, ac.table_name, ac.column_names, acr.owner r_owner,
					acr.table_name r_table_name, acr.column_names r_column_names
			  FROM ac ac
			  JOIN ac acr ON ac.r_owner = acr.owner AND ac.r_constraint_name = acr.constraint_name
			 WHERE ac.constraint_type = 'R') 
	   USING (owner, table_name, column_names, r_owner, r_table_name, r_column_names))
	LOOP
		UPDATE cms.fk_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE fk_cons_id= x.fk_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/

BEGIN
	FOR x in (SELECT fk_cons_id, owner, app_sid, 'FK_'||
			CASE
				WHEN LENGTH(tab_name)+LENGTH(r_tab_name)<=23 THEN tab_name||'_'||r_tab_name
				ELSE
					CASE
						WHEN LENGTH(r_tab_name)>12 THEN SUBSTR(tab_name,1,12)||'_'||SUBSTR(r_tab_name,1,11)
						ELSE SUBSTR(tab_name,1,23-LENGTH(r_tab_name))||'_'||r_tab_name
					END
			END constraint_name
		FROM (SELECT fk.app_sid, fk.fk_cons_id, fk.owner,
				DECODE(t.managed, 0, fk.table_name, 1, 'C$'||fk.table_name) table_name, fk.table_name tab_name,
				LISTAGG(fk.column_name, ', ') WITHIN GROUP (ORDER BY pos) column_names, fk.uk_cons_id, fk.r_owner,
				DECODE(tr.managed, 0, fk.r_table_name, 1, 'C$'||fk.r_table_name) r_table_name, fk.r_table_name r_tab_name,
				LISTAGG(fk.r_column_name, ', ') WITHIN GROUP (ORDER BY pos) r_column_names
		  FROM cms.fk fk
		  JOIN cms.tab t ON fk.fk_tab_sid = t.tab_sid
		  JOIN cms.tab tr ON fk.r_tab_sid = tr.tab_sid
		 WHERE fk_cons_id IN (SELECT fk_cons_id
			FROM cms.fk_cons
		   WHERE constraint_name IS NULL)
		 GROUP BY fk.app_sid, fk.fk_cons_id, fk.fk_tab_sid, fk.owner, t.managed, fk.table_name,
				  fk.uk_cons_id, fk.r_owner, fk.r_tab_sid, tr.managed, fk.r_table_name))
	LOOP
		UPDATE cms.fk_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE fk_cons_id= x.fk_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/

DECLARE
	v_suffix NUMBER(10);
BEGIN
	FOR x in (SELECT app_sid, constraint_owner, constraint_name, count(*) FROM cms.fk_cons
		GROUP BY app_sid, constraint_owner, constraint_name 
	   HAVING COUNT(*) >1)
	LOOP
		v_suffix := 1;
		FOR y IN(SELECT app_sid, fk_cons_id 
			FROM cms.fk_cons 
		   WHERE constraint_name = x.constraint_name 
			 AND constraint_owner = x.constraint_owner 
			 AND app_sid = x.app_sid)
		LOOP
			UPDATE cms.fk_cons
			   SET constraint_name = constraint_name || '_' || v_suffix 
			 WHERE fk_cons_id = y.fk_cons_id 
			   AND app_sid= y.app_sid;
			v_suffix := v_suffix+ 1;
		END LOOP;
	END LOOP;
END;
/

/*
 * all_constraints.search_condition is returned as a LONG datatype, which cannot easily
 * be compared to a CLOB or converted to a CLOB. The TO_CLOB function can only be used
 * to convert the column when inserting into a CLOB column, so create a temporary table
 * to store the data as a CLOB and allow comparison  with cms.ck_cons.search_condition.
 */
CREATE TABLE cms.us3942_check_constraint AS (
	SELECT owner, table_name, constraint_name, TO_LOB(search_condition) search_condition
	  FROM all_constraints
	 WHERE constraint_type = 'C'
	   AND (owner, table_name) IN (SELECT owner, table_name FROM cms.ck)
	);

BEGIN
	FOR x IN (SELECT t1.app_sid, t1.ck_cons_id, t1.owner, t1.tab_name, t1.column_names, t2.constraint_name
		FROM (SELECT app_sid, ck_cons_id, oracle_schema owner, managed, oracle_table tab_name, column_names, search_condition,
			     DECODE(managed,0,oracle_table,'C$'||oracle_table) table_name
			FROM cms.ck_cons
			JOIN cms.tab USING (app_sid, tab_sid)
			JOIN (SELECT app_sid, ck_cons_id, LISTAGG(column_name,'_') WITHIN GROUP (ORDER BY column_name) column_names
				FROM cms.ck
			   GROUP BY app_sid, ck_cons_id) 
		   USING (app_sid, ck_cons_id)) t1
		LEFT JOIN (SELECT owner, table_name, constraint_name, search_condition, column_names
			FROM CMS.US3942_CHECK_CONSTRAINT
			JOIN (SELECT owner, table_name, constraint_name, LISTAGG(column_name, '_') WITHIN GROUP (ORDER BY column_name) column_names
				FROM all_cons_columns
			   GROUP BY owner, constraint_name, table_name) 
		   USING (owner, constraint_name, table_name)) t2 
		  ON t1.owner = t2.owner 
		 AND t1.table_name = t2.table_name 
		 AND t2.column_names = t1.column_names 
		 AND dbms_lob.compare(t1.search_condition, t2.search_condition) = 0)
	LOOP
		UPDATE cms.ck_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE ck_cons_id= x.ck_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/


BEGIN
	FOR x in (SELECT ck_cons_id, owner, app_sid, 'CK_'||
				CASE
					WHEN LENGTH(t1.tab_name)+LENGTH(t1.column_names)<=23 THEN t1.tab_name||'_'||t1.column_names
					ELSE
						CASE
							WHEN LENGTH(t1.column_names)>12 THEN SUBSTR(t1.tab_name,1,12)||'_'||SUBSTR(t1.column_names,1,11)
							ELSE SUBSTR(t1.tab_name,1,23-LENGTH(t1.column_names))||'_'||t1.column_names
						END
				END constraint_name
		FROM (SELECT app_sid, ck_cons_id, oracle_schema owner, managed, oracle_table tab_name, column_names, search_condition,
			     DECODE(managed,0,oracle_table,'C$'||oracle_table) table_name
			FROM cms.ck_cons
			JOIN cms.tab USING (app_sid, tab_sid)
			JOIN (SELECT app_sid, ck_cons_id, LISTAGG(column_name,'_') WITHIN GROUP (ORDER BY column_name) column_names
				FROM cms.ck
			   GROUP BY app_sid, ck_cons_id) 
		   USING (app_sid, ck_cons_id)) t1
		   WHERE ck_cons_id IN (SELECT ck_cons_id
			FROM cms.ck_cons
		   WHERE constraint_name IS NULL))
	LOOP
		UPDATE cms.ck_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE ck_cons_id= x.ck_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/

DECLARE
	v_suffix NUMBER(10);
BEGIN
	FOR x in (SELECT app_sid, constraint_owner, constraint_name, count(*) FROM cms.ck_cons
		GROUP BY app_sid, constraint_owner, constraint_name 
	   HAVING COUNT(*) >1)
	LOOP
		v_suffix := 1;
		FOR y IN(SELECT app_sid, ck_cons_id 
			FROM cms.ck_cons 
		   WHERE constraint_name = x.constraint_name 
			 AND constraint_owner = x.constraint_owner 
			 AND app_sid = x.app_sid)
		LOOP
			UPDATE cms.ck_cons
			   SET constraint_name = constraint_name || '_' || v_suffix 
			 WHERE ck_cons_id = y.ck_cons_id 
			   AND app_sid= y.app_sid;
			v_suffix := v_suffix+ 1;
		END LOOP;
	END LOOP;
END;
/

DROP TABLE cms.us3942_check_constraint;

BEGIN
	FOR x IN (SELECT app_sid,uk_cons_id,owner, constraint_name
		FROM (SELECT uk.app_sid, uk.uk_cons_id, uk.owner, table_name tab_name,
				 DECODE(t.managed, 0, uk.table_name, 1, 'C$'||uk.table_name) table_name,
				 LISTAGG(uk.column_name, '_') WITHIN GROUP (ORDER BY uk.pos) column_names
			FROM cms.uk
			JOIN cms.tab t ON uk.app_sid = t.app_sid AND uk.uk_tab_sid = t.tab_sid
		   GROUP BY uk.app_sid, uk.uk_cons_id, uk.owner, t.managed, uk.table_name)
		LEFT JOIN (SELECT constraint_name, owner, table_name, LISTAGG(column_name, '_') WITHIN GROUP (ORDER BY position) column_names
			FROM all_constraints
			JOIN all_cons_columns USING (owner, table_name, constraint_name)
		   WHERE constraint_type = 'U'
		   GROUP BY constraint_name, owner, table_name) 
	   USING (owner, table_name, column_names))
	LOOP
		UPDATE cms.uk_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE uk_cons_id= x.uk_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/

BEGIN
	FOR x in (SELECT uk_cons_id, owner, app_sid,  CASE
				WHEN pk_cons_id = uk_cons_id THEN CASE
					WHEN LENGTH(tab_name) <= 23 THEN 'PK_' || tab_name
					ELSE 'PK_' || SUBSTR(tab_name, 23)
				END
				ELSE 'UK_'|| CASE
						WHEN LENGTH(tab_name)+LENGTH(column_names)<=23 THEN tab_name||'_'||column_names
						ELSE
							CASE
								WHEN LENGTH(column_names)>12 THEN SUBSTR(tab_name,1,12)||'_'||SUBSTR(column_names,1,11)
								ELSE SUBSTR(tab_name,1,23-LENGTH(column_names))||'_'||column_names
							END
					END 
				END constraint_name
		FROM (SELECT uk.app_sid, uk.uk_cons_id, uk.owner, table_name tab_name, t.pk_cons_id,
				 DECODE(t.managed, 0, uk.table_name, 1, 'C$'||uk.table_name) table_name,
				 LISTAGG(uk.column_name, '_') WITHIN GROUP (ORDER BY uk.pos) column_names
			FROM cms.uk
			JOIN cms.tab t ON uk.app_sid = t.app_sid AND uk.uk_tab_sid = t.tab_sid
		   GROUP BY uk.app_sid, uk.uk_cons_id, uk.owner, t.managed, uk.table_name, t.pk_cons_id)
	   WHERE uk_cons_id IN (SELECT uk_cons_id
			FROM cms.uk_cons
		   WHERE constraint_name IS NULL))
	LOOP
		UPDATE cms.uk_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE uk_cons_id= x.uk_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/

DECLARE
	v_suffix NUMBER(10);
BEGIN
	FOR x in (SELECT app_sid, constraint_owner, constraint_name, count(*) FROM cms.uk_cons
		GROUP BY app_sid, constraint_owner, constraint_name 
	   HAVING COUNT(*) >1)
	LOOP
		v_suffix := 1;
		FOR y IN(SELECT app_sid, uk_cons_id 
			FROM cms.uk_cons 
		   WHERE constraint_name = x.constraint_name 
			 AND constraint_owner = x.constraint_owner 
			 AND app_sid = x.app_sid)
		LOOP
			UPDATE cms.uk_cons
			   SET constraint_name = constraint_name || '_' || v_suffix 
			 WHERE uk_cons_id = y.uk_cons_id 
			   AND app_sid= y.app_sid;
			v_suffix := v_suffix+ 1;
		END LOOP;
	END LOOP;
END;
/

UPDATE cms.fk_cons fk
   SET fk.constraint_name = 'FK_' || fk_cons_id,
   fk.constraint_owner = (
	SELECT oracle_schema 
	  FROM cms.tab t 
	  WHERE t.tab_sid = fk.tab_sid
   )
 WHERE fk.constraint_name IS NULL 
    OR fk.constraint_owner IS NULL;

UPDATE cms.ck_cons ck
   SET ck.constraint_name = 'CK_' || ck_cons_id,
   ck.constraint_owner = (
	SELECT oracle_schema 
	  FROM cms.tab t 
	  WHERE t.tab_sid = ck.tab_sid
   )
 WHERE ck.constraint_name IS NULL 
    OR ck.constraint_owner IS NULL;

UPDATE cms.uk_cons uk
   SET uk.constraint_name = 'UK_' || uk_cons_id,
   uk.constraint_owner = (
	SELECT oracle_schema 
	  FROM cms.tab t 
	  WHERE t.tab_sid = uk.tab_sid
   )
 WHERE uk.constraint_name IS NULL 
    OR uk.constraint_owner IS NULL;

ALTER TABLE cms.fk_cons MODIFY (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
ALTER TABLE cms.fk_cons ADD CONSTRAINT UK_FK_CONS_OWNER_NAME UNIQUE (app_sid, constraint_owner, constraint_name);

ALTER TABLE cms.ck_cons MODIFY (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
ALTER TABLE cms.ck_cons ADD CONSTRAINT UK_CK_CONS_OWNER_NAME UNIQUE (app_sid, constraint_owner, constraint_name);

ALTER TABLE cms.uk_cons MODIFY (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
ALTER TABLE cms.uk_cons ADD CONSTRAINT UK_UK_CONS_OWNER_NAME UNIQUE (app_sid, constraint_owner, constraint_name);

-- *** Grants ***
GRANT SELECT ON csr.property_options to cms;
GRANT SELECT ON csr.delegation_grid to cms;
GRANT SELECT ON csr.v$ind to cms;
GRANT SELECT ON csr.aggregate_ind_group to cms;
GRANT SELECT ON csr.aggregate_ind_group_member to cms;
GRANT select_catalog_role TO cms;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/export_pkg
@../../../aspen2/cms/db/tab_pkg
@../flow_pkg

@../../../aspen2/cms/db/export_body
@../../../aspen2/cms/db/tab_body
@../../../aspen2/cms/db/form_body
@../flow_body
@../csrimp/imp_body

@update_tail

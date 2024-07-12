-- Please update version.sql too -- this keeps clean builds in sync
define version=400
@update_header

UPDATE source_type_error_code 
  SET detail_url = '/csr/site/dataExplorer4/dataNavigator/dataNavigator.acds?valId=%VALID%'
 WHERE error_code = 0 
   AND source_type_id = 5;

-- this appears to have been done already
/*
ALTER TABLE TPL_REPORT ADD (
	INTERVAL	VARCHAR2(1)	DEFAULT 'y' NOT NULL,
	CONSTRAINT CHK_TPL_REPORT_INTERVAL CHECK (INTERVAL IN ('m','q','h','y'))
);
*/

ALTER TABLE TPL_REPORT_TAG_IND ADD (
	MONTH_OFFSET      NUMBER(10, 0)     DEFAULT 0 NOT NULL
);

ALTER TABLE TPL_REPORT_TAG_EVAL ADD (
	MONTH_OFFSET      NUMBER(10, 0)     DEFAULT 0 NOT NULL
);

-- this appears to have been done already
/*
ALTER TABLE TPL_REPORT_TAG_DATAVIEW ADD (
	MONTH_OFFSET	NUMBER(10,0) DEFAULT -12 NOT NULL,
	MONTH_DURATION	NUMBER(10,0) DEFAULT 12 NOT NULL
);
*/






-- deal with ye olde flaky ER/Studio changing constraint naming issue
BEGIN
	FOR r IN (
		SELECT c.table_name, c.constraint_name
		 FROM user_constraints c, user_constraints p
		WHERE c.table_name LIKE 'TPL_REPORT_TAG_%' 
		  and c.constraint_type = 'R'
		  AND c.r_constraint_name = p.constraint_name
		  AND p.table_name = 'TPL_REPORT_TAG'
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/
 
ALTER TABLE TPL_REPORT_TAG_DATAVIEW DROP CONSTRAINT RefDATAVIEW907;
ALTER TABLE TPL_REPORT_TAG_DV_REGION DROP CONSTRAINT RefRANGE_REGION_MEMBER1249; 
ALTER TABLE TPL_REPORT_TAG_EVAL_COND DROP CONSTRAINT RefTPL_REPORT_TAG_EVAL1260;



-- SEQUENCE: TPL_REPORT_TAG_DATAVIEW_ID_SEQ 
--

CREATE SEQUENCE TPL_REPORT_TAG_DATAVIEW_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- 
-- SEQUENCE: TPL_REPORT_TAG_EVAL_ID_SEQ 
--

CREATE SEQUENCE TPL_REPORT_TAG_EVAL_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- 
-- SEQUENCE: TPL_REPORT_TAG_IND_ID_SEQ 
--

CREATE SEQUENCE TPL_REPORT_TAG_IND_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


ALTER TABLE TPL_REPORT_TAG ADD (
    TPL_REPORT_TAG_IND_ID         NUMBER(10, 0),
    TPL_REPORT_TAG_EVAL_ID        NUMBER(10, 0),
    TPL_REPORT_TAG_DATAVIEW_ID    NUMBER(10, 0)
);

alter table tpl_report_tag_ind drop primary key cascade drop index;
alter table tpl_report_tag_eval drop primary key cascade drop index;
alter table tpl_report_tag_dataview drop primary key cascade drop index;
alter table tpl_report_tag_dv_region drop primary key cascade drop index;


/*************************************
 TPL_REPORT_TAG_DATAVIEW 
 *************************************/

ALTER TABLE TPL_REPORT_TAG_DATAVIEW ADD (
	TPL_REPORT_TAG_DATAVIEW_ID    NUMBER(10, 0)
);

UPDATE TPL_REPORT_TAG_DATAVIEW SET TPL_REPORT_TAG_DATAVIEW_ID  = TPL_REPORT_TAG_DATAVIEW_ID_SEQ.NEXTVAL;

ALTER TABLE TPL_REPORT_TAG_DATAVIEW MODIFY TPL_REPORT_TAG_DATAVIEW_ID NOT NULL;

ALTER TABLE TPL_REPORT_TAG_DATAVIEW ADD CONSTRAINT PK_TPL_REPORT_TAG_DATAVIEW PRIMARY KEY (APP_SID, TPL_REPORT_TAG_DATAVIEW_ID);

-- fix up child table: TPL_REPORT_TAG_DV_REGION

ALTER TABLE TPL_REPORT_TAG_DV_REGION ADD (
    TPL_REPORT_TAG_DATAVIEW_ID    NUMBER(10, 0)
);

BEGIN
	-- propagate ids down
	FOR r IN (
		SELECT TPL_REPORT_TAG_DATAVIEW_ID, TAG, TPL_REPORT_SID
		  FROM TPL_REPORT_TAG_DATAVIEW 
	)
	LOOP
		UPDATE tpl_report_tag
		   SET tpl_report_tag_dataview_id = r.TPL_REPORT_TAG_DATAVIEW_ID
		 WHERE tag = r.tag
		   AND tpl_report_sid = r.tpl_report_sid;
		--
		UPDATE TPL_REPORT_TAG_DV_REGION  
		   SET TPL_REPORT_TAG_DATAVIEW_ID  = r.TPL_REPORT_TAG_DATAVIEW_ID
		 WHERE TAG = r.TAG
		   AND TPL_REPORT_SID = r.TPL_REPORT_SID;
	END LOOP;
END;
/

ALTER TABLE TPL_REPORT_TAG_DV_REGION MODIFY TPL_REPORT_TAG_DATAVIEW_ID  NOT NULL;

ALTER TABLE TPL_REPORT_TAG_DV_REGION ADD CONSTRAINT PK_TPL_RPT_RAG_RV_REGION PRIMARY KEY (APP_SID, DATAVIEW_SID, REGION_SID, TPL_REPORT_TAG_DATAVIEW_ID);

-- clean up
ALTER TABLE TPL_REPORT_TAG_DV_REGION DROP COLUMN TPL_REPORT_SID;
ALTER TABLE TPL_REPORT_TAG_DV_REGION DROP COLUMN TAG;
ALTER TABLE TPL_REPORT_TAG_DATAVIEW DROP COLUMN TPL_REPORT_SID;
ALTER TABLE TPL_REPORT_TAG_DATAVIEW DROP COLUMN TAG;

 
 

/*************************************
 TPL_REPORT_TAG_EVAL
 *************************************/



ALTER TABLE TPL_REPORT_TAG_EVAL ADD (
    TPL_REPORT_TAG_EVAL_ID    NUMBER(10, 0)
);

UPDATE tpl_report_tag_eval SET tpl_report_tag_eval_id = tpl_report_tag_eval_id_seq.nextval;
  
ALTER TABLE TPL_REPORT_TAG_EVAL MODIFY TPL_REPORT_TAG_EVAL_ID NOT NULL;

ALTER TABLE TPL_REPORT_TAG_EVAL ADD CONSTRAINT PK_TPL_REPORT_TAG_EVAL PRIMARY KEY (TPL_REPORT_TAG_EVAL_ID, APP_SID);
 
-- fix up child table: TPL_REPORT_TAG_EVAL_COND
ALTER TABLE TPL_REPORT_TAG_EVAL_COND ADD (
    TPL_REPORT_TAG_EVAL_ID    NUMBER(10, 0)
);


BEGIN
	-- propagate ids down
	FOR r IN (
		SELECT TPL_REPORT_TAG_EVAL_ID, TAG, TPL_REPORT_SID
		  FROM TPL_REPORT_TAG_EVAL 
	)
	LOOP		
		UPDATE tpl_report_tag
		   SET tpl_report_tag_eval_id = r.TPL_REPORT_TAG_EVAL_ID
		 WHERE tag = r.tag
		   AND tpl_report_sid = r.tpl_report_sid;
		--   
		UPDATE TPL_REPORT_TAG_EVAL_COND  
		   SET TPL_REPORT_TAG_EVAL_ID  = r.TPL_REPORT_TAG_EVAL_ID
		 WHERE TAG = r.TAG
		   AND TPL_REPORT_SID = r.TPL_REPORT_SID;
	END LOOP;
END;
/

ALTER TABLE TPL_REPORT_TAG_EVAL_COND MODIFY TPL_REPORT_TAG_EVAL_ID NOT NULL;

 
ALTER TABLE TPL_REPORT_TAG ADD CONSTRAINT RefTPL_REPORT_TAG_EVAL1257
    FOREIGN KEY (TPL_REPORT_TAG_EVAL_ID, APP_SID)
    REFERENCES TPL_REPORT_TAG_EVAL(TPL_REPORT_TAG_EVAL_ID, APP_SID)
;


-- cleanup
ALTER TABLE TPL_REPORT_TAG_EVAL DROP COLUMN TPL_REPORT_SID;
ALTER TABLE TPL_REPORT_TAG_EVAL DROP COLUMN TAG;
ALTER TABLE TPL_REPORT_TAG_EVAL_COND DROP COLUMN TPL_REPORT_SID;
ALTER TABLE TPL_REPORT_TAG_EVAL_COND DROP COLUMN TAG;





/*************************************
 TPL_REPORT_TAG_IND
 *************************************/


ALTER TABLE TPL_REPORT_TAG_IND ADD (
    TPL_REPORT_TAG_IND_ID    NUMBER(10, 0)
);


UPDATE TPL_REPORT_TAG_IND SET TPL_REPORT_TAG_IND_ID = TPL_REPORT_TAG_IND_ID_SEQ.NEXTVAL;

ALTER TABLE TPL_REPORT_TAG_IND MODIFY TPL_REPORT_TAG_IND_ID NOT NULL;

ALTER TABLE TPL_REPORT_TAG_IND ADD (
    CONSTRAINT PK_TPL_RPT_TAG_IND PRIMARY KEY (TPL_REPORT_TAG_IND_ID, APP_SID)
);


BEGIN
	-- propagate ids down
	FOR r IN (
		SELECT TPL_REPORT_TAG_IND_ID, TAG, TPL_REPORT_SID
		  FROM TPL_REPORT_TAG_IND
	)
	LOOP		
		UPDATE tpl_report_tag
		   SET tpl_report_tag_ind_id = r.TPL_REPORT_TAG_IND_ID
		 WHERE tag = r.tag
		   AND tpl_report_sid = r.tpl_report_sid;
	END LOOP;
END;
/


ALTER TABLE TPL_REPORT_TAG_IND DROP COLUMN TPL_REPORT_SID;
ALTER TABLE TPL_REPORT_TAG_IND DROP COLUMN TAG;



ALTER TABLE TPL_REPORT_TAG ADD CONSTRAINT CT_TPL_REPORT_TAG CHECK (
	(tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL)
	OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL)
	OR (tag_type IN (2,3) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL)
);

-- INDEX: AK_TPL_RPT_TAG_DV 
--
CREATE UNIQUE INDEX CT_TPL_RPT_TAG_DV ON TPL_REPORT_TAG_DATAVIEW(APP_SID, TPL_REPORT_TAG_DATAVIEW_ID, DATAVIEW_SID);
 


 
ALTER TABLE TPL_REPORT_TAG ADD CONSTRAINT RefTPL_REPORT_TAG_IND1413 
    FOREIGN KEY (TPL_REPORT_TAG_IND_ID, APP_SID)
    REFERENCES TPL_REPORT_TAG_IND(TPL_REPORT_TAG_IND_ID, APP_SID)
;


ALTER TABLE TPL_REPORT_TAG ADD CONSTRAINT RefTPL_REPORT_TAG_DATAVIEW1414 
    FOREIGN KEY (APP_SID, TPL_REPORT_TAG_DATAVIEW_ID)
    REFERENCES TPL_REPORT_TAG_DATAVIEW(APP_SID, TPL_REPORT_TAG_DATAVIEW_ID)
;

ALTER TABLE TPL_REPORT_TAG_DATAVIEW ADD CONSTRAINT RefDATAVIEW907 
    FOREIGN KEY (APP_SID, DATAVIEW_SID)
    REFERENCES CSR.DATAVIEW(APP_SID, DATAVIEW_SID)
;

 

ALTER TABLE TPL_REPORT_TAG_DV_REGION ADD CONSTRAINT RefDATAVIEW1416 
    FOREIGN KEY (APP_SID, DATAVIEW_SID)
    REFERENCES CSR.DATAVIEW(APP_SID, DATAVIEW_SID)
;


ALTER TABLE TPL_REPORT_TAG_EVAL ADD CONSTRAINT RefCUSTOMER1417 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;
 
ALTER TABLE TPL_REPORT_TAG_EVAL_COND ADD CONSTRAINT RefTPL_REPORT_TAG_EVAL1260 
    FOREIGN KEY (TPL_REPORT_TAG_EVAL_ID, APP_SID)
    REFERENCES TPL_REPORT_TAG_EVAL(TPL_REPORT_TAG_EVAL_ID, APP_SID)
;
 
 
ALTER TABLE TPL_REPORT_TAG_IND ADD CONSTRAINT RefCUSTOMER1418 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

 
ALTER TABLE TPL_REPORT_TAG_DV_REGION ADD CONSTRAINT RefRANGE_REGION_MEMBER1249 
    FOREIGN KEY (APP_SID, DATAVIEW_SID, REGION_SID)
    REFERENCES CSR.RANGE_REGION_MEMBER(APP_SID, RANGE_SID, REGION_SID)
;
 
-- XXX: this doesn't work for some reason
/*
ALTER TABLE TPL_REPORT_TAG_DV_REGION ADD CONSTRAINT RefTPL_REPORT_TAG_DATAVIEW1248 
    FOREIGN KEY (APP_SID, TPL_REPORT_TAG_DATAVIEW_ID, DATAVIEW_SID)
    REFERENCES TPL_REPORT_TAG_DATAVIEW(APP_SID, TPL_REPORT_TAG_DATAVIEW_ID, DATAVIEW_SID)
;
*/
 



@update_tail

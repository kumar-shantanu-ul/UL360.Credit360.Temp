-- Please update version.sql too -- this keeps clean builds in sync
define version=26
@update_header

CREATE TABLE REGION_TREE(
    REGION_TREE_ROOT_SID    NUMBER(10, 0)    NOT NULL,
    CSR_ROOT_SID            NUMBER(10, 0)    NOT NULL,
    LAST_RECALC_DTM         DATE,
    IS_PRIMARY              NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CONSTRAINT PK148 PRIMARY KEY (REGION_TREE_ROOT_SID)
)
;

ALTER TABLE REGION_TREE ADD CONSTRAINT RefCUSTOMER243 
    FOREIGN KEY (CSR_ROOT_SID)
    REFERENCES CUSTOMER(CSR_ROOT_SID)
;

CREATE INDEX IDX_REGION_PARSED_LINK ON REGION(NVL(LINK_TO_REGION_SID, REGION_SID));


DECLARE
	v_region_root_sid security_pkg.T_SID_ID;
	v_act varchar(38);
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	FOR r IN (SELECT csr_root_sid FROM CUSTOMER)
	LOOP
		v_region_root_sid := securableobject_pkg.GetSIDFromPath(v_act, r.csr_root_sid, 'Regions');    	    
		INSERT INTO REGION_TREE
			(REGION_TREE_ROOT_SID, CSR_ROOT_SID, LAST_RECALC_DTM, IS_PRIMARY)
		VALUES
			(v_region_root_sid, r.csr_root_sid, NULL, 1);
	END LOOP;
END;
/




-- FOR NGT GROUP SPLIT TREE:
DECLARE
	v_host	VARCHAR2(255) := 'National Grid';
BEGIN
	INSERT INTO region_tree
		(region_tree_root_sid, csr_root_sid, is_primary)
	SELECT so.sid_id, rt.csr_root_sid, 0 
	  FROM SECURITY.securable_object so, region_tree rt, customer c 
	 WHERE so.parent_sid_id = rt.region_tree_root_sid 
	   AND rt.csr_root_sid = c.csr_root_sid
	   AND c.NAME=v_host;
	 --
	DELETE
	  FROM region_tree 
	 WHERE csr_root_sid = 
	 	(SELECT csr_root_sid FROM customer WHERE NAME=v_host)
	   AND IS_PRIMARY = 1;
	  --
	UPDATE region_tree 
	   SET is_primary = 1
	 WHERE region_tree_root_sid = 
		(SELECT MIN(region_tree_root_sid) 
		  FROM region_tree 
		 WHERE csr_root_sid = 
		 	(SELECT csr_root_sid FROM customer WHERE NAME=v_host));
END;
/


@update_tail

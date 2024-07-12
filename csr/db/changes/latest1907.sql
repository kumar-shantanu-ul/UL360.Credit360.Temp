-- Please update version.sql too -- this keeps clean builds in sync
define version=1907
@update_header

DECLARE
	v_count number;
BEGIN
	-- Add missing tables - if wood module not enabled
	SELECT count(*) 
	  INTO v_count
	  FROM all_tables
	 WHERE table_name = 'WOOD_PART_WOOD'
	   AND owner = 'SUPPLIER';	
	
	IF v_count = 0 THEN
		execute immediate 'CREATE TABLE SUPPLIER.WOOD_PART_WOOD(	PRODUCT_PART_ID         NUMBER(10, 0)     NOT NULL,
		SPECIES_CODE            VARCHAR2(32)      NOT NULL,
							REGION                  VARCHAR2(255),
							CERT_DOC_GROUP_ID       NUMBER(10, 0),
							FOREST_SOURCE_CAT_CODE  VARCHAR2(32)      NOT NULL,
							BLEACHING_PROCESS_ID    NUMBER(10, 0)     NOT NULL,
							WRME_WOOD_TYPE_ID       NUMBER(10, 0)     NOT NULL,
							CERT_SCHEME_ID          NUMBER(10, 0)     NOT NULL,
							COUNTRY_CODE            VARCHAR2(8)       NOT NULL,
							CONSTRAINT PK28 PRIMARY KEY (PRODUCT_PART_ID)
						)';
	END IF;
	
	-- Add missing tables - if wood module not enabled
	SELECT count(*) 
	  INTO v_count
	  FROM all_tables
	 WHERE table_name = 'FOREST_SOURCE_CAT'
	   AND owner = 'SUPPLIER';	
	
	IF v_count = 0 THEN
		execute immediate 'CREATE TABLE SUPPLIER.FOREST_SOURCE_CAT(
								FOREST_SOURCE_CAT_CODE    VARCHAR2(32)      NOT NULL,
								NAME                      VARCHAR2(256)     NOT NULL,
								DESCRIPTION               VARCHAR2(1024),
								CONSTRAINT PK55 PRIMARY KEY (FOREST_SOURCE_CAT_CODE)
							)';
	END IF;
	
	-- Add missing tables - if wood module not enabled
	SELECT count(*) 
	  INTO v_count
	  FROM all_tables
	 WHERE table_name = 'CERT_SCHEME_SOURCE_CAT_MAPPING'
	   AND owner = 'SUPPLIER';	
	
	-- about to drop
	IF v_count = 0 THEN
		execute immediate 'CREATE TABLE SUPPLIER.CERT_SCHEME_SOURCE_CAT_MAPPING(
								FOO VARCHAR2(32)      NOT NULL
							)';
	END IF;
	
	-- Add missing tables - if wood module not enabled
	SELECT count(*) 
	  INTO v_count
	  FROM all_tables
	 WHERE table_name = 'CERT_SCHEME'
	   AND owner = 'SUPPLIER';		
	IF v_count = 0 THEN
		execute immediate 'CREATE TABLE SUPPLIER.CERT_SCHEME(
							CERT_SCHEME_ID       NUMBER(10, 0)     NOT NULL,
							NAME                 VARCHAR2(255)     NOT NULL,
							DESCRIPTION          VARCHAR2(1024),
							CONSTRAINT PK50 PRIMARY KEY (CERT_SCHEME_ID)
						)';
	END IF;
	
	-- Add missing tables - if wood module not enabled
	SELECT count(*) 
	  INTO v_count
	  FROM all_tables
	 WHERE table_name = 'TREE_SPECIES'
	   AND owner = 'SUPPLIER';		
	   
	IF v_count = 0 THEN
		execute immediate 'CREATE TABLE SUPPLIER.TREE_SPECIES(
								SPECIES_CODE      VARCHAR2(32)     NOT NULL,
								GENUS             VARCHAR2(256),
								SPECIES           VARCHAR2(256),
								COMMON_NAME       VARCHAR2(256),
								CONSTRAINT PK49 PRIMARY KEY (SPECIES_CODE)
							)';
	END IF;
END;
/

-- store the old Forest Source Cat description

ALTER TABLE SUPPLIER.WOOD_PART_WOOD
 ADD (OLD_FSCC_DESC  VARCHAR2(1000));
 
ALTER TABLE SUPPLIER.WOOD_PART_WOOD
 ADD (OLD_FSCC_CODE  VARCHAR2(1000));
 
 ALTER TABLE SUPPLIER.WOOD_PART_WOOD
 ADD (OLD_CERT_ID  NUMBER(10));

UPDATE supplier.wood_part_wood w 
   SET old_fscc_desc = (SELECT name FROM supplier.forest_source_cat fc WHERE fc.forest_source_cat_code = w.forest_source_cat_code);
			  
UPDATE supplier.wood_part_wood w 
   SET old_fscc_code = forest_source_cat_code;	

UPDATE supplier.wood_part_wood w 
   SET old_cert_id  = cert_scheme_id;

-- do the new style accredditation to cert mapping

DROP TABLE SUPPLIER.CERT_SCHEME_SOURCE_CAT_MAPPING CASCADE CONSTRAINTS
;

DROP TABLE SUPPLIER.FOREST_SOURCE_CAT CASCADE CONSTRAINTS
;

CREATE TABLE SUPPLIER.FOREST_SOURCE_CAT(
    FOREST_SOURCE_CAT_CODE    VARCHAR2(32)      NOT NULL,
    NAME                      VARCHAR2(256)     NOT NULL,
    DESCRIPTION               VARCHAR2(1024),
    CONSTRAINT PK55 PRIMARY KEY (FOREST_SOURCE_CAT_CODE)
);

ALTER TABLE SUPPLIER.CERT_SCHEME
 ADD (VERIFIED_FSCC  VARCHAR2(32) );

 ALTER TABLE SUPPLIER.CERT_SCHEME
 ADD (NON_VERIFIED_FSCC  VARCHAR2(32)  );

-- basedata missing if wood module not enable - add in so script can run - I'm not sure how we "should" handle this
BEGIN
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (1, 'Unknown', 'Unknown', '2', '1');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (2, 'Certfor', 'Certfor', '3', '1');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (3, 'Cerflor', 'Cerflor', '3', '1');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN	
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (4, 'CSA', 'CSA', '3', '1');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (5, 'FSC', 'FSC', '4', '4');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (6, 'FSC Recycled', 'FSC Recycled', 'RII', 'RII');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (7, 'LEI', 'LEI', '3', '1');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (8, 'MTCC', 'MTCC', '3', '1');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (9, 'No Certification Scheme', 'No Certification Scheme', '2', '1');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (10, 'PEFC', 'PEFC', '3', '3');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (11, 'SFI', 'SFI', '3', '1');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (12, 'SGS CSP', 'SGS CSP', '3', '2');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (13, 'TFT', 'TFT', '3', '2');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (14, 'Verified 1st Party', 'Verified 1st Party', '2', '2');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (15, 'Verified 2nd Party', 'Verified 2nd Party', '3', '3');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (16, 'Verified 3rd Party', 'Verified 3rd Party', '3', '3');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
	
	BEGIN
		INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (17, 'WWF Producer Group', 'WWF Producer Group', '3', '2');
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
END;
/

BEGIN
	INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('1', 'Limited knowledge of source');
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('2', 'Source Assessed');
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('3', 'Source Verified');
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('4', 'Credibly Certified');
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('RI', 'Recycled pre-consumer');
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('RII', 'Recycled post-consumer');
	 
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '1' WHERE cert_scheme_id = 2;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '1' WHERE cert_scheme_id = 3;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '1' WHERE cert_scheme_id = 4;
	UPDATE supplier.cert_scheme SET verified_fscc = '4', non_verified_fscc = '4' WHERE cert_scheme_id = 5;
	UPDATE supplier.cert_scheme SET verified_fscc = 'RII', non_verified_fscc = 'RII' WHERE cert_scheme_id = 6;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '1' WHERE cert_scheme_id = 7;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '1' WHERE cert_scheme_id = 8;
	UPDATE supplier.cert_scheme SET verified_fscc = '2', non_verified_fscc = '1' WHERE cert_scheme_id = 9;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '3' WHERE cert_scheme_id = 10;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '1' WHERE cert_scheme_id = 11;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '2' WHERE cert_scheme_id = 12;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '2' WHERE cert_scheme_id = 13;
	UPDATE supplier.cert_scheme SET verified_fscc = '2', non_verified_fscc = '1' WHERE cert_scheme_id = 1;
	UPDATE supplier.cert_scheme SET verified_fscc = '2', non_verified_fscc = '2' WHERE cert_scheme_id = 14;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '3' WHERE cert_scheme_id = 15;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '3' WHERE cert_scheme_id = 16;
	UPDATE supplier.cert_scheme SET verified_fscc = '3', non_verified_fscc = '2' WHERE cert_scheme_id = 17;
END;
/
 
 -- stop cols being null
ALTER TABLE SUPPLIER.CERT_SCHEME
MODIFY(VERIFIED_FSCC  NOT NULL);

ALTER TABLE SUPPLIER.CERT_SCHEME
MODIFY(NON_VERIFIED_FSCC  NOT NULL);
 
ALTER TABLE SUPPLIER.CERT_SCHEME ADD CONSTRAINT FK_FSC_CS_NON_VERF 
    FOREIGN KEY (NON_VERIFIED_FSCC)
    REFERENCES SUPPLIER.FOREST_SOURCE_CAT(FOREST_SOURCE_CAT_CODE)
;

ALTER TABLE SUPPLIER.CERT_SCHEME ADD CONSTRAINT FK_FSC_CS_VERF 
    FOREIGN KEY (VERIFIED_FSCC)
    REFERENCES SUPPLIER.FOREST_SOURCE_CAT(FOREST_SOURCE_CAT_CODE)
;

BEGIN
	FOR r IN (SELECT * FROM all_constraints WHERE owner='SUPPLIER' and constraint_name ='REFCERT_SCHEME136') LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE SUPPLIER.WOOD_PART_WOOD DROP CONSTRAINT REFCERT_SCHEME136';
	END LOOP;
END;
/

ALTER TABLE SUPPLIER.WOOD_PART_WOOD ADD CONSTRAINT FK_CS_WPW_CERT_ID FOREIGN KEY (CERT_SCHEME_ID) REFERENCES SUPPLIER.CERT_SCHEME(CERT_SCHEME_ID);


@update_tail

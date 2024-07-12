-- Please update version.sql too -- this keeps clean builds in sync
define version=1252
@update_header



/* ---------------------------------------------------------------------- */
/* Sequences                                                              */
/* ---------------------------------------------------------------------- */

CREATE SEQUENCE CHEM.CAS_GROUP_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

/* ---------------------------------------------------------------------- */
/* Add table "CAS_GROUP"                                                  */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.CAS_GROUP (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CAS_GROUP_ID NUMBER(10) NOT NULL,
    PARENT_GROUP_ID NUMBER(10),
    LABEL VARCHAR2(255),
    LOOKUP_KEY VARCHAR2(64),
    CONSTRAINT PK_CAS_GROUP PRIMARY KEY (APP_SID, CAS_GROUP_ID)
);

CREATE UNIQUE INDEX CHEM.IDX_CAS_GROUP_1 ON CHEM.CAS_GROUP (APP_SID,NVL(UPPER(LOOKUP_KEY),'CGID'||CAS_GROUP_ID));

/* ---------------------------------------------------------------------- */
/* Add table "CAS_GROUP_MEMBER"                                           */
/* ---------------------------------------------------------------------- */

CREATE TABLE CHEM.CAS_GROUP_MEMBER (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CAS_GROUP_ID NUMBER(10) NOT NULL,
    CAS_CODE VARCHAR2(50) NOT NULL,
    CONSTRAINT PK_CAS_GROUP_MEMBER PRIMARY KEY (APP_SID, CAS_GROUP_ID, CAS_CODE)
);

CREATE UNIQUE INDEX CHEM.IDX_CAS_GROUP_MEMBER_1 ON CHEM.CAS_GROUP_MEMBER (APP_SID,CAS_CODE);

/* ---------------------------------------------------------------------- */
/* Foreign key constraints                                                */
/* ---------------------------------------------------------------------- */


ALTER TABLE CHEM.CAS_GROUP ADD CONSTRAINT FK_CAS_GRP_CAS_GRP 
    FOREIGN KEY (APP_SID, PARENT_GROUP_ID) REFERENCES CHEM.CAS_GROUP (APP_SID,CAS_GROUP_ID);

ALTER TABLE CHEM.CAS_GROUP_MEMBER ADD CONSTRAINT FK_CAS_CAS_GRP_MBR 
    FOREIGN KEY (CAS_CODE) REFERENCES CHEM.CAS (CAS_CODE);

ALTER TABLE CHEM.CAS_GROUP_MEMBER ADD CONSTRAINT FK_CAS_GRP_CAS_GRP_MBR 
    FOREIGN KEY (APP_SID, CAS_GROUP_ID) REFERENCES CHEM.CAS_GROUP (APP_SID,CAS_GROUP_ID);

CREATE OR REPLACE VIEW CHEM.V$OUTPUTS AS
	 SELECT su.app_sid, NVL(cg.label, 'Unknown') cas_group_label, cg.cas_group_id, 
			c.cas_code, c.name,  
			s.ref substance_ref, s.description substance_description,
			sr.waiver_status_id, sr.region_sid, su.start_dtm, su.end_dtm, 
			pd.to_air_pct * su.mass_value * sc.pct_composition air_mass_value,
			pd.to_water_pct * su.mass_value * sc.pct_composition water_mass_value
		  FROM substance_use su
			JOIN substance s ON su.substance_id = s.substance_id AND su.app_sid = s.app_sid
			JOIN substance_region sr ON su.substance_id = sr.substance_id AND su.region_sid = sr.region_sid AND su.app_sid = sr.app_sid
			JOIN process_destination pd ON su.process_destination_id = pd.process_destination_id AND su.app_sid = pd.app_sid
			JOIN substance_cas sc ON s.substance_id = sc.substance_id
			JOIN cas c ON sc.cas_code = c.cas_code
			LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code 
			LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;

@update_tail

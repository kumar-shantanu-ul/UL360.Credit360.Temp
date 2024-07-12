-- Please update version.sql too -- this keeps clean builds in sync
define version=343
@update_header

-- TABLE: EGRID 
--

CREATE TABLE EGRID(
    EGRID_REF    VARCHAR2(4)      NOT NULL,
    NAME         VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK622 PRIMARY KEY (EGRID_REF)
)
;



ALTER TABLE REGION ADD (
    EGRID_REF             VARCHAR2(4)
);

ALTER TABLE REGION ADD CONSTRAINT RefEGRID1238 
    FOREIGN KEY (EGRID_REF)
    REFERENCES EGRID(EGRID_REF);
    
BEGIN
INSERT INTO egrid (egrid_ref, name) VALUES ('AKGD','ASCC Alaska Grid');
INSERT INTO egrid (egrid_ref, name) VALUES ('AKMS','ASCC Alaska Miscellaneous');
INSERT INTO egrid (egrid_ref, name) VALUES ('CALI','WSCC California');
INSERT INTO egrid (egrid_ref, name) VALUES ('ECMI','ECAR Michigan');
INSERT INTO egrid (egrid_ref, name) VALUES ('ECOV','ECAR Ohio Valley');
INSERT INTO egrid (egrid_ref, name) VALUES ('ERCT','ERCOT All');
INSERT INTO egrid (egrid_ref, name) VALUES ('FRCC','FRCC All');
INSERT INTO egrid (egrid_ref, name) VALUES ('HIMS','HICC Hawaii Miscellaneous');
INSERT INTO egrid (egrid_ref, name) VALUES ('HIOA','HICC Oahu');
INSERT INTO egrid (egrid_ref, name) VALUES ('MAAC','MAAC All');
INSERT INTO egrid (egrid_ref, name) VALUES ('MANN','MAIN North');
INSERT INTO egrid (egrid_ref, name) VALUES ('MANS','MAIN South');
INSERT INTO egrid (egrid_ref, name) VALUES ('MAPP','MAPP All');
INSERT INTO egrid (egrid_ref, name) VALUES ('NEWE','NPCC New England');
INSERT INTO egrid (egrid_ref, name) VALUES ('NWGB','WSCC Great Basin');
INSERT INTO egrid (egrid_ref, name) VALUES ('NWPN','WSCC Pacific Northwest');
INSERT INTO egrid (egrid_ref, name) VALUES ('NYCW','NPCC NYC/Westchester');
INSERT INTO egrid (egrid_ref, name) VALUES ('NYLI','NPCC Long Island');
INSERT INTO egrid (egrid_ref, name) VALUES ('NYUP','NPCC Upstate New  York');
INSERT INTO egrid (egrid_ref, name) VALUES ('ROCK','WSCC Rockies');
INSERT INTO egrid (egrid_ref, name) VALUES ('SPNO','SPP North');
INSERT INTO egrid (egrid_ref, name) VALUES ('SPSO','SPP South');
INSERT INTO egrid (egrid_ref, name) VALUES ('SRMV','SERC Mississippi Valley');
INSERT INTO egrid (egrid_ref, name) VALUES ('SRSO','SERC South');
INSERT INTO egrid (egrid_ref, name) VALUES ('SRTV','SERC Tennessee Valley');
INSERT INTO egrid (egrid_ref, name) VALUES ('SRVC','SERC Virginia/Carolina');
INSERT INTO egrid (egrid_ref, name) VALUES ('WSSW','WSCC Southwest');
END;
/


@../region_pkg.sql
@../dataview_body.sql
@../delegation_body.sql
@../imp_body.sql
@../range_body.sql
@../region_body.sql
@../schema_body.sql
@../sheet_body.sql
@../val_datasource_body.sql
@../vb_legacy_body.sql

@update_tail

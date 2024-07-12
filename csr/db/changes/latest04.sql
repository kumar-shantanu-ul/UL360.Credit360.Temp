-- Please update version.sql too -- this keeps clean builds in sync
define version=04
@update_header


alter table delegation_region add (aggregate_to_region_sid NUMBER(10));

update delegation set regions_are_children = 0 where regions_are_children is null;

update delegation_region
 set aggregate_to_region_sid = region_sid 
 where delegation_sid in (select delegation_sid from delegation where regions_are_children = 0);

 
update ( 
select dr.aggregate_to_region_sid, r.parent_sid from delegation_region dr, region r, delegation d
 where   dr.region_sid = r.region_sid 
 and d.delegation_sid = dr.delegation_sid and regions_are_children = 1)
set aggregate_to_region_sid = parent_sid;

alter table delegation_region 	modify (aggregate_to_region_sid not null);







CREATE SEQUENCE IMP_MEASURE_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

alter table imp_val add (imp_measure_Id number(10));

alter table delegation add (regions_are_children number(10));

alter table delegation add (SECTION_XML CLOB DEFAULT EMPTY_CLOB());

alter table delegation_ind add (SECTION_KEY VARCHAR2(256));




CREATE TABLE IMP_MEASURE(
    IMP_MEASURE_ID         NUMBER(10, 0)    NOT NULL,
    CSR_ROOT_SID           NUMBER(10, 0)    NOT NULL,
    DESCRIPTION            VARCHAR2(255)    NOT NULL,
    MAPS_TO_MEASURE_CONVERSION_ID    NUMBER(10, 0),
    MAPS_TO_MEASURE_SID    NUMBER(10, 0),
    IMP_IND_ID		   NUMBER(10,0),
    CONSTRAINT PK_IMP_IND_1 PRIMARY KEY (IMP_MEASURE_ID)
);



ALTER TABLE IMP_VAL ADD CONSTRAINT RefIMP_MEASURE167 
    FOREIGN KEY (IMP_MEASURE_ID)
    REFERENCES IMP_MEASURE(IMP_MEASURE_ID);

ALTER TABLE IMP_MEASURE ADD CONSTRAINT RefIMP_IND169 
    FOREIGN KEY (IMP_IND_ID)
    REFERENCES IMP_IND(IMP_IND_ID)
;




alter table sheet add (last_reminded_dtm date);

CREATE OR REPLACE VIEW SHEET_WITH_LAST_ACTION AS
SELECT SH.SHEET_ID, SH.DELEGATION_SID, SH.START_DTM, SH.END_DTM, SH.REMINDER_DTM, SH.SUBMISSION_DTM, SHE.SHEET_ACTION_ID LAST_ACTION_ID, SHE.FROM_USER_SID LAST_ACTION_FROM_USER_SID, SHE.ACTION_DTM LAST_ACTION_DTM, SHE.NOTE LAST_ACTION_NOTE, SHE.TO_DELEGATION_SID LAST_ACTION_TO_DELEGATION_SID,
            CASE WHEN SYSDATE >= submission_dtm AND SHE.SHEET_ACTION_ID IN (0,2) THEN 1 --csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_RETURNED
             	 WHEN SYSDATE >= reminder_dtm AND SHE.SHEET_ACTION_ID IN (0,2) THEN 2 --csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_RETURNED
                 ELSE 3
            END STATUS, SH.LAST_REMINDED_DTM
FROM SHEET_HISTORY SHE, SHEET SH
WHERE SH.LAST_SHEET_HISTORY_ID = SHE.SHEET_HISTORY_ID AND SHE.SHEET_ID = SH.SHEET_ID
 AND SHE.SHEET_ID = SH.SHEET_ID AND SH.LAST_SHEET_HISTORY_ID = SHE.SHEET_HISTORY_ID
;

@update_tail

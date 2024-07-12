-- Please update version.sql too -- this keeps clean builds in sync
define version=43
@update_header

CREATE VIEW IMP_VAL_MAPPED
(IND_DESCRIPTION, REGION_DESCRIPTION, IND_SID, REGION_SID, IMP_IND_DESCRIPTION, IMP_REGION_DESCRIPTION, IMP_VAL_ID, IMP_IND_ID, IMP_REGION_ID, UNKNOWN, START_DTM, END_DTM, VAL, CONVERSION_FACTOR, FILE_SID, IMP_SESSION_SID, SET_VAL_ID, IMP_MEASURE_ID) AS
SELECT i.description ind_description, r.description region_description, i.ind_sid, r.region_sid, 
       	ii.description imp_ind_description, ir.description imp_region_description, 
       		iv."IMP_VAL_ID",iv."IMP_IND_ID",iv."IMP_REGION_ID",iv."UNKNOWN",iv."START_DTM",iv."END_DTM",iv."VAL",iv."CONVERSION_FACTOR",iv."FILE_SID",iv."IMP_SESSION_SID",iv."SET_VAL_ID",iv."IMP_MEASURE_ID" 
         FROM imp_val iv, imp_ind ii, imp_region ir, ind i, region r 
        WHERE iv.imp_ind_id = ii.imp_ind_id 
          AND iv.imp_region_id = ir.imp_region_id 
          AND ii.maps_to_ind_sid = i.ind_sid 
          AND ir.maps_to_region_sid = r.region_sid
;


create index ix_sheet_value on sheet_value (ind_sid, region_sid, status) tablespace indx;

@update_tail

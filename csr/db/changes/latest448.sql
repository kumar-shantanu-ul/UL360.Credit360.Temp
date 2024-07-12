-- Please update version.sql too -- this keeps clean builds in sync
define version=448
@update_header

ALTER TABLE dataview_ind_member
  ADD (POS NUMBER(10,0));
  
ALTER TABLE dataview_ind_member
  ADD (SCALE NUMBER(10,0));

ALTER TABLE dataview_ind_member
  ADD (FORMAT_MASK VARCHAR2(255));

ALTER TABLE dataview_ind_member
  ADD (MEASURE_DESCRIPTION VARCHAR2(255));

ALTER TABLE dataview_ind_member
  ADD (FLAGS NUMBER(10, 0));

ALTER TABLE dataview_ind_member
  ADD (MULTIPLIER_IND_SID NUMBER(10,0));

ALTER TABLE dataview_ind_member
  ADD (MEASURE_CONVERSION_ID NUMBER(10,0));

ALTER TABLE dataview_region_member
  ADD (DESCRIPTION VARCHAR2(1023));

ALTER TABLE dataview_region_member
  ADD (POS NUMBER(10,0));
  
ALTER TABLE DATAVIEW_IND_MEMBER ADD CONSTRAINT RefMEASURE_CONVERSION1638 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE DATAVIEW_IND_MEMBER ADD CONSTRAINT RefIND1639 
    FOREIGN KEY (APP_SID, MULTIPLIER_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

BEGIN
	UPDATE dataview_ind_member dim
	   SET (pos, scale, format_mask, measure_description, flags, multiplier_ind_sid, measure_conversion_id) =
	   	   (SELECT pos, scale, format_mask, measure_description, flags, multiplier_ind_sid, measure_conversion_id
	   	      FROM range_ind_member rim
	   	   	 WHERE dim.app_sid = rim.app_sid AND dim.dataview_sid = rim.range_sid AND dim.ind_sid = rim.ind_sid);

	UPDATE dataview_region_member drm
	   SET (pos, description) = 
	   	   (SELECT pos, description
	   	      FROM range_region_member rrm
	   	     WHERE drm.app_sid = rrm.app_sid AND drm.dataview_sid = rrm.range_sid AND drm.region_sid = rrm.region_sid);
END;
/


ALTER TABLE dataview_ind_member MODIFY POS NOT NULL;

ALTER TABLE dataview_region_member MODIFY POS NOT NULL;

@update_tail

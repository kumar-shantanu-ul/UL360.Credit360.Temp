-- Please update version.sql too -- this keeps clean builds in sync
define version=392
@update_header

CREATE TABLE csr.range_ind_member_fb4194 AS SELECT * FROM csr.range_ind_member rim WHERE EXISTS(SELECT * FROM ind i WHERE i.ind_sid = rim.ind_sid and i.app_sid = rim.app_sid AND i.measure_sid IS NULL) AND EXISTS(SELECT * FROM dataview dv WHERE dv.dataview_sid = rim.range_sid AND dv.app_sid = rim.app_sid);

DELETE FROM csr.range_ind_member rim WHERE EXISTS(SELECT * FROM ind i WHERE i.ind_sid = rim.ind_sid and i.app_sid = rim.app_sid AND i.measure_sid IS NULL) AND EXISTS(SELECT * FROM dataview dv WHERE dv.dataview_sid = rim.range_sid AND dv.app_sid = rim.app_sid);

@update_tail

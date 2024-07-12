
-- Please update version.sql too -- this keeps clean builds in sync
define version=2550
@update_header

EXEC security.user_pkg.logonadmin; 

UPDATE csr.dataview_ind_member
   SET measure_conversion_id = NULL
 WHERE (app_sid, dataview_sid, pos) IN (
		SELECT dim.app_sid, dim.dataview_sid, dim.pos
		  FROM csr.dataview_ind_member dim
		  JOIN csr.measure_conversion mc ON dim.app_sid = mc.app_sid AND dim.measure_conversion_id = mc.measure_conversion_id
		  JOIN csr.measure m ON mc.app_sid = m.app_sid AND mc.measure_sid = m.measure_sid
		  JOIN csr.ind i ON dim.app_sid = i.app_sid AND dim.ind_sid = i.ind_sid
		  JOIN csr.measure im ON i.app_sid = im.app_sid AND i.measure_sid = im.measure_sid
		 WHERE NVL(im.measure_sid, -1) != NVL(mc.measure_sid, -1)
);


@../indicator_body

@update_tail
-- Please update version.sql too -- this keeps clean builds in sync
define version=1455
@update_header

INSERT INTO csr.val_change_log (app_sid, ind_sid, start_dtm, end_dtm)
SELECT i.app_sid, i.ind_sid, TO_DATE('1990-01-01', 'yyyy-mm-dd'), TO_DATE('2020-01-01', 'yyyy-mm-dd')
  FROM csr.ind i
  JOIN csr.measure mes
	ON i.measure_sid = mes.measure_sid
 WHERE mes.std_measure_conversion_id IN (26176,26175,26171,26170,26169,26165,26164,26163)
 GROUP BY i.app_sid, i.ind_sid;

@update_tail
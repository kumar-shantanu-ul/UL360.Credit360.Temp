-- Please update version.sql too -- this keeps clean builds in sync
define version=1427
@update_header

/*
Original query to see how many records are affected (2,350,814 on livedata).

SELECT COUNT(*) FROM csr.delegation_ind_description a
  JOIN csr.ind_description b ON a.app_sid = b.app_sid AND a.ind_sid = b.ind_sid AND a.lang = b.lang
 WHERE TRIM(a.description) = TRIM(b.description)
*/

DELETE FROM csr.delegation_ind_description
 WHERE (app_sid, delegation_sid, ind_sid, lang) IN (
	SELECT a.app_sid, a.delegation_sid, a.ind_sid, a.lang 
	  FROM csr.delegation_ind_description a
		JOIN csr.ind_description b ON a.app_sid = b.app_sid AND a.ind_sid = b.ind_sid AND a.lang = b.lang
	  WHERE TRIM(a.description) = TRIM(b.description)
);

@update_tail

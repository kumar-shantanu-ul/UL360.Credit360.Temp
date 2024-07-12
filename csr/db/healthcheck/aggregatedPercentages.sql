SELECT i.ind_sid, m.description, indicator_pkg.INTERNAL_GetIndPathString(i.ind_sid) ind_path
  FROM customer c, measure m, ind i
 WHERE c.host = 'rbsenv.credit360.com'
   AND c.app_sid = m.app_sid
   AND (
	LOWER(m.description) like '%pct%' OR
	LOWER(m.description) like '%percent%' OR
	REPLACE(m.description,'%',CHR(0)) like '%'||chr(0)||'%'
   )
   AND m.measure_sid = i.measure_sid
   AND i.aggregate IN ('SUM', 'FORCE SUM')
 UNION
SELECT i.ind_sid, m.description, indicator_pkg.INTERNAL_GetIndPathString(i.ind_sid) ind_path
  FROM customer c, measure m, ind i
 WHERE c.host = 'rbsenv.credit360.com'
   AND c.app_sid = m.app_sid
   AND m.custom_field is not null 
   AND LENGTH(m.custom_field) > 1
   AND m.measure_sid = i.measure_sid
   AND i.aggregate IN ('SUM', 'FORCE SUM')

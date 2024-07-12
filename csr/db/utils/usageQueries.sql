
select qi.host, indicator_count, region_count, value_count, user_count, min_value_date, max_value_date, max_value_date - min_value_date date_range_days, form_count
  from customer c, 
(
	-- number of indicators per active customer
	select host, count(*) indicator_count
	  from ind i, customer c 
	 where active = 1
	   and status = 2
	   and i.app_sid = c.app_sid
	 group by host
)qi, (
	-- number of regions per active customer
	select host, count(*) region_count
	  from region r, customer c 
	 where active = 1
	   and status = 2
	   and r.app_sid = c.app_sid
	 group by host
)qr, (
	-- number of values (excluding aggregates) per active customer
	select host, count(*) value_count
	  from region r, customer c, val v
	 where active = 1
	   and c.status = 2
	   and v.region_sid = r.region_sid
	   and r.app_sid = c.app_sid
	 group by host
)qv, (
	-- number of users logged in during last 12 months per active customer
	select host, count(*) user_count
	  from csr_user cu, customer c, security.user_table ut
	 where c.status = 2
	   and ut.sid_id = cu.csr_user_sid
	   and ut.last_logon > add_months(sysdate, -12)
	   and cu.app_sid = c.app_sid
	 group by host
)qu, (
	-- min and max date range for data
	select host, min(period_start_dtm) min_value_date, max(period_end_dtm) max_value_date
	  from region r, customer c, val v
	 where active = 1
	   and c.status = 2
	   and v.region_sid = r.region_sid
	   and r.app_sid = c.app_sid
	 group by host
)qd, (
	select host, sum(cnt) form_count
	  from (
		select host, count(*) cnt
		  from delegation d, customer c
		 where c.status = 2
		   and d.app_sid = c.app_sid
		 group by host
		 union 
		select host, count(*) cnt
		  from form f, customer c
		 where c.status = 2
		   and f.app_sid = c.app_sid
		 group by host
	 )
	 group by host 
)qf
  where c.status = 2
    and c.host = qi.host(+)
    and c.host = qr.host(+)
    and c.host = qv.host(+)
    and c.host = qu.host(+)
    and c.host = qd.host(+)
    and c.host = qf.host(+);
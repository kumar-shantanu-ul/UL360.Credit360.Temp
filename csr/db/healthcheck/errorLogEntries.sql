select count(*) 
  from customer c, error_log el, val v
 where c.host='rbs3.credit360.com'
   and c.app_sid = el.app_sid
   and el.val_change_id = v.last_val_change_id

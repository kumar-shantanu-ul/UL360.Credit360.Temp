select * 
  from csr.val v1, csr.val v2
 where v1.val_id != v2.val_id
   and v1.ind_sid = v2.ind_sid
   and v1.region_sid = v2.region_sid
   and v1.period_start_dtm < v2.period_end_dtm
   and v1.period_end_dtm > v2.period_start_dtm;

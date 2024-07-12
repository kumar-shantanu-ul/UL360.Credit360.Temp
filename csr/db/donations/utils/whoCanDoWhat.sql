select distinct c.host, s.name scheme_name, r.description region_description, cu.full_name user_name
  from csr.customer c, region_group rg, region_group_member rgm, csr.region r,
    csr.region_owner ro, csr.csr_user cu, budget b, scheme s
 where c.app_sid = rg.app_sid
   and rg.region_group_sid = rgm.region_group_sid
   and rgm.region_sid = r.region_sid
   and r.region_sid = ro.region_sid
   and ro.user_sid = cu.csr_user_sid
   and rg.region_group_sid = b.region_group_sid
   and b.scheme_sid = s.scheme_sid
 order by host, scheme_name, region_description, cu.full_name;
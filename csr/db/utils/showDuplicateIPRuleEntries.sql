select v.*, dupr.ip_rule_index covered_by_index, dupr.ipv4_address covered_by_ipv4, dupr.ipv4_bitmask covered_by_mask
from security.v$ip_rule_entry v
join security.ip_rule_entry ip
on ip.ip_rule_id = v.ip_rule_id and ip.ip_rule_index = v.ip_rule_index
join security.ip_rule_entry dup
on dup.ip_rule_id = ip.ip_rule_id
and dup.allow = ip.allow
and dup.require_ssl = ip.require_ssl
and dup.ip_rule_index <> ip.ip_rule_index
join security.v$ip_rule_entry dupr
on dup.ip_rule_id = dupr.ip_rule_id
and dup.ip_rule_index = dupr.ip_rule_index
where bitand(ip.ipv4_address, dup.ipv4_bitmask) = dup.ipv4_address
and bitand(ip.ipv4_bitmask, dup.ipv4_bitmask) = dup.ipv4_bitmask
order by dupr.ipv4_address, v.ipv4_address
;

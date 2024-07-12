delete from security.ip_rule_entry
where (ip_rule_id, ip_rule_index) in (
	select ip.ip_rule_id, ip.ip_rule_index
	from security.ip_rule_entry ip
	join security.ip_rule_entry dup
	on dup.ip_rule_id = ip.ip_rule_id
	and dup.allow = ip.allow
	and dup.require_ssl = ip.require_ssl
	and dup.ip_rule_index <> ip.ip_rule_index
	where bitand(ip.ipv4_address, dup.ipv4_bitmask) = dup.ipv4_address
	and bitand(ip.ipv4_bitmask, dup.ipv4_bitmask) = dup.ipv4_bitmask
);

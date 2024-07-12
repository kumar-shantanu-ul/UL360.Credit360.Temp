select to_char(mod(ipv4_address,256))||'.'||
        to_char(mod(trunc(ipv4_address/256),256))||'.'||
        to_char(mod(trunc(ipv4_address/256/256),256))||'.'||
        to_char(mod(trunc(ipv4_address/256/256/256),256)) ipv4_address,                
        case 
            when ipv4_bitmask = -1 then '255.255.255.255' 
            else 
            to_char(mod(ipv4_bitmask,256))||'.'||
            to_char(mod(trunc(ipv4_bitmask/256),256))||'.'||
            to_char(mod(trunc(ipv4_bitmask/256/256),256))||'.'||
            to_char(mod(trunc(ipv4_bitmask/256/256/256),256)) 
        end ipv4_bitmask
 from security.ip_rule_entry 
  where ip_rule_id = 3  -- sempra
    and allow = 1
  order by ipv4_address;
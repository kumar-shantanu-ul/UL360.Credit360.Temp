-- Please update version.sql too -- this keeps clean builds in sync
define version=566
@update_header

update ind set calc_xml = regexp_Replace(to_char(extract(calc_xml,'/').getClobVal()),'<gasfactor sid="[0-9]+"','<gasfactor sid="'||ind.map_to_ind_sid||'"')
where dbms_lob.instr(extract(calc_xml,'/').getClobVal(), '<gasfactor')>0 and map_to_ind_sid is not null;
delete from calc_dependency where (app_sid, calc_ind_sid) in (select app_sid, ind_sid from ind where ind_type = 0);

@../datasource_body
@../stored_calc_datasource_body
@../indicator_body

@update_tail

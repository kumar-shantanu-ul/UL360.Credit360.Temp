-- Please update version.sql too -- this keeps clean builds in sync
define version=999
@update_header

alter table cms.tab_column add calc_xml xmltype;
alter table cms.tab_column add constraint ck_tab_col_calc_xml check ( (calc_xml is null and col_type != 25) or (calc_xml is not null and col_type = 25) );
alter table cms.tab_column add data_type varchar2(106);
alter table cms.tab_column add data_length number;
alter table cms.tab_column add data_precision number;
alter table cms.tab_column add data_scale number;
alter table cms.tab_column add nullable varchar2(1);
alter table cms.tab_column add char_length number;

@../../../aspen2/cms/db/calc_xml_pkg
@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body
@../../../aspen2/cms/db/calc_xml_body

@update_tail

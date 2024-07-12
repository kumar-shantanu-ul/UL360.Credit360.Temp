-- Please update version.sql too -- this keeps clean builds in sync
define version=2467
@update_header

grant select, references on csr.measure to cms;

-- XXX: these need adding to schema.dez on trunk merge
alter table cms.tab_column add measure_sid number(10);
alter table cms.tab_column add constraint fk_tab_column_csr_measure foreign key (app_sid, measure_sid) references csr.measure (app_sid, measure_sid);
alter table cms.tab_column add constraint ck_tab_column_measure check ( measure_sid is null or (col_type = 12 and measure_sid is not null) );

alter table cms.tab_column add constraint uk_tab_column_tab_column unique (app_sid, tab_sid, column_sid);

alter table cms.tab_column add measure_conv_column_sid number(10);
alter table cms.tab_column add constraint fk_tab_column_measure_conv foreign key (app_sid, tab_sid, measure_conv_column_sid) references cms.tab_column (app_sid, tab_sid, column_sid);
alter table cms.tab_column add measure_conv_date_column_sid number(10);
alter table cms.tab_column add constraint fk_tab_column_meas_conv_date foreign key (app_sid, tab_sid, measure_conv_date_column_sid) references cms.tab_column (app_sid, tab_sid, column_sid);

alter table cms.tab add has_rid_column number(1) default 0 not null;
alter table cms.tab add constraint ck_tab_has_rid_column check (has_rid_column in (0,1));
--

alter table csr.measure add lookup_key varchar2(64);
create unique index csr.ux_measure_lookup_key on csr.measure (app_sid, nvl(upper(lookup_key), measure_sid));
alter table csr.measure_conversion add lookup_key varchar2(64);
create unique index csr.ux_measure_conv_lookup_key on csr.measure_conversion (app_sid, nvl(upper(lookup_key), measure_conversion_id));

@../../../aspen2/cms/db/calc_xml_pkg 
@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/util_pkg
@../measure_pkg
@../../../aspen2/cms/db/calc_xml_body 
@../../../aspen2/cms/db/tab_body
@../../../aspen2/cms/db/util_body
@../delegation_body
@../enable_body
@../indicator_body
@../measure_body

@update_tail

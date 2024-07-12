-- Please update version.sql too -- this keeps clean builds in sync
define version=2735
@update_header

begin
	insert into cms.col_type values (38, 'Form selection');
	commit;
end;
/

alter table cms.tab_column add (
	form_selection_desc_field 		VARCHAR2(30),
	form_selection_pos_field 		VARCHAR2(30),
	form_selection_form_field 		VARCHAR2(30),
	form_selection_hidden_field		VARCHAR2(30)
);

alter table cms.tab_column add (
	enumerated_colour_field			VARCHAR2(30),
	enumerated_extra_fields			VARCHAR2(4000)
);

alter table csrimp.cms_tab_column add (
	form_selection_desc_field 		VARCHAR2(30),
	form_selection_pos_field 		VARCHAR2(30),
	form_selection_form_field 		VARCHAR2(30),
	form_selection_hidden_field		VARCHAR2(30)
);

alter table csrimp.cms_tab_column add (
	enumerated_colour_field			VARCHAR2(30),
	enumerated_extra_fields			VARCHAR2(4000)
);

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail

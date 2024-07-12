-- Please update version.sql too -- this keeps clean builds in sync
define version=362
@update_header

-- fix settings for old dataviews
update dataview set use_unmerged=1 where dbms_lob.instr(chart_style_xml,'UseUnmerged="True"')>0 and use_unmerged=0 and dataview_type_id=2;
update dataview set show_variance=1 where dbms_lob.instr(chart_style_xml,'ShowVariance="True"')>0 and show_variance=0 and dataview_type_id=2;

@update_tail

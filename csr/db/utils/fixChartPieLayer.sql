/*
if <layer type="pie"> in the default chart style xml is set, then it's not possible
to edit "three-d" and a couple of other attributes.  this updates the existing
style xml to fix.

update dataview 
   set chart_style_xml = regexp_replace(chart_style_xml, '(<layer type="pie"[^>]+>)','<layer type="pie" data-labels="yes">')
where dataview_sid in (
select so.sid_id
  from security.securable_object so
       start with so.sid_id = securableobject_pkg.getsidfrompath(null,0,'//aspen/applications/allianceboots.credit360.com')
       connect by prior sid_id = parent_sid_id) ;
       
-- or maybe use something like
-- '(<layer type="pie"[^>]+)three-d="[[:digit:]]+"([^>]+>)','\1\2');
-- depending on what you want
*/

--Please update version.sql too -- this keeps clean builds in sync
define version=2595
@update_header

UPDATE csr.plugin
   SET cs_class = 'Credit360.Audit.AuditCalendarDto'
 WHERE description = 'Audits'
   AND cs_class = 'Credit360.Plugins.PluginDto'
   AND js_class = 'Credit360.Calendars.Audits'

@../enable_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=928
@update_header

alter table csr.xml_request_cache add (mime_type varchar2(255));

update csr.xml_request_cache set mime_type = 'text/xml';

alter table csr.xml_request_cache modify mime_type not null;

alter table csr.xml_request_cache rename to http_request_cache;

@..\logistics_pkg
@..\logistics_body

INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'Location map', 'Credit360.Portlets.LocationMap', '/csr/site/portal/portlets/locationMap.js');

INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'Image chart', 'Credit360.Portlets.ImageChart', '/csr/site/portal/portlets/imageChart.js');

update csr.portlet set name= 'Region dropdown', type = 'Credit360.Portlets.RegionDropdown', script_path = '/csr/site/portal/portlets/regionDropdown.js' where type = 'Credit360.Portlets.RegionPickerProperties';

@update_tail

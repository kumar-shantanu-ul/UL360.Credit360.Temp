-- Please update version.sql too -- this keeps clean builds in sync
define version=2784
define minor_version=0
@update_header

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC AS
    SELECT t.app_sid, t.topic_id, t.country_code, ecn.name country, stn.status_id, stn.name status, 
        t.report_dtm, t.adoption_dtm, t.importance, t.archived, t.version topic_version, t.url, t.region_sid,
        tt.version text_version, tt.version_pub_dtm text_version_pub_dtm, tt.title, tt.abstract, tt.analysis, tt.affected_ops,
        tt.reg_citation, tt.biz_impact, t.flow_item_id, fs.label flow_state_label, fs.state_colour, fs.lookup_key state_lookup_key, t.protocol
      FROM csr.enhesa_topic t
      JOIN csr.enhesa_topic_text tt ON t.topic_id = tt.topic_id AND tt.lang = 'EN' AND t.protocol = tt.protocol
      JOIN csr.enhesa_status_name stn ON t.status_id = stn.status_id AND stn.lang = 'EN'
      JOIN csr.enhesa_country_name ecn ON t.country_code = ecn.country_code AND ecn.lang = 'EN'
      JOIN csr.flow_item fi ON t.flow_item_id = fi.flow_item_id AND t.app_sid = fi.app_sid
      JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
    ;

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_REGION AS  
    SELECT tr.topic_id, tr.country_code, cn.name country, tr.region_code, crn.name region, tr.protocol
      FROM csr.enhesa_topic_region tr 
      JOIN csr.enhesa_country_name cn ON tr.country_code = cn.country_code AND cn.lang = 'EN'
      JOIN csr.enhesa_country_region_name crn ON tr.country_code = crn.country_code AND tr.region_code = crn.region_code AND crn.lang = 'EN'
    ; 

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_KEYWORD AS
    SELECT tk.topic_id, tk.keyword_id, kt.main, kt.category, tk.protocol
      FROM csr.enhesa_topic_keyword tk 
      JOIN csr.enhesa_keyword_text kt ON tk.keyword_id = kt.keyword_id AND kt.lang = 'EN' AND tk.protocol = kt.protocol
    ; 

CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_REG AS
    SELECT tr.topic_id, tr.reg_id, r.parent_reg_id, r.reg_ref, rt.title, r.ref_dtm, r.link, r.archived, r.version reg_version,
        r.reg_level, rt.version reg_text_version, rt.version_pub_dtm reg_text_version_pub_dtm, tr.protocol
      FROM csr.enhesa_topic_reg tr
      JOIN csr.enhesa_reg r ON tr.reg_id = r.reg_id AND tr.protocol = r.protocol
      JOIN csr.enhesa_reg_text rt ON r.reg_id = rt.reg_id AND rt.lang = 'EN' AND tr.protocol = rt.protocol
    ;
	
@..\enhesa_pkg
@..\enhesa_body

@update_tail

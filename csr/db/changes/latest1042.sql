-- Please update version.sql too -- this keeps clean builds in sync
define version=1042
@update_header

ALTER TABLE CSR.SCENARIO_RULE_LIKE_CONTIG_IND ADD CONSTRAINT FK_SCN_RL_LIKE_CTG_IND_IND
FOREIGN KEY (APP_SID, IND_SID) REFERENCES CSR.IND (APP_SID, IND_SID)

create index csr.ix_scn_rule_like_ctg_ind_ind on csr.scenario_rule_like_contig_ind (app_sid, ind_sid);

@update_tail

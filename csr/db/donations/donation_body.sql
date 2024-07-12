CREATE OR REPLACE PACKAGE BODY DONATIONS.donation_Pkg
IS

-- 
-- PROCEDURE: CreateDONATION 
--
PROCEDURE CreateDonation (
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_recipient_sid				IN	security_pkg.T_SID_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_budget_id			  		IN	donation.budget_id%TYPE,
	in_region_sid			  		IN	security_pkg.T_SID_ID,
	in_activity						IN	donation.activity%TYPE,
	in_donated_dtm					IN	donation.donated_dtm%TYPE,
	in_end_dtm						IN	donation.end_dtm%TYPE,
	in_donation_status_sid			IN	donation.donation_status_sid%TYPE,
	in_paid_dtm						IN	donation.paid_dtm%TYPE,
	in_payment_ref					IN	donation.payment_ref%TYPE,
	in_notes						IN	donation.notes%TYPE,
	in_allocated_from_donation_id	IN	donation.allocated_from_donation_id%TYPE,
	in_extra_values_xml				IN	donation.extra_values_xml%TYPE,
	in_document_sids				IN	security_pkg.T_SID_IDS,
	in_letter_text					IN	donation.letter_body_text%TYPE,
	in_contact_name					IN	donation.contact_name%TYPE,
	in_custom_values				IN  T_CUSTOM_VALUES,
	out_donation_id					OUT donation.donation_id%TYPE
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_is_budget_active 				budget.is_active%TYPE;
	v_means_paid					donation_status.means_paid%TYPE;
	v_means_donated 				donation_status.means_donated%TYPE;
	v_contact_name					donation.contact_name%TYPE;
	v_track_payments				scheme.track_payments%TYPE;
	v_track_donation_end_dtm		scheme.track_donation_end_dtm%TYPE;
	t_documents                     security.T_SID_TABLE;
	v_app_sid             security_pkg.T_SID_ID;
BEGIN
  v_app_sid := security_pkg.getApp();
  
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_scheme_sid, scheme_Pkg.PERMISSION_ADD_NEW) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding new donation');
	END IF;
	
	-- check permissions for donation status
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_donation_status_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating donation with selected status');
	END IF;
	
	-- check if destination budget is active
	SELECT is_active 
	  INTO v_is_budget_active 
	  FROM budget 
	 WHERE budget_id = in_budget_id;
	 
	IF v_is_budget_active != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Selected budget can''t accept more donations');
	END IF;
	
	-- check dates / statuses
	SELECT means_paid, means_donated 
	  INTO v_means_paid, v_means_donated 
	  FROM donation_status ds
	 WHERE donation_status_sid = in_donation_status_sid;
	
	SELECT track_payments, track_donation_end_dtm
	  INTO v_track_payments, v_track_donation_end_dtm
	  FROM scheme
	 WHERE scheme_sid = in_scheme_sid;
	
	IF v_means_donated =1 AND in_donated_dtm IS NULL THEN
		RAISE_APPLICATION_ERROR(scheme_Pkg.ERR_DONATED_DTM_MISSING, 'Donated date required for this status');
	END IF;
	IF v_means_paid = 1 AND in_paid_dtm IS NULL AND v_track_payments = 1 THEN
		RAISE_APPLICATION_ERROR(scheme_Pkg.ERR_PAID_DTM_MISSING, 'Paid date required for this status');
	END IF;
	-- TODO: mandatory TBC
--	IF track_donation_end_dtm = 1 AND in_end_dtm IS NULL THEN
--		RAISE_APPLICATION_ERROR( ... , 'End date required');
--	END IF;
	-- Get recipient contact name
	SELECT contact_name
	  INTO v_contact_name
	  FROM recipient
	 WHERE recipient_sid = in_recipient_sid;
	 
	-- Is the contact name different from the passed contact name
	IF in_contact_name IS NULL OR 
		LOWER(v_contact_name) = LOWER(in_contact_name) THEN
    	v_contact_name := NULL;
	ELSE
    	v_contact_name := in_contact_name;
    END IF;
	
	
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	UPDATE RECIPIENT 
	   SET LAST_USED_DTM = SYSDATE 
	 WHERE recipient_sid = in_recipient_sid;
	  
	
	
	INSERT INTO donation
	            (donation_id, recipient_sid, scheme_sid,
	             budget_id, activity, entered_dtm, entered_by_sid,
	             donated_dtm, end_dtm, paid_dtm, payment_ref, notes,
	             allocated_from_donation_id, extra_values_xml, donation_status_sid, 
	             region_sid, letter_body_text, contact_name,
	             last_status_changed_dtm, last_status_changed_by,
	             custom_1, custom_2, custom_3, custom_4, custom_5,
	             custom_6, custom_7, custom_8, custom_9, custom_10,
	             custom_11, custom_12, custom_13, custom_14, custom_15,
	             custom_16, custom_17, custom_18, custom_19, custom_20,
				 custom_21, custom_22, custom_23, custom_24, custom_25,
	             custom_26, custom_27, custom_28, custom_29, custom_30,
	             custom_31, custom_32, custom_33, custom_34, custom_35,
	             custom_36, custom_37, custom_38, custom_39, custom_40,
				 custom_41, custom_42, custom_43, custom_44, custom_45,
	             custom_46, custom_47, custom_48, custom_49, custom_50,
	             custom_51, custom_52, custom_53, custom_54, custom_55,
	             custom_56, custom_57, custom_58, custom_59, custom_60,
	             custom_61, custom_62, custom_63, custom_64, custom_65,
	             custom_66, custom_67, custom_68, custom_69, custom_70,
				 custom_71, custom_72, custom_73, custom_74, custom_75,
	             custom_76, custom_77, custom_78, custom_79, custom_80,
	             custom_81, custom_82, custom_83, custom_84, custom_85,
	             custom_86, custom_87, custom_88, custom_89, custom_90,
	             custom_91, custom_92, custom_93, custom_94, custom_95, 
	             custom_96, custom_97, custom_98, custom_99, custom_100, 
	             custom_101, custom_102, custom_103, custom_104, custom_105, 
	             custom_106, custom_107, custom_108, custom_109, custom_110, 
	             custom_111, custom_112, custom_113, custom_114, custom_115, 
	             custom_116, custom_117, custom_118, custom_119, custom_120,
	             custom_121, custom_122, custom_123, custom_124, custom_125, 
				 custom_126, custom_127, custom_128, custom_129, custom_130, 
				 custom_131, custom_132, custom_133, custom_134, custom_135, 
				 custom_136, custom_137, custom_138, custom_139, custom_140, 
				 custom_141, custom_142, custom_143, custom_144, custom_145, 
				 custom_146, custom_147, custom_148, custom_149, custom_150, 
				 custom_151, custom_152, custom_153, custom_154, custom_155, 
				 custom_156, custom_157, custom_158, custom_159, custom_160, 
				 custom_161, custom_162, custom_163, custom_164, custom_165, 
				 custom_166, custom_167, custom_168, custom_169, custom_170, 
				 custom_171, custom_172, custom_173, custom_174, custom_175, 
				 custom_176, custom_177, custom_178, custom_179, custom_180, 
				 custom_181, custom_182, custom_183, custom_184, custom_185, 
				 custom_186, custom_187, custom_188, custom_189, custom_190, 
				 custom_191, custom_192, custom_193, custom_194, custom_195, 
				 custom_196, custom_197, custom_198, custom_199, custom_200, 
				 custom_201, custom_202, custom_203, custom_204, custom_205, 
				 custom_206, custom_207, custom_208, custom_209, custom_210, 
				 custom_211, custom_212, custom_213, custom_214, custom_215, 
				 custom_216, custom_217, custom_218, custom_219, custom_220,
				 custom_221, custom_222, custom_223, custom_224, custom_225, 
				 custom_226, custom_227, custom_228, custom_229, custom_230, 
				 custom_231, custom_232, custom_233, custom_234, custom_235, 
				 custom_236, custom_237, custom_238, custom_239, custom_240, 
				 custom_241, custom_242, custom_243, custom_244, custom_245, 
				 custom_246, custom_247, custom_248, custom_249, custom_250, 
				 custom_251, custom_252, custom_253, custom_254, custom_255, 
				 custom_256, custom_257, custom_258, custom_259, custom_260
	            )
	     VALUES (donation_id_seq.NEXTVAL, in_recipient_sid, in_scheme_sid,
	             in_budget_id, in_activity, SYSDATE, v_user_sid,
	             in_donated_dtm, in_end_dtm, in_paid_dtm, in_payment_ref, NVL(in_notes, EMPTY_CLOB()),
	             in_allocated_from_donation_id, NVL(in_extra_values_xml, EMPTY_CLOB()), in_donation_status_sid, 
	             in_region_sid, in_letter_text, v_contact_name,
	             SYSDATE, v_user_sid,
	             in_custom_values(1),
	             in_custom_values(2),
	             in_custom_values(3),
	             in_custom_values(4),
	             in_custom_values(5),
	             in_custom_values(6),
	             in_custom_values(7),
	             in_custom_values(8),
	             in_custom_values(9),
	             in_custom_values(10),
	             in_custom_values(11),
	             in_custom_values(12),
	             in_custom_values(13),
	             in_custom_values(14),
	             in_custom_values(15),
	             in_custom_values(16),
	             in_custom_values(17),
	             in_custom_values(18),
	             in_custom_values(19),
	             in_custom_values(20),
	             in_custom_values(21),
	             in_custom_values(22),
	             in_custom_values(23),
	             in_custom_values(24),
	             in_custom_values(25),
	             in_custom_values(26),
	             in_custom_values(27),
	             in_custom_values(28),
	             in_custom_values(29),
	             in_custom_values(30),
	             in_custom_values(31),
	             in_custom_values(32),
	             in_custom_values(33),
	             in_custom_values(34),
	             in_custom_values(35),
	             in_custom_values(36),
	             in_custom_values(37),
	             in_custom_values(38),
	             in_custom_values(39),
	             in_custom_values(40),
	             in_custom_values(41),
	             in_custom_values(42),
	             in_custom_values(43),
	             in_custom_values(44),
	             in_custom_values(45),
	             in_custom_values(46),
	             in_custom_values(47),
	             in_custom_values(48),
	             in_custom_values(49),
	             in_custom_values(50),
	             in_custom_values(51),
	             in_custom_values(52),
	             in_custom_values(53),
	             in_custom_values(54),
	             in_custom_values(55),
	             in_custom_values(56),
	             in_custom_values(57),
	             in_custom_values(58),
	             in_custom_values(59),
	             in_custom_values(60),
	             in_custom_values(61),
	             in_custom_values(62),
	             in_custom_values(63),
	             in_custom_values(64),
	             in_custom_values(65),
	             in_custom_values(66),
	             in_custom_values(67),
	             in_custom_values(68),
	             in_custom_values(69),
	             in_custom_values(70),
	             in_custom_values(71),
	             in_custom_values(72),
	             in_custom_values(73),
	             in_custom_values(74),
	             in_custom_values(75),
	             in_custom_values(76),
	             in_custom_values(77),
	             in_custom_values(78),
	             in_custom_values(79),
	             in_custom_values(80),
	             in_custom_values(81),
	             in_custom_values(82),
	             in_custom_values(83),
	             in_custom_values(84),
	             in_custom_values(85),
	             in_custom_values(86),
	             in_custom_values(87),
	             in_custom_values(88),
	             in_custom_values(89),
	             in_custom_values(90),
	             in_custom_values(91),
	             in_custom_values(92),
	             in_custom_values(93),
	             in_custom_values(94),
	             in_custom_values(95),
	             in_custom_values(96),
	             in_custom_values(97),
	             in_custom_values(98),
	             in_custom_values(99),
	             in_custom_values(100),
	             in_custom_values(101),
	             in_custom_values(102),
	             in_custom_values(103),
	             in_custom_values(104),
	             in_custom_values(105),
	             in_custom_values(106),
	             in_custom_values(107),
	             in_custom_values(108),
	             in_custom_values(109),
	             in_custom_values(110),
	             in_custom_values(111),
	             in_custom_values(112),
	             in_custom_values(113),
	             in_custom_values(114),
	             in_custom_values(115),
	             in_custom_values(116),
	             in_custom_values(117),
	             in_custom_values(118),
	             in_custom_values(119),
	             in_custom_values(120),
				 in_custom_values(121),
				 in_custom_values(122),
				 in_custom_values(123),
				 in_custom_values(124),
				 in_custom_values(125),
				 in_custom_values(126),
				 in_custom_values(127),
				 in_custom_values(128),
				 in_custom_values(129),
				 in_custom_values(130),
				 in_custom_values(131),
				 in_custom_values(132),
				 in_custom_values(133),
				 in_custom_values(134),
				 in_custom_values(135),
				 in_custom_values(136),
				 in_custom_values(137),
				 in_custom_values(138),
				 in_custom_values(139),
				 in_custom_values(140),
				 in_custom_values(141),
				 in_custom_values(142),
				 in_custom_values(143),
				 in_custom_values(144),
				 in_custom_values(145),
				 in_custom_values(146),
				 in_custom_values(147),
				 in_custom_values(148),
				 in_custom_values(149),
				 in_custom_values(150),
				 in_custom_values(151),
				 in_custom_values(152),
				 in_custom_values(153),
				 in_custom_values(154),
				 in_custom_values(155),
				 in_custom_values(156),
				 in_custom_values(157),
				 in_custom_values(158),
				 in_custom_values(159),
				 in_custom_values(160),
				 in_custom_values(161),
				 in_custom_values(162),
				 in_custom_values(163),
				 in_custom_values(164),
				 in_custom_values(165),
				 in_custom_values(166),
				 in_custom_values(167),
				 in_custom_values(168),
				 in_custom_values(169),
				 in_custom_values(170),
				 in_custom_values(171),
				 in_custom_values(172),
				 in_custom_values(173),
				 in_custom_values(174),
				 in_custom_values(175),
				 in_custom_values(176),
				 in_custom_values(177),
				 in_custom_values(178),
				 in_custom_values(179),
				 in_custom_values(180),
				 in_custom_values(181),
				 in_custom_values(182),
				 in_custom_values(183),
				 in_custom_values(184),
				 in_custom_values(185),
				 in_custom_values(186),
				 in_custom_values(187),
				 in_custom_values(188),
				 in_custom_values(189),
				 in_custom_values(190),
				 in_custom_values(191),
				 in_custom_values(192),
				 in_custom_values(193),
				 in_custom_values(194),
				 in_custom_values(195),
				 in_custom_values(196),
				 in_custom_values(197),
				 in_custom_values(198),
				 in_custom_values(199),
				 in_custom_values(200),
				 in_custom_values(201),
				 in_custom_values(202),
				 in_custom_values(203),
				 in_custom_values(204),
				 in_custom_values(205),
				 in_custom_values(206),
				 in_custom_values(207),
				 in_custom_values(208),
				 in_custom_values(209),
				 in_custom_values(210),
				 in_custom_values(211),
				 in_custom_values(212),
				 in_custom_values(213),
				 in_custom_values(214),
				 in_custom_values(215),
				 in_custom_values(216),
				 in_custom_values(217),
				 in_custom_values(218),
				 in_custom_values(219),
				 in_custom_values(220),
				 in_custom_values(221),
				 in_custom_values(222),
				 in_custom_values(223),
				 in_custom_values(224),
				 in_custom_values(225),
				 in_custom_values(226),
				 in_custom_values(227),
				 in_custom_values(228),
				 in_custom_values(229),
				 in_custom_values(230),
				 in_custom_values(231),
				 in_custom_values(232),
				 in_custom_values(233),
				 in_custom_values(234),
				 in_custom_values(235),
				 in_custom_values(236),
				 in_custom_values(237),
				 in_custom_values(238),
				 in_custom_values(239),
				 in_custom_values(240),
				 in_custom_values(241),
				 in_custom_values(242),
				 in_custom_values(243),
				 in_custom_values(244),
				 in_custom_values(245),
				 in_custom_values(246),
				 in_custom_values(247),
				 in_custom_values(248),
				 in_custom_values(249),
				 in_custom_values(250),
				 in_custom_values(251),
				 in_custom_values(252),
				 in_custom_values(253),
				 in_custom_values(254),
				 in_custom_values(255),
				 in_custom_values(256),
				 in_custom_values(257),
				 in_custom_values(258),
				 in_custom_values(259),
				 in_custom_values(260)
	            )
	  RETURNING donation_id
	       INTO out_donation_id;
	     
	csr.csr_data_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
        in_scheme_sid, 'Donation created with id {0}', out_donation_id, null, null, out_donation_id);
       
	-- fiddle documents
	t_documents := security_pkg.SidArrayToTable(in_document_sids);
	INSERT INTO donation_doc (donation_id, document_sid) 
                (SELECT out_donation_id, column_value
                  FROM TABLE(t_documents) where column_value != -1);
END;

PROCEDURE AuditFieldValueChange(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	in_field_num		IN	custom_field.field_num%TYPE,
	in_old_value		IN	VARCHAR2,
	in_new_value		IN	VARCHAR2,
	in_donation_id    IN  donation.donation_id%TYPE
)
AS
  v_label     varchar2(255);
BEGIN
	IF in_old_value = in_new_value THEN
		RETURN;
	ELSE 
		BEGIN
		  SELECT label 
			INTO v_label 
			FROM custom_field
		   WHERE field_num = in_field_num
			 AND app_sid = in_app_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN;
		END;
		
		csr.csr_data_pkg.AuditValueChange(in_act,  csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, in_app_sid, 
		   in_scheme_sid, v_label, in_old_value, in_new_value, in_donation_id); 
	END IF;
END;

FUNCTION CanUpdate(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_donation_id		IN	donation.donation_id%TYPE
) RETURN BOOLEAN
AS
	v_region_ok			NUMBER(10) := 0;
	v_user_sid			security_pkg.T_SID_ID;
	v_region_sid		security_pkg.T_SID_ID;
	v_scheme_sid		security_pkg.T_SID_ID;
	v_entered_by_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);

	SELECT entered_by_sid, region_sid, scheme_sid
	  INTO v_entered_by_sid, v_region_sid, v_scheme_sid
	  FROM donation
	 WHERE donation_id = in_donation_id;

	SELECT COUNT(*) 
	  INTO v_region_ok			
	  FROM csr.region_owner
	 WHERE user_sid = v_user_sid
	   AND region_sid = v_region_sid;
	
	IF security_pkg.IsAccessAllowedSID(in_act_id, v_scheme_sid, scheme_Pkg.PERMISSION_UPDATE_MINE) AND v_entered_by_sid = v_user_sid THEN
		RETURN TRUE; -- it's theirs 
	ELSIF security_pkg.IsAccessAllowedSID(in_act_id, v_scheme_sid, scheme_Pkg.PERMISSION_UPDATE_ALL) THEN
		RETURN TRUE; -- they can do anything
	ELSIF security_pkg.IsAccessAllowedSID(in_act_id, v_scheme_sid, scheme_Pkg.PERMISSION_UPDATE_REGION) AND v_region_ok > 0 THEN
		RETURN TRUE; -- it's one of their regions and they have permissions for their regions
	ELSE
		RETURN FALSE;
	END IF;
END;

-- 
-- PROCEDURE: AmendDONATION 
--
PROCEDURE AmendDonation (
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_donation_id					IN	donation.donation_id%TYPE,
	in_recipient_sid				IN	security_pkg.T_SID_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_budget_id					IN	donation.budget_id%TYPE,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_activity						IN	donation.activity%TYPE,
	in_donated_dtm					IN	donation.donated_dtm%TYPE,
	in_end_dtm						IN	donation.end_dtm%TYPE,
	in_donation_status_sid			IN	donation.donation_status_sid%TYPE,
	in_paid_dtm						IN	donation.paid_dtm%TYPE,
	in_payment_ref					IN	donation.payment_ref%TYPE,
	in_notes						IN	donation.notes%TYPE,
	in_allocated_from_donation_id	IN	donation.allocated_from_donation_id%TYPE,
	in_extra_values_xml				IN	donation.extra_values_xml%TYPE,
	in_document_sids				IN	security_pkg.T_SID_IDS,
	in_letter_text					IN	donation.letter_body_text%TYPE,
	in_contact_name					IN	donation.contact_name%TYPE,
	in_custom_values				IN  T_CUSTOM_VALUES
)
AS
	CURSOR c_values IS
    SELECT d.activity,
						d.donation_status_sid, region.region_sid, region.description region_description, r.org_name recipient_name,
            d.recipient_sid, r.ref recipient_ref, d.entered_dtm, d.entered_by_sid, d.donated_dtm, d.end_dtm,
            d.paid_dtm,  d.payment_ref, XMLTYPE(d.extra_values_xml) extra_values_xml, d.notes,
            r.org_name, b.region_group_sid, 
            b.description budget_description, 
            ds.description donation_status_description,
            us.full_name entered_by_name,
            custom_1, custom_2, custom_3, custom_4, custom_5,
            custom_6, custom_7, custom_8, custom_9, custom_10,
            custom_11, custom_12, custom_13, custom_14, custom_15,
            custom_16, custom_17, custom_18, custom_19, custom_20,
            custom_21, custom_22, custom_23, custom_24, custom_25,
            custom_26, custom_27, custom_28, custom_29, custom_30,
            custom_31, custom_32, custom_33, custom_34, custom_35,
            custom_36, custom_37, custom_38, custom_39, custom_40,
			custom_41, custom_42, custom_43, custom_44, custom_45,
			custom_46, custom_47, custom_48, custom_49, custom_50,
			custom_51, custom_52, custom_53, custom_54, custom_55,
			custom_56, custom_57, custom_58, custom_59, custom_60,
			custom_61, custom_62, custom_63, custom_64, custom_65,
			custom_66, custom_67, custom_68, custom_69, custom_70,
			custom_71, custom_72, custom_73, custom_74, custom_75,
			custom_76, custom_77, custom_78, custom_79, custom_80,
			custom_81, custom_82, custom_83, custom_84, custom_85,
			custom_86, custom_87, custom_88, custom_89, custom_90,
			custom_91, custom_92, custom_93, custom_94, custom_95, 
			custom_96, custom_97, custom_98, custom_99, custom_100, 
			custom_101, custom_102, custom_103, custom_104, custom_105, 
			custom_106, custom_107, custom_108, custom_109, custom_110, 
			custom_111, custom_112, custom_113, custom_114, custom_115, 
			custom_116, custom_117, custom_118, custom_119, custom_120,
			custom_121, custom_122, custom_123, custom_124, custom_125, 
			custom_126, custom_127, custom_128, custom_129, custom_130, 
			custom_131, custom_132, custom_133, custom_134, custom_135, 
			custom_136, custom_137, custom_138, custom_139, custom_140, 
			custom_141, custom_142, custom_143, custom_144, custom_145, 
			custom_146, custom_147, custom_148, custom_149, custom_150, 
			custom_151, custom_152, custom_153, custom_154, custom_155, 
			custom_156, custom_157, custom_158, custom_159, custom_160, 
			custom_161, custom_162, custom_163, custom_164, custom_165, 
			custom_166, custom_167, custom_168, custom_169, custom_170, 
			custom_171, custom_172, custom_173, custom_174, custom_175, 
			custom_176, custom_177, custom_178, custom_179, custom_180, 
			custom_181, custom_182, custom_183, custom_184, custom_185, 
			custom_186, custom_187, custom_188, custom_189, custom_190, 
			custom_191, custom_192, custom_193, custom_194, custom_195, 
			custom_196, custom_197, custom_198, custom_199, custom_200, 
			custom_201, custom_202, custom_203, custom_204, custom_205, 
			custom_206, custom_207, custom_208, custom_209, custom_210, 
			custom_211, custom_212, custom_213, custom_214, custom_215, 
			custom_216, custom_217, custom_218, custom_219, custom_220,
			custom_221, custom_222, custom_223, custom_224, custom_225, 
			custom_226, custom_227, custom_228, custom_229, custom_230, 
			custom_231, custom_232, custom_233, custom_234, custom_235, 
			custom_236, custom_237, custom_238, custom_239, custom_240, 
			custom_241, custom_242, custom_243, custom_244, custom_245, 
			custom_246, custom_247, custom_248, custom_249, custom_250, 
			custom_251, custom_252, custom_253, custom_254, custom_255, 
			custom_256, custom_257, custom_258, custom_259, custom_260
            FROM DONATION d, RECIPIENT r, SCHEME s, BUDGET b, REGION_GROUP rg, DONATION_STATUS ds, CURRENCY cur, csr.csr_user us, csr.v$region region
           WHERE d.donation_id = in_donation_id
           and r.recipient_sid = d.recipient_sid
           and s.scheme_sid = d.scheme_sid
           and b.budget_id = d.budget_id
            AND b.region_group_sid = rg.region_group_sid 
            and ds.donation_status_sid = d.donation_status_sid
            and cur.currency_code = b.currency_code
            and d.entered_by_sid = us.csr_user_sid
           and d.region_sid = region.region_sid;
	r_old							c_values%ROWTYPE;
	r_new							c_values%ROWTYPE;
	v_prev_recipient_sid 			security_pkg.T_SID_ID;
	v_means_paid					donation_status.means_paid%TYPE;
	v_means_donated 				donation_status.means_donated%TYPE;
	v_transition_sid				transition.transition_sid%TYPE;
	v_entered_by_sid				security_pkg.T_SID_ID;
	v_user_sid						security_pkg.T_SID_ID;
	v_contact_name					donation.contact_name%TYPE;
	v_track_donation_end_dtm		scheme.track_donation_end_dtm%TYPE;
	v_track_payments				scheme.track_payments%TYPE;
	t_documents						security.T_SID_TABLE;
	v_app_sid						security_pkg.T_SID_ID;
	v_fields_xml         	 		XMLTYPE;
BEGIN
	v_app_sid := security_pkg.getApp();

	-- fetch old data
	OPEN c_values;
	FETCH c_values INTO r_old;
	CLOSE c_values;

	-- check dates / statuses
	SELECT means_paid, means_donated 
	  INTO v_means_paid, v_means_donated 
	  FROM donation_status
	 WHERE donation_status_sid = in_donation_status_sid;
	
	-- check permissions for donation status
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, r_old.donation_status_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing donation status');
	END IF;
	
	-- check permission on transition
	-- only if status is going to be changed
	-- otherwise we'll have NO DATA FOUND (there's no transition when status doesn't change)
	IF r_old.donation_status_sid != in_donation_status_sid THEN
		SELECT transition_sid 
		  INTO v_transition_sid 
		  FROM transition 
		 WHERE from_donation_status_sid = r_old.donation_status_sid 
		   AND to_donation_status_sid = in_donation_status_sid;
			 
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_transition_sid, scheme_pkg.PERMISSION_TRANSITION_ALLOWED) THEN
			RAISE_APPLICATION_ERROR(scheme_pkg.ERR_TRANSITION_INVALID, 'Current status can''t be changed for selected status');
		END IF;
	END IF;
	 
	-- get track payment
	SELECT track_payments, track_donation_end_dtm
	  INTO v_track_payments, v_track_donation_end_dtm
	  FROM scheme s, donation d
	 WHERE s.scheme_sid = d.scheme_sid
	   AND donation_id = in_donation_id; 

	IF v_means_donated = 1 AND in_donated_dtm IS NULL THEN
		RAISE_APPLICATION_ERROR(scheme_Pkg.ERR_DONATED_DTM_MISSING, 'Donated date required for this status');
	END IF;
	IF v_means_paid = 1 AND in_paid_dtm IS NULL AND v_track_payments = 1 THEN
		RAISE_APPLICATION_ERROR(scheme_Pkg.ERR_PAID_DTM_MISSING, 'Paid date required for this status');
	END IF;
	-- TODO: mandatory v_track_donation_end_dtm TBC

	-- if recipient different then update the used dtm
	SELECT recipient_sid, entered_by_sid
	  INTO v_prev_recipient_sid, v_entered_by_sid
	  FROM donation
	 WHERE donation_id = in_donation_id;
	
	-- check entered_by_sid
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	IF NOT CanUpdate(in_act_id, in_donation_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied amending donation');
	END IF;
	
	IF v_prev_recipient_sid != in_recipient_sid THEN
		UPDATE RECIPIENT 
		   SET LAST_USED_DTM = SYSDATE 
		 WHERE recipient_sid = in_recipient_sid;
	END IF;
	
	
	-- Get recipient contact name
	SELECT contact_name
	  INTO v_contact_name
	  FROM recipient
	 WHERE recipient_sid = in_recipient_sid;
	 
	-- Is the contact name different from the passed contact name
	IF in_contact_name IS NULL OR 
		LOWER(v_contact_name) = LOWER(in_contact_name) THEN
    	v_contact_name := NULL;
	ELSE
    	v_contact_name := in_contact_name;
    END IF;


  IF in_custom_values.count <> 260 THEN 
    RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'CUSTOM VALUES COUNT WRONG');
  END if;
   
	-- TODO: store updated dtm etc?
	UPDATE donation
		SET recipient_sid = in_recipient_sid,
			scheme_sid = in_scheme_sid,
			budget_id = in_budget_id,
			activity = in_activity,
			region_sid = in_region_sid,
			donated_dtm = in_donated_dtm,
			end_dtm = in_end_dtm,
			donation_status_sid = in_donation_status_sid,
			paid_dtm = in_paid_dtm,
			payment_ref = in_payment_ref,
			notes = NVL(in_notes, EMPTY_CLOB()),
			allocated_from_donation_id = in_allocated_from_donation_id,
			extra_values_xml = NVL(in_extra_values_xml, EMPTY_CLOB()),
			letter_body_text = in_letter_text,
			contact_name = v_contact_name,
			custom_1 = in_custom_values(1), --CASE WHEN in_custom_values.EXISTS(1) THEN in_custom_values(1) ELSE custom_1 END,
			custom_2 = in_custom_values(2),
			custom_3 = in_custom_values(3),
			custom_4 = in_custom_values(4),
			custom_5 = in_custom_values(5),
			custom_6 = in_custom_values(6),
			custom_7 = in_custom_values(7),
			custom_8 = in_custom_values(8),
			custom_9 = in_custom_values(9),
			custom_10 = in_custom_values(10),
			custom_11 = in_custom_values(11), 
			custom_12 = in_custom_values(12),
			custom_13 = in_custom_values(13),
			custom_14 = in_custom_values(14),
			custom_15 = in_custom_values(15),
			custom_16 = in_custom_values(16),
			custom_17 = in_custom_values(17),
			custom_18 = in_custom_values(18),
			custom_19 = in_custom_values(19),
			custom_20 = in_custom_values(20),
			custom_21 = in_custom_values(21), 
			custom_22 = in_custom_values(22),
			custom_23 = in_custom_values(23),
			custom_24 = in_custom_values(24),
			custom_25 = in_custom_values(25),
			custom_26 = in_custom_values(26),
			custom_27 = in_custom_values(27),
			custom_28 = in_custom_values(28),
			custom_29 = in_custom_values(29),
			custom_30 = in_custom_values(30),
			custom_31 = in_custom_values(31), 
			custom_32 = in_custom_values(32),
			custom_33 = in_custom_values(33),
			custom_34 = in_custom_values(34),
			custom_35 = in_custom_values(35),
			custom_36 = in_custom_values(36),
			custom_37 = in_custom_values(37),
			custom_38 = in_custom_values(38),
			custom_39 = in_custom_values(39),
			custom_40 = in_custom_values(40),
			custom_41 = in_custom_values(41),
			custom_42 = in_custom_values(42),
			custom_43 = in_custom_values(43),
			custom_44 = in_custom_values(44),
			custom_45 = in_custom_values(45),
			custom_46 = in_custom_values(46),
			custom_47 = in_custom_values(47),
			custom_48 = in_custom_values(48),
			custom_49 = in_custom_values(49),
			custom_50 = in_custom_values(50),
			custom_51 = in_custom_values(51),
			custom_52 = in_custom_values(52),
			custom_53 = in_custom_values(53),
			custom_54 = in_custom_values(54),
			custom_55 = in_custom_values(55),
			custom_56 = in_custom_values(56),
			custom_57 = in_custom_values(57),
			custom_58 = in_custom_values(58),
			custom_59 = in_custom_values(59),
			custom_60 = in_custom_values(60),
			custom_61 = in_custom_values(61), 
			custom_62 = in_custom_values(62),
			custom_63 = in_custom_values(63),
			custom_64 = in_custom_values(64),
			custom_65 = in_custom_values(65),
			custom_66 = in_custom_values(66),
			custom_67 = in_custom_values(67),
			custom_68 = in_custom_values(68),
			custom_69 = in_custom_values(69),
			custom_70 = in_custom_values(70),
			custom_71 = in_custom_values(71),
			custom_72 = in_custom_values(72),
			custom_73 = in_custom_values(73),
			custom_74 = in_custom_values(74),
			custom_75 = in_custom_values(75),
			custom_76 = in_custom_values(76),
			custom_77 = in_custom_values(77),
			custom_78 = in_custom_values(78),
			custom_79 = in_custom_values(79),
			custom_80 = in_custom_values(80),
			custom_81 = in_custom_values(81),
			custom_82 = in_custom_values(82),
			custom_83 = in_custom_values(83),
			custom_84 = in_custom_values(84),
			custom_85 = in_custom_values(85),
			custom_86 = in_custom_values(86),
			custom_87 = in_custom_values(87),
			custom_88 = in_custom_values(88),
			custom_89 = in_custom_values(89),
			custom_90 = in_custom_values(90),
			custom_91 = in_custom_values(91),
			custom_92 = in_custom_values(92),
			custom_93 = in_custom_values(93),
			custom_94 = in_custom_values(94),
			custom_95 = in_custom_values(95),
			custom_96 = in_custom_values(96),
			custom_97 = in_custom_values(97),
			custom_98 = in_custom_values(98),
			custom_99 = in_custom_values(99),
			custom_100 = in_custom_values(100),
			custom_101 = in_custom_values(101),
			custom_102 = in_custom_values(102),
			custom_103 = in_custom_values(103),
			custom_104 = in_custom_values(104),
			custom_105 = in_custom_values(105),
			custom_106 = in_custom_values(106),
			custom_107 = in_custom_values(107),
			custom_108 = in_custom_values(108),
			custom_109 = in_custom_values(109),
			custom_110 = in_custom_values(110),
			custom_111 = in_custom_values(111),
			custom_112 = in_custom_values(112),
			custom_113 = in_custom_values(113),
			custom_114 = in_custom_values(114),
			custom_115 = in_custom_values(115),
			custom_116 = in_custom_values(116),
			custom_117 = in_custom_values(117),
			custom_118 = in_custom_values(118),
			custom_119 = in_custom_values(119),
			custom_120 = in_custom_values(120),
			custom_121 = in_custom_values(121),
			custom_122 = in_custom_values(122),
			custom_123 = in_custom_values(123),
			custom_124 = in_custom_values(124),
			custom_125 = in_custom_values(125),
			custom_126 = in_custom_values(126),
			custom_127 = in_custom_values(127),
			custom_128 = in_custom_values(128),
			custom_129 = in_custom_values(129),
			custom_130 = in_custom_values(130),
			custom_131 = in_custom_values(131),
			custom_132 = in_custom_values(132),
			custom_133 = in_custom_values(133),
			custom_134 = in_custom_values(134),
			custom_135 = in_custom_values(135),
			custom_136 = in_custom_values(136),
			custom_137 = in_custom_values(137),
			custom_138 = in_custom_values(138),
			custom_139 = in_custom_values(139),
			custom_140 = in_custom_values(140),
			custom_141 = in_custom_values(141),
			custom_142 = in_custom_values(142),
			custom_143 = in_custom_values(143),
			custom_144 = in_custom_values(144),
			custom_145 = in_custom_values(145),
			custom_146 = in_custom_values(146),
			custom_147 = in_custom_values(147),
			custom_148 = in_custom_values(148),
			custom_149 = in_custom_values(149),
			custom_150 = in_custom_values(150),
			custom_151 = in_custom_values(151),
			custom_152 = in_custom_values(152),
			custom_153 = in_custom_values(153),
			custom_154 = in_custom_values(154),
			custom_155 = in_custom_values(155),
			custom_156 = in_custom_values(156),
			custom_157 = in_custom_values(157),
			custom_158 = in_custom_values(158),
			custom_159 = in_custom_values(159),
			custom_160 = in_custom_values(160),
			custom_161 = in_custom_values(161),
			custom_162 = in_custom_values(162),
			custom_163 = in_custom_values(163),
			custom_164 = in_custom_values(164),
			custom_165 = in_custom_values(165),
			custom_166 = in_custom_values(166),
			custom_167 = in_custom_values(167),
			custom_168 = in_custom_values(168),
			custom_169 = in_custom_values(169),
			custom_170 = in_custom_values(170),
			custom_171 = in_custom_values(171),
			custom_172 = in_custom_values(172),
			custom_173 = in_custom_values(173),
			custom_174 = in_custom_values(174),
			custom_175 = in_custom_values(175),
			custom_176 = in_custom_values(176),
			custom_177 = in_custom_values(177),
			custom_178 = in_custom_values(178),
			custom_179 = in_custom_values(179),
			custom_180 = in_custom_values(180),
			custom_181 = in_custom_values(181),
			custom_182 = in_custom_values(182),
			custom_183 = in_custom_values(183),
			custom_184 = in_custom_values(184),
			custom_185 = in_custom_values(185),
			custom_186 = in_custom_values(186),
			custom_187 = in_custom_values(187),
			custom_188 = in_custom_values(188),
			custom_189 = in_custom_values(189),
			custom_190 = in_custom_values(190),
			custom_191 = in_custom_values(191),
			custom_192 = in_custom_values(192),
			custom_193 = in_custom_values(193),
			custom_194 = in_custom_values(194),
			custom_195 = in_custom_values(195),
			custom_196 = in_custom_values(196),
			custom_197 = in_custom_values(197),
			custom_198 = in_custom_values(198),
			custom_199 = in_custom_values(199),
			custom_200 = in_custom_values(200),
			custom_201 = in_custom_values(201),
			custom_202 = in_custom_values(202),
			custom_203 = in_custom_values(203),
			custom_204 = in_custom_values(204),
			custom_205 = in_custom_values(205),
			custom_206 = in_custom_values(206),
			custom_207 = in_custom_values(207),
			custom_208 = in_custom_values(208),
			custom_209 = in_custom_values(209),
			custom_210 = in_custom_values(210),
			custom_211 = in_custom_values(211),
			custom_212 = in_custom_values(212),
			custom_213 = in_custom_values(213),
			custom_214 = in_custom_values(214),
			custom_215 = in_custom_values(215),
			custom_216 = in_custom_values(216),
			custom_217 = in_custom_values(217),
			custom_218 = in_custom_values(218),
			custom_219 = in_custom_values(219),
			custom_220 = in_custom_values(220),
			custom_221 = in_custom_values(221),
			custom_222 = in_custom_values(222),
			custom_223 = in_custom_values(223),
			custom_224 = in_custom_values(224),
			custom_225 = in_custom_values(225),
			custom_226 = in_custom_values(226),
			custom_227 = in_custom_values(227),
			custom_228 = in_custom_values(228),
			custom_229 = in_custom_values(229),
			custom_230 = in_custom_values(230),
			custom_231 = in_custom_values(231),
			custom_232 = in_custom_values(232),
			custom_233 = in_custom_values(233),
			custom_234 = in_custom_values(234),
			custom_235 = in_custom_values(235),
			custom_236 = in_custom_values(236),
			custom_237 = in_custom_values(237),
			custom_238 = in_custom_values(238),
			custom_239 = in_custom_values(239),
			custom_240 = in_custom_values(240),
			custom_241 = in_custom_values(241),
			custom_242 = in_custom_values(242),
			custom_243 = in_custom_values(243),
			custom_244 = in_custom_values(244),
			custom_245 = in_custom_values(245),
			custom_246 = in_custom_values(246),
			custom_247 = in_custom_values(247),
			custom_248 = in_custom_values(248),
			custom_249 = in_custom_values(249),
			custom_250 = in_custom_values(250),
			custom_251 = in_custom_values(251),
			custom_252 = in_custom_values(252),
			custom_253 = in_custom_values(253),
			custom_254 = in_custom_values(254),
			custom_255 = in_custom_values(255),
			custom_256 = in_custom_values(256),
			custom_257 = in_custom_values(257),
			custom_258 = in_custom_values(258),
			custom_259 = in_custom_values(259),
			custom_260 = in_custom_values(260)
	WHERE donation_id = in_donation_id;
	
	
	
	-- now we've updated our data, refetch
	OPEN c_values;
	FETCH c_values INTO r_new;
	CLOSE c_values;
	
	
	-- write data to audit
	
	-- donation_status_description
	IF r_old.donation_status_sid != r_new.donation_status_sid THEN
		-- write donation status change only if status changed
		UPDATE donation 
		   SET last_status_changed_dtm = SYSDATE,
			   last_status_changed_by = v_user_sid
		 WHERE donation_id = in_donation_id;
		csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
      		in_scheme_sid, 'Status', r_old.donation_status_description, r_new.donation_status_description, in_donation_id);
	END IF;	

	-- activity
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
      in_scheme_sid, 'Activity', r_old.activity, r_new.activity, in_donation_id);
	
	-- region_description
	  csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
      in_scheme_sid, 'Region', r_old.region_description, r_new.region_description, in_donation_id);
	
	-- recipient_name
	  csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
      in_scheme_sid, 'Recipient', r_old.recipient_name, r_new.recipient_name, in_donation_id);
	
	-- donated_dtm
    csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
      in_scheme_sid, 'Donated date', r_old.donated_dtm, r_new.donated_dtm, in_donation_id);
	
	-- end_dtm
    csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
      in_scheme_sid, 'End date', r_old.end_dtm, r_new.end_dtm, in_donation_id);

	-- paid_dtm
    csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
      in_scheme_sid, 'Paid date', r_old.paid_dtm, r_new.paid_dtm, in_donation_id);
	
	-- payment_ref
    csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
      in_scheme_sid, 'Payment reference', r_old.payment_ref, r_new.payment_ref, in_donation_id);
		
	-- notes
    csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
      in_scheme_sid, 'Payment reference', r_old.notes, r_new.notes, in_donation_id);
	
  -- audit on values
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,1,r_old.custom_1,r_new.custom_1, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,2,r_old.custom_2,r_new.custom_2, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,3,r_old.custom_3,r_new.custom_3, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,4,r_old.custom_4,r_new.custom_4, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,5,r_old.custom_5,r_new.custom_5, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,6,r_old.custom_6,r_new.custom_6, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,7,r_old.custom_7,r_new.custom_7, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,8,r_old.custom_8,r_new.custom_8, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,9,r_old.custom_9,r_new.custom_9, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,10,r_old.custom_10,r_new.custom_10, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,11,r_old.custom_11,r_new.custom_11, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,12,r_old.custom_12,r_new.custom_12, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,13,r_old.custom_13,r_new.custom_13, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,14,r_old.custom_14,r_new.custom_14, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,15,r_old.custom_15,r_new.custom_15, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,16,r_old.custom_16,r_new.custom_16, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,17,r_old.custom_17,r_new.custom_17, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,18,r_old.custom_18,r_new.custom_18, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,19,r_old.custom_19,r_new.custom_19, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,20,r_old.custom_20,r_new.custom_20, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,21,r_old.custom_21,r_new.custom_21, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,22,r_old.custom_22,r_new.custom_22, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,23,r_old.custom_23,r_new.custom_23, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,24,r_old.custom_24,r_new.custom_24, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,25,r_old.custom_25,r_new.custom_25, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,26,r_old.custom_26,r_new.custom_26, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,27,r_old.custom_27,r_new.custom_27, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,28,r_old.custom_28,r_new.custom_28, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,29,r_old.custom_29,r_new.custom_29, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,30,r_old.custom_30,r_new.custom_30, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,31,r_old.custom_31,r_new.custom_31, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,32,r_old.custom_32,r_new.custom_32, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,33,r_old.custom_33,r_new.custom_33, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,34,r_old.custom_34,r_new.custom_34, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,35,r_old.custom_35,r_new.custom_35, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,36,r_old.custom_36,r_new.custom_36, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,37,r_old.custom_37,r_new.custom_37, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,38,r_old.custom_38,r_new.custom_38, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,39,r_old.custom_39,r_new.custom_39, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,40,r_old.custom_40,r_new.custom_40, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,41,r_old.custom_41,r_new.custom_41, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,42,r_old.custom_42,r_new.custom_42, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,43,r_old.custom_43,r_new.custom_43, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,44,r_old.custom_44,r_new.custom_44, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,45,r_old.custom_45,r_new.custom_45, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,46,r_old.custom_46,r_new.custom_46, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,47,r_old.custom_47,r_new.custom_47, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,48,r_old.custom_48,r_new.custom_48, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,49,r_old.custom_49,r_new.custom_49, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,50,r_old.custom_50,r_new.custom_50, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,51,r_old.custom_51,r_new.custom_51, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,52,r_old.custom_52,r_new.custom_52, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,53,r_old.custom_53,r_new.custom_53, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,54,r_old.custom_54,r_new.custom_54, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,55,r_old.custom_55,r_new.custom_55, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,56,r_old.custom_56,r_new.custom_56, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,57,r_old.custom_57,r_new.custom_57, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,58,r_old.custom_58,r_new.custom_58, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,59,r_old.custom_59,r_new.custom_59, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,60,r_old.custom_60,r_new.custom_60, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,61,r_old.custom_61,r_new.custom_61, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,62,r_old.custom_62,r_new.custom_62, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,63,r_old.custom_63,r_new.custom_63, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,64,r_old.custom_64,r_new.custom_64, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,65,r_old.custom_65,r_new.custom_65, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,66,r_old.custom_66,r_new.custom_66, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,67,r_old.custom_67,r_new.custom_67, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,68,r_old.custom_68,r_new.custom_68, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,69,r_old.custom_69,r_new.custom_69, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,70,r_old.custom_70,r_new.custom_70, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,71,r_old.custom_71,r_new.custom_71, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,72,r_old.custom_72,r_new.custom_72, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,73,r_old.custom_73,r_new.custom_73, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,74,r_old.custom_74,r_new.custom_74, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,75,r_old.custom_75,r_new.custom_75, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,76,r_old.custom_76,r_new.custom_76, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,77,r_old.custom_77,r_new.custom_77, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,78,r_old.custom_78,r_new.custom_78, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,79,r_old.custom_79,r_new.custom_79, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,80,r_old.custom_80,r_new.custom_80, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,81,r_old.custom_81,r_new.custom_81, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,82,r_old.custom_82,r_new.custom_82, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,83,r_old.custom_83,r_new.custom_83, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,84,r_old.custom_84,r_new.custom_84, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,85,r_old.custom_85,r_new.custom_85, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,86,r_old.custom_86,r_new.custom_86, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,87,r_old.custom_87,r_new.custom_87, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,88,r_old.custom_88,r_new.custom_88, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,89,r_old.custom_89,r_new.custom_89, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,90,r_old.custom_90,r_new.custom_90, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,91,r_old.custom_91,r_new.custom_91, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,92,r_old.custom_92,r_new.custom_92, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,93,r_old.custom_93,r_new.custom_93, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,94,r_old.custom_94,r_new.custom_94, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,95,r_old.custom_95,r_new.custom_95, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,96,r_old.custom_96,r_new.custom_96, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,97,r_old.custom_97,r_new.custom_97, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,98,r_old.custom_98,r_new.custom_98, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,99,r_old.custom_99,r_new.custom_99, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,100,r_old.custom_100,r_new.custom_100, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,101,r_old.custom_101,r_new.custom_101, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,102,r_old.custom_102,r_new.custom_102, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,103,r_old.custom_103,r_new.custom_103, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,104,r_old.custom_104,r_new.custom_104, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,105,r_old.custom_105,r_new.custom_105, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,106,r_old.custom_106,r_new.custom_106, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,107,r_old.custom_107,r_new.custom_107, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,108,r_old.custom_108,r_new.custom_108, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,109,r_old.custom_109,r_new.custom_109, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,110,r_old.custom_110,r_new.custom_110, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,111,r_old.custom_111,r_new.custom_111, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,112,r_old.custom_112,r_new.custom_112, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,113,r_old.custom_113,r_new.custom_113, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,114,r_old.custom_114,r_new.custom_114, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,115,r_old.custom_115,r_new.custom_115, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,116,r_old.custom_116,r_new.custom_116, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,117,r_old.custom_117,r_new.custom_117, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,118,r_old.custom_118,r_new.custom_118, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,119,r_old.custom_119,r_new.custom_119, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,120,r_old.custom_120,r_new.custom_120, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,121,r_old.custom_121,r_new.custom_121, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,122,r_old.custom_122,r_new.custom_122, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,123,r_old.custom_123,r_new.custom_123, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,124,r_old.custom_124,r_new.custom_124, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,125,r_old.custom_125,r_new.custom_125, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,126,r_old.custom_126,r_new.custom_126, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,127,r_old.custom_127,r_new.custom_127, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,128,r_old.custom_128,r_new.custom_128, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,129,r_old.custom_129,r_new.custom_129, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,130,r_old.custom_130,r_new.custom_130, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,131,r_old.custom_131,r_new.custom_131, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,132,r_old.custom_132,r_new.custom_132, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,133,r_old.custom_133,r_new.custom_133, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,134,r_old.custom_134,r_new.custom_134, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,135,r_old.custom_135,r_new.custom_135, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,136,r_old.custom_136,r_new.custom_136, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,137,r_old.custom_137,r_new.custom_137, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,138,r_old.custom_138,r_new.custom_138, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,139,r_old.custom_139,r_new.custom_139, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,140,r_old.custom_140,r_new.custom_140, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,141,r_old.custom_141,r_new.custom_141, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,142,r_old.custom_142,r_new.custom_142, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,143,r_old.custom_143,r_new.custom_143, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,144,r_old.custom_144,r_new.custom_144, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,145,r_old.custom_145,r_new.custom_145, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,146,r_old.custom_146,r_new.custom_146, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,147,r_old.custom_147,r_new.custom_147, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,148,r_old.custom_148,r_new.custom_148, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,149,r_old.custom_149,r_new.custom_149, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,150,r_old.custom_150,r_new.custom_150, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,151,r_old.custom_151,r_new.custom_151, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,152,r_old.custom_152,r_new.custom_152, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,153,r_old.custom_153,r_new.custom_153, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,154,r_old.custom_154,r_new.custom_154, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,155,r_old.custom_155,r_new.custom_155, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,156,r_old.custom_156,r_new.custom_156, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,157,r_old.custom_157,r_new.custom_157, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,158,r_old.custom_158,r_new.custom_158, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,159,r_old.custom_159,r_new.custom_159, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,160,r_old.custom_160,r_new.custom_160, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,161,r_old.custom_161,r_new.custom_161, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,162,r_old.custom_162,r_new.custom_162, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,163,r_old.custom_163,r_new.custom_163, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,164,r_old.custom_164,r_new.custom_164, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,165,r_old.custom_165,r_new.custom_165, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,166,r_old.custom_166,r_new.custom_166, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,167,r_old.custom_167,r_new.custom_167, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,168,r_old.custom_168,r_new.custom_168, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,169,r_old.custom_169,r_new.custom_169, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,170,r_old.custom_170,r_new.custom_170, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,171,r_old.custom_171,r_new.custom_171, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,172,r_old.custom_172,r_new.custom_172, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,173,r_old.custom_173,r_new.custom_173, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,174,r_old.custom_174,r_new.custom_174, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,175,r_old.custom_175,r_new.custom_175, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,176,r_old.custom_176,r_new.custom_176, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,177,r_old.custom_177,r_new.custom_177, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,178,r_old.custom_178,r_new.custom_178, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,179,r_old.custom_179,r_new.custom_179, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,180,r_old.custom_180,r_new.custom_180, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,181,r_old.custom_181,r_new.custom_181, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,182,r_old.custom_182,r_new.custom_182, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,183,r_old.custom_183,r_new.custom_183, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,184,r_old.custom_184,r_new.custom_184, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,185,r_old.custom_185,r_new.custom_185, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,186,r_old.custom_186,r_new.custom_186, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,187,r_old.custom_187,r_new.custom_187, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,188,r_old.custom_188,r_new.custom_188, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,189,r_old.custom_189,r_new.custom_189, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,190,r_old.custom_190,r_new.custom_190, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,191,r_old.custom_191,r_new.custom_191, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,192,r_old.custom_192,r_new.custom_192, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,193,r_old.custom_193,r_new.custom_193, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,194,r_old.custom_194,r_new.custom_194, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,195,r_old.custom_195,r_new.custom_195, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,196,r_old.custom_196,r_new.custom_196, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,197,r_old.custom_197,r_new.custom_197, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,198,r_old.custom_198,r_new.custom_198, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,199,r_old.custom_199,r_new.custom_199, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,200,r_old.custom_200,r_new.custom_200, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,201,r_old.custom_201,r_new.custom_201, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,202,r_old.custom_202,r_new.custom_202, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,203,r_old.custom_203,r_new.custom_203, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,204,r_old.custom_204,r_new.custom_204, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,205,r_old.custom_205,r_new.custom_205, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,206,r_old.custom_206,r_new.custom_206, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,207,r_old.custom_207,r_new.custom_207, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,208,r_old.custom_208,r_new.custom_208, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,209,r_old.custom_209,r_new.custom_209, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,210,r_old.custom_210,r_new.custom_210, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,211,r_old.custom_211,r_new.custom_211, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,212,r_old.custom_212,r_new.custom_212, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,213,r_old.custom_213,r_new.custom_213, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,214,r_old.custom_214,r_new.custom_214, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,215,r_old.custom_215,r_new.custom_215, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,216,r_old.custom_216,r_new.custom_216, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,217,r_old.custom_217,r_new.custom_217, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,218,r_old.custom_218,r_new.custom_218, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,219,r_old.custom_219,r_new.custom_219, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,220,r_old.custom_220,r_new.custom_220, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,221,r_old.custom_221,r_new.custom_221, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,222,r_old.custom_222,r_new.custom_222, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,223,r_old.custom_223,r_new.custom_223, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,224,r_old.custom_224,r_new.custom_224, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,225,r_old.custom_225,r_new.custom_225, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,226,r_old.custom_226,r_new.custom_226, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,227,r_old.custom_227,r_new.custom_227, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,228,r_old.custom_228,r_new.custom_228, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,229,r_old.custom_229,r_new.custom_229, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,230,r_old.custom_230,r_new.custom_230, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,231,r_old.custom_231,r_new.custom_231, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,232,r_old.custom_232,r_new.custom_232, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,233,r_old.custom_233,r_new.custom_233, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,234,r_old.custom_234,r_new.custom_234, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,235,r_old.custom_235,r_new.custom_235, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,236,r_old.custom_236,r_new.custom_236, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,237,r_old.custom_237,r_new.custom_237, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,238,r_old.custom_238,r_new.custom_238, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,239,r_old.custom_239,r_new.custom_239, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,240,r_old.custom_240,r_new.custom_240, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,241,r_old.custom_241,r_new.custom_241, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,242,r_old.custom_242,r_new.custom_242, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,243,r_old.custom_243,r_new.custom_243, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,244,r_old.custom_244,r_new.custom_244, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,245,r_old.custom_245,r_new.custom_245, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,246,r_old.custom_246,r_new.custom_246, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,247,r_old.custom_247,r_new.custom_247, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,248,r_old.custom_248,r_new.custom_248, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,249,r_old.custom_249,r_new.custom_249, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,250,r_old.custom_250,r_new.custom_250, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,251,r_old.custom_251,r_new.custom_251, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,252,r_old.custom_252,r_new.custom_252, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,253,r_old.custom_253,r_new.custom_253, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,254,r_old.custom_254,r_new.custom_254, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,255,r_old.custom_255,r_new.custom_255, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,256,r_old.custom_256,r_new.custom_256, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,257,r_old.custom_257,r_new.custom_257, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,258,r_old.custom_258,r_new.custom_258, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,259,r_old.custom_259,r_new.custom_259, in_donation_id);
	AuditFieldValueChange(in_act_id, v_app_sid, in_scheme_sid,260,r_old.custom_260,r_new.custom_260, in_donation_id);
	
	-- Write audit entry on text fields
	-- store fields info xml
	SELECT XMLTYPE(EXTRA_FIELDS_XML) INTO v_fields_xml FROM scheme WHERE scheme_sid = in_scheme_sid;
	AuditInfoXmlChanges(in_act_id, v_app_sid, in_scheme_sid, v_fields_xml, r_old.extra_values_xml, r_new.extra_values_xml, in_donation_id);

	-- audit on documents ? 
	-- fiddle documents
	t_documents := security_pkg.SidArrayToTable(in_document_sids);
	-- delete all 
	DELETE FROM donation_doc WHERE donation_id = in_donation_id;
	-- insert updated
	INSERT INTO donation_doc (donation_id, document_sid) 
                (SELECT in_donation_id, column_value
                  FROM TABLE(t_documents) where column_value != -1);
END;


-- 
-- PROCEDURE: DeleteDONATION 
--
PROCEDURE DeleteDonation (
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_donation_id	IN donation.donation_Id%TYPE
)
AS
	v_scheme_sid		security_pkg.T_SID_ID;
	v_user_sid			security_pkg.T_SID_ID;
	v_entered_by_sid	security_pkg.T_SID_ID;
	v_app_sid         	security_pkg.T_SID_ID;
	v_fc_cnt			NUMBER(1);
BEGIN
	v_app_sid := security_pkg.GetApp();
  
	BEGIN
		SELECT scheme_sid, entered_by_sid 	
		  INTO v_scheme_sid, v_entered_by_sid
		  FROM donation
		 WHERE donation_id = in_donation_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Donation not found');
	END;
		
	
	IF NOT CanUpdate(in_act_id, in_donation_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied amending donation');
	END IF;
	
	SELECT count(*) 
	  INTO v_fc_cnt
	  FROM fc_donation
	 WHERE donation_id = in_donation_id;
	
	IF v_fc_cnt != 0 THEN
		RAISE_APPLICATION_ERROR(scheme_pkg.ERR_DELETE_FC_DONATION, 'Can''t delete donation that belongs to funding commitment.');
	END IF;
		
		
	DELETE FROM donation_tag
		WHERE donation_id = in_donation_id;
    DELETE FROM donation_doc
		WHERE donation_id = in_donation_id;		
	DELETE FROM donation
		WHERE donation_id = in_donation_id;
	
	
	csr.csr_data_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
        v_scheme_sid, 'Donation with id {0} has been deleted', in_donation_id, null, null, in_donation_id);
        
END;

FUNCTION ConcatTagIds(
	in_donation_id	IN	donation.donation_id%TYPE
) RETURN VARCHAR2
AS
	v_s		VARCHAR2(4096);	
	v_sep	VARCHAR2(2);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (SELECT tag_id FROM DONATION_TAG WHERE DONATION_ID = in_donation_id)
	LOOP
		v_s := v_s || v_sep || r.tag_id;
		v_sep := ',';
	END LOOP;	
	RETURN v_s;
END;

FUNCTION ConcatTags(
	in_donation_id	IN	donation.donation_id%TYPE,
	in_max_length		IN 	INTEGER DEFAULT 10
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(512);
	v_sep VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (
		SELECT tag FROM DONATION_TAG dt, TAG t 
		 WHERE DONATION_ID = in_donation_id
		   AND dt.tag_id = t.tag_id
	)
	LOOP
		IF LENGTH(v_s) + LENGTH(r.tag) + 3 >= in_max_length THEN
			v_s := v_s || '...';
			EXIT;
		END IF;
		v_s := v_s || v_sep || r.tag;		
		v_sep := ', ';
	END LOOP;
	RETURN v_s;
END;

FUNCTION ConcatRecipientTagIds(
	in_recipient_sid	IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_s		VARCHAR2(4096);	
	v_sep	VARCHAR2(2);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (SELECT tag_id FROM RECIPIENT_TAG WHERE RECIPIENT_SID = in_recipient_sid)
	LOOP
		v_s := v_s || v_sep || r.tag_id;
		v_sep := ',';
	END LOOP;	
	RETURN v_s;
END;

FUNCTION ConcatRecipientTags(
	in_recipient_sid	IN	security_pkg.T_SID_ID,
	in_max_length		IN 	INTEGER DEFAULT 10
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(512);
	v_sep VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (
		SELECT tag FROM RECIPIENT_TAG rt, TAG t 
		 WHERE recipient_sid = in_recipient_sid
		   AND rt.tag_id = t.tag_id
	)
	LOOP
		IF LENGTH(v_s) + LENGTH(r.tag) + 3 >= in_max_length THEN
			v_s := v_s || '...';
			EXIT;
		END IF;
		v_s := v_s || v_sep || r.tag;		
		v_sep := ', ';
	END LOOP;
	RETURN v_s;
END;


FUNCTION ConcatRegionTagIds(
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_s		VARCHAR2(4096);	
	v_sep	VARCHAR2(2);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (SELECT tag_id FROM csr.REGION_TAG WHERE REGION_SID = in_region_sid)
	LOOP
		v_s := v_s || v_sep || r.tag_id;
		v_sep := ',';
	END LOOP;	
	RETURN v_s;
END;


FUNCTION ConcatRegionTags(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_max_length		IN 	INTEGER DEFAULT 10
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(512);
	v_sep VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (
		SELECT tag FROM csr.REGION_TAG rt, csr.v$TAG t 
		 WHERE region_sid = in_region_sid
		   AND rt.tag_id = t.tag_id
	)
	LOOP
		IF LENGTH(v_s) + LENGTH(r.tag) + 3 >= in_max_length THEN
			v_s := v_s || '...';
			EXIT;
		END IF;
		v_s := v_s || v_sep || r.tag;		
		v_sep := ', ';
	END LOOP;
	RETURN v_s;
END;


PROCEDURE INTERNAL_GetDonations(
	t_ids				IN	security.T_SID_TABLE,
	out_cur				OUT security_Pkg.T_OUTPUT_CUR,
	out_docs			OUT	security_Pkg.T_OUTPUT_CUR,
	out_tags			OUT	security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_docs FOR
		SELECT dd.donation_id, dd.document_sid, dd.description, fu.filename, fu.mime_type
		  FROM donation_doc dd
			JOIN csr.file_Upload fu ON dd.document_sid = fu.file_upload_sid
		 WHERE dd.donation_id IN (
			 SELECT column_value FROM TABLE(t_ids)
		  );
		 		
	OPEN out_tags FOR
		SELECT dt.donation_id, t.tag, tg.name group_name
		  FROM donation_tag dt
			JOIN tag t ON dt.tag_id = t.tag_id
			JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id
			JOIN tag_group tg ON tgm.tag_group_sid = tg.tag_group_sid
		 WHERE dt.donation_id IN (
			 SELECT column_value FROM TABLE(t_ids)
		  );
	
	OPEN out_cur FOR
		SELECT d.donation_id, d.activity, d.entered_dtm,  
			NVL(cue.full_name, 'n/a') entered_full_name, NVL(cue.email, 'n/a') entered_email, 
			d.letter_body_text, 
			-- this looks dodgy but it's used elsewhere
			CASE WHEN ds.means_donated = 1 THEN d.donated_dtm ELSE NULL END donated_dtm, 
			CASE WHEN s.track_donation_end_dtm = 1 THEN d.end_dtm ELSE NULL END end_dtm,
			CASE WHEN ds.means_paid = 1 THEN d.paid_dtm ELSE NULL END paid_dtm,
			d.payment_ref,
			ds.description donation_status_description, ds.colour status_colour,
			s.scheme_sid, s.name scheme_name, 
			b.budget_id, b.description budget_description, 
			b.currency_code, cur.symbol currency_symbol,
			rg.description region_group_description,
			custom_1, custom_2, custom_3, custom_4, custom_5,
			custom_6, custom_7, custom_8, custom_9, custom_10,
			custom_11, custom_12, custom_13, custom_14, custom_15,
			custom_16, custom_17, custom_18, custom_19, custom_20,
			custom_21, custom_22, custom_23, custom_24, custom_25,
			custom_26, custom_27, custom_28, custom_29, custom_30,
			custom_31, custom_32, custom_33, custom_34, custom_35,
			custom_36, custom_37, custom_38, custom_39, custom_40,
			custom_41, custom_42, custom_43, custom_44, custom_45,
			custom_46, custom_47, custom_48, custom_49, custom_50,
			custom_51, custom_52, custom_53, custom_54, custom_55,
			custom_56, custom_57, custom_58, custom_59, custom_60,
			custom_61, custom_62, custom_63, custom_64, custom_65,
			custom_66, custom_67, custom_68, custom_69, custom_70,
			custom_71, custom_72, custom_73, custom_74, custom_75,
			custom_76, custom_77, custom_78, custom_79, custom_80,
			custom_81, custom_82, custom_83, custom_84, custom_85,
			custom_86, custom_87, custom_88, custom_89, custom_90,
			custom_91, custom_92, custom_93, custom_94, custom_95,
			custom_96, custom_97, custom_98, custom_99, custom_100,
			custom_101, custom_102, custom_103, custom_104, custom_105,
			custom_106, custom_107, custom_108, custom_109, custom_110, 
			custom_111, custom_112, custom_113, custom_114, custom_115,
			custom_116, custom_117, custom_118, custom_119, custom_120,
			custom_121, custom_122, custom_123, custom_124, custom_125,
			custom_126, custom_127, custom_128, custom_129, custom_130,
			custom_131, custom_132, custom_133, custom_134, custom_135,
			custom_136, custom_137, custom_138, custom_139, custom_140,
			custom_141, custom_142, custom_143, custom_144, custom_145,
			custom_146, custom_147, custom_148, custom_149, custom_150,
			custom_151, custom_152, custom_153, custom_154, custom_155,
			custom_156, custom_157, custom_158, custom_159, custom_160,
			custom_161, custom_162, custom_163, custom_164, custom_165,
			custom_166, custom_167, custom_168, custom_169, custom_170,
			custom_171, custom_172, custom_173, custom_174, custom_175,
			custom_176, custom_177, custom_178, custom_179, custom_180,
			custom_181, custom_182, custom_183, custom_184, custom_185,
			custom_186, custom_187, custom_188, custom_189, custom_190,
			custom_191, custom_192, custom_193, custom_194, custom_195,
			custom_196, custom_197, custom_198, custom_199, custom_200,
			custom_201, custom_202, custom_203, custom_204, custom_205,
			custom_206, custom_207, custom_208, custom_209, custom_210,
			custom_211, custom_212, custom_213, custom_214, custom_215,
			custom_216, custom_217, custom_218, custom_219, custom_220,
			custom_221, custom_222, custom_223, custom_224, custom_225,
			custom_226, custom_227, custom_228, custom_229, custom_230,
			custom_231, custom_232, custom_233, custom_234, custom_235,
			custom_236, custom_237, custom_238, custom_239, custom_240,
			custom_241, custom_242, custom_243, custom_244, custom_245,
			custom_246, custom_247, custom_248, custom_249, custom_250,
			custom_251, custom_252, custom_253, custom_254, custom_255,
			custom_256, custom_257, custom_258, custom_259, custom_260
		  FROM donation d
			JOIN donation_status ds ON d.donation_status_sid = ds.donation_status_sid
			JOIN scheme s ON d.scheme_sid = s.scheme_sid
			JOIN budget b ON d.budget_id = b.budget_id
			JOIN csr.csr_user cue ON d.entered_by_sid = cue.csr_user_sid 
			JOIN region_group rg ON b.region_group_sid = rg.region_group_sid
			JOIN currency cur ON b.currency_code = cur.currency_code
		 WHERE d.donation_id IN (
			 SELECT column_value FROM TABLE(t_ids)
		  )
		 ORDER BY entered_dtm DESC;
END;

PROCEDURE INTERNAL_GetSchemeTables(
	in_act_id			IN  security_pkg.T_ACT_ID,
	out_view_mine 		OUT	T_SCHEME_TABLE,
	out_view_region 	OUT	T_SCHEME_TABLE,
	out_view_all 		OUT	T_SCHEME_TABLE
)
AS
BEGIN
	out_view_mine 	:= T_SCHEME_TABLE();
	out_view_region := T_SCHEME_TABLE();
	out_view_all 	:= T_SCHEME_TABLE();
	
	-- check for permissions on schemes?
	-- quickest thing is to go through all schemes and work out which ones fit	
	FOR r IN  (
		 SELECT scheme_sid 
		   FROM scheme
		  WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	)
	LOOP
		IF security_pkg.IsAccessAllowedSID(in_act_id, r.scheme_sid, scheme_pkg.PERMISSION_VIEW_ALL) THEN
			out_view_all.extend;
			out_view_all( out_view_all.COUNT ) := T_SCHEME_ROW( r.scheme_sid );	
		ELSIF security_pkg.IsAccessAllowedSID(in_act_id, r.scheme_sid, scheme_pkg.PERMISSION_VIEW_REGION) THEN
			out_view_region.extend;
			out_view_region( out_view_region.COUNT ) := T_SCHEME_ROW( r.scheme_sid );		
		ELSIF security_pkg.IsAccessAllowedSID(in_act_id, r.scheme_sid, scheme_pkg.PERMISSION_VIEW_MINE) THEN
			out_view_mine.extend;
			out_view_mine( out_view_mine.COUNT ) := T_SCHEME_ROW( r.scheme_sid );		
		END IF;
	END LOOP;
END;


PROCEDURE GetDonationsForStatuses(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_status_sids		IN  security_pkg.T_SID_IDS,	
	out_cur				OUT security_Pkg.T_OUTPUT_CUR,
	out_docs			OUT	security_Pkg.T_OUTPUT_CUR,
	out_tags			OUT	security_Pkg.T_OUTPUT_CUR
)
AS
	t_status_sids	security.T_SID_TABLE;
	t_ids			security.T_SID_TABLE;
	v_user_sid		security_pkg.T_SID_ID;
	t_view_mine 	T_SCHEME_TABLE;
	t_view_region 	T_SCHEME_TABLE;
	t_view_all 		T_SCHEME_TABLE;
BEGIN
	t_status_sids := security_pkg.SidArrayToTable(in_status_sids);
	
	INTERNAL_GetSchemeTables(
		in_act_id,
		t_view_mine,
		t_view_region,
		t_view_all
	);
	
	v_user_sid := security_pkg.getSid;
	
	SELECT donation_id
	  BULK COLLECT INTO t_ids
	  FROM donation
	 WHERE donation_status_sid IN (
			SELECT column_value from TABLE(t_status_sids)
		)
		-- consider returning all info but blanking it out in the UI? i.e. otherwise it appears no money donated
	   AND (
			(entered_by_sid = v_user_sid AND scheme_sid IN (SELECT scheme_sid FROM TABLE(t_view_mine)))
			OR (region_sid IN (SELECT region_sid FROM csr.region_owner WHERE user_sid = v_user_sid) 
				AND scheme_sid IN (SELECT scheme_sid FROM TABLE(t_view_region)))
			OR (scheme_sid IN (SELECT scheme_sid FROM TABLE(t_view_all)))
		);
	 			
	INTERNAL_GetDonations(t_ids, out_cur, out_docs, out_tags);
END;


PROCEDURE GetDonationsForRecipient(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_recipient_sid	IN  security_pkg.T_SID_ID,	
	out_cur				OUT security_Pkg.T_OUTPUT_CUR,
	out_docs			OUT	security_Pkg.T_OUTPUT_CUR,
	out_tags			OUT	security_Pkg.T_OUTPUT_CUR
)
AS
	t_ids			security.T_SID_TABLE;
	v_user_sid		security_pkg.T_SID_ID;
	t_view_mine 	T_SCHEME_TABLE;
	t_view_region 	T_SCHEME_TABLE;
	t_view_all 		T_SCHEME_TABLE;
BEGIN
	
	INTERNAL_GetSchemeTables(
		in_act_id,
		t_view_mine,
		t_view_region,
		t_view_all
	);
	
	v_user_sid := security_pkg.getSid;
	
	SELECT donation_id
	  BULK COLLECT INTO t_ids
	  FROM donation
	 WHERE recipient_sid = in_recipient_sid	
		-- consider returning all info but blanking it out in the UI? i.e. otherwise it appears no money donated
	   AND (
			(entered_by_sid = v_user_sid AND scheme_sid IN (SELECT scheme_sid FROM TABLE(t_view_mine)))
			OR (region_sid IN (SELECT region_sid FROM csr.region_owner WHERE user_sid = v_user_sid) 
				AND scheme_sid IN (SELECT scheme_sid FROM TABLE(t_view_region)))
			OR (scheme_sid IN (SELECT scheme_sid FROM TABLE(t_view_all)))
		);
	 			
	INTERNAL_GetDonations(t_ids, out_cur, out_docs, out_tags);
END;


/* legacy code */
PROCEDURE GetDonationsCountForRecipient(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_recipient_sid	IN  security_pkg.T_SID_ID,
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
		SELECT COUNT(*) CNT
		  FROM donation d
		 WHERE recipient_sid = in_recipient_sid;
END;

/* legacy code */
PROCEDURE GetDonationsListForRecipient(
    in_act_id					IN  security_pkg.T_ACT_ID,
	in_recipient_sid	        IN  security_pkg.T_SID_ID,
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
    SELECT donation_id, activity, ds.description donation_status_description, CASE WHEN ds.means_donated= 1 THEN to_char(donated_dtm, 'yyyy-mm-dd') ELSE null END donated_dtm_fmt
	  FROM donation d, donation_status ds
	 WHERE recipient_sid = in_recipient_sid
	   AND d.donation_status_sid = ds.donation_status_sid ;
END;




-- TODO: alter to return cursors for budget etc? or do via parent object in Assembly?
PROCEDURE GetDonation(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_donation_id		IN  donation.donation_id%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur       OUT Security_pkg.T_OUTPUT_CUR
)
AS
	v_scheme_sid		security_pkg.T_SID_ID;
	v_just_mine			number(1);
	v_just_region		number(1);
BEGIN
	-- get scheme from budget
	SELECT scheme_sid INTO v_scheme_sid
	  FROM DONATION
	 WHERE donation_id = in_donation_id;

	-- what permissions?
	IF security_pkg.IsAccessAllowedSID(in_act_id, v_scheme_sid, scheme_Pkg.PERMISSION_VIEW_ALL) THEN
		v_just_region := 0;
		v_just_mine	:= 0;
	ELSIF  security_pkg.IsAccessAllowedSID(in_act_id, v_scheme_sid, scheme_Pkg.PERMISSION_VIEW_REGION) THEN
		v_just_region := 1;
		v_just_mine	:= 0;
	ELSIF  security_pkg.IsAccessAllowedSID(in_act_id, v_scheme_sid, scheme_Pkg.PERMISSION_VIEW_MINE) THEN
		v_just_region := 0;
		v_just_mine	:= 1;
	ELSE
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied viewing donations for scheme');
	END IF;

	OPEN out_cur FOR
		SELECT donation_id, 
			d.region_sid, donation_status_sid, activity, entered_dtm, entered_by_sid, donated_dtm, d.end_dtm, paid_dtm, payment_ref,
			notes, extra_values_Xml, d.scheme_sid, b.region_group_sid, b.budget_id, allocated_from_donation_id,
			r.recipient_sid, org_name, NVL(d.contact_name, r.contact_name) contact_name, address_1, address_2, address_3, address_4,
			town, state, postcode, phone, fax, email, last_used_dtm, country_code, ref, letter_body_text,
			 custom_1, custom_2, custom_3, custom_4, custom_5,
			 custom_6, custom_7, custom_8, custom_9, custom_10,
			 custom_11, custom_12, custom_13, custom_14, custom_15,
			 custom_16, custom_17, custom_18, custom_19, custom_20,
			 custom_21, custom_22, custom_23, custom_24, custom_25,
			 custom_26, custom_27, custom_28, custom_29, custom_30,
			 custom_31, custom_32, custom_33, custom_34, custom_35,
			 custom_36, custom_37, custom_38, custom_39, custom_40,
			 custom_41, custom_42, custom_43, custom_44, custom_45,
			 custom_46, custom_47, custom_48, custom_49, custom_50,
			 custom_51, custom_52, custom_53, custom_54, custom_55,
			 custom_56, custom_57, custom_58, custom_59, custom_60,
			custom_61, custom_62, custom_63, custom_64, custom_65,
			custom_66, custom_67, custom_68, custom_69, custom_70,
			custom_71, custom_72, custom_73, custom_74, custom_75,
			custom_76, custom_77, custom_78, custom_79, custom_80,
			custom_81, custom_82, custom_83, custom_84, custom_85,
			custom_86, custom_87, custom_88, custom_89, custom_90,
			custom_91, custom_92, custom_93, custom_94, custom_95,
			custom_96, custom_97, custom_98, custom_99, custom_100,
			custom_101, custom_102, custom_103, custom_104, custom_105,
			custom_106, custom_107, custom_108, custom_109, custom_110, 
			custom_111, custom_112, custom_113, custom_114, custom_115,
			custom_116, custom_117, custom_118, custom_119, custom_120,
			custom_121, custom_122, custom_123, custom_124, custom_125,
			custom_126, custom_127, custom_128, custom_129, custom_130,
			custom_131, custom_132, custom_133, custom_134, custom_135,
			custom_136, custom_137, custom_138, custom_139, custom_140,
			custom_141, custom_142, custom_143, custom_144, custom_145,
			custom_146, custom_147, custom_148, custom_149, custom_150,
			custom_151, custom_152, custom_153, custom_154, custom_155,
			custom_156, custom_157, custom_158, custom_159, custom_160,
			custom_161, custom_162, custom_163, custom_164, custom_165,
			custom_166, custom_167, custom_168, custom_169, custom_170,
			custom_171, custom_172, custom_173, custom_174, custom_175,
			custom_176, custom_177, custom_178, custom_179, custom_180,
			custom_181, custom_182, custom_183, custom_184, custom_185,
			custom_186, custom_187, custom_188, custom_189, custom_190,
			custom_191, custom_192, custom_193, custom_194, custom_195,
			custom_196, custom_197, custom_198, custom_199, custom_200,
			custom_201, custom_202, custom_203, custom_204, custom_205,
			custom_206, custom_207, custom_208, custom_209, custom_210,
			custom_211, custom_212, custom_213, custom_214, custom_215,
			custom_216, custom_217, custom_218, custom_219, custom_220,
			custom_221, custom_222, custom_223, custom_224, custom_225,
			custom_226, custom_227, custom_228, custom_229, custom_230,
			custom_231, custom_232, custom_233, custom_234, custom_235,
			custom_236, custom_237, custom_238, custom_239, custom_240,
			custom_241, custom_242, custom_243, custom_244, custom_245,
			custom_246, custom_247, custom_248, custom_249, custom_250,
			custom_251, custom_252, custom_253, custom_254, custom_255,
			custom_256, custom_257, custom_258, custom_259, custom_260
		  FROM donation d, recipient r, budget b
		 WHERE donation_id = in_donation_id
		   AND d.recipient_sid = r.recipient_sid
		   AND d.budget_id = b.budget_id;
    
    OPEN documents_cur FOR
            SELECT document_sid 
              FROM donation_doc 
             WHERE donation_id = in_donation_id;
	
END;		 

/*
FUNCTION ConcatTagGroupMembers(
	in_donation_id		IN	
	in_tag_group_sid	IN	security_pkg.T_SID_ID,
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(512);
	v_sep VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (
		SELECT tag
		  FROM tag_group_member tgm, tag t, donation_tag dt
		 WHERE tgm.tag_id = t.tag_id
		   AND tgm.tag_group_sid = in_tag_group_sid
		   AND dt.donation_id = in_donation_id
		   AND t.tag_id = dt.tag_id)
	LOOP
		v_s := v_s || v_sep || r.tag;		
		v_sep := ', ';
	END LOOP;
	RETURN v_s;
END;
*/

PROCEDURE GetDonationsForApp(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_app_sid			IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur		OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT donation_id, 
			region_sid, donation_status_sid, activity, entered_dtm, entered_by_sid, donated_dtm, paid_dtm, d.end_dtm, payment_ref, 
			notes, extra_values_Xml, scheme_sid, budget_id, allocated_from_donation_id, recipient_sid, letter_body_text, contact_name,
			 custom_1, custom_2, custom_3, custom_4, custom_5,
			 custom_6, custom_7, custom_8, custom_9, custom_10,
			 custom_11, custom_12, custom_13, custom_14, custom_15,
			 custom_16, custom_17, custom_18, custom_19, custom_20,
			 custom_21, custom_22, custom_23, custom_24, custom_25,
			 custom_26, custom_27, custom_28, custom_29, custom_30,
			 custom_31, custom_32, custom_33, custom_34, custom_35,
			 custom_36, custom_37, custom_38, custom_39, custom_40,
			 custom_41, custom_42, custom_43, custom_44, custom_45,
			 custom_46, custom_47, custom_48, custom_49, custom_50,
			 custom_51, custom_52, custom_53, custom_54, custom_55,
			 custom_56, custom_57, custom_58, custom_59, custom_60,
			 custom_61, custom_62, custom_63, custom_64, custom_65,
			 custom_66, custom_67, custom_68, custom_69, custom_70,
			 custom_71, custom_72, custom_73, custom_74, custom_75,
			 custom_76, custom_77, custom_78, custom_79, custom_80,
			 custom_81, custom_82, custom_83, custom_84, custom_85,
			 custom_86, custom_87, custom_88, custom_89, custom_90,
			 custom_91, custom_92, custom_93, custom_94, custom_95,
			 custom_96, custom_97, custom_98, custom_99, custom_100,
			 custom_101, custom_102, custom_103, custom_104, custom_105,
			 custom_106, custom_107, custom_108, custom_109, custom_110, 
			 custom_111, custom_112, custom_113, custom_114, custom_115,
			 custom_116, custom_117, custom_118, custom_119, custom_120,
			 custom_121, custom_122, custom_123, custom_124, custom_125,
			 custom_126, custom_127, custom_128, custom_129, custom_130,
			 custom_131, custom_132, custom_133, custom_134, custom_135,
			 custom_136, custom_137, custom_138, custom_139, custom_140,
			 custom_141, custom_142, custom_143, custom_144, custom_145,
			 custom_146, custom_147, custom_148, custom_149, custom_150,
			 custom_151, custom_152, custom_153, custom_154, custom_155,
			 custom_156, custom_157, custom_158, custom_159, custom_160,
			 custom_161, custom_162, custom_163, custom_164, custom_165,
			 custom_166, custom_167, custom_168, custom_169, custom_170,
			 custom_171, custom_172, custom_173, custom_174, custom_175,
			 custom_176, custom_177, custom_178, custom_179, custom_180,
			 custom_181, custom_182, custom_183, custom_184, custom_185,
			 custom_186, custom_187, custom_188, custom_189, custom_190,
			 custom_191, custom_192, custom_193, custom_194, custom_195,
			 custom_196, custom_197, custom_198, custom_199, custom_200,
			 custom_201, custom_202, custom_203, custom_204, custom_205,
			 custom_206, custom_207, custom_208, custom_209, custom_210,
			 custom_211, custom_212, custom_213, custom_214, custom_215,
			 custom_216, custom_217, custom_218, custom_219, custom_220,
			 custom_221, custom_222, custom_223, custom_224, custom_225,
			 custom_226, custom_227, custom_228, custom_229, custom_230,
			 custom_231, custom_232, custom_233, custom_234, custom_235,
			 custom_236, custom_237, custom_238, custom_239, custom_240,
			 custom_241, custom_242, custom_243, custom_244, custom_245,
			 custom_246, custom_247, custom_248, custom_249, custom_250,
			 custom_251, custom_252, custom_253, custom_254, custom_255,
			 custom_256, custom_257, custom_258, custom_259, custom_260
		  FROM donation d
		 WHERE scheme_sid IN (
		 	SELECT scheme_sid
		 	  FROM scheme
		 	 WHERE app_sid = in_app_sid
		 );
		 
    OPEN documents_cur FOR
        SELECT document_sid, donation_id 
          FROM donation_doc 
         WHERE donation_id IN (select donation_id from donation where scheme_sid IN (
                SELECT scheme_sid
                  FROM scheme
                 WHERE app_sid = in_app_sid
             )
        );
END;

PROCEDURE GetDonationsForScheme(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_scheme_sid		IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur       OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT donation_id, 
			region_sid, donation_status_sid, activity, entered_dtm, entered_by_sid, donated_dtm, d.end_dtm, paid_dtm, payment_ref, 
			notes, extra_values_Xml, scheme_sid, budget_id, allocated_from_donation_id, recipient_sid, letter_body_text, contact_name,
			custom_1, custom_2, custom_3, custom_4, custom_5,
			custom_6, custom_7, custom_8, custom_9, custom_10,
			custom_11, custom_12, custom_13, custom_14, custom_15,
			custom_16, custom_17, custom_18, custom_19, custom_20,
			custom_21, custom_22, custom_23, custom_24, custom_25,
			custom_26, custom_27, custom_28, custom_29, custom_30,
			custom_31, custom_32, custom_33, custom_34, custom_35,
			custom_36, custom_37, custom_38, custom_39, custom_40,
			custom_41, custom_42, custom_43, custom_44, custom_45,
			custom_46, custom_47, custom_48, custom_49, custom_50,
			custom_51, custom_52, custom_53, custom_54, custom_55,
			custom_56, custom_57, custom_58, custom_59, custom_60,
			custom_61, custom_62, custom_63, custom_64, custom_65,
			custom_66, custom_67, custom_68, custom_69, custom_70,
			custom_71, custom_72, custom_73, custom_74, custom_75,
			custom_76, custom_77, custom_78, custom_79, custom_80,
			custom_81, custom_82, custom_83, custom_84, custom_85,
			custom_86, custom_87, custom_88, custom_89, custom_90,
			custom_91, custom_92, custom_93, custom_94, custom_95,
			custom_96, custom_97, custom_98, custom_99, custom_100,
			custom_101, custom_102, custom_103, custom_104, custom_105,
			custom_106, custom_107, custom_108, custom_109, custom_110, 
			custom_111, custom_112, custom_113, custom_114, custom_115,
			custom_116, custom_117, custom_118, custom_119, custom_120,
			custom_121, custom_122, custom_123, custom_124, custom_125,
			custom_126, custom_127, custom_128, custom_129, custom_130,
			custom_131, custom_132, custom_133, custom_134, custom_135,
			custom_136, custom_137, custom_138, custom_139, custom_140,
			custom_141, custom_142, custom_143, custom_144, custom_145,
			custom_146, custom_147, custom_148, custom_149, custom_150,
			custom_151, custom_152, custom_153, custom_154, custom_155,
			custom_156, custom_157, custom_158, custom_159, custom_160,
			custom_161, custom_162, custom_163, custom_164, custom_165,
			custom_166, custom_167, custom_168, custom_169, custom_170,
			custom_171, custom_172, custom_173, custom_174, custom_175,
			custom_176, custom_177, custom_178, custom_179, custom_180,
			custom_181, custom_182, custom_183, custom_184, custom_185,
			custom_186, custom_187, custom_188, custom_189, custom_190,
			custom_191, custom_192, custom_193, custom_194, custom_195,
			custom_196, custom_197, custom_198, custom_199, custom_200,
			custom_201, custom_202, custom_203, custom_204, custom_205,
			custom_206, custom_207, custom_208, custom_209, custom_210,
			custom_211, custom_212, custom_213, custom_214, custom_215,
			custom_216, custom_217, custom_218, custom_219, custom_220,
			custom_221, custom_222, custom_223, custom_224, custom_225,
			custom_226, custom_227, custom_228, custom_229, custom_230,
			custom_231, custom_232, custom_233, custom_234, custom_235,
			custom_236, custom_237, custom_238, custom_239, custom_240,
			custom_241, custom_242, custom_243, custom_244, custom_245,
			custom_246, custom_247, custom_248, custom_249, custom_250,
			custom_251, custom_252, custom_253, custom_254, custom_255,
			custom_256, custom_257, custom_258, custom_259, custom_260
		  FROM donation d
		 WHERE scheme_sid = in_scheme_sid;
    
    OPEN documents_cur FOR
        SELECT document_sid, donation_id 
          FROM donation_doc 
         WHERE donation_id IN (select donation_id from donation where scheme_sid = in_scheme_sid);
END;

PROCEDURE GetDonationsForBudget(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_budget_id		IN  budget.budget_id%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur       OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT donation_id,
			region_sid, donation_status_sid, activity, entered_dtm, entered_by_sid, donated_dtm, paid_dtm, end_dtm, payment_ref, 
			notes, extra_values_Xml, scheme_sid, budget_id, allocated_from_donation_id, recipient_sid, letter_body_text, contact_name,
			custom_1, custom_2, custom_3, custom_4, custom_5,
			custom_6, custom_7, custom_8, custom_9, custom_10,
			custom_11, custom_12, custom_13, custom_14, custom_15,
			custom_16, custom_17, custom_18, custom_19, custom_20,
			custom_21, custom_22, custom_23, custom_24, custom_25,
			custom_26, custom_27, custom_28, custom_29, custom_30,
			custom_31, custom_32, custom_33, custom_34, custom_35,
			custom_36, custom_37, custom_38, custom_39, custom_40,
			custom_41, custom_42, custom_43, custom_44, custom_45,
			custom_46, custom_47, custom_48, custom_49, custom_50,
			custom_51, custom_52, custom_53, custom_54, custom_55,
			custom_56, custom_57, custom_58, custom_59, custom_60,
			custom_61, custom_62, custom_63, custom_64, custom_65,
			custom_66, custom_67, custom_68, custom_69, custom_70,
			custom_71, custom_72, custom_73, custom_74, custom_75,
			custom_76, custom_77, custom_78, custom_79, custom_80,
			custom_81, custom_82, custom_83, custom_84, custom_85,
			custom_86, custom_87, custom_88, custom_89, custom_90,
			custom_91, custom_92, custom_93, custom_94, custom_95,
			custom_96, custom_97, custom_98, custom_99, custom_100,
			custom_101, custom_102, custom_103, custom_104, custom_105,
			custom_106, custom_107, custom_108, custom_109, custom_110, 
			custom_111, custom_112, custom_113, custom_114, custom_115,
			custom_116, custom_117, custom_118, custom_119, custom_120,
			custom_121, custom_122, custom_123, custom_124, custom_125,
			custom_126, custom_127, custom_128, custom_129, custom_130,
			custom_131, custom_132, custom_133, custom_134, custom_135,
			custom_136, custom_137, custom_138, custom_139, custom_140,
			custom_141, custom_142, custom_143, custom_144, custom_145,
			custom_146, custom_147, custom_148, custom_149, custom_150,
			custom_151, custom_152, custom_153, custom_154, custom_155,
			custom_156, custom_157, custom_158, custom_159, custom_160,
			custom_161, custom_162, custom_163, custom_164, custom_165,
			custom_166, custom_167, custom_168, custom_169, custom_170,
			custom_171, custom_172, custom_173, custom_174, custom_175,
			custom_176, custom_177, custom_178, custom_179, custom_180,
			custom_181, custom_182, custom_183, custom_184, custom_185,
			custom_186, custom_187, custom_188, custom_189, custom_190,
			custom_191, custom_192, custom_193, custom_194, custom_195,
			custom_196, custom_197, custom_198, custom_199, custom_200,
			custom_201, custom_202, custom_203, custom_204, custom_205,
			custom_206, custom_207, custom_208, custom_209, custom_210,
			custom_211, custom_212, custom_213, custom_214, custom_215,
			custom_216, custom_217, custom_218, custom_219, custom_220,
			custom_221, custom_222, custom_223, custom_224, custom_225,
			custom_226, custom_227, custom_228, custom_229, custom_230,
			custom_231, custom_232, custom_233, custom_234, custom_235,
			custom_236, custom_237, custom_238, custom_239, custom_240,
			custom_241, custom_242, custom_243, custom_244, custom_245,
			custom_246, custom_247, custom_248, custom_249, custom_250,
			custom_251, custom_252, custom_253, custom_254, custom_255,
			custom_256, custom_257, custom_258, custom_259, custom_260
		  FROM donation d
		 WHERE budget_id = in_budget_id;

    OPEN documents_cur FOR
        SELECT document_sid, donation_id 
          FROM donation_doc 
         WHERE donation_id IN (select donation_id from donation where budget_id = in_budget_id);
END;

PROCEDURE GetDonationsForRecipient2(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_recipient_sid	IN  security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
	documents_cur		OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT donation_id,
			region_sid, donation_status_sid, activity, entered_dtm, entered_by_sid, donated_dtm,  to_char(donated_dtm,'yyyy-mm-dd') donated_dtm_fmt, paid_dtm, payment_ref, end_dtm,
			notes, extra_values_Xml, scheme_sid, budget_id, allocated_from_donation_id, recipient_sid, letter_body_text, contact_name,
	             custom_1, custom_2, custom_3, custom_4, custom_5,
	             custom_6, custom_7, custom_8, custom_9, custom_10,
	             custom_11, custom_12, custom_13, custom_14, custom_15,
	             custom_16, custom_17, custom_18, custom_19, custom_20,
				 custom_21, custom_22, custom_23, custom_24, custom_25,
	             custom_26, custom_27, custom_28, custom_29, custom_30,
	             custom_31, custom_32, custom_33, custom_34, custom_35,
	             custom_36, custom_37, custom_38, custom_39, custom_40,
	             custom_41, custom_42, custom_43, custom_44, custom_45,
				 custom_46, custom_47, custom_48, custom_49, custom_50,
				 custom_51, custom_52, custom_53, custom_54, custom_55,
				 custom_56, custom_57, custom_58, custom_59, custom_60,
	             custom_61, custom_62, custom_63, custom_64, custom_65,
	             custom_66, custom_67, custom_68, custom_69, custom_70,
				 custom_71, custom_72, custom_73, custom_74, custom_75,
	             custom_76, custom_77, custom_78, custom_79, custom_80,
	             custom_81, custom_82, custom_83, custom_84, custom_85,
	             custom_86, custom_87, custom_88, custom_89, custom_90,
	             custom_91, custom_92, custom_93, custom_94, custom_95,
				 custom_96, custom_97, custom_98, custom_99, custom_100,
				 custom_101, custom_102, custom_103, custom_104, custom_105,
				 custom_106, custom_107, custom_108, custom_109, custom_110, 
				 custom_111, custom_112, custom_113, custom_114, custom_115,
				 custom_116, custom_117, custom_118, custom_119, custom_120,
				 custom_121, custom_122, custom_123, custom_124, custom_125,
				 custom_126, custom_127, custom_128, custom_129, custom_130,
				 custom_131, custom_132, custom_133, custom_134, custom_135,
				 custom_136, custom_137, custom_138, custom_139, custom_140,
				 custom_141, custom_142, custom_143, custom_144, custom_145,
				 custom_146, custom_147, custom_148, custom_149, custom_150,
				 custom_151, custom_152, custom_153, custom_154, custom_155,
				 custom_156, custom_157, custom_158, custom_159, custom_160,
				 custom_161, custom_162, custom_163, custom_164, custom_165,
				 custom_166, custom_167, custom_168, custom_169, custom_170,
				 custom_171, custom_172, custom_173, custom_174, custom_175,
				 custom_176, custom_177, custom_178, custom_179, custom_180,
				 custom_181, custom_182, custom_183, custom_184, custom_185,
				 custom_186, custom_187, custom_188, custom_189, custom_190,
				 custom_191, custom_192, custom_193, custom_194, custom_195,
				 custom_196, custom_197, custom_198, custom_199, custom_200,
				 custom_201, custom_202, custom_203, custom_204, custom_205,
				 custom_206, custom_207, custom_208, custom_209, custom_210,
				 custom_211, custom_212, custom_213, custom_214, custom_215,
				 custom_216, custom_217, custom_218, custom_219, custom_220,
				 custom_221, custom_222, custom_223, custom_224, custom_225,
				 custom_226, custom_227, custom_228, custom_229, custom_230,
				 custom_231, custom_232, custom_233, custom_234, custom_235,
				 custom_236, custom_237, custom_238, custom_239, custom_240,
				 custom_241, custom_242, custom_243, custom_244, custom_245,
				 custom_246, custom_247, custom_248, custom_249, custom_250,
				 custom_251, custom_252, custom_253, custom_254, custom_255,
				 custom_256, custom_257, custom_258, custom_259, custom_260
		  FROM donation d
		 WHERE recipient_sid = in_recipient_sid;

    OPEN documents_cur FOR
        SELECT document_sid, donation_id 
          FROM donation_doc 
         WHERE donation_id IN (SELECT donation_id FROM donation WHERE recipient_sid = in_recipient_sid);
END;



PROCEDURE GetDonationsForTag(
        in_act_id			IN  security_pkg.T_ACT_ID,
        in_tag_id			IN  tag.tag_id%TYPE,
        out_cur				OUT Security_Pkg.T_OUTPUT_CUR,
        documents_cur		OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT d.donation_id, 
			region_sid, donation_status_sid, activity, entered_dtm, entered_by_sid, donated_dtm, paid_dtm, payment_ref, end_dtm, 
			notes, extra_values_Xml, scheme_sid, budget_id, allocated_from_donation_id, recipient_sid, letter_body_text, contact_name,
				 custom_1, custom_2, custom_3, custom_4, custom_5,
	             custom_6, custom_7, custom_8, custom_9, custom_10,
	             custom_11, custom_12, custom_13, custom_14, custom_15,
	             custom_16, custom_17, custom_18, custom_19, custom_20,
				 custom_21, custom_22, custom_23, custom_24, custom_25,
	             custom_26, custom_27, custom_28, custom_29, custom_30,
	             custom_31, custom_32, custom_33, custom_34, custom_35,
	             custom_36, custom_37, custom_38, custom_39, custom_40,
	             custom_41, custom_42, custom_43, custom_44, custom_45,
				 custom_46, custom_47, custom_48, custom_49, custom_50,
				 custom_51, custom_52, custom_53, custom_54, custom_55,
				 custom_56, custom_57, custom_58, custom_59, custom_60,
	             custom_61, custom_62, custom_63, custom_64, custom_65,
	             custom_66, custom_67, custom_68, custom_69, custom_70,
				 custom_71, custom_72, custom_73, custom_74, custom_75,
	             custom_76, custom_77, custom_78, custom_79, custom_80,
	             custom_81, custom_82, custom_83, custom_84, custom_85,
	             custom_86, custom_87, custom_88, custom_89, custom_90,
	             custom_91, custom_92, custom_93, custom_94, custom_95,
				 custom_96, custom_97, custom_98, custom_99, custom_100,
				 custom_101, custom_102, custom_103, custom_104, custom_105,
				 custom_106, custom_107, custom_108, custom_109, custom_110, 
				 custom_111, custom_112, custom_113, custom_114, custom_115,
				 custom_116, custom_117, custom_118, custom_119, custom_120,
				 custom_121, custom_122, custom_123, custom_124, custom_125,
				 custom_126, custom_127, custom_128, custom_129, custom_130,
				 custom_131, custom_132, custom_133, custom_134, custom_135,
				 custom_136, custom_137, custom_138, custom_139, custom_140,
				 custom_141, custom_142, custom_143, custom_144, custom_145,
				 custom_146, custom_147, custom_148, custom_149, custom_150,
				 custom_151, custom_152, custom_153, custom_154, custom_155,
				 custom_156, custom_157, custom_158, custom_159, custom_160,
				 custom_161, custom_162, custom_163, custom_164, custom_165,
				 custom_166, custom_167, custom_168, custom_169, custom_170,
				 custom_171, custom_172, custom_173, custom_174, custom_175,
				 custom_176, custom_177, custom_178, custom_179, custom_180,
				 custom_181, custom_182, custom_183, custom_184, custom_185,
				 custom_186, custom_187, custom_188, custom_189, custom_190,
				 custom_191, custom_192, custom_193, custom_194, custom_195,
				 custom_196, custom_197, custom_198, custom_199, custom_200,
				 custom_201, custom_202, custom_203, custom_204, custom_205,
				 custom_206, custom_207, custom_208, custom_209, custom_210,
				 custom_211, custom_212, custom_213, custom_214, custom_215,
				 custom_216, custom_217, custom_218, custom_219, custom_220,
				 custom_221, custom_222, custom_223, custom_224, custom_225,
				 custom_226, custom_227, custom_228, custom_229, custom_230,
				 custom_231, custom_232, custom_233, custom_234, custom_235,
				 custom_236, custom_237, custom_238, custom_239, custom_240,
				 custom_241, custom_242, custom_243, custom_244, custom_245,
				 custom_246, custom_247, custom_248, custom_249, custom_250,
				 custom_251, custom_252, custom_253, custom_254, custom_255,
				 custom_256, custom_257, custom_258, custom_259, custom_260
		  FROM donation d, donation_tag dt
		 WHERE dt.tag_id = in_tag_id
		   AND d.donation_id = dt.donation_id;

    OPEN documents_cur FOR
        SELECT document_sid, donation_id 
          FROM donation_doc 
         WHERE donation_id in (select d.donation_id from donation d, donation_tag dt
                                    WHERE dt.tag_id = in_tag_id
                                    AND d.donation_id = dt.donation_id
                                );
END;

-- SP call to insert some tag_ids for each tag_group into our temporary table
PROCEDURE ClearTagsFromFilterCondition
AS
BEGIN
	DELETE FROM tag_condition;
	DELETE FROM region_tag_condition;
	DELETE FROM recipient_tag_condition;
END;

PROCEDURE AddTagsToFilterCondition(
	 in_tag_group_sid	IN	security_pkg.T_SID_ID,
	 in_tag_ids 		IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	FOR i IN in_tag_ids.FIRST .. in_tag_ids.LAST
	LOOP 
		INSERT INTO tag_condition (tag_group_sid, tag_id) VALUES (in_tag_group_sid, in_tag_ids(i));
	END LOOP;
END;

PROCEDURE AddRecTagsToFilterCondition(
	 in_tag_group_sid	IN	security_pkg.T_SID_ID,
	 in_tag_ids 		IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	FOR i IN in_tag_ids.FIRST .. in_tag_ids.LAST
	LOOP 
		INSERT INTO recipient_tag_condition (tag_group_sid, tag_id) VALUES (in_tag_group_sid, in_tag_ids(i));
	END LOOP;
END;

PROCEDURE AddRegionTagsToFilterCondition(
	 in_tag_group_id	IN	security_pkg.T_SID_ID,
	 in_tag_ids 		IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	FOR i IN in_tag_ids.FIRST .. in_tag_ids.LAST
	LOOP 
		INSERT INTO region_tag_condition (tag_group_id, tag_id) VALUES (in_tag_group_id, in_tag_ids(i));
	END LOOP;
END;

PROCEDURE GetFilteredList(
	 in_act_id				   IN  security_pkg.T_ACT_ID,
	 in_app_sid				   IN  security_pkg.T_SID_ID,
	 in_recipient_name		   IN  recipient.org_name%TYPE,
	 in_recipient_sid		   IN  security_pkg.T_SID_ID,
	 in_scheme_ids             IN  security_pkg.T_SID_IDS,
	 in_donation_status_sids   IN  security_pkg.T_SID_IDS,
	 in_budget_names           IN  donation_pkg.T_BUDGET_NAMES,
	 in_region_group_ids	   IN  security_pkg.T_SID_IDS,
	 in_region_sid             IN  security_pkg.T_SID_ID,
	 in_include_children       IN  NUMBER,
	 in_funding_commitment_ids IN  security_pkg.T_SID_IDS,
	 in_start_dtm              IN  donation.entered_dtm%TYPE,
	 in_end_dtm                IN  donation.entered_dtm%TYPE,
	 in_donated_start_dtm      IN  donation.donated_dtm%TYPE,
	 in_donated_end_dtm        IN  donation.donated_dtm%TYPE,
	 in_search_term            IN  varchar2,
	 in_start_row			   IN  NUMBER,		    -- 1 based (not 0)
	 in_page_size			   IN  NUMBER,		
	 in_sort_by				   IN  security_pkg.T_VARCHAR2_ARRAY,
	 in_sort_dir			   IN  security_pkg.T_VARCHAR2_ARRAY,	
	 out_cur				   OUT security_pkg.T_OUTPUT_CUR 
)
AS
     t_scheme_filter                 security.T_SID_TABLE := security.T_SID_TABLE();
	 t_donation_status_filter		 security.T_SID_TABLE := security.T_SID_TABLE(); -- they're not SIDS, but they're NUMBER(10)s....
	 t_budget_filter				 T_BUDGET_NAME_TABLE := T_BUDGET_NAME_TABLE();
	 t_region_group_filter			 security.T_SID_TABLE := security.T_SID_TABLE();
	 t_funding_commitment_filter	 security.T_SID_TABLE := security.T_SID_TABLE();
	 t_budgets_allowed				 T_BUDGET_ID_TABLE := T_BUDGET_ID_TABLE();
	 --
	 v_lower_recipient_name			 recipient.org_name%TYPE;
	 v_lower_search_term			 varchar2(255);
	 v_number_of_tags		 		 INTEGER;
	 v_number_of_region_tags		 INTEGER;
	 v_number_of_recipient_tags		 INTEGER;
	 v_scheme_filter_count           INTEGER;
	 v_budget_filter_count 	   	 	 INTEGER;
	 v_donation_status_filter_count  INTEGER;
	 v_region_group_filter_count 	 INTEGER;
	 v_fc_filter_count				 INTEGER;
	 v_budget_id					 budget.budget_id%TYPE;
	 c_budget				   		 security_pkg.T_OUTPUT_CUR;
	 v_user_sid						 security_pkg.T_SID_ID;
	 v_can_view_all					 NUMBER(1);
	 v_can_view_mine				 NUMBER(1);
	 v_can_view_region				 NUMBER(1);
	 v_sql							 VARCHAR2(32000);
	 v_order_check_sql 				 VARCHAR2(32000);
	 v_order_by						 VARCHAR2(32000);
	 t_sort_cols					 security.T_VARCHAR2_TABLE;
	 t_sort_dirs					 security.T_VARCHAR2_TABLE;
	 v_bad_cols						 NUMBER(3);
	 v_bad_dirs						 NUMBER(3);
	 v_column_sql					 VARCHAR2(512);
	 
BEGIN
	user_pkg.GetSID(in_act_id, v_user_sid);

	 -- copy stuff into table types
	 -- do scheme
	 IF in_scheme_ids.COUNT >= 1 AND in_scheme_ids(1) IS NOT NULL THEN
        FOR i IN in_scheme_ids.FIRST .. in_scheme_ids.LAST
        LOOP
            t_scheme_filter.extend;
            t_scheme_filter(t_scheme_filter.count) := in_scheme_ids(i);
        END LOOP;
	 END IF;
	 -- do donation status
	 IF in_donation_status_sids.COUNT >= 1 AND in_donation_status_sids(1) IS NOT NULL THEN
		 FOR i IN in_donation_status_sids.FIRST .. in_donation_status_sids.LAST
		 LOOP 
			 t_donation_status_filter.extend;
			 t_donation_status_filter(t_donation_status_filter.count) := in_donation_status_sids(i);
		 END LOOP;
     END IF;
	 -- do budget
	 IF in_budget_names.COUNT >= 1 AND in_budget_names(1) IS NOT NULL THEN
		FOR i IN in_budget_names.FIRST .. in_budget_names.LAST
		 LOOP 
			 t_budget_filter.extend;
			 t_budget_filter(t_budget_filter.count) := in_budget_names(i);
		 END LOOP;
	 END IF;
	 -- do region_group
	 IF in_region_group_ids.COUNT >= 1 AND in_region_group_ids(1) IS NOT NULL THEN
		FOR i IN in_region_group_ids.FIRST .. in_region_group_ids.LAST
		 LOOP 
			 t_region_group_filter.extend;
			 t_region_group_filter(t_region_group_filter.count) := in_region_group_ids(i);
		 END LOOP;
	 END IF;
	 -- do funding_commitment
	 IF in_funding_commitment_ids.COUNT >= 1 AND in_funding_commitment_ids(1) IS NOT NULL THEN
		FOR i IN in_funding_commitment_ids.FIRST .. in_funding_commitment_ids.LAST
		 LOOP 
			 t_funding_commitment_filter.extend;
			 t_funding_commitment_filter(t_funding_commitment_filter.count) := in_funding_commitment_ids(i);
		 END LOOP;
	 END IF;
	 -- figure out how many tags are in the tag_condition table
	 -- this is used in the sub query when we filter to ensure that all parts
	 -- of the (effective) AND condition are met.
	 SELECT COUNT(tag_id)
       INTO v_number_of_tags
	   FROM tag_condition;
	 
	 SELECT COUNT(tag_id)
       INTO v_number_of_recipient_tags
	   FROM recipient_tag_condition;
	   
	 SELECT COUNT(tag_id)
       INTO v_number_of_region_tags
	   FROM region_tag_condition;
	 
	 -- put the number of other conditions we're applying into variables (as the table.COUNT
	 -- property can't be accessed from PL/SQL
  	 v_scheme_filter_count := t_scheme_filter.COUNT;
  	 v_budget_filter_count := t_budget_filter.COUNT;
	 v_donation_status_filter_count := t_donation_status_filter.COUNT;
	 v_region_group_filter_count := t_region_group_filter.COUNT;
	 v_fc_filter_count := t_funding_commitment_filter.COUNT;
	 v_lower_recipient_name := LOWER(in_recipient_name);
	 v_lower_search_term := LOWER(in_search_term);
	 
	 -- work out what budgets we have available and copy into a table 
	 budget_pkg.GetMyBudgetIDs(in_act_id, in_app_sid, c_budget);
	 WHILE TRUE
	 LOOP
	 	 FETCH c_budget INTO v_budget_id,  v_can_view_all, v_can_view_mine, v_can_view_region;
		 EXIT WHEN c_budget%NOTFOUND;
		 t_budgets_allowed.extend;
		 t_budgets_allowed(t_budgets_allowed.count) := T_BUDGET_ID_ROW(v_budget_id, v_can_view_all, v_can_view_mine, v_can_view_region);
	 END LOOP;
	 
	
	-- fiddle with advanced sorting
	t_sort_cols := security_pkg.Varchar2ArrayToTable(in_sort_by);
	t_sort_dirs := security_pkg.Varchar2ArrayToTable(in_sort_dir);

	v_order_check_sql := 'SELECT count(*) FROM TABLE(:1) WHERE value NOT IN(''entered_dtm'',''entered_by_name'',''donation_status_description'',''org_name'',''activity'',''region_description'',''scheme_name'',''budget_description'',''budget_amount'',''donated_dtm'',''paid_dtm'',''payment_ref'',''currency_code'',''recipient_ref'',''region_group_description'',''last_status_changed_by'',''last_status_changed_dtm'', ''funding_commitment_name'', ''funding_commitment_amount''';
	FOR i IN 1..260 
	LOOP
		v_order_check_sql := v_order_check_sql || ',''custom_' || i || '''';
	END LOOP;
	v_order_check_sql := v_order_check_sql || ')';

	EXECUTE IMMEDIATE
		v_order_check_sql
	INTO v_bad_cols USING t_sort_cols;
		
	 SELECT count(*)
	  INTO v_bad_dirs
	  FROM TABLE(t_sort_dirs) 
	 WHERE value NOT IN ('a','d');
	 
	IF v_bad_cols != 0 OR v_bad_dirs != 0 THEN
		raise_application_error(-20001, 'Bad sort columns/order in input');
	END IF; 
	
	v_order_by := '';
    FOR r IN (SELECT rownum, count(*) over () total, value FROM TABLE(t_sort_cols))
    LOOP
		IF r.rownum = 1 THEN
			v_order_by := v_order_by || ' ORDER BY ';
		END IF;
		
		-- try to wrap with NLS_SORT option if we have textual column
		v_column_sql := CASE WHEN (SUBSTR(LOWER(r.value),0,7) = 'custom_' OR SUBSTR(LOWER(r.value),-4,4) = '_dtm') OR LOWER(r.value) = 'funding_commitment_amount' THEN r.value ELSE 'NLSSORT('||r.value||', ''NLS_SORT=BINARY_CI'')' END;
		  
		-- hmmm... I assume the in_sort_dir array will be ordered as the in_sort_cols
		v_order_by := v_order_by || v_column_sql || ' ' || CASE WHEN in_sort_dir(r.rownum) = 'd' THEN 'DESC NULLS LAST' ELSE 'ASC NULLS LAST' END;
		IF r.rownum != r.total THEN
			v_order_by := v_order_by || ',';
		END IF;
    END LOOP;	
	 
	 v_sql := 'SELECT y.*, donation_pkg.concatTagIds(y.donation_id) tag_ids, donation_pkg.concatTags(y.donation_id, 50) tags, ' ||
'				      donation_pkg.concatRegionTagIds(y.region_sid) region_tag_ids, donation_pkg.concatRegionTags(y.region_sid, 50) region_tags, ' ||
'				      donation_pkg.concatRecipientTagIds(y.recipient_sid) recipient_tag_ids, donation_pkg.concatRecipientTags(y.recipient_sid, 50) recipient_tags ' ||
'       FROM ('||
'      SELECT rownum rn, x.*, count(*) over () total_rows'||
'      FROM ('||
'       SELECT d.activity, d.region_sid, d.donation_id, d.budget_id, d.scheme_sid, d.donation_status_sid,  to_char(d.last_status_changed_dtm,''yyyy-mm-dd'')  last_status_changed_dtm, (SELECT full_name FROM csr.csr_user WHERE csr.csr_user.csr_user_sid =  d.last_status_changed_by) last_status_changed_by,'||
'          d.recipient_sid, r.ref recipient_ref, d.entered_dtm,  to_char(d.entered_dtm,''yyyy-mm-dd'') entered_dtm_fmt, d.entered_by_sid, CASE WHEN ds.means_donated = 1 THEN d.donated_dtm ELSE NULL END donated_dtm, '||
'        CASE WHEN ds.means_donated = 1 THEN to_char(d.donated_dtm,''yyyy-mm-dd'') ELSE NULL END donated_dtm_fmt , CASE WHEN ds.means_paid = 1 THEN d.paid_dtm ELSE NULL END paid_dtm, CASE WHEN ds.means_paid=1 THEN to_char(d.paid_dtm,''yyyy-mm-dd'') ELSE NULL END paid_dtm_fmt,   d.payment_ref,'||
' 	     CASE WHEN s.track_donation_end_dtm = 1 THEN to_char(d.end_dtm,''yyyy-mm-dd'') ELSE NULL END end_dtm_fmt , CASE WHEN s.track_donation_end_dtm = 1 THEN d.end_dtm ELSE NULL END end_dtm, '||
'         r.org_name, b.budget_amount, b.region_group_sid, b.description budget_description, ds.description donation_status_description, ds.colour donation_status_colour,  b.currency_code, b.exchange_rate, cur.symbol currency_symbol, s.name scheme_name, '||
'      rg.description region_group_description, (select description from csr.v$region r where region_sid = d.region_sid) region_description, fc.name funding_commitment_name, fb.amount funding_commitment_amount, '||
'      us.full_name entered_by_name, extra_values_xml,'||
'      custom_1, custom_2, custom_3, custom_4, custom_5,'||
'      custom_6, custom_7, custom_8, custom_9, custom_10,'||
'      custom_11, custom_12, custom_13, custom_14, custom_15,'||
'      custom_16, custom_17, custom_18, custom_19, custom_20,'||
'      custom_21, custom_22, custom_23, custom_24, custom_25,'||
'      custom_26, custom_27, custom_28, custom_29, custom_30,'||
'      custom_31, custom_32, custom_33, custom_34, custom_35,'||
'      custom_36, custom_37, custom_38, custom_39, custom_40, '||
'      custom_41, custom_42, custom_43, custom_44, custom_45,'||
'      custom_46, custom_47, custom_48, custom_49, custom_50,'||
'      custom_51, custom_52, custom_53, custom_54, custom_55,'||
'      custom_56, custom_57, custom_58, custom_59, custom_60,'||
'      custom_61, custom_62, custom_63, custom_64, custom_65,'||
'      custom_66, custom_67, custom_68, custom_69, custom_70,'||
'      custom_71, custom_72, custom_73, custom_74, custom_75,'||
'      custom_76, custom_77, custom_78, custom_79, custom_80,'||
'      custom_81, custom_82, custom_83, custom_84, custom_85,'||
'      custom_86, custom_87, custom_88, custom_89, custom_90,'||
'      custom_91, custom_92, custom_93, custom_94, custom_95,'||
'      custom_96, custom_97, custom_98, custom_99, custom_100,'||
'      custom_101, custom_102, custom_103, custom_104, custom_105,'||
'      custom_106, custom_107, custom_108, custom_109, custom_110,'||
'      custom_111, custom_112, custom_113, custom_114, custom_115,'||
'      custom_116, custom_117, custom_118, custom_119, custom_120,'||
'      custom_121, custom_122, custom_123, custom_124, custom_125,'||
'      custom_126, custom_127, custom_128, custom_129, custom_130,'||
'      custom_131, custom_132, custom_133, custom_134, custom_135,'||
'      custom_136, custom_137, custom_138, custom_139, custom_140,'||
'      custom_141, custom_142, custom_143, custom_144, custom_145,'||
'      custom_146, custom_147, custom_148, custom_149, custom_150,'||
'      custom_151, custom_152, custom_153, custom_154, custom_155,'||
'      custom_156, custom_157, custom_158, custom_159, custom_160,'||
'      custom_161, custom_162, custom_163, custom_164, custom_165,'||
'      custom_166, custom_167, custom_168, custom_169, custom_170,'||
'      custom_171, custom_172, custom_173, custom_174, custom_175,'||
'      custom_176, custom_177, custom_178, custom_179, custom_180,'||
'      custom_181, custom_182, custom_183, custom_184, custom_185,'||
'      custom_186, custom_187, custom_188, custom_189, custom_190,'||
'      custom_191, custom_192, custom_193, custom_194, custom_195,'||
'      custom_196, custom_197, custom_198, custom_199, custom_200,'||
'      custom_201, custom_202, custom_203, custom_204, custom_205,'||
'      custom_206, custom_207, custom_208, custom_209, custom_210,'||
'      custom_211, custom_212, custom_213, custom_214, custom_215,'||
'      custom_216, custom_217, custom_218, custom_219, custom_220,'||
'      custom_221, custom_222, custom_223, custom_224, custom_225,'||
'      custom_226, custom_227, custom_228, custom_229, custom_230,'||
'      custom_231, custom_232, custom_233, custom_234, custom_235,'||
'      custom_236, custom_237, custom_238, custom_239, custom_240,'||
'      custom_241, custom_242, custom_243, custom_244, custom_245,'||
'      custom_246, custom_247, custom_248, custom_249, custom_250,'||
'      custom_251, custom_252, custom_253, custom_254, custom_255,'||
'      custom_256, custom_257, custom_258, custom_259, custom_260,'||
'      (select count(*) from donation_doc dd where dd.donation_id = d.donation_id AND dd.document_sid != -1) document_sid'||
--COUNT(dd.document_sid) document_sid -- we have count as document_sid column to maintain backward compatibility with saved views, etc...'||
'      FROM DONATION d '||
'		JOIN RECIPIENT r ON d.recipient_sid = r.recipient_sid '||
'		JOIN SCHEME s ON d.scheme_sid = s.scheme_sid AND s.app_sid = d.app_sid'||
'		JOIN BUDGET b ON d.budget_id = b.budget_id'||
'		JOIN REGION_GROUP rg ON b.region_group_sid = rg.region_group_sid '||
'		JOIN DONATION_STATUS ds ON d.donation_status_sid = ds.donation_status_sid '||
'		JOIN CURRENCY cur ON cur.currency_code = b.currency_code '||
'		JOIN CSR.CSR_USER us ON d.entered_by_sid = us.csr_user_sid '||
'  LEFT JOIN FC_DONATION fd ON fd.donation_id = d.donation_id '||
'  LEFT JOIN FUNDING_COMMITMENT fc ON fc.funding_commitment_sid = fd.funding_commitment_sid '||
'  LEFT JOIN FC_BUDGET fb ON fb.funding_commitment_sid = fd.funding_commitment_sid AND fb.budget_id = d.budget_id'||
' 		JOIN TABLE(:1) ba ON ba.budget_id = b.budget_id '||	-- must be on budgets allowed list
'  LEFT JOIN TABLE(:2) sc ON sc.column_value = d.scheme_sid '||
'  LEFT JOIN TABLE(:3) bc ON bc.column_value = b.description '||
'  LEFT JOIN TABLE(:4) dsc ON dsc.column_value = d.donation_status_sid '||
'  LEFT JOIN TABLE(:5) rgc ON rgc.column_value = b.region_group_sid' ||
'  LEFT JOIN ('||
'           SELECT d.donation_id'||
'             FROM DONATION_TAG dt, TAG_GROUP_MEMBER tgm, DONATION d, TAG_CONDITION tc'||
'            WHERE d.donation_id = dt.donation_id'||
'              AND dt.tag_id = tgm.tag_id'||
'              AND tgm.tag_group_sid = tc.tag_group_sid'||
'              AND tgm.tag_id = tc.tag_id'||
'            GROUP BY d.donation_id '||
'           HAVING COUNT(*) = :7'||
'         )t ON t.donation_id = d.donation_id '|| -- filter on tags
'  LEFT JOIN (' ||
'			SELECT d.donation_id'||
'             FROM csr.REGION_TAG rt, csr.TAG_GROUP_MEMBER tgm, DONATION d, REGION_TAG_CONDITION rtc'||
'            WHERE d.region_sid = rt.region_sid'||
'              AND rt.tag_id = tgm.tag_id'||
'              AND tgm.tag_group_id = rtc.tag_group_id'||
'              AND tgm.tag_id = rtc.tag_id'||
'            GROUP BY d.donation_id '||
'           HAVING COUNT(*) = :8'||
'       )rt ON rt.donation_id = d.donation_id'|| -- filter on region_tag_groups
'  LEFT JOIN (' ||
'			SELECT d.donation_id'||
'             FROM RECIPIENT_TAG rt, TAG_GROUP_MEMBER tgm, DONATION d, RECIPIENT_TAG_CONDITION rtc'||
'            WHERE d.recipient_sid = rt.recipient_sid'||
'              AND rt.tag_id = tgm.tag_id'||
'              AND tgm.tag_group_sid = rtc.tag_group_sid'||
'              AND tgm.tag_id = rtc.tag_id'||
'            GROUP BY d.donation_id '||
'           HAVING COUNT(*) = :9'||
'       )rect ON rect.donation_id = d.donation_id'|| -- filter on recipient tags
'     WHERE ('||
'      ba.can_view_all = 1 '||
'      OR (ba.can_view_mine =1 AND d.entered_by_sid = '||v_user_sid||')'||
'      OR (ba.can_view_region =1 AND d.region_sid IN (SELECT region_sid FROM csr.region_owner WHERE user_sid = '||v_user_sid||'))'||
'     ) '|| -- checks scheme permissions
'		AND s.app_sid = sys_context(''security'',''app'')'||
'       AND (:9 IS NULL OR r.recipient_sid = :10)'||
'       AND (:11 IS NULL OR ('||
'           LOWER(r.org_name) LIKE :12 '||
'        OR LOWER(r.contact_name) LIKE :13'||
'        OR LOWER(town) LIKE :14 '||
'        OR org_name_soundex = SOUNDEX(:15)'||
'		    ))'||
-- scheme
'				   AND ('||v_scheme_filter_count||' = 0 OR sc.column_value IS NOT NULL)'||
-- budget
'				   AND ('||v_budget_filter_count||' = 0 OR bc.column_value IS NOT NULL)'||
-- donation_status
'				   AND ('||v_donation_status_filter_count||' = 0 OR dsc.column_value IS NOT NULL)'||
-- region_group
'				   AND ('||v_region_group_filter_count||' = 0 OR rgc.column_value IS NOT NULL)'||
-- funding_commitment
-- hmm... seems it slows down the query exec significantly so we don't support it as of yet
-- tag_ids
'				   AND ('||v_number_of_tags||' = 0 OR t.donation_id IS NOT NULL)'||
-- recipient tag_ids
'				   AND ('||v_number_of_recipient_tags||' = 0 OR rect.donation_id IS NOT NULL)'||
-- region tag_ids
'				   AND ('||v_number_of_region_tags||' = 0 OR rt.donation_id IS NOT NULL)'||
-- region filter
'				   AND (d.region_sid IN ('||
'						SELECT region_sid FROM csr.region START WITH region_sid = :16 CONNECT BY '||in_include_children||' = 1 AND prior region_sid = parent_sid)'||
'				    OR :17 IS NULL)'||
-- search term filter
'				   AND (:18 IS NULL OR ('||
'							LOWER(d.activity) LIKE :19'||
'                        OR	LOWER(d.extra_values_xml) LIKE :20'||
'                        OR	LOWER(us.full_name) LIKE :21'||
'				   ))'||
-- date filter
'				   AND (d.entered_dtm >= :22 OR :23 IS NULL)'||
'				   AND (d.entered_dtm < :24 + 1 OR :25 IS NULL)'||
'				   AND (d.donated_dtm >= :26 OR :27 IS NULL)'||
'				   AND (d.donated_dtm < :28 + 1 OR :29 IS NULL)';
	
	v_sql := v_sql || v_order_by;			   
	
	v_sql := v_sql || '			 	   )x'||
'	     )y'||
'		 WHERE rn > '||in_start_row||' AND rn <= '|| (in_start_row + in_page_size);

	OPEN out_cur FOR v_sql 	
		USING 	t_budgets_allowed, t_scheme_filter, t_budget_filter, t_donation_status_filter, t_region_group_filter, -- t_funding_commitment_filter,
			v_number_of_tags, v_number_of_region_tags, v_number_of_recipient_tags, in_recipient_sid, in_recipient_sid, v_lower_recipient_name, '%' || v_lower_recipient_name || '%',
			'%' || v_lower_recipient_name || '%', '%' || v_lower_recipient_name || '%', v_lower_recipient_name, in_region_sid, in_region_sid,
			in_search_term, '%' || v_lower_search_term || '%', '%' || v_lower_search_term || '%', '%' || v_lower_search_term || '%', in_start_dtm,
			in_start_dtm, in_end_dtm, in_end_dtm, in_donated_start_dtm, in_donated_start_dtm,
			in_donated_end_dtm, in_donated_end_dtm;
	
END;


PROCEDURE GetDonationDetails(
	 in_act_id				   IN  security_pkg.T_ACT_ID,
	 in_app_sid				   IN  security_pkg.T_SID_ID,
	 in_donation_id		       IN  security_pkg.T_SID_ID,
	 out_cur				   OUT security_pkg.T_OUTPUT_CUR,
	 out_doc_cur    		   OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
       SELECT y.*, concatTagIds(y.donation_id) tag_ids, count(*) over () total_rows
 		  FROM (
			    SELECT d.activity, d.donation_id, d.budget_id, d.scheme_sid, d.donation_status_sid, 
				  	   d.recipient_sid, d.entered_dtm,  d.entered_by_sid,			  	   
				  	   CASE WHEN ds.means_donated = 1 THEN d.donated_dtm ELSE NULL END donated_dtm, 
				  	   CASE WHEN s.track_donation_end_dtm = 1 THEN d.end_dtm ELSE NULL END end_dtm, 
					   CASE WHEN ds.means_donated = 1 THEN to_char(d.donated_dtm,'yyyy-mm-dd') ELSE NULL END donated_dtm_fmt,
					   CASE WHEN ds.means_paid = 1 THEN d.paid_dtm ELSE NULL END paid_dtm,
					   d.payment_ref,
						r.org_name, b.region_group_sid, b.description budget_description, 
						ds.description donation_status_description, b.currency_code, cur.symbol currency_symbol,
						s.name scheme_name, rg.description region_group_description,
						 custom_1, custom_2, custom_3, custom_4, custom_5,
						 custom_6, custom_7, custom_8, custom_9, custom_10,
						 custom_11, custom_12, custom_13, custom_14, custom_15,
						 custom_16, custom_17, custom_18, custom_19, custom_20,
						 custom_21, custom_22, custom_23, custom_24, custom_25,
						 custom_26, custom_27, custom_28, custom_29, custom_30,
						 custom_31, custom_32, custom_33, custom_34, custom_35,
						 custom_36, custom_37, custom_38, custom_39, custom_40,
						 custom_41, custom_42, custom_43, custom_44, custom_45,
						 custom_46, custom_47, custom_48, custom_49, custom_50,
						 custom_51, custom_52, custom_53, custom_54, custom_55,
						 custom_56, custom_57, custom_58, custom_59, custom_60, 
						custom_61, custom_62, custom_63, custom_64, custom_65,
						custom_66, custom_67, custom_68, custom_69, custom_70,
						custom_71, custom_72, custom_73, custom_74, custom_75,
						custom_76, custom_77, custom_78, custom_79, custom_80,
						custom_81, custom_82, custom_83, custom_84, custom_85,
						custom_86, custom_87, custom_88, custom_89, custom_90,
						custom_91, custom_92, custom_93, custom_94, custom_95,
						custom_96, custom_97, custom_98, custom_99, custom_100,
						custom_101, custom_102, custom_103, custom_104, custom_105,
						custom_106, custom_107, custom_108, custom_109, custom_110, 
						custom_111, custom_112, custom_113, custom_114, custom_115,
						custom_116, custom_117, custom_118, custom_119, custom_120, 
						custom_121, custom_122, custom_123, custom_124, custom_125,
						custom_126, custom_127, custom_128, custom_129, custom_130,
						custom_131, custom_132, custom_133, custom_134, custom_135,
						custom_136, custom_137, custom_138, custom_139, custom_140,
						custom_141, custom_142, custom_143, custom_144, custom_145,
						custom_146, custom_147, custom_148, custom_149, custom_150,
						custom_151, custom_152, custom_153, custom_154, custom_155,
						custom_156, custom_157, custom_158, custom_159, custom_160,
						custom_161, custom_162, custom_163, custom_164, custom_165,
						custom_166, custom_167, custom_168, custom_169, custom_170,
						custom_171, custom_172, custom_173, custom_174, custom_175,
						custom_176, custom_177, custom_178, custom_179, custom_180,
						custom_181, custom_182, custom_183, custom_184, custom_185,
						custom_186, custom_187, custom_188, custom_189, custom_190,
						custom_191, custom_192, custom_193, custom_194, custom_195,
						custom_196, custom_197, custom_198, custom_199, custom_200,
						custom_201, custom_202, custom_203, custom_204, custom_205,
						custom_206, custom_207, custom_208, custom_209, custom_210,
						custom_211, custom_212, custom_213, custom_214, custom_215,
						custom_216, custom_217, custom_218, custom_219, custom_220, 
						custom_221, custom_222, custom_223, custom_224, custom_225,
						custom_226, custom_227, custom_228, custom_229, custom_230,
						custom_231, custom_232, custom_233, custom_234, custom_235,
						custom_236, custom_237, custom_238, custom_239, custom_240,
						custom_241, custom_242, custom_243, custom_244, custom_245,
						custom_246, custom_247, custom_248, custom_249, custom_250,
						custom_251, custom_252, custom_253, custom_254, custom_255,
						custom_256, custom_257, custom_258, custom_259, custom_260,
						 (
						   		SELECT d.donation_id
		  					      FROM DONATION_TAG dt, TAG_GROUP_MEMBER tgm, DONATION d, TAG_CONDITION tc
								 WHERE d.donation_id = dt.donation_id
		  						   AND dt.tag_id = tgm.tag_id
								   AND tgm.tag_group_sid = tc.tag_group_sid
								   AND tgm.tag_id = tc.tag_id
								 GROUP BY d.donation_id
						   )t, 
						us.full_name entered_by_name
                FROM DONATION d, RECIPIENT r, SCHEME s, BUDGET b, REGION_GROUP rg, DONATION_STATUS ds, CURRENCY cur, csr.csr_user us
               WHERE d.donation_id = in_donation_id
                 AND d.budget_id = b.budget_id  
                 AND d.scheme_sid = s.scheme_Sid
                 AND d.recipient_sid = r.recipient_sid 
                 AND b.region_group_sid = rg.region_group_sid 
                 AND cur.currency_code = b.currency_code 
                 AND d.donation_status_sid = ds.donation_status_sid
                 AND d.entered_by_sid = us.csr_user_sid
	     )y;
	     
    OPEN out_doc_cur FOR
        SELECT document_sid 
          FROM donation_doc  
         WHERE donation_id = in_donation_id;

END;

PROCEDURE SetRecipientContactName(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_donation_id		IN	donation.donation_id%TYPE,
  in_recipient_sid   IN donation.recipient_sid%TYPE,
	in_contact_name		IN	donation.contact_name%TYPE
)
AS
	v_app_sid							security_pkg.T_SID_ID;
  v_entered_by_sid			security_pkg.T_SID_ID;
  v_prev_recipient_sid	security_pkg.T_SID_ID;
	v_user_sid						security_pkg.T_SID_ID;
	v_scheme_sid    donation.scheme_sid%TYPE;
	v_contact_name  donation.contact_name%TYPE;
	v_old_contact_name	donation.contact_name%TYPE;
BEGIN

	v_app_sid := security_pkg.getApp();
	
	-- if recipient different then update the used dtm
	SELECT scheme_sid, recipient_sid, entered_by_sid
	  INTO v_scheme_sid, v_prev_recipient_sid, v_entered_by_sid
	  FROM DONATION where donation_id = in_donation_id;

	IF NOT CanUpdate(in_act_id, in_donation_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied amending donation');
	END IF;
	
	IF v_prev_recipient_sid != in_recipient_sid THEN
		UPDATE RECIPIENT
		   SET LAST_USED_DTM = SYSDATE
		 WHERE recipient_sid = in_recipient_sid;
	END IF;

	-- Get recipient contact name
	SELECT contact_name 
	  INTO v_contact_name
	  FROM recipient
	 WHERE recipient_sid = in_recipient_sid;

	-- Is the contact name different from the passed contact name
	IF in_contact_name IS NULL OR
		LOWER(v_contact_name) = LOWER(in_contact_name) THEN
    v_contact_name := NULL;
	ELSE
    v_contact_name := in_contact_name;
  END IF;


	-- get old contact_name value for auditing purpose
	SELECT contact_name 
	  INTO v_old_contact_name
	  FROM donation
	 WHERE donation_id = in_donation_id;
	 
	IF v_old_contact_name is NULL THEN
		SELECT contact_name 
	    INTO v_old_contact_name
	    FROM recipient
		 WHERE recipient_sid = in_recipient_sid;
	END IF;
	 
	 
  -- Update the donation with the chosen recipient
  UPDATE donation
  SET contact_name = v_contact_name,
    recipient_sid = in_recipient_sid
  WHERE donation_id = in_donation_id;

	
	-- Write Audit
	csr.csr_data_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, v_app_sid, 
		v_scheme_sid, 'Contact name',v_old_contact_name,  v_contact_name, in_donation_id);
	
END;

PROCEDURE SetLetterText(
	in_act				IN	security_pkg.T_ACT_ID,
	in_donation_id		IN	donation.donation_id%TYPE,
	in_text				IN	donation.letter_body_text%TYPE
)
AS
BEGIN
	UPDATE donation
	   SET letter_body_text = in_text
	 WHERE donation_id = in_donation_id;
END;

PROCEDURE GetLetterText(
	in_act				IN	security_pkg.T_ACT_ID,
	in_donation_id		IN	donation.donation_id%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT letter_body_text
		  FROM donation
		 WHERE donation_id = in_donation_id;
END;


PROCEDURE AuditInfoXmlChanges(
	in_act					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_object_sid		    IN	security_pkg.T_SID_ID,
	in_info_xml_fields		IN	XMLTYPE,
	in_old_info_xml			IN	XMLTYPE,
	in_new_info_xml			IN	XMLTYPE,
	in_sub_object_id		IN  donation.donation_id%TYPE
)
AS
BEGIN


	-- this got taken from csr_data_pkg and amended slightly to work with xml structure for donatoins
	-- the change is that field is referred by @id in donations, whereas for main csr_data_pkg it's referred by @name
	FOR rx IN (
		 SELECT 
		    CASE 
		      WHEN n.node_key IS NULL THEN '{0} deleted'
		      WHEN o.node_key IS NULL THEN '{0} set to "{2}"'
		      ELSE '{0} changed from "{1}" to "{2}"'
		    END action, f.node_label, 
		    REGEXP_REPLACE(NVL(o.node_value,'Empty'),'^<!\[CDATA\[(.*)\]\]>$','\1', 1, 0, 'n') old_node_value, 
		    REGEXP_REPLACE(NVL(n.node_value,'Empty'),'^<!\[CDATA\[(.*)\]\]>$','\1', 1, 0, 'n') new_node_value
		  FROM (
		      SELECT 
		        EXTRACT(VALUE(x), 'field/@id').getStringVal() node_key,
		        EXTRACT(VALUE(x), 'field/@name').getStringVal() node_label
		      FROM TABLE(XMLSEQUENCE(EXTRACT(in_info_xml_fields, '*/field' )))x
		   )f, (
		    SELECT 
			  EXTRACT(VALUE(x), 'field/@id').getStringVal() node_key, 
			  -- getStringVal has limit to 4000 chars, so we need to trim stuff for auditing
			  DBMS_LOB.SUBSTR( EXTRACT(VALUE(x), 'field/text()').getClobVal(), 2000,1) node_value
		      FROM TABLE(
		        XMLSEQUENCE(EXTRACT(in_old_info_xml, '/values/field'))
		      )x
		  )o FULL JOIN (
		     SELECT 
		      EXTRACT(VALUE(x), 'field/@id').getStringVal() node_key, 
		      -- getStringVal has limit to 4000 chars, so we need to trim stuff for auditing
		      DBMS_LOB.SUBSTR( EXTRACT(VALUE(x), 'field/text()').getClobVal(), 2000,1) node_value
		      FROM TABLE(
		        XMLSEQUENCE(EXTRACT(in_new_info_xml, '/values/field'))
		      )x
		  )n ON o.node_key = n.node_key
		  WHERE f.node_key = NVL(o.node_key, n.node_key)
		    AND (n.node_key IS NULL
				OR o.node_key IS NULL
				OR NVL(o.node_value, '-') != NVL(n.node_value, '-')
			)
	)
	LOOP
		csr.csr_data_pkg.WriteAuditLogEntryAndSubObject(in_act, csr.csr_data_pkg.AUDIT_TYPE_DONATIONS_DONATION, in_app_sid, in_object_sid, in_sub_object_id,
			 rx.action, rx.node_label, rx.old_node_value, rx.new_node_value);
	END LOOP;
END;


PROCEDURE GetAuditLogForDonation(
	in_act_id			  IN	security_pkg.T_ACT_ID,
	in_app_sid		      IN	security_pkg.T_SID_ID,
	in_object_sid		  IN	security_pkg.T_SID_ID,
	in_sub_object_id	  IN	donation.donation_id%TYPE,
	in_order_by			  IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				  OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	csr.csr_data_pkg.GetAuditLogForObject(in_act_id, in_app_sid, in_object_sid, in_sub_object_id, in_order_by, out_cur);
END;

-- no security -- called only by import tool
PROCEDURE UNSEC_ImportDonation(
	in_donation_Id		IN	donation.donation_id%TYPE,
	in_entered_by_sid	IN	donation.entered_by_sid%TYPE
)
AS
BEGIN
	UPDATE donation
	   SET entered_by_sid = in_entered_by_sid
	 WHERE donation_id = in_donation_id;
END;

PROCEDURE UpdateDonationDoc(
	in_donation_id		IN	donation.donation_id%TYPE,
	in_document_sid 	IN	donation_doc.document_sid%TYPE,
	in_filename			IN 	csr.file_upload.filename%TYPE,
	in_description		IN	donation_doc.description%TYPE
)
AS
	v_act_id 	security_pkg.T_ACT_ID;
BEGIN
	v_act_id := SYS_CONTEXT('security', 'act');
	
	IF NOT CanUpdate(v_act_id, in_donation_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied amending donation');
	END IF;
	
	UPDATE csr.file_upload 
	   SET filename = in_filename
	 WHERE file_upload_sid = in_document_sid;
	 
	UPDATE donation_doc 
	   SET description = in_description
	 WHERE donation_id = in_donation_id 
	   AND document_sid = in_document_sid;
END;

PROCEDURE GetDonationDocs(
	in_document_sid		IN donation_doc.document_sid%TYPE,
	out_doc_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_description_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id 	security_pkg.T_ACT_ID;
BEGIN
	v_act_id := SYS_CONTEXT('security', 'act');
	
	-- get file upload info
	csr.fileupload_pkg.getFileUploadWithoutData(v_act_id, in_document_sid, out_doc_cur);
	
	-- get file upload desc
	OPEN out_description_cur FOR
		SELECT description 
		  FROM donation_doc 
		 WHERE document_sid = in_document_sid;
END;

PROCEDURE GetAllFiles(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_donation_id		IN	donation.donation_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- security check on scheme PERMISSION_VIEW_ALL
	-- this SP is used by c:\cvs\csr\tools\ExpAllDonationsFiles command line tool only
	OPEN out_cur FOR
		SELECT dd.donation_id,  dd.description, fu.filename, fu.mime_type, fu.data
		  FROM donation_doc dd, donation d, csr.file_upload fu
		 WHERE dd.donation_id = in_donation_id
		   AND dd.donation_id = d.donation_id
		   AND dd.document_sid = fu.file_upload_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, d.scheme_sid, scheme_Pkg.PERMISSION_VIEW_ALL) = 1
		 ORDER BY dd.donation_id;
END;

PROCEDURE IsV2Enabled(
	out_is_version_2_enabled		OUT	customer_filter_flag.is_version_2_enabled%TYPE
)
AS
BEGIN
	SELECT is_version_2_enabled
	  INTO out_is_version_2_enabled
	  FROM donations.customer_filter_flag
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetCountries(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT country country_code, name country
		  FROM postcode.country
		 ORDER BY name;
END;

END donation_Pkg;
/

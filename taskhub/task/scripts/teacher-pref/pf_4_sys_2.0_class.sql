-- ----------------------------------------------------------------------------------------------------------------
-- 2.0: 四季切齐正式课 (2.0_formal)，公开课 (open)


INSERT INTO memory.teacher_pref.class
SELECT clt.id AS class_id
	, CASE
		WHEN cl.cl_course_type = 3 THEN '公开课(2.0)'
		WHEN cl.fee_common_id = 65 THEN 'Standby(2.0)'
		WHEN cl.cl_typecn IN ('小班课 1V1', '小班课 1V4') THEN '一对四正式课(2.0)'
		ELSE ''
	  END as class_course_type_name
	, CASE
		WHEN cl.cl_course_type = 3 THEN 'open_2.0'
		WHEN cl.fee_common_id = 65 THEN 'standby_2.0'
		WHEN cl.cl_typecn IN ('小班课 1V1', '小班课 1V4') THEN '1v4_formal_2.0'
		ELSE ''
	  END as class_course_type_code
	, CASE
		-- WHEN cl.cl_typecn = '公开课' THEN 'open'
		WHEN cl.cl_course_type = 3 THEN 'open'
		WHEN cl.fee_common_id = 65 THEN 'standby'
		WHEN cl.cl_typecn = '小班课 1V1' THEN 'to1'
		WHEN cl.cl_typecn = '小班课 1V4' AND sum_sk + sum_kk + sum_st < 3 THEN 'to1'
		WHEN cl.cl_typecn = '小班课 1V4' THEN 'to4'
		ELSE ''
	  END as class_salary_type
	, IF(cl.cl_course_type = 3, NULL, sum_sk + sum_kk + sum_st) AS student_count
	, t.teacher_id
	, t.teacher_sso_id
	-- , t.teacher_ss_id
	-- , t.english_name
	-- , cl.cl_name
	, DATE(from_unixtime(clt.clt_starttime)) AS class_date
	, IF(sbj.teacher_status = 3, 0, 1) AS is_valid_for_salary
	, clt.create_time AS class_create_at
	, (clt.clt_starttime - to_unixtime(clt.create_time)) <= pp.max_class_create_in_urgent AS is_create_in_urgent
	, from_unixtime(clt.clt_starttime) AS start_time
	, from_unixtime(clt.clt_endtime) AS end_time
	, (clt.clt_endtime - clt.clt_starttime) / 60 AS duration	
	, from_unixtime(ts.teacher_entry_time) AS entry_time
	, IF (ts.teacher_entry_time IS NULL OR ts.teacher_entry_time = 0, -9999
		, ts.teacher_entry_time - clt.clt_starttime) > pp.min_come_late_seconds AS is_come_late
	, NULL AS exit_time
	, -9999 > pp.min_leave_early_seconds AS is_leave_early
	, NULL AS feedback_time
--	, CASE 
--		WHEN cl.cl_course_type = 3 THEN 1  -- 公开课
--		WHEN cl.fee_common_id = 65 THEN 1 -- Standby
--		ELSE COALESCE(fb.is_fb_on_time, 0)
--	  END AS is_fb_on_time
	, 1 AS is_fb_on_time 	-- TODO: 只限 2 月
	, 2 AS sys
FROM ssmysql.sishu.bk_class_times as clt
	INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
		ON is_cur = TRUE
	inner JOIN ssmysql.sishu.bk_user_info AS ui 
		ON ui.id = clt.clt_teacher_id
	INNER JOIN memory.teacher_pref.teachers AS t
		ON t.teacher_ss_id IS NOT NULL AND ui.uid = t.teacher_ss_id
	INNER JOIN ssmysql.sishu.bk_class AS cl -- 班级不允许删除
		ON cl.id = clt.cl_id
	INNER JOIN ssmysql.sishu.bk_subject AS sbj  -- subject 与 class_times 同时存在
		ON sbj.id = clt.sbj_id
	LEFT JOIN (
		select clt_id, uid
			, min(sign_date_unix) as teacher_entry_time
		from ssmysql.sishu.bk_sign_in AS bsi
			INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
				ON is_cur = TRUE
		WHERE bsi.addtime >= to_unixtime(pp.stime)
		group by clt_id, uid
	) AS ts
		on ts.clt_id = clt.id
			and ts.uid = ui.uid
	LEFT JOIN (
		SELECT sbj_id, IF(SUM(sbj_bx + sbj_zy + sbj_zw) > 0, 1, 0) AS is_fb_on_time -- 暂时不考虑评价时间
		FROM ssmysql.sishu.bk_subjectdet AS bs
			INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
				ON is_cur = TRUE
		-- WHERE -- 下次需要过滤时间
		GROUP BY sbj_id
	) AS fb
		ON clt.sbj_id = fb.sbj_id
WHERE clt.clt_starttime >= to_unixtime(pp.stime)
	AND clt.clt_starttime < to_unixtime(pp.etime)
	AND sbj.status = 1
	AND sbj.teacher_status IN (1, 3, 4, 5)	-- 2.老师请假: 相当于课程取消
ORDER BY t.teacher_id, clt.clt_starttime
;






-- stat

DROP TABLE IF EXISTS memory.teacher_pref.ystd_teacher_stat;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.ystd_teacher_stat AS
SELECT t.teacher_id
	, t.english_name
	, a.signed_cls_cnt
	, a.avl_cls_cnt
	, COALESCE(ycs.cls_cnt, 0) AS cls_cnt
	, COALESCE(l.leave_cnt, 0) AS leave_cnt
	, a.leave_cls_cnt
	, COALESCE(ab.abst_cnt, 0) AS abst_cnt
	, a.abst_cls_cnt
	, COALESCE(ycs.come_late_cnt, 0) AS come_late_cnt
	, COALESCE(ycs.come_late_secs_amt, 0) AS come_late_secs_amt
	, COALESCE(ycs.leave_early_cnt, 0) AS leave_early_cnt
	, COALESCE(ycs.leave_early_secs_amt, 0) AS leave_early_secs_amt
	, COALESCE(ycs.fb_delayed_cnt, 0) AS fb_delayed_cnt
FROM (
	SELECT tt.teacher_id
		, COUNT(*) AS signed_cls_cnt
		, SUM(IF(is_leave = 0, 1, 0)) AS avl_cls_cnt
		, SUM(IF(is_leave = 1, 1, 0)) AS leave_cls_cnt
		, SUM(IF(is_abst = 1, 1, 0)) AS abst_cls_cnt
	FROM memory.teacher_pref.teacher_timeslot AS tt
	GROUP BY tt.teacher_id
) AS a
	INNER JOIN memory.teacher_pref.teachers AS t
		ON a.teacher_id = t.teacher_id
	LEFT JOIN (
		-- 请假次数
		SELECT tl.teacher_id, COUNT(*) AS leave_cnt
		FROM memory.teacher_pref.teacher_leave_fixed AS tl
		WHERE current_timestamp > tl.start_time
			AND (current_timestamp - INTERVAL '1' DAY) <= tl.end_time
		GROUP BY tl.teacher_id
	) AS l
		ON a.teacher_id = l.teacher_id
	LEFT JOIN (
		-- 旷工次数
		SELECT ta.teacher_id, COUNT(*) AS abst_cnt
		FROM memory.teacher_pref.teacher_absence AS ta
		WHERE current_timestamp > ta.start_time
			AND (current_timestamp - INTERVAL '1' DAY) <= ta.end_time
		GROUP BY ta.teacher_id
	) ab
		ON a.teacher_id = ab.teacher_id
	LEFT JOIN memory.teacher_pref.ystd_class_stat AS ycs
		ON a.teacher_id = ycs.teacher_id
;




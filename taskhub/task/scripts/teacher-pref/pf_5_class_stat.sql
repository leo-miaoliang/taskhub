
DROP TABLE IF EXISTS memory.teacher_pref.ystd_class;

CREATE TABLE IF NOT EXISTS memory.teacher_pref.ystd_class AS
SELECT c.class_id
	, c.class_course_type_code
	, c.teacher_id
	, t.english_name
	, c.start_time
	, c.entry_time
	, IF(c.is_come_late, to_unixtime(c.entry_time) - to_unixtime(c.start_time), 0) AS come_late_secs
	, c.end_time
	, c.exit_time
	, IF(c.is_leave_early, to_unixtime(c.end_time) - to_unixtime(c.exit_time), 0) AS leave_early_secs
	, is_fb_on_time
	, c.sys
FROM memory.teacher_pref.class AS c
	INNER JOIN memory.teacher_pref.teachers AS t
		ON c.teacher_id = t.teacher_id
WHERE class_date = current_date - INTERVAL '1' DAY
	AND c.is_valid_for_salary = 1
;


DROP TABLE IF EXISTS memory.teacher_pref.ystd_class_stat;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.ystd_class_stat AS
SELECT teacher_id
	, count(*) AS cls_cnt
	, SUM(IF(come_late_secs > 0, 1, 0)) AS come_late_cnt
	, SUM(IF(come_late_secs > 0, come_late_secs, 0)) AS come_late_secs_amt
	, SUM(IF(leave_early_secs > 0, 1, 0)) AS leave_early_cnt
	, SUM(IF(leave_early_secs > 0, leave_early_secs, 0)) AS leave_early_secs_amt
	, SUM(IF(is_fb_on_time = 0, 1, 0)) AS fb_delayed_cnt
FROM memory.teacher_pref.ystd_class AS yc
GROUP BY teacher_id
;





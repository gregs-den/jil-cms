import { supabase } from "./supabaseClient";

// Attendance-based category funnel:
//   First Timer -> Attendees   on the 2nd attendance
//   Attendees   -> WSAM        once attendance is >= 60% within 6 months of the first attendance
const ATTENDANCE_WINDOW_MONTHS = 6;
const WSAM_ATTENDANCE_RATE = 0.6;

const toISODate = d => new Date(d).toISOString().slice(0, 10);

const addMonths = (date, months) => {
  const d = new Date(date);
  d.setMonth(d.getMonth() + months);
  return d;
};

// Call after every successful attendance check-in. Best-effort: never throws,
// so a failure here must not block the check-in that triggered it.
export async function applyAttendanceCategoryRules(memberId) {
  try {
    const { data: member } = await supabase
      .from("members")
      .select("id, category, branch_id")
      .eq("id", memberId)
      .maybeSingle();
    if (!member) return;

    const { data: records } = await supabase
      .from("attendance")
      .select("service_date")
      .eq("member_id", memberId)
      .order("service_date", { ascending: true });
    if (!records || records.length === 0) return;

    let category = member.category;

    // Rule 1: First Timer -> Attendees on the 2nd attendance.
    if (category === "First Timer" && records.length >= 2) {
      await supabase.from("members").update({ category: "Attendees" }).eq("id", memberId);
      category = "Attendees";
    }

    if (category !== "Attendees") return;

    // Rule 2: Attendees -> WSAM once attendance >= 60% within 6 months of first attendance.
    const firstDate = new Date(records[0].service_date);
    const windowEnd = addMonths(firstDate, ATTENDANCE_WINDOW_MONTHS);
    if (new Date() > windowEnd) return;

    const attendedInWindow = records.filter(r => {
      const d = new Date(r.service_date);
      return d >= firstDate && d <= windowEnd;
    }).length;

    let servicesQuery = supabase
      .from("attendance")
      .select("service_date")
      .gte("service_date", toISODate(firstDate))
      .lte("service_date", toISODate(windowEnd));
    if (member.branch_id) servicesQuery = servicesQuery.eq("branch_id", member.branch_id);

    const { data: branchRows } = await servicesQuery;
    const distinctServices = new Set((branchRows || []).map(r => r.service_date)).size;
    if (distinctServices === 0) return;

    const rate = attendedInWindow / distinctServices;
    if (rate >= WSAM_ATTENDANCE_RATE) {
      await supabase.from("members").update({ category: "WSAM" }).eq("id", memberId);
    }
  } catch {
    /* best-effort: never block a check-in on this */
  }
}

// Life Group bible-study funnel:
//   Attendees -> LGAM once attendance is >= 60% within 3 months of the member's first
//   LG session. Mirrors the Sunday-service Attendees -> WSAM rule, but gated on Bible
//   study attendance instead — only fires for members currently in "Attendees".
const LG_WINDOW_MONTHS = 3;
const LGAM_ATTENDANCE_RATE = 0.6;

// Call after every successful bible-study check-in. Best-effort: never throws,
// so a failure here must not block the check-in that triggered it.
export async function applyLifeGroupCategoryRule(memberId) {
  try {
    const { data: member } = await supabase
      .from("members")
      .select("id, category, life_group_id")
      .eq("id", memberId)
      .maybeSingle();
    if (!member || !member.life_group_id || member.category !== "Attendees") return;

    const { data: records } = await supabase
      .from("lg_attendance")
      .select("session_date")
      .eq("member_id", memberId)
      .order("session_date", { ascending: true });
    if (!records || records.length === 0) return;

    const firstDate = new Date(records[0].session_date);
    const windowEnd = addMonths(firstDate, LG_WINDOW_MONTHS);
    if (new Date() > windowEnd) return;

    const attendedInWindow = records.filter(r => {
      const d = new Date(r.session_date);
      return d >= firstDate && d <= windowEnd;
    }).length;

    const { data: groupRows } = await supabase
      .from("lg_attendance")
      .select("session_date")
      .eq("life_group_id", member.life_group_id)
      .gte("session_date", toISODate(firstDate))
      .lte("session_date", toISODate(windowEnd));
    const distinctSessions = new Set((groupRows || []).map(r => r.session_date)).size;
    if (distinctSessions === 0) return;

    const rate = attendedInWindow / distinctSessions;
    if (rate >= LGAM_ATTENDANCE_RATE) {
      await supabase.from("members").update({ category: "LGAM" }).eq("id", memberId);
    }
  } catch {
    /* best-effort: never block a check-in on this */
  }
}

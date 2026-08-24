import { useState, useEffect, useMemo, useCallback } from "react";
import { supabase } from "../lib/supabaseClient";
import { applyLifeGroupCategoryRule } from "../lib/categoryTransfer";

/* ═══════════════════════════════════════════════════════════
   DESIGN TOKENS (shared with App.jsx)
═══════════════════════════════════════════════════════════ */
const C = {
  ink:"#0A0F1E", ink2:"#1C2336",
  slate:"#64748B", mist:"#94A3B8", cloud:"#CBD5E1",
  fog:"#E8EDF5", white:"#FFFFFF",
  blue:"#1D4ED8", blue2:"#3B82F6", blue3:"#DBEAFE",
  green:"#15803D", green2:"#22C55E", green3:"#DCFCE7",
  amber:"#B45309", amber2:"#F59E0B", amber3:"#FEF3C7",
  rose:"#BE123C", rose2:"#F43F5E", rose3:"#FFE4E6",
  violet:"#6D28D9", violet2:"#8B5CF6", violet3:"#EDE9FE",
};
const R = { xs:"6px", sm:"10px", md:"14px", lg:"18px", xl:"24px", xxl:"32px", full:"9999px" };
const SH = { sm:"0 2px 8px rgba(0,0,0,.07)", md:"0 4px 20px rgba(0,0,0,.09)", lg:"0 8px 40px rgba(0,0,0,.12)" };

const useIsMobile = () => {
  const [mob, setMob] = useState(window.innerWidth < 768);
  useEffect(() => {
    const fn = () => setMob(window.innerWidth < 768);
    window.addEventListener("resize", fn);
    return () => window.removeEventListener("resize", fn);
  }, []);
  return mob;
};

const Card = ({ children, style={} }) => (
  <div style={{ background:C.white, borderRadius:R.xl, boxShadow:SH.sm,
    border:`1px solid ${C.fog}`, padding:"18px 20px", ...style }}>
    {children}
  </div>
);

const Badge = ({ label, color=C.blue }) => (
  <span style={{ background:`${color}18`, color, padding:"3px 10px", borderRadius:R.full,
    fontSize:11, fontWeight:700, letterSpacing:.3, whiteSpace:"nowrap" }}>{label}</span>
);

const Btn = ({ label, onClick, color=C.blue, outline, full, sm, disabled }) => (
  <button onClick={onClick} disabled={disabled} style={{
    display:"flex", alignItems:"center", gap:6, justifyContent:"center",
    padding: sm ? "7px 14px" : "10px 20px",
    background: disabled ? C.cloud : outline ? "transparent" : color,
    color: disabled ? C.white : outline ? color : C.white,
    border: `1.5px solid ${disabled ? C.cloud : color}`,
    borderRadius: R.full,
    fontWeight: 600, fontSize: sm ? 12 : 14,
    cursor: disabled ? "not-allowed" : "pointer", transition:"all .15s",
    width: full ? "100%" : "auto", flexShrink: 0,
  }}>
    {label}
  </button>
);

const Toast = ({ msg, type="success", onDone }) => {
  useEffect(()=>{ const t=setTimeout(onDone,3200); return()=>clearTimeout(t); },[onDone]);
  const bg = type==="error"?C.rose3:type==="warn"?C.amber3:C.green3;
  const fg = type==="error"?C.rose:type==="warn"?C.amber:C.green;
  return (
    <div style={{ position:"fixed", bottom:24, left:"50%", transform:"translateX(-50%)",
      background:bg, color:fg, borderRadius:R.full, padding:"11px 22px", fontSize:13,
      fontWeight:600, boxShadow:SH.md, zIndex:2000, whiteSpace:"nowrap" }}>
      {msg}
    </div>
  );
};

const Modal = ({ open, onClose, title, children, width=480 }) => {
  if (!open) return null;
  return (
    <div onClick={onClose} style={{ position:"fixed", inset:0, background:"rgba(10,15,30,.5)",
      backdropFilter:"blur(6px)", zIndex:1000, display:"flex", alignItems:"center", justifyContent:"center", padding:16 }}>
      <div onClick={e=>e.stopPropagation()} style={{ background:C.white, borderRadius:R.xxl,
        boxShadow:SH.lg, width:"100%", maxWidth:width, maxHeight:"92vh", overflowY:"auto" }}>
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", padding:"22px 24px 0" }}>
          <h3 style={{ margin:0, fontWeight:800, fontSize:17, color:C.ink }}>{title}</h3>
          <button onClick={onClose} style={{ border:"none", background:C.fog, borderRadius:"50%",
            width:32, height:32, cursor:"pointer", display:"flex", alignItems:"center",
            justifyContent:"center", fontSize:16, color:C.slate, lineHeight:1 }}>✕</button>
        </div>
        <div style={{ padding:"16px 24px 28px" }}>{children}</div>
      </div>
    </div>
  );
};

const Av = ({ name, size=34 }) => {
  const colors = [C.blue, C.violet2, C.rose2, C.green2, C.amber2, "#0EA5E9"];
  let h = 0; for (const c of (name||"?")) h += c.charCodeAt(0);
  return (
    <div style={{ width:size, height:size, borderRadius:"50%", background:colors[h%colors.length],
      display:"flex", alignItems:"center", justifyContent:"center", color:"#fff",
      fontWeight:700, fontSize:size*0.37, flexShrink:0 }}>
      {(name||"?").split(" ").map(w=>w[0]).join("").slice(0,2).toUpperCase()}
    </div>
  );
};

const catColor = c =>
  c==="WSAM"        ? C.blue   :
  c==="LGAM"        ? C.violet2:
  c==="WSAM/LGAM"   ? C.green  :
  c==="First Timer" ? C.amber  :
  c==="Attendees"   ? C.blue2  :
  C.rose2;

const toISODate = d => {
  const dt = new Date(d);
  const pad = n => String(n).padStart(2,"0");
  return `${dt.getFullYear()}-${pad(dt.getMonth()+1)}-${pad(dt.getDate())}`;
};

const logAction = async (action, details, entity, entityId) => {
  try {
    const { data:{ session } } = await supabase.auth.getSession();
    if (!session) return;
    const { data:profile } = await supabase.from("profiles").select("username").eq("id", session.user.id).maybeSingle();
    await supabase.from("audit_logs").insert([{
      user_id: session.user.id,
      user_name: profile?.username || session.user.email || "Unknown",
      action, details: details||null, entity: entity||null,
      entity_id: entityId ? String(entityId) : null,
    }]);
  } catch {}
};

/* ═══════════════════════════════════════════════════════════
   LIFE GROUP PAGE
═══════════════════════════════════════════════════════════ */
export default function LifeGroupPage({ role, user }) {
  const mob = useIsMobile();
  const canManage = role === "lg_leader" || role === "admin" || role === "superadmin";

  const [loading, setLoading] = useState(true);
  const [members, setMembers] = useState([]);
  const [selectedLeader, setSelectedLeader] = useState(role === "lg_leader" ? (user?.name || "") : "");
  const [groupAttendance, setGroupAttendance] = useState([]);
  const [sessionDate, setSessionDate] = useState(toISODate(new Date()));
  const [checked, setChecked] = useState({});
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const [addOpen, setAddOpen] = useState(false);
  const [addSearch, setAddSearch] = useState("");
  const [addingId, setAddingId] = useState(null);
  const [lifeGroups, setLifeGroups] = useState([]);
  const [approving, setApproving] = useState(false);
  const [confirmApproveOpen, setConfirmApproveOpen] = useState(false);

  const notify = (msg, type="success") => setToast({ msg, type });

  const fetchLifeGroups = useCallback(async () => {
    const { data } = await supabase.from("life_groups").select("*");
    setLifeGroups(data || []);
  }, []);

  useEffect(() => { fetchLifeGroups(); }, [fetchLifeGroups]);

  const currentGroup = useMemo(() =>
    lifeGroups.find(g => g.leader_name.trim().toLowerCase() === selectedLeader.trim().toLowerCase())
  , [lifeGroups, selectedLeader]);

  const ensureGroupExists = async (leaderName) => {
    const exists = lifeGroups.some(g => g.leader_name.trim().toLowerCase() === leaderName.trim().toLowerCase());
    if (exists) return;
    const { data, error } = await supabase.from("life_groups")
      .insert({ leader_name: leaderName, status: "probationary" })
      .select().single();
    if (!error && data) {
      setLifeGroups(prev => [...prev, data]);
      notify(`New Life Group started for ${leaderName} — probationary for 3 months.`, "warn");
    }
  };

  const isGroupEligible = group => {
    if (!group) return false;
    const eligibleOn = new Date(group.created_at);
    eligibleOn.setMonth(eligibleOn.getMonth() + 3);
    return new Date() >= eligibleOn;
  };

  const doApprove = async () => {
    if (!currentGroup) return;
    setApproving(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const { error } = await supabase.from("life_groups")
        .update({ status: "official", approved_at: new Date().toISOString(), approved_by: session?.user?.id || null })
        .eq("id", currentGroup.id);
      if (error) { notify("Failed to approve: " + error.message, "error"); setApproving(false); return; }
      logAction("lifegroup_approved", `${selectedLeader}'s Life Group approved as official`, "life_group", currentGroup.id);
      notify(`${selectedLeader}'s Life Group is now official ✓`);
      setConfirmApproveOpen(false);
      await fetchLifeGroups();
    } catch (err) {
      notify("Unexpected error: " + err.message, "error");
    }
    setApproving(false);
  };

  const approveGroup = () => {
    if (!currentGroup) return;
    if (!isGroupEligible(currentGroup)) { setConfirmApproveOpen(true); return; }
    doApprove();
  };

  const fetchMembers = useCallback(async () => {
    let all = [], from = 0;
    while (true) {
      const { data, error } = await supabase
        .from("members")
        .select("id, name, member_code, category, lifegroup_leader, is_active")
        .order("name", { ascending: true })
        .range(from, from + 999);
      if (error || !data || data.length === 0) break;
      all = [...all, ...data];
      if (data.length < 1000) break;
      from += 1000;
    }
    setMembers(all);
    setLoading(false);
  }, []);

  useEffect(() => { fetchMembers(); }, [fetchMembers]);

  const [lgLeaderAccounts, setLgLeaderAccounts] = useState([]);

  useEffect(() => {
    supabase.from("profiles").select("members(name)").eq("role", "lg_leader")
      .then(({ data }) => {
        const names = (data || []).map(p => p.members?.name).filter(Boolean);
        setLgLeaderAccounts([...new Set(names)]);
      });
  }, []);

  const leaderNames = useMemo(() => {
    const counts = {};
    members.forEach(m => {
      const leader = (m.lifegroup_leader || "").trim();
      if (leader && m.is_active !== false) counts[leader] = (counts[leader] || 0) + 1;
    });
    // Include lg_leader accounts that don't have any members assigned yet, so
    // admin/dev can originate a brand-new group before the leader adds anyone.
    lgLeaderAccounts.forEach(name => {
      if (!(name in counts)) counts[name] = 0;
    });
    return Object.entries(counts).sort((a,b) => a[0].localeCompare(b[0]));
  }, [members, lgLeaderAccounts]);

  const roster = useMemo(() => {
    const target = selectedLeader.trim().toLowerCase();
    if (!target) return [];
    return members.filter(m =>
      (m.lifegroup_leader || "").trim().toLowerCase() === target && m.is_active !== false
    );
  }, [members, selectedLeader]);

  const fetchGroupAttendance = useCallback(async (leader) => {
    if (!leader) { setGroupAttendance([]); return; }
    const { data } = await supabase
      .from("lg_attendance")
      .select("member_id, session_date")
      .eq("life_group_leader", leader);
    setGroupAttendance(data || []);
  }, []);

  useEffect(() => { fetchGroupAttendance(selectedLeader); }, [selectedLeader, fetchGroupAttendance]);

  useEffect(() => {
    // Preload checked state for the selected date from already-recorded rows.
    const already = {};
    groupAttendance.forEach(r => {
      if (r.session_date === sessionDate) already[r.member_id] = true;
    });
    setChecked(already);
  }, [sessionDate, groupAttendance]);

  const distinctSessionCount = useMemo(() =>
    new Set(groupAttendance.map(r => r.session_date)).size
  , [groupAttendance]);

  const memberStats = m => {
    const attended = groupAttendance.filter(r => r.member_id === m.id).length;
    const pct = distinctSessionCount ? Math.round((attended / distinctSessionCount) * 100) : 0;
    return { attended, pct };
  };

  const alreadyRecorded = memberId =>
    groupAttendance.some(r => r.member_id === memberId && r.session_date === sessionDate);

  const toggleChecked = memberId => {
    if (alreadyRecorded(memberId)) return;
    setChecked(prev => ({ ...prev, [memberId]: !prev[memberId] }));
  };

  const saveAttendance = async () => {
    const toInsert = roster.filter(m => checked[m.id] && !alreadyRecorded(m.id));
    if (toInsert.length === 0) { notify("No new attendance to save.", "warn"); return; }
    setSaving(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const rows = toInsert.map(m => ({
        member_id: m.id,
        life_group_leader: selectedLeader,
        session_date: sessionDate,
        present: true,
        recorded_by: session?.user?.id || null,
      }));
      const { error } = await supabase.from("lg_attendance").insert(rows);
      if (error) { notify("Failed to save: " + error.message, "error"); setSaving(false); return; }

      for (const m of toInsert) {
        await applyLifeGroupCategoryRule(m.id);
      }

      logAction("lg_attendance_recorded",
        `${toInsert.length} member(s) marked present for ${selectedLeader}'s Life Group on ${sessionDate}`,
        "lg_attendance", null);

      notify(`Saved attendance for ${toInsert.length} member(s) ✓`);
      await fetchGroupAttendance(selectedLeader);
      await fetchMembers();
    } catch (err) {
      notify("Unexpected error: " + err.message, "error");
    }
    setSaving(false);
  };

  const addSearchResults = useMemo(() => {
    const q = addSearch.trim().toLowerCase();
    if (!q) return [];
    const target = selectedLeader.trim().toLowerCase();
    return members
      .filter(m => m.is_active !== false)
      .filter(m => (m.lifegroup_leader || "").trim().toLowerCase() !== target)
      .filter(m => m.name?.toLowerCase().includes(q) || m.member_code?.toLowerCase().includes(q))
      .slice(0, 20);
  }, [members, addSearch, selectedLeader]);

  const assignToGroup = async (member) => {
    setAddingId(member.id);
    try {
      await ensureGroupExists(selectedLeader);
      const { error } = await supabase.from("members")
        .update({ lifegroup_leader: selectedLeader }).eq("id", member.id);
      if (error) { notify("Failed to add member: " + error.message, "error"); setAddingId(null); return; }

      logAction("member_updated", `${member.name} added to ${selectedLeader}'s Life Group`, "member", member.id);
      notify(`${member.name} added ✓`);
      setAddSearch("");
      await fetchMembers();
    } catch (err) {
      notify("Unexpected error: " + err.message, "error");
    }
    setAddingId(null);
  };

  if (!canManage) {
    return (
      <Card>
        <div style={{ textAlign:"center", padding:"30px 0", color:C.mist }}>
          You don't have access to Life Group.
        </div>
      </Card>
    );
  }

  const uncheckedCount = roster.filter(m => checked[m.id] && !alreadyRecorded(m.id)).length;

  return (
    <div>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}

      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:18, flexWrap:"wrap", gap:10 }}>
        <div>
          <h2 style={{ margin:"0 0 2px", fontWeight:800, fontSize:20, color:C.ink }}>Life Group</h2>
          <div style={{ fontSize:12, color:C.mist }}>Bible study attendance for your group</div>
        </div>
      </div>

      {(role === "admin" || role === "superadmin") && (
        <Card style={{ marginBottom:16 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate, display:"block", marginBottom:6 }}>
            Viewing group led by
          </label>
          <select value={selectedLeader} onChange={e=>setSelectedLeader(e.target.value)}
            style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
              fontSize:14, outline:"none", background:C.white, color:C.ink, width:"100%", maxWidth:360 }}>
            <option value="">— Select a Life Group leader —</option>
            {leaderNames.map(([name, count]) => (
              <option key={name} value={name}>{name} ({count} member{count!==1?"s":""})</option>
            ))}
          </select>
        </Card>
      )}

      {!selectedLeader ? (
        <Card>
          <div style={{ textAlign:"center", padding:"30px 0", color:C.mist }}>
            {role === "lg_leader"
              ? "No members are currently assigned to your Life Group."
              : "Select a Life Group leader above to view their roster."}
          </div>
        </Card>
      ) : loading ? (
        <Card><div style={{ textAlign:"center", padding:"30px 0", color:C.mist }}>Loading…</div></Card>
      ) : (
        <>
          <div style={{ display:"flex", justifyContent:"flex-end", marginBottom:12 }}>
            <Btn label="+ Add Member" sm onClick={()=>setAddOpen(true)}/>
          </div>

          <div style={{ display:"grid", gridTemplateColumns: mob ? "1fr 1fr" : "repeat(4, 1fr)", gap:12, marginBottom:16 }}>
            <Card>
              <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:6 }}>Group Size</div>
              <div style={{ fontSize:26, fontWeight:800, color:C.ink }}>{roster.length}</div>
            </Card>
            <Card>
              <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:6 }}>Sessions Recorded</div>
              <div style={{ fontSize:26, fontWeight:800, color:C.ink }}>{distinctSessionCount}</div>
            </Card>
            <Card>
              <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:6 }}>Leader</div>
              <div style={{ fontSize:14, fontWeight:700, color:C.ink, marginTop:6 }}>{selectedLeader}</div>
            </Card>
            <Card>
              <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:6 }}>Status</div>
              {currentGroup ? (
                <>
                  <Badge label={currentGroup.status==="official" ? "Official" : "Probationary"}
                    color={currentGroup.status==="official" ? C.green : C.amber2}/>
                  {currentGroup.status==="probationary" && (
                    <div style={{ fontSize:11, color:C.mist, marginTop:6 }}>
                      Eligible {(() => { const d = new Date(currentGroup.created_at); d.setMonth(d.getMonth()+3); return toISODate(d); })()}
                    </div>
                  )}
                  {currentGroup.status==="probationary" && (role==="admin" || role==="superadmin") && (
                    <div style={{ marginTop:8 }}>
                      <Btn label={approving ? "Approving…" : "Approve"} sm color={C.green} disabled={approving} onClick={approveGroup}/>
                    </div>
                  )}
                </>
              ) : (
                <div style={{ fontSize:13, color:C.mist, marginTop:6 }}>—</div>
              )}
            </Card>
          </div>

          <Card style={{ marginBottom:16 }}>
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", flexWrap:"wrap", gap:10, marginBottom:14 }}>
              <div>
                <label style={{ fontSize:12, fontWeight:600, color:C.slate, display:"block", marginBottom:6 }}>Session Date</label>
                <input type="date" value={sessionDate} max={toISODate(new Date())}
                  onChange={e=>setSessionDate(e.target.value)}
                  style={{ padding:"9px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md, fontSize:14, outline:"none", color:C.ink }}/>
              </div>
              <Btn label={saving ? "Saving…" : `Save Attendance${uncheckedCount ? ` (${uncheckedCount})` : ""}`}
                onClick={saveAttendance} disabled={saving || uncheckedCount===0}/>
            </div>

            <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
              {roster.length === 0 ? (
                <div style={{ textAlign:"center", padding:"20px 0", color:C.mist }}>No members in this group.</div>
              ) : roster.map(m => {
                const recorded = alreadyRecorded(m.id);
                const isChecked = recorded || !!checked[m.id];
                const { attended, pct } = memberStats(m);
                return (
                  <div key={m.id} onClick={()=>toggleChecked(m.id)}
                    style={{ display:"flex", alignItems:"center", gap:12, padding:"10px 12px",
                      borderRadius:R.md, border:`1.5px solid ${isChecked?C.green2:C.fog}`,
                      background: isChecked ? C.green3 : C.white,
                      cursor: recorded ? "default" : "pointer" }}>
                    <input type="checkbox" checked={isChecked} disabled={recorded} readOnly
                      style={{ width:18, height:18, flexShrink:0 }}/>
                    <Av name={m.name} size={32}/>
                    <div style={{ flex:1, minWidth:0 }}>
                      <div style={{ fontWeight:600, color:C.ink, fontSize:13, overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>{m.name}</div>
                      <div style={{ fontSize:11, color:C.mist }}>{attended}/{distinctSessionCount} sessions · {pct}%</div>
                    </div>
                    <Badge label={m.category || "—"} color={catColor(m.category)}/>
                    {recorded && <span style={{ fontSize:11, color:C.green, fontWeight:700 }}>✓ Recorded</span>}
                  </div>
                );
              })}
            </div>
          </Card>
        </>
      )}

      <Modal open={addOpen} onClose={()=>{ setAddOpen(false); setAddSearch(""); }} title="Add Member to Life Group">
        <div style={{ fontSize:12, color:C.mist, marginBottom:14 }}>
          Search for an existing member to add to <strong style={{ color:C.ink }}>{selectedLeader}</strong>'s group.
        </div>
        <input value={addSearch} onChange={e=>setAddSearch(e.target.value)}
          placeholder="Search name or member code…" autoFocus
          style={{ width:"100%", padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
            fontSize:14, outline:"none", color:C.ink, boxSizing:"border-box", marginBottom:12 }}/>

        <div style={{ display:"flex", flexDirection:"column", gap:6, maxHeight:320, overflowY:"auto" }}>
          {addSearch.trim() && addSearchResults.length === 0 && (
            <div style={{ textAlign:"center", padding:"16px 0", color:C.mist, fontSize:13 }}>No matching members found.</div>
          )}
          {addSearchResults.map(m => (
            <div key={m.id} style={{ display:"flex", alignItems:"center", gap:10, padding:"9px 12px",
              borderRadius:R.md, border:`1px solid ${C.fog}` }}>
              <Av name={m.name} size={30}/>
              <div style={{ flex:1, minWidth:0 }}>
                <div style={{ fontWeight:600, color:C.ink, fontSize:13 }}>{m.name}</div>
                <div style={{ fontSize:11, color:C.mist }}>
                  {m.member_code}{m.lifegroup_leader ? ` · currently under ${m.lifegroup_leader}` : ""}
                </div>
              </div>
              <Badge label={m.category || "—"} color={catColor(m.category)}/>
              <Btn label={addingId===m.id ? "Adding…" : "Add"} sm disabled={addingId===m.id}
                onClick={()=>assignToGroup(m)}/>
            </div>
          ))}
        </div>
      </Modal>

      <Modal open={confirmApproveOpen} onClose={()=>setConfirmApproveOpen(false)} title="Approve Early?" width={420}>
        <div style={{ fontSize:13, color:C.ink, marginBottom:18, lineHeight:1.5 }}>
          <strong>{selectedLeader}</strong>'s Life Group hasn't reached its 3-month probation mark yet
          {currentGroup && (() => {
            const d = new Date(currentGroup.created_at); d.setMonth(d.getMonth()+3);
            return <> (eligible <strong>{toISODate(d)}</strong>)</>;
          })()}. Approve it as official anyway?
        </div>
        <div style={{ display:"flex", gap:8, justifyContent:"space-between" }}>
          <Btn label={approving ? "Approving…" : "Approve Anyway"} color={C.green} disabled={approving} onClick={doApprove}/>
          <Btn label="Cancel" outline onClick={()=>setConfirmApproveOpen(false)}/>
        </div>
      </Modal>
    </div>
  );
}

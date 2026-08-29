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

export const LG_GROUP_TYPES = ["Men", "Women", "Young Adult", "KKB", "Children", "Hetero"];

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

const Inp = ({ label, value, onChange, placeholder, type="text", options, required }) => (
  <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:14 }}>
    <label style={{ fontSize:12, fontWeight:600, color:C.slate, letterSpacing:.2 }}>
      {label}{required&&<span style={{color:C.rose2}}> *</span>}
    </label>
    {options ? (
      <select value={value} onChange={e=>onChange(e.target.value)}
        style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
          fontSize:14, outline:"none", background:C.white, color:C.ink }}>
        <option value="">— Select —</option>
        {options.map(o=><option key={o} value={o}>{o}</option>)}
      </select>
    ) : (
      <input type={type} value={value} onChange={e=>onChange(e.target.value)} placeholder={placeholder}
        style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
          fontSize:14, outline:"none", color:C.ink }}/>
    )}
  </div>
);

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
  const isAdminRole = role === "admin" || role === "superadmin";

  const [loading, setLoading] = useState(true);
  const [members, setMembers] = useState([]);
  const [lifeGroups, setLifeGroups] = useState([]);
  const [selectedGroupId, setSelectedGroupId] = useState("");
  const [groupAttendance, setGroupAttendance] = useState([]);
  const [sessionDate, setSessionDate] = useState(toISODate(new Date()));
  const [checked, setChecked] = useState({});
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const [addOpen, setAddOpen] = useState(false);
  const [addSearch, setAddSearch] = useState("");
  const [addingId, setAddingId] = useState(null);
  const [groupQuery, setGroupQuery] = useState("");
  const [groupDropdownOpen, setGroupDropdownOpen] = useState(false);
  const [approving, setApproving] = useState(false);
  const [confirmApproveOpen, setConfirmApproveOpen] = useState(false);
  const [createOpen, setCreateOpen] = useState(false);
  const [createForm, setCreateForm] = useState({ name:"", leader_name:"", group_type:"", address:"", started_at: toISODate(new Date()) });
  const [creating, setCreating] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [editForm, setEditForm] = useState({ name:"", leader_name:"", group_type:"", address:"", started_at: toISODate(new Date()) });
  const [savingEdit, setSavingEdit] = useState(false);
  const [leaderAccounts, setLeaderAccounts] = useState([]);

  const notify = (msg, type="success") => setToast({ msg, type });

  const fetchLifeGroups = useCallback(async () => {
    const { data } = await supabase.from("life_groups").select("*").order("name");
    setLifeGroups(data || []);
  }, []);

  useEffect(() => { fetchLifeGroups(); }, [fetchLifeGroups]);

  // Leader picker sources actual lg_leader accounts (not free text), since a group's
  // leader_name must match the leader's display name exactly for them to see it.
  const fetchLeaderAccounts = useCallback(async () => {
    const { data } = await supabase
      .from("profiles")
      .select("id, username, members(name)")
      .eq("role", "lg_leader");
    const names = (data || [])
      .map(p => p.members?.name || p.username)
      .filter(Boolean)
      .sort((a, b) => a.localeCompare(b));
    setLeaderAccounts([...new Set(names)]);
  }, []);

  useEffect(() => { fetchLeaderAccounts(); }, [fetchLeaderAccounts]);

  const fetchMembers = useCallback(async () => {
    let all = [], from = 0;
    while (true) {
      const { data, error } = await supabase
        .from("members")
        .select("id, name, member_code, category, lifegroup_leader, life_group_id, is_active")
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

  // Groups this user leads (for lg_leader: only their own; admin/dev manage any).
  const myGroups = useMemo(() =>
    lifeGroups.filter(g => g.leader_name.trim().toLowerCase() === (user?.name||"").trim().toLowerCase())
  , [lifeGroups, user?.name]);

  const pickableGroups = role === "lg_leader" ? myGroups : lifeGroups;

  // Auto-select a leader's only group; leave the picker open if they have several.
  useEffect(() => {
    if (role !== "lg_leader") return;
    if (selectedGroupId) return;
    if (myGroups.length === 1) setSelectedGroupId(myGroups[0].id);
  }, [role, myGroups, selectedGroupId]);

  const memberCounts = useMemo(() => {
    const counts = {};
    members.forEach(m => {
      if (m.life_group_id && m.is_active !== false) counts[m.life_group_id] = (counts[m.life_group_id] || 0) + 1;
    });
    return counts;
  }, [members]);

  const selectedGroup = useMemo(() =>
    lifeGroups.find(g => g.id === selectedGroupId) || null
  , [lifeGroups, selectedGroupId]);

  const groupLabel = g => `${g.name} · ${g.group_type || "Untyped"} · led by ${g.leader_name} (${memberCounts[g.id] || 0} member${(memberCounts[g.id]||0)!==1?"s":""})`;

  // Keep the search box showing the current selection whenever it changes
  // elsewhere (auto-select, a new group being created, etc.).
  useEffect(() => {
    setGroupQuery(selectedGroup ? groupLabel(selectedGroup) : "");
  }, [selectedGroup?.id]);

  const groupSearchResults = useMemo(() => {
    const q = groupQuery.trim().toLowerCase();
    if (!q || (selectedGroup && groupQuery === groupLabel(selectedGroup))) return pickableGroups;
    return pickableGroups.filter(g =>
      g.name.toLowerCase().includes(q) ||
      g.leader_name.toLowerCase().includes(q) ||
      (g.group_type || "").toLowerCase().includes(q)
    );
  }, [pickableGroups, groupQuery, selectedGroup, memberCounts]);

  const roster = useMemo(() => {
    if (!selectedGroupId) return [];
    return members.filter(m => m.life_group_id === selectedGroupId && m.is_active !== false);
  }, [members, selectedGroupId]);

  const fetchGroupAttendance = useCallback(async (groupId) => {
    if (!groupId) { setGroupAttendance([]); return; }
    const { data } = await supabase
      .from("lg_attendance")
      .select("member_id, session_date")
      .eq("life_group_id", groupId);
    setGroupAttendance(data || []);
  }, []);

  useEffect(() => { fetchGroupAttendance(selectedGroupId); }, [selectedGroupId, fetchGroupAttendance]);

  useEffect(() => {
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

  const isGroupEligible = group => {
    if (!group) return false;
    const eligibleOn = new Date(group.created_at);
    eligibleOn.setMonth(eligibleOn.getMonth() + 3);
    return new Date() >= eligibleOn;
  };

  const doApprove = async () => {
    if (!selectedGroup) return;
    setApproving(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const { error } = await supabase.from("life_groups")
        .update({ status: "official", approved_at: new Date().toISOString(), approved_by: session?.user?.id || null })
        .eq("id", selectedGroup.id);
      if (error) { notify("Failed to approve: " + error.message, "error"); setApproving(false); return; }
      logAction("lifegroup_approved", `${selectedGroup.name} approved as official`, "life_group", selectedGroup.id);
      notify(`${selectedGroup.name} is now official ✓`);
      setConfirmApproveOpen(false);
      await fetchLifeGroups();
    } catch (err) {
      notify("Unexpected error: " + err.message, "error");
    }
    setApproving(false);
  };

  const approveGroup = () => {
    if (!selectedGroup) return;
    if (!isGroupEligible(selectedGroup)) { setConfirmApproveOpen(true); return; }
    doApprove();
  };

  const saveAttendance = async () => {
    const toInsert = roster.filter(m => checked[m.id] && !alreadyRecorded(m.id));
    if (toInsert.length === 0) { notify("No new attendance to save.", "warn"); return; }
    setSaving(true);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const rows = toInsert.map(m => ({
        member_id: m.id,
        life_group_id: selectedGroupId,
        life_group_leader: selectedGroup?.leader_name || "",
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
        `${toInsert.length} member(s) marked present for ${selectedGroup?.name}'s Life Group on ${sessionDate}`,
        "lg_attendance", null);

      notify(`Saved attendance for ${toInsert.length} member(s) ✓`);
      await fetchGroupAttendance(selectedGroupId);
      await fetchMembers();
    } catch (err) {
      notify("Unexpected error: " + err.message, "error");
    }
    setSaving(false);
  };

  const addSearchResults = useMemo(() => {
    const q = addSearch.trim().toLowerCase();
    if (!q || !selectedGroupId) return [];
    return members
      .filter(m => m.is_active !== false)
      .filter(m => m.life_group_id !== selectedGroupId)
      .filter(m => m.name?.toLowerCase().includes(q) || m.member_code?.toLowerCase().includes(q))
      .slice(0, 20);
  }, [members, addSearch, selectedGroupId]);

  const assignToGroup = async (member) => {
    if (!selectedGroup) return;
    setAddingId(member.id);
    try {
      const { error } = await supabase.from("members")
        .update({ life_group_id: selectedGroup.id, lifegroup_leader: selectedGroup.leader_name })
        .eq("id", member.id);
      if (error) { notify("Failed to add member: " + error.message, "error"); setAddingId(null); return; }

      logAction("member_updated", `${member.name} added to ${selectedGroup.name}`, "member", member.id);
      notify(`${member.name} added ✓`);
      setAddSearch("");
      await fetchMembers();
    } catch (err) {
      notify("Unexpected error: " + err.message, "error");
    }
    setAddingId(null);
  };

  const openCreate = () => {
    if (!isAdminRole) return;
    setCreateForm({
      name: "", leader_name: "", group_type: "", address: "", started_at: toISODate(new Date()),
    });
    setCreateOpen(true);
  };

  const createGroup = async () => {
    if (!isAdminRole) return;
    if (!createForm.name.trim() || !createForm.leader_name.trim() || !createForm.group_type) {
      notify("Name, leader, and group type are required.", "warn");
      return;
    }
    setCreating(true);
    try {
      const { data, error } = await supabase.from("life_groups").insert({
        name: createForm.name.trim(),
        leader_name: createForm.leader_name.trim(),
        group_type: createForm.group_type,
        address: createForm.address.trim() || null,
        started_at: createForm.started_at || null,
        status: "probationary",
      }).select().single();
      if (error) { notify("Failed to create group: " + error.message, "error"); setCreating(false); return; }

      logAction("lifegroup_created", `${data.name} (${data.group_type}) created — probationary`, "life_group", data.id);
      notify(`${data.name} created — probationary for 3 months.`, "warn");
      setLifeGroups(prev => [...prev, data].sort((a,b) => a.name.localeCompare(b.name)));
      setSelectedGroupId(data.id);
      setCreateOpen(false);
    } catch (err) {
      notify("Unexpected error: " + err.message, "error");
    }
    setCreating(false);
  };

  const openEdit = () => {
    if (!isAdminRole || !selectedGroup) return;
    setEditForm({
      name: selectedGroup.name || "",
      leader_name: selectedGroup.leader_name || "",
      group_type: selectedGroup.group_type || "",
      address: selectedGroup.address || "",
      started_at: selectedGroup.started_at || toISODate(new Date()),
    });
    setEditOpen(true);
  };

  const saveEdit = async () => {
    if (!isAdminRole) return;
    if (!selectedGroup || !editForm.name.trim() || !editForm.leader_name.trim() || !editForm.group_type) {
      notify("Name, leader, and group type are required.", "warn");
      return;
    }
    setSavingEdit(true);
    try {
      const payload = {
        name: editForm.name.trim(),
        leader_name: editForm.leader_name.trim(),
        group_type: editForm.group_type,
        address: editForm.address.trim() || null,
        started_at: editForm.started_at || null,
      };
      const { error } = await supabase.from("life_groups").update(payload).eq("id", selectedGroup.id);
      if (error) { notify("Failed to save: " + error.message, "error"); setSavingEdit(false); return; }

      logAction("lifegroup_updated", `${payload.name} details updated`, "life_group", selectedGroup.id);
      notify(`${payload.name} updated ✓`);
      setEditOpen(false);
      await fetchLifeGroups();
      // Leader name may have changed — keep members' display-only text field in sync.
      await supabase.from("members").update({ lifegroup_leader: payload.leader_name }).eq("life_group_id", selectedGroup.id);
      await fetchMembers();
    } catch (err) {
      notify("Unexpected error: " + err.message, "error");
    }
    setSavingEdit(false);
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
        {isAdminRole && <Btn label="+ Create Life Group" sm outline onClick={openCreate}/>}
      </div>

      <Card style={{ marginBottom:16 }}>
        <label style={{ fontSize:12, fontWeight:600, color:C.slate, display:"block", marginBottom:6 }}>
          {role === "lg_leader" ? "Your Life Group" : "Viewing group"}
        </label>
        <div style={{ position:"relative", width:"100%", maxWidth:420 }}>
          <input value={groupQuery}
            onChange={e=>{ setGroupQuery(e.target.value); setGroupDropdownOpen(true); }}
            onFocus={()=>setGroupDropdownOpen(true)}
            placeholder="Search by group name, leader, or type…"
            style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
              fontSize:14, outline:"none", background:C.white, color:C.ink, width:"100%", boxSizing:"border-box" }}/>

          {groupDropdownOpen && (
            <>
              <div onClick={()=>setGroupDropdownOpen(false)} style={{ position:"fixed", inset:0, zIndex:50 }}/>
              <div style={{ position:"absolute", top:"calc(100% + 4px)", left:0, right:0, background:C.white,
                border:`1px solid ${C.fog}`, borderRadius:R.md, boxShadow:SH.md, maxHeight:280, overflowY:"auto",
                zIndex:100 }}>
                {groupSearchResults.length === 0 ? (
                  <div style={{ padding:"14px 16px", fontSize:13, color:C.mist, textAlign:"center" }}>No matching Life Groups.</div>
                ) : groupSearchResults.map(g => (
                  <div key={g.id} onClick={()=>{ setSelectedGroupId(g.id); setGroupDropdownOpen(false); }}
                    style={{ padding:"10px 14px", fontSize:13, color:C.ink, cursor:"pointer",
                      background: g.id===selectedGroupId ? C.fog : "transparent" }}
                    onMouseEnter={e=>e.currentTarget.style.background=C.fog}
                    onMouseLeave={e=>e.currentTarget.style.background = g.id===selectedGroupId ? C.fog : "transparent"}>
                    {groupLabel(g)}
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
        {pickableGroups.length === 0 && (
          <div style={{ fontSize:12, color:C.mist, marginTop:8 }}>
            {role === "lg_leader"
              ? "You don't lead any Life Groups yet. Ask an admin to create one for you."
              : <>No Life Groups yet. Click "+ Create Life Group" to start one.</>}
          </div>
        )}
      </Card>

      {!selectedGroupId ? (
        <Card>
          <div style={{ textAlign:"center", padding:"30px 0", color:C.mist }}>
            Select a Life Group above to view its roster.
          </div>
        </Card>
      ) : loading ? (
        <Card><div style={{ textAlign:"center", padding:"30px 0", color:C.mist }}>Loading…</div></Card>
      ) : (
        <>
          <div style={{ display:"flex", justifyContent:"flex-end", marginBottom:12 }}>
            <Btn label="+ Add Member" sm onClick={()=>setAddOpen(true)}/>
          </div>

          <div style={{ display:"grid", gridTemplateColumns: mob ? "1fr 1fr" : "repeat(3, 1fr)", gap:12, marginBottom:12 }}>
            <Card>
              <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:6 }}>Group Size</div>
              <div style={{ fontSize:26, fontWeight:800, color:C.ink }}>{roster.length}</div>
            </Card>
            <Card>
              <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:6 }}>Sessions Recorded</div>
              <div style={{ fontSize:26, fontWeight:800, color:C.ink }}>{distinctSessionCount}</div>
            </Card>
            <Card>
              <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:6 }}>Status</div>
              {selectedGroup && (
                <>
                  <Badge label={selectedGroup.status==="official" ? "Official" : "Probationary"}
                    color={selectedGroup.status==="official" ? C.green : C.amber2}/>
                  {selectedGroup.status==="probationary" && (
                    <div style={{ fontSize:11, color:C.mist, marginTop:6 }}>
                      Eligible {(() => { const d = new Date(selectedGroup.created_at); d.setMonth(d.getMonth()+3); return toISODate(d); })()}
                    </div>
                  )}
                  {selectedGroup.status==="probationary" && isAdminRole && (
                    <div style={{ marginTop:8 }}>
                      <Btn label={approving ? "Approving…" : "Approve"} sm color={C.green} disabled={approving} onClick={approveGroup}/>
                    </div>
                  )}
                </>
              )}
            </Card>
          </div>

          {selectedGroup && (
            <Card style={{ marginBottom:16 }}>
              {isAdminRole && (
                <div style={{ display:"flex", justifyContent:"flex-end", marginBottom:10 }}>
                  <Btn label="Edit Group" outline sm onClick={openEdit}/>
                </div>
              )}
              <div style={{ display:"grid", gridTemplateColumns: mob ? "1fr 1fr" : "repeat(4, 1fr)", gap:14 }}>
                <div>
                  <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:4 }}>Name</div>
                  <div style={{ fontSize:13, fontWeight:600, color:C.ink }}>{selectedGroup.name}</div>
                </div>
                <div>
                  <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:4 }}>Leader</div>
                  <div style={{ fontSize:13, fontWeight:600, color:C.ink }}>{selectedGroup.leader_name}</div>
                </div>
                <div>
                  <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:4 }}>Type</div>
                  <Badge label={selectedGroup.group_type || "Untyped"} color={C.violet2}/>
                </div>
                <div>
                  <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:4 }}>Started</div>
                  <div style={{ fontSize:13, fontWeight:600, color:C.ink }}>{selectedGroup.started_at || "—"}</div>
                </div>
                <div style={{ gridColumn: mob ? "span 2" : "span 4" }}>
                  <div style={{ fontSize:11, color:C.mist, fontWeight:700, textTransform:"uppercase", letterSpacing:.4, marginBottom:4 }}>Address</div>
                  <div style={{ fontSize:13, fontWeight:600, color:C.ink }}>{selectedGroup.address || "—"}</div>
                </div>
              </div>
            </Card>
          )}

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
          Search for an existing member to add to <strong style={{ color:C.ink }}>{selectedGroup?.name}</strong>.
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
          <strong>{selectedGroup?.name}</strong> hasn't reached its 3-month probation mark yet
          {selectedGroup && (() => {
            const d = new Date(selectedGroup.created_at); d.setMonth(d.getMonth()+3);
            return <> (eligible <strong>{toISODate(d)}</strong>)</>;
          })()}. Approve it as official anyway?
        </div>
        <div style={{ display:"flex", gap:8, justifyContent:"space-between" }}>
          <Btn label={approving ? "Approving…" : "Approve Anyway"} color={C.green} disabled={approving} onClick={doApprove}/>
          <Btn label="Cancel" outline onClick={()=>setConfirmApproveOpen(false)}/>
        </div>
      </Modal>

      <Modal open={createOpen} onClose={()=>setCreateOpen(false)} title="Create Life Group">
        <Inp label="Group Name" value={createForm.name} onChange={v=>setCreateForm({...createForm,name:v})}
          placeholder="e.g. Tuesday Men's Life Group" required/>
        <Inp label="Leader" value={createForm.leader_name} onChange={v=>setCreateForm({...createForm,leader_name:v})}
          options={leaderAccounts} required/>
        <Inp label="Group Type" value={createForm.group_type} onChange={v=>setCreateForm({...createForm,group_type:v})}
          options={LG_GROUP_TYPES} required/>
        <Inp label="Address" value={createForm.address} onChange={v=>setCreateForm({...createForm,address:v})}
          placeholder="Where the group meets"/>
        <Inp label="Start Date" type="date" value={createForm.started_at} onChange={v=>setCreateForm({...createForm,started_at:v})}/>
        <div style={{ display:"flex", gap:8, justifyContent:"space-between" }}>
          <Btn label={creating ? "Creating…" : "Create"} onClick={createGroup} disabled={creating}/>
          <Btn label="Cancel" outline onClick={()=>setCreateOpen(false)}/>
        </div>
      </Modal>

      <Modal open={editOpen} onClose={()=>setEditOpen(false)} title="Edit Life Group">
        <Inp label="Group Name" value={editForm.name} onChange={v=>setEditForm({...editForm,name:v})}
          placeholder="e.g. Tuesday Men's Life Group" required/>
        <Inp label="Leader" value={editForm.leader_name} onChange={v=>setEditForm({...editForm,leader_name:v})}
          options={leaderAccounts} required/>
        <Inp label="Group Type" value={editForm.group_type} onChange={v=>setEditForm({...editForm,group_type:v})}
          options={LG_GROUP_TYPES} required/>
        <Inp label="Address" value={editForm.address} onChange={v=>setEditForm({...editForm,address:v})}
          placeholder="Where the group meets"/>
        <Inp label="Start Date" type="date" value={editForm.started_at} onChange={v=>setEditForm({...editForm,started_at:v})}/>
        <div style={{ display:"flex", gap:8, justifyContent:"space-between" }}>
          <Btn label={savingEdit ? "Saving…" : "Save Changes"} onClick={saveEdit} disabled={savingEdit}/>
          <Btn label="Cancel" outline onClick={()=>setEditOpen(false)}/>
        </div>
      </Modal>
    </div>
  );
}

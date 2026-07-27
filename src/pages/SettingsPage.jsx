import { useState, useEffect } from "react";
import { supabase } from "../lib/supabaseClient";

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

/* ═══════════════════════════════════════════════════════════
   MINI COMPONENTS
═══════════════════════════════════════════════════════════ */
const useIsMobile = () => {
  const [mob, setMob] = useState(window.innerWidth < 768);
  useEffect(() => {
    const fn = () => setMob(window.innerWidth < 768);
    window.addEventListener("resize", fn);
    return () => window.removeEventListener("resize", fn);
  }, []);
  return mob;
};

const Card = ({ children, style={}, onClick, hoverable }) => {
  const [hov, setHov] = useState(false);
  return (
    <div onClick={onClick}
      onMouseEnter={()=>hoverable&&setHov(true)}
      onMouseLeave={()=>hoverable&&setHov(false)}
      style={{ background:C.white, borderRadius:R.xl, boxShadow:hov?SH.md:SH.sm,
        border:`1px solid ${C.fog}`, padding:"18px 20px",
        transition:"box-shadow .18s, transform .18s",
        transform:hov?"translateY(-2px)":"none",
        cursor:onClick?"pointer":"default", ...style }}>
      {children}
    </div>
  );
};

const Pill = ({ label, active, onClick, color=C.blue }) => (
  <button onClick={onClick} style={{ padding:"6px 16px", borderRadius:R.full,
    border:`1.5px solid ${active?color:C.cloud}`, background:active?color:C.white,
    color:active?C.white:C.slate, fontWeight:600, fontSize:13, cursor:"pointer",
    transition:"all .15s", whiteSpace:"nowrap" }}>
    {label}
  </button>
);

const Badge = ({ label, color=C.blue }) => (
  <span style={{ background:`${color}18`, color, padding:"3px 10px", borderRadius:R.full,
    fontSize:11, fontWeight:700, letterSpacing:.3, whiteSpace:"nowrap" }}>{label}</span>
);

const Inp = ({ label, value, onChange, placeholder, options, required, type="text" }) => (
  <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:14 }}>
    <label style={{ fontSize:12, fontWeight:600, color:C.slate, letterSpacing:.2 }}>
      {label}{required&&<span style={{color:C.rose2}}> *</span>}
    </label>
    {options ? (
      <select value={value} onChange={e=>onChange(e.target.value)}
        style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
          fontSize:14, outline:"none", background:C.white, color:C.ink, appearance:"none" }}>
        <option value="">— Select —</option>
        {options.map(o=><option key={o} value={o}>{o}</option>)}
      </select>
    ) : (
      <input type={type} value={value} onChange={e=>onChange(e.target.value)}
        placeholder={placeholder}
        style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
          fontSize:14, outline:"none", color:C.ink }}/>
    )}
  </div>
);

const Btn = ({ label, onClick, color=C.blue, outline, full, sm, icon:IcoComp, danger }) => {
  const bg = danger ? C.rose2 : outline ? "transparent" : color;
  const fg = outline ? (danger ? C.rose2 : color) : C.white;
  const brd = danger ? C.rose2 : color;
  return (
    <button onClick={onClick} style={{
      display:"flex", alignItems:"center", gap:6, justifyContent:"center",
      padding: sm ? "7px 14px" : "10px 20px",
      background: bg, color: fg,
      border: `1.5px solid ${brd}`,
      borderRadius: R.full,
      fontWeight: 600, fontSize: sm ? 12 : 14,
      cursor:"pointer", transition:"all .15s",
      width: full ? "100%" : "auto",
      flexShrink: 0,
    }}>
      {IcoComp && <IcoComp size={sm?13:15} color={fg}/>} {label}
    </button>
  );
};

const Modal = ({ open, onClose, title, children, width=520 }) => {
  if (!open) return null;
  return (
    <div onClick={onClose} style={{ position:"fixed", inset:0,
      background:"rgba(10,15,30,.5)", backdropFilter:"blur(6px)",
      zIndex:1000, display:"flex", alignItems:"center", justifyContent:"center", padding:16 }}>
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

const Av = ({ name, size=36 }) => {
  const colors = [C.blue, C.violet2, C.rose2, C.green2, C.amber2, "#0EA5E9"];
  let h = 0; for (let c of (name||"?")) h += c.charCodeAt(0);
  return (
    <div style={{ width:size, height:size, borderRadius:"50%", background:colors[h%colors.length],
      display:"flex", alignItems:"center", justifyContent:"center", color:"#fff",
      fontWeight:700, fontSize:size*0.37, flexShrink:0 }}>
      {(name||"?").split(" ").map(w=>w[0]).join("").slice(0,2).toUpperCase()}
    </div>
  );
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

const BackBtn = ({ onClick }) => (
  <button onClick={onClick} style={{ display:"flex", alignItems:"center", gap:6, border:"none",
    background:"transparent", cursor:"pointer", color:C.blue,
    fontWeight:600, fontSize:13, marginBottom:16, padding:0 }}>
    ← Back to Settings
  </button>
);

/* ═══════════════════════════════════════════════════════════
   ICONS (subset needed)
═══════════════════════════════════════════════════════════ */
const SVG = ({ children, size=20, color="currentColor", sw=1.5 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
    stroke={color} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
    {children}
  </svg>
);
const Ico = {
  users:    (p)=><SVG {...p}><circle cx="9" cy="8" r="3.5"/><path d="M2 21v-1.5A5.5 5.5 0 0116 19.5V21"/><path d="M17 5.13a3.5 3.5 0 010 6.74"/><path d="M22 21v-1.5a5.5 5.5 0 00-3.5-5.15"/></SVG>,
  branch:   (p)=><SVG {...p}><circle cx="12" cy="4" r="2"/><circle cx="6" cy="12" r="2"/><circle cx="18" cy="12" r="2"/><circle cx="12" cy="20" r="2"/><path d="M12 6v4m0 0l-4.5 2M12 10l4.5 2M12 14v4"/></SVG>,
  finance:  (p)=><SVG {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v1m0 8v1"/><path d="M9.5 10.5A2.5 2.5 0 0112 8h.5a2.5 2.5 0 010 5h-1a2.5 2.5 0 000 5H12a2.5 2.5 0 002.5-2"/></SVG>,
  report:   (p)=><SVG {...p}><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></SVG>,
  calendar: (p)=><SVG {...p}><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></SVG>,
  settings: (p)=><SVG {...p}><circle cx="12" cy="12" r="3"/><path d="M12 2v2m0 16v2M4.22 4.22l1.42 1.42m12.72 12.72l1.42 1.42M2 12h2m16 0h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/></SVG>,
  upload:   (p)=><SVG {...p}><polyline points="16 16 12 12 8 16"/><line x1="12" y1="12" x2="12" y2="21"/><path d="M20.39 18.39A5 5 0 0018 9h-1.26A8 8 0 103 16.3"/></SVG>,
  map:      (p)=><SVG {...p}><polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"/><line x1="8" y1="2" x2="8" y2="18"/><line x1="16" y1="6" x2="16" y2="22"/></SVG>,
  plus:     (p)=><SVG {...p}><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></SVG>,
  check:    (p)=><SVG {...p}><polyline points="20 6 9 17 4 12"/></SVG>,
  chevronR: (p)=><SVG {...p}><polyline points="9 18 15 12 9 6"/></SVG>,
};

/* ═══════════════════════════════════════════════════════════
   USER MANAGEMENT
═══════════════════════════════════════════════════════════ */
const UserManagementPage = ({ role }) => {
  const [users, setUsers] = useState([]);
  const [members, setMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null);
  const [selected, setSelected] = useState(null);
  const [form, setForm] = useState({ name:"", email:"", username:"", password:"", role:"regular", branch_id:"", member_id:"" });
  const [branches, setBranches] = useState([]);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const [search, setSearch] = useState("");
  const [filterRole, setFilterRole] = useState("all");
  const [memberSearch, setMemberSearch] = useState("");
  const mob = useIsMobile();
  const [resetModalUser, setResetModalUser] = useState(null);
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [resetting, setResetting] = useState(false);

  const openResetModal = (u) => {
    setResetModalUser(u);
    setNewPassword("");
    setConfirmPassword("");
  };

  const handleResetPassword = async () => {
    if (!newPassword || newPassword.length < 6) { alert("Password must be at least 6 characters."); return; }
    if (newPassword !== confirmPassword) { alert("Passwords do not match."); return; }
    setResetting(true);
    try {
      const { data: sessionData } = await supabase.auth.getSession();
      const accessToken = sessionData?.session?.access_token;
      if (!accessToken) { alert("Session expired. Please log in again."); setResetting(false); return; }
      const { data, error } = await supabase.functions.invoke("reset-password", {
        headers: { Authorization: `Bearer ${accessToken}` },
        body: { userId: resetModalUser.id, newPassword },
      });
      if (error || data?.error) {
        alert("Failed: " + (data?.error || error.message));
      } else {
        setToast({ msg:`Password updated for ${resetModalUser?.members?.name || resetModalUser?.email}`, type:"success" });
        setResetModalUser(null);
        setNewPassword("");
        setConfirmPassword("");
      }
    } catch (err) {
      alert("Failed to update password.");
    } finally {
      setResetting(false);
    }
  };

  useEffect(() => {
    const fetchAllMembers = async () => {
      let all = [], from = 0;
      while (true) {
        const { data, error } = await supabase.from("members").select("id, name, member_code")
          .order("name", { ascending: true }).range(from, from + 999);
        if (error || !data || data.length === 0) break;
        all = [...all, ...data];
        if (data.length < 1000) break;
        from += 1000;
      }
      return all;
    };

    const loadAll = async () => {
      const { data: sessionData } = await supabase.auth.getSession();
      const accessToken = sessionData?.session?.access_token;
      const [u, m, b, authUsers] = await Promise.all([
        supabase.from("profiles").select("id, username, role, branch_id, member_id, members(name), branches(name)").order("username"),
        fetchAllMembers(),
        supabase.from("branches").select("id, name").order("name"),
        supabase.functions.invoke("list-users", { headers: { Authorization: `Bearer ${accessToken}` } }),
      ]);
      const emailMap = {};
      (authUsers?.data?.users || []).forEach(au => { emailMap[au.id] = au.email; });
      setUsers((u.data || []).map(p => ({ ...p, email: emailMap[p.id] || null })));
      setMembers(m);
      if (b.data) setBranches(b.data);
      setLoading(false);
    };
    loadAll();
  }, []);

  const openEdit = (u) => {
    setSelected(u);
    setForm({ name: u.members?.name||"", email: u.email||"", username: u.username||"",
      password:"", role: u.role||"regular", branch_id: u.branch_id||"", member_id: u.member_id||"" });
    setModal("edit");
  };

  const openInvite = () => {
    setSelected(null);
    setForm({ name:"", email:"", username:"", password:"", role:"regular", branch_id:"", member_id:"" });
    setModal("invite");
  };

  const saveUser = async () => {
    setSaving(true);
    if (modal === "edit") {
      const { error } = await supabase.from("profiles").update({
        username: form.username, role: form.role,
        branch_id: form.branch_id || null, member_id: form.member_id || null,
      }).eq("id", selected.id);
      if (error) { setToast({ msg:"Update failed: " + error.message, type:"error" }); }
      else {
        setUsers(prev => prev.map(u => u.id === selected.id
          ? { ...u, ...form, branches: branches.find(b=>b.id===form.branch_id) } : u));
        setToast({ msg:`${form.name} updated`, type:"success" });
        logAction("user_updated", `Updated ${form.name}`, "user", selected.id);
        setModal(null);
      }
    } else {
      const { data: sessionData } = await supabase.auth.getSession();
      const accessToken = sessionData?.session?.access_token;
      if (!accessToken) { setToast({ msg:"Session expired.", type:"error" }); setSaving(false); return; }
      const { data, error } = await supabase.functions.invoke("create-user", {
        headers: { Authorization: `Bearer ${accessToken}` },
        body: {
          email: form.email, username: form.username, password: form.password,
          role: form.role, branch_id: form.branch_id || null, member_id: form.member_id || null,
          member_name: members.find(m => m.id === form.member_id)?.name || "",
        },
      });
      if (error || data?.error) {
        setToast({ msg:"Create failed: " + (data?.error || error.message), type:"error" });
      } else {
        setUsers(prev => [...prev, { id: data.userId, name: form.name, email: form.email,
          role: form.role, branch_id: form.branch_id, member_id: form.member_id,
          branches: branches.find(b=>b.id===form.branch_id) }]);
        setToast({ msg:`${form.name} created`, type:"success" });
        setModal(null);
        logAction("user_created", `Created ${form.name}`, "user", data.userId);
      }
    }
    setSaving(false);
  };

  const deactivateUser = async (u) => {
    if (!confirm(`Deactivate ${u.members?.name}?`)) return;
    const { error } = await supabase.from("profiles").update({ role:"deactivated" }).eq("id", u.id);
    if (error) { setToast({ msg:"Failed: " + error.message, type:"error" }); return; }
    setUsers(prev => prev.map(x => x.id===u.id ? {...x, role:"deactivated"} : x));
    setToast({ msg:`${u.members?.name} deactivated`, type:"warn" });
    logAction("user_deactivated", `Deactivated ${u.members?.name}`, "user", u.id);
  };

  const reactivateUser = async (u) => {
    const { error } = await supabase.from("profiles").update({ role:"regular" }).eq("id", u.id);
    if (error) { setToast({ msg:"Failed: " + error.message, type:"error" }); return; }
    setUsers(prev => prev.map(x => x.id===u.id ? {...x, role:"regular"} : x));
    setToast({ msg:`${u.members?.name} re-activated`, type:"success" });
    logAction("user_activated", `Activated ${u.members?.name}`, "user", u.id);
  };

  const deleteUser = async (u) => {
    if (!confirm(`Permanently delete ${u.members?.name}?`)) return;
    const { error } = await supabase.from("profiles").delete().eq("id", u.id);
    if (error) { setToast({ msg:"Failed: " + error.message, type:"error" }); return; }
    setUsers(prev => prev.filter(x => x.id !== u.id));
    setToast({ msg:`${u.members?.name} deleted`, type:"error" });
    logAction("user_deleted", `Deleted ${u.members?.name}`, "user", u.id);
  };

  const updateRoleInline = async (u, newRole) => {
    const { error } = await supabase.from("profiles").update({ role: newRole }).eq("id", u.id);
    if (error) { setToast({ msg:"Failed: " + error.message, type:"error" }); return; }
    setUsers(prev => prev.map(x => x.id===u.id ? {...x, role:newRole} : x));
    setToast({ msg:`${u.members?.name} → ${newRole}`, type:"success" });
    logAction("user_role_changed", `${u.members?.name} → ${newRole}`, "user", u.id);
  };

  const ROLE_COLORS = { superadmin:C.rose2, admin:C.violet2, regular:C.blue, deactivated:C.mist };

  const filtered = users.filter(u => {
    const matchSearch = u.members?.name?.toLowerCase().includes(search.toLowerCase()) ||
      u.email?.toLowerCase().includes(search.toLowerCase());
    const matchRole = filterRole === "all" || u.role === filterRole;
    return matchSearch && matchRole;
  });

  const filteredMembers = members.filter(m => {
    const q = memberSearch.toLowerCase();
    return m.name?.toLowerCase().includes(q) || m.member_code?.toLowerCase().includes(q);
  });

  return (
    <div>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}

      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:18, flexWrap:"wrap", gap:10 }}>
        <div>
          <h2 style={{ margin:"0 0 2px", fontWeight:800, fontSize:20, color:C.ink }}>User Management</h2>
          <div style={{ fontSize:12, color:C.mist }}>{users.length} total accounts</div>
        </div>
        <Btn label="+ Invite User" onClick={openInvite} sm/>
      </div>

      <input value={search} onChange={e=>setSearch(e.target.value)}
        placeholder="Search by name or email…"
        style={{ width:"100%", padding:"10px 14px", borderRadius:R.full, border:`1.5px solid ${C.cloud}`,
          fontSize:13, outline:"none", color:C.ink, boxSizing:"border-box", marginBottom:12 }}/>

      <div style={{ display:"flex", gap:6, marginBottom:16, flexWrap:"wrap" }}>
        {[
          { key:"all",        label:`All (${users.length})` },
          { key:"superadmin", label:`Dev (${users.filter(u=>u.role==="superadmin").length})`,    color:C.rose2 },
          { key:"admin",      label:`Admin (${users.filter(u=>u.role==="admin").length})`,       color:C.violet2 },
          { key:"regular",    label:`Member (${users.filter(u=>u.role==="regular").length})`,    color:C.blue },
          { key:"deactivated",label:`Disabled (${users.filter(u=>u.role==="deactivated").length})`, color:C.mist },
        ].map(f=>(
          <Pill key={f.key} label={f.label} active={filterRole===f.key}
            onClick={()=>setFilterRole(f.key)} color={f.color||C.blue}/>
        ))}
      </div>

      {mob ? (
        <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
          {loading ? (
            <div style={{ textAlign:"center", padding:"28px 0", color:C.mist }}>Loading…</div>
          ) : filtered.map(u => (
            <Card key={u.id} style={{ opacity: u.role==="deactivated"?.5:1 }}>
              <div style={{ display:"flex", alignItems:"center", gap:12, marginBottom:12 }}>
                <Av name={u.members?.name||u.email} size={40}/>
                <div style={{ flex:1, minWidth:0 }}>
                  <div style={{ fontWeight:700, color:C.ink, fontSize:14 }}>{u.members?.name||"—"}</div>
                  <div style={{ fontSize:11, color:C.mist, overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>{u.email}</div>
                  {u.username && <div style={{ fontSize:11, color:C.blue, fontWeight:600 }}>@{u.username}</div>}
                </div>
                <Badge label={u.role==="superadmin"?"Dev":u.role} color={ROLE_COLORS[u.role]||C.slate}/>
              </div>
              <div style={{ display:"flex", gap:6, flexWrap:"wrap" }}>
                <button onClick={()=>openEdit(u)} style={{ border:"none", background:C.blue3, borderRadius:R.sm, padding:"6px 12px", cursor:"pointer", fontSize:12, color:C.blue, fontWeight:600 }}>Edit</button>
                <button onClick={()=>openResetModal(u)} style={{ border:"none", background:C.violet3, borderRadius:R.sm, padding:"6px 12px", cursor:"pointer", fontSize:12, color:C.violet, fontWeight:600 }}>Reset PW</button>
                {u.role==="deactivated"
                  ? <button onClick={()=>reactivateUser(u)} style={{ border:"none", background:C.green3, borderRadius:R.sm, padding:"6px 12px", cursor:"pointer", fontSize:12, color:C.green, fontWeight:600 }}>Activate</button>
                  : <button onClick={()=>deactivateUser(u)} style={{ border:"none", background:C.amber3, borderRadius:R.sm, padding:"6px 12px", cursor:"pointer", fontSize:12, color:C.amber, fontWeight:600 }}>Disable</button>
                }
                <button onClick={()=>deleteUser(u)} style={{ border:"none", background:C.rose3, borderRadius:R.sm, padding:"6px 12px", cursor:"pointer", fontSize:12, color:C.rose2, fontWeight:600 }}>Delete</button>
              </div>
            </Card>
          ))}
        </div>
      ) : (
        <Card style={{ padding:0, overflow:"hidden" }}>
          <div style={{ overflowX:"auto" }}>
            <table style={{ width:"100%", borderCollapse:"collapse", fontSize:13 }}>
              <thead>
                <tr style={{ background:C.fog }}>
                  {["User","Username","Role","Branch","Linked Member","Actions"].map(h=>(
                    <th key={h} style={{ textAlign:"left", padding:"10px 16px", color:C.slate, fontWeight:600, fontSize:11, textTransform:"uppercase", letterSpacing:.4, whiteSpace:"nowrap" }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan={6} style={{ padding:"28px 16px", textAlign:"center", color:C.mist }}>Loading…</td></tr>
                ) : filtered.length === 0 ? (
                  <tr><td colSpan={6} style={{ padding:"28px 16px", textAlign:"center", color:C.mist }}>No users found.</td></tr>
                ) : filtered.map(u => {
                  const linkedMember = members.find(m=>m.id===u.member_id);
                  return (
                    <tr key={u.id} style={{ borderTop:`1px solid ${C.fog}`, opacity:u.role==="deactivated"?.5:1 }}>
                      <td style={{ padding:"12px 16px" }}>
                        <div style={{ display:"flex", alignItems:"center", gap:10 }}>
                          <Av name={u.members?.name||u.email} size={34}/>
                          <div>
                            <div style={{ fontWeight:600, color:C.ink }}>{u.members?.name||"—"}</div>
                            <div style={{ fontSize:11, color:C.mist }}>{u.email}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding:"12px 16px", color:C.slate, fontSize:12 }}>{u.username||"—"}</td>
                      <td style={{ padding:"12px 16px" }}>
                        <select value={u.role} onChange={e=>updateRoleInline(u, e.target.value)}
                          style={{ padding:"5px 10px", borderRadius:R.md, border:`1.5px solid ${ROLE_COLORS[u.role]||C.cloud}`,
                            fontSize:12, outline:"none", background:`${ROLE_COLORS[u.role]||C.slate}12`,
                            color:ROLE_COLORS[u.role]||C.slate, fontWeight:600, cursor:"pointer" }}>
                          <option value="regular">Member</option>
                          <option value="admin">Admin</option>
                          <option value="superadmin">Dev / Super</option>
                          <option value="deactivated">Deactivated</option>
                        </select>
                      </td>
                      <td style={{ padding:"12px 16px", color:C.slate, fontSize:12 }}>{u.branches?.name||"—"}</td>
                      <td style={{ padding:"12px 16px" }}>
                        {linkedMember ? (
                          <span style={{ fontSize:12, color:C.green, fontWeight:600 }}>✓ {linkedMember.name}</span>
                        ) : (
                          <span style={{ fontSize:12, color:C.mist }}>Not linked</span>
                        )}
                      </td>
                      <td style={{ padding:"12px 16px" }}>
                        <div style={{ display:"flex", gap:6, flexWrap:"wrap" }}>
                          <button onClick={()=>openEdit(u)} style={{ border:"none", background:C.blue3, borderRadius:R.sm, padding:"6px 10px", cursor:"pointer", fontSize:11, color:C.blue, fontWeight:600 }}>Edit</button>
                          <button onClick={()=>openResetModal(u)} style={{ border:"none", background:C.violet3, borderRadius:R.sm, padding:"6px 10px", cursor:"pointer", fontSize:11, color:C.violet, fontWeight:600 }}>Reset PW</button>
                          {u.role==="deactivated"
                            ? <button onClick={()=>reactivateUser(u)} style={{ border:"none", background:C.green3, borderRadius:R.sm, padding:"6px 10px", cursor:"pointer", fontSize:11, color:C.green, fontWeight:600 }}>Activate</button>
                            : <button onClick={()=>deactivateUser(u)} style={{ border:"none", background:C.amber3, borderRadius:R.sm, padding:"6px 10px", cursor:"pointer", fontSize:11, color:C.amber, fontWeight:600 }}>Disable</button>
                          }
                          <button onClick={()=>deleteUser(u)} style={{ border:"none", background:C.rose3, borderRadius:R.sm, padding:"6px 10px", cursor:"pointer", fontSize:11, color:C.rose2, fontWeight:600 }}>Delete</button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Edit / Invite Modal */}
      <Modal open={!!modal} onClose={()=>setModal(null)} title={modal==="invite"?"Invite New User":"Edit User"}>
        <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:14 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>Link to Member Record</label>
          <input value={memberSearch} onChange={e=>setMemberSearch(e.target.value)}
            placeholder="Search members by name or code…"
            style={{ padding:"9px 14px", border:`1.5px solid ${C.cloud}`, borderRadius:R.md,
              fontSize:13, outline:"none", color:C.ink, marginBottom:6, boxSizing:"border-box" }}/>
          <select value={form.member_id} onChange={e=>{
              const memberId = e.target.value;
              const picked = members.find(m=>m.id===memberId);
              setForm({...form, member_id: memberId, ...(picked ? { name: picked.name } : {}) });
            }}
            style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md, fontSize:14, outline:"none", background:C.white, color:C.ink }}>
            <option value="">— Not linked —</option>
            {filteredMembers.map(m=><option key={m.id} value={m.id}>{m.name} ({m.member_code})</option>)}
          </select>
          {memberSearch && (
            <div style={{ fontSize:11, color:C.mist, marginTop:4 }}>
              {filteredMembers.length} match{filteredMembers.length!==1?"es":""}
            </div>
          )}
        </div>
        {form.member_id && (
          <div style={{ background:C.green3, borderRadius:R.md, padding:"10px 14px", fontSize:12, color:C.green, marginBottom:14 }}>
            ✓ Name auto-filled from member record.
          </div>
        )}
        {!form.member_id && (
          <Inp label="Full Name" value={form.name} onChange={v=>setForm({...form,name:v})} placeholder="Juan dela Cruz" required/>
        )}
        <Inp label="Email Address" value={form.email} onChange={v=>setForm({...form,email:v})} placeholder="juan@example.com" required/>
        {modal==="edit" && (
          <Inp label="Username" value={form.username} onChange={v=>setForm({...form,username:v})} placeholder="juandelacruz" required/>
        )}
        {modal==="invite" && (
          <Inp label="Password" type="password" value={form.password} onChange={v=>setForm({...form,password:v})} placeholder="At least 6 characters" required/>
        )}
        <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:14 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>Role</label>
          <select value={form.role} onChange={e=>setForm({...form,role:e.target.value})}
            style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md, fontSize:14, outline:"none", background:C.white, color:C.ink }}>
            <option value="regular">Regular Member</option>
            <option value="admin">Admin</option>
            <option value="superadmin">Super Admin / Dev</option>
          </select>
        </div>
        <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:14 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>Branch</label>
          <select value={form.branch_id} onChange={e=>setForm({...form,branch_id:e.target.value})}
            style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md, fontSize:14, outline:"none", background:C.white, color:C.ink }}>
            <option value="">— No branch assigned —</option>
            {branches.map(b=><option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        </div>
        <div style={{ display:"flex", gap:8, justifyContent:"space-between" }}>
          <Btn label={saving?"Saving…":modal==="invite"?"Send Invite":"Save Changes"} onClick={saveUser}/>
          <Btn label="Cancel" outline onClick={()=>setModal(null)}/>
        </div>
      </Modal>

      {/* Reset Password Modal */}
      <Modal open={!!resetModalUser} onClose={()=>setResetModalUser(null)} title="Reset User Password">
        {resetModalUser && (
          <div style={{ display:"flex", flexDirection:"column", gap:14 }}>
            <div style={{ fontSize:13, color:C.slate }}>
              Set a new password for <strong style={{ color:C.ink }}>{resetModalUser.members?.name || resetModalUser.email}</strong>.
            </div>
            <Inp label="New Password" type="password" value={newPassword} onChange={v=>setNewPassword(v)} placeholder="At least 6 characters" required/>
            <Inp label="Confirm New Password" type="password" value={confirmPassword} onChange={v=>setConfirmPassword(v)} placeholder="Re-enter new password" required/>
            <div style={{ display:"flex", gap:8, justifyContent:"space-between" }}>
              <Btn label={resetting?"Updating…":"Update Password"} onClick={handleResetPassword}/>
              <Btn label="Cancel" outline onClick={()=>setResetModalUser(null)}/>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};

/* ═══════════════════════════════════════════════════════════
   BRANCHES
═══════════════════════════════════════════════════════════ */
const BranchesPage = () => {
  const [branches, setBranches] = useState([]);
  const [modal, setModal] = useState(false);
  const [editModal, setEditModal] = useState(false);
  const [editTarget, setEditTarget] = useState(null);
  const [form, setForm] = useState({ name:"", address:"", parent_id:"" });
  const [editForm, setEditForm] = useState({ name:"", address:"", parent_id:"" });
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const colors = [C.blue, C.violet2, C.green, C.amber, C.rose2];

  useEffect(() => {
    supabase.from("branches").select("*").order("name")
      .then(({ data }) => { if (data) setBranches(data); });
  }, []);

  const mainBranches = branches.filter(b => !b.parent_id);
  const subOf = (parentId) => branches.filter(b => b.parent_id === parentId);

  const openEdit = (b) => {
    setEditTarget(b);
    setEditForm({ name:b.name, address:b.address||"", parent_id:b.parent_id||"" });
    setEditModal(true);
  };

  const saveBranch = async () => {
    setSaving(true);
    const { error } = await supabase.from("branches").update({
      name: editForm.name, address: editForm.address, parent_id: editForm.parent_id || null,
    }).eq("id", editTarget.id);
    if (error) setToast({ msg:"Failed: " + error.message, type:"error" });
    else {
      setBranches(prev => prev.map(b => b.id===editTarget.id ? {...b,...editForm} : b));
      setEditModal(false);
      setToast({ msg:`"${editForm.name}" updated!`, type:"success" });
      logAction("branch_updated", `Updated "${editForm.name}"`, "branch", editTarget.id);
    }
    setSaving(false);
  };

  const deleteBranch = async (b) => {
    if (!confirm(`Delete "${b.name}"?`)) return;
    const { error } = await supabase.from("branches").delete().eq("id", b.id);
    if (error) setToast({ msg:"Failed: " + error.message, type:"error" });
    else {
      setBranches(prev => prev.filter(x => x.id !== b.id));
      setToast({ msg:`"${b.name}" deleted`, type:"warn" });
      logAction("branch_deleted", `Deleted "${b.name}"`, "branch", b.id);
    }
  };

  const addBranch = async () => {
    if (!form.name.trim()) return;
    setSaving(true);
    const { data, error } = await supabase.from("branches")
      .insert([{ name: form.name, address: form.address, parent_id: form.parent_id || null }])
      .select().single();
    if (error) setToast({ msg:"Failed: " + error.message, type:"error" });
    else {
      setBranches(prev => [...prev, data]);
      setForm({ name:"", address:"", parent_id:"" });
      setModal(false);
      setToast({ msg:`"${data.name}" added!`, type:"success" });
      logAction("branch_added", `Added "${data.name}"`, "branch", data.id);
    }
    setSaving(false);
  };

  return (
    <div>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:18 }}>
        <h2 style={{ margin:0, fontWeight:800, fontSize:20, color:C.ink }}>Church Branches</h2>
        <Btn label="Add Branch" icon={Ico.plus} onClick={()=>setModal(true)} sm/>
      </div>

      {mainBranches.map((b, i) => {
        const subs = subOf(b.id);
        return (
          <div key={b.id} style={{ marginBottom:16 }}>
            <Card style={{ borderLeft:`4px solid ${colors[i%colors.length]}` }}>
              <div style={{ display:"flex", alignItems:"center", gap:14 }}>
                <div style={{ width:42, height:42, borderRadius:R.md, background:`${colors[i%colors.length]}12`,
                  display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                  <Ico.map size={20} color={colors[i%colors.length]}/>
                </div>
                <div style={{ flex:1 }}>
                  <div style={{ fontWeight:700, fontSize:15, color:C.ink }}>{b.name}</div>
                  {b.address && <div style={{ fontSize:12, color:C.mist }}>{b.address}</div>}
                </div>
                <Badge label={`${subs.length} sub-branch${subs.length!==1?"es":""}`} color={colors[i%colors.length]}/>
                <div style={{ display:"flex", gap:6 }}>
                  <button onClick={()=>openEdit(b)} style={{ border:"none", background:C.blue3, borderRadius:R.sm, padding:"5px 10px", cursor:"pointer", fontSize:11, color:C.blue, fontWeight:600 }}>Edit</button>
                  <button onClick={()=>deleteBranch(b)} style={{ border:"none", background:C.rose3, borderRadius:R.sm, padding:"5px 10px", cursor:"pointer", fontSize:11, color:C.rose2, fontWeight:600 }}>Delete</button>
                </div>
              </div>
            </Card>
            {subs.map((s, si) => (
              <div key={s.id} style={{ display:"flex", marginLeft:24 }}>
                <div style={{ width:24, display:"flex", flexDirection:"column", alignItems:"center", flexShrink:0 }}>
                  <div style={{ width:2, flex:1, background:C.fog }}/>
                  <div style={{ width:16, height:2, background:C.fog }}/>
                  {si < subs.length-1 && <div style={{ width:2, flex:1, background:C.fog }}/>}
                </div>
                <Card style={{ flex:1, marginBottom: si < subs.length-1 ? 6 : 0, padding:"12px 16px", background:C.fog, border:"none", boxShadow:"none", borderRadius:R.md }}>
                  <div style={{ display:"flex", alignItems:"center", gap:10 }}>
                    <Ico.branch size={15} color={C.slate}/>
                    <div style={{ flex:1 }}>
                      <div style={{ fontWeight:600, fontSize:13, color:C.ink }}>{s.name}</div>
                      {s.address && <div style={{ fontSize:11, color:C.mist }}>{s.address}</div>}
                    </div>
                    <Badge label="Sub-branch" color={C.slate}/>
                    <div style={{ display:"flex", gap:6 }}>
                      <button onClick={()=>openEdit(s)} style={{ border:"none", background:C.blue3, borderRadius:R.sm, padding:"5px 10px", cursor:"pointer", fontSize:11, color:C.blue, fontWeight:600 }}>Edit</button>
                      <button onClick={()=>deleteBranch(s)} style={{ border:"none", background:C.rose3, borderRadius:R.sm, padding:"5px 10px", cursor:"pointer", fontSize:11, color:C.rose2, fontWeight:600 }}>Delete</button>
                    </div>
                  </div>
                </Card>
              </div>
            ))}
          </div>
        );
      })}

      <Modal open={modal} onClose={()=>setModal(false)} title="Add Branch / Sub-branch">
        <Inp label="Branch Name" value={form.name} onChange={v=>setForm({...form,name:v})} placeholder="e.g. Barangay Sto. Tomas" required/>
        <Inp label="Address (optional)" value={form.address} onChange={v=>setForm({...form,address:v})} placeholder="e.g. Sto. Tomas, Pinamalayan"/>
        <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:14 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>Parent Branch</label>
          <select value={form.parent_id} onChange={e=>setForm({...form,parent_id:e.target.value})}
            style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md, fontSize:14, outline:"none", background:C.white, color:C.ink }}>
            <option value="">— Main Branch (no parent) —</option>
            {mainBranches.map(b=><option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        </div>
        <Btn label={saving?"Saving…":"Add Branch"} icon={Ico.plus} onClick={addBranch} full/>
      </Modal>

      <Modal open={editModal} onClose={()=>setEditModal(false)} title="Edit Branch">
        <Inp label="Branch Name" value={editForm.name} onChange={v=>setEditForm({...editForm,name:v})} required/>
        <Inp label="Address (optional)" value={editForm.address} onChange={v=>setEditForm({...editForm,address:v})}/>
        <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:14 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>Parent Branch</label>
          <select value={editForm.parent_id} onChange={e=>setEditForm({...editForm,parent_id:e.target.value})}
            style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md, fontSize:14, outline:"none", background:C.white, color:C.ink }}>
            <option value="">— Main Branch (no parent) —</option>
            {mainBranches.filter(b=>b.id!==editTarget?.id).map(b=><option key={b.id} value={b.id}>{b.name}</option>)}
          </select>
        </div>
        <Btn label={saving?"Saving…":"Save Changes"} icon={Ico.check} onClick={saveBranch} full/>
      </Modal>
    </div>
  );
};

/* ═══════════════════════════════════════════════════════════
   FINANCE CATEGORIES
═══════════════════════════════════════════════════════════ */
const FinanceCategoriesPage = () => {
  const [categories, setCategories] = useState([]);
  const [modal, setModal] = useState(false);
  const [editModal, setEditModal] = useState(false);
  const [editTarget, setEditTarget] = useState(null);
  const [form, setForm] = useState({ name:"", description:"" });
  const [editForm, setEditForm] = useState({ name:"", description:"" });
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const colors = [C.blue, C.violet2, C.green, C.amber, C.rose2, "#0891B2", "#D97706"];

  useEffect(() => {
    supabase.from("finance_categories").select("*").order("name")
      .then(({ data }) => { if (data) setCategories(data); });
  }, []);

  const addCategory = async () => {
    if (!form.name.trim()) return;
    setSaving(true);
    const { data, error } = await supabase.from("finance_categories")
      .insert([{ name: form.name, description: form.description }]).select().single();
    if (error) setToast({ msg:"Failed: " + error.message, type:"error" });
    else {
      setCategories(prev => [...prev, data]);
      setForm({ name:"", description:"" });
      setModal(false);
      setToast({ msg:`"${data.name}" added!`, type:"success" });
      logAction("category_added", `Added "${data.name}"`, "finance_category", data.id);
    }
    setSaving(false);
  };

  const saveCategory = async () => {
    setSaving(true);
    const { error } = await supabase.from("finance_categories").update({
      name: editForm.name, description: editForm.description,
    }).eq("id", editTarget.id);
    if (error) setToast({ msg:"Failed: " + error.message, type:"error" });
    else {
      setCategories(prev => prev.map(c => c.id===editTarget.id ? {...c,...editForm} : c));
      setEditModal(false);
      setToast({ msg:`"${editForm.name}" updated!`, type:"success" });
      logAction("category_updated", `Updated "${editForm.name}"`, "finance_category", editTarget.id);
    }
    setSaving(false);
  };

  const deleteCategory = async (c) => {
    if (!confirm(`Delete "${c.name}"?`)) return;
    const { error } = await supabase.from("finance_categories").delete().eq("id", c.id);
    if (error) setToast({ msg:"Failed: " + error.message, type:"error" });
    else {
      setCategories(prev => prev.filter(x => x.id !== c.id));
      setToast({ msg:`"${c.name}" deleted`, type:"warn" });
      logAction("category_deleted", `Deleted "${c.name}"`, "finance_category", c.id);
    }
  };

  return (
    <div>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:18 }}>
        <h2 style={{ margin:0, fontWeight:800, fontSize:20, color:C.ink }}>Finance Categories</h2>
        <Btn label="Add Category" icon={Ico.plus} onClick={()=>setModal(true)} sm/>
      </div>
      <div style={{ display:"flex", flexDirection:"column", gap:10, maxWidth:560 }}>
        {categories.length === 0
          ? <p style={{ color:C.mist, fontSize:13 }}>No categories yet.</p>
          : categories.map((c, i) => {
              const color = colors[i % colors.length];
              return (
                <Card key={c.id} style={{ display:"flex", alignItems:"center", gap:14, padding:"14px 18px", borderLeft:`4px solid ${color}` }}>
                  <div style={{ width:38, height:38, borderRadius:R.md, background:`${color}12`, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                    <Ico.finance size={17} color={color}/>
                  </div>
                  <div style={{ flex:1 }}>
                    <div style={{ fontWeight:700, fontSize:14, color:C.ink }}>{c.name}</div>
                    {c.description && <div style={{ fontSize:12, color:C.mist }}>{c.description}</div>}
                  </div>
                  <div style={{ display:"flex", gap:6 }}>
                    <button onClick={()=>{ setEditTarget(c); setEditForm({ name:c.name, description:c.description||"" }); setEditModal(true); }}
                      style={{ border:"none", background:C.blue3, borderRadius:R.sm, padding:"5px 10px", cursor:"pointer", fontSize:11, color:C.blue, fontWeight:600 }}>Edit</button>
                    <button onClick={()=>deleteCategory(c)}
                      style={{ border:"none", background:C.rose3, borderRadius:R.sm, padding:"5px 10px", cursor:"pointer", fontSize:11, color:C.rose2, fontWeight:600 }}>Delete</button>
                  </div>
                </Card>
              );
            })
        }
      </div>
      <Modal open={modal} onClose={()=>setModal(false)} title="Add Finance Category">
        <Inp label="Category Name" value={form.name} onChange={v=>setForm({...form,name:v})} placeholder="e.g. Tithes" required/>
        <Inp label="Description (optional)" value={form.description} onChange={v=>setForm({...form,description:v})} placeholder="e.g. Regular tithe giving"/>
        <Btn label={saving?"Saving…":"Add Category"} icon={Ico.plus} onClick={addCategory} full/>
      </Modal>
      <Modal open={editModal} onClose={()=>setEditModal(false)} title="Edit Category">
        <Inp label="Category Name" value={editForm.name} onChange={v=>setEditForm({...editForm,name:v})} required/>
        <Inp label="Description (optional)" value={editForm.description} onChange={v=>setEditForm({...editForm,description:v})}/>
        <Btn label={saving?"Saving…":"Save Changes"} icon={Ico.check} onClick={saveCategory} full/>
      </Modal>
    </div>
  );
};

/* ═══════════════════════════════════════════════════════════
   AUDIT LOG
═══════════════════════════════════════════════════════════ */
const AuditLogPage = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all");

  useEffect(() => {
    supabase.from("audit_logs").select("*").order("created_at", { ascending: false }).limit(100)
      .then(({ data }) => { if (data) setLogs(data); setLoading(false); });
  }, []);

  const ACTION_FILTERS = ["all","login","member_created","member_updated","finance_submitted",
    "attendance_recorded","branch_added","branch_deleted","user_updated","user_role_changed",
    "user_deactivated","user_activated","user_deleted"];

  const actionColor = (a) => {
    if (!a) return C.slate;
    if (a.includes("delete")) return C.rose2;
    if (a.includes("create") || a.includes("added")) return C.green;
    if (a.includes("update") || a.includes("edit")) return C.blue;
    if (a.includes("login")) return C.violet2;
    if (a.includes("submit") || a.includes("record")) return C.amber;
    return C.slate;
  };

  const filtered = filter === "all" ? logs : logs.filter(l => l.action === filter);

  return (
    <div>
      <h2 style={{ margin:"0 0 16px", fontWeight:800, fontSize:20, color:C.ink }}>Audit Log</h2>
      <div style={{ display:"flex", gap:6, marginBottom:16, flexWrap:"wrap" }}>
        {ACTION_FILTERS.map(a => (
          <Pill key={a} label={a === "all" ? `All (${logs.length})` : a.replace(/_/g," ")}
            active={filter===a} onClick={()=>setFilter(a)} color={actionColor(a)}/>
        ))}
      </div>
      <Card style={{ padding:0, overflow:"hidden" }}>
        <div style={{ overflowX:"auto" }}>
          <table style={{ width:"100%", borderCollapse:"collapse", fontSize:13 }}>
            <thead>
              <tr style={{ background:C.fog }}>
                {["User","Action","Details","Entity","When"].map(h=>(
                  <th key={h} style={{ textAlign:"left", padding:"10px 16px", color:C.slate, fontWeight:600, fontSize:11, textTransform:"uppercase", letterSpacing:.4, whiteSpace:"nowrap" }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} style={{ padding:"28px 16px", textAlign:"center", color:C.mist }}>Loading…</td></tr>
              ) : filtered.length === 0 ? (
                <tr><td colSpan={5} style={{ padding:"28px 16px", textAlign:"center", color:C.mist }}>No logs found.</td></tr>
              ) : filtered.map(l => (
                <tr key={l.id} style={{ borderTop:`1px solid ${C.fog}` }}>
                  <td style={{ padding:"11px 16px" }}>
                    <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                      <Av name={l.user_name||"?"} size={28}/>
                      <span style={{ fontWeight:500, color:C.ink, fontSize:12 }}>{l.user_name||"—"}</span>
                    </div>
                  </td>
                  <td style={{ padding:"11px 16px" }}>
                    <Badge label={(l.action||"—").replace(/_/g," ")} color={actionColor(l.action)}/>
                  </td>
                  <td style={{ padding:"11px 16px", color:C.slate, fontSize:12, maxWidth:220 }}>{l.details||"—"}</td>
                  <td style={{ padding:"11px 16px", color:C.mist, fontSize:12 }}>{l.entity||"—"}</td>
                  <td style={{ padding:"11px 16px", color:C.mist, fontSize:11, whiteSpace:"nowrap" }}>
                    {new Date(l.created_at).toLocaleString("en-PH",{ month:"short", day:"numeric", hour:"2-digit", minute:"2-digit" })}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
};

/* ═══════════════════════════════════════════════════════════
   MONTHLY THEME
═══════════════════════════════════════════════════════════ */
const MonthlyThemePage = () => {
  const [toast, setToast] = useState(null);
  const [themeFile, setThemeFile] = useState(null);
  const [themeUploading, setThemeUploading] = useState(false);
  const [themeUrl, setThemeUrl] = useState(null);
  const [themeColor, setThemeColor] = useState("#1D4ED8");

  useEffect(() => {
    supabase.from("monthly_theme").select("image_url, color").eq("id", 1).single()
      .then(({ data }) => {
        if (data?.image_url) setThemeUrl(data.image_url);
        if (data?.color) setThemeColor(data.color);
      });
  }, []);

  const uploadImage = async (file, folder, onSuccess) => {
    const ext = file.name.split(".").pop().toLowerCase();
    const path = `${folder}-${Date.now()}.${ext}`;
    const { error } = await supabase.storage.from("theme").upload(path, file, { upsert: true });
    if (error) { setToast({ msg:"Upload failed: " + error.message, type:"error" }); return null; }
    const { data:{ publicUrl } } = supabase.storage.from("theme").getPublicUrl(path);
    onSuccess(publicUrl);
    return publicUrl;
  };

  const saveThemeColor = async () => {
    const { error } = await supabase.from("monthly_theme").update({
      color: themeColor, updated_at: new Date().toISOString()
    }).eq("id", 1);
    if (error) setToast({ msg:"Failed: " + error.message, type:"error" });
    else setToast({ msg:"Theme color saved! App will update.", type:"success" });
  };

  return (
    <div>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}
      <h2 style={{ margin:"0 0 18px", fontWeight:800, fontSize:20, color:C.ink }}>Monthly Theme & Backgrounds</h2>

      <Card style={{ maxWidth:560, marginBottom:16 }}>
        <h3 style={{ margin:"0 0 12px", fontWeight:700, fontSize:14, color:C.ink }}>🎨 Primary Theme Color</h3>
        <p style={{ fontSize:12, color:C.mist, margin:"0 0 16px" }}>This color will be used throughout the entire app.</p>
        <div style={{ display:"flex", gap:16, alignItems:"center", marginBottom:16 }}>
          <div style={{ width:80, height:80, borderRadius:R.xl, background:themeColor, border:`3px solid ${C.fog}`, boxShadow:SH.sm, flexShrink:0 }}/>
          <div style={{ flex:1 }}>
            <label style={{ fontSize:12, fontWeight:600, color:C.slate, display:"block", marginBottom:8 }}>Pick Color</label>
            <input type="color" value={themeColor} onChange={e=>setThemeColor(e.target.value)}
              style={{ width:"100%", height:50, borderRadius:R.md, border:`2px solid ${C.fog}`, cursor:"pointer" }}/>
          </div>
        </div>
        <div style={{ marginBottom:16 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate, display:"block", marginBottom:8 }}>Hex Code</label>
          <input type="text" value={themeColor}
            onChange={e=>{ if (e.target.value.match(/^#[0-9A-F]{6}$/i)) setThemeColor(e.target.value); }}
            placeholder="#1D4ED8"
            style={{ width:"100%", padding:"10px 14px", borderRadius:R.md, border:`1.5px solid ${C.cloud}`,
              fontSize:13, boxSizing:"border-box", fontWeight:600, fontFamily:"monospace" }}/>
        </div>
        <Btn label="Save Theme Color" onClick={saveThemeColor} full/>
      </Card>

      <Card style={{ maxWidth:560 }}>
        <h3 style={{ margin:"0 0 6px", fontWeight:700, fontSize:14, color:C.ink }}>Monthly Theme Banner</h3>
        <p style={{ fontSize:12, color:C.mist, marginTop:0, marginBottom:14 }}>Shown on the Dashboard and as Login page background.</p>
        {themeUrl && (
          <div style={{ marginBottom:14, borderRadius:R.xl, overflow:"hidden" }}>
            <img src={themeUrl} alt="Current" style={{ width:"100%", display:"block", maxHeight:200, objectFit:"cover" }}/>
          </div>
        )}
        <input type="file" accept="image/jpeg,image/png,image/webp" onChange={e=>setThemeFile(e.target.files[0])}/>
        {themeFile && (
          <div style={{ marginTop:12 }}>
            <Btn label={themeUploading?"Uploading…":"Upload"} onClick={async () => {
              setThemeUploading(true);
              const url = await uploadImage(themeFile, "theme", setThemeUrl);
              if (url) {
                await supabase.from("monthly_theme").update({ image_url: url, updated_at: new Date().toISOString() }).eq("id", 1);
                setToast({ msg:"Monthly theme updated!", type:"success" });
                setThemeFile(null);
              }
              setThemeUploading(false);
            }}/>
          </div>
        )}
      </Card>
    </div>
  );
};

/* ═══════════════════════════════════════════════════════════
   APP SETTINGS
═══════════════════════════════════════════════════════════ */
const AppSettingsPage = () => {
  const [settings, setSettings] = useState({ church_name:"", address:"", contact_email:"", contact_phone:"", logo_url:"" });
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const [loading, setLoading] = useState(true);
  const [logoFile, setLogoFile] = useState(null);
  const [logoUploading, setLogoUploading] = useState(false);

  useEffect(() => {
    supabase.from("app_settings").select("key, value").then(({ data }) => {
      if (data) {
        const map = {};
        data.forEach(r => { map[r.key] = r.value || ""; });
        setSettings(prev => ({ ...prev, ...map }));
      }
      setLoading(false);
    });
  }, []);

  const save = async () => {
    setSaving(true);
    const results = await Promise.all(
      Object.entries(settings).map(([key, value]) =>
        supabase.from("app_settings").upsert({ key, value }, { onConflict:"key" })
      )
    );
    const failed = results.find(r => r.error);
    if (failed) setToast({ msg:"Failed: " + failed.error.message, type:"error" });
    else setToast({ msg:"Settings saved!", type:"success" });
    setSaving(false);
  };

  if (loading) return <div style={{ color:C.mist, padding:"28px 0" }}>Loading settings…</div>;

  return (
    <div>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}
      <h2 style={{ margin:"0 0 18px", fontWeight:800, fontSize:20, color:C.ink }}>App Settings</h2>
      <Card style={{ maxWidth:560 }}>
        <h3 style={{ margin:"0 0 16px", fontWeight:700, fontSize:14, color:C.ink }}>Church Information</h3>
        <Inp label="Church Name" value={settings.church_name} onChange={v=>setSettings({...settings,church_name:v})} placeholder="e.g. JIL Pinamalayan"/>
        <Inp label="Address" value={settings.address} onChange={v=>setSettings({...settings,address:v})} placeholder="e.g. Pinamalayan, Oriental Mindoro"/>
        <Inp label="Contact Email" value={settings.contact_email} onChange={v=>setSettings({...settings,contact_email:v})} placeholder="e.g. jilpinamalayan@gmail.com"/>
        <Inp label="Contact Phone" value={settings.contact_phone} onChange={v=>setSettings({...settings,contact_phone:v})} placeholder="e.g. 09XX-XXX-XXXX"/>
        <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:14 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate, letterSpacing:.2 }}>Church Logo</label>
          <input type="file" accept="image/jpeg,image/png,image/svg+xml,image/webp"
            onChange={e=>setLogoFile(e.target.files[0])}/>
          {logoFile && (
            <div style={{ marginTop:8 }}>
              <Btn sm label={logoUploading?"Uploading…":"Upload Logo"} onClick={async () => {
                setLogoUploading(true);
                const ext = logoFile.name.split(".").pop().toLowerCase();
                const path = `logo-${Date.now()}.${ext}`;
                const { error: upErr } = await supabase.storage.from("theme").upload(path, logoFile, { upsert: true });
                if (upErr) { setToast({ msg:"Upload failed: " + upErr.message, type:"error" }); }
                else {
                  const { data:{ publicUrl } } = supabase.storage.from("theme").getPublicUrl(path);
                  setSettings(prev => ({ ...prev, logo_url: publicUrl }));
                  setLogoFile(null);
                  setToast({ msg:"Logo uploaded!", type:"success" });
                }
                setLogoUploading(false);
              }}/>
            </div>
          )}
          {settings.logo_url && (
            <div style={{ marginTop:8, display:"flex", alignItems:"center", gap:10 }}>
              <img src={settings.logo_url} alt="Logo"
                style={{ width:56, height:56, objectFit:"contain", borderRadius:R.md, border:`1px solid ${C.fog}`, background:C.fog, padding:4 }}/>
              <span style={{ fontSize:12, color:C.mist }}>Current logo</span>
            </div>
          )}
        </div>
        <Btn label={saving?"Saving…":"Save Changes"} icon={Ico.check} onClick={save} full/>
      </Card>
    </div>
  );
};

/* ═══════════════════════════════════════════════════════════
   SETTINGS PAGE (main entry point)
═══════════════════════════════════════════════════════════ */
export default function SettingsPage({ role }) {
  const [subPage, setSubPage] = useState(null);

  const items = [
    { key:"users",             I:Ico.users,    label:"User Management",    desc:"Add, edit, deactivate CMS accounts",            color:C.blue },
    { key:"branches",          I:Ico.branch,   label:"Branch Management",  desc:"Configure branch details and leaders",           color:C.violet2 },
    { key:"finance-categories",I:Ico.finance,  label:"Finance Categories", desc:"Edit giving types and fund labels",              color:C.green },
    { key:"audit-log",         I:Ico.report,   label:"Audit Log",          desc:"Track who did what and when",                   color:C.violet2 },
    { key:"monthly-theme",     I:Ico.calendar, label:"Monthly Theme",      desc:"Upload the banner shown on dashboard and login", color:C.amber },
    { key:"app-settings",      I:Ico.settings, label:"App Settings",       desc:"Church name, address, contact info",            color:C.slate },
  ];

  if (subPage === "users")              return <div><BackBtn onClick={()=>setSubPage(null)}/><UserManagementPage role={role}/></div>;
  if (subPage === "branches")           return <div><BackBtn onClick={()=>setSubPage(null)}/><BranchesPage/></div>;
  if (subPage === "finance-categories") return <div><BackBtn onClick={()=>setSubPage(null)}/><FinanceCategoriesPage/></div>;
  if (subPage === "audit-log")          return <div><BackBtn onClick={()=>setSubPage(null)}/><AuditLogPage/></div>;
  if (subPage === "monthly-theme")      return <div><BackBtn onClick={()=>setSubPage(null)}/><MonthlyThemePage/></div>;
  if (subPage === "app-settings")       return <div><BackBtn onClick={()=>setSubPage(null)}/><AppSettingsPage/></div>;

  return (
    <div>
      <h2 style={{ margin:"0 0 18px", fontWeight:800, fontSize:20, color:C.ink }}>Settings</h2>
      <div style={{ display:"flex", flexDirection:"column", gap:10, maxWidth:520 }}>
        {items.map(s => (
          <Card key={s.key} onClick={()=>setSubPage(s.key)} hoverable
            style={{ display:"flex", alignItems:"center", gap:14, padding:"14px 18px" }}>
            <div style={{ width:40, height:40, borderRadius:R.md, background:`${s.color}12`,
              display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
              <s.I size={18} color={s.color}/>
            </div>
            <div style={{ flex:1 }}>
              <div style={{ fontWeight:600, fontSize:14, color:C.ink }}>{s.label}</div>
              <div style={{ fontSize:12, color:C.mist }}>{s.desc}</div>
            </div>
            <Ico.chevronR size={15} color={C.cloud}/>
          </Card>
        ))}
      </div>
    </div>
  );
}
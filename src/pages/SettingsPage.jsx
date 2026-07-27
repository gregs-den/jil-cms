import { useState, useEffect } from "react";
import { supabase } from "../lib/supabaseClient";

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

const BRANCHES = ["Main – Pinamalayan","Sta. Rita","Buli","Inclanay","Luma","Bacungan","Bagong Silang","Bukal","Pamana","Papandayan","Pier"];
const ROLES = ["member", "admin", "superadmin"];

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

const Btn = ({ label, onClick, color=C.blue, outline, full, sm, danger }) => (
  <button onClick={onClick} style={{
    display:"flex", alignItems:"center", justifyContent:"center", gap:6,
    padding: sm?"7px 14px":"10px 20px",
    background: danger ? C.rose2 : outline?"transparent":color,
    color: danger ? C.white : outline?color:C.white,
    border:`1.5px solid ${danger ? C.rose2 : color}`, borderRadius:R.full,
    fontWeight:600, fontSize:sm?12:14, cursor:"pointer",
    transition:"all .15s", width:full?"100%":"auto", flexShrink:0,
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

const Modal = ({ open, onClose, title, children, width=520 }) => {
  if (!open) return null;
  return (
    <div onClick={onClose} style={{ position:"fixed", inset:0,
      background:"rgba(10,15,30,.5)", backdropFilter:"blur(6px)",
      zIndex:1000, display:"flex", alignItems:"center", justifyContent:"center",
      padding:16, boxSizing:"border-box" }}>
      <div onClick={e=>e.stopPropagation()} style={{ background:C.white, borderRadius:R.xxl,
        boxShadow:SH.lg, width:"100%", maxWidth:width, maxHeight:"92vh",
        overflowY:"auto", overflowX:"hidden", boxSizing:"border-box" }}>
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center",
          padding:"22px 24px 0" }}>
          <h3 style={{ margin:0, fontWeight:800, fontSize:17, color:C.ink }}>{title}</h3>
          <button onClick={onClose} style={{ border:"none", background:C.fog, borderRadius:"50%",
            width:32, height:32, cursor:"pointer", display:"flex", alignItems:"center",
            justifyContent:"center", fontSize:16, color:C.slate, lineHeight:1, flexShrink:0 }}>
            ✕
          </button>
        </div>
        <div style={{ padding:"16px 24px 28px", boxSizing:"border-box", width:"100%" }}>
          {children}
        </div>
      </div>
    </div>
  );
};

const Av = ({ name, size=36 }) => {
  const colors = [C.blue, C.violet2, C.rose2, C.green2, C.amber2, "#0EA5E9"];
  let h = 0; for (let c of (name||"?")) h += c.charCodeAt(0);
  const color = colors[h % colors.length];
  return (
    <div style={{
      width:size, height:size, borderRadius:"50%",
      background: color,
      display:"flex", alignItems:"center", justifyContent:"center",
      color:"#fff", fontWeight:700,
      fontSize: size*0.37, flexShrink:0,
      fontFamily:"system-ui,sans-serif",
      letterSpacing:-.5,
    }}>
      {(name||"?").split(" ").map(w=>w[0]).join("").slice(0,2).toUpperCase()}
    </div>
  );
};

const ROLE_COLORS = {
  superadmin: C.rose2,
  admin: C.violet2,
  member: C.blue,
};

// ════════════════════════════════════════════════════════════
//  USER MANAGEMENT PAGE
// ════════════════════════════════════════════════════════════
export default function UserManagementPage({ role, user }) {
  const mob = useIsMobile();
  const [tab, setTab] = useState("users");
  const [users, setUsers] = useState([]);
  const [members, setMembers] = useState([]);
  const [branches, setBranches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState(null);
  const [modal, setModal] = useState(null);
  const [memberSearch, setMemberSearch] = useState("");
  const [saving, setSaving] = useState(false);

  const [form, setForm] = useState({ 
    name:"", email:"", username:"", password:"", role:"member", branch_id:"", member_id:"" 
  });
  const [selected, setSelected] = useState(null);

  // Only superadmin can access this
  useEffect(() => {
    if (role !== "superadmin") {
      setToast({ msg:"Only superadmins can access this page", type:"error" });
      return;
    }
    loadUsers();
    loadMembers();
    loadBranches();
  }, [role]);

  const loadUsers = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from("profiles")
      .select("*, branch:branches(name)")
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Error loading users:", error);
      setToast({ msg:"Failed to load users", type:"error" });
    } else {
      setUsers(data || []);
    }
    setLoading(false);
  };

  const loadMembers = async () => {
    const { data } = await supabase.from("members").select("id, name, member_code").order("name");
    setMembers(data || []);
  };

  const loadBranches = async () => {
    const { data } = await supabase.from("branches").select("id, name").order("name");
    setBranches(data || []);
  };

  const filteredMembers = memberSearch.trim() 
    ? members.filter(m => 
        m.name.toLowerCase().includes(memberSearch.toLowerCase()) ||
        m.member_code.toLowerCase().includes(memberSearch.toLowerCase())
      )
    : members;

  const openInviteModal = () => {
    setSelected(null);
    setForm({ name:"", email:"", username:"", password:"", role:"member", branch_id:"", member_id:"" });
    setMemberSearch("");
    setModal("invite");
  };

  const openEditModal = (u) => {
    setSelected(u);
    setForm({
      name: u.name || "",
      email: u.email || "",
      username: u.username || "",
      password: "",
      role: u.role || "member",
      branch_id: u.branch_id || "",
      member_id: u.member_id || ""
    });
    setMemberSearch("");
    setModal("edit");
  };

  const saveUser = async () => {
    if (!form.name.trim() || !form.email.trim() || !form.username.trim()) {
      setToast({ msg:"Name, email, and username are required", type:"warn" });
      return;
    }

    setSaving(true);

    if (modal === "invite") {
      if (!form.password.trim()) {
        setToast({ msg:"Password is required for new users", type:"warn" });
        setSaving(false);
        return;
      }

      // Create auth user
      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email: form.email,
        password: form.password,
      });

      if (signUpError) {
        setToast({ msg:"Failed to create user: "+signUpError.message, type:"error" });
        setSaving(false);
        return;
      }

      // Create profile
      const { error: profileError } = await supabase.from("profiles").insert([{
        id: authData.user?.id,
        name: form.name,
        email: form.email,
        username: form.username,
        role: form.role,
        branch_id: form.branch_id || null,
        member_id: form.member_id || null,
      }]);

      if (profileError) {
        setToast({ msg:"Failed to create profile: "+profileError.message, type:"error" });
      } else {
        setToast({ msg:`Invited ${form.email}!`, type:"success" });
        setModal(null);
        loadUsers();
      }
    } else {
      // Edit existing user
      const { error } = await supabase.from("profiles").update({
        name: form.name,
        email: form.email,
        username: form.username,
        role: form.role,
        branch_id: form.branch_id || null,
        member_id: form.member_id || null,
      }).eq("id", selected.id);

      if (error) {
        setToast({ msg:"Failed to update user: "+error.message, type:"error" });
      } else {
        setToast({ msg:`${form.name} updated!`, type:"success" });
        setModal(null);
        loadUsers();
      }
    }
    setSaving(false);
  };

  const deleteUser = async (u) => {
    if (!confirm(`Delete "${u.name}"? This action cannot be undone.`)) return;

    const { error: profileError } = await supabase.from("profiles").delete().eq("id", u.id);
    
    if (profileError) {
      setToast({ msg:"Failed to delete user", type:"error" });
    } else {
      setToast({ msg:`${u.name} deleted`, type:"warn" });
      loadUsers();
    }
  };

  if (role !== "superadmin") {
    return (
      <div style={{ textAlign:"center", padding:"60px 20px", color:C.mist }}>
        <div style={{ fontSize:18, fontWeight:700, color:C.ink, marginBottom:8 }}>⛔ Access Denied</div>
        <div>Only superadmins can manage users.</div>
      </div>
    );
  }

  return (
    <div>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}

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
            ✓ Name auto-filled from member record. Giving, attendance, and QR will be linked to this member record.
          </div>
        )}
        {!form.member_id && (
          <Inp label="Full Name" value={form.name} onChange={v=>setForm({...form,name:v})} placeholder="Juan dela Cruz" required/>
        )}
        <Inp label="Email Address" value={form.email} onChange={v=>setForm({...form,email:v})} placeholder="juan@example.com" required/>
        <Inp label="Username" value={form.username} onChange={v=>setForm({...form,username:v})} placeholder="juandelacruz" required/>
        {modal==="invite" && (
          <Inp label="Password" type="password" value={form.password} onChange={v=>setForm({...form,password:v})} placeholder="At least 6 characters" required/>
        )}
        <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:14 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>Role</label>
          <select value={form.role} onChange={e=>setForm({...form,role:e.target.value})}
            style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md, fontSize:14, outline:"none", background:C.white, color:C.ink }}>
            <option value="member">Regular Member</option>
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
        <div style={{ display:"flex", gap:8 }}>
          <Btn label={saving?"Saving…":modal==="invite"?"Send Invite":"Save Changes"} onClick={saveUser} full/>
          <Btn label="Cancel" outline onClick={()=>setModal(null)}/>
        </div>
      </Modal>

      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:18, flexWrap:"wrap", gap:10 }}>
        <h2 style={{ margin:0, fontWeight:800, fontSize:20, color:C.ink }}>User Management</h2>
        <Btn label="+ Invite User" onClick={openInviteModal} color={C.green}/>
      </div>

      <div style={{ display:"flex", gap:8, marginBottom:18, flexWrap:"wrap" }}>
        <Pill label="All Users" active={tab==="users"} onClick={()=>setTab("users")}/>
        <Pill label="Activity Log" active={tab==="activity"} onClick={()=>setTab("activity")} color={C.violet2}/>
      </div>

      {/* ── USERS TAB ── */}
      {tab === "users" && (
        <>
          {loading ? (
            <div style={{ textAlign:"center", color:C.mist, padding:"40px" }}>Loading users…</div>
          ) : users.length === 0 ? (
            <Card><div style={{ textAlign:"center", color:C.mist }}>No users yet. Invite one above!</div></Card>
          ) : (
            <div style={{ display:"grid", gridTemplateColumns:mob?"1fr":"1fr", gap:12 }}>
              {users.map(u => (
                <Card key={u.id} style={{ padding:"14px 16px", display:"flex", alignItems:"center", gap:14, justifyContent:"space-between" }}>
                  <div style={{ display:"flex", alignItems:"center", gap:14, flex:1, minWidth:0 }}>
                    <Av name={u.name} size={40}/>
                    <div style={{ flex:1, minWidth:0 }}>
                      <div style={{ fontWeight:700, fontSize:14, color:C.ink }}>{u.name}</div>
                      <div style={{ fontSize:12, color:C.mist, whiteSpace:"nowrap", overflow:"hidden", textOverflow:"ellipsis" }}>
                        {u.email}
                      </div>
                      <div style={{ fontSize:11, color:C.slate, marginTop:2 }}>@{u.username}</div>
                    </div>
                  </div>

                  <div style={{ display:"flex", gap:8, alignItems:"center", flexShrink:0, flexWrap:"wrap", justifyContent:"flex-end" }}>
                    <Badge label={u.role.toUpperCase()} color={ROLE_COLORS[u.role]}/>
                    {u.branch?.name && (
                      <Badge label={u.branch.name.split("–")[0].trim()} color={C.slate}/>
                    )}
                    <button onClick={()=>openEditModal(u)}
                      style={{ border:"none", background:C.blue3, borderRadius:R.sm,
                        padding:"6px 12px", cursor:"pointer", color:C.blue,
                        fontWeight:600, fontSize:12, flexShrink:0 }}>
                      Edit
                    </button>
                    <button onClick={()=>deleteUser(u)}
                      style={{ border:"none", background:C.rose3, borderRadius:R.sm,
                        padding:"6px 12px", cursor:"pointer", color:C.rose2,
                        fontWeight:600, fontSize:12, flexShrink:0 }}>
                      Delete
                    </button>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </>
      )}

      {/* ── ACTIVITY LOG TAB ── */}
      {tab === "activity" && (
        <Card>
          <h3 style={{ margin:"0 0 16px", fontWeight:700, fontSize:14, color:C.ink }}>Recent Activity</h3>
          <div style={{ fontSize:12, color:C.mist, textAlign:"center", padding:"40px 0" }}>
            Activity log coming soon. Track user actions and audit trail here.
          </div>
        </Card>
      )}
    </div>
  );
}
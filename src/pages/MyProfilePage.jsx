import { useState, useEffect, useRef } from "react";
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
const SH = { sm:"0 2px 8px rgba(0,0,0,.07)", md:"0 4px 20px rgba(0,0,0,.09)" };

const Card = ({ children, style={} }) => (
  <div style={{ background:C.white, borderRadius:R.xl, boxShadow:SH.sm,
    border:`1px solid ${C.fog}`, padding:"18px 20px", ...style }}>
    {children}
  </div>
);

const Inp = ({ label, value, onChange, placeholder, type="text", required }) => (
  <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:14 }}>
    <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>
      {label}{required && <span style={{ color:C.rose2 }}> *</span>}
    </label>
    <input type={type} value={value} onChange={e=>onChange(e.target.value)}
      placeholder={placeholder}
      style={{ padding:"10px 14px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
        fontSize:14, outline:"none", color:C.ink }}/>
  </div>
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

const Av = ({ name, size=80, photoUrl }) => {
  const colors = [C.blue, C.violet2, C.rose2, C.green2, C.amber2, "#0EA5E9"];
  let h = 0; for (let c of (name||"?")) h += c.charCodeAt(0);
  if (photoUrl) return (
    <img src={photoUrl} alt={name}
      style={{ width:size, height:size, borderRadius:"50%", objectFit:"cover",
        border:`3px solid ${C.white}`, boxShadow:SH.md }}/>
  );
  return (
    <div style={{ width:size, height:size, borderRadius:"50%",
      background:colors[h%colors.length],
      display:"flex", alignItems:"center", justifyContent:"center",
      color:"#fff", fontWeight:700, fontSize:size*0.35, flexShrink:0,
      border:`3px solid ${C.white}`, boxShadow:SH.md }}>
      {(name||"?").split(" ").map(w=>w[0]).join("").slice(0,2).toUpperCase()}
    </div>
  );
};

export default function MyProfilePage({ role, user }) {
  const [member, setMember] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef(null);

  const [form, setForm] = useState({
    phone: "",
    email: "",
    address: "",
    photo_url: "",
  });

  useEffect(() => {
    if (!user?.memberId) return;
    loadMember();
  }, [user?.memberId]);

  const loadMember = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from("members")
      .select("*, branches(name)")
      .eq("id", user.memberId)
      .single();

    if (error) {
      setToast({ msg:"Failed to load profile", type:"error" });
    } else {
      setMember(data);
      setForm({
        phone: data.phone || "",
        email: data.email || "",
        address: data.address || "",
        photo_url: data.photo_url || "",
      });
    }
    setLoading(false);
  };

  const uploadPhoto = async (file) => {
    setUploading(true);
    const ext = file.name.split(".").pop().toLowerCase();
    const path = `member-photos/${user.memberId}-${Date.now()}.${ext}`;

    const { error: upErr } = await supabase.storage
      .from("theme")
      .upload(path, file, { upsert: true });

    if (upErr) {
      setToast({ msg:"Upload failed: " + upErr.message, type:"error" });
      setUploading(false);
      return;
    }

    const { data: { publicUrl } } = supabase.storage.from("theme").getPublicUrl(path);
    setForm(prev => ({ ...prev, photo_url: publicUrl }));
    setUploading(false);
    setToast({ msg:"Photo uploaded!", type:"success" });
  };

  const saveProfile = async () => {
    if (!user?.memberId) return;
    setSaving(true);

    const { error } = await supabase.from("members").update({
      phone: form.phone || null,
      email: form.email || null,
      address: form.address || null,
      photo_url: form.photo_url || null,
    }).eq("id", user.memberId);

    if (error) {
      setToast({ msg:"Failed: " + error.message, type:"error" });
    } else {
      setToast({ msg:"Profile updated!", type:"success" });
      await loadMember();
    }
    setSaving(false);
  };

  if (loading) return (
    <div style={{ textAlign:"center", padding:"60px 0", color:C.mist }}>Loading profile…</div>
  );

  if (!member) return (
    <div style={{ textAlign:"center", padding:"60px 0", color:C.mist }}>
      No member record linked to your account.
    </div>
  );

  return (
    <div style={{ maxWidth:560, margin:"0 auto" }}>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}

      <h2 style={{ margin:"0 0 18px", fontWeight:800, fontSize:20, color:C.ink }}>My Profile</h2>

      {/* Profile Header */}
      <Card style={{ marginBottom:16, textAlign:"center", padding:"28px 20px" }}>
        <div style={{ display:"flex", flexDirection:"column", alignItems:"center", gap:12 }}>
          <div style={{ position:"relative" }}>
            <Av name={member.name} size={90} photoUrl={form.photo_url}/>
            <button onClick={()=>fileRef.current?.click()}
              style={{ position:"absolute", bottom:0, right:0, width:28, height:28,
                borderRadius:"50%", background:C.blue, border:`2px solid ${C.white}`,
                display:"flex", alignItems:"center", justifyContent:"center",
                cursor:"pointer", fontSize:14 }}>
              📷
            </button>
            <input ref={fileRef} type="file" accept="image/*" style={{ display:"none" }}
              onChange={e=>{ if(e.target.files[0]) uploadPhoto(e.target.files[0]); }}/>
          </div>

          {uploading && (
            <div style={{ fontSize:12, color:C.mist }}>Uploading photo…</div>
          )}

          <div>
            <div style={{ fontWeight:800, fontSize:20, color:C.ink }}>{member.name}</div>
            <div style={{ fontSize:13, color:C.mist }}>{member.member_code}</div>
            <div style={{ fontSize:12, color:C.blue, fontWeight:600, marginTop:4 }}>
              {member.branches?.name || "—"}
            </div>
          </div>

          <div style={{ display:"flex", gap:16, marginTop:8 }}>
            <div style={{ textAlign:"center" }}>
              <div style={{ fontSize:20, fontWeight:800, color:C.ink }}>{member.points || 0}</div>
              <div style={{ fontSize:11, color:C.mist }}>Faith Points</div>
            </div>
            <div style={{ textAlign:"center" }}>
              <div style={{ fontSize:20, fontWeight:800, color:C.ink }}>{member.status || member.category || "—"}</div>
              <div style={{ fontSize:11, color:C.mist }}>Category</div>
            </div>
          </div>
        </div>
      </Card>

      {/* Read-only Info */}
      <Card style={{ marginBottom:16 }}>
        <h3 style={{ margin:"0 0 14px", fontWeight:700, fontSize:14, color:C.ink }}>Church Info</h3>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:12 }}>
          {[
            { label:"Member Code", value:member.member_code },
            { label:"Branch", value:member.branches?.name },
            { label:"Status", value:member.is_active ? "Active" : "Inactive" },
            { label:"Birthdate", value:member.birthdate ? new Date(member.birthdate).toLocaleDateString("en-PH", { month:"long", day:"numeric", year:"numeric" }) : "—" },
          ].map(({ label, value }) => (
            <div key={label}>
              <div style={{ fontSize:11, color:C.mist, fontWeight:600, marginBottom:2 }}>{label}</div>
              <div style={{ fontSize:13, color:C.ink, fontWeight:500 }}>{value || "—"}</div>
            </div>
          ))}
        </div>
      </Card>

      {/* Editable Info */}
      <Card>
        <h3 style={{ margin:"0 0 16px", fontWeight:700, fontSize:14, color:C.ink }}>Contact Information</h3>
        <Inp label="Phone Number" value={form.phone} onChange={v=>setForm({...form,phone:v})}
          placeholder="e.g. 09XX-XXX-XXXX" type="tel"/>
        <Inp label="Email Address" value={form.email} onChange={v=>setForm({...form,email:v})}
          placeholder="e.g. juan@example.com" type="email"/>
        <Inp label="Home Address" value={form.address} onChange={v=>setForm({...form,address:v})}
          placeholder="e.g. Brgy. Magsaysay, Pinamalayan"/>

        <button onClick={saveProfile} disabled={saving}
          style={{ width:"100%", padding:"12px", borderRadius:R.full,
            background: saving ? C.cloud : C.blue, color:C.white,
            border:"none", fontWeight:700, fontSize:14,
            cursor: saving ? "not-allowed" : "pointer" }}>
          {saving ? "Saving…" : "Save Changes"}
        </button>
      </Card>
    </div>
  );
}
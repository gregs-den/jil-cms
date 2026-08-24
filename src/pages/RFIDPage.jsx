import { useState, useEffect, useRef } from "react";
import { supabase } from "../lib/supabaseClient";
import { applyAttendanceCategoryRules } from "../lib/categoryTransfer";

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

const Pill = ({ label, active, onClick, color=C.blue }) => (
  <button onClick={onClick} style={{ padding:"6px 16px", borderRadius:R.full,
    border:`1.5px solid ${active?color:C.cloud}`, background:active?color:C.white,
    color:active?C.white:C.slate, fontWeight:600, fontSize:13, cursor:"pointer",
    transition:"all .15s", whiteSpace:"nowrap" }}>
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

// ════════════════════════════════════════════════════════════
//  RFID PAGE
// ════════════════════════════════════════════════════════════
export default function RFIDPage({ role, user }) {
  const mob = useIsMobile();
  const [tab, setTab] = useState("scanner");
  const [toast, setToast] = useState(null);

  const isAdmin = role === "admin" || role === "superadmin";

  return (
    <div>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}

      <h2 style={{ margin:"0 0 16px", fontWeight:800, fontSize:20, color:C.ink }}>RFID</h2>

      <div style={{ display:"flex", gap:8, marginBottom:18, flexWrap:"wrap" }}>
        <Pill label="📡 Scanner" active={tab==="scanner"} onClick={()=>setTab("scanner")} color={C.green}/>
        {isAdmin && (
          <Pill label="🔗 Register Cards" active={tab==="register"} onClick={()=>setTab("register")} color={C.blue}/>
        )}
        {isAdmin && (
          <Pill label="📋 Cards List" active={tab==="cards"} onClick={()=>setTab("cards")} color={C.violet2}/>
        )}
      </div>

      {tab === "scanner" && <RFIDScanner user={user} role={role} setToast={setToast}/>}
      {tab === "register" && isAdmin && <RFIDRegister setToast={setToast}/>}
      {tab === "cards" && isAdmin && <RFIDCardsList setToast={setToast}/>}
    </div>
  );
}

// ════════════════════════════════════════════════════════════
//  RFID SCANNER — tap card to mark attendance
// ════════════════════════════════════════════════════════════
function RFIDScanner({ user, role, setToast }) {
  const inputRef = useRef(null);
  const [uid, setUid] = useState("");
  const [scanning, setScanning] = useState(true);
  const [lastScan, setLastScan] = useState(null);
  const [recentScans, setRecentScans] = useState([]);
  const [loading, setLoading] = useState(false);

  // Auto-focus the hidden input
  useEffect(() => {
    if (scanning) inputRef.current?.focus();
  }, [scanning]);

  // Keep input focused when window is clicked
  const handleContainerClick = () => {
    inputRef.current?.focus();
  };

  const handleScan = async (cardUid) => {
    if (!cardUid.trim() || loading) return;
    setLoading(true);

    // Look up card
    const { data: card, error: cardError } = await supabase
      .from("rfid_cards")
      .select("*, member:members(id, name, branch_id, branches(name))")
      .eq("card_uid", cardUid.trim())
      .eq("is_active", true)
      .maybeSingle();

    if (cardError || !card) {
      setLastScan({ success: false, message: "Card not registered", uid: cardUid });
      setToast({ msg: "⚠️ Card not registered!", type: "warn" });
      setUid("");
      setLoading(false);
      return;
    }

    const member = card.member;
    const today = new Date().toISOString().split("T")[0];

    // Check if already marked today
    const { data: existing } = await supabase
      .from("attendance")
      .select("id")
      .eq("member_id", member.id)
      .eq("service_date", today)
      .maybeSingle();

    if (existing) {
      setLastScan({ success: true, already: true, member, uid: cardUid });
      setToast({ msg: `${member.name} already marked today!`, type: "warn" });
      setUid("");
      setLoading(false);
      return;
    }

    // Mark attendance
    const { error: attError } = await supabase.from("attendance").insert([{
      member_id: member.id,
      service_date: today,
      present: true,
    }]);

    if (attError) {
      setLastScan({ success: false, message: attError.message, uid: cardUid });
      setToast({ msg: "Failed to mark attendance", type: "error" });
    } else {
      const scan = { success: true, already: false, member, uid: cardUid, time: new Date() };
      setLastScan(scan);
      setRecentScans(prev => [scan, ...prev].slice(0, 10));
      setToast({ msg: `✅ ${member.name} marked present!`, type: "success" });
      applyAttendanceCategoryRules(member.id);
    }

    setUid("");
    setLoading(false);
    inputRef.current?.focus();
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter") {
      handleScan(uid);
    }
  };

  return (
    <div onClick={handleContainerClick}>
      {/* Hidden input that captures RFID reader input */}
      <input
        ref={inputRef}
        value={uid}
        onChange={e => setUid(e.target.value)}
        onKeyDown={handleKeyDown}
        style={{ position:"absolute", opacity:0, width:0, height:0 }}
        autoFocus
      />

      {/* Scanner Status */}
      <Card style={{ marginBottom:16, textAlign:"center", padding:"40px 20px",
        background: scanning ? `linear-gradient(135deg, ${C.green}15, ${C.green2}08)` : C.fog,
        borderLeft: `4px solid ${scanning ? C.green : C.slate}`,
        cursor:"pointer" }}>
        <div style={{ fontSize:64, marginBottom:12 }}>
          {loading ? "⏳" : scanning ? "📡" : "⏸️"}
        </div>
        <div style={{ fontWeight:800, fontSize:20, color: scanning ? C.green : C.slate, marginBottom:8 }}>
          {loading ? "Processing..." : scanning ? "Ready to Scan" : "Paused"}
        </div>
        <div style={{ fontSize:13, color:C.mist, marginBottom:20 }}>
          {scanning ? "Tap an RFID card or fob to mark attendance" : "Click to resume scanning"}
        </div>
        <button onClick={(e) => { e.stopPropagation(); setScanning(v=>!v); }}
          style={{ padding:"10px 24px", borderRadius:R.full, border:"none",
            background: scanning ? C.rose2 : C.green, color:C.white,
            fontWeight:700, fontSize:14, cursor:"pointer" }}>
          {scanning ? "⏸ Pause" : "▶ Resume"}
        </button>
      </Card>

      {/* Last Scan Result */}
      {lastScan && (
        <Card style={{ marginBottom:16,
          borderLeft: `4px solid ${lastScan.success ? (lastScan.already ? C.amber : C.green) : C.rose2}`,
          background: lastScan.success ? (lastScan.already ? C.amber3 : C.green3) : C.rose3 }}>
          <div style={{ display:"flex", alignItems:"center", gap:14 }}>
            <div style={{ fontSize:36 }}>
              {lastScan.success ? (lastScan.already ? "⚠️" : "✅") : "❌"}
            </div>
            <div>
              <div style={{ fontWeight:700, fontSize:15, color:C.ink }}>
                {lastScan.success
                  ? lastScan.already
                    ? `${lastScan.member.name} already marked today`
                    : `${lastScan.member.name} marked present!`
                  : lastScan.message || "Unknown card"
                }
              </div>
              {lastScan.success && (
                <div style={{ fontSize:12, color:C.slate }}>
                  {lastScan.member.branches?.name} · {new Date().toLocaleTimeString()}
                </div>
              )}
              <div style={{ fontSize:11, color:C.mist, marginTop:2 }}>
                Card UID: {lastScan.uid}
              </div>
            </div>
          </div>
        </Card>
      )}

      {/* Recent Scans */}
      {recentScans.length > 0 && (
        <Card>
          <h3 style={{ margin:"0 0 14px", fontWeight:700, fontSize:14, color:C.ink }}>
            Recent Scans ({recentScans.length})
          </h3>
          <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
            {recentScans.map((scan, i) => (
              <div key={i} style={{ display:"flex", alignItems:"center", gap:12,
                padding:"10px 12px", background:C.fog, borderRadius:R.lg }}>
                <Av name={scan.member.name} size={32}/>
                <div style={{ flex:1 }}>
                  <div style={{ fontWeight:600, fontSize:13, color:C.ink }}>{scan.member.name}</div>
                  <div style={{ fontSize:11, color:C.mist }}>{scan.time?.toLocaleTimeString()}</div>
                </div>
                <span style={{ fontSize:11, color:C.green, fontWeight:600 }}>✓ Present</span>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════
//  RFID REGISTER — assign card to member
// ════════════════════════════════════════════════════════════
function RFIDRegister({ setToast }) {
  const inputRef = useRef(null);
  const [members, setMembers] = useState([]);
  const [memberSearch, setMemberSearch] = useState("");
  const [selectedMember, setSelectedMember] = useState(null);
  const [cardUid, setCardUid] = useState("");
  const [waitingForCard, setWaitingForCard] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    supabase.from("members").select("id, name, member_code").order("name")
      .then(({ data }) => { if (data) setMembers(data); });
  }, []);

  useEffect(() => {
    if (waitingForCard) inputRef.current?.focus();
  }, [waitingForCard]);

  const filteredMembers = memberSearch.trim()
    ? members.filter(m =>
        m.name.toLowerCase().includes(memberSearch.toLowerCase()) ||
        m.member_code?.toLowerCase().includes(memberSearch.toLowerCase())
      )
    : members;

  const handleCardScan = (e) => {
    if (e.key === "Enter" && cardUid.trim()) {
      setWaitingForCard(false);
    }
  };

  const registerCard = async () => {
    if (!selectedMember || !cardUid.trim()) return;
    setSaving(true);

    // Check if card already registered
    const { data: existing } = await supabase
      .from("rfid_cards")
      .select("id, member:members(name)")
      .eq("card_uid", cardUid.trim())
      .maybeSingle();

    if (existing) {
      setToast({ msg: `Card already registered to ${existing.member?.name}`, type: "warn" });
      setSaving(false);
      return;
    }

    // Check if member already has a card
    const { data: memberCard } = await supabase
      .from("rfid_cards")
      .select("id")
      .eq("member_id", selectedMember.id)
      .eq("is_active", true)
      .maybeSingle();

    if (memberCard) {
      // Deactivate old card
      await supabase.from("rfid_cards").update({ is_active: false }).eq("id", memberCard.id);
    }

    const { error } = await supabase.from("rfid_cards").insert([{
      member_id: selectedMember.id,
      card_uid: cardUid.trim(),
      is_active: true,
    }]);

    if (error) {
      setToast({ msg: "Failed: " + error.message, type: "error" });
    } else {
      setToast({ msg: `Card registered to ${selectedMember.name}!`, type: "success" });
      setSelectedMember(null);
      setCardUid("");
      setMemberSearch("");
    }
    setSaving(false);
  };

  return (
    <div style={{ maxWidth:520, margin:"0 auto" }}>
      <Card>
        <h3 style={{ margin:"0 0 16px", fontWeight:700, fontSize:14, color:C.ink }}>
          Register RFID Card
        </h3>

        {/* Step 1: Select Member */}
        <div style={{ marginBottom:16 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate, display:"block", marginBottom:6 }}>
            Step 1: Select Member
          </label>
          <input value={memberSearch} onChange={e=>setMemberSearch(e.target.value)}
            placeholder="Search by name or code..."
            style={{ width:"100%", padding:"10px 14px", border:`1.5px solid ${C.fog}`,
              borderRadius:R.md, fontSize:14, outline:"none", color:C.ink,
              marginBottom:8, boxSizing:"border-box" }}/>
          <select value={selectedMember?.id || ""} onChange={e=>{
              const m = members.find(x=>x.id===e.target.value);
              setSelectedMember(m||null);
            }}
            style={{ width:"100%", padding:"10px 14px", border:`1.5px solid ${C.fog}`,
              borderRadius:R.md, fontSize:14, outline:"none", background:C.white,
              color:C.ink, boxSizing:"border-box" }}>
            <option value="">— Select Member —</option>
            {filteredMembers.map(m=>(
              <option key={m.id} value={m.id}>{m.name} ({m.member_code})</option>
            ))}
          </select>
        </div>

        {selectedMember && (
          <div style={{ background:C.green3, borderRadius:R.md, padding:"10px 14px",
            fontSize:12, color:C.green, marginBottom:16, fontWeight:600 }}>
            ✓ Selected: {selectedMember.name}
          </div>
        )}

        {/* Step 2: Scan Card */}
        <div style={{ marginBottom:16 }}>
          <label style={{ fontSize:12, fontWeight:600, color:C.slate, display:"block", marginBottom:6 }}>
            Step 2: Scan RFID Card
          </label>
          {!waitingForCard ? (
            <button onClick={()=>{ setCardUid(""); setWaitingForCard(true); }}
              disabled={!selectedMember}
              style={{ width:"100%", padding:"14px", borderRadius:R.lg,
                border:`2px dashed ${selectedMember ? C.blue : C.cloud}`,
                background: selectedMember ? C.blue3 : C.fog,
                color: selectedMember ? C.blue : C.mist,
                fontWeight:700, fontSize:14, cursor: selectedMember ? "pointer" : "not-allowed" }}>
              📡 Click to Scan Card
            </button>
          ) : (
            <div style={{ position:"relative" }}>
              <input ref={inputRef} value={cardUid}
                onChange={e=>setCardUid(e.target.value)}
                onKeyDown={handleCardScan}
                placeholder="Waiting for card tap... (press Enter when done)"
                style={{ width:"100%", padding:"14px", border:`2px solid ${C.green}`,
                  borderRadius:R.lg, fontSize:14, outline:"none", color:C.ink,
                  background:C.green3, boxSizing:"border-box",
                  animation:"pulse 1s infinite" }}
                autoFocus/>
              <div style={{ fontSize:11, color:C.green, marginTop:4, fontWeight:600 }}>
                📡 Tap your RFID card now...
              </div>
            </div>
          )}
        </div>

        {cardUid && !waitingForCard && (
          <div style={{ background:C.blue3, borderRadius:R.md, padding:"10px 14px",
            fontSize:12, color:C.blue, marginBottom:16, fontWeight:600 }}>
            ✓ Card UID: {cardUid}
          </div>
        )}

        <button onClick={registerCard}
          disabled={!selectedMember || !cardUid.trim() || saving}
          style={{ width:"100%", padding:"12px", borderRadius:R.full,
            background: (!selectedMember || !cardUid.trim() || saving) ? C.cloud : C.blue,
            color:C.white, border:"none", fontWeight:700, fontSize:14,
            cursor: (!selectedMember || !cardUid.trim() || saving) ? "not-allowed" : "pointer" }}>
          {saving ? "Registering..." : "Register Card"}
        </button>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════════
//  RFID CARDS LIST
// ════════════════════════════════════════════════════════════
function RFIDCardsList({ setToast }) {
  const [cards, setCards] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    loadCards();
  }, []);

  const loadCards = async () => {
    setLoading(true);
    const { data } = await supabase
      .from("rfid_cards")
      .select("*, member:members(id, name, member_code)")
      .order("registered_at", { ascending: false });
    if (data) setCards(data);
    setLoading(false);
  };

  const deactivateCard = async (id, memberName) => {
    const { error } = await supabase.from("rfid_cards").update({ is_active: false }).eq("id", id);
    if (error) {
      setToast({ msg: "Failed to deactivate", type: "error" });
    } else {
      setToast({ msg: `Card for ${memberName} deactivated`, type: "warn" });
      loadCards();
    }
  };

  const deleteCard = async (id, memberName) => {
    if (!confirm(`Delete card for ${memberName}?`)) return;
    const { error } = await supabase.from("rfid_cards").delete().eq("id", id);
    if (error) {
      setToast({ msg: "Failed to delete", type: "error" });
    } else {
      setToast({ msg: `Card deleted`, type: "warn" });
      loadCards();
    }
  };

  const filtered = search.trim()
    ? cards.filter(c => c.member?.name?.toLowerCase().includes(search.toLowerCase()) ||
        c.card_uid.toLowerCase().includes(search.toLowerCase()))
    : cards;

  return (
    <div>
      <input value={search} onChange={e=>setSearch(e.target.value)}
        placeholder="Search by member name or card UID..."
        style={{ width:"100%", padding:"10px 14px", border:`1.5px solid ${C.fog}`,
          borderRadius:R.md, fontSize:14, outline:"none", color:C.ink,
          marginBottom:16, boxSizing:"border-box" }}/>

      {loading ? (
        <div style={{ textAlign:"center", color:C.mist, padding:40 }}>Loading cards...</div>
      ) : filtered.length === 0 ? (
        <Card><div style={{ textAlign:"center", color:C.mist }}>No cards registered yet.</div></Card>
      ) : (
        <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
          {filtered.map(c => (
            <Card key={c.id} style={{ display:"flex", alignItems:"center", gap:14,
              justifyContent:"space-between", padding:"12px 16px",
              borderLeft:`3px solid ${c.is_active ? C.green : C.slate}` }}>
              <div style={{ display:"flex", alignItems:"center", gap:12, flex:1, minWidth:0 }}>
                <Av name={c.member?.name||"?"} size={36}/>
                <div>
                  <div style={{ fontWeight:700, fontSize:13, color:C.ink }}>{c.member?.name||"Unknown"}</div>
                  <div style={{ fontSize:11, color:C.mist }}>{c.member?.member_code}</div>
                  <div style={{ fontSize:11, color:C.slate, fontFamily:"monospace" }}>{c.card_uid}</div>
                </div>
              </div>
              <div style={{ display:"flex", gap:6, flexShrink:0, flexWrap:"wrap", justifyContent:"flex-end" }}>
                <span style={{ fontSize:11, fontWeight:600,
                  color: c.is_active ? C.green : C.slate,
                  background: c.is_active ? C.green3 : C.fog,
                  padding:"3px 10px", borderRadius:R.full }}>
                  {c.is_active ? "Active" : "Inactive"}
                </span>
                {c.is_active && (
                  <button onClick={()=>deactivateCard(c.id, c.member?.name)}
                    style={{ border:"none", background:C.amber3, borderRadius:R.sm,
                      padding:"5px 10px", cursor:"pointer", color:C.amber,
                      fontWeight:600, fontSize:11 }}>
                    Deactivate
                  </button>
                )}
                <button onClick={()=>deleteCard(c.id, c.member?.name)}
                  style={{ border:"none", background:C.rose3, borderRadius:R.sm,
                    padding:"5px 10px", cursor:"pointer", color:C.rose2,
                    fontWeight:600, fontSize:11 }}>
                  Delete
                </button>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
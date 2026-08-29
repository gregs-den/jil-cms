import { useState, useEffect } from "react";
import { supabase } from "../lib/supabaseClient";
import * as XLSX from "xlsx";

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

const Pill = ({ label, active, onClick, color=C.blue }) => (
  <button onClick={onClick} style={{ padding:"6px 16px", borderRadius:R.full,
    border:`1.5px solid ${active?color:C.cloud}`, background:active?color:C.white,
    color:active?C.white:C.slate, fontWeight:600, fontSize:13, cursor:"pointer",
    transition:"all .15s", whiteSpace:"nowrap" }}>
    {label}
  </button>
);

const Inp = ({ label, value, onChange, type="text", options }) => (
  <div style={{ display:"flex", flexDirection:"column", gap:5 }}>
    <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>{label}</label>
    {options ? (
      <select value={value} onChange={e=>onChange(e.target.value)}
        style={{ padding:"9px 12px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
          fontSize:13, outline:"none", background:C.white, color:C.ink }}>
        {options.map(o=><option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    ) : (
      <input type={type} value={value} onChange={e=>onChange(e.target.value)}
        style={{ padding:"9px 12px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
          fontSize:13, outline:"none", color:C.ink }}/>
    )}
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

// ── PDF Export (using window.jsPDF loaded via CDN) ──────────────────
const loadJsPDF = () => new Promise((resolve) => {
  if (window.jspdf) { resolve(window.jspdf.jsPDF); return; }
  const script = document.createElement("script");
  script.src = "https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js";
  script.onload = () => {
    const script2 = document.createElement("script");
    script2.src = "https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.8.2/jspdf.plugin.autotable.min.js";
    script2.onload = () => resolve(window.jspdf.jsPDF);
    document.head.appendChild(script2);
  };
  document.head.appendChild(script);
});

const exportPDF = async (title, columns, rows, filename) => {
  const jsPDF = await loadJsPDF();
  const doc = new jsPDF({ orientation: rows[0]?.length > 5 ? "landscape" : "portrait" });

  doc.setFontSize(16);
  doc.setFont("helvetica", "bold");
  doc.text(title, 14, 18);

  doc.setFontSize(9);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(100);
  doc.text(`Generated: ${new Date().toLocaleString("en-PH")}`, 14, 26);
  doc.text(`Total records: ${rows.length}`, 14, 32);

  doc.autoTable({
    head: [columns],
    body: rows,
    startY: 38,
    styles: { fontSize: 9, cellPadding: 3 },
    headStyles: { fillColor: [29, 78, 216], textColor: 255, fontStyle:"bold" },
    alternateRowStyles: { fillColor: [248, 250, 252] },
    margin: { left: 14, right: 14 },
  });

  doc.save(`${filename}.pdf`);
};

// ── Excel Export ─────────────────────────────────────────────────────
const exportExcel = (title, columns, rows, filename) => {
  const ws = XLSX.utils.aoa_to_sheet([
    [title],
    [`Generated: ${new Date().toLocaleString("en-PH")}`],
    [`Total records: ${rows.length}`],
    [],
    columns,
    ...rows,
  ]);
  ws["!cols"] = columns.map(() => ({ wch: 20 }));
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, "Report");
  XLSX.writeFile(wb, `${filename}.xlsx`);
};

// ════════════════════════════════════════════════════════════
//  REPORTS PAGE
// ════════════════════════════════════════════════════════════
export default function ReportsPage({ role, user }) {
  const [tab, setTab] = useState("attendance");
  const [branches, setBranches] = useState([]);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    supabase.from("branches").select("id, name").order("name")
      .then(({ data }) => { if (data) setBranches(data); });
  }, []);

  const isSuperAdmin = role === "superadmin";

  return (
    <div>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}

      <h2 style={{ margin:"0 0 16px", fontWeight:800, fontSize:20, color:C.ink }}>Reports</h2>

      <div style={{ display:"flex", gap:8, marginBottom:18, flexWrap:"wrap" }}>
        <Pill label="📅 Attendance" active={tab==="attendance"} onClick={()=>setTab("attendance")} color={C.blue}/>
        <Pill label="💰 Finance" active={tab==="finance"} onClick={()=>setTab("finance")} color={C.green}/>
        <Pill label="👥 Members" active={tab==="members"} onClick={()=>setTab("members")} color={C.violet2}/>
        <Pill label="📈 Growth" active={tab==="growth"} onClick={()=>setTab("growth")} color={C.amber2}/>
      </div>

      {tab === "attendance" && (
        <AttendanceReport branches={branches} isSuperAdmin={isSuperAdmin} user={user} setToast={setToast}/>
      )}
      {tab === "finance" && (
        <FinanceReport branches={branches} isSuperAdmin={isSuperAdmin} user={user} setToast={setToast}/>
      )}
      {tab === "members" && (
        <MembersReport branches={branches} isSuperAdmin={isSuperAdmin} user={user} setToast={setToast}/>
      )}
      {tab === "growth" && (
        <MembershipGrowthReport setToast={setToast}/>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════
//  ATTENDANCE REPORT
// ════════════════════════════════════════════════════════════
function AttendanceReport({ branches, isSuperAdmin, user, setToast }) {
  const [dateFrom, setDateFrom] = useState(() => {
    const d = new Date(); d.setDate(1);
    return d.toISOString().split("T")[0];
  });
  const [dateTo, setDateTo] = useState(() => new Date().toISOString().split("T")[0]);
  const [branchId, setBranchId] = useState("");
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [generated, setGenerated] = useState(false);

  const generate = async () => {
    setLoading(true);
    let q = supabase.from("attendance")
      .select("*, member:members(name, member_code, branch_id, branches(name))")
      .gte("date", dateFrom)
      .lte("date", dateTo)
      .order("date", { ascending: false });

    const { data: rows, error } = await q;
    if (error) { setToast({ msg:"Failed: " + error.message, type:"error" }); setLoading(false); return; }

    let filtered = rows || [];
    if (!isSuperAdmin && user?.branchId) {
      filtered = filtered.filter(r => r.member?.branch_id === user.branchId);
    } else if (branchId) {
      filtered = filtered.filter(r => r.member?.branch_id === branchId);
    }

    setData(filtered);
    setGenerated(true);
    setLoading(false);
  };

  const columns = ["Date", "Member Name", "Member Code", "Branch", "Status", "Method"];
  const rows = data.map(r => [
    r.date,
    r.member?.name || "—",
    r.member?.member_code || "—",
    r.member?.branches?.name || "—",
    r.status || "present",
    r.method || "manual",
  ]);

  const title = `Attendance Report (${dateFrom} to ${dateTo})`;

  return (
    <div>
      <Card style={{ marginBottom:16 }}>
        <h3 style={{ margin:"0 0 16px", fontWeight:700, fontSize:14, color:C.ink }}>Filter</h3>
        <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fit, minmax(180px,1fr))", gap:12, marginBottom:16 }}>
          <Inp label="Date From" type="date" value={dateFrom} onChange={setDateFrom}/>
          <Inp label="Date To" type="date" value={dateTo} onChange={setDateTo}/>
          {isSuperAdmin && (
            <Inp label="Branch" value={branchId} onChange={setBranchId}
              options={[{value:"",label:"All Branches"}, ...branches.map(b=>({value:b.id,label:b.name}))]}/>
          )}
        </div>
        <button onClick={generate} disabled={loading}
          style={{ padding:"10px 24px", borderRadius:R.full, background:C.blue, color:C.white,
            border:"none", fontWeight:700, fontSize:14, cursor:loading?"not-allowed":"pointer" }}>
          {loading ? "Generating…" : "Generate Report"}
        </button>
      </Card>

      {generated && (
        <Card>
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16, flexWrap:"wrap", gap:10 }}>
            <div>
              <div style={{ fontWeight:700, fontSize:15, color:C.ink }}>{title}</div>
              <div style={{ fontSize:12, color:C.mist }}>{data.length} records found</div>
            </div>
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>exportExcel(title, columns, rows, "attendance-report")}
                style={{ padding:"8px 16px", borderRadius:R.full, background:C.green3, color:C.green,
                  border:`1.5px solid ${C.green}`, fontWeight:600, fontSize:12, cursor:"pointer" }}>
                📊 Export Excel
              </button>
              <button onClick={()=>exportPDF(title, columns, rows, "attendance-report")}
                style={{ padding:"8px 16px", borderRadius:R.full, background:C.rose3, color:C.rose,
                  border:`1.5px solid ${C.rose}`, fontWeight:600, fontSize:12, cursor:"pointer" }}>
                📄 Export PDF
              </button>
            </div>
          </div>

          {data.length === 0 ? (
            <div style={{ textAlign:"center", padding:"28px 0", color:C.mist }}>No records found for this filter.</div>
          ) : (
            <div style={{ overflowX:"auto" }}>
              <table style={{ width:"100%", borderCollapse:"collapse", fontSize:13 }}>
                <thead>
                  <tr style={{ background:C.fog }}>
                    {columns.map(h=>(
                      <th key={h} style={{ textAlign:"left", padding:"10px 14px", color:C.slate,
                        fontWeight:600, fontSize:11, textTransform:"uppercase", letterSpacing:.4, whiteSpace:"nowrap" }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {data.map((r,i)=>(
                    <tr key={r.id||i} style={{ borderTop:`1px solid ${C.fog}` }}>
                      <td style={{ padding:"10px 14px", color:C.ink }}>{r.date}</td>
                      <td style={{ padding:"10px 14px", fontWeight:600, color:C.ink }}>{r.member?.name||"—"}</td>
                      <td style={{ padding:"10px 14px", color:C.mist, fontSize:12 }}>{r.member?.member_code||"—"}</td>
                      <td style={{ padding:"10px 14px", color:C.slate, fontSize:12 }}>{r.member?.branches?.name||"—"}</td>
                      <td style={{ padding:"10px 14px" }}>
                        <span style={{ background:C.green3, color:C.green, padding:"2px 10px", borderRadius:R.full, fontSize:11, fontWeight:700 }}>
                          {r.status||"present"}
                        </span>
                      </td>
                      <td style={{ padding:"10px 14px", color:C.mist, fontSize:12 }}>{r.method||"manual"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════
//  FINANCE REPORT
// ════════════════════════════════════════════════════════════
function FinanceReport({ branches, isSuperAdmin, user, setToast }) {
  const [dateFrom, setDateFrom] = useState(() => {
    const d = new Date(); d.setDate(1);
    return d.toISOString().split("T")[0];
  });
  const [dateTo, setDateTo] = useState(() => new Date().toISOString().split("T")[0]);
  const [branchId, setBranchId] = useState("");
  const [type, setType] = useState("");
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [generated, setGenerated] = useState(false);

  const TYPES = ["Tithes","Offering","Pledges","Mission","Support","iCare","First Fruit"];

  const generate = async () => {
    setLoading(true);
    let q = supabase.from("giving")
      .select("*, member:members(name, member_code, branch_id, branches(name))")
      .gte("date", dateFrom)
      .lte("date", dateTo)
      .order("date", { ascending: false });

    if (type) q = q.eq("type", type);

    const { data: rows, error } = await q;
    if (error) { setToast({ msg:"Failed: " + error.message, type:"error" }); setLoading(false); return; }

    let filtered = rows || [];
    if (!isSuperAdmin && user?.branchId) {
      filtered = filtered.filter(r => r.member?.branch_id === user.branchId);
    } else if (branchId) {
      filtered = filtered.filter(r => r.member?.branch_id === branchId);
    }

    setData(filtered);
    setGenerated(true);
    setLoading(false);
  };

  const grandTotal = data.reduce((a,r)=>a+(r.amount||0), 0);
  const columns = ["Date", "Member Name", "Member Code", "Branch", "Type", "Amount"];
  const rows = data.map(r => [
    r.date,
    r.member?.name || "—",
    r.member?.member_code || "—",
    r.member?.branches?.name || "—",
    r.type || "—",
    `₱${(r.amount||0).toLocaleString()}`,
  ]);

  const title = `Finance Report (${dateFrom} to ${dateTo})`;

  // Breakdown by type
  const breakdown = TYPES.map(t => ({
    type: t,
    total: data.filter(r=>r.type===t).reduce((a,r)=>a+(r.amount||0),0),
    count: data.filter(r=>r.type===t).length,
  })).filter(b=>b.total>0);

  return (
    <div>
      <Card style={{ marginBottom:16 }}>
        <h3 style={{ margin:"0 0 16px", fontWeight:700, fontSize:14, color:C.ink }}>Filter</h3>
        <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fit, minmax(180px,1fr))", gap:12, marginBottom:16 }}>
          <Inp label="Date From" type="date" value={dateFrom} onChange={setDateFrom}/>
          <Inp label="Date To" type="date" value={dateTo} onChange={setDateTo}/>
          <Inp label="Giving Type" value={type} onChange={setType}
            options={[{value:"",label:"All Types"}, ...TYPES.map(t=>({value:t,label:t}))]}/>
          {isSuperAdmin && (
            <Inp label="Branch" value={branchId} onChange={setBranchId}
              options={[{value:"",label:"All Branches"}, ...branches.map(b=>({value:b.id,label:b.name}))]}/>
          )}
        </div>
        <button onClick={generate} disabled={loading}
          style={{ padding:"10px 24px", borderRadius:R.full, background:C.green, color:C.white,
            border:"none", fontWeight:700, fontSize:14, cursor:loading?"not-allowed":"pointer" }}>
          {loading ? "Generating…" : "Generate Report"}
        </button>
      </Card>

      {generated && (
        <>
          {/* Summary Cards */}
          <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fit,minmax(140px,1fr))", gap:12, marginBottom:16 }}>
            <Card style={{ borderTop:`3px solid ${C.green}`, padding:"14px 16px" }}>
              <div style={{ fontSize:11, color:C.mist, fontWeight:600, marginBottom:4 }}>TOTAL COLLECTED</div>
              <div style={{ fontSize:22, fontWeight:800, color:C.ink }}>₱{grandTotal.toLocaleString()}</div>
            </Card>
            <Card style={{ borderTop:`3px solid ${C.blue}`, padding:"14px 16px" }}>
              <div style={{ fontSize:11, color:C.mist, fontWeight:600, marginBottom:4 }}>TRANSACTIONS</div>
              <div style={{ fontSize:22, fontWeight:800, color:C.ink }}>{data.length}</div>
            </Card>
            <Card style={{ borderTop:`3px solid ${C.violet2}`, padding:"14px 16px" }}>
              <div style={{ fontSize:11, color:C.mist, fontWeight:600, marginBottom:4 }}>CONTRIBUTORS</div>
              <div style={{ fontSize:22, fontWeight:800, color:C.ink }}>{new Set(data.map(r=>r.member_id)).size}</div>
            </Card>
          </div>

          {/* Breakdown */}
          {breakdown.length > 0 && (
            <Card style={{ marginBottom:16 }}>
              <h3 style={{ margin:"0 0 12px", fontWeight:700, fontSize:13, color:C.ink }}>Breakdown by Type</h3>
              <div style={{ display:"flex", flexDirection:"column", gap:8 }}>
                {breakdown.map(b=>(
                  <div key={b.type} style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
                    <span style={{ fontSize:13, color:C.ink }}>{b.type}</span>
                    <div style={{ display:"flex", gap:12, alignItems:"center" }}>
                      <span style={{ fontSize:11, color:C.mist }}>{b.count} tx</span>
                      <span style={{ fontSize:13, fontWeight:700, color:C.green }}>₱{b.total.toLocaleString()}</span>
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          )}

          <Card>
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16, flexWrap:"wrap", gap:10 }}>
              <div>
                <div style={{ fontWeight:700, fontSize:15, color:C.ink }}>{title}</div>
                <div style={{ fontSize:12, color:C.mist }}>{data.length} records · Total: ₱{grandTotal.toLocaleString()}</div>
              </div>
              <div style={{ display:"flex", gap:8 }}>
                <button onClick={()=>exportExcel(title, columns, rows, "finance-report")}
                  style={{ padding:"8px 16px", borderRadius:R.full, background:C.green3, color:C.green,
                    border:`1.5px solid ${C.green}`, fontWeight:600, fontSize:12, cursor:"pointer" }}>
                  📊 Export Excel
                </button>
                <button onClick={()=>exportPDF(title, columns, rows, "finance-report")}
                  style={{ padding:"8px 16px", borderRadius:R.full, background:C.rose3, color:C.rose,
                    border:`1.5px solid ${C.rose}`, fontWeight:600, fontSize:12, cursor:"pointer" }}>
                  📄 Export PDF
                </button>
              </div>
            </div>

            {data.length === 0 ? (
              <div style={{ textAlign:"center", padding:"28px 0", color:C.mist }}>No records found.</div>
            ) : (
              <div style={{ overflowX:"auto" }}>
                <table style={{ width:"100%", borderCollapse:"collapse", fontSize:13 }}>
                  <thead>
                    <tr style={{ background:C.fog }}>
                      {columns.map(h=>(
                        <th key={h} style={{ textAlign:"left", padding:"10px 14px", color:C.slate,
                          fontWeight:600, fontSize:11, textTransform:"uppercase", letterSpacing:.4, whiteSpace:"nowrap" }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {data.map((r,i)=>(
                      <tr key={r.id||i} style={{ borderTop:`1px solid ${C.fog}` }}>
                        <td style={{ padding:"10px 14px", color:C.ink }}>{r.date}</td>
                        <td style={{ padding:"10px 14px", fontWeight:600, color:C.ink }}>{r.member?.name||"—"}</td>
                        <td style={{ padding:"10px 14px", color:C.mist, fontSize:12 }}>{r.member?.member_code||"—"}</td>
                        <td style={{ padding:"10px 14px", color:C.slate, fontSize:12 }}>{r.member?.branches?.name||"—"}</td>
                        <td style={{ padding:"10px 14px" }}>
                          <span style={{ background:C.blue3, color:C.blue, padding:"2px 10px", borderRadius:R.full, fontSize:11, fontWeight:700 }}>
                            {r.type}
                          </span>
                        </td>
                        <td style={{ padding:"10px 14px", fontWeight:700, color:C.green }}>₱{(r.amount||0).toLocaleString()}</td>
                      </tr>
                    ))}
                    <tr style={{ borderTop:`2px solid ${C.cloud}`, background:C.fog }}>
                      <td colSpan={5} style={{ padding:"10px 14px", fontWeight:700, color:C.ink, textAlign:"right" }}>Grand Total:</td>
                      <td style={{ padding:"10px 14px", fontWeight:800, color:C.green, fontSize:15 }}>₱{grandTotal.toLocaleString()}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            )}
          </Card>
        </>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════
//  MEMBERS REPORT
// ════════════════════════════════════════════════════════════
function MembersReport({ branches, isSuperAdmin, user, setToast }) {
  const [branchId, setBranchId] = useState("");
  const [status, setStatus] = useState("");
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [generated, setGenerated] = useState(false);

  const generate = async () => {
    setLoading(true);
    let q = supabase.from("members")
      .select("*, branches(name)")
      .order("name", { ascending: true });

    if (status) q = q.eq("is_active", status === "active");

    const { data: rows, error } = await q;
    if (error) { setToast({ msg:"Failed: " + error.message, type:"error" }); setLoading(false); return; }

    let filtered = rows || [];
    if (!isSuperAdmin && user?.branchId) {
      filtered = filtered.filter(r => r.branch_id === user.branchId);
    } else if (branchId) {
      filtered = filtered.filter(r => r.branch_id === branchId);
    }

    setData(filtered);
    setGenerated(true);
    setLoading(false);
  };

  const columns = ["Member Code", "Name", "Branch", "Status", "Points", "Category"];
  const rows = data.map(r => [
    r.member_code || "—",
    r.name || "—",
    r.branches?.name || "—",
    r.is_active ? "Active" : "Inactive",
    r.points || 0,
    r.status || r.category || "—",
  ]);

  const title = "Members Report";

  return (
    <div>
      <Card style={{ marginBottom:16 }}>
        <h3 style={{ margin:"0 0 16px", fontWeight:700, fontSize:14, color:C.ink }}>Filter</h3>
        <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fit, minmax(180px,1fr))", gap:12, marginBottom:16 }}>
          <Inp label="Status" value={status} onChange={setStatus}
            options={[{value:"",label:"All"},{value:"active",label:"Active"},{value:"inactive",label:"Inactive"}]}/>
          {isSuperAdmin && (
            <Inp label="Branch" value={branchId} onChange={setBranchId}
              options={[{value:"",label:"All Branches"}, ...branches.map(b=>({value:b.id,label:b.name}))]}/>
          )}
        </div>
        <button onClick={generate} disabled={loading}
          style={{ padding:"10px 24px", borderRadius:R.full, background:C.violet2, color:C.white,
            border:"none", fontWeight:700, fontSize:14, cursor:loading?"not-allowed":"pointer" }}>
          {loading ? "Generating…" : "Generate Report"}
        </button>
      </Card>

      {generated && (
        <Card>
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16, flexWrap:"wrap", gap:10 }}>
            <div>
              <div style={{ fontWeight:700, fontSize:15, color:C.ink }}>{title}</div>
              <div style={{ fontSize:12, color:C.mist }}>{data.length} members found</div>
            </div>
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>exportExcel(title, columns, rows, "members-report")}
                style={{ padding:"8px 16px", borderRadius:R.full, background:C.green3, color:C.green,
                  border:`1.5px solid ${C.green}`, fontWeight:600, fontSize:12, cursor:"pointer" }}>
                📊 Export Excel
              </button>
              <button onClick={()=>exportPDF(title, columns, rows, "members-report")}
                style={{ padding:"8px 16px", borderRadius:R.full, background:C.rose3, color:C.rose,
                  border:`1.5px solid ${C.rose}`, fontWeight:600, fontSize:12, cursor:"pointer" }}>
                📄 Export PDF
              </button>
            </div>
          </div>

          {data.length === 0 ? (
            <div style={{ textAlign:"center", padding:"28px 0", color:C.mist }}>No members found.</div>
          ) : (
            <div style={{ overflowX:"auto" }}>
              <table style={{ width:"100%", borderCollapse:"collapse", fontSize:13 }}>
                <thead>
                  <tr style={{ background:C.fog }}>
                    {columns.map(h=>(
                      <th key={h} style={{ textAlign:"left", padding:"10px 14px", color:C.slate,
                        fontWeight:600, fontSize:11, textTransform:"uppercase", letterSpacing:.4, whiteSpace:"nowrap" }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {data.map((r,i)=>(
                    <tr key={r.id||i} style={{ borderTop:`1px solid ${C.fog}` }}>
                      <td style={{ padding:"10px 14px", color:C.mist, fontSize:12 }}>{r.member_code||"—"}</td>
                      <td style={{ padding:"10px 14px", fontWeight:600, color:C.ink }}>{r.name||"—"}</td>
                      <td style={{ padding:"10px 14px", color:C.slate, fontSize:12 }}>{r.branches?.name||"—"}</td>
                      <td style={{ padding:"10px 14px" }}>
                        <span style={{ background:r.is_active?C.green3:C.rose3,
                          color:r.is_active?C.green:C.rose2, padding:"2px 10px",
                          borderRadius:R.full, fontSize:11, fontWeight:700 }}>
                          {r.is_active?"Active":"Inactive"}
                        </span>
                      </td>
                      <td style={{ padding:"10px 14px", color:C.ink }}>{r.points||0}</td>
                      <td style={{ padding:"10px 14px", color:C.slate, fontSize:12 }}>{r.status||r.category||"—"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════
//  MEMBERSHIP GROWTH REPORT
// ════════════════════════════════════════════════════════════
const GROWTH_TYPES = ["Men", "Women", "Young Adult", "Youth", "Kids"];
const GROWTH_TYPE_LABELS = { Youth: "KKB", Kids: "Children" };
const CATEGORY_GROUPS = {
  category1: { label: "Category 1 (WSAM + LGAM + WSAM/LGAM)", categories: ["WSAM", "LGAM", "WSAM/LGAM"] },
  category2: { label: "Category 2 (WSAM + WSAM/LGAM)", categories: ["WSAM", "WSAM/LGAM"] },
};

// Life Group demographic classification — distinct from GROWTH_TYPES (a
// person's own age/gender bracket): this is the TYPE OF GROUP a Life Group is
// registered as, set explicitly by whoever creates it.
const LG_GROUP_TYPES = ["Men", "Women", "Young Adult", "KKB", "Children", "Hetero"];
// LG Attendance excludes Hetero (mixed) groups from its own breakdown — kept
// as a valid Life Group type everywhere else.
const LG_ATTENDANCE_TYPES = LG_GROUP_TYPES.filter(t => t !== "Hetero");

const calcAge = bd => {
  if (!bd) return null;
  const d = new Date(bd), now = new Date();
  return now.getFullYear() - d.getFullYear() -
    (now < new Date(now.getFullYear(), d.getMonth(), d.getDate()) ? 1 : 0);
};
const autoType = (birthdate, gender) => {
  const age = calcAge(birthdate);
  if (age === null) return null;
  if (age <= 12) return "Kids";
  if (age <= 24) return "Youth";
  if (age <= 35) return "Young Adult";
  return gender === "Female" ? "Women" : "Men";
};
const liveType = m => autoType(m.birthdate, m.gender) || m.member_type;

const monthLabel = dateStr => {
  const [y, mo] = dateStr.split("-").map(Number);
  return new Date(y, mo - 1, 1).toLocaleDateString("en-US", { month: "short", year: "numeric" });
};
const firstOfMonthISO = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-01`;
};

// ── Grouped bar chart: bars clustered by month, one bar per type ───
const niceMax = v => {
  if (v <= 0) return 10;
  const mag = Math.pow(10, Math.floor(Math.log10(v)));
  const step = mag / 2;
  return Math.ceil(v / step) * step;
};

// Fixed categorical order (validated for adjacent-pair CVD separation).
const SERIES_COLORS = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300"];

// Rounded-top, square-bottom bar path — 4px data-end, baseline stays flat.
const barPath = (x, y, w, h, r) => {
  if (h <= 0) return "";
  r = Math.min(r, w / 2, h);
  return `M ${x} ${y+h} L ${x} ${y+r} Q ${x} ${y} ${x+r} ${y} L ${x+w-r} ${y} Q ${x+w} ${y} ${x+w} ${y+r} L ${x+w} ${y+h} Z`;
};

function GroupedBarChart({ months, series, title, subtitle }) {
  const [hover, setHover] = useState(null); // { mi, si }
  const W = 720, H = 300;
  const padL = 48, padR = 20, padT = 20, padB = 40;
  const plotW = W - padL - padR, plotH = H - padT - padB;

  const allVals = series.flatMap(s => s.values);
  const maxVal = niceMax(Math.max(1, ...allVals));
  const yFor = v => padT + plotH - (v / maxVal) * plotH;
  const ticks = [0, 0.25, 0.5, 0.75, 1].map(f => Math.round(maxVal * f));

  const n = series.length;
  const clusterW = months.length ? plotW / months.length : plotW;
  const clusterPad = Math.min(clusterW * 0.12, 14);
  const gap = 2;
  const barW = Math.min(20, (clusterW - clusterPad * 2 - gap * (n - 1)) / n);
  const groupW = barW * n + gap * (n - 1);

  return (
    <div>
      <div style={{ fontWeight:700, fontSize:14, color:C.ink, marginBottom:2 }}>{title}</div>
      <div style={{ fontSize:12, color:C.mist, marginBottom:14 }}>{subtitle}</div>
      <div style={{ display:"flex", gap:20, flexWrap:"wrap" }}>
        <div style={{ display:"flex", flexDirection:"column", gap:8, minWidth:120 }}>
          {series.map(s => (
            <div key={s.key} style={{ display:"flex", alignItems:"center", gap:8 }}>
              <span style={{ width:10, height:10, background:s.color, borderRadius:2, flexShrink:0 }}/>
              <span style={{ fontSize:12, color:C.ink, fontWeight:600 }}>{s.label}</span>
            </div>
          ))}
        </div>
        <div style={{ position:"relative", flex:1, minWidth:280 }}>
          <svg viewBox={`0 0 ${W} ${H}`} style={{ width:"100%", height:"auto", display:"block" }}
            onMouseLeave={()=>setHover(null)}>
            {ticks.map((t,i) => {
              const y = yFor(t);
              return (
                <g key={i}>
                  <line x1={padL} y1={y} x2={W-padR} y2={y} stroke="#e1e0d9" strokeWidth={1}/>
                  <text x={padL-8} y={y+4} textAnchor="end" fontSize={11} fill="#898781">{t.toLocaleString()}</text>
                </g>
              );
            })}
            <line x1={padL} y1={padT+plotH} x2={W-padR} y2={padT+plotH} stroke="#c3c2b7" strokeWidth={1}/>

            {months.map((mo,mi) => {
              const clusterX = padL + mi * clusterW + (clusterW - groupW) / 2;
              return (
                <g key={mo}>
                  <text x={padL + mi * clusterW + clusterW/2} y={H-14} textAnchor="middle" fontSize={11} fill="#898781">
                    {monthLabel(mo)}
                  </text>
                  {series.map((s, si) => {
                    const v = s.values[mi];
                    const x = clusterX + si * (barW + gap);
                    const y = yFor(v);
                    const h = padT + plotH - y;
                    const isHover = hover && hover.mi === mi && hover.si === si;
                    return (
                      <path key={s.key} d={barPath(x, y, barW, h, 3)}
                        fill={s.color} opacity={isHover ? 1 : 0.88}
                        stroke={isHover ? "#0b0b0b" : "none"} strokeWidth={isHover ? 1.5 : 0}
                        onMouseEnter={()=>setHover({ mi, si })}
                        style={{ cursor:"pointer" }}/>
                    );
                  })}
                </g>
              );
            })}
          </svg>
          {hover && (
            <div style={{ position:"absolute", top:20,
              left:`${Math.min(Math.max(((padL + hover.mi*clusterW + clusterW/2)/W)*100,10),90)}%`,
              transform:"translateX(-50%)",
              background:C.ink, color:"#fff", borderRadius:R.sm, padding:"6px 10px", fontSize:12,
              pointerEvents:"none", whiteSpace:"nowrap" }}>
              <div style={{ fontWeight:700 }}>{series[hover.si].values[hover.mi].toLocaleString()} {series[hover.si].label}</div>
              <div style={{ color:"#c3c2b7" }}>{monthLabel(months[hover.mi])}</div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

const ATTENDANCE_MODE = "attendance";
const FIRSTTIMERS_MODE = "firsttimers";
const LG_COUNT_MODE = "lgcount";
const LG_LEADERS_MODE = "lgleaders";
const LG_MEMBERSHIP_MODE = "lgmembership";
const LG_ATTENDANCE_MODE = "lgattendance";

function MembershipGrowthReport({ setToast }) {
  const [group, setGroup] = useState("category1");
  const [snapshots, setSnapshots] = useState([]);
  const [attendanceByMonth, setAttendanceByMonth] = useState({});
  const [firstTimersByMonth, setFirstTimersByMonth] = useState({});
  const [lgAttendanceByMonth, setLgAttendanceByMonth] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => { syncAndLoad(); }, []);

  const syncAndLoad = async () => {
    setLoading(true);
    try {
      let all = [], from = 0;
      while (true) {
        const { data, error } = await supabase.from("members")
          .select("category, member_type, birthdate, gender, is_active, life_group_id")
          .eq("is_active", true)
          .range(from, from + 999);
        if (error) { setToast({ msg:"Failed: " + error.message, type:"error" }); break; }
        if (!data || data.length === 0) break;
        all = [...all, ...data];
        if (data.length < 1000) break;
        from += 1000;
      }

      const thisMonth = firstOfMonthISO();
      const rows = [];
      Object.entries(CATEGORY_GROUPS).forEach(([key, def]) => {
        const counts = Object.fromEntries(GROWTH_TYPES.map(t => [t, 0]));
        all.forEach(m => {
          if (!def.categories.includes(m.category)) return;
          const t = liveType(m);
          if (t in counts) counts[t] += 1;
        });
        GROWTH_TYPES.forEach(t => {
          rows.push({ snapshot_month: thisMonth, category_group: key, member_type: t, count: counts[t] });
        });
      });

      // No. of Life Groups / Life Group Leaders / LG Membership — all current-state
      // counts, classified by each group's own registered type (not a person's
      // personal demographic), snapshotted the same way as Category 1/2.
      const { data: lgRows } = await supabase.from("life_groups").select("id, leader_name, group_type");
      const groups = lgRows || [];
      const groupTypeById = Object.fromEntries(groups.map(g => [g.id, g.group_type]));

      const membershipCounts = Object.fromEntries(LG_GROUP_TYPES.map(t => [t, 0]));
      all.forEach(m => {
        const t = m.life_group_id ? groupTypeById[m.life_group_id] : null;
        if (t && t in membershipCounts) membershipCounts[t] += 1;
      });

      LG_GROUP_TYPES.forEach(t => {
        const groupsOfType = groups.filter(g => g.group_type === t);
        rows.push({ snapshot_month: thisMonth, category_group: LG_COUNT_MODE, member_type: t, count: groupsOfType.length });
        rows.push({ snapshot_month: thisMonth, category_group: LG_LEADERS_MODE, member_type: t, count: new Set(groupsOfType.map(g => g.leader_name)).size });
        rows.push({ snapshot_month: thisMonth, category_group: LG_MEMBERSHIP_MODE, member_type: t, count: membershipCounts[t] });
      });

      const { error: upsertError } = await supabase.from("membership_snapshots")
        .upsert(rows, { onConflict: "snapshot_month,category_group,member_type" });
      if (upsertError) setToast({ msg:"Snapshot save failed: " + upsertError.message, type:"error" });

      const { data: history, error: historyError } = await supabase
        .from("membership_snapshots").select("*").order("snapshot_month", { ascending: true });
      if (historyError) { setToast({ msg:"Failed: " + historyError.message, type:"error" }); setLoading(false); return; }
      setSnapshots(history || []);

      // Sunday Service Attendance: computed straight from real attendance history
      // (each row already carries a real date, so no snapshotting needed). The
      // "average" per month = total check-ins that month / distinct service dates
      // that month — i.e. how many Sundays occurred that month — so someone who
      // attends all 4 Sundays counts as 4 check-ins spread across 4 Sundays, not
      // a 4x inflated headcount.
      let attRows = [], attFrom = 0;
      while (true) {
        const { data, error } = await supabase.from("attendance")
          .select("member_id, service_date, members(birthdate, gender, member_type)")
          .range(attFrom, attFrom + 999);
        if (error) { setToast({ msg:"Failed: " + error.message, type:"error" }); break; }
        if (!data || data.length === 0) break;
        attRows = [...attRows, ...data];
        if (data.length < 1000) break;
        attFrom += 1000;
      }

      const byMonth = {};
      attRows.forEach(r => {
        if (!r.service_date || !r.members) return;
        const mo = `${r.service_date.slice(0, 7)}-01`;
        byMonth[mo] ??= { sundays: new Set(), counts: Object.fromEntries(GROWTH_TYPES.map(t => [t, 0])) };
        byMonth[mo].sundays.add(r.service_date);
        const t = liveType(r.members);
        if (t in byMonth[mo].counts) byMonth[mo].counts[t] += 1;
      });
      setAttendanceByMonth(byMonth);

      // First Timers: each member's FIRST-EVER attendance date, bucketed by month —
      // i.e. brand-new visitors that month, not a snapshot of current category.
      const firstDateByMember = {}, infoByMember = {};
      attRows.forEach(r => {
        if (!r.member_id || !r.service_date) return;
        if (!firstDateByMember[r.member_id] || r.service_date < firstDateByMember[r.member_id]) {
          firstDateByMember[r.member_id] = r.service_date;
        }
        if (r.members && !infoByMember[r.member_id]) infoByMember[r.member_id] = r.members;
      });
      const ftByMonth = {};
      Object.entries(firstDateByMember).forEach(([memberId, date]) => {
        const mo = `${date.slice(0, 7)}-01`;
        ftByMonth[mo] ??= Object.fromEntries(GROWTH_TYPES.map(t => [t, 0]));
        const info = infoByMember[memberId];
        const t = info ? liveType(info) : null;
        if (t && t in ftByMonth[mo]) ftByMonth[mo][t] += 1;
      });
      setFirstTimersByMonth(ftByMonth);

      // LG Attendance: average = check-ins ÷ sessions that month, bucketed by
      // the group's own type instead of the member's personal type, with the
      // "sessions" denominator scoped per group type too (different groups
      // can meet on different days).
      let lgAttRows = [], lgAttFrom = 0;
      while (true) {
        const { data, error } = await supabase.from("lg_attendance")
          .select("session_date, life_groups(group_type)")
          .range(lgAttFrom, lgAttFrom + 999);
        if (error) { setToast({ msg:"Failed: " + error.message, type:"error" }); break; }
        if (!data || data.length === 0) break;
        lgAttRows = [...lgAttRows, ...data];
        if (data.length < 1000) break;
        lgAttFrom += 1000;
      }

      const lgByMonth = {};
      lgAttRows.forEach(r => {
        const t = r.life_groups?.group_type;
        if (!r.session_date || !t) return;
        const mo = `${r.session_date.slice(0, 7)}-01`;
        lgByMonth[mo] ??= { sessionsByType: {}, counts: Object.fromEntries(LG_GROUP_TYPES.map(x => [x, 0])) };
        lgByMonth[mo].sessionsByType[t] ??= new Set();
        lgByMonth[mo].sessionsByType[t].add(r.session_date);
        lgByMonth[mo].counts[t] += 1;
      });
      setLgAttendanceByMonth(lgByMonth);
    } catch (err) {
      setToast({ msg:"Unexpected error: " + err.message, type:"error" });
    }
    setLoading(false);
  };

  const isAttendance = group === ATTENDANCE_MODE;
  const isFirstTimers = group === FIRSTTIMERS_MODE;
  const isLgAttendance = group === LG_ATTENDANCE_MODE;
  const isLgSnapshot = group === LG_COUNT_MODE || group === LG_LEADERS_MODE || group === LG_MEMBERSHIP_MODE;

  const activeTypes = isLgAttendance ? LG_ATTENDANCE_TYPES
    : isLgSnapshot ? LG_GROUP_TYPES
    : GROWTH_TYPES;
  const activeLabel = t => (isLgSnapshot || isLgAttendance) ? t : (GROWTH_TYPE_LABELS[t] || t);

  const months = isAttendance
    ? Object.keys(attendanceByMonth).sort()
    : isFirstTimers
    ? Object.keys(firstTimersByMonth).sort()
    : isLgAttendance
    ? Object.keys(lgAttendanceByMonth).sort()
    : [...new Set(snapshots.filter(s => isLgSnapshot ? s.category_group === group : true).map(s => s.snapshot_month))].sort();

  const cell = (month, type) => {
    if (isAttendance) {
      const m = attendanceByMonth[month];
      if (!m || m.sundays.size === 0) return 0;
      return Math.round(m.counts[type] / m.sundays.size);
    }
    if (isFirstTimers) return firstTimersByMonth[month]?.[type] ?? 0;
    if (isLgAttendance) {
      const m = lgAttendanceByMonth[month];
      const sessions = m?.sessionsByType?.[type]?.size || 0;
      if (!m || sessions === 0) return 0;
      return Math.round(m.counts[type] / sessions);
    }
    return snapshots.find(s => s.snapshot_month === month && s.category_group === group && s.member_type === type)?.count ?? 0;
  };

  const columns = ["Type", ...months.map(monthLabel)];
  const totalRowLabel = isAttendance || isLgAttendance ? "Average Attendance"
    : group === LG_COUNT_MODE ? "Total No. of Life Groups"
    : group === LG_LEADERS_MODE ? "Total No. of Life Group Leaders"
    : group === LG_MEMBERSHIP_MODE ? "Total LG Membership"
    : "Total Membership";
  const tableRows = [
    ...activeTypes.map(t => [activeLabel(t), ...months.map(mo => cell(mo, t))]),
    [totalRowLabel, ...months.map(mo => activeTypes.reduce((sum, t) => sum + cell(mo, t), 0))],
  ];
  const chartSeries = activeTypes.map((t, i) => ({
    key: t,
    label: activeLabel(t),
    color: SERIES_COLORS[i],
    values: months.map(mo => cell(mo, t)),
  }));

  const title = isAttendance ? "Sunday Service Attendance"
    : isFirstTimers ? "Total No. of First Timers (Sunday Service)"
    : group === LG_COUNT_MODE ? "No. of Life Groups"
    : group === LG_LEADERS_MODE ? "Life Group Leaders"
    : group === LG_MEMBERSHIP_MODE ? "LG Membership"
    : group === LG_ATTENDANCE_MODE ? "LG Attendance"
    : CATEGORY_GROUPS[group].label;

  return (
    <div>
      <Card style={{ marginBottom:16 }}>
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", flexWrap:"wrap", gap:12 }}>
          <div style={{ display:"flex", gap:8, flexWrap:"wrap" }}>
            {Object.entries(CATEGORY_GROUPS).map(([key, def]) => (
              <Pill key={key} label={def.label} active={group===key} onClick={()=>setGroup(key)} color={C.amber2}/>
            ))}
            <Pill label="Sunday Service Attendance" active={isAttendance} onClick={()=>setGroup(ATTENDANCE_MODE)} color={C.blue}/>
            <Pill label="First Timers" active={isFirstTimers} onClick={()=>setGroup(FIRSTTIMERS_MODE)} color={C.rose2}/>
            <Pill label="No. of Life Groups" active={group===LG_COUNT_MODE} onClick={()=>setGroup(LG_COUNT_MODE)} color={C.violet2}/>
            <Pill label="Life Group Leaders" active={group===LG_LEADERS_MODE} onClick={()=>setGroup(LG_LEADERS_MODE)} color={C.violet2}/>
            <Pill label="LG Membership" active={group===LG_MEMBERSHIP_MODE} onClick={()=>setGroup(LG_MEMBERSHIP_MODE)} color={C.violet2}/>
            <Pill label="LG Attendance" active={isLgAttendance} onClick={()=>setGroup(LG_ATTENDANCE_MODE)} color={C.violet2}/>
          </div>
          <div style={{ fontSize:12, color:C.mist }}>
            {isAttendance
              ? "Average = total check-ins ÷ Sundays that month."
              : isFirstTimers
              ? "Each member counted once, in the month of their first-ever attendance."
              : isLgAttendance
              ? "Average = check-ins ÷ sessions that month, per group type."
              : isLgSnapshot
              ? "Classified by each Life Group's own registered type — snapshots update automatically each month you view this report."
              : "Snapshots update automatically each month you view this report."}
          </div>
        </div>
      </Card>

      {!loading && months.length > 0 && (
        <Card style={{ marginBottom:16 }}>
          <GroupedBarChart months={months} series={chartSeries} title={title}
            subtitle={isAttendance ? "Average Sunday attendance by type"
              : isFirstTimers ? "New first-time attendees by type"
              : isLgAttendance ? "Average Bible study attendance by group type"
              : isLgSnapshot ? "By Life Group type" : "Membership by type"}/>
        </Card>
      )}

      <Card>
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16, flexWrap:"wrap", gap:10 }}>
          <div>
            <div style={{ fontWeight:700, fontSize:15, color:C.ink }}>{title}</div>
            <div style={{ fontSize:12, color:C.mist }}>{months.length} month{months.length!==1?"s":""} recorded</div>
          </div>
          {months.length > 0 && (
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>exportExcel(title, columns, tableRows, "membership-growth")}
                style={{ padding:"8px 16px", borderRadius:R.full, background:C.green3, color:C.green,
                  border:`1.5px solid ${C.green}`, fontWeight:600, fontSize:12, cursor:"pointer" }}>
                📊 Export Excel
              </button>
              <button onClick={()=>exportPDF(title, columns, tableRows, "membership-growth")}
                style={{ padding:"8px 16px", borderRadius:R.full, background:C.rose3, color:C.rose,
                  border:`1.5px solid ${C.rose}`, fontWeight:600, fontSize:12, cursor:"pointer" }}>
                📄 Export PDF
              </button>
            </div>
          )}
        </div>

        {loading ? (
          <div style={{ textAlign:"center", padding:"28px 0", color:C.mist }}>Loading…</div>
        ) : months.length === 0 ? (
          <div style={{ textAlign:"center", padding:"28px 0", color:C.mist }}>No snapshots recorded yet.</div>
        ) : (
          <div style={{ overflowX:"auto" }}>
            <table style={{ width:"100%", borderCollapse:"collapse", fontSize:13 }}>
              <thead>
                <tr style={{ background:C.fog }}>
                  {columns.map(h=>(
                    <th key={h} style={{ textAlign:"left", padding:"10px 14px", color:C.slate,
                      fontWeight:600, fontSize:11, textTransform:"uppercase", letterSpacing:.4, whiteSpace:"nowrap" }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {tableRows.map((r, i) => (
                  <tr key={r[0]} style={{ borderTop:`1px solid ${C.fog}`, background: i===tableRows.length-1?C.fog:C.white }}>
                    {r.map((v, j) => (
                      <td key={j} style={{ padding:"10px 14px", fontWeight: j===0||i===tableRows.length-1?700:400,
                        color: i===tableRows.length-1?C.ink:C.slate }}>{v}</td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
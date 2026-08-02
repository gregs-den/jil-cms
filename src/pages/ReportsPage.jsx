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
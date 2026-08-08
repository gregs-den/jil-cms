import { useState, useEffect, useCallback } from "react";
import QRCode from "qrcode";
import { supabase } from "../lib/supabaseClient";
// Import for CSV parsing, PDF export, and ZIP creation
// Add these to package.json: papaparse, html2pdf, jszip

// ── Design tokens ───────────────────────────────────────────
const C = {
  ink: "#0A0F1E", ink2: "#1C2336", ink3: "#2E3A52",
  slate: "#64748B", mist: "#94A3B8", cloud: "#CBD5E1",
  fog: "#E8EDF5", white: "#FFFFFF",
  blue: "#1D4ED8", blue2: "#3B82F6", blue3: "#DBEAFE",
  green: "#15803D", green2: "#22C55E", green3: "#DCFCE7",
  amber: "#B45309", amber2: "#F59E0B", amber3: "#FEF3C7",
  rose: "#BE123C", rose2: "#F43F5E", rose3: "#FFE4E6",
  violet: "#6D28D9", violet2: "#8B5CF6", violet3: "#EDE9FE",
};
const R = { xs:"6px", sm:"10px", md:"14px", lg:"18px", xl:"24px", xxl:"32px", full:"9999px" };
const SH = { sm:"0 2px 8px rgba(0,0,0,.07)", md:"0 4px 20px rgba(0,0,0,.09)", lg:"0 8px 40px rgba(0,0,0,.13)" };

// ── Shared components ────────────────────────────────────────
const Inp = ({ label, type="text", value, onChange, required, options }) => (
  <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:16 }}>
    <label style={{ fontSize:12, fontWeight:600, color:C.slate, letterSpacing:.2 }}>
      {label}{required && <span style={{ color:C.rose2 }}> *</span>}
    </label>
    {options ? (
      <select value={value} onChange={e=>onChange(e.target.value)}
        style={{ padding:"10px 14px", border:`1.5px solid ${C.cloud}`, borderRadius:R.md,
          fontSize:14, outline:"none", background:C.white, color:C.ink, appearance:"none",
          backgroundImage:`url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2364748B' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E")`,
          backgroundRepeat:"no-repeat", backgroundPosition:"right 12px center" }}>
        {options.map(o=><option key={o} value={o}>{o}</option>)}
      </select>
    ) : (
      <input type={type} value={value} onChange={e=>onChange(e.target.value)}
        style={{ padding:"10px 14px", border:`1.5px solid ${C.cloud}`, borderRadius:R.md,
          fontSize:14, outline:"none", color:C.ink, background:C.white, transition:"border-color .15s" }}
        onFocus={e=>e.target.style.borderColor=C.blue2}
        onBlur={e=>e.target.style.borderColor=C.cloud}/>
    )}
  </div>
);

const Badge = ({ label, color=C.blue }) => (
  <span style={{ background:`${color}18`, color, padding:"3px 10px", borderRadius:R.full,
    fontSize:11, fontWeight:700, letterSpacing:.3, whiteSpace:"nowrap" }}>{label}</span>
);

const Spinner = ({ size=18 }) => (
  <div style={{ display:"inline-block", width:size, height:size, borderRadius:"50%",
    border:`2px solid ${C.cloud}`, borderTopColor:C.blue, animation:"spin .7s linear infinite" }}>
    <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
  </div>
);

const Toast = ({ msg, type="success", onDone }) => {
  useEffect(()=>{ const t=setTimeout(onDone,3200); return ()=>clearTimeout(t); },[onDone]);
  const bg = type==="error"?C.rose3:type==="warn"?C.amber3:type==="info"?C.blue3:C.green3;
  const fg = type==="error"?C.rose:type==="warn"?C.amber:type==="info"?C.blue:C.green;
  return (
    <div style={{ position:"fixed", bottom:24, left:"50%", transform:"translateX(-50%)",
      background:bg, color:fg, borderRadius:R.full, padding:"11px 22px", fontSize:13,
      fontWeight:600, boxShadow:SH.md, zIndex:2000, whiteSpace:"nowrap",
      animation:"slideUp .25s ease" }}>
      <style>{`@keyframes slideUp{from{transform:translateX(-50%) translateY(12px);opacity:0}}`}</style>
      {msg}
    </div>
  );
};

const Card = ({ children, style={} }) => (
  <div style={{ background:C.white, borderRadius:R.xl, boxShadow:SH.md, 
    border:`1px solid ${C.fog}`, padding:20, ...style }}>
    {children}
  </div>
);

// ── Reopen Modal ─────────────────────────────────────────────
// Lets admin pick a new expiry time and reactivate an ended/expired event
const ReopenModal = ({ open, row, onClose, onConfirm, loading }) => {
  const pad = n => String(n).padStart(2,"0");
  const toLocalDT = (date) =>
    `${date.getFullYear()}-${pad(date.getMonth()+1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;

  // Default new expiry = 2 hours from now
  const [newExpiry, setNewExpiry] = useState(() => {
    const d = new Date();
    d.setHours(d.getHours() + 2, 0, 0, 0);
    return toLocalDT(d);
  });

  // Reset expiry each time the modal opens for a new row
  useEffect(() => {
    if (open) {
      const d = new Date();
      d.setHours(d.getHours() + 2, 0, 0, 0);
      setNewExpiry(toLocalDT(d));
    }
  }, [open, row?.id]);

  if (!open || !row) return null;

  return (
    <div onClick={onClose} style={{ position:"fixed", inset:0,
      background:"rgba(10,15,30,.5)", backdropFilter:"blur(6px)",
      zIndex:1000, display:"flex", alignItems:"center", justifyContent:"center", padding:16 }}>
      <div onClick={e=>e.stopPropagation()} style={{ background:C.white, borderRadius:R.xxl,
        boxShadow:SH.lg, width:"100%", maxWidth:420 }}>

        {/* Header */}
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center",
          padding:"22px 24px 0" }}>
          <h3 style={{ margin:0, fontWeight:800, fontSize:17, color:C.ink }}>Reopen Service</h3>
          <button onClick={onClose} style={{ border:"none", background:C.fog, borderRadius:"50%",
            width:32, height:32, cursor:"pointer", display:"flex", alignItems:"center",
            justifyContent:"center", fontSize:16, color:C.slate }}>✕</button>
        </div>

        <div style={{ padding:"16px 24px 28px" }}>
          {/* Event summary */}
          <div style={{ background:C.fog, borderRadius:R.lg, padding:"12px 14px", marginBottom:20 }}>
            <div style={{ fontWeight:700, fontSize:14, color:C.ink }}>{row.event}</div>
            <div style={{ fontSize:12, color:C.mist, marginTop:3 }}>
              {row.date} · {row.time?.slice(0,5)} · {row.branch}
            </div>
          </div>

          {/* Warning */}
          <div style={{ background:C.amber3, border:`1px solid ${C.amber2}`, borderRadius:R.md,
            padding:"10px 14px", fontSize:12, color:C.amber, fontWeight:600, marginBottom:20 }}>
            ⚠️ Reopening will deactivate any currently live service and make this one active again.
          </div>

          {/* New expiry picker */}
          <div style={{ marginBottom:20 }}>
            <label style={{ fontSize:12, fontWeight:600, color:C.slate, display:"block", marginBottom:6 }}>
              New Expiry Time
            </label>
            <input type="datetime-local" value={newExpiry}
              min={new Date().toISOString().slice(0,16)}
              onChange={e=>setNewExpiry(e.target.value)}
              style={{ width:"100%", padding:"10px 14px", border:`1.5px solid ${C.cloud}`,
                borderRadius:R.md, fontSize:14, outline:"none", color:C.ink,
                boxSizing:"border-box" }}/>
            <div style={{ fontSize:11, color:C.mist, marginTop:5 }}>
              Suggested: 1–2 hours from now to give latecomers enough time to scan.
            </div>
          </div>

          {/* Actions */}
          <div style={{ display:"flex", gap:10 }}>
            <button onClick={onClose}
              style={{ flex:1, padding:"10px 0", borderRadius:R.full, background:C.white,
                color:C.slate, border:`1.5px solid ${C.cloud}`, fontWeight:600,
                fontSize:14, cursor:"pointer" }}>
              Cancel
            </button>
            <button onClick={()=>onConfirm(row, newExpiry)} disabled={loading || !newExpiry}
              style={{ flex:1, padding:"10px 0", borderRadius:R.full,
                background: loading ? C.amber3 : C.amber2,
                color: C.white, border:"none", fontWeight:700, fontSize:14,
                cursor: loading ? "not-allowed" : "pointer",
                display:"flex", alignItems:"center", justifyContent:"center", gap:8 }}>
              {loading ? <><Spinner size={15}/> Reopening…</> : "🔓 Reopen"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

// ── Helpers ──────────────────────────────────────────────────
const pad = n => String(n).padStart(2,"0");

const toLocalDatetimeValue = (date) =>
  `${date.getFullYear()}-${pad(date.getMonth()+1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;

const todayDate = () => {
  const d = new Date();
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}`;
};

const defaultExpiry = () => {
  const d = new Date();
  d.setHours(12,0,0,0);
  return toLocalDatetimeValue(d);
};

const defaultServiceTime = () => {
  const d = new Date();
  d.setHours(9,0,0,0);
  return `${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

const formatDateTime = (iso) => {
  if (!iso) return "—";
  const d = new Date(iso);
  return d.toLocaleString(undefined, { month:"short", day:"numeric", hour:"2-digit", minute:"2-digit" });
};

function BulkQRTab({ role, user, branches }) {
  // ── Core State ──
  const [members, setMembers] = useState([]);
  const [branchId, setBranchId] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedMembers, setSelectedMembers] = useState(new Set());
  const [loading, setLoading] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [progress, setProgress] = useState(0);
  const [toast, setToast] = useState(null);
  
  // ── Customization State ──
  const [qrStyle, setQrStyle] = useState({ size:200, color:"#000000", bg:"#FFFFFF" });
  const [qrSize, setQrSize] = useState(200);
  const [template, setTemplate] = useState("standard");
  const [showLabels, setShowLabels] = useState(true);
  const [labelFields, setLabelFields] = useState(["name", "member_code", "branch"]);
  const [gridColumns, setGridColumns] = useState(4);
  
  // ── Export State ──
  const [exportFormat, setExportFormat] = useState("print");
  const [csvFile, setCsvFile] = useState(null);
  
  // ── Templates ──
  const templates = {
    standard: { name: "Standard", gap: 20, cols: 4 },
    compact: { name: "Compact", gap: 12, cols: 5 },
    large: { name: "Large", gap: 24, cols: 3 },
    minimal: { name: "Minimal", gap: 16, cols: 4 },
  };

  // Fetch members from database
  useEffect(() => {
    const fetchMembers = async () => {
      setLoading(true);
      let q = supabase.from("members").select("id, name, member_code, branch_id, email, branches(name)")
        .eq("is_active", true).order("name");
      if (role !== "superadmin" && user?.branchId) q = q.eq("branch_id", user.branchId);
      const { data } = await q;
      if (data) setMembers(data);
      setLoading(false);
    };
    fetchMembers();
  }, []);

  // ── Filtering Logic ──
  const filtered = members.filter(m => {
    const matchesBranch = !branchId || m.branch_id === branchId;
    const matchesSearch = !searchQuery || 
      m.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      m.member_code.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesBranch && matchesSearch;
  });

  // ── CSV Upload Handler ──
  const handleCsvUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    const reader = new FileReader();
    reader.onload = async (event) => {
      try {
        // Parse CSV manually or use papaparse if available
        const csv = event.target.result;
        const lines = csv.split('\n');
        const headers = lines[0].split(',').map(h => h.trim().toLowerCase());
        
        const newMembers = [];
        for (let i = 1; i < lines.length; i++) {
          if (!lines[i].trim()) continue;
          const values = lines[i].split(',').map(v => v.trim());
          const member = {};
          headers.forEach((h, idx) => { member[h] = values[idx]; });
          newMembers.push({ ...member, id: `csv_${i}` });
        }
        
        // Add to members if they don't exist
        const uniqueMembers = [...members, ...newMembers.filter(
          nm => !members.find(m => m.member_code === nm.member_code)
        )];
        setMembers(uniqueMembers);
        showToast(`Imported ${newMembers.length} members from CSV`, "success");
      } catch (err) {
        showToast("CSV parsing failed", "error");
      }
    };
    reader.readAsText(file);
  };

  // ── Database Storage ──
  const saveToHistory = async () => {
    try {
      await supabase.from("qr_generation_history").insert({
        user_id: user.id,
        branch_id: branchId || null,
        member_count: selectedMembers.size || filtered.length,
        template,
        qr_style: qrStyle,
        grid_columns: gridColumns,
        created_at: new Date().toISOString(),
      });
      showToast("Saved to history", "success");
    } catch (err) {
      console.error("Failed to save history:", err);
    }
  };

  // ── Export Functions ──
  const generateQRDataUrl = async (m) => {
    const payload = JSON.stringify({ 
      memberId: m.id, 
      name: m.name, 
      code: m.member_code,
      branch: m.branches?.name 
    });
    return await QRCode.toDataURL(payload, {
      width: qrSize,
      margin: 1,
      color: { dark: qrStyle.color, light: qrStyle.bg },
    });
  };

  // Print/Web Preview
  const generatePrintView = async () => {
    if (filtered.length === 0) return;
    setGenerating(true);
    setProgress(0);

    const toExport = selectedMembers.size > 0 
      ? filtered.filter(m => selectedMembers.has(m.id))
      : filtered;

    const win = window.open("", "_blank");
    const templateConfig = templates[template];
    
    win.document.write(`
      <html><head><title>Bulk QR Codes - ${new Date().toLocaleDateString()}</title>
      <style>
        body { font-family: system-ui, sans-serif; margin: 0; padding: 20px; background: #f8f9fa; }
        .header { margin-bottom: 24px; }
        .title { font-size: 24px; font-weight: 700; color: #0a0f1e; margin: 0 0 8px; }
        .meta { font-size: 13px; color: #64748b; }
        .grid { display: grid; grid-template-columns: repeat(${templateConfig.cols}, 1fr); gap: ${templateConfig.gap}px; }
        .card { 
          border: 1px solid #e2e8f0; 
          border-radius: 12px; 
          padding: 16px; 
          text-align: center; 
          break-inside: avoid;
          background: white;
          box-shadow: 0 2px 8px rgba(0,0,0,.07);
        }
        .qr-container { margin-bottom: 12px; }
        .qr-container img { width: 100%; max-width: ${qrSize}px; }
        .name { font-weight: 700; font-size: 13px; margin: 8px 0 4px; color: #0a0f1e; }
        .code { font-size: 11px; color: #64748b; margin: 2px 0; }
        .branch { font-size: 10px; color: #94a3b8; }
        .no-print { display: block; margin-bottom: 20px; }
        button { padding: 12px 24px; background: #1D4ED8; color: white; border: none; border-radius: 999px; font-weight: 700; cursor: pointer; font-size: 14px; }
        button:hover { background: #3B82F6; }
        .stats { font-size: 13px; color: #64748b; margin-left: 12px; }
        @media print {
          body { padding: 10px; background: white; }
          .grid { grid-template-columns: repeat(${templateConfig.cols}, 1fr); gap: ${templateConfig.gap / 2}px; }
          .no-print { display: none; }
          @page { size: A4; margin: 10mm; }
        }
      </style></head>
      <body>
      <div class="no-print">
        <button onclick="window.print()">🖨️ Print All QR Codes</button>
        <span class="stats">${toExport.length} QR codes | Template: ${templates[template].name}</span>
      </div>
      <div class="header">
        <div class="title">Member QR Codes</div>
        <div class="meta">Generated on ${new Date().toLocaleString()}</div>
      </div>
      <div class="grid">
    `);

    for (let i = 0; i < toExport.length; i++) {
      const m = toExport[i];
      const dataUrl = await generateQRDataUrl(m);

      let labelHtml = "";
      if (showLabels) {
        if (labelFields.includes("name")) labelHtml += `<div class="name">${m.name}</div>`;
        if (labelFields.includes("member_code")) labelHtml += `<div class="code">${m.member_code}</div>`;
        if (labelFields.includes("branch")) labelHtml += `<div class="branch">${m.branches?.name || ""}</div>`;
      }

      win.document.write(`
        <div class="card">
          <div class="qr-container">
            <img src="${dataUrl}" alt="${m.name}"/>
          </div>
          ${labelHtml}
        </div>
      `);

      setProgress(Math.round((i + 1) / toExport.length * 100));
    }

    win.document.write(`</div></body></html>`);
    win.document.close();
    setGenerating(false);
    setProgress(0);
    saveToHistory();
  };

  // Download as PNG/JPG/SVG
  const downloadAsImages = async (format) => {
    if (filtered.length === 0) return;
    setGenerating(true);
    setProgress(0);

    const toExport = selectedMembers.size > 0 
      ? filtered.filter(m => selectedMembers.has(m.id))
      : filtered;

    // Using JSZip for bundling
    // For single files, just download
    for (let i = 0; i < toExport.length; i++) {
      const m = toExport[i];
      const dataUrl = await generateQRDataUrl(m);
      
      const link = document.createElement('a');
      link.href = dataUrl;
      link.download = `QR_${m.member_code}_${m.name.replace(/\s+/g, '_')}.png`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      setProgress(Math.round((i + 1) / toExport.length * 100));
      // Stagger downloads
      await new Promise(r => setTimeout(r, 200));
    }

    setGenerating(false);
    setProgress(0);
    showToast(`Downloaded ${toExport.length} QR codes as ${format}`, "success");
    saveToHistory();
  };

  // Export as PDF
  const exportPdf = async () => {
    setGenerating(true);
    setProgress(0);
    
    const toExport = selectedMembers.size > 0 
      ? filtered.filter(m => selectedMembers.has(m.id))
      : filtered;

    try {
      // Create PDF content
      const { jsPDF } = window.jspdf || {};
      if (!jsPDF) {
        showToast("PDF library not loaded. Try print instead.", "warn");
        setGenerating(false);
        return;
      }

      const doc = new jsPDF();
      const templateConfig = templates[template];
      const pageHeight = doc.internal.pageSize.getHeight();
      const pageWidth = doc.internal.pageSize.getWidth();
      const margin = 10;
      const colWidth = (pageWidth - margin * 2) / templateConfig.cols;
      const spacing = 5;

      let x = margin, y = margin + 15;
      doc.setFontSize(14);
      doc.text("Member QR Codes", margin, margin + 5);

      for (let i = 0; i < toExport.length; i++) {
        const m = toExport[i];
        const dataUrl = await generateQRDataUrl(m);

        if (y + qrSize / 4 > pageHeight - margin) {
          doc.addPage();
          x = margin;
          y = margin;
        }

        // Add QR
        doc.addImage(dataUrl, 'PNG', x + (colWidth - qrSize / 4) / 2, y, qrSize / 4, qrSize / 4);

        // Add labels
        let labelY = y + qrSize / 4 + 2;
        if (showLabels) {
          doc.setFontSize(8);
          if (labelFields.includes("name")) {
            doc.text(m.name.substring(0, 15), x + colWidth / 2, labelY, { align: "center" });
            labelY += 3;
          }
          if (labelFields.includes("member_code")) {
            doc.text(m.member_code, x + colWidth / 2, labelY, { align: "center" });
            labelY += 3;
          }
        }

        x += colWidth;
        if (x + colWidth > pageWidth) {
          x = margin;
          y += qrSize / 4 + 20;
        }

        setProgress(Math.round((i + 1) / toExport.length * 100));
      }

      doc.save(`QR_Codes_${new Date().toISOString().split('T')[0]}.pdf`);
      showToast(`PDF exported with ${toExport.length} QR codes`, "success");
      saveToHistory();
    } catch (err) {
      console.error("PDF export failed:", err);
      showToast("PDF export failed", "error");
    }
    
    setGenerating(false);
    setProgress(0);
  };

  // Send via Email
  const sendViaEmail = async () => {
    const toExport = selectedMembers.size > 0 
      ? filtered.filter(m => selectedMembers.has(m.id))
      : filtered;

    setGenerating(true);
    setProgress(0);

    try {
      const qrDataUrls = {};
      for (let i = 0; i < toExport.length; i++) {
        qrDataUrls[toExport[i].id] = await generateQRDataUrl(toExport[i]);
        setProgress(Math.round((i + 1) / toExport.length * 100));
      }

      // Call backend email function
      const { data, error } = await supabase.functions.invoke('send-bulk-qr-emails', {
        body: {
          members: toExport.map(m => ({ ...m, qr_data_url: qrDataUrls[m.id] })),
          sender_id: user.id,
        }
      });

      if (error) throw error;
      showToast(`Sent QR codes to ${toExport.length} members`, "success");
      saveToHistory();
    } catch (err) {
      console.error("Email send failed:", err);
      showToast("Failed to send emails", "error");
    }

    setGenerating(false);
    setProgress(0);
  };

  const showToast = (msg, type = "success") => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3200);
  };

  const toggleMemberSelection = (memberId) => {
    const newSelected = new Set(selectedMembers);
    if (newSelected.has(memberId)) {
      newSelected.delete(memberId);
    } else {
      newSelected.add(memberId);
    }
    setSelectedMembers(newSelected);
  };

  const selectAll = () => {
    setSelectedMembers(new Set(filtered.map(m => m.id)));
  };

  const clearSelection = () => {
    setSelectedMembers(new Set());
  };

  return (
    <div>
      {/* ── CSV Upload ── */}
      <Card style={{ marginBottom:16, background:C.blue3 }}>
        <h3 style={{ margin:"0 0 12px", fontWeight:700, fontSize:13, color:C.blue }}>📤 Import Members from CSV</h3>
        <input type="file" accept=".csv" onChange={handleCsvUpload}
          style={{ padding:"8px 12px", border:`1.5px dashed ${C.blue}`, borderRadius:R.md,
            fontSize:12, cursor:"pointer", color:C.slate }}/>
        <div style={{ fontSize:11, color:C.mist, marginTop:6 }}>
          Expected columns: name, member_code, email, branch (optional)
        </div>
      </Card>

      {/* ── Configuration ── */}
      <Card style={{ marginBottom:16 }}>
        <h3 style={{ margin:"0 0 16px", fontWeight:700, fontSize:14, color:C.ink }}>⚙️ QR Configuration</h3>
        
        {/* Row 1: Branch, Size, Template */}
        <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fit,minmax(160px,1fr))", gap:12, marginBottom:16 }}>
          {role === "superadmin" && (
            <Inp label="Branch" options={["All Branches", ...branches.map(b => b.name)]}
              value={branchId ? branches.find(b => b.id === branchId)?.name || "" : "All Branches"}
              onChange={v => setBranchId(v === "All Branches" ? "" : branches.find(b => b.name === v)?.id || "")}/>
          )}
          
          <div style={{ display:"flex", flexDirection:"column", gap:5 }}>
            <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>QR Size (px)</label>
            <select value={qrSize} onChange={e => setQrSize(Number(e.target.value))}
              style={{ padding:"9px 12px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
                fontSize:13, outline:"none", background:C.white }}>
              <option value={150}>150px (Small)</option>
              <option value={200}>200px (Standard)</option>
              <option value={250}>250px (Large)</option>
              <option value={300}>300px (Extra Large)</option>
            </select>
          </div>

          <div style={{ display:"flex", flexDirection:"column", gap:5 }}>
            <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>Template</label>
            <select value={template} onChange={e => setTemplate(e.target.value)}
              style={{ padding:"9px 12px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
                fontSize:13, outline:"none", background:C.white }}>
              {Object.entries(templates).map(([k, v]) => (
                <option key={k} value={k}>{v.name}</option>
              ))}
            </select>
          </div>

          <div style={{ display:"flex", flexDirection:"column", gap:5 }}>
            <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>Grid Columns</label>
            <select value={gridColumns} onChange={e => setGridColumns(Number(e.target.value))}
              style={{ padding:"9px 12px", border:`1.5px solid ${C.fog}`, borderRadius:R.md,
                fontSize:13, outline:"none", background:C.white }}>
              <option value={3}>3 Columns</option>
              <option value={4}>4 Columns</option>
              <option value={5}>5 Columns</option>
              <option value={6}>6 Columns</option>
            </select>
          </div>
        </div>

        {/* Row 2: Colors */}
        <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fit,minmax(160px,1fr))", gap:12, marginBottom:16 }}>
          <div style={{ display:"flex", flexDirection:"column", gap:5 }}>
            <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>QR Color</label>
            <div style={{ display:"flex", gap:8, alignItems:"center" }}>
              <input type="color" value={qrStyle.color} onChange={e=>setQrStyle({...qrStyle,color:e.target.value})}
                style={{ width:40, height:36, borderRadius:R.sm, border:`1px solid ${C.fog}`, cursor:"pointer" }}/>
              <span style={{ fontSize:11, color:C.mist, wordBreak:"break-all" }}>{qrStyle.color}</span>
            </div>
          </div>

          <div style={{ display:"flex", flexDirection:"column", gap:5 }}>
            <label style={{ fontSize:12, fontWeight:600, color:C.slate }}>Background</label>
            <div style={{ display:"flex", gap:8, alignItems:"center" }}>
              <input type="color" value={qrStyle.bg} onChange={e=>setQrStyle({...qrStyle,bg:e.target.value})}
                style={{ width:40, height:36, borderRadius:R.sm, border:`1px solid ${C.fog}`, cursor:"pointer" }}/>
              <span style={{ fontSize:11, color:C.mist, wordBreak:"break-all" }}>{qrStyle.bg}</span>
            </div>
          </div>
        </div>

        {/* Labels Configuration */}
        <div style={{ marginBottom:16 }}>
          <label style={{ display:"flex", alignItems:"center", gap:8, cursor:"pointer", marginBottom:10 }}>
            <input type="checkbox" checked={showLabels} onChange={e => setShowLabels(e.target.checked)}
              style={{ width:16, height:16, cursor:"pointer" }}/>
            <span style={{ fontSize:12, fontWeight:600, color:C.slate }}>Show Labels</span>
          </label>
          {showLabels && (
            <div style={{ display:"flex", gap:12, marginLeft:24, flexWrap:"wrap" }}>
              {["name", "member_code", "branch"].map(field => (
                <label key={field} style={{ display:"flex", alignItems:"center", gap:6, cursor:"pointer" }}>
                  <input type="checkbox" checked={labelFields.includes(field)} 
                    onChange={e => {
                      if (e.target.checked) {
                        setLabelFields([...labelFields, field]);
                      } else {
                        setLabelFields(labelFields.filter(f => f !== field));
                      }
                    }}
                    style={{ width:14, height:14, cursor:"pointer" }}/>
                  <span style={{ fontSize:11, color:C.slate, textTransform:"capitalize" }}>{field}</span>
                </label>
              ))}
            </div>
          )}
        </div>
      </Card>

      {/* ── Search & Filter ── */}
      <Card style={{ marginBottom:16 }}>
        <h3 style={{ margin:"0 0 12px", fontWeight:700, fontSize:14, color:C.ink }}>🔍 Find Members</h3>
        <input type="text" placeholder="Search by name or member code..."
          value={searchQuery} onChange={e => setSearchQuery(e.target.value)}
          style={{ width:"100%", padding:"10px 14px", border:`1.5px solid ${C.cloud}`, borderRadius:R.md,
            fontSize:13, outline:"none", boxSizing:"border-box" }}/>
        
        <div style={{ display:"flex", gap:8, marginTop:12, alignItems:"center" }}>
          <span style={{ fontSize:12, color:C.slate, fontWeight:600 }}>
            {filtered.length} members {selectedMembers.size > 0 ? `(${selectedMembers.size} selected)` : ""}
          </span>
          {filtered.length > 0 && (
            <>
              <button onClick={selectAll}
                style={{ padding:"6px 12px", fontSize:11, background:C.blue3, color:C.blue,
                  border:`1px solid ${C.blue}`, borderRadius:R.md, cursor:"pointer", fontWeight:600 }}>
                Select All
              </button>
              {selectedMembers.size > 0 && (
                <button onClick={clearSelection}
                  style={{ padding:"6px 12px", fontSize:11, background:C.rose3, color:C.rose,
                    border:`1px solid ${C.rose2}`, borderRadius:R.md, cursor:"pointer", fontWeight:600 }}>
                  Clear
                </button>
              )}
            </>
          )}
        </div>
      </Card>

      {/* ── Export Formats ── */}
      <Card style={{ marginBottom:16 }}>
        <h3 style={{ margin:"0 0 16px", fontWeight:700, fontSize:14, color:C.ink }}>📥 Export QR Codes</h3>

        <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fit,minmax(120px,1fr))", gap:10, marginBottom:16 }}>
          {[
            { id: "print", label: "🖨️ Print/Web", fn: generatePrintView },
            { id: "pdf", label: "📄 PDF", fn: exportPdf },
            { id: "png", label: "🖼️ PNG Images", fn: () => downloadAsImages("PNG") },
            { id: "email", label: "📧 Email", fn: sendViaEmail },
          ].map(exp => (
            <button key={exp.id} onClick={exp.fn} disabled={generating || filtered.length === 0}
              style={{ padding:"10px", borderRadius:R.md, background:C.blue, color:C.white,
                border:"none", fontWeight:600, fontSize:12, cursor:generating||filtered.length===0?"not-allowed":"pointer",
                opacity:generating||filtered.length===0?0.6:1 }}>
              {exp.label}
            </button>
          ))}
        </div>

        {generating && (
          <div style={{ marginBottom:16 }}>
            <div style={{ display:"flex", justifyContent:"space-between", marginBottom:6 }}>
              <span style={{ fontSize:12, color:C.slate }}>Generating…</span>
              <span style={{ fontSize:12, fontWeight:700, color:C.blue }}>{progress}%</span>
            </div>
            <div style={{ background:C.fog, borderRadius:R.full, height:8, overflow:"hidden" }}>
              <div style={{ width:`${progress}%`, height:"100%", background:C.blue,
                borderRadius:R.full, transition:"width .3s" }}/>
            </div>
          </div>
        )}
      </Card>

      {/* ── Members List ── */}
      {filtered.length > 0 && (
        <Card>
          <h3 style={{ margin:"0 0 12px", fontWeight:700, fontSize:14, color:C.ink }}>
            👥 Members ({filtered.length})
          </h3>
          <div style={{ display:"flex", flexDirection:"column", gap:6, maxHeight:500, overflowY:"auto" }}>
            {filtered.map(m => (
              <div key={m.id} onClick={() => toggleMemberSelection(m.id)}
                style={{ display:"flex", alignItems:"center", gap:12,
                  padding:"10px 12px", background: selectedMembers.has(m.id) ? C.blue3 : C.fog,
                  borderRadius:R.lg, cursor:"pointer", border: selectedMembers.has(m.id) ? `1.5px solid ${C.blue}` : "none" }}>
                <div style={{ width:18, height:18, borderRadius:4, background:C.white, border:`1.5px solid ${selectedMembers.has(m.id)?C.blue:C.cloud}`,
                  display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                  {selectedMembers.has(m.id) && <span style={{ color:C.blue, fontSize:12, fontWeight:700 }}>✓</span>}
                </div>
                <div style={{ width:32, height:32, borderRadius:"50%", background:C.violet3,
                  display:"flex", alignItems:"center", justifyContent:"center",
                  fontSize:11, fontWeight:700, color:C.violet2, flexShrink:0 }}>
                  {m.name.split(" ").map(w=>w[0]).join("").slice(0,2).toUpperCase()}
                </div>
                <div style={{ flex:1, minWidth:0 }}>
                  <div style={{ fontSize:12, fontWeight:600, color:C.ink }}>{m.name}</div>
                  <div style={{ fontSize:11, color:C.mist }}>{m.member_code} • {m.branches?.name}</div>
                </div>
              </div>
            ))}
          </div>
        </Card>
      )}

      {toast && (
        <Toast msg={toast.msg} type={toast.type} onDone={() => setToast(null)}/>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════
//  GO LIVE PAGE
// ════════════════════════════════════════════════════════════
export default function QRGeneratorPage({ role, user }) {
  const [eventName,   setEventName]   = useState("Sunday Worship Service");
  const [date,        setDate]        = useState(todayDate());
  const [serviceTime, setServiceTime] = useState(defaultServiceTime());
  const [expiry,      setExpiry]      = useState(defaultExpiry());
  const [branch,      setBranch]      = useState("");
  const [branches,    setBranches]    = useState([]);
  useEffect(() => {
  supabase.from("branches").select("id, name").order("name")
    .then(({ data }) => { if (data) setBranches(data); });
}, []);

  const [activeEvent, setActiveEvent] = useState(null);
  const [history,     setHistory]     = useState([]);
  const [qrData,      setQrData]      = useState(null);
  const [loading,     setLoading]     = useState(false);
  const [reopenLoading, setReopenLoading] = useState(false);
  const [loadingPage, setLoadingPage] = useState(true);
  const [toast,       setToast]       = useState(null);
  const [expired,     setExpired]     = useState(false);
  const [timeLeft,    setTimeLeft]    = useState("");

  // Reopen modal state
  const [reopenRow,  setReopenRow]  = useState(null);
  const [reopenOpen, setReopenOpen] = useState(false);
  const [tab, setTab] = useState("live");

  const notify = (msg, type="success") => setToast({ msg, type });

  // ── Build QR image ─────────────────────────────────────────
  const buildQR = useCallback(async (row) => {
    const payload = JSON.stringify({
      event:  row.event,
      date:   row.date,
      time:   row.time,
      expiry: row.expiry,
      branch: row.branch,
      type:   "attendance",
      id:     String(row.id),
    });
    return QRCode.toDataURL(payload, {
      width: 320, margin: 2,
      color: { dark:"#0A0F1E", light:"#FFFFFF" },
      errorCorrectionLevel: "H",
    });
  }, []);

  // ── Fetch events ───────────────────────────────────────────
  const fetchEvents = useCallback(async () => {
  setLoadingPage(true);

  let query = supabase
    .from("service_events").select("*")
    .order("created_at", { ascending:false }).limit(25);

  if (role === "admin" && user?.branchId) {
    const { data: branchData } = await supabase
      .from("branches").select("id, name, parent_id");
    const myBranch = branchData?.find(b => b.id === user.branchId);
    const isSubBranch = !!myBranch?.parent_id;
    const accessibleNames = isSubBranch
      ? [myBranch?.name].filter(Boolean)
      : [myBranch?.name, ...(branchData?.filter(b => b.parent_id === user.branchId) || []).map(b => b.name)].filter(Boolean);
    if (accessibleNames.length > 0) {
      query = query.in("branch", accessibleNames);
    }
  }

  const { data, error } = await query;

    if (error) { notify("Failed to load history: " + error.message, "error"); setLoadingPage(false); return; }

    const rows = data || [];
    const active = rows.find(r => r.is_active);
    setHistory(rows);
    setActiveEvent(active || null);

    if (active) {
      const dataUrl = await buildQR(active);
      setQrData(dataUrl);
      setEventName(active.event);
      setDate(active.date);
      setServiceTime(active.time?.slice(0,5) || defaultServiceTime());
      setExpiry(toLocalDatetimeValue(new Date(active.expiry)));
      setBranch(active.branch);
    } else {
      setQrData(null);
    }
    setLoadingPage(false);
  }, [buildQR, role, user?.branchId]);

  useEffect(() => {
  fetchEvents();
  supabase.from("branches").select("*, parent:parent_id(name)").order("name")
    .then(({ data }) => {
      if (data) {
        setBranches(data);
        if (role === "admin" && user?.branchId) {
          const myBranch = data.find(b => b.id === user.branchId);
          if (myBranch) setBranch(myBranch.name);
        }
      }
    });
}, [fetchEvents]);

  // ── Countdown ──────────────────────────────────────────────
  useEffect(() => {
    if (!activeEvent?.expiry) { setExpired(false); setTimeLeft(""); return; }
    const tick = () => {
      const diff = new Date(activeEvent.expiry).getTime() - Date.now();
      if (diff <= 0) { setExpired(true); setTimeLeft("Expired"); return; }
      setExpired(false);
      const h = Math.floor(diff/3600000);
      const m = Math.floor((diff%3600000)/60000);
      const s = Math.floor((diff%60000)/1000);
      setTimeLeft(`${h>0?h+"h ":""}${m}m ${s}s`);
    };
    tick();
    const id = setInterval(tick,1000);
    return () => clearInterval(id);
  }, [activeEvent]);

  // ── Go Live ────────────────────────────────────────────────
  const goLive = async () => {
    if (!eventName.trim()) { notify("Event name is required","warn"); return; }
    if (!date)             { notify("Date is required","warn"); return; }
    setLoading(true);
    try {
      await supabase.from("service_events").update({ is_active:false }).eq("is_active",true);
      const { data:inserted, error:insErr } = await supabase.from("service_events")
        .insert({ event:eventName.trim(), date, time:serviceTime, branch,
          expiry:new Date(expiry).toISOString(), is_active:true })
        .select().single();
      if (insErr) throw insErr;
      const dataUrl = await buildQR(inserted);
      setQrData(dataUrl);
      setActiveEvent(inserted);
      notify("You're live ✓");
      fetchEvents();
    } catch (err) {
      notify("Failed to go live: " + err.message, "error");
    }
    setLoading(false);
  };

  // ── End Live ───────────────────────────────────────────────
  const endLive = async () => {
    if (!activeEvent) return;
    if (!window.confirm("End this live session? Members won't be able to check in via this QR anymore.")) return;
    setLoading(true);
    const { error } = await supabase.from("service_events")
      .update({ is_active:false }).eq("id", activeEvent.id);
    if (error) notify("Failed to end session: " + error.message,"error");
    else { notify("Live session ended"); setActiveEvent(null); setQrData(null); fetchEvents(); }
    setLoading(false);
  };

  // ── Reopen: set new expiry + reactivate ────────────────────
  const handleReopen = async (row, newExpiry) => {
    setReopenLoading(true);
    try {
      // Deactivate any currently active event
      await supabase.from("service_events").update({ is_active:false }).eq("is_active",true);

      // Reactivate the chosen row with a fresh expiry
      const { data:updated, error:upErr } = await supabase.from("service_events")
        .update({ is_active:true, expiry:new Date(newExpiry).toISOString() })
        .eq("id", row.id)
        .select().single();
      if (upErr) throw upErr;

      const dataUrl = await buildQR(updated);
      setQrData(dataUrl);
      setActiveEvent(updated);

      // Sync form fields so admin can edit and go live again easily
      setEventName(updated.event);
      setDate(updated.date);
      setServiceTime(updated.time?.slice(0,5) || defaultServiceTime());
      setExpiry(toLocalDatetimeValue(new Date(updated.expiry)));
      setBranch(updated.branch);

      notify(`"${updated.event}" is live again ✓`);
      setReopenOpen(false);
      setReopenRow(null);
      fetchEvents();
    } catch (err) {
      notify("Failed to reopen: " + err.message, "error");
    }
    setReopenLoading(false);
  };

  // ── Download / Print ───────────────────────────────────────
  const downloadFor = async (row, dataUrl) => {
    const url = dataUrl || await buildQR(row);
    const link = document.createElement("a");
    link.href = url;
    link.download = `${row.event.replace(/\s+/g,"-")}-QR-${row.date}.png`;
    link.click();
    notify("QR downloaded ✓");
  };

  const printFor = async (row, dataUrl) => {
    const url = dataUrl || await buildQR(row);
    const win = window.open("","_blank");
    win.document.write(`
      <html><head><title>QR – ${row.event}</title>
      <style>
        body { font-family:sans-serif; display:flex; flex-direction:column;
          align-items:center; justify-content:center; min-height:100vh;
          margin:0; padding:24px; box-sizing:border-box; }
        img { width:280px; height:280px; }
        h2 { margin:0 0 4px; font-size:20px; color:#0A0F1E; }
        p  { margin:2px 0; font-size:13px; color:#64748B; }
        .box { border:2px solid #E8EDF5; border-radius:16px; padding:28px 32px; text-align:center; }
      </style></head>
      <body>
        <div class="box">
          <h2>${row.event}</h2>
          <p>${row.date} · ${row.time}</p>
          <p>${row.branch}</p>
          <img src="${url}" alt="QR Code" style="margin:18px 0"/>
          <p style="font-size:11px;color:#94A3B8">Scan to record attendance · Expires ${formatDateTime(row.expiry)}</p>
        </div>
      </body></html>`);
    win.document.close();
    win.print();
  };

  // ════════════════════════════════════════════════════════
  //  RENDER
  // ════════════════════════════════════════════════════════
  return (
    <div>
      {toast && <Toast msg={toast.msg} type={toast.type} onDone={()=>setToast(null)}/>}

      <ReopenModal
        open={reopenOpen}
        row={reopenRow}
        loading={reopenLoading}
        onClose={()=>{ setReopenOpen(false); setReopenRow(null); }}
        onConfirm={handleReopen}
      />

      <h2 style={{ margin:"0 0 16px", fontWeight:800, fontSize:22, color:C.ink, textAlign:"center" }}>
        QR Generator
      </h2>
      <div style={{ display:"flex", gap:8, marginBottom:20, justifyContent:"center" }}>
        <div style={{ display:"flex", gap:8 }}>
          <button onClick={()=>setTab("live")} style={{ padding:"10px 18px", borderRadius:R.full, 
            background:tab==="live"?C.green3:C.fog, color:tab==="live"?C.green:C.slate, 
            border:"none", fontWeight:600, fontSize:13, cursor:"pointer" }}>
            🔴 Go Live
          </button>
          <button onClick={()=>setTab("bulk")} style={{ padding:"10px 18px", borderRadius:R.full, 
            background:tab==="bulk"?C.violet3:C.fog, color:tab==="bulk"?C.violet2:C.slate, 
            border:"none", fontWeight:600, fontSize:13, cursor:"pointer" }}>
            📦 Bulk QR
          </button>
        </div>
      </div>

      {tab === "live" && <>

      <div style={{ display:"grid", gridTemplateColumns:"repeat(auto-fit, minmax(300px, 1fr))",
        gap:20, alignItems:"start" }}>

        {/* ── Left: Configure ───────────────────────────── */}
        <div style={{ background:C.white, borderRadius:R.xl, boxShadow:SH.sm,
          border:`1px solid ${C.fog}`, padding:"24px 24px 20px" }}>
          <h3 style={{ margin:"0 0 20px", fontWeight:700, fontSize:16, color:C.ink, textAlign:"center" }}>
            {activeEvent ? "Update & Go Live" : "Configure Service"}
          </h3>

          <Inp label="Event Name" value={eventName} onChange={setEventName} required/>
          <Inp label="Date" type="date" value={date} onChange={setDate} required/>
          <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:12 }}>
            <Inp label="Service Time" type="time" value={serviceTime} onChange={setServiceTime}/>
            <Inp label="Expiry" type="datetime-local" value={expiry} onChange={setExpiry}/>
          </div>
          <div style={{ display:"flex", flexDirection:"column", gap:5, marginBottom:16 }}>
            <label style={{ fontSize:12, fontWeight:600, color:C.slate, letterSpacing:.2 }}>Branch</label>
            <select value={branch} onChange={e=>setBranch(e.target.value)}
              style={{ padding:"10px 14px", border:`1.5px solid ${C.cloud}`, borderRadius:R.md,
                fontSize:14, outline:"none", background:C.white, color:C.ink }}>
              <option value="">— Select Branch —</option>
              {branches
  .filter(b => !b.parent_id)
  .filter(b => {
    if (role !== "admin") return true;
    const myBranch = branches.find(x => x.id === user?.branchId);
    const isSubBranch = !!myBranch?.parent_id;
    if (isSubBranch) return b.id === myBranch?.parent_id;
    return b.id === user?.branchId;
  })
  .map(b => (
    <optgroup key={b.id} label={b.name}>
      {(!( role === "admin") || branches.find(x=>x.id===user?.branchId)?.id === b.id) && (
        <option value={b.name}>{b.name} (Main)</option>
      )}
      {branches
                .filter(s => s.parent_id === b.id)
                .filter(s => {
                  if (role !== "admin") return true;
                  const myBranch = branches.find(x => x.id === user?.branchId);
                  const isSubBranch = !!myBranch?.parent_id;
                  if (isSubBranch) return s.id === user?.branchId;
                  return true;
                })
                .map(s => (
                  <option key={s.id} value={s.name}>↳ {s.name}</option>
                ))
              }
            </optgroup>
          ))
        }
            </select>
          </div>

          <button onClick={goLive} disabled={loading}
            style={{ width:"100%", padding:"13px 0", borderRadius:R.full,
              background: loading?C.blue3:C.blue, color:C.white, border:"none",
              fontWeight:700, fontSize:15, cursor:loading?"not-allowed":"pointer",
              display:"flex", alignItems:"center", justifyContent:"center", gap:8,
              transition:"background .2s", marginTop:4 }}>
            {loading
              ? <><div style={{ width:16, height:16, border:`2px solid rgba(255,255,255,.4)`,
                  borderTopColor:"#fff", borderRadius:"50%", animation:"spin .7s linear infinite" }}/>
                  {activeEvent?"Updating…":"Going live…"}</>
              : <><span style={{ fontSize:13 }}>🟢</span>{activeEvent?"Go Live Again":"Go Live"}</>}
          </button>

          {activeEvent && (
            <button onClick={endLive} disabled={loading}
              style={{ width:"100%", padding:"11px 0", borderRadius:R.full, background:C.white,
                color:C.rose2, border:`1.5px solid ${C.rose3}`, fontWeight:600,
                fontSize:13, cursor:"pointer", marginTop:10 }}>
              End Live Session
            </button>
          )}
          <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
        </div>

        {/* ── Right: QR Preview ─────────────────────────── */}
        <div style={{ background:C.white, borderRadius:R.xl, boxShadow:SH.sm,
          border:`1px solid ${C.fog}`, padding:"24px", minHeight:420,
          display:"flex", flexDirection:"column", alignItems:"center",
          justifyContent:"center", gap:16 }}>

          {loadingPage ? (
            <div style={{ textAlign:"center", color:C.mist }}>
              <Spinner/>
              <div style={{ marginTop:12, fontSize:14 }}>Loading…</div>
            </div>
          ) : !activeEvent ? (
            <div style={{ textAlign:"center", color:C.mist }}>
              <div style={{ width:72, height:72, borderRadius:"50%", background:C.fog,
                display:"flex", alignItems:"center", justifyContent:"center", margin:"0 auto 16px" }}>
                <svg width={32} height={32} viewBox="0 0 24 24" fill="none" stroke={C.cloud}
                  strokeWidth={1.5} strokeLinecap="round">
                  <rect x="3" y="3" width="7" height="7" rx="1"/>
                  <rect x="14" y="3" width="7" height="7" rx="1"/>
                  <rect x="3" y="14" width="7" height="7" rx="1"/>
                  <rect x="5" y="5" width="3" height="3"/>
                  <rect x="16" y="5" width="3" height="3"/>
                  <rect x="5" y="16" width="3" height="3"/>
                </svg>
              </div>
              <div style={{ fontSize:14, color:C.mist, maxWidth:200, lineHeight:1.5 }}>
                Configure a service and go live to generate a QR code for attendance
              </div>
            </div>
          ) : (
            <>
              <div style={{ textAlign:"center" }}>
                <div style={{ fontWeight:800, fontSize:17, color:C.ink }}>{activeEvent.event}</div>
                <div style={{ fontSize:12, color:C.mist, marginTop:2 }}>
                  {activeEvent.date} · {activeEvent.time?.slice(0,5)} · {activeEvent.branch}
                </div>
              </div>

              <div style={{ position:"relative", padding:16, border:`1.5px solid ${C.fog}`,
                borderRadius:R.lg, background:C.white, boxShadow:SH.sm }}>
                {expired && (
                  <div style={{ position:"absolute", inset:0, background:"rgba(255,255,255,.88)",
                    borderRadius:R.lg, display:"flex", flexDirection:"column",
                    alignItems:"center", justifyContent:"center", zIndex:2, gap:6 }}>
                    <span style={{ fontSize:28 }}>⏰</span>
                    <span style={{ fontWeight:700, color:C.rose, fontSize:14 }}>QR Expired</span>
                    <button onClick={()=>{ setReopenRow(activeEvent); setReopenOpen(true); }}
                      style={{ marginTop:6, padding:"7px 18px", background:C.amber2, color:C.white,
                        border:"none", borderRadius:R.full, fontWeight:700, fontSize:12,
                        cursor:"pointer" }}>
                      🔓 Reopen
                    </button>
                  </div>
                )}
                {qrData && (
                  <img src={qrData} alt="QR Code"
                    style={{ display:"block", width:220, height:220,
                      filter:expired?"grayscale(1) opacity(.4)":"none", transition:"filter .3s" }}/>
                )}
              </div>

              <div style={{ display:"flex", alignItems:"center", gap:6,
                background:expired?C.rose3:C.green3, borderRadius:R.full, padding:"6px 14px" }}>
                <span style={{ fontSize:11 }}>{expired?"⛔":"🟢"}</span>
                <span style={{ fontSize:12, fontWeight:600, color:expired?C.rose:C.green }}>
                  {expired?"Expired":`Live · expires in ${timeLeft}`}
                </span>
              </div>

              <div style={{ display:"flex", gap:8, flexWrap:"wrap", justifyContent:"center" }}>
                <button onClick={()=>downloadFor(activeEvent, qrData)}
                  style={{ display:"flex", alignItems:"center", gap:6, padding:"9px 18px",
                    borderRadius:R.full, background:C.blue, color:C.white, border:"none",
                    fontWeight:600, fontSize:13, cursor:"pointer" }}>
                  <svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round"><polyline points="21 15 16 20 11 15"/><line x1="16" y1="4" x2="16" y2="20"/></svg>
                  Download
                </button>
                <button onClick={()=>printFor(activeEvent, qrData)}
                  style={{ display:"flex", alignItems:"center", gap:6, padding:"9px 18px",
                    borderRadius:R.full, background:C.white, color:C.slate,
                    border:`1.5px solid ${C.cloud}`, fontWeight:600, fontSize:13, cursor:"pointer" }}>
                  <svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 01-2-2v-5a2 2 0 012-2h16a2 2 0 012 2v5a2 2 0 01-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
                  Print
                </button>
                {expired && (
                  <button onClick={()=>{ setReopenRow(activeEvent); setReopenOpen(true); }}
                    style={{ display:"flex", alignItems:"center", gap:6, padding:"9px 18px",
                      borderRadius:R.full, background:C.amber2, color:C.white, border:"none",
                      fontWeight:600, fontSize:13, cursor:"pointer" }}>
                    🔓 Reopen
                  </button>
                )}
              </div>

              <div style={{ background:C.fog, borderRadius:R.md, padding:"10px 14px",
                fontSize:11, color:C.mist, textAlign:"center", maxWidth:300, lineHeight:1.6 }}>
                This QR encodes event, date, time, branch & expiry. Members scan it to mark attendance.
              </div>
            </>
          )}
        </div>
      </div>

      {/* ── History ───────────────────────────────────────────── */}
      <div style={{ marginTop:28 }}>
        <h3 style={{ margin:"0 0 14px", fontWeight:800, fontSize:16, color:C.ink }}>
          Go Live History
        </h3>

        {loadingPage ? (
          <div style={{ textAlign:"center", padding:"30px 0", color:C.mist }}><Spinner/></div>
        ) : history.length === 0 ? (
          <div style={{ textAlign:"center", padding:"40px 0", color:C.mist, fontSize:13 }}>
            No services have gone live yet.
          </div>
        ) : (
          <div style={{ background:C.white, borderRadius:R.xl, boxShadow:SH.sm,
            border:`1px solid ${C.fog}`, overflow:"hidden" }}>
            <div style={{ overflowX:"auto" }}>
              <table style={{ width:"100%", borderCollapse:"collapse", fontSize:13 }}>
                <thead>
                  <tr style={{ background:C.fog }}>
                    {["Event","Date","Time","Branch","Expiry","Status","Actions"].map(h=>(
                      <th key={h} style={{ textAlign:"left", padding:"10px 14px", color:C.slate,
                        fontWeight:600, fontSize:11, textTransform:"uppercase", letterSpacing:.4,
                        whiteSpace:"nowrap" }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {history.map(row => {
                    const isExpired = new Date(row.expiry).getTime() < Date.now();
                    const isLive    = row.is_active && !isExpired;
                    const isEnded   = !row.is_active;
                    const canReopen = isExpired || isEnded;

                    return (
                      <tr key={row.id} style={{ borderTop:`1px solid ${C.fog}`,
                        background: isLive ? `${C.green}05` : C.white }}>
                        <td style={{ padding:"10px 14px", fontWeight:600, color:C.ink }}>{row.event}</td>
                        <td style={{ padding:"10px 14px", color:C.slate }}>{row.date}</td>
                        <td style={{ padding:"10px 14px", color:C.slate }}>{row.time?.slice(0,5)}</td>
                        <td style={{ padding:"10px 14px", color:C.slate, fontSize:12 }}>
                          {(row.branch||"").split("–")[0].trim()}
                        </td>
                        <td style={{ padding:"10px 14px", color:C.slate, fontSize:12 }}>
                          {formatDateTime(row.expiry)}
                        </td>
                        <td style={{ padding:"10px 14px" }}>
                          {isLive
                            ? <Badge label="🟢 Live"   color={C.green}/>
                            : isExpired && row.is_active
                            ? <Badge label="⏰ Expired" color={C.rose2}/>
                            : <Badge label="Ended"     color={C.mist}/>}
                        </td>
                        <td style={{ padding:"10px 14px" }}>
                          <div style={{ display:"flex", gap:6, flexWrap:"wrap" }}>
                            <button onClick={()=>downloadFor(row)}
                              style={{ padding:"6px 12px", borderRadius:R.full, background:C.white,
                                color:C.blue, border:`1.5px solid ${C.blue3}`, fontWeight:600,
                                fontSize:12, cursor:"pointer" }}>
                              Download
                            </button>
                            <button onClick={()=>printFor(row)}
                              style={{ padding:"6px 12px", borderRadius:R.full, background:C.white,
                                color:C.slate, border:`1.5px solid ${C.cloud}`, fontWeight:600,
                                fontSize:12, cursor:"pointer" }}>
                              Print
                            </button>
                            {canReopen && (
                              <button onClick={()=>{ setReopenRow(row); setReopenOpen(true); }}
                                style={{ padding:"6px 12px", borderRadius:R.full,
                                  background:C.amber3, color:C.amber,
                                  border:`1.5px solid ${C.amber2}`, fontWeight:700,
                                  fontSize:12, cursor:"pointer" }}>
                                🔓 Reopen
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
        </div>
        </>}
          {tab === "bulk" && (
        <BulkQRTab role={role} user={user} branches={branches}/>
      )}
    </div>
  );
}
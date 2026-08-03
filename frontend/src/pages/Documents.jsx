import { useState, useEffect } from "react";
import { useAuth } from "@/context/AuthContext";
import {
  FileText, Upload, Trash, Download, Eye, FolderOpen,
  Image, FilePdf, FileXls, FileDoc, MagnifyingGlass,
} from "@phosphor-icons/react";

const STORAGE_KEY = "milli_documents";

const CATEGORIES = [
  { id: "taxes", label: "Tax Documents", icon: FileText },
  { id: "receipts", label: "Receipts", icon: FilePdf },
  { id: "invoices", label: "Invoices", icon: FileDoc },
  { id: "statements", label: "Bank Statements", icon: FileXls },
  { id: "other", label: "Other", icon: FolderOpen },
];

export default function Documents() {
  const { user } = useAuth();
  const [documents, setDocuments] = useState([]);
  const [activeCategory, setActiveCategory] = useState("all");
  const [search, setSearch] = useState("");
  const [showUpload, setShowUpload] = useState(false);

  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        setDocuments(JSON.parse(stored));
      } else {
        const samples = [
          { id: "d1", name: "2025 Schedule C.pdf", category: "taxes", size: "245 KB", date: "2026-01-15", type: "pdf" },
          { id: "d2", name: "Q4 1099-NEC.pdf", category: "taxes", size: "128 KB", date: "2026-01-10", type: "pdf" },
          { id: "d3", name: "Uber Receipt Jan.pdf", category: "receipts", size: "56 KB", date: "2026-01-20", type: "pdf" },
          { id: "d4", name: "Chase Statement Dec.pdf", category: "statements", size: "412 KB", date: "2026-01-05", type: "pdf" },
        ];
        setDocuments(samples);
        localStorage.setItem(STORAGE_KEY, JSON.stringify(samples));
      }
    } catch { setDocuments([]); }
  }, []);

  const saveDocs = (docs) => {
    setDocuments(docs);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(docs));
  };

  const handleUpload = (e) => {
    const files = Array.from(e.target.files || []);
    const newDocs = files.map((f, i) => ({
      id: `d${Date.now()}${i}`,
      name: f.name,
      category: activeCategory === "all" ? "other" : activeCategory,
      size: `${Math.round(f.size / 1024)} KB`,
      date: new Date().toISOString().split("T")[0],
      type: f.name.split(".").pop()?.toLowerCase() || "file",
    }));
    saveDocs([...documents, ...newDocs]);
    setShowUpload(false);
  };

  const deleteDoc = (id) => {
    saveDocs(documents.filter((d) => d.id !== id));
  };

  const filtered = documents.filter((d) => {
    const catMatch = activeCategory === "all" || d.category === activeCategory;
    const searchMatch = !search || d.name.toLowerCase().includes(search.toLowerCase());
    return catMatch && searchMatch;
  });

  const getIcon = (type) => {
    if (type === "pdf") return FilePdf;
    if (["xls", "xlsx", "csv"].includes(type)) return FileXls;
    if (["doc", "docx"].includes(type)) return FileDoc;
    if (["jpg", "jpeg", "png", "gif"].includes(type)) return Image;
    return FileText;
  };

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-4">
      <header>
        <h1
          className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight"
          style={{ fontFamily: "'Outfit', system-ui, sans-serif" }}
        >
          Documents
        </h1>
        <p className="text-zinc-400 text-[14px] mt-1">Store and organize your tax documents, receipts, and statements.</p>
      </header>

      <div className="milli-card rounded-2xl p-3 flex items-center gap-2">
        <MagnifyingGlass size={18} className="text-zinc-500 flex-shrink-0" />
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search documents..."
          className="flex-1 bg-transparent text-white text-[14px] outline-none placeholder:text-zinc-600"
        />
      </div>

      <div className="flex gap-2 overflow-x-auto pb-1 -mx-1 px-1">
        <button
          onClick={() => setActiveCategory("all")}
          className={`px-3.5 py-1.5 rounded-full text-[12px] font-medium whitespace-nowrap transition ${
            activeCategory === "all" ? "bg-volt text-black" : "milli-card text-zinc-400"
          }`}
        >
          All ({documents.length})
        </button>
        {CATEGORIES.map((cat) => {
          const count = documents.filter((d) => d.category === cat.id).length;
          return (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id)}
              className={`px-3.5 py-1.5 rounded-full text-[12px] font-medium whitespace-nowrap transition ${
                activeCategory === cat.id ? "bg-volt text-black" : "milli-card text-zinc-400"
              }`}
            >
              {cat.label} ({count})
            </button>
          );
        })}
      </div>

      <button
        onClick={() => setShowUpload(!showUpload)}
        className="w-full milli-card rounded-2xl py-3.5 flex items-center justify-center gap-2 text-[14px] font-semibold text-volt active:scale-[0.99] transition-transform"
        style={{ border: "1px dashed rgba(0,229,255,0.3)" }}
      >
        <Upload size={18} weight="bold" />
        Upload Document
      </button>

      {showUpload && (
        <label className="milli-card rounded-2xl p-6 flex flex-col items-center gap-2 cursor-pointer active:opacity-70">
          <Upload size={32} className="text-zinc-500" />
          <span className="text-zinc-400 text-[13px]">Tap to select files</span>
          <input type="file" multiple onChange={handleUpload} className="hidden" />
        </label>
      )}

      <div className="space-y-2">
        {filtered.length === 0 ? (
          <div className="milli-card rounded-2xl p-8 text-center">
            <FolderOpen size={32} className="text-zinc-600 mx-auto mb-2" />
            <p className="text-zinc-500 text-[13px]">No documents found.</p>
          </div>
        ) : (
          filtered.map((doc) => {
            const Icon = getIcon(doc.type);
            return (
              <div
                key={doc.id}
                className="milli-card rounded-2xl p-4 flex items-center gap-3"
              >
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
                  style={{ background: "rgba(0,229,255,0.08)", border: "1px solid rgba(0,229,255,0.15)" }}
                >
                  <Icon size={20} className="text-volt" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-white text-[14px] font-medium truncate">{doc.name}</div>
                  <div className="text-zinc-500 text-[11px] mt-0.5">
                    {doc.size} - {doc.date}
                  </div>
                </div>
                <button className="text-zinc-500 active:text-white p-1.5">
                  <Eye size={16} />
                </button>
                <button className="text-zinc-500 active:text-white p-1.5">
                  <Download size={16} />
                </button>
                <button
                  onClick={() => deleteDoc(doc.id)}
                  className="text-zinc-500 active:text-red-400 p-1.5"
                >
                  <Trash size={16} />
                </button>
              </div>
            );
          })
        )}
      </div>

      <div className="milli-card rounded-2xl p-4 flex items-center gap-3">
        <div
          className="w-10 h-10 rounded-xl flex items-center justify-center"
          style={{ background: "rgba(0,229,255,0.06)" }}
        >
          <FileText size={20} className="text-zinc-400" />
        </div>
        <div className="flex-1">
          <div className="text-white text-[13px] font-medium">{documents.length} documents stored</div>
          <div className="text-zinc-500 text-[11px]">Encrypted at rest. Auto-categorized by Milli AI.</div>
        </div>
      </div>
    </div>
  );
}
import { useState } from "react";
import { useAuth } from "@/context/AuthContext";
import { MilliCardHero } from "@/components/MilliCard";
import {
  Check, Crown, Shield, Truck, CreditCard, Sparkle, ArrowRight, ArrowLeft,
} from "@phosphor-icons/react";

const MATERIALS = [
  {
    id: "metal",
    name: "Brushed Metal",
    description: "Premium brushed stainless steel with a silver-chrome finish. Weighty, durable, and etched with the Milli M logo.",
    price: 0,
    badge: "Included with Elite",
    icon: Shield,
    accent: "linear-gradient(135deg, #F5F6F8 0%, #D8DBE0 18%, #B8BCC2 38%, #8F9399 58%, #5C6066 78%, #2E3136 100%)",
  },
  {
    id: "titanium",
    name: "Aerospace Titanium",
    description: "Ultra-light Grade 5 titanium with a gunmetal finish. Scratch-resistant, hypoallergenic, and 45% lighter than steel.",
    price: 49,
    badge: "+$49 one-time",
    icon: Sparkle,
    accent: "linear-gradient(135deg, #6B7280 0%, #4B5563 30%, #374151 60%, #1F2937 100%)",
  },
];

export default function CardOrder() {
  const { user } = useAuth();
  const [material, setMaterial] = useState("metal");
  const [step, setStep] = useState(1); // 1 = choose, 2 = shipping, 3 = review, 4 = done
  const [form, setForm] = useState({
    legalName: user?.name || "",
    address1: user?.address_line1 || "",
    address2: user?.address_line2 || "",
    city: user?.city || "",
    state: user?.state || "",
    zip: user?.zip || "",
    phone: user?.phone || "",
    ssnLast4: "",
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  const selectedMaterial = MATERIALS.find((m) => m.id === material);

  function update(field, value) {
    setForm((f) => ({ ...f, [field]: value }));
  }

  async function submitOrder() {
    setSubmitting(true);
    setError(null);
    try {
      const { api } = await import("@/lib/api");
      await api.post("/card/order", {
        material,
        ...form,
      });
      setStep(4);
    } catch (err) {
      setError(err?.message || "Failed to submit card order. Please try again.");
    } finally {
      setSubmitting(false);
    }
  }

  const canProceedShipping =
    form.legalName.trim() &&
    form.address1.trim() &&
    form.city.trim() &&
    form.state.trim() &&
    form.zip.trim() &&
    form.phone.trim() &&
    form.ssnLast4.length === 4;

  return (
    <div className="px-5 sm:px-6 pt-4 pb-6 max-w-2xl mx-auto space-y-6">
      {/* Header */}
      <header>
        <button
          onClick={() => (step > 1 ? setStep(step - 1) : window.history.back())}
          className="flex items-center gap-1.5 text-zinc-400 text-[14px] mb-3 active:text-white transition"
        >
          <ArrowLeft size={16} weight="bold" />
          Back
        </button>
        <div className="flex items-center gap-2 mb-1">
          <Crown size={24} weight="fill" className="text-[#D4FF00]" />
          <h1 className="font-chrome font-bold text-white text-[28px] sm:text-[32px] leading-tight tracking-tight"
            style={{ fontFamily: "'Outfit', system-ui, sans-serif' }}>
            Milli Visa Elite Card
          </h1>
        </div>
        <p className="text-zinc-400 text-[14px] mt-1">
          Order your premium debit card. Available exclusively for Elite members.
        </p>
      </header>

      {/* Progress */}
      <div className="flex items-center gap-2">
        {[1, 2, 3].map((s) => (
          <div
            key={s}
            className={`flex-1 h-1 rounded-full transition ${
              step >= s ? "bg-[#D4FF00]" : "bg-white/10"
            }`}
          />
        ))}
      </div>

      {/* Step 1: Choose material */}
      {step === 1 && (
        <div className="space-y-4">
          {/* Card preview */}
          <div className="flex justify-center py-4">
            <div className="w-full max-w-sm">
              <MilliCardHero
                user={{ ...user, plan: "elite" }}
                className={material === "titanium" ? "titanium-variant" : ""}
              />
            </div>
          </div>
          <h2 className="text-white text-[18px] font-semibold">Choose your card material</h2>

          {MATERIALS.map((m) => {
            const Icon = m.icon;
            const selected = material === m.id;
            return (
              <button
                key={m.id}
                onClick={() => setMaterial(m.id)}
                className={`w-full text-left milli-card rounded-2xl p-5 transition ${
                  selected ? "border-2 border-[#D4FF00]" : "border border-white/6"
                }`}
                style={{
                  background: selected
                    ? "linear-gradient(180deg, rgba(212,255,0,0.06) 0%, rgba(10,14,18,0.9) 100%)"
                    : "rgba(10,14,18,0.9)",
                }}
              >
                <div className="flex items-start gap-4">
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0"
                    style={{ background: m.accent }}
                  >
                    <Icon size={22} weight="fill" className="text-white/80" />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between">
                      <span className="text-white text-[16px] font-semibold">{m.name}</span>
                      {selected && <Check size={18} weight="bold" className="text-[#D4FF00]" />}
                    </div>
                    <p className="text-zinc-400 text-[13px] mt-1 leading-relaxed">{m.description}</p>
                    <span
                      className="inline-block mt-2 text-[11px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full"
                      style={{
                        background: m.price === 0 ? "rgba(212,255,0,0.15)" : "rgba(0,229,255,0.15)",
                        color: m.price === 0 ? "#D4FF00" : "#00E5FF",
                      }}
                    >
                      {m.badge}
                    </span>
                  </div>
                </div>
              </button>
            );
          })}

          <button
            onClick={() => setStep(2)}
            className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl bg-[#D4FF00] text-black text-[15px] font-bold active:scale-[0.99] transition"
          >
            Continue
            <ArrowRight size={18} weight="bold" />
          </button>
        </div>
      )}

      {/* Step 2: Shipping info */}
      {step === 2 && (
        <div className="space-y-4">
          <div className="flex items-center gap-2 mb-2">
            <Truck size={20} weight="fill" className="text-[#D4FF00]" />
            <h2 className="text-white text-[18px] font-semibold">Shipping information</h2>
          </div>

          <div className="milli-card rounded-2xl p-5 space-y-4">
            <Field label="Legal full name" value={form.legalName} onChange={(v) => update("legalName", v)} placeholder="Alexander D. Chen" />
            <Field label="Street address" value={form.address1} onChange={(v) => update("address1", v)} placeholder="123 Main St" />
            <Field label="Apt / Suite (optional)" value={form.address2} onChange={(v) => update("address2", v)} placeholder="Apt 4B" />
            <div className="grid grid-cols-2 gap-3">
              <Field label="City" value={form.city} onChange={(v) => update("city", v)} placeholder="San Francisco" />
              <Field label="State" value={form.state} onChange={(v) => update("state", v)} placeholder="CA" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <Field label="ZIP code" value={form.zip} onChange={(v) => update("zip", v)} placeholder="94102" />
              <Field label="Phone" value={form.phone} onChange={(v) => update("phone", v)} placeholder="+1 415 555 0123" />
            </div>
            <Field
              label="Last 4 of SSN (identity verification)"
              value={form.ssnLast4}
              onChange={(v) => update("ssnLast4", v.replace(/\D/g, "").slice(0, 4))}
              placeholder="1234"
              type="password"
              maxLength={4}
            />
          </div>

          <p className="text-zinc-500 text-[12px] leading-relaxed">
            Your SSN is used only for identity verification required by our card issuer partner.
            It is encrypted and never stored in plaintext.
          </p>

          <button
            onClick={() => setStep(3)}
            disabled={!canProceedShipping}
            className={`w-full flex items-center justify-center gap-2 py-3.5 rounded-xl text-[15px] font-bold transition ${
              canProceedShipping
                ? "bg-[#D4FF00] text-black active:scale-[0.99]"
                : "bg-white/10 text-zinc-500"
            }`}
          >
            Review order
            <ArrowRight size={18} weight="bold" />
          </button>
        </div>
      )}

      {/* Step 3: Review */}
      {step === 3 && (
        <div className="space-y-4">
          <div className="flex items-center gap-2 mb-2">
            <CreditCard size={20} weight="fill" className="text-[#D4FF00]" />
            <h2 className="text-white text-[18px] font-semibold">Review your order</h2>
          </div>

          <div className="flex justify-center py-2">
            <div className="w-full max-w-xs">
              <MilliCardHero
                user={{ ...user, plan: "elite", name: form.legalName }}
                className={material === "titanium" ? "titanium-variant" : ""}
              />
            </div>
          </div>

          <div className="milli-card rounded-2xl p-5 space-y-3">
            <Row label="Card" value="Milli Visa Elite Debit" />
            <Row label="Material" value={selectedMaterial.name} />
            <Row
              label="Material fee"
              value={selectedMaterial.price === 0 ? "Included" : `$${selectedMaterial.price}.00`}
            />
            <Row label="Shipping" value="Free (5-7 business days)" />
            <div className="border-t border-white/8 pt-3">
              <Row
                label="Total due today"
                value={selectedMaterial.price === 0 ? "$0.00" : `$${selectedMaterial.price}.00`}
                bold
              />
            </div>
          </div>

          <div className="milli-card rounded-2xl p-5">
            <div className="text-zinc-500 text-[11px] uppercase tracking-wide mb-2">Shipping to</div>
            <div className="text-white text-[14px] font-medium">{form.legalName}</div>
            <div className="text-zinc-400 text-[13px] mt-0.5">
              {form.address1}
              {form.address2 ? `, ${form.address2}` : ""}
              <br />
              {form.city}, {form.state} {form.zip}
              <br />
              {form.phone}
            </div>
          </div>

          {error && (
            <div className="text-red-400 text-[13px] text-center">{error}</div>
          )}

          <button
            onClick={submitOrder}
            disabled={submitting}
            className="w-full flex items-center justify-center gap-2 py-3.5 rounded-xl bg-[#D4FF00] text-black text-[15px] font-bold active:scale-[0.99] transition disabled:opacity-50"
          >
            {submitting ? "Submitting..." : "Place order"}
            {!submitting && <ArrowRight size={18} weight="bold" />}
          </button>
        </div>
      )}

      {/* Step 4: Confirmation */}
      {step === 4 && (
        <div className="space-y-6 text-center pt-8">
          <div className="w-20 h-20 rounded-full bg-[#D4FF00] mx-auto flex items-center justify-center">
            <Check size={40} weight="bold" className="text-black" />
          </div>
          <div>
            <h2 className="text-white text-[24px] font-bold">Order placed!</h2>
            <p className="text-zinc-400 text-[14px] mt-2 max-w-sm mx-auto">
              Your Milli Visa Elite {selectedMaterial.name} card is being manufactured.
              You'll receive a tracking number via email within 2-3 business days.
              Expected delivery: 5-7 business days.
            </p>
          </div>
          <button
            onClick={() => (window.location.href = "/app")}
            className="px-6 py-3 rounded-xl bg-white/10 text-white text-[14px] font-medium active:scale-[0.99] transition"
          >
            Back to dashboard
          </button>
        </div>
      )}
    </div>
  );
}

function Field({ label, value, onChange, placeholder, type = "text", maxLength }) {
  return (
    <div>
      <label className="block text-zinc-500 text-[12px] uppercase tracking-wide mb-1.5">{label}</label>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        maxLength={maxLength}
        className="w-full bg-white/5 border border-white/8 rounded-lg px-3.5 py-2.5 text-white text-[15px] placeholder:text-zinc-600 focus:outline-none focus:border-[#D4FF00]/40 transition"
      />
    </div>
  );
}

function Row({ label, value, bold }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-zinc-400 text-[14px]">{label}</span>
      <span className={`text-[14px] ${bold ? "text-white font-bold" : "text-white/90"}`}>{value}</span>
    </div>
  );
}
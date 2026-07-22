/**
 * useStoreKit — Capacitor 7 IAP hook backed by StoreKit 2.
 *
 * On native iOS it uses @capgo/native-purchases (real StoreKit 2 flow).
 * On the web preview it falls back to mocked products so the paywall
 * still renders and the /verify-receipt endpoint can be exercised.
 */
import { useCallback, useEffect, useRef, useState } from "react";
import { Capacitor } from "@capacitor/core";
import { api } from "@/lib/api";

export const IAP_PRODUCTS = [
  {
    id: "milli.basic.monthly",
    plan: "basic",
    name: "Basic",
    price: 19.99,
    priceDisplay: "$19.99",
    tagline: "Track everything.",
    features: [
      "Auto mileage tracking",
      "Expense log",
      "Tax Ready Score™",
      "Quarterly reminders",
      "Milli AI (basic)",
    ],
  },
  {
    id: "milli.pro.monthly",
    plan: "pro",
    name: "Pro",
    price: 29.99,
    priceDisplay: "$29.99",
    tagline: "Full autopilot.",
    featured: true,
    features: [
      "Everything in Basic",
      "AI Receipt OCR",
      "Milli Autopilot™",
      "Income categorization",
      "Tax projections",
    ],
  },
  {
    id: "milli.elite.monthly",
    plan: "elite",
    name: "Elite",
    price: 49.99,
    priceDisplay: "$49.99",
    tagline: "Done-for-you filing.",
    features: [
      "Everything in Pro",
      "Milli Tax Vault™",
      "Solo 401(k) tracking",
      "Federal + State auto-filing",
      "Priority support",
      "Multi-vehicle analytics",
    ],
  },
];

export function useStoreKit() {
  const [products, setProducts] = useState(IAP_PRODUCTS);
  const [loading, setLoading] = useState(false);
  const [purchasing, setPurchasing] = useState(null);
  const [error, setError] = useState(null);
  const nativeRef = useRef(null);

  const isNative = Capacitor.isNativePlatform();

  // Lazy-load the native plugin only on iOS to keep the web bundle slim.
  const getPlugin = useCallback(async () => {
    if (nativeRef.current) return nativeRef.current;
    if (!isNative) return null;
    const mod = await import("@capgo/native-purchases");
    nativeRef.current = mod.NativePurchases;
    return nativeRef.current;
  }, [isNative]);

  // Fetch localized product data from Apple (falls back to hardcoded on web).
  const fetchProducts = useCallback(async () => {
    if (!isNative) return;
    setLoading(true);
    try {
      const plugin = await getPlugin();
      const { products: native } = await plugin.getProducts({
        productIdentifiers: IAP_PRODUCTS.map((p) => p.id),
      });
      // Merge Apple's localized prices onto our tier metadata
      const merged = IAP_PRODUCTS.map((tier) => {
        const found = native.find((n) => n.identifier === tier.id);
        return found ? { ...tier, priceDisplay: found.priceString || tier.priceDisplay } : tier;
      });
      setProducts(merged);
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setLoading(false);
    }
  }, [isNative, getPlugin]);

  // Purchase → wait for listener → validate on backend → acknowledge.
  const purchase = useCallback(
    async (productId) => {
      setError(null);
      setPurchasing(productId);
      try {
        if (isNative) {
          const plugin = await getPlugin();
          await plugin.purchaseProduct({ productIdentifier: productId });
          // Listener wired below handles /verify-receipt + acknowledge
        } else {
          // Web fallback — dev-only shortcut that still hits the backend
          // to prove the /verify-receipt route works end-to-end.
          await api.post("/subscriptions/verify-receipt", {
            transactionId: `web-mock-${Date.now()}`,
            productId,
          });
        }
        return { ok: true };
      } catch (e) {
        setError(e.message || String(e));
        return { ok: false, error: e };
      } finally {
        setPurchasing(null);
      }
    },
    [isNative, getPlugin]
  );

  const restore = useCallback(async () => {
    if (!isNative) return { restored: 0 };
    try {
      const plugin = await getPlugin();
      const txs = (await plugin.restorePurchases()) || [];
      for (const t of txs) {
        if (t.transactionId) {
          await api.post("/subscriptions/verify-receipt", {
            transactionId: t.transactionId,
            productId: t.productIdentifier,
          });
        }
      }
      return { restored: txs.length };
    } catch (e) {
      setError(e.message || String(e));
      return { restored: 0, error: e };
    }
  }, [isNative, getPlugin]);

  // Attach a persistent transactionUpdated listener (native only)
  useEffect(() => {
    if (!isNative) return;
    let sub;
    (async () => {
      const plugin = await getPlugin();
      sub = await plugin.addListener("transactionUpdated", async (tx) => {
        if (!tx?.transactionId) return;
        try {
          await api.post("/subscriptions/verify-receipt", {
            transactionId: tx.transactionId,
            productId: tx.productIdentifier,
          });
          // Acknowledge so Apple stops re-delivering this event on cold start
          await plugin.acknowledgePurchase({ transactionId: tx.transactionId });
        } catch (e) {
          setError(e.message || String(e));
        }
      });
    })();
    return () => { sub?.remove?.(); };
  }, [isNative, getPlugin]);

  useEffect(() => { fetchProducts(); }, [fetchProducts]);

  return { products, loading, purchasing, error, purchase, restore, isNative };
}

"""
Milli — Live Market data.

Uses yfinance (no API key required) to fetch:
  * S&P 500 quote + intraday history for the Market Overview
  * Top gainers / losers / most-actives from a curated watchlist universe
  * Individual quotes for user watchlists

If yfinance is offline or rate-limited, endpoints degrade to a cached
seed so the UI never breaks.
"""
from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
import asyncio

import yfinance as yf

# Universe used for movers — top 20 mega/large caps + popular tickers with drivers
UNIVERSE = [
    "AAPL","MSFT","NVDA","GOOGL","AMZN","META","TSLA","AVGO","BRK-B","LLY",
    "JPM","V","XOM","UNH","MA","PG","JNJ","HD","MRK","ABBV",
    "COST","NFLX","AMD","BAC","CRM","KO","PEP","MCD","DIS","WMT",
]

_cache: dict[str, Any] = {"movers": None, "at": 0}


def _quote_to_dict(t: str, info: dict[str, Any], hist_prev_close: float | None = None) -> dict[str, Any]:
    price = info.get("regularMarketPrice") or info.get("last_price") or info.get("currentPrice")
    prev  = info.get("regularMarketPreviousClose") or hist_prev_close or price
    change = (price - prev) if (price is not None and prev is not None) else 0
    pct    = (change / prev * 100) if prev else 0
    return {
        "ticker": t,
        "name":   info.get("shortName") or info.get("longName") or t,
        "price":  round(price or 0, 2),
        "prev_close": round(prev or 0, 2),
        "change":     round(change or 0, 2),
        "change_pct": round(pct, 2),
        "volume":     int(info.get("regularMarketVolume") or 0),
    }


def _fast_quote(ticker: str) -> dict[str, Any]:
    """Quick quote (fast_info + short history) — used in list contexts."""
    try:
        t = yf.Ticker(ticker)
        fi = t.fast_info or {}
        price = fi.get("last_price") or fi.get("regular_market_price")
        prev  = fi.get("previous_close") or fi.get("regular_market_previous_close")
        change = (price - prev) if (price and prev) else 0
        pct    = (change / prev * 100) if prev else 0
        return {
            "ticker": ticker,
            "name":   (t.info.get("shortName") if hasattr(t, "info") else None) or ticker,
            "price":  round(price or 0, 2),
            "prev_close": round(prev or 0, 2),
            "change":     round(change or 0, 2),
            "change_pct": round(pct, 2),
        }
    except Exception:
        return {"ticker": ticker, "name": ticker, "price": 0, "prev_close": 0, "change": 0, "change_pct": 0}


async def get_market_overview(range_: str = "1d") -> dict[str, Any]:
    """
    Returns an S&P-500 style overview:
      { index: {...}, sparkline: [{t, o, h, l, c}], last_updated }
    """
    loop = asyncio.get_running_loop()

    def _blocking() -> dict[str, Any]:
        t = yf.Ticker("^GSPC")
        fi = t.fast_info or {}
        hist_map = {"1d": ("1d", "5m"), "1w": ("5d", "30m"),
                    "1m": ("1mo", "1h"), "1y": ("1y", "1d"),
                    "all": ("max", "1wk")}
        period, interval = hist_map.get(range_, ("1d", "5m"))
        hist = t.history(period=period, interval=interval, auto_adjust=False)
        sparkline = []
        for idx, row in hist.iterrows():
            sparkline.append({
                "t": idx.isoformat(),
                "o": float(row["Open"]), "h": float(row["High"]),
                "l": float(row["Low"]),  "c": float(row["Close"]),
            })
        price = fi.get("last_price") or fi.get("regular_market_price") or 0
        prev  = fi.get("previous_close") or fi.get("regular_market_previous_close") or price
        # Fallback: derive price from sparkline if fast_info was empty (weekends/off-hours)
        if not price and sparkline:
            price = sparkline[-1]["c"]
        if not prev and len(sparkline) >= 2:
            prev = sparkline[0]["c"]
        change = (price - prev) if (price and prev) else 0
        pct    = (change / prev * 100) if prev else 0
        return {
            "index": {
                "ticker": "SPX", "name": "S&P 500",
                "price": round(price, 2),
                "prev_close": round(prev, 2),
                "change": round(change, 2),
                "change_pct": round(pct, 2),
            },
            "sparkline": sparkline,
            "range": range_,
            "last_updated": datetime.now(timezone.utc).isoformat(),
        }
    return await loop.run_in_executor(None, _blocking)


async def get_movers() -> dict[str, Any]:
    """Top gainers / losers / most-actives from Milli's universe."""
    now = datetime.now(timezone.utc).timestamp()
    if _cache["movers"] and (now - _cache["at"] < 120):   # 2-min cache
        return _cache["movers"]

    loop = asyncio.get_running_loop()

    def _blocking() -> dict[str, Any]:
        quotes: list[dict[str, Any]] = []
        # Batch-download previous close + current price via `tickers` string
        try:
            data = yf.download(
                tickers=" ".join(UNIVERSE),
                period="2d", interval="1d",
                progress=False, group_by="ticker", auto_adjust=False, threads=True,
            )
            for tk in UNIVERSE:
                try:
                    sub = data[tk] if tk in data.columns.get_level_values(0) else None
                    if sub is None or len(sub.dropna()) < 2:
                        continue
                    closes = sub["Close"].dropna().tolist()
                    if len(closes) < 2:
                        continue
                    price = float(closes[-1])
                    prev  = float(closes[-2])
                    change = price - prev
                    pct    = (change / prev * 100) if prev else 0
                    volume = int(sub["Volume"].dropna().tolist()[-1]) if "Volume" in sub else 0
                    quotes.append({
                        "ticker": tk, "name": tk,
                        "price":  round(price, 2),
                        "prev_close": round(prev, 2),
                        "change":     round(change, 2),
                        "change_pct": round(pct, 2),
                        "volume":     volume,
                    })
                except Exception:
                    continue
        except Exception:
            pass

        gainers = sorted(quotes, key=lambda q: q["change_pct"], reverse=True)[:5]
        losers  = sorted(quotes, key=lambda q: q["change_pct"])[:5]
        actives = sorted(quotes, key=lambda q: q.get("volume", 0), reverse=True)[:5]
        return {
            "gainers": gainers, "losers": losers, "actives": actives,
            "count": len(quotes),
            "last_updated": datetime.now(timezone.utc).isoformat(),
        }

    result = await loop.run_in_executor(None, _blocking)
    _cache["movers"] = result
    _cache["at"] = now
    return result


async def get_quote_batch(tickers: list[str]) -> list[dict[str, Any]]:
    loop = asyncio.get_running_loop()
    def _blocking() -> list[dict[str, Any]]:
        return [_fast_quote(t) for t in tickers[:20]]
    return await loop.run_in_executor(None, _blocking)

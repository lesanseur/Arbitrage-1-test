import csv
import os
import time
from datetime import datetime, timezone

import ccxt


def env_str(name: str, default: str) -> str:
    return os.getenv(name, default).strip()


def env_float(name: str, default: float) -> float:
    value = os.getenv(name)
    return float(value) if value is not None else default


def env_int(name: str, default: int) -> int:
    value = os.getenv(name)
    return int(value) if value is not None else default


def env_optional_int(name: str):
    value = os.getenv(name)
    if value is None or value.strip() == "":
        return None
    return int(value)


# ===== CONFIG (env overridable) =====
EXCHANGE_A = env_str("EXCHANGE_A", "binance")
EXCHANGE_B = env_str("EXCHANGE_B", "kraken")
SYMBOL = env_str("SYMBOL", "BTC/USDT")
POLL_SECONDS = env_int("POLL_SECONDS", 10)
MIN_NET_SPREAD_PCT = env_float("MIN_NET_SPREAD_PCT", 0.40)
MAX_LOOPS = env_optional_int("MAX_LOOPS")

# Estimated total costs in percent (fees + slippage)
TOTAL_COSTS_PCT = env_float("TOTAL_COSTS_PCT", 0.25)

CSV_PATH = env_str("CSV_PATH", "arbitrage_log.csv")


def build_exchange(exchange_id: str):
    exchange_cls = getattr(ccxt, exchange_id, None)
    if not exchange_cls:
        raise ValueError(f"Unsupported exchange: {exchange_id}")
    exchange = exchange_cls({"enableRateLimit": True})
    exchange.load_markets()
    if SYMBOL not in exchange.markets:
        raise ValueError(f"{SYMBOL} not available on {exchange_id}")
    return exchange


def get_last_price(exchange, symbol: str) -> float:
    ticker = exchange.fetch_ticker(symbol)
    last = ticker.get("last")
    if last is None:
        raise RuntimeError(f"No last price from {exchange.id} for {symbol}")
    return float(last)


def spread_pct(buy_price: float, sell_price: float) -> float:
    return ((sell_price - buy_price) / buy_price) * 100


def init_csv(path: str):
    try:
        with open(path, "x", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(
                [
                    "timestamp",
                    "buy_exchange",
                    "buy_price",
                    "sell_exchange",
                    "sell_price",
                    "gross_spread_pct",
                    "net_spread_pct",
                    "signal",
                ]
            )
    except FileExistsError:
        pass


def append_csv(path: str, row):
    with open(path, "a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(row)


def main():
    ex_a = build_exchange(EXCHANGE_A)
    ex_b = build_exchange(EXCHANGE_B)
    init_csv(CSV_PATH)

    print(
        f"[{datetime.now(timezone.utc).isoformat()}] Paper arbitrage scanner started: "
        f"{EXCHANGE_A} vs {EXCHANGE_B} | {SYMBOL}"
    )

    loops = 0
    while True:
        loops += 1
        ts = datetime.now(timezone.utc).isoformat()
        try:
            price_a = get_last_price(ex_a, SYMBOL)
            price_b = get_last_price(ex_b, SYMBOL)

            # Buy A / Sell B
            gross_ab = spread_pct(price_a, price_b)
            net_ab = gross_ab - TOTAL_COSTS_PCT

            # Buy B / Sell A
            gross_ba = spread_pct(price_b, price_a)
            net_ba = gross_ba - TOTAL_COSTS_PCT

            if net_ab >= MIN_NET_SPREAD_PCT:
                signal = f"BUY {EXCHANGE_A} / SELL {EXCHANGE_B}"
                print(f"[{ts}] {signal} | gross={gross_ab:.3f}% net={net_ab:.3f}%")
                append_csv(path=CSV_PATH, row=[ts, EXCHANGE_A, price_a, EXCHANGE_B, price_b, f"{gross_ab:.4f}", f"{net_ab:.4f}", signal])
            elif net_ba >= MIN_NET_SPREAD_PCT:
                signal = f"BUY {EXCHANGE_B} / SELL {EXCHANGE_A}"
                print(f"[{ts}] {signal} | gross={gross_ba:.3f}% net={net_ba:.3f}%")
                append_csv(path=CSV_PATH, row=[ts, EXCHANGE_B, price_b, EXCHANGE_A, price_a, f"{gross_ba:.4f}", f"{net_ba:.4f}", signal])
            else:
                print(
                    f"[{ts}] HOLD | "
                    f"{EXCHANGE_A}={price_a:.2f} {EXCHANGE_B}={price_b:.2f} "
                    f"net_ab={net_ab:.3f}% net_ba={net_ba:.3f}%"
                )
        except Exception as exc:
            print(f"[{ts}] ERROR: {exc}")

        if MAX_LOOPS is not None and loops >= MAX_LOOPS:
            print("Reached MAX_LOOPS, stopping.")
            break

        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()

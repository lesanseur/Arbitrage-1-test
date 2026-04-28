# Deploy sur Render (sans ton PC)

Ce bot tourne en **simulation (paper)** sur Render, pas sur ton ordinateur.

## 1) Mettre le dossier sur GitHub

Depuis `C:\Users\FEYA\OneDrive\Documents\TRADING\ROBOTS\TEST`:

```bash
git init
git add .
git commit -m "Arbitrage paper bot for Render"
git branch -M main
git remote add origin <TON_URL_GITHUB>
git push -u origin main
```

## 2) Deploy sur Render

1. Va sur [Render](https://render.com) et connecte ton compte GitHub.
2. Clique **New** -> **Blueprint**.
3. Selectionne ton repo.
4. Render detecte `render.yaml` et cree un **Worker**.
5. Clique **Apply** / **Create**.

## 3) Variables d'environnement

Tu peux modifier dans Render -> service -> Environment:

- `EXCHANGE_A` (ex: `binance`)
- `EXCHANGE_B` (ex: `kraken`)
- `SYMBOL` (ex: `BTC/USDT`)
- `POLL_SECONDS` (ex: `10`)
- `MIN_NET_SPREAD_PCT` (ex: `0.40`)
- `TOTAL_COSTS_PCT` (ex: `0.25`)

## 4) Voir les resultats

Dans Render -> service -> **Logs**:
- `HOLD` = pas d'opportunite nette
- `BUY ... / SELL ...` = opportunite detectee en simulation

## Important

- Ce setup n'envoie **aucun ordre reel**.
- N'ajoute pas de cles API tant que tu n'as pas valide la logique en paper.

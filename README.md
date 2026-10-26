# Chop-A-Forest V4.8.5 — Faster Mobs / Boss + Endless

PATCH ONLY, nakładka na V4.8.4 (nie instalować na starszych wersjach).

Podmień: `main.lua`, `cogs/combat.lua`, `cogs/scheduler.lua`, `cogs/dodge.lua`, `cogs/tools.lua`.
Dodaj dwa NOWE pliki: `cogs/bossreset.lua`, `cogs/endless.lua`.
Pozostałych plików, w szczególności `cogs/collection.lua` z 9-sekundowym sellen, NIE ruszaj.

Zmiany:
- Zwykły tryb: szkielety i Pumpkinlingi przed Jackiem, bez automatycznych uników.
- Gdy zaobserwujemy reset HP Jacka / wymianę aktywnego Guardiana w walce: fallback do wcześniejszego priorytetu Jacka i unikania tylko obszarów bezpośrednio zagrażających postaci.
- Bardziej agresywny, bliższy zawis w walkach, 1 klatka na stabilizację po teleportacji, korekta celownika tuż przed LPM, przechodzenie na inne strony hitboxa przy nieskutecznych atakach.
- Po pojawieniu się `RunEnd.Stage.Endless` bot klika zaobserwowany w V10 przycisk i sprawdza tekst `STARTING...`.
- NIE dotyka zakupu plecaka, ClawsSpeed, sprzedaży 9s, jajka i PumpkinHead.

Uruchom po Commit:
`loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.8.5"))()`

Testowano lokalnie wyłącznie parsowanie składni Lua i statyczne sprawdzanie spójności plików; nie testowano w runtime Roblox.

Uwaga: monitor resetu bazuje na atrybutach serwera HP, State, MonsterId. Nie gwarantuje wykrycia każdego resetu, szczególnie niewidocznego dla klienta.

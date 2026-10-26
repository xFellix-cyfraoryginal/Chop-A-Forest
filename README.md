Chop-A-Forest V4.8.7 — BOSS RUSH / OLD AIM / ENDLESS CLICK FIX

PATCH ONLY na V4.8.6.

PODMIEŃ 8 PLIKÓW:
  main.lua
  cogs/core.lua
  cogs/combat.lua
  cogs/dodge.lua
  cogs/survival.lua
  cogs/scheduler.lua
  cogs/ui.lua
  cogs/endless.lua

ZMIANY:
- BOSS ONLY=ON + IGNORE HP PAUSE=ON: tryb BOSS RUSH — całkowity brak
  uników czerwonych ostrzeżeń, brak przerw HP i wycofywania się.
  Gdy Jack istnieje, bot nie przechodzi do małych mobów ani drzew.
  Pozostałe kombinacje przełączników zachowują normalne uniki.
- Przywrócone celowanie z V4.8.5: środek replikowanego modelu
  Jacka zamiast losowej części Hitbox/Body. W trybie Boss Rush nie
  zwiększa odległości od niego po nietrafieniu.
- BOSS RUSH nadal wymaga faktycznych trafień i cooldownu akceptowanego
  przez serwer. Nie gwarantuje nieśmiertelności — postać może zginąć.
- ENDLESS: poprawka pionowego przesunięcia kliknięcia (inset GUI),
  retry co 0.75 s różnymi metodami oraz widoczne numerowane próby.
  Sukces rozpoznawany po STARTING...; gra może nadal odmówić.
- Sprzedaż, plecak, farmienie, Egg, PumpkinHead i Claw Speed bez zmian.

Uruchom po commit:
loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.8.7"))()

Test lokalny: texlua składnia; statyczna walidacja patcha.
NIE testowano wewnątrz Roblox.

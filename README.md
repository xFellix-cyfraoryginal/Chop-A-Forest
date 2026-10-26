Chop-A-Forest V4.8.6 — Sell Credit / Boss Only / HP Pause Dodge / Endless

PATCH ONLY na V4.8.5. To nie jest pełna instalacja.

PODMIEŃ 10 PLIKÓW:
  main.lua
  cogs/core.lua
  cogs/survival.lua
  cogs/dodge.lua
  cogs/scheduler.lua
  cogs/combat.lua
  cogs/tools.lua
  cogs/collection.lua
  cogs/endless.lua
  cogs/ui.lua

Nie kasuj pozostałych cogów (egg, pumpkin, world, claws, hover itd.).

ZMIANY:
1) SELL: bot zachowuje teleport + fizyczne stanie na DepositPad.
   Jeśli jest WZROST pieniędzy (leaderstats.Cash lub Stat_CashEarned),
   a HUD wykazuje stabilne 0/pojemność, może zakończyć sprzedaż
   po minimum 2.8 s na padzie + potwierdzeniu stabilności zera.
   Po wyjściu z pada czeka dodatkowo 0.85 s przed podnoszeniem.
   Jeśli brak zapłaty lub niepewna synchronizacja: stary bezpieczny
   tryb 9–13.5 s z awaryjnym kliknięciem po 2.1 s i ponowną próbą.
   Sam HUD 0/30 NIGDY nie uruchamia szybkiego powrotu.
2) DODGE: wraca wykrywanie telegraphed Circle/Line z MonsterFx,
   również w trakcie HP Pause (Heartbeat). Unika tylko stref,
   których geometria obejmuje obecny punkt postaci.
3) UI: IGNORE HP PAUSE ON/OFF (domyślnie OFF, normalna pauza),
   BOSS ONLY ON/OFF (domyślnie OFF, moby najpierw).
   Boss Only ON ignoruje małe moby; jeśli boss nie istnieje,
   farma działa normalnie, a po pojawieniu się Jacka priorytet ma Jack.
4) COMBAT: próbuje celować w replikowaną część Hitbox/Body/Root,
   a nie tylko środek modelu; adaptacyjnie obniża opóźnienie inputu
   przy potwierdzonych zmianach HP, po missach przywraca wolniejsze tempo.
   Szybsze kliknięcie nie gwarantuje przyjęcia przez serwer.
5) ENDLESS: alternatywne sposoby aktywacji widocznego przycisku
   RunEnd.Stage.Endless (w tym próba wykorzystania połączeń GUI w
   executorze), retry co 1.5 s, sukces tylko po STARTING...

OSOBNY LOGGER V14:
CropForest_BossHitbox_Sell_Logger_V14_RAW.lua
Nie należy do repo. Uruchom w executorze niezależnie od Auto Farm,
przeprowadź 1 sprzedaż i walkę z bossem, naciśnij EXPORT JSON.
Zapisuje geometrię części dostępnych na kliencie, pozycję kamery,
raycast, Warn/FireTrail z MonsterFx, zmiany HP i sale timeline.
Brak __namecall hooków. Nie dowodzi dokładnej geometrii serwerowej.

Uruchom po Commit:
loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.8.6"))()

Kontrola: składnia Lua 5.3 (texlua) wszystkich plików; statyczne
sprawdzanie spójności. NIE TESTOWANO W RUNTIME ROBLOX. Konieczna próba.

Chop-A-Forest V4.8.8 — SELL SERVER ACK ONLY

BAZA: V4.8.7. Patch zawiera TYLKO:
  main.lua
  cogs/collection.lua

POTWIERDZONE W LOGACH V9:
  CarriedLogs 5 -> 0
  Stat_LogsSold 3908 -> 3913  (5 nowych sprzedanych)
  Oba atrybuty zmienily sie przy sprzedazy w tej samej chwili.

ZMIANY:
- Sprzedaz: rzeczywiste potwierdzenie serwera (Stat_LogsSold rośnie o
  liczbę kłód, CarriedLogs = 0, HUD = 0).
- Przy torbie: najpierw wejscie na DepositPad, potem wycelowane LPM
  z boku, jezeli sam kontakt nie zadziala. Potem powrot na pad.
- Bez plecaka, z kłodami w rekach: BEZ fallbacku LPM, aby nie rzucic drewnem.
- Nie odblokowuje pickupu od samego 0/30 ani od zarobku za moba.
- Gdy attr sold/carried jest opozniony, wraca na pad i ponawia proby
  zamiast zawiesic sie z serverowym Bag Full.
- Legacy fallback tylko gdy oba atrybuty sa niedostepne (9s + 5s stabilne 0).
- Dziennik ostatnich 20 prob: env.CAF_V4.sellAudit
- TYLKO collector. Boss 4.8.7, Endless, movement, UI pozostaja bez zmian.

COMMIT oba pliki do githuba, potem wykonaj:
loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua?v=4.8.8"))()

TEST: sprawdz czy po 30/30 -> 0/30 podnosi kolejna klode bez Bag Full.
Przy niepowodzeniu podaj komunikat: SELL no server confirmation...

Walidacja offline: kompilacja skladni texlua; nie testowano w Roblox.

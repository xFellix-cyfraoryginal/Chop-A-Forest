# Chop-A-Forest — Auto Farm Alpha V2

**100% Luau**, bez Pythona, bez loggerów w repo. Lekki `main.lua` pobiera 10 niezależnych cogów (każdy poniżej 300 linii). Repo jest skonfigurowane dla `xFellix-cyfraoryginal/Chop-A-Forest` na gałęzi `main` — **nie trzeba podawać loginu ani `getgenv()`**.

## Drzewo plików

```text
Chop-A-Forest/
├── main.lua
├── cogs/
│   ├── core.lua
│   ├── world.lua
│   ├── movement.lua
│   ├── attack.lua
│   ├── collect.lua
│   ├── combat.lua
│   ├── event.lua
│   ├── engine.lua
│   ├── esp.lua
│   └── ui.lua
├── README.md
└── .gitignore
```

## Instalacja

Podmień pliki w repo GitHub, zachowując ścieżki. Wszystkie nowe cogi **muszą** zostać wrzucone razem ze zmienionym `main.lua`. Repo musi być publiczne, żeby `game:HttpGet()` pobierał RAW plików.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/xFellix-cyfraoryginal/Chop-A-Forest/main/main.lua"))()
```

Po uruchomieniu włącza się panel. Kliknij `START`, aby uruchomić Auto Farm. `STOP` zatrzymuje, `UNLOAD` całkowicie odłącza.

## Co nowego

- **Auto Collect V2**: podejście do `Workspace.Logs.Log`, skierowanie kursora/kamery, symulacja lewego kliknięcia, potwierdzenie wzrostu `PlayerGui.ChopHud.Backpack.Count`; próby ponowne i ignorowanie problematycznych kłód w bieżącej serii. **Nie zakłada sukcesu od samego TP ani od zniknięcia kłody.**
- **Auto Sell**: docelowo `Workspace.Map.SellSpot.DepositPad`, wejście w strefę i próba kliknięcia, potwierdzenie `0/5` z licznika plecaka.
- **Auto Combat**: wykrywanie każdego modelu w `Workspace.Monsters` posiadającego `MonsterId`, `Monster`, `HP`, `MaxHP`. Nie wymaga nazw przeciwników. Ignoruje sprzedawców, ręce i modele trofeów. `State=Dead` i `HP<=0` wykluczają cel.
- **Combat Defend / Hunt**: obrona przed bliskimi mobami lub wyszukiwanie w ustawionym zasięgu, slot 1/2/Auto, odstępy ataków, weryfikacja spadku HP i limit błędów. `Monster=Guardian` priorytetowo traktowany jako boss, jeżeli żywy boss używa tego samego schematu.
- **Graveyard**: filtry Graveyard dla drzew i mobów, status area/event i liczba żywych mobów/bossów w panelu.
- **UI**: `FARM`, `MOVE`, `COMBAT`, `EVENT`, `CONFIG`, `DEBUG`; draggable, minimizacja, eksport JSON.

## Krótki test

1. Uruchom **Peaceful**, ustaw `Walk` + `Input`, `Auto Collect ON`, `Auto Sell ON`, `Auto Combat OFF`. Zetnij drzewo. Sprawdź, czy plecak wzrasta i czy Sell go opróżnia.
2. Jeśli nie działa, spróbuj `Step TP` i `pickupDistance` 3–5. Eksportuj JSON, gdy nie potwierdza pickup.
3. W Event/Night włącz `Auto Combat`, ustaw `Defend` (na początek), `combatTool=2` dla siekiery; następnie możesz użyć `Hunt` + priorytet `Combat`.
4. `eventOnly` dotyczy drzew z biome `Graveyard` lub typem rozpoczynającym się od `Haunted`. `eventMobs` ogranicza cele do biomu `Graveyard`.
5. Na koniec kliknij `EXPORT` i w razie problemów wyślij JSON.

## Ograniczenia Alpha

Kod przeszedł lokalny test składni Lua. Nie mamy środowiska Roblox do przeprowadzenia testu działania. Symulowane kliknięcia (`VirtualInputManager`, `mouse1click`) zależą od executora, a ruch/ataki zależą od walidacji serwera. Nie zapewniamy, że w każdej konfiguracji będą działały. Tryb `Experimental Remote` dla drzew pozostał niezweryfikowany i jest **wyłączony domyślnie**. Nie są przechwytywane ani modyfikowane cudze wywołania sieciowe. Podczas testowania combate użyj początkowo `Defend` i pilnuj HP — automat zatrzymuje się przy progu `combatHealth`.

Loggery V6/V7 pozostają poza tym repo jako osobne RAW Lua.

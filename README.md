# CropForest CS — Alpha

Repozytorium Luau do gry Chop a Forest: Auto Farm oraz osobny Combat Scout. Podział na moduły ułatwia rozwijanie kodu. Wszystkie moduły `cogs/` mają maksymalnie 300 linijek.

## Struktura

```text
CropForest-CS/
├── main.lua                    # wejście Auto Farm (GitHub loader)
├── combat_main.lua             # wejście Combat Scout (GitHub loader)
├── cogs/
│   ├── farm/
│   │   ├── core.lua            # usługi, konfiguracja, zapis, unload
│   │   ├── world.lua           # drzewa, kłody, strefy
│   │   ├── movement.lua        # Walk / Step TP / Instant TP
│   │   ├── attack.lua          # wejście, wybór narzędzia, atak
│   │   ├── engine.lua          # cykl farmy, zbieranie, sprzedaż
│   │   ├── esp.lua             # wizualizacja celu i kłód
│   │   └── ui.lua              # panel Auto Farm
│   └── combat/
│       ├── base.lua            # usługi, eksport, unload
│       ├── detection.lua       # wykrywanie NPC / bossów
│       ├── observer.lua        # HP, wejścia, przychodzące zdarzenia
│       └── ui.lua              # panel + oznaczenia NPC
├── dist/
│   ├── main.bundle.lua         # wersja jednoplikowa Auto Farm
│   └── combat.bundle.lua       # wersja jednoplikowa loggera
└── tools/
    └── build.py               # składanie pojedynczych plików
```

## GitHub — uruchamianie osobnych cogów

1. Utwórz nowe repozytorium np. `CropForest-CS` na https://github.com/new.
2. Wgraj **zawartość** tego folderu, zachowując `cogs/farm` i `cogs/combat`.
3. W plikach `main.lua` i `combat_main.lua` podmień:

   `https://raw.githubusercontent.com/TWOJ_LOGIN/TWOJE_REPO/main/`

   na rzeczywisty adres RAW swojego repozytorium, np. `https://raw.githubusercontent.com/twojlogin/CropForest-CS/main/`.
4. W executorze uruchom Auto Farm:

   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/twojlogin/CropForest-CS/main/main.lua"))()
   ```

5. W trybie, w którym są moby/bossy, uruchom osobno Combat Scout:

   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/twojlogin/CropForest-CS/main/combat_main.lua"))()
   ```

Możesz też **bez edytowania repozytorium** podać URL na czas sesji:

```lua
getgenv().CROPFOREST_BASE_URL = "https://raw.githubusercontent.com/twojlogin/CropForest-CS/main/"
loadstring(game:HttpGet(getgenv().CROPFOREST_BASE_URL .. "main.lua"))()
```

W ten sposób zmieniasz tylko adres w loaderze executora; pliki repozytorium pozostają niezmienione.

## Test bez GitHub

Uruchom `dist/main.bundle.lua` lub `dist/combat.bundle.lua` bezpośrednio w executorze, tak samo jak stare jednoplikowe wersje. Nie ładują modułów przez HTTP.

## Przebudowanie plików jednoplikowych

```bash
python tools/build.py
```

## Moduły i kolejność

Każdy plik `cogs/` zwraca funkcję `return function(C) ... end` i otrzymuje ten sam obiekt `C`. Dlatego moduły muszą być ładowane w kolejności zapisanej w `main.lua` i `combat_main.lua`. Przed restartem skryptu istniejąca instancja jest wyładowywana.

## Alpha: co działa, a co wymaga testów

- Auto Farm: wykrywanie prawdziwych drzew i kłód, tryby poruszania Walk/Step TP/Instant TP, Input i eksperymentalna metoda Remote, zbieranie i Sell na podstawie zmian stanu. Działanie automatycznych ataków/teleportów zależy od walidacji serwera i executora.
- Combat Scout: niezależny logger przeciwników. Nie wykryje bossów na Peaceful, jeżeli tryb ich nie zawiera.
- Tryb Experimental Remote korzysta z częściowo rozpoznanych wywołań i nie ma gwarancji poprawności.
- Wcześniejsze loggery z hookami mogą pozostawić zmiany do restartu klienta. Dla testów Alpha uruchom Roblox od nowa.
- Projekt nie był testowany live po rozdzieleniu na repozytorium. Używaj swoich plików/repozytorium, bo `loadstring` uruchamia kod pobierany z internetu.

# CropForest Auto Farm Alpha

**Wyłącznie Auto Farm.** Repozytorium zawiera samo Luau (`.lua`), bez Pythona, bez skryptów budowania i bez osobnych loggerów.

## Pliki

```text
CropForest-CS/
├── main.lua
└── cogs/
    ├── core.lua
    ├── world.lua
    ├── movement.lua
    ├── attack.lua
    ├── engine.lua
    ├── esp.lua
    └── ui.lua
```

Każdy cog ma najwyżej 300 linijek, zwraca `function(C)` i jest ładowany z `main.lua` we właściwej kolejności.

## Instalacja na GitHubie

1. Utwórz repozytorium, np. **CropForest-CS**, na GitHubie. Gałąź główna powinna nazywać się `main` (lub popraw ją w URL).
2. Rozpakuj ZIP i wrzuć **pliki i folder `cogs`**, nie sam archiwalny ZIP.
3. W `main.lua` zamień `TWOJ_LOGIN` na swój login. Jeśli repozytorium ma inną nazwę, popraw także `CropForest-CS` w adresie.
4. Uruchom w executorze:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TWOJ_LOGIN/CropForest-CS/main/main.lua"))()
```

Zastąp `TWOJ_LOGIN` swoim loginem. Kod sam dociąga siedem plików z `cogs/`.

### Alternatywa bez edytowania `main.lua`

```lua
getgenv().CROPFOREST_BASE_URL = "https://raw.githubusercontent.com/TWOJ_LOGIN/CropForest-CS/main/"
loadstring(game:HttpGet(getgenv().CROPFOREST_BASE_URL .. "main.lua"))()
```

Wtedy w repozytorium nie musisz zmieniać domyślnego adresu w `main.lua`.

## Funkcje Alpha

- **Walk**, **Step TP**, **Instant TP** z regulowanymi parametrami w UI.
- Wykrywanie prawdziwych drzew po `TreeId`, `HP`, `Felled`; priorytet Golden.
- Próby automatycznych ataków w trybie Input; opcjonalny eksperymentalny Remote.
- Podchodzenie do kłód, odczyt plecaka, podejście/TP do Sell i weryfikacja sprzedaży.
- ESP celu, status i Unload.

**Status:** Alpha. Nie zostało potwierdzone, że wszystkie automatyczne uderzenia, zbieranie i teleporty są akceptowane przez serwer. `Experimental Remote` nie musi działać. Eksport informacji o błędach w panelu farmy to wewnętrzna diagnostyka, nie oddzielny logger.

Repozytorium jest przygotowane do opublikowania, ale nie zostało opublikowane automatycznie. Nie uruchamiaj skryptów RAW z nieznanych repozytoriów.
